extends RefCounted
## Cliente WebSocket para matchmaking (fila de 20s) e partidas online PvP.
## Caso passem os 20s sem adversário (ou servidor indisponível), cai contra bot local.

const Protocol = preload("res://net/online_protocol.gd")
const Perspective = preload("res://net/perspective_mapper.gd")

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


func is_in_match() -> bool:
	return state == State.IN_MATCH


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
			_send_packet({"type": "join_queue", "version": Protocol.VERSION, "name": player_name})
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

	# Leitura de pacotes recebidos
	while ws.get_ready_state() == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count() > 0:
		var packet: PackedByteArray = ws.get_packet()
		var msg: Dictionary = Protocol.decode(packet, Protocol.MAX_SERVER_MESSAGE)
		if msg.is_empty():
			continue
		_handle_message(msg)


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
			# Converte perspectiva se o jogador for time 1
			latest_snapshot = Perspective.to_client_snapshot(raw_snap, assigned_team)
			snapshot_received.emit(latest_snapshot)
		"events":
			var raw_events: Array = msg.get("events", [])
			var mapped_events: Array[Dictionary] = Perspective.to_client_events(raw_events, assigned_team)
			for ev: Dictionary in mapped_events:
				pending_events.append(ev)
			events_received.emit(mapped_events)
		"match_over":
			var winner: int = int(msg.get("winner", -1))
			if assigned_team == 1 and winner >= 0:
				winner = Perspective.flip_team(winner)
			var reason: String = str(msg.get("reason", ""))
			match_ended.emit(winner, reason)
		"ping":
			_send_packet({"type": "pong"})


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
	return err == OK
