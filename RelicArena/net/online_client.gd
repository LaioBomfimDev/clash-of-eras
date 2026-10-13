extends RefCounted
## Cliente WebSocket para matchmaking (fila de 20s) e partidas online PvP.
## Caso passem os 20s sem adversário (ou servidor indisponível), cai contra bot local.

const Protocol = preload("res://net/online_protocol.gd")
const Perspective = preload("res://net/perspective_mapper.gd")
const CATALOG_CACHE_CAPABILITY: String = "snapshot_catalog_cache_v1"
const MAX_BUFFERED_EVENTS: int = 256
const PING_INTERVAL_SECONDS: float = 3.0
const MAX_RECEIVED_PACKETS_PER_STEP: int = 64
const RECEIVE_BUDGET_USEC: int = 4000

enum State {
	DISCONNECTED,
	CONNECTING,
	IN_QUEUE,
	MATCH_FOUND,
	IN_MATCH,
	FALLBACK_BOT
}

var state: State = State.DISCONNECTED
var ws: WebSocketPeer = WebSocketPeer.new()
var server_url: String = Protocol.DEFAULT_SERVER_URL
var queue_time: float = 0.0
var max_queue_seconds: float = Protocol.QUEUE_SECONDS

var room_id: String = ""
var assigned_team: int = 0
var player_name: String = "Jogador"
var opponent_name: String = "Adversário"
var latest_snapshot: Dictionary = {}
var pending_events: Array[Dictionary] = []
var status_message: String = ""
var _catalog_cache: Dictionary = {}
var _pending_snapshot_message: Dictionary = {}
var _ping_timer: float = 0.0
var _ping_nonce: int = 0
var _ping_sent_usec: int = 0
var _last_snapshot_usec: int = 0
var _metrics: Dictionary = {}

# Sinais para integração com a UI
signal matchmaking_tick(seconds_left: float)
signal match_started(team: int, opp_name: String)
signal snapshot_received(snapshot: Dictionary)
signal events_received(events: Array[Dictionary])
signal fallback_to_bot(reason: String)
signal match_ended(winner: int, reason: String)


func start_matchmaking(custom_url: String = "", custom_name: String = "") -> void:
	reset()
	if not custom_name.strip_edges().is_empty():
		player_name = custom_name.strip_edges().substr(0, 16)
	if not custom_url.is_empty():
		server_url = custom_url
	else:
		server_url = Protocol.DEFAULT_SERVER_URL
	queue_time = 0.0
	state = State.CONNECTING
	status_message = "Conectando ao servidor..."
	ws = WebSocketPeer.new()
	var err: Error = ws.connect_to_url(server_url)
	if err != OK:
		_trigger_fallback("Servidor offline")


func cancel_matchmaking() -> void:
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_packet({"type": "leave_queue"})
		ws.close()
	reset()


func reset() -> void:
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.close()
	state = State.DISCONNECTED
	queue_time = 0.0
	room_id = ""
	assigned_team = 0
	opponent_name = "Adversário"
	latest_snapshot.clear()
	pending_events.clear()
	status_message = ""
	_catalog_cache.clear()
	_pending_snapshot_message.clear()
	_ping_timer = 0.0
	_ping_nonce = 0
	_ping_sent_usec = 0
	_last_snapshot_usec = 0
	_metrics = {"rtt_ms": -1.0, "rx_bytes": 0, "tx_bytes": 0, "rx_packets": 0,
		"tx_packets": 0, "snapshots_received": 0, "snapshots_applied": 0,
		"snapshots_coalesced": 0, "events_received": 0, "decode_last_step_usec": 0}


func is_in_match() -> bool:
	return state == State.IN_MATCH


## RTT é ida e volta, incluindo polling; -1 significa sem amostra. Bytes são payload.
func get_network_metrics() -> Dictionary:
	var result: Dictionary = _metrics.duplicate()
	result["outbound_buffered_bytes"] = ws.get_current_outbound_buffered_amount() if ws != null else 0
	result["queued_inbound_packets"] = ws.get_available_packet_count() if ws != null else 0
	result["snapshot_age_ms"] = float(Time.get_ticks_usec() - _last_snapshot_usec) / 1000.0 if _last_snapshot_usec > 0 else -1.0
	return result


func send_command(op: String, payload: Dictionary = {}) -> bool:
	if state != State.IN_MATCH or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	var msg: Dictionary = {
		"type": "command",
		"room_id": room_id,
		"op": op,
		"payload": payload
	}
	return _send_packet(msg)


func step(delta: float) -> void:
	if state == State.DISCONNECTED or state == State.FALLBACK_BOT:
		return

	if ws == null:
		return

	ws.poll()
	var ready_state: WebSocketPeer.State = ws.get_ready_state()

	# Tratamento da fase de conexão e fila
	if state == State.CONNECTING:
		queue_time += delta
		if ready_state == WebSocketPeer.STATE_OPEN:
			state = State.IN_QUEUE
			status_message = "Buscando jogador..."
			_send_packet({"type": "join_queue", "version": Protocol.VERSION, "name": player_name,
				"capabilities": [CATALOG_CACHE_CAPABILITY]})
		elif ready_state == WebSocketPeer.STATE_CLOSED or ready_state == WebSocketPeer.STATE_CLOSING:
			_trigger_fallback("Servidor indisponível")
			return
		elif queue_time >= 5.0: # Timeout de handshake inicial
			_trigger_fallback("Tempo limite de conexão")
			return

	elif state == State.IN_QUEUE:
		queue_time += delta
		var remaining: float = maxf(0.0, max_queue_seconds - queue_time)
		matchmaking_tick.emit(remaining)
		if queue_time >= max_queue_seconds:
			_trigger_fallback("Nenhum jogador encontrado em 20s")
			return
		if ready_state == WebSocketPeer.STATE_CLOSED or ready_state == WebSocketPeer.STATE_CLOSING:
			_trigger_fallback("Conexão perdida")
			return

	elif state == State.IN_MATCH:
		if ready_state == WebSocketPeer.STATE_CLOSED or ready_state == WebSocketPeer.STATE_CLOSING:
			# Partida caiu no meio
			status_message = "Conexão com a partida perdida."

	_drain_incoming_packets()
	_update_ping(delta)


## Orçamento cooperativo: verifica entre pacotes, sem interromper uma decodificação.
## Pacotes restantes ficam no WebSocket para o próximo quadro, mantendo a ordem.
## budget_usec == 0 desativa só o relógio para testes determinísticos do teto de pacotes.
func _drain_incoming_packets(max_packets: int = MAX_RECEIVED_PACKETS_PER_STEP, budget_usec: int = RECEIVE_BUDGET_USEC) -> int:
	var started: int = Time.get_ticks_usec()
	var decode_usec: int = 0
	var received_packets: int = 0
	while ws.get_ready_state() == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count() > 0:
		if received_packets >= max_packets:
			break
		if received_packets > 0 and budget_usec > 0 and Time.get_ticks_usec() - started >= budget_usec:
			break
		var packet: PackedByteArray = ws.get_packet()
		received_packets += 1
		_metrics["rx_bytes"] = int(_metrics.get("rx_bytes", 0)) + packet.size()
		_metrics["rx_packets"] = int(_metrics.get("rx_packets", 0)) + 1
		var decode_started: int = Time.get_ticks_usec()
		var msg: Dictionary = Protocol.decode(packet, Protocol.MAX_SERVER_MESSAGE)
		decode_usec += Time.get_ticks_usec() - decode_started
		if msg.is_empty():
			continue
		_consume_decoded_message(msg)
	_flush_pending_snapshot()
	_metrics["decode_last_step_usec"] = decode_usec
	return received_packets


## Só descarta snapshots substituídos; eventos e transições mantêm a ordem.
func _consume_decoded_message(msg: Dictionary) -> void:
	if str(msg.get("type", "")) == "snapshot":
		_metrics["snapshots_received"] = int(_metrics.get("snapshots_received", 0)) + 1
		if not _pending_snapshot_message.is_empty():
			# Snapshot completo inicial não pode perder o catálogo ao ser substituído.
			_cache_catalog(_pending_snapshot_message.get("snapshot", {}))
			_metrics["snapshots_coalesced"] = int(_metrics.get("snapshots_coalesced", 0)) + 1
		_pending_snapshot_message = msg
	else:
		_flush_pending_snapshot()
		_handle_message(msg)


func _flush_pending_snapshot() -> void:
	if _pending_snapshot_message.is_empty():
		return
	var message: Dictionary = _pending_snapshot_message
	_pending_snapshot_message = {}
	_handle_message(message)


func _cache_catalog(snapshot: Dictionary) -> void:
	for key: String in ["recipes", "item_catalog"]:
		if snapshot.has(key):
			_catalog_cache[key] = snapshot[key].duplicate(true)


func _update_ping(delta: float) -> void:
	if state not in [State.IN_QUEUE, State.IN_MATCH]:
		return
	_ping_timer += delta
	if _ping_timer < PING_INTERVAL_SECONDS:
		return
	_ping_timer = 0.0
	_ping_nonce += 1
	_ping_sent_usec = Time.get_ticks_usec()
	_send_packet({"type": "ping", "nonce": _ping_nonce})


func _handle_message(msg: Dictionary) -> void:
	var msg_type: String = str(msg.get("type", ""))
	match msg_type:
		"queue_joined":
			status_message = "Na fila de matchmaking..."
		"match_found":
			room_id = str(msg.get("room_id", ""))
			assigned_team = int(msg.get("team", 0))
			opponent_name = str(msg.get("opponent_name", "Jogador"))
			state = State.IN_MATCH
			status_message = "Partida encontrada!"
			match_started.emit(assigned_team, opponent_name)
		"snapshot":
			var raw_snap: Dictionary = msg.get("snapshot", {})
			_cache_catalog(raw_snap)
			if bool(msg.get("catalog_cached", false)):
				for key: String in ["recipes", "item_catalog"]:
					if not raw_snap.has(key):
						if not _catalog_cache.has(key):
							return
						raw_snap[key] = _catalog_cache[key]
			# Converte perspectiva se o jogador for time 1
			latest_snapshot = Perspective.to_client_snapshot(raw_snap, assigned_team)
			_last_snapshot_usec = Time.get_ticks_usec()
			_metrics["snapshots_applied"] = int(_metrics.get("snapshots_applied", 0)) + 1
			snapshot_received.emit(latest_snapshot)
		"events":
			var raw_events: Array = msg.get("events", [])
			var mapped_events: Array[Dictionary] = Perspective.to_client_events(raw_events, assigned_team)
			pending_events.append_array(mapped_events)
			if pending_events.size() > MAX_BUFFERED_EVENTS:
				pending_events = pending_events.slice(pending_events.size() - MAX_BUFFERED_EVENTS)
			_metrics["events_received"] = int(_metrics.get("events_received", 0)) + mapped_events.size()
			events_received.emit(mapped_events)
		"match_over":
			var winner: int = int(msg.get("winner", -1))
			if assigned_team == 1 and winner >= 0:
				winner = Perspective.flip_team(winner)
			var reason: String = str(msg.get("reason", ""))
			match_ended.emit(winner, reason)
		"ping":
			_send_packet({"type": "pong"})
		"pong":
			if int(msg.get("nonce", -1)) == _ping_nonce and _ping_sent_usec > 0:
				_metrics["rtt_ms"] = float(Time.get_ticks_usec() - _ping_sent_usec) / 1000.0
				_ping_sent_usec = 0


func _trigger_fallback(reason: String) -> void:
	state = State.FALLBACK_BOT
	status_message = "Jogando contra bot local (%s)" % reason
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.close()
	fallback_to_bot.emit(reason)


func _send_packet(msg: Dictionary) -> bool:
	if ws == null or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	var bytes: PackedByteArray = Protocol.encode(msg)
	var err: Error = ws.send(bytes, WebSocketPeer.WRITE_MODE_BINARY)
	if err == OK:
		_metrics["tx_bytes"] = int(_metrics.get("tx_bytes", 0)) + bytes.size()
		_metrics["tx_packets"] = int(_metrics.get("tx_packets", 0)) + 1
	return err == OK
