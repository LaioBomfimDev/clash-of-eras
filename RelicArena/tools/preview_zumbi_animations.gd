extends SceneTree
## Vitrine local de quadros reais. Não executa combate, rede ou gerações.
## --script res://tools/preview_zumbi_animations.gd [-- --capture]

class Stage extends Node2D:
	const Bank = preload("res://client/character_animation_bank.gd")
	const Art = preload("res://client/character_visuals.gd")
	var bank: Bank = Bank.new()
	var art: Art = Art.new()
	var elapsed: float = 0.0
	var level: int = 1
	var paused: bool = false
	var capture_mode: bool = false
	var direction: String = "east"
	const DIRECTIONS: Array[String] = ["east", "west", "north-east", "north-west", "south-east", "south-west", "north", "south"]

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bank.load_assets()
		art.load_assets()

	func _process(delta: float) -> void:
		if not paused:
			elapsed += delta
		queue_redraw()

	func _unhandled_key_input(event: InputEvent) -> void:
		if not event is InputEventKey or not event.pressed or event.echo:
			return
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_SPACE:
				elapsed = 0.0
			KEY_P:
				paused = not paused
			KEY_R:
				bank.load_assets()
				elapsed = 0.0
			KEY_LEFT, KEY_RIGHT:
				var available: Array[String] = []
				for candidate: String in DIRECTIONS:
					if bank.has_animation("zumbi", "walk", candidate) or bank.has_animation("zumbi", "attack", candidate) or bank.has_animation("zumbi", "skill", candidate):
						available.append(candidate)
				if not available.is_empty():
					var step: int = -1 if event.keycode == KEY_LEFT else 1
					direction = available[posmod(available.find(direction) + step, available.size())]
					elapsed = 0.0
			KEY_1, KEY_2, KEY_3:
				level = int(event.keycode - KEY_1) + 1

	func _text(at: Vector2, text: String, size: int = 18, color: Color = Color("e8dfca")) -> void:
		draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("172321"))
		_text(Vector2(42, 52), "ZUMBI — ANIMAÇÕES REAIS / TESTE DE ESCALA", 28, Color("f1d28c"))
		var names: Dictionary = {"east": "Leste", "west": "Oeste", "north-east": "Nordeste", "north-west": "Noroeste", "south-east": "Sudeste", "south-west": "Sudoeste"}
		_text(Vector2(42, 86), "%s · nível %d · PNGs originais preservados" % [names.get(direction, direction), level])
		_text(Vector2(42, 116), "SETAS: direção   ESPAÇO: reiniciar   P: pausar   1–3: nível   R: recarregar   ESC: sair", 16)
		var multiplier: float = pow(1.2, level - 1)
		for index: int in range(3):
			var state: String = ["walk", "attack", "skill"][index]
			var title: String = ["CAMINHADA", "ESTOCADA", "INSPIRAÇÃO"][index]
			var left: float = 24.0 + 416.0 * index
			var center: float = left + 200.0
			draw_rect(Rect2(left, 143, 400, 505), Color("23332e"))
			_text(Vector2(left + 20, 174), title, 22, Color("f1d28c"))
			_text(Vector2(left + 20, 202), "Tamanho usado no tabuleiro", 15)
			var duration: float = bank.clip_duration("zumbi", state, direction)
			if duration <= 0.0:
				_text(Vector2(left + 20, 270), "Aguardando clip revisado", 17)
				continue
			var time: float = fposmod(elapsed, duration + (0.0 if state == "walk" else 0.7))
			if capture_mode:
				time = {"walk": duration * 0.35, "attack": 0.05, "skill": 0.3}[state]
			var frame: Dictionary = bank.frame_data("zumbi", state, direction, time)
			if frame.is_empty():
				continue
			var texture: Texture2D = frame["texture"]
			var anchor: Vector2 = frame["anchor"]
			var feet: Vector2 = Vector2(center, 301)
			draw_rect(Rect2(left + 14, 213, 372, 104), Color("b6a47c"))
			draw_line(Vector2(left + 14, 301), Vector2(left + 386, 301), Color("665b43"))
			var scale: float = art.board_scale_for("zumbi") * multiplier
			draw_texture_rect(texture, Rect2((feet - anchor * scale).round(), texture.get_size() * scale), false)
			_text(Vector2(left + 20, 349), "Ampliação para conferir os detalhes", 15)
			var zoom: float = 2.0 * multiplier
			var zoom_feet: Vector2 = Vector2(center, 602)
			draw_line(Vector2(left + 14, 602), Vector2(left + 386, 602), Color("50634f"))
			draw_texture_rect(texture, Rect2((zoom_feet - anchor * zoom).round(), texture.get_size() * zoom), false)
			_text(Vector2(left + 20, 632), "Quadro %d" % int(frame["frame_index"]), 14)
		_text(Vector2(42, 685), "Só clips revisados por direção. Lâminas animadas N2/N3 e vistas faltantes continuam em produção.", 16)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var stage: Stage = Stage.new()
	root.add_child(stage)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--direction="):
			stage.direction = argument.trim_prefix("--direction=")
	if "--capture" not in OS.get_cmdline_user_args():
		return
	if DisplayServer.get_name() == "headless":
		push_error("A captura precisa do renderizador; a vitrine não altera o jogo.")
		quit(1)
		return
	stage.capture_mode = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(folder)
	var frame: Image = root.get_texture().get_image()
	var status: Error = frame.save_png(folder.path_join("zumbi_animacoes_%s_2026-10-13.png" % stage.direction))
	print("ZUMBI ANIMATION PREVIEW CAPTURE: ", status)
	quit(0 if status == OK else 1)
