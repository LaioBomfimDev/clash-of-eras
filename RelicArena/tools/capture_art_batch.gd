extends SceneTree
## Diagnóstico de PNGs originais pelo viewport; não modifica os sprites.

const DIRECTIONS: Array[String] = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
var finished: bool = false
var textures: Array[Texture2D] = []
var entries: Array[Dictionary] = []
var keys: Array[String] = []

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	create_timer(20).timeout.connect(func() -> void:
		if not finished:
			push_error("Art capture timeout")
			quit(1))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/manifest.json"))
	if not parsed is Dictionary:
		quit(1)
		return
	var characters: Dictionary = parsed.get("characters", {})
	var reference_directions: Dictionary = {}
	for direction: String in DIRECTIONS:
		reference_directions[direction] = "res://assets/michael/original/Idle/rotations/" + direction + ".png"
	characters = {"michael": {"states": {"idle": {"directions": reference_directions}}}}.merged(characters)
	for key: String in characters:
		keys.append(key)
	for key: String in keys:
		var directions: Dictionary = characters[key].get("states", {}).get("idle", {}).get("directions", {})
		for direction: String in DIRECTIONS:
			var path: String = str(directions.get(direction, ""))
			var source: Image = Image.load_from_file(ProjectSettings.globalize_path(path)) if not path.is_empty() else null
			if source == null or source.is_empty():
				push_error("Missing original: " + path)
				quit(1)
				return
			var used: Rect2i = source.get_used_rect()
			entries.append({"key": key, "direction": direction, "path": path, "canvas": [source.get_width(), source.get_height()], "used": [used.position.x, used.position.y, used.size.x, used.size.y]})
			textures.append(ImageTexture.create_from_image(source))
	root.size = Vector2i(1280, keys.size() * 112 + 42)
	root.content_scale_size = root.size
	var sheet: Node2D = Node2D.new()
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sheet)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, Vector2(root.size)), Color("162a30"))
		var font: Font = ThemeDB.fallback_font
		for column: int in range(8):
			sheet.draw_string(font, Vector2(164 + column * 132, 22), DIRECTIONS[column], HORIZONTAL_ALIGNMENT_CENTER, 112, 13, Color("e4c879"))
		for row: int in range(keys.size()):
			sheet.draw_string(font, Vector2(8, 94 + row * 112), keys[row], HORIZONTAL_ALIGNMENT_LEFT, 145, 19, Color("9bd6cc"))
			for column: int in range(8):
				var texture: Texture2D = textures[row * 8 + column]
				var used: Array = entries[row * 8 + column]["used"]
				var position: Vector2 = Vector2(184 + column * 132, 44 + row * 112)
				sheet.draw_texture_rect(texture, Rect2(position, texture.get_size() * 1.25), false)
				sheet.draw_string(font, position + Vector2(0, 99), "%d px" % int(used[3]), HORIZONTAL_ALIGNMENT_CENTER, 85, 11, Color("839d9b")))
	sheet.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var output: String = ProjectSettings.globalize_path("res://captures/lote_03_direcoes.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var result: Error = root.get_texture().get_image().save_png(output)
	var report: FileAccess = FileAccess.open("res://captures/lote_03_direcoes.json", FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"poses": textures.size(), "entries": entries}, "\t"))
		report.close()
	print("ART_CAPTURE: %d poses; %s; result=%d" % [textures.size(), output, result])
	finished = true
	sheet.queue_free()
	textures.clear()
	await process_frame
	quit(0 if result == OK else 1)
