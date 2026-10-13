extends SceneTree
## Captura somente o viewport deste jogo para conferir o Zumbi do lote 04 (níveis 1–3 e compêndio).
## Uso: Godot --path RelicArena --script res://tools/capture_zumbi_lote04.gd
## Diagnóstico visual: usa comandos válidos e ofertas grátis injetadas só na sessão local da captura.

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
	# Compêndio: pose de estudo nos níveis 1 e 3.
	view.set("lobby_subview", "heroes")
	view.set("lobby_selected_hero_key", "zumbi")
	view.set("lobby_preview_mode", "pose")
	for level: int in [1, 3]:
		view.set("lobby_preview_level", level)
		view.set("lobby_signature", "")
		view.call("_refresh")
		await _save(view, "lote_04_zumbi_compendio_n%d" % level)
	view.set("lobby_subview", "none")
	view.set("lobby_signature", "")
	view.call("_start_match")
	for option: Dictionary in view.state.get("own", {}).get("benefit_options", []):
		if option.get("kind", "") == "gold":
			view.call("_command", "choose_benefit", {"option_id": option["option_id"]})
			break
	var lineups: Array = [["zumbi", "neymar", "obama", "michael"], ["barbie", "elon", "lula", "snoop"]]
	var command: int = 0
	for team: int in range(2):
		for unit in view.session.sim.units:
			if unit.team == team and unit.active and not lineups[team].has(unit.key):
				command += 1
				view.session.apply_command(team, "zumbi04_%d" % command, "bench", {"unit_id": unit.id})
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
			_recruit(view, 0, "zumbi", command)
			view.call("_consume_events")
			view.call("_refresh")
		for index: int in range(16):
			view.call("_update_visuals", 0.05)
		await _save(view, "lote_04_zumbi_tabuleiro_n%d" % level)
	print("ZUMBI04_CAPTURES: " + ", ".join(saved))
	finished = true
	view.queue_free()
	await process_frame
	quit(0 if saved.size() == 5 else 1)


func _recruit(view: Node, team: int, key: String, command: int) -> bool:
	view.session.teams[team]["shop"][3] = view.session._offer(team, 3, "hero", key, view.specs[key].display_name, 0)
	view.session.teams[team]["shop"][3]["offer_id"] += ":zumbi04_%d" % command
	return bool(view.session.apply_command(team, "zumbi04_r%d" % command, "recruit", {"offer_id": view.session.teams[team]["shop"][3]["offer_id"]}).get("ok", false))


func _save(view: Node, name: String) -> void:
	if view.call("_phase") != "menu":
		view.call("_prepare_frame")
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(folder)
	var frame: Image = root.get_texture().get_image()
	if frame != null and not frame.is_empty() and frame.save_png(folder.path_join(name + ".png")) == OK:
		saved.append(name)
