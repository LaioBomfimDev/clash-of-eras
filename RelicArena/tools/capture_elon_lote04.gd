extends SceneTree
## Captura somente o viewport deste jogo para conferir o Elon Musk do lote 04 (níveis 1–3 e compêndio).
## Uso: Godot --path RelicArena --script res://tools/capture_elon_lote04.gd

var finished: bool = false
var saved: Array[String] = []

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	create_timer(40).timeout.connect(func() -> void:
		if not finished:
			push_error("Captura do viewport excedeu 40 segundos.")
			quit(1))
	if DisplayServer.get_name() == "headless":
		push_error("A captura requer renderizador; testes de regras usam --headless.")
		quit(1)
		return
	var view: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.audio.set_enabled(false)
	
	# Compêndio: Elon Musk nos níveis 1, 2 e 3.
	view.set("lobby_subview", "heroes")
	view.set("lobby_selected_hero_key", "elon")
	view.set("lobby_preview_mode", "pose")
	for level: int in [1, 2, 3]:
		view.set("lobby_preview_level", level)
		view.set("lobby_signature", "")
		view.call("_refresh")
		await _save(view, "lote_04_elon_compendio_n%d" % level)
	
	# Tabuleiro: combate do Elon Musk
	view.set("lobby_subview", "none")
	view.set("lobby_signature", "")
	view.call("_start_match")
	for option: Dictionary in view.state.get("own", {}).get("benefit_options", []):
		if option.get("kind", "") == "gold":
			view.call("_command", "choose_benefit", {"option_id": option["option_id"]})
			break
	
	var lineups: Array = [["elon", "zumbi", "obama", "michael"], ["barbie", "neymar", "lula", "snoop"]]
	var command: int = 0
	for team: int in range(2):
		for unit in view.session.sim.units:
			if unit.team == team and unit.active and not lineups[team].has(unit.key):
				command += 1
				view.session.apply_command(team, "elon04_%d" % command, "bench", {"unit_id": unit.id})
		for key: String in lineups[team]:
			if (view.session.teams[team]["owned"] as Array).has(key):
				continue
			command += 1
			if not _recruit(view, team, key, command):
				push_error("Não foi possível recrutar " + key)
	view.call("_consume_events")
	view.call("_refresh")
	
	for level: int in [1, 2, 3]:
		if level > 1:
			command += 1
			_recruit(view, 0, "elon", command)
			view.call("_consume_events")
			view.call("_refresh")
		await _save(view, "lote_04_elon_tabuleiro_n%d" % level)
	
	print("ELON04_CAPTURES: " + ", ".join(saved))
	finished = true
	quit(0)

func _save(view: Node, filename: String) -> void:
	for frame: int in range(4):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	var folder: String = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_absolute(folder)
	var path: String = folder.path_join(filename + ".png")
	img.save_png(path)
	saved.append(filename)

func _recruit(view: Node, team: int, key: String, command: int) -> bool:
	view.session.teams[team]["gold"] = 999
	view.session.teams[team]["shop"][3] = view.session._offer(team, 3, "hero", key, key, 0)
	view.session.teams[team]["shop"][3]["offer_id"] += ":elon04_%d" % command
	return bool(view.session.apply_command(team, "elon04_r%d" % command, "recruit", {"offer_id": view.session.teams[team]["shop"][3]["offer_id"]}).get("ok", false))
