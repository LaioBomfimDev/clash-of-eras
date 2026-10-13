extends SceneTree
## Visualizador isolado: não instancia main nem altera a simulação/manifestos.
## Abrir quando solicitado:
## Godot --path RelicArena --script res://tools/preview_zumbi_animations.gd
## Capturar três ações disponíveis e encerrar: acrescentar -- --capture
## Opções: --direction=east --level=1 --manifest=res://.../manifest.json

const AnimationBank = preload("res://client/character_animation_bank.gd")
const CharacterVisuals = preload("res://client/character_visuals.gd")
const ACTIONS: Array[String] = ["walk", "attack", "skill"]
const LEVEL_SCALE: Array[float] = [1.0, 1.2, 1.44]
const SIZE: Vector2i = Vector2i(1280, 720)
const GOLD: Color = Color("e6c879")

class PreviewCanvas extends Node2D:
	var controller: Variant

	func _process(delta: float) -> void:
		controller._tick(delta)

	func _draw() -> void:
		controller._draw_preview(self)

	func _input(event: InputEvent) -> void:
		controller._handle_input(event)

var bank: AnimationBank = AnimationBank.new()
var art: CharacterVisuals = CharacterVisuals.new()
var canvas: PreviewCanvas
var direction_button: OptionButton
var level_buttons: Array[Button] = []
var manifest_path: String = AnimationBank.DEFAULT_MANIFEST_PATH
var manifest_text: String = ""
var definitions: Dictionary = {}
var direction: String = "east"
var level: int = 1
var elapsed: float = 0.0
var poll_remaining: float = 1.0
var base_scale: float = 76.0 / 123.0
var clip_sizes: Dictionary = {}
var status: String = ""
var highlight_action: String = ""
var capture_running: bool = false
var capture_finished: bool = false


func _initialize() -> void:
	_setup.call_deferred()


func _setup() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--direction="):
			direction = argument.trim_prefix("--direction=")
		elif argument.begins_with("--level="):
			level = clampi(int(argument.trim_prefix("--level=")), 1, 3)
		elif argument.begins_with("--manifest="):
			manifest_path = argument.trim_prefix("--manifest=")
	root.title = "Clash of Eras — Zumbi: estudo de animações"
	root.size = SIZE
	root.content_scale_size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.close_requested.connect(func() -> void: quit())
	canvas = PreviewCanvas.new()
	canvas.controller = self
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	_create_controls()
	art.load_assets()
	base_scale = art.board_scale_for("zumbi")
	_reload_bank()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_all.call_deferred(true)


func _create_controls() -> void:
	_button("REINICIAR · ESPAÇO", Rect2(20, 652, 205, 40), _restart)
	for value: int in [1, 2, 3]:
		var button: Button = _button("NÍVEL %d" % value, Rect2(242 + (value - 1) * 105, 652, 95, 40), _set_level.bind(value))
		level_buttons.append(button)
	direction_button = OptionButton.new()
	direction_button.position = Vector2(565, 652)
	direction_button.size = Vector2(175, 40)
	direction_button.focus_mode = Control.FOCUS_NONE
	direction_button.item_selected.connect(_select_direction)
	canvas.add_child(direction_button)
	_button("RECARREGAR", Rect2(752, 652, 145, 40), _reload_bank)
	_button("CAPTURAR 3 AÇÕES", Rect2(909, 652, 205, 40), _capture_all.bind(false))
	_button("SAIR · ESC", Rect2(1126, 652, 134, 40), func() -> void: quit())


func _button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	canvas.add_child(button)
	return button


func _tick(delta: float) -> void:
	if not capture_running:
		elapsed += maxf(0.0, delta)
		poll_remaining -= delta
		if poll_remaining <= 0.0:
			poll_remaining = 1.0
			var current: String = FileAccess.get_file_as_string(manifest_path) if FileAccess.file_exists(manifest_path) else ""
			if current != manifest_text:
				_reload_bank()
	canvas.queue_redraw()


func _handle_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			_restart()
		KEY_1, KEY_2, KEY_3:
			_set_level(int(event.keycode - KEY_1) + 1)
		KEY_ESCAPE:
			quit()
		_:
			return
	root.set_input_as_handled()


func _restart() -> void:
	elapsed = 0.0
	status = "Reiniciado. Ataque/habilidade têm reprise somente neste visualizador."


func _set_level(value: int) -> void:
	level = clampi(value, 1, 3)
	_restart()
	for index: int in range(level_buttons.size()):
		level_buttons[index].modulate = GOLD if index + 1 == level else Color.WHITE


func _select_direction(index: int) -> void:
	direction = direction_button.get_item_text(index)
	_restart()


func _reload_bank() -> void:
	manifest_text = FileAccess.get_file_as_string(manifest_path) if FileAccess.file_exists(manifest_path) else ""
	var parser: JSON = JSON.new()
	var text: String = manifest_text
	if not text.is_empty() and text.unicode_at(0) == 0xFEFF:
		text = text.substr(1)
	definitions = {}
	if parser.parse(text) == OK and parser.data is Dictionary:
		definitions = parser.data.get("characters", {}).get("zumbi", {}).get("states", {})
	bank.load_assets(manifest_path)
	clip_sizes.clear()
	direction_button.clear()
	var available: Array[String] = []
	for candidate: String in AnimationBank.DIRECTIONS:
		for action: String in ACTIONS:
			if bank.has_animation("zumbi", action, candidate):
				available.append(candidate)
				break
	if available.is_empty():
		direction_button.add_item("aguardando direções")
		direction_button.disabled = true
		direction = "east"
	else:
		direction_button.disabled = false
		if not available.has(direction):
			direction = "east" if available.has("east") else available[0]
		for candidate: String in available:
			direction_button.add_item(candidate)
		direction_button.select(available.find(direction))
	for action: String in ACTIONS:
		for candidate: String in available:
			if not bank.has_animation("zumbi", action, candidate):
				continue
			var info: Dictionary = _clip_info(action, candidate)
			var count: int = (info.get("frames", []) as Array).size()
			var fps: float = float(info.get("fps", 1.0))
			var maximum: Vector2 = Vector2.ONE
			for index: int in range(count):
				var data: Dictionary = bank.frame_data("zumbi", action, candidate, (index + 0.1) / fps)
				if data.is_empty():
					continue
				var texture: Texture2D = data["texture"]
				var used: Rect2i = texture.get_image().get_used_rect()
				var anchor: Vector2 = data["anchor"]
				maximum.x = maxf(maximum.x, used.size.x)
				maximum.y = maxf(maximum.y, anchor.y - used.position.y)
			clip_sizes[action + ":" + candidate] = maximum
	_set_level(level)
	status = "Manifesto relido; somente clips válidos do banco. Atualização automática a cada 1 s."


func _clip_info(action: String, selected_direction: String) -> Dictionary:
	var definition: Dictionary = definitions.get(action, {})
	var entry: Dictionary = definition.get("directions", {}).get(selected_direction, {})
	return {"frames": entry.get("frames", []), "fps": entry.get("fps", definition.get("fps", 0)), "loop": entry.get("loop", definition.get("loop", action == "walk"))}


func _sample_time(action: String) -> float:
	var duration: float = bank.clip_duration("zumbi", action, direction)
	# O banco continua não-loop: só a prévia repete depois de manter o fim por 0,6 s.
	return elapsed if action == "walk" or duration <= 0.0 else fposmod(elapsed, duration + 0.6)


func _inspection_zoom(action: String) -> float:
	var extent: Vector2 = clip_sizes.get(action + ":" + direction, Vector2(123, 123))
	var scale: float = base_scale * LEVEL_SCALE[level - 1]
	return maxf(1.0, minf(2.0, minf(220.0 / maxf(extent.y * scale, 1.0), 352.0 / maxf(extent.x * scale, 1.0))))


func _draw_preview(target: Node2D) -> void:
	target.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), Color("111b25"))
	_text(target, Vector2(20, 35), "ZUMBI · WALK / ATTACK / SKILL", 25, GOLD)
	_text(target, Vector2(20, 62), "Direção: %s   |   Nível %d · escala ×%.2f   |   Frente N1 no tabuleiro: 76 px" % [direction, level, LEVEL_SCALE[level - 1]], 17)
	_text(target, Vector2(20, 86), "Clips N1: níveis 2/3 ampliam o conjunto; lâmina animada própria de cada nível não está sendo simulada.", 15, Color("b8c8d5"))
	_text(target, Vector2(20, 109), status, 14, Color("91a8bd"))
	for index: int in range(ACTIONS.size()):
		_draw_column(target, ACTIONS[index], 20.0 + index * 420.0)
	_text(target, Vector2(20, 714), "ESPAÇO reinicia · 1–3 nível · ESC sai · Capturas leem somente o viewport desta aplicação.", 13, Color("91a8bd"))


func _draw_column(target: Node2D, action: String, x: float) -> void:
	var rect: Rect2 = Rect2(x, 125, 400, 510)
	target.draw_rect(rect, Color("1a2835"))
	target.draw_rect(rect, GOLD if highlight_action == action else Color("334c60"), false, 2.0)
	_text(target, Vector2(x + 16, 153), action.to_upper(), 21, GOLD)
	var available: Array[String] = []
	for candidate: String in AnimationBank.DIRECTIONS:
		if bank.has_animation("zumbi", action, candidate):
			available.append(candidate)
	_text(target, Vector2(x + 16, 175), "Direções: " + (", ".join(available) if not available.is_empty() else "nenhuma"), 13)
	var data: Dictionary = bank.frame_data("zumbi", action, direction, _sample_time(action))
	if data.is_empty():
		_text(target, Vector2(x + 55, 315), "AGUARDANDO QUADROS", 20, Color("c5d1db"))
		_text(target, Vector2(x + 46, 342), "Sem clip válido nesta direção.", 16)
		return
	var info: Dictionary = _clip_info(action, direction)
	var count: int = (info["frames"] as Array).size()
	_text(target, Vector2(x + 16, 198), "%d quadros · %.1f FPS · quadro %d" % [count, float(info["fps"]), int(data["frame_index"])], 14)
	_text(target, Vector2(x + 16, 219), "Loop original" if action == "walk" and bool(info["loop"]) else "Ação única · reprise só nesta prévia", 13, Color("91a8bd"))
	_text(target, Vector2(x + 16, 246), "TAMANHO NO TABULEIRO", 14)
	_draw_sprite(target, data, Vector2(x + 200, 349), base_scale * LEVEL_SCALE[level - 1])
	var zoom: float = _inspection_zoom(action)
	_text(target, Vector2(x + 16, 383), "INSPEÇÃO · %.2f× o tamanho acima" % zoom, 14)
	_draw_sprite(target, data, Vector2(x + 200, 616), base_scale * LEVEL_SCALE[level - 1] * zoom)


func _draw_sprite(target: Node2D, data: Dictionary, feet: Vector2, scale: float) -> void:
	var texture: Texture2D = data["texture"]
	var anchor: Vector2 = data["anchor"]
	target.draw_line(feet + Vector2(-74, 0), feet + Vector2(74, 0), Color("75a9b6"), 1.0)
	target.draw_line(feet + Vector2(0, -7), feet + Vector2(0, 7), Color("75a9b6"), 1.0)
	target.draw_set_transform(feet.round(), 0.0, Vector2(scale, scale))
	target.draw_texture(texture, -anchor)
	target.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _text(target: CanvasItem, at: Vector2, value: String, size: int = 15, color: Color = Color("dde6ec")) -> void:
	target.draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _capture_all(exit_after: bool = false) -> void:
	if capture_running:
		return
	if DisplayServer.get_name() == "headless":
		status = "Captura requer renderizador; não lê a tela do computador."
		if exit_after:
			quit(1)
		return
	for action: String in ACTIONS:
		if not bank.has_animation("zumbi", action, direction):
			status = "Captura completa aguardando WALK, ATTACK e SKILL válidos em " + direction
			if exit_after:
				printerr(status)
				quit(1)
			return
	capture_running = true
	capture_finished = false
	create_timer(20.0).timeout.connect(func() -> void:
		if capture_running and not capture_finished:
			printerr("ZUMBI_PREVIEW_CAPTURE: timeout")
			quit(1))
	var folder: String = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(folder)
	var saved: int = 0
	for action: String in ACTIONS:
		highlight_action = action
		elapsed = bank.clip_duration("zumbi", action, direction) * 0.45
		canvas.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		var name: String = "zumbi_animations_%s_%s_n%d" % [action, direction, level]
		if image == null or image.is_empty() or image.save_png(folder.path_join(name + ".png")) != OK:
			printerr("ZUMBI_PREVIEW_CAPTURE: não salvou " + name)
			continue
		var data: Dictionary = bank.frame_data("zumbi", action, direction, _sample_time(action))
		var anchor: Vector2 = data["anchor"]
		var texture: Texture2D = data["texture"]
		var report: FileAccess = FileAccess.open(folder.path_join(name + ".json"), FileAccess.WRITE)
		if report != null:
			report.store_string(JSON.stringify({"viewport": [1280, 720], "action": action, "direction": direction, "level": level, "clip_art_level": 1,
				"manifest": manifest_path, "texture": texture.resource_path, "frame_index": data["frame_index"], "anchor": [anchor.x, anchor.y],
				"base_scale": base_scale, "level_scale": LEVEL_SCALE[level - 1], "inspection_zoom": _inspection_zoom(action), "sample_time": _sample_time(action)}, "\t"))
			report.close()
		saved += 1
		print("ZUMBI_PREVIEW_CAPTURE: " + folder.path_join(name + ".png"))
	capture_finished = true
	capture_running = false
	highlight_action = ""
	status = "%d capturas do viewport salvas em res://captures." % saved
	_restart()
	if exit_after:
		quit(0 if saved == 3 else 1)
