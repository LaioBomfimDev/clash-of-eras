extends SceneTree
## Galeria de apresentação renderizada com os PNGs originais, sem editar assets.

var finished: bool = false
var entries: Array[Dictionary] = []

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	create_timer(20).timeout.connect(func() -> void:
		if not finished:
			push_error("Roster capture timeout")
			quit(1))
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/manifest.json"))
	if not manifest is Dictionary:
		quit(1)
		return
	var characters: Dictionary = manifest.get("characters", {})
	characters = {"michael": {"states": {"idle": {"directions": {"south": "res://assets/michael/original/Idle/rotations/south.png"}}}}}.merged(characters)
	var names: Dictionary = {"michael": "Michael", "neymar": "Neymar", "caramelo": "Caramelo", "obama": "Obama", "zumbi": "Zumbi dos Palmares", "barbie": "Barbie", "ken": "Ken · invocação", "elon": "Elon Musk", "snoop": "Snoop Dogg", "lula": "Lula", "bob_marley": "Bob Marley", "rapunzel": "Rapunzel"}
	for key: String in characters:
		var path: String = str(characters[key].get("states", {}).get("idle", {}).get("directions", {}).get("south", ""))
		var source: Image = Image.load_from_file(ProjectSettings.globalize_path(path)) if not path.is_empty() else null
		if source == null or source.is_empty():
			push_error("Missing original: " + path)
			quit(1)
			return
		var used: Rect2i = source.get_used_rect()
		entries.append({"name": names.get(key, key), "texture": ImageTexture.create_from_image(source), "anchor": Vector2(source.get_width() * 0.5, used.end.y), "realistic": key == "michael" or characters[key].get("art_batch", "") == "realista_03"})
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var sheet: Node2D = Node2D.new()
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sheet)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(0, 0, 1280, 720), Color("13252d"))
		var font: Font = ThemeDB.fallback_font
		sheet.draw_string(font, Vector2(24, 34), "CLASH OF ERAS · ELENCO DO LABORATÓRIO", HORIZONTAL_ALIGNMENT_LEFT, 1220, 25, Color("f4d58a"))
		sheet.draw_string(font, Vector2(24, 58), "PixelLab · proporções adultas · oito direções por personagem", HORIZONTAL_ALIGNMENT_LEFT, 1220, 15, Color("9bbab6"))
		for index: int in range(entries.size()):
			var entry: Dictionary = entries[index]
			var card: Rect2 = Rect2(20 + (index % 4) * 315, 78 + (index / 4) * 209, 295, 196)
			sheet.draw_rect(card, Color("203841"))
			sheet.draw_rect(card, Color("3b5d61"), false, 1.0)
			var texture: Texture2D = entry["texture"]
			var feet: Vector2 = card.position + Vector2(147, 160)
			sheet.draw_line(feet + Vector2(-35, 0), feet + Vector2(35, 0), Color("557779"), 1.0)
			sheet.draw_texture_rect(texture, Rect2(feet - (entry["anchor"] as Vector2) * 2.7, texture.get_size() * 2.7), false)
			sheet.draw_string(font, card.position + Vector2(8, 185), str(entry["name"]), HORIZONTAL_ALIGNMENT_CENTER, 279, 17, Color("e4d7b2"))
			if not bool(entry["realistic"]):
				sheet.draw_string(font, card.position + Vector2(8, 20), "PROVISÓRIO", HORIZONTAL_ALIGNMENT_LEFT, 279, 12, Color("efb079")))
	sheet.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var output: String = ProjectSettings.globalize_path("res://captures/lote_03_elenco.png")
	var result: Error = root.get_texture().get_image().save_png(output)
	print("ROSTER_CAPTURE: %d personagens; result=%d; %s" % [entries.size(), result, output])
	finished = true
	sheet.queue_free()
	entries.clear()
	await process_frame
	quit(0 if result == OK else 1)
