extends RefCounted
## Somente apresentação: recorta os clips originais, sem decidir regras de combate.
## O CanvasItem que desenha deve usar TEXTURE_FILTER_NEAREST.

const MANIFEST_PATH: String = "res://assets/vfx/manifest.json"
var effects: Dictionary = {}


func load_assets() -> void:
	effects.clear()
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	var entries: Variant = manifest.get("effects", [])
	if not entries is Array:
		return
	for value: Variant in entries:
		if not value is Dictionary:
			continue
		var key: String = str(value.get("key", ""))
		if key.is_empty() or effects.has(key):
			continue
		var effect: Dictionary = _load_effect(value)
		if not effect.is_empty():
			effects[key] = effect


func has_effect(key: String) -> bool:
	return effects.has(key)


## Para loops, retorna a duração de um ciclo; para desconhecidos, zero.
func duration(key: String) -> float:
	if not effects.has(key):
		return 0.0
	var effect: Dictionary = effects[key]
	return float(effect["frames"]) / float(effect["fps"])


## Offset é relativo ao ponto de reprodução exportado, já incluindo a origem.
## Não subtrair novamente o anchor do canvas nem desenhar células de padding.
func frame_data(key: String, elapsed: float) -> Dictionary:
	if not effects.has(key) or not is_finite(elapsed):
		return {}
	var effect: Dictionary = effects[key]
	var time: float = maxf(0.0, elapsed)
	var clip_duration: float = duration(key)
	if bool(effect["loop"]):
		time = fposmod(time, clip_duration)
	elif time >= clip_duration:
		return {}
	var frame_index: int = mini(int(floor(time * float(effect["fps"]))), int(effect["frames"]) - 1)
	var columns: int = int(effect["columns"])
	var size: Vector2 = effect["size"]
	var origin: Vector2 = Vector2(frame_index % columns, floori(float(frame_index) / columns)) * size
	return {
		"texture": effect["texture"], "region": Rect2(origin, size),
		"offset": effect["offset"], "size": size, "frame_index": frame_index
	}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _load_effect(entry: Dictionary) -> Dictionary:
	# The selected part is authoritative; never fall back to a whole-with-sprite clip.
	var selected: String = str(entry.get("clip", ""))
	if selected.is_empty() or selected == "whole-with-sprite" or bool(entry.get("character_embedded", true)):
		return {}
	var original_path: String = str(entry.get("original_manifest", ""))
	var original: Dictionary = _read_json(original_path)
	var fps: float = float(original.get("fps", 0.0))
	if not is_finite(fps) or fps <= 0.0:
		return {}
	var clips: Variant = original.get("clips", [])
	if not clips is Array:
		return {}
	var clip: Dictionary = {}
	for candidate: Variant in clips:
		if candidate is Dictionary and str(candidate.get("name", "")) == selected:
			clip = candidate
			break
	if clip.is_empty():
		return {}
	var sheets: Variant = clip.get("sheets", [])
	var frame: Variant = clip.get("frame", {})
	var offset: Variant = clip.get("offset", {})
	if not sheets is Array or sheets.size() != 1 or not sheets[0] is Dictionary or not frame is Dictionary or not offset is Dictionary:
		return {}
	var sheet: Dictionary = sheets[0]
	var frames: int = int(clip.get("frames", 0))
	var columns: int = int(sheet.get("columns", 0))
	var rows: int = int(sheet.get("rows", 0))
	var size: Vector2 = Vector2(float(frame.get("w", 0.0)), float(frame.get("h", 0.0)))
	var anchor_offset: Vector2 = Vector2(float(offset.get("x", 0.0)), float(offset.get("y", 0.0)))
	if frames <= 0 or columns <= 0 or rows <= 0 or frames > columns * rows or int(sheet.get("frames", 0)) != frames or int(sheet.get("first_frame", -1)) != 0:
		return {}
	if not size.is_finite() or size.x <= 0.0 or size.y <= 0.0 or size != size.floor() or not anchor_offset.is_finite():
		return {}
	var filename: String = str(sheet.get("file", ""))
	if filename.is_empty() or filename.contains("whole-with-sprite") or filename != filename.get_file():
		return {}
	var texture_path: String = original_path.get_base_dir().path_join(filename)
	if not ResourceLoader.exists(texture_path):
		return {}
	var texture: Texture2D = load(texture_path) as Texture2D
	if texture == null or texture.get_size() != size * Vector2(columns, rows):
		return {}
	return {
		"texture": texture, "texture_path": texture_path, "clip": selected,
		"frames": frames, "fps": fps, "columns": columns, "rows": rows,
		"offset": anchor_offset, "size": size, "loop": bool(clip.get("loop", false))
	}
