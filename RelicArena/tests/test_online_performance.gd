extends SceneTree
## Regressões de filas, cache negociado, privacidade e diagnóstico de rede.
## Loopback usa dois clientes locais; não representa latência de internet ou FPS.
const Protocol = preload("res://net/online_protocol.gd")
const Client = preload("res://net/online_client.gd")
const Server = preload("res://net/online_server.gd")
const Perspective = preload("res://net/perspective_mapper.gd")
const Session = preload("res://simulation/match_session.gd")
var passed: int = 0
var failed: int = 0
var command_id: int = 0

class RecordingServer extends "res://net/online_server.gd":
	var messages: Array[Dictionary] = []
	var blocked_clients: Array[int] = []
	func _send_to_client(client: Dictionary, message: Dictionary) -> bool:
		messages.append({"client_id": client["id"], "message": message.duplicate(true)})
		return true
	func _snapshot_backpressured(client: Dictionary) -> bool:
		return blocked_clients.has(int(client.get("id", -1)))
	func snapshots(client_id: int = -1) -> Array[Dictionary]:
		var output: Array[Dictionary] = []
		for entry: Dictionary in messages:
			if entry["message"].get("type") == "snapshot" and (client_id < 0 or int(entry["client_id"]) == client_id):
				output.append(entry["message"])
		return output

func _initialize() -> void:
	_test_coalescing_cache_and_event_order()
	_test_events_are_delivered_but_history_is_bounded()
	_test_perspective_isolation()
	_test_room_initialization_is_symmetric()
	_test_server_burst_cache_and_privacy()
	_test_buy_and_equip_in_same_poll()
	_test_backpressure_and_phase_changes()
	_test_loopback_metrics()
	print("ONLINE PERFORMANCE TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("ONLINE PERFORMANCE FAIL: ", description)

func _fixture() -> Session:
	var session: Session = Session.new(20261013)
	session.bot_enabled = false
	session.reset(20261013)
	for team: int in range(2):
		var own: Dictionary = session.snapshot_for_team(team)["own"]
		_command(session, team, "choose_benefit", {"option_id": own["benefit_options"][0]["option_id"]})
		for offer: Dictionary in own["shop"]:
			if offer["kind"] == "hero":
				_command(session, team, "recruit", {"offer_id": offer["offer_id"]})
	return session

func _command(session: Session, team: int, operation: String, payload: Dictionary = {}) -> Dictionary:
	command_id += 1
	return session.apply_command(team, "network_perf_%d" % command_id, operation, payload)

func _partial_message(snapshot: Dictionary) -> Dictionary:
	var partial: Dictionary = snapshot.duplicate(true)
	partial.erase("recipes")
	partial.erase("item_catalog")
	return {"type": "snapshot", "snapshot": partial, "catalog_cached": true}

func _test_coalescing_cache_and_event_order() -> void:
	var session: Session = _fixture()
	var raw: Dictionary = session.snapshot_for_team(1)
	var original: Dictionary = raw.duplicate(true)
	var client: Client = Client.new()
	client.reset()
	client.assigned_team = 1
	var emissions: Array[String] = []
	client.snapshot_received.connect(func(snapshot: Dictionary) -> void: emissions.append("snapshot:%d" % int(snapshot["own"]["gold"])))
	client.events_received.connect(func(_events: Array[Dictionary]) -> void: emissions.append("events:%d" % int(client.latest_snapshot["own"]["gold"])))
	client._consume_decoded_message({"type": "snapshot", "snapshot": raw})
	var partial: Dictionary = _partial_message(raw)
	partial["snapshot"]["own"]["gold"] = 18
	client._consume_decoded_message(partial)
	client._flush_pending_snapshot()
	_check(emissions == ["snapshot:18"], "burst applies only newest snapshot once")
	_check(client.get_network_metrics()["snapshots_coalesced"] == 1, "coalesced snapshot is counted")
	_check(client.latest_snapshot.has("recipes") and client.latest_snapshot.has("item_catalog"), "initial full catalog survives coalescing into partial snapshot")
	_check(client.latest_snapshot["recipes"] == original["recipes"], "hydrated recipes match authority")
	_check(client.latest_snapshot["item_catalog"] == original["item_catalog"], "hydrated item catalog matches authority")
	_check(raw == original, "perspective does not mutate source snapshot")
	client.latest_snapshot["item_catalog"].clear()
	client._consume_decoded_message(_partial_message(raw))
	client._flush_pending_snapshot()
	_check(client.latest_snapshot["item_catalog"] == original["item_catalog"], "consumer mutation cannot corrupt catalog cache")
	emissions.clear()
	partial = _partial_message(raw)
	partial["snapshot"]["own"]["gold"] = 16
	client._consume_decoded_message(partial)
	client._consume_decoded_message({"type": "events", "events": [{"type": "test", "team": 1}]})
	partial = _partial_message(raw)
	partial["snapshot"]["own"]["gold"] = 14
	client._consume_decoded_message(partial)
	client._flush_pending_snapshot()
	_check(emissions == ["snapshot:16", "events:16", "snapshot:14"], "event boundaries preserve corresponding snapshot order")
	client.reset()
	client._consume_decoded_message(_partial_message(raw))
	client._flush_pending_snapshot()
	_check(client.latest_snapshot.is_empty(), "new connection cannot reuse prior match catalog")
	_check(client.get_network_metrics()["rtt_ms"] == -1.0, "RTT without a sample remains unknown")
	for connection: Dictionary in client.events_received.get_connections():
		client.events_received.disconnect(connection["callable"])

func _test_events_are_delivered_but_history_is_bounded() -> void:
	var client: Client = Client.new()
	client.reset()
	var delivered: Array[int] = [0]
	client.events_received.connect(func(events: Array[Dictionary]) -> void: delivered[0] += events.size())
	for batch: int in range(3):
		var events: Array[Dictionary] = []
		for index: int in range(200):
			events.append({"type": "test", "sequence": batch * 200 + index})
		client._consume_decoded_message({"type": "events", "events": events})
	_check(delivered[0] == 600, "events_received delivers all 600 events without dropping any")
	_check(client.pending_events.size() == Client.MAX_BUFFERED_EVENTS, "unused event history has bounded memory")
	_check(client.pending_events.back()["sequence"] == 599, "bounded history retains newest events")
	_check(client.get_network_metrics()["events_received"] == 600, "event diagnostics count complete delivery")

func _test_perspective_isolation() -> void:
	var session: Session = _fixture()
	_command(session, 0, "ready")
	_command(session, 1, "ready")
	session.step(1.0)
	var raw: Dictionary = session.snapshot_for_team(1)
	var original: Dictionary = raw.duplicate(true)
	var mapped: Dictionary = Perspective.to_client_snapshot(raw, 1)
	for index: int in range(mapped["combat"]["units"].size()):
		_check(mapped["combat"]["units"][index]["team"] == Perspective.flip_team(raw["combat"]["units"][index]["team"]), "combat team maps exactly once")
	mapped["combat"]["units"][0]["equipment"].clear()
	mapped["own"]["units"][0]["cell"] = [99, 99]
	mapped["combat"]["projectiles"].clear()
	mapped["test_config"]["copies_for_level"][0] = 99
	_check(raw == original, "single root copy isolates all nested presentation changes")
	var twice: Dictionary = Perspective.to_client_snapshot(Perspective.to_client_snapshot(raw, 1), 1)
	_check(twice == raw, "applying perspective rotation twice restores full combat snapshot")

func _recording_room() -> Array:
	var server: RecordingServer = RecordingServer.new()
	server.clients = [{"id": 1, "catalog_cache_enabled": true}, {"id": 2, "catalog_cache_enabled": false}]
	var room: Server.RoomData = Server.RoomData.new()
	room.id = "network_perf"
	room.session = _fixture()
	room.player_ids = [1, 2]
	room.last_phase = room.session.phase
	server.rooms[room.id] = room
	return [server, room]

## Usa a criação real da sala; a fixture de desempenho já desativa o bot antes do reset.
func _test_room_initialization_is_symmetric() -> void:
	var server: RecordingServer = RecordingServer.new()
	server.clients = [{"id": 1, "name": "Fresh1", "room_id": ""},
		{"id": 2, "name": "Fresh2", "room_id": ""}]
	server._create_room(server.clients[0], server.clients[1])
	_check(server.rooms.size() == 1, "real room creation produces one authoritative session")
	var room: Server.RoomData = server.rooms[server.rooms.keys()[0]]
	_check(not room.session.bot_enabled, "PvP room disables local bot")
	for team: int in range(2):
		var snapshot: Dictionary = room.session.snapshot_for_team(team)
		var own: Dictionary = snapshot["own"]
		_check(int(own["gold"]) == 20, "fresh PvP team %d starts with 20 gold" % team)
		_check(own["owned"].is_empty(), "fresh PvP team %d starts without recruited heroes" % team)
		_check(int(own["capacity"]) == 4, "fresh PvP team %d starts at capacity 4" % team)
		_check(own["benefit_options"].size() == 3, "fresh PvP team %d receives three benefit choices" % team)
		_check(not bool(own["ready"]), "fresh PvP team %d is not automatically ready" % team)
		_check(snapshot["phase"] == "benefit", "fresh PvP team %d sees benefit phase before preparing" % team)
		print("ROOM INITIAL STATE team=%d gold=%d owned=%s capacity=%d benefits=%d ready=%s phase=%s" % [
			team, own["gold"], own["owned"], own["capacity"], own["benefit_options"].size(), own["ready"], snapshot["phase"]])
		var sent: Dictionary = server.snapshots(team + 1)[0]["snapshot"]
		_check(sent == snapshot, "first transmitted snapshot for team %d matches fresh authority" % team)

func _test_server_burst_cache_and_privacy() -> void:
	var fixture: Array = _recording_room()
	var server: RecordingServer = fixture[0]
	var room: Server.RoomData = fixture[1]
	server._broadcast_room_snapshots(room, true)
	_check(server.snapshots(1)[0]["snapshot"].has("item_catalog"), "first snapshot includes full catalog")
	server.messages.clear()
	var gold_before: int = int(room.session.teams[0]["gold"])
	for _index: int in range(8):
		server._process_room_command(room, 0, "reroll", {})
	_check(server.snapshots().is_empty(), "command burst does not serialize intermediate snapshots")
	server._update_rooms(0.0)
	_check(server.snapshots().size() == 2, "eight commands produce one snapshot per recipient in the same step")
	_check(int(room.session.teams[0]["gold"]) == gold_before - 16, "coalescing preserves every authoritative reroll and debit")
	var modern: Dictionary = server.snapshots(1)[0]
	var legacy: Dictionary = server.snapshots(2)[0]
	_check(bool(modern.get("catalog_cached", false)) and not modern["snapshot"].has("item_catalog"), "opted-in client receives compact snapshot after full catalog")
	_check(legacy["snapshot"].has("recipes") and legacy["snapshot"].has("item_catalog"), "legacy client keeps complete version-1 snapshot")
	_check(modern["snapshot"]["enemy"] == room.session.snapshot_for_team(0)["enemy"], "compact snapshot preserves private preparation filtering")
	_check(not modern["snapshot"]["enemy"].has("shop") and not modern["snapshot"]["enemy"].has("bag"), "opponent economy is never exposed by cache")
	_check(Protocol.decode(Protocol.encode(modern), Protocol.MAX_SERVER_MESSAGE) == modern, "compact messages retain version-1 binary framing")
	server.messages.clear()
	server._broadcast_room_snapshots(room, true)
	_check(server.snapshots(1)[0]["snapshot"].has("item_catalog"), "forced full state refresh includes catalog again")

func _test_backpressure_and_phase_changes() -> void:
	var fixture: Array = _recording_room()
	var server: RecordingServer = fixture[0]
	var room: Server.RoomData = fixture[1]
	server.blocked_clients = [1]
	server._broadcast_room_snapshots(room, true)
	_check(server.snapshots(1).is_empty() and server.snapshots(2).size() == 1, "slow recipient does not queue obsolete snapshot or block opponent")
	_check(bool(server.clients[0].get("snapshot_pending", false)), "slow recipient keeps a pending latest-state marker")
	server._process_room_command(room, 0, "reroll", {})
	server._update_rooms(0.0)
	server.blocked_clients.clear()
	server._update_rooms(0.0)
	_check(server.snapshots(1).size() == 1, "cleared backpressure sends one newest snapshot")
	var recovered: Dictionary = server.snapshots(1)[0]["snapshot"]
	_check(recovered["own"]["gold"] == room.session.teams[0]["gold"], "retry contains authoritative state after pending command")
	_check(recovered.has("item_catalog"), "initial full catalog is retained across backpressure")
	server.messages.clear()
	_command(room.session, 0, "ready")
	_command(room.session, 1, "ready")
	server._update_rooms(0.0)
	_check(server.snapshots(1).size() == 1 and server.snapshots(1)[0]["snapshot"]["phase"] == "combat", "phase transition sends combat immediately below periodic interval")
	_check(server.snapshots(1)[0]["snapshot"].has("item_catalog"), "phase transition sends complete state")
	server.messages.clear()
	for _index: int in range(10):
		server._update_rooms(0.05)
	_check(server.snapshots().size() <= 10, "combat periodic traffic stays within 10 snapshots/sec per client")

func _test_buy_and_equip_in_same_poll() -> void:
	var fixture: Array = _recording_room()
	var server: RecordingServer = fixture[0]
	var room: Server.RoomData = fixture[1]
	room.session.drain_events_by_team()
	var own: Dictionary = room.session.snapshot_for_team(0)["own"]
	var offer: Dictionary = own["shop"][0]
	var unit: Dictionary = own["units"][0]
	server._process_room_command(room, 0, "buy_item", {"offer_id": offer["offer_id"]})
	server._process_room_command(room, 0, "equip", {"unit_id": unit["id"], "item_id": Protocol.BOUGHT_PREFIX + str(offer["offer_id"])})
	server._update_rooms(0.0)
	var after: Dictionary = room.session.snapshot_for_team(0)["own"]
	_check(int(after["gold"]) == int(own["gold"]) - int(offer["price"]), "buy/equip burst charges once")
	_check(after["bag"] == own["bag"] and after["equipment"].get(unit["id"], []).size() == 1, "offer placeholder resolves before coalesced snapshot is sent")
	_check(server.snapshots().size() == 2, "buy/equip burst sends one final state per recipient")
	var own_bought_events: int = 0
	var enemy_bought_events: int = 0
	for entry: Dictionary in server.messages:
		if entry["message"].get("type") != "events":
			continue
		for event: Dictionary in entry["message"]["events"]:
			if event.get("type") == "item_bought":
				if int(entry["client_id"]) == 1:
					own_bought_events += 1
				else:
					enemy_bought_events += 1
	_check(own_bought_events == 1 and enemy_bought_events == 0, "coalescing preserves private economic event delivery")

func _test_loopback_metrics() -> void:
	var server: Server = Server.new()
	var error: Error = server.listen(8936)
	_check(error == OK, "loopback listener starts")
	if error != OK:
		return
	var first: Client = Client.new()
	var second: Client = Client.new()
	first.start_matchmaking("ws://127.0.0.1:8936", "Perf1")
	second.start_matchmaking("ws://127.0.0.1:8936", "Perf2")
	for _index: int in range(180):
		server.step(0.025)
		first.step(0.025)
		second.step(0.025)
	_check(first.is_in_match() and second.is_in_match(), "two loopback clients join actual WebSocket room")
	var metrics: Dictionary = first.get_network_metrics()
	_check(int(metrics["rx_bytes"]) > 0 and int(metrics["tx_bytes"]) > 0, "real socket diagnostics count incoming and outgoing payload")
	_check(int(metrics["snapshots_received"]) > 1 and int(metrics["snapshots_applied"]) > 1, "loopback continues periodic snapshots after initial full state")
	_check(float(metrics["rtt_ms"]) >= 0.0, "compatible server answers a real ping with measured local RTT")
	_check(first.latest_snapshot.has("recipes") and first.latest_snapshot.has("item_catalog"), "live compact snapshots preserve complete UI state")
	_check(first.latest_snapshot["enemy"]["units"].is_empty(), "live preparation keeps opponent current formation hidden")
	_check(first._catalog_cache == second._catalog_cache, "both recipients hydrate same public catalog independently")
	print("LOCAL NETWORK METRICS: ", JSON.stringify(metrics))
	first.reset()
	second.reset()
	server.stop()
