extends RefCounted
## Servidor autoritativo de WebSocket para Clash of Eras.
## Gerencia fila de matchmaking, emparelhamento de jogadores e execução de partidas dedicadas.

const Protocol = preload("res://net/online_protocol.gd")
const Perspective = preload("res://net/perspective_mapper.gd")
const Session = preload("res://simulation/match_session.gd")

var tcp_server: TCPServer = TCPServer.new()
var is_listening: bool = false
var port: int = Protocol.DEFAULT_PORT

# Estruturas de gerenciamento
var clients: Array[Dictionary] = [] # { id, peer, tcp_stream, in_queue, room_id, queue_time }
var matchmaking_queue: Array[int] = [] # client_ids
var rooms: Dictionary = {} # room_id -> RoomData
var next_client_id: int = 1
var next_room_id: int = 1

# Snapshot/Eventos push rate limiter (envia snapshots regulares a ~15-20 FPS para economizar banda)
const SNAPSHOT_INTERVAL: float = 0.05


class RoomData:
	var id: String
	var session: Session
	var player_ids: Array[int] = [-1, -1]
	var player_names: Array[String] = ["Jogador 1", "Jogador 2"]
	var snapshot_timer: float = 0.0
	var command_counter: Array[int] = [0, 0]
	var last_bought_offer: Dictionary = {} # offer_id -> item_id real


func listen(listen_port: int = Protocol.DEFAULT_PORT) -> Error:
	stop()
	port = listen_port
	var err: Error = tcp_server.listen(port, "*")
	if err == OK:
		is_listening = true
		print("[SERVER] Ouvindo conexões WebSocket na porta %d..." % port)
	else:
		push_error("[SERVER] Falha ao abrir porta %d: %d" % [port, err])
	return err


func stop() -> void:
	for r_id: String in rooms.keys():
		_close_room(r_id, "Servidor reiniciado")
	for c: Dictionary in clients:
		var p: WebSocketPeer = c.get("peer")
		if p != null and p.get_ready_state() == WebSocketPeer.STATE_OPEN:
			p.close()
	clients.clear()
	matchmaking_queue.clear()
	rooms.clear()
	if tcp_server.is_listening():
		tcp_server.stop()
	is_listening = false


func step(delta: float) -> void:
	if not is_listening:
		return

	_accept_new_connections()
	_poll_clients(delta)
	_update_matchmaking()
	_update_rooms(delta)


func _accept_new_connections() -> void:
	while tcp_server.is_connection_available():
		var conn: StreamPeerTCP = tcp_server.take_connection()
		if conn == null:
			continue
		var ws: WebSocketPeer = WebSocketPeer.new()
		var err: Error = ws.accept_stream(conn)
		if err != OK:
			conn.disconnect_from_host()
			continue

		var c_id: int = next_client_id
		next_client_id += 1
		clients.append({
			"id": c_id,
			"peer": ws,
			"tcp": conn,
			"in_queue": false,
			"room_id": "",
			"name": "Jogador %d" % c_id
		})


func _poll_clients(_delta: float) -> void:
	var to_remove: Array[int] = []

	for i: int in range(clients.size()):
		var c: Dictionary = clients[i]
		var ws: WebSocketPeer = c["peer"]
		ws.poll()
		var state: WebSocketPeer.State = ws.get_ready_state()

		if state == WebSocketPeer.STATE_CLOSED or state == WebSocketPeer.STATE_CLOSING:
			to_remove.append(int(c["id"]))
			continue

		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var packet: PackedByteArray = ws.get_packet()
				var msg: Dictionary = Protocol.decode(packet, Protocol.MAX_CLIENT_MESSAGE)
				if not msg.is_empty():
					_handle_client_message(c, msg)

	for c_id: int in to_remove:
		_disconnect_client(c_id)


func _handle_client_message(client: Dictionary, msg: Dictionary) -> void:
	var msg_type: String = str(msg.get("type", ""))
	var c_id: int = int(client["id"])

	match msg_type:
		"join_queue":
			if not matchmaking_queue.has(c_id) and str(client["room_id"]).is_empty():
				matchmaking_queue.append(c_id)
				client["in_queue"] = true
				_send_to_client(client, {"type": "queue_joined"})
				print("[SERVER] Jogador %d entrou na fila. Total na fila: %d" % [c_id, matchmaking_queue.size()])

		"leave_queue":
			matchmaking_queue.erase(c_id)
			client["in_queue"] = false

		"command":
			var room_id: String = str(client["room_id"])
			if rooms.has(room_id):
				var room: RoomData = rooms[room_id]
				var team: int = 0 if room.player_ids[0] == c_id else 1
				var op: String = str(msg.get("op", ""))
				var payload: Dictionary = msg.get("payload", {})
				_process_room_command(room, team, op, payload)

		"pong":
			pass


func _update_matchmaking() -> void:
	# Emparelha de 2 em 2 jogadores
	while matchmaking_queue.size() >= 2:
		var p1_id: int = matchmaking_queue.pop_front()
		var p2_id: int = matchmaking_queue.pop_front()

		var c1: Dictionary = _find_client(p1_id)
		var c2: Dictionary = _find_client(p2_id)

		if c1.is_empty() or c2.is_empty():
			continue

		c1["in_queue"] = false
		c2["in_queue"] = false

		_create_room(c1, c2)


func _create_room(c1: Dictionary, c2: Dictionary) -> void:
	var room_id: String = "room_%d" % next_room_id
	next_room_id += 1

	var room: RoomData = RoomData.new()
	room.id = room_id
	# Semente determinística para a partida
	var match_seed: int = int(Time.get_ticks_msec()) + next_room_id * 1009
	room.session = Session.new(match_seed)
	room.session.bot_enabled = false # PvP puro: ambos os lados são humanos!
	room.player_ids = [int(c1["id"]), int(c2["id"])]
	room.player_names = [str(c1["name"]), str(c2["name"])]

	c1["room_id"] = room_id
	c2["room_id"] = room_id

	rooms[room_id] = room

	print("[SERVER] Sala criada: %s (%s vs %s)" % [room_id, room.player_names[0], room.player_names[1]])

	# Notifica ambos os jogadores
	_send_to_client(c1, {
		"type": "match_found",
		"room_id": room_id,
		"team": 0,
		"opponent_name": room.player_names[1]
	})
	_send_to_client(c2, {
		"type": "match_found",
		"room_id": room_id,
		"team": 1,
		"opponent_name": room.player_names[0]
	})

	# Envia snapshot inicial
	_broadcast_room_snapshots(room, true)


func _process_room_command(room: RoomData, team: int, op: String, payload: Dictionary) -> void:
	if not Protocol.ALLOWED_OPERATIONS.has(op):
		return

	# Ajusta perspectiva de coordenadas para o time 1 (que joga no topo na simulação)
	var authoritative_payload: Dictionary = Perspective.from_client_payload(payload, team)

	# Se for compra de item, memoriza o ID gerado para permitir compra e equipagem instantânea
	if op == "equip" and str(authoritative_payload.get("item_id", "")).begins_with(Protocol.BOUGHT_PREFIX):
		var prefix_offer: String = str(authoritative_payload["item_id"]).substr(Protocol.BOUGHT_PREFIX.length())
		if room.last_bought_offer.has(prefix_offer):
			authoritative_payload["item_id"] = room.last_bought_offer[prefix_offer]

	room.command_counter[team] += 1
	var cmd_id: String = "srv_cmd_%d_%d" % [team, room.command_counter[team]]
	var res: Dictionary = room.session.apply_command(team, cmd_id, op, authoritative_payload)

	if op == "buy_item" and bool(res.get("ok", false)):
		var offer_id: String = str(authoritative_payload.get("offer_id", ""))
		var item_id: String = str(res.get("data", {}).get("id", ""))
		if not offer_id.is_empty() and not item_id.is_empty():
			room.last_bought_offer[offer_id] = item_id

	# Imediatamente envia o snapshot atualizado e os eventos após comando
	_broadcast_room_snapshots(room, true)


func _update_rooms(delta: float) -> void:
	var finished_rooms: Array[String] = []

	for r_id: String in rooms.keys():
		var room: RoomData = rooms[r_id]
		room.session.step(delta)
		room.snapshot_timer += delta

		# Envia eventos acumulados
		var events_by_team: Array[Array] = room.session.drain_events_by_team()
		for t: int in range(2):
			if not events_by_team[t].is_empty():
				var c: Dictionary = _find_client(room.player_ids[t])
				if not c.is_empty():
					_send_to_client(c, {
						"type": "events",
						"events": events_by_team[t]
					})

		# Envia snapshots periódicos
		if room.snapshot_timer >= SNAPSHOT_INTERVAL:
			room.snapshot_timer = 0.0
			_broadcast_room_snapshots(room, false)

		if room.session.phase == "match_over":
			_broadcast_match_over(room)
			finished_rooms.append(r_id)

	for r_id: String in finished_rooms:
		_close_room(r_id, "Partida concluída")


func _broadcast_room_snapshots(room: RoomData, _force: bool) -> void:
	for t: int in range(2):
		var c: Dictionary = _find_client(room.player_ids[t])
		if not c.is_empty():
			var snap: Dictionary = room.session.snapshot_for_team(t)
			_send_to_client(c, {
				"type": "snapshot",
				"snapshot": snap
			})


func _broadcast_match_over(room: RoomData) -> void:
	var winner: int = room.session.sim.match_winner
	for t: int in range(2):
		var c: Dictionary = _find_client(room.player_ids[t])
		if not c.is_empty():
			_send_to_client(c, {
				"type": "match_over",
				"winner": winner,
				"reason": "Vencedor definido"
			})


func _disconnect_client(c_id: int) -> void:
	matchmaking_queue.erase(c_id)
	for i: int in range(clients.size() - 1, -1, -1):
		if clients[i]["id"] == c_id:
			var room_id: String = str(clients[i]["room_id"])
			if rooms.has(room_id):
				_close_room(room_id, "Adversário desconectou")
			clients.remove_at(i)
			break


func _close_room(room_id: String, reason: String) -> void:
	if not rooms.has(room_id):
		return
	var room: RoomData = rooms[room_id]
	for p_id: int in room.player_ids:
		var c: Dictionary = _find_client(p_id)
		if not c.is_empty():
			c["room_id"] = ""
			_send_to_client(c, {
				"type": "match_over",
				"winner": -1,
				"reason": reason
			})
	rooms.erase(room_id)


func _find_client(c_id: int) -> Dictionary:
	for c: Dictionary in clients:
		if c["id"] == c_id:
			return c
	return {}


func _send_to_client(client: Dictionary, msg: Dictionary) -> void:
	var ws: WebSocketPeer = client.get("peer")
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var bytes: PackedByteArray = Protocol.encode(msg)
		ws.send(bytes, WebSocketPeer.WRITE_MODE_BINARY)
