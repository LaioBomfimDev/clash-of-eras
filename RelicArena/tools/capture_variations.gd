extends SceneTree
## Diagnostic sheet rendered by Godot; the original PNGs are never modified.

const DIRECTIONS: Array[String] = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const KEYS: Array[String] = ["neymar", "caramelo", "obama", "zumbi"]
var textures: Array[Texture2D] = []
var completed: bool = false

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	create_timer(15).timeout.connect(func() -> void:
		if not completed:
			push_error("Variation capture timeout")
			quit(1))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/manifest.json"))
	for key: String in KEYS:
		for direction: String in DIRECTIONS:
			var path: String = manifest["characters"][key]["states"]["idle"]["directions"][direction]
			var source: Image = Image.load_from_file(path)
			if source == null or source.is_empty():
				push_error("Missing original: " + path)
				quit(1)
				return
			textures.append(ImageTexture.create_from_image(source))
	var sheet: Node2D = Node2D.new()
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sheet)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(0, 0, 640, 360), Color("162a30"))
		var font: Font = ThemeDB.fallback_font
		for index: int in range(8):
			sheet.draw_string(font, Vector2(35 + index * 76, 17), DIRECTIONS[index], HORIZONTAL_ALIGNMENT_CENTER, 72, 8, Color("e4c879"))
		for row: int in range(4):
			for column: int in range(8):
				var top: Vector2 = Vector2(35 + column * 76, 26 + row * 81)
				sheet.draw_texture(textures[row * 8 + column], top)
				sheet.draw_string(font, top + Vector2(0, 75), KEYS[row], HORIZONTAL_ALIGNMENT_CENTER, 68, 9, Color("9bd6cc")))
	sheet.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var output: String = ProjectSettings.globalize_path("res://captures/v1_1_variacoes.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var captured: Image = root.get_texture().get_image()
	var result: Error = captured.save_png(output)
	print("VARIATION_CAPTURE: %d poses; %s; result=%d" % [textures.size(), output, result])
	completed = true
	sheet.queue_free()
	textures.clear()
	await process_frame
	quit(0 if result == OK else 1)
