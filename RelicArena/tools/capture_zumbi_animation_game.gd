extends SceneTree
## Diagnóstico visual isolado: duas unidades reais e eventos reais da simulação.
## A formação inimiga é aproximada antes do combate apenas nesta sessão de captura.
## Não modifica dados, combate, economia, rede ou saves do projeto.

const MainView = preload("res://client/main.gd")
var saved: Array[String] = []
var evidence: Array[Dictionary] = []
var facing: String = "east"
var expected: Array[String] = ["skill", "walk"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--direction="):
			facing = argument.trim_prefix("--direction=")
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var view: MainView = MainView.new()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.audio.set_enabled(false)
	view.menu_open = false
	var setup: bool = view.session.sim.preparation_setup([
		{"id": 4, "key": "zumbi", "team": 0, "cell": Vector2i(3, 5), "active": true},
		{"id": 101, "key": "obama", "team": 1, "cell": Vector2i(5, 2), "active": true}
	])
	if not setup:
		quit(1)
		return
	var target_cells: Dictionary = {"east": Vector2i(6, 5), "west": Vector2i(0, 5), "north-east": Vector2i(5, 2), "north-west": Vector2i(1, 2)}
	if not target_cells.has(facing):
		quit(1)
		return
	view.session.sim.get_unit(101).cell = target_cells[facing]
	if view.character_bank.has_animation("zumbi", "attack", facing):
		expected.append("attack")
	view.session.events.clear()
	view.session.sim.events.clear()
	if not view.session.sim.start_combat():
		quit(1)
		return
	view.session.phase = "combat"
	view.session._collect_core_events()
	view._consume_events()
	view._refresh()
	view._update_visuals(0.30)
	view._prepare_frame()
	if _body(view).get("animation_state", "") == "skill":
		await _save(view, "skill")
	view._update_visuals(0.50)
	for index: int in range(200):
		view.session.step(0.05)
		view._consume_events()
		view._refresh()
		view._update_visuals(0.05)
		view._prepare_frame()
		var body: Dictionary = _body(view)
		var state: String = str(body.get("animation_state", ""))
		if state in ["walk", "attack"]:
			var path: String = (body["texture"] as Texture2D).resource_path
			if ("/" + facing + "/") not in path and not path.ends_with("_" + facing + ".png"):
				continue # A captura declarada NE/NW precisa mostrar aquele clip real.
		if state == "walk" and (body["texture"] as Texture2D).resource_path.ends_with("frame_000.png"):
			continue # Capturar uma passada, não o primeiro quadro de repouso.
		if state in ["walk", "attack"] and state not in saved:
			await _save(view, state)
		if saved.size() == expected.size() and expected.all(func(action: String) -> bool: return action in saved):
			break
	var output: String = ProjectSettings.globalize_path("res://captures/zumbi_game_%s_evidence_2026-10-13.json" % facing)
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"kind": "isolated visual capture with real simulation events and PNGs", "requested_facing": facing, "required": expected, "captured": saved, "frames": evidence}, "\t"))
	print("ZUMBI GAME ANIMATION CAPTURES: ", saved)
	view.queue_free()
	await process_frame
	quit(0 if saved.size() == expected.size() and expected.all(func(action: String) -> bool: return action in saved) else 1)

func _body(view: MainView) -> Dictionary:
	for entry: Dictionary in view.frame_entries:
		if int(entry["unit"].get("id", -1)) == 4:
			return entry
	return {}

func _save(view: MainView, action: String) -> void:
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path("res://captures/zumbi_game_%s_%s_2026-10-13.png" % [facing, action])
	var image: Image = root.get_texture().get_image()
	if image.save_png(path) != OK:
		return
	saved.append(action)
	var body: Dictionary = _body(view)
	var texture: Texture2D = body["texture"]
	evidence.append({"state": action, "texture": texture.resource_path, "anchor": str(body["anchor"]), "display_scale": body["display_scale"], "elapsed_combat": view.session.sim.elapsed, "path": path})
