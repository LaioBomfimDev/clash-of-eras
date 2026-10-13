extends RefCounted
## Banco opcional de quadros originais; não controla ações nem tempo da simulação.
## Schema: characters.<hero>.states.<stance|walk|attack|skill>.{fps,loop,directions}.
## Cada direção declara {frames:[respaths],anchor:[x,y]}; fps/loop/anchor podem
## ser definidos na direção. A âncora vale para todo o clip, nunca por quadro.
## O chamador mantém o visual idle quando frame_data() retorna {}.

const DEFAULT_MANIFEST_PATH: String = "res://assets/characters/animations_manifest.json"
const STATES: Array[String] = ["stance", "walk", "attack", "skill"]
const DIRECTIONS: Array[String] = [
	"south", "south-east", "east", "north-east",
	"north", "north-west", "west", "south-west"
]

var _clips: Dictionary = {}


func load_assets(path: String = DEFAULT_MANIFEST_PATH) -> void:
	_clips.clear()
	if not FileAccess.file_exists(path):
		return
	var text: String = FileAccess.get_file_as_string(path)
	if not text.is_empty() and text.unicode_at(0) == 0xFEFF:
		text = text.substr(1)
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return
	_load_definitions(parser.data)


## Sem direção, informa se existe ao menos um clip da ação; com direção, é exato.
func has_animation(key: String, state: String, direction: String = "") -> bool:
	if not _clips.has(key):
		return false
	var states: Dictionary = _clips[key]
	if not states.has(state):
		return false
	var directions: Dictionary = states[state]
	return not directions.is_empty() if direction.is_empty() else directions.has(direction)


func clip_duration(key: String, state: String, direction: String) -> float:
	var clip: Dictionary = _get_clip(key, state, direction)
	return 0.0 if clip.is_empty() else float(clip["duration"])


## Referências já carregadas para aquecer recortes antes da primeira animação.
## O descritor é novo; os PNGs/âncoras originais continuam os mesmos do clip.
func loaded_frames() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for states: Dictionary in _clips.values():
		for directions: Dictionary in states.values():
			for clip: Dictionary in directions.values():
				for texture: Texture2D in clip["frames"]:
					result.append({"texture": texture, "anchor": clip["anchor"]})
	return result


## Walk pode repetir; attack e skill não repetem e conservam o último quadro.
## Tempo local negativo começa em zero. NaN/Inf não produzem quadro desenhável.
## Não há fallback de direção, espelhamento, escala ou reutilização de outro herói.
func frame_data(key: String, state: String, direction: String, elapsed: float) -> Dictionary:
	if not is_finite(elapsed):
		return {}
	var clip: Dictionary = _get_clip(key, state, direction)
	if clip.is_empty():
		return {}
	var frames: Array[Texture2D] = clip["frames"]
	var duration: float = clip["duration"]
	var time: float = maxf(0.0, elapsed)
	var frame_index: int = frames.size() - 1
	if bool(clip["loop"]):
		time = fposmod(time, duration)
		frame_index = mini(floori(time * float(clip["fps"])), frames.size() - 1)
	elif time < duration:
		frame_index = mini(floori(time * float(clip["fps"])), frames.size() - 1)
	return {
		"texture": frames[frame_index], "anchor": clip["anchor"],
		"frame_index": frame_index, "duration": duration
	}


func _get_clip(key: String, state: String, direction: String) -> Dictionary:
	if not has_animation(key, state, direction) or direction.is_empty():
		return {}
	var states: Dictionary = _clips[key]
	var directions: Dictionary = states[state]
	return directions[direction]


## Separado da leitura de disco para testar o mesmo carregamento com fixtures.
func _load_definitions(manifest: Dictionary) -> void:
	_clips.clear()
	var characters: Variant = manifest.get("characters", {})
	if not characters is Dictionary:
		return
	for raw_key: Variant in characters:
		if not raw_key is String or raw_key.is_empty():
			continue
		var character: Variant = characters[raw_key]
		if not character is Dictionary:
			continue
		var states: Variant = character.get("states", {})
		if not states is Dictionary:
			continue
		for state: String in STATES:
			var definition: Variant = states.get(state, {})
			if not definition is Dictionary:
				continue
			var directions: Variant = definition.get("directions", {})
			if not directions is Dictionary:
				continue
			for direction: String in DIRECTIONS:
				var entry: Variant = directions.get(direction, {})
				if not entry is Dictionary or entry.is_empty():
					continue
				var clip: Dictionary = _load_clip(state, definition, entry)
				if clip.is_empty():
					continue
				var key: String = raw_key
				if not _clips.has(key):
					_clips[key] = {}
				if not _clips[key].has(state):
					_clips[key][state] = {}
				_clips[key][state][direction] = clip


func _load_clip(state: String, definition: Dictionary, entry: Dictionary) -> Dictionary:
	var raw_fps: Variant = entry.get("fps", definition.get("fps", 0.0))
	if not _is_number(raw_fps):
		return {}
	var fps: float = float(raw_fps)
	if not is_finite(fps) or fps <= 0.0:
		return {}
	var raw_anchor: Variant = entry.get("anchor", definition.get("anchor", null))
	if not raw_anchor is Array or raw_anchor.size() != 2:
		return {}
	if not _is_number(raw_anchor[0]) or not _is_number(raw_anchor[1]):
		return {}
	var anchor: Vector2 = Vector2(float(raw_anchor[0]), float(raw_anchor[1]))
	if not is_finite(anchor.x) or not is_finite(anchor.y):
		return {}
	var raw_loop: Variant = entry.get("loop", definition.get("loop", state == "walk"))
	if not raw_loop is bool:
		return {}
	var paths: Variant = entry.get("frames", [])
	if not paths is Array or paths.is_empty():
		return {}
	var frames: Array[Texture2D] = []
	for path: Variant in paths:
		if not path is String or path.is_empty():
			return {}
		var texture: Texture2D = _load_texture(path)
		if texture == null:
			# Não comprimir a sequência ao ignorar um quadro ausente.
			return {}
		frames.append(texture)
	var duration: float = float(frames.size()) / fps
	if not is_finite(duration) or duration <= 0.0:
		return {}
	return {
		"frames": frames, "fps": fps, "loop": bool(raw_loop) and state == "walk",
		"anchor": anchor, "duration": duration
	}


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	return load(path) as Texture2D


func _is_number(value: Variant) -> bool:
	return value is int or value is float
