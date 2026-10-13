extends SceneTree
## Diagnóstico: altera somente sessões descartáveis e a apresentação da fixture.
const Session = preload("res://simulation/match_session.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _run() -> void:
	create_timer(20).timeout.connect(func() -> void: quit(2))
	var session: Session = Session.new(100)
	var rules_before: Dictionary = session.sim.level_rules.duplicate(true)
	var snapshot: Dictionary = session.snapshot_for_team(0)
	snapshot["test_config"]["power_multiplier"][1] = 9.0
	snapshot["test_config"]["copies_for_level"][2] = 99
	print("SNAPSHOT_ALIAS: multiplier=", session.sim.level_multiplier(2), "; max_copies=", session._max_copies())
	_check(session.sim.level_rules == rules_before, "alterar test_config do snapshot preserva regras autoritativas")
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	var view: Node = scene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.audio.set_enabled(false)
	view.call("_start_match")
	for option: Dictionary in view.state["own"]["benefit_options"]:
		if option["kind"] == "gold":
			view.call("_command", "choose_benefit", {"option_id": option["option_id"]})
			break
	for key: String in ["neymar", "elon"]:
		view.session.teams[0]["shop"][3] = view.session._offer(0, 3, "hero", key, key, 0)
		view.session.teams[0]["shop"][3]["offer_id"] += ":review_" + key
		view.call("_command", "recruit", {"offer_id": view.session.teams[0]["shop"][3]["offer_id"]})
	view.call("_fight")
	_check(view.call("_phase") == "combat", "fixture inicia combate por comandos da Session")
	var killed_id: int = -1
	for unit in view.session.sim.units:
		if unit.team == 0 and unit.key == "elon":
			unit.alive = false
			unit.hp = 0.0
			killed_id = unit.id
	view.call("_refresh")
	view.call("_toggle_drawer", "synergies")
	var ranged_text: String = ""
	for child: Node in view.drawer.get_children():
		if child is Label and (child as Label).text.begins_with("Atiradores"):
			ranged_text = (child as Label).text
	var frozen: Array = view.call("_displayed_synergies", "combat", view.state["own"])
	print("DRAWER_SYNERGY: phase=", view.call("_phase"), "; killed_id=", killed_id,
		"; frozen=", frozen[1]["count"], "; preview=", view.state["own"]["synergies"][1]["count"], "; label=", ranged_text)
	_check(int(frozen[1]["count"]) == 2 and int(view.state["own"]["synergies"][1]["count"]) == 1, "morte reduz preview mas preserva formação congelada")
	_check(ranged_text.contains("2 membros"), "gaveta mostra membros da formação congelada durante combate")
	view.queue_free()
	await process_frame
	print("REVIEW REGRESSIONS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
