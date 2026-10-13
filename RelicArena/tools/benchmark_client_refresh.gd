extends SceneTree
## Microbenchmark reproduzível do cliente. Não mede internet, GPU nem FPS de navegador.
## Usa snapshots reais de Session e os sinais do transporte, sem abrir conexão.

const MainView = preload("res://client/main.gd")
const Session = preload("res://simulation/match_session.gd")
const SAMPLES: int = 2400
const WARMUP: int = 120

class ProfileView extends MainView:
	var refresh_calls: int = 0

	func _refresh_shop(own: Dictionary, prep: bool) -> void:
		refresh_calls += 1
		super._refresh_shop(own, prep)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var view: Node2D
	var source_label: String = "current"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--baseline-source="):
			var baseline_path: String = argument.trim_prefix("--baseline-source=")
			var baseline: GDScript = GDScript.new()
			baseline.source_code = FileAccess.get_file_as_string(baseline_path).replace("extends Node2D\n", "extends Node2D\nvar refresh_calls: int = 0\n").replace("func _refresh_shop(own: Dictionary, prep: bool) -> void:\n", "func _refresh_shop(own: Dictionary, prep: bool) -> void:\n\trefresh_calls += 1\n")
			if baseline.reload() != OK:
				push_error("BENCHMARK baseline source cannot load")
				quit(1)
				return
			view = baseline.new()
			source_label = "saved_baseline"
	if view == null:
		view = ProfileView.new()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	Engine.max_fps = 0
	view.menu_open = false
	view.is_online_match = true
	var authority: Session = Session.new(MainView.MATCH_SEED)
	var keys: Array[String] = ["zumbi", "michael", "barbie", "elon", "snoop", "bob_marley", "lula", "rapunzel"]
	var roster: Array[Dictionary] = []
	for team: int in range(2):
		for index: int in range(keys.size()):
			roster.append({"id": team * 100 + index + 1, "key": keys[index], "team": team,
				"cell": Vector2i(index, 5 if team == 0 else 2), "active": true})
	if not authority.sim.preparation_setup(roster):
		push_error("BENCHMARK fixture formation rejected")
		quit(1)
		return
	for team: int in range(2):
		authority.teams[team]["owned"] = keys.duplicate()
		authority.teams[team]["capacity"] = 8
		authority.teams[team]["benefit_options"] = []
		authority.teams[team]["copies"] = {}
		for key: String in keys:
			authority.teams[team]["copies"][key] = 1
	authority.phase = "preparation"
	var prep_snapshot: Dictionary = authority.snapshot_for_team(0)
	view.state = prep_snapshot
	view._refresh()
	var reports: Array[Dictionary] = []
	reports.append(_measure(view, prep_snapshot, "online_preparation_20_snapshots_per_60_frames"))
	authority.sim.start_combat()
	authority.phase = "combat"
	var combat_snapshot: Dictionary = authority.snapshot_for_team(0)
	reports.append(_measure(view, combat_snapshot, "online_combat_20_snapshots_per_60_frames"))
	var output: Dictionary = {"godot": Engine.get_version_info()["string"], "display": DisplayServer.get_name(),
		"source": source_label, "samples": SAMPLES, "warmup": WARMUP, "unit_count": roster.size(), "reports": reports,
		"scope": "CPU synchronous _process and snapshot callbacks only; excludes rendering, internet and browser FPS"}
	print("CLIENT_REFRESH_BENCHMARK: " + JSON.stringify(output))
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var file: FileAccess = FileAccess.open(argument.trim_prefix("--output="), FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(output, "\t") + "\n")
	view.queue_free()
	await process_frame
	quit(0)


func _measure(view: Node2D, snapshot: Dictionary, scenario: String) -> Dictionary:
	for index: int in range(WARMUP):
		if index % 3 == 0:
			view.online_client.snapshot_received.emit(snapshot)
		view._process(1.0 / 60.0)
	view.refresh_calls = 0
	var timings: Array[float] = []
	var total_us: int = 0
	for index: int in range(SAMPLES):
		var start: int = Time.get_ticks_usec()
		if index % 3 == 0:
			view.online_client.snapshot_received.emit(snapshot)
		view._process(1.0 / 60.0)
		var elapsed_us: int = Time.get_ticks_usec() - start
		total_us += elapsed_us
		timings.append(float(elapsed_us))
	timings.sort()
	return {"scenario": scenario, "mean_cpu_us": float(total_us) / float(SAMPLES),
		"p50_cpu_us": timings[SAMPLES / 2], "p95_cpu_us": timings[int(SAMPLES * 0.95)],
		"ui_refresh_calls": view.refresh_calls, "snapshot_callbacks": SAMPLES / 3}
