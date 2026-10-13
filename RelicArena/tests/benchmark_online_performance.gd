extends SceneTree
## Medições locais repetíveis. Não mede FPS, TLS, internet nem dispositivos físicos.
const Protocol = preload("res://net/online_protocol.gd")
const Perspective = preload("res://net/perspective_mapper.gd")
const Session = preload("res://simulation/match_session.gd")
const Server = preload("res://net/online_server.gd")
const ITERATIONS: int = 400
var command_id: int = 0

class CountingServer extends "res://net/online_server.gd":
	var snapshot_count: int = 0
	var snapshot_bytes: int = 0
	func _send_to_client(_client: Dictionary, message: Dictionary) -> bool:
		if message.get("type") == "snapshot":
			snapshot_count += 1
			snapshot_bytes += Protocol.encode(message).size()
		return true

func _initialize() -> void:
	var preparation: Session = _fixture()
	var combat: Session = _fixture()
	_command(combat, 0, "ready")
	_command(combat, 1, "ready")
	combat.step(1.0)
	if combat.phase != "combat":
		printerr("BENCHMARK FIXTURE: expected active combat")
		quit(1)
		return
	var output: Dictionary = {
		"scope": "Godot headless local; fixed seed; no rendering or internet",
		"godot": Engine.get_version_info()["string"],
		"iterations": ITERATIONS,
		"preparation": _measure_snapshot(preparation),
		"combat": _measure_snapshot(combat),
		"command_burst": _measure_command_burst(preparation),
	}
	var output_path: String = "res://captures/perf_rede_2026_10_13/benchmark_latest.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t") + "\n")
	print("ONLINE PERFORMANCE BENCHMARK: ", JSON.stringify(output))
	quit(0)

func _fixture() -> Session:
	var session: Session = Session.new(20261013)
	session.bot_enabled = false
	session.reset(20261013)
	for team: int in range(2):
		var own: Dictionary = session.snapshot_for_team(team)["own"]
		var option: Dictionary = own["benefit_options"][0]
		_command(session, team, "choose_benefit", {"option_id": option["option_id"]})
		for offer: Dictionary in own["shop"]:
			if offer["kind"] == "hero":
				_command(session, team, "recruit", {"offer_id": offer["offer_id"]})
	return session

func _command(session: Session, team: int, op: String, payload: Dictionary = {}) -> Dictionary:
	command_id += 1
	return session.apply_command(team, "perf_%d" % command_id, op, payload)

func _measure_snapshot(session: Session) -> Dictionary:
	var snapshot: Dictionary = session.snapshot_for_team(1)
	var message: Dictionary = {"type": "snapshot", "snapshot": snapshot}
	var bytes: PackedByteArray = Protocol.encode(message)
	var started: int = Time.get_ticks_usec()
	for _index: int in range(ITERATIONS):
		session.snapshot_for_team(1)
	var build_usec: float = float(Time.get_ticks_usec() - started) / ITERATIONS
	started = Time.get_ticks_usec()
	for _index: int in range(ITERATIONS):
		Protocol.encode(message)
	var encode_usec: float = float(Time.get_ticks_usec() - started) / ITERATIONS
	started = Time.get_ticks_usec()
	for _index: int in range(ITERATIONS):
		Protocol.decode(bytes, Protocol.MAX_SERVER_MESSAGE)
	var decode_usec: float = float(Time.get_ticks_usec() - started) / ITERATIONS
	started = Time.get_ticks_usec()
	for _index: int in range(ITERATIONS):
		Perspective.to_client_snapshot(snapshot, 1)
	var map_usec: float = float(Time.get_ticks_usec() - started) / ITERATIONS
	var cached: Dictionary = snapshot.duplicate()
	cached.erase("recipes")
	cached.erase("item_catalog")
	var cached_message: Dictionary = {"type": "snapshot", "snapshot": cached, "catalog_cached": true}
	var paired_mapping: Dictionary = _paired_mapping(snapshot)
	var paired_transport: Dictionary = _paired_transport(message, cached_message)
	return {
		"phase": session.phase,
		"own_units": snapshot["own"]["units"].size(),
		"combat_units": snapshot["combat"].get("units", []).size(),
		"full_raw_bytes": var_to_bytes(message).size(),
		"full_wire_bytes": bytes.size(),
		"without_static_wire_bytes": Protocol.encode({"type": "snapshot", "snapshot": cached}).size(),
		"negotiated_cached_wire_bytes": Protocol.encode(cached_message).size(),
		"build_mean_usec": build_usec, "encode_mean_usec": encode_usec,
		"decode_mean_usec": decode_usec, "map_team1_mean_usec": map_usec,
		"per_client_payload_bytes_sec_at_10hz": bytes.size() * 10,
		"cached_per_client_payload_bytes_sec_at_10hz": Protocol.encode(cached_message).size() * 10,
		"paired_mapping": paired_mapping,
		"paired_transport": paired_transport,
	}

## Compara os dois algoritmos na mesma execução para reduzir ruído de carga do PC.
## O código anterior é o backup SHA-256 registrado antes da edição.
func _paired_mapping(snapshot: Dictionary) -> Dictionary:
	var previous_script: GDScript = GDScript.new()
	previous_script.source_code = FileAccess.get_file_as_string("res://captures/perf_rede_2026_10_13/perspective_mapper.before.txt")
	if previous_script.reload() != OK:
		return {"error": "baseline mapper could not be compiled"}
	var previous: RefCounted = previous_script.new()
	var current: RefCounted = Perspective.new()
	var samples_before: Array[float] = []
	var samples_after: Array[float] = []
	for sample: int in range(20):
		var order: Array = [previous, current] if sample % 2 == 0 else [current, previous]
		for mapper: RefCounted in order:
			var started: int = Time.get_ticks_usec()
			for _index: int in range(15):
				mapper.call("to_client_snapshot", snapshot, 1)
			var duration: float = float(Time.get_ticks_usec() - started) / 15.0
			if mapper == previous:
				samples_before.append(duration)
			else:
				samples_after.append(duration)
	return {"before_median_usec": _median(samples_before), "after_median_usec": _median(samples_after),
		"samples": 20, "iterations_per_sample": 15, "order": "alternating"}

func _paired_transport(full: Dictionary, cached: Dictionary) -> Dictionary:
	var full_samples: Array[float] = []
	var cached_samples: Array[float] = []
	for sample: int in range(20):
		var order: Array = [full, cached] if sample % 2 == 0 else [cached, full]
		for message: Dictionary in order:
			var started: int = Time.get_ticks_usec()
			for _index: int in range(15):
				Protocol.decode(Protocol.encode(message), Protocol.MAX_SERVER_MESSAGE)
			var duration: float = float(Time.get_ticks_usec() - started) / 15.0
			if message.has("catalog_cached"):
				cached_samples.append(duration)
			else:
				full_samples.append(duration)
	return {"full_encode_decode_median_usec": _median(full_samples),
		"cached_encode_decode_median_usec": _median(cached_samples),
		"samples": 20, "iterations_per_sample": 15, "order": "alternating"}

func _median(samples: Array[float]) -> float:
	samples.sort()
	return (samples[9] + samples[10]) * 0.5

func _measure_command_burst(session: Session) -> Dictionary:
	var server: CountingServer = CountingServer.new()
	server.clients = [{"id": 1}, {"id": 2}]
	var room: Server.RoomData = Server.RoomData.new()
	room.id = "perf_room"
	room.session = session
	room.player_ids = [1, 2]
	server.rooms[room.id] = room
	var unit: Dictionary = session.snapshot_for_team(0)["own"]["units"][0]
	var started: int = Time.get_ticks_usec()
	for _index: int in range(8):
		server._process_room_command(room, 0, "place", {"unit_id": unit["id"], "cell": unit["cell"]})
	server._update_rooms(0.0)
	return {"commands": 8, "snapshots_both_clients": server.snapshot_count,
		"snapshot_wire_bytes_both_clients": server.snapshot_bytes,
		"cpu_usec": Time.get_ticks_usec() - started}
