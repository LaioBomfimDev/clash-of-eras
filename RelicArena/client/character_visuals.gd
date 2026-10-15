extends RefCounted
## Somente apresentação. O ciclo de dança existente pode representar qualquer ação.

const DIRECTIONS: Array[String] = ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
## Teste de escala no tabuleiro 1280×720: altura alfa frontal N1 em pixels de tela.
## Não altera PNGs, retratos ou compêndio. A escala base fica fixa entre direções
## e níveis, preservando o crescimento da lâmina e os multiplicadores 1/1.2/1.44.
const BOARD_HEIGHT_TARGETS: Dictionary = {
	"neymar": 68.0, "caramelo": 56.0, "obama": 70.0, "zumbi": 76.0,
	"michael": 68.0, "barbie": 68.0, "ken": 68.0, "elon": 68.0,
	"snoop": 68.0, "lula": 70.0, "bob_marley": 68.0, "rapunzel": 68.0,
	"boss_dev": 160.0, "monstro_olho_tentaculos": 118.0, "slime_lodo_olho": 108.0
}
const STATIC_PATHS: Dictionary = {
	"neymar": "res://assets/characters/neymar/realista_03/original/Idle/rotations/south.png",
	"obama": "res://assets/characters/obama/realista_03/original/Idle/rotations/south.png",
	"caramelo": "res://assets/characters/provisorio/caramelo.png",
	"zumbi": "res://assets/characters/provisorio/zumbi.png",
	"barbie": "res://assets/characters/barbie/realista_03/original/Idle/rotations/south.png",
	"ken": "res://assets/characters/provisorio/ken.png",
	"elon": "res://assets/characters/elon/grande_04/original/Idle/rotations/south.png",
	"snoop": "res://assets/characters/provisorio/snoop.png",
	"lula": "res://assets/characters/provisorio/lula.png",
	"bob_marley": "res://assets/characters/provisorio/bob_marley.png",
	"rapunzel": "res://assets/characters/provisorio/rapunzel.png",
	"boss_dev": "res://assets/characters/boss_dev/game_ready/idle_south.png",
	"monstro_olho_tentaculos": "res://assets/characters/boss_dev/monstros/monstro_olho_tentaculos.png",
	"slime_lodo_olho": "res://assets/characters/boss_dev/monstros/slime_lodo_olho.png",
	"cleopatra": "res://assets/characters/provisorio/cleopatra.png",
	"julio_cesar": "res://assets/characters/provisorio/julio_cesar.png",
	"einstein": "res://assets/characters/provisorio/einstein.png",
	"napoleao": "res://assets/characters/provisorio/napoleao.png",
}
var statics: Dictionary = {}
var metrics: Dictionary = {}
var directional_frames: Dictionary = {}
var rotations: Dictionary = {}
var state_rotations: Dictionary = {}
var fps: float = 10.0
var manifest: Dictionary = {}
var frame_count: int = 0
var character_states: Dictionary = {}
var character_manifest: Dictionary = {}
var directional_texture_count: int = 0
var portraits: Dictionary = {}
## Centro horizontal e topo da cabeça na frente (manifesto), quando a arte tem algo acima dela (lança).
var portrait_focus: Dictionary = {}


func load_assets() -> void:
	for key: String in STATIC_PATHS:
		statics[key] = _load_texture(str(STATIC_PATHS[key]))
	_load_character_directions()
	var manifest_path: String = "res://assets/michael/manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		return
	manifest = parsed
	fps = float(manifest.get("fps", 10.0))
	var entries: Dictionary = manifest.get("directions", {})
	for direction: String in entries:
		var entry: Variant = entries[direction]
		var paths: Array = entry if entry is Array else entry.get("frames", [])
		var loaded: Array[Texture2D] = []
		for path: Variant in paths:
			var texture: Texture2D = _load_texture(_resource_path(str(path)))
			if texture != null:
				if entry is Dictionary and entry.get("anchor", []) is Array and entry["anchor"].size() == 2:
					metrics[texture.get_instance_id()]["anchor"] = Vector2(float(entry["anchor"][0]), float(entry["anchor"][1]))
				loaded.append(texture)
				frame_count += 1
		var stable_height: float = 0.0
		for texture: Texture2D in loaded:
			stable_height = maxf(stable_height, float(metrics[texture.get_instance_id()]["height"]))
		for texture: Texture2D in loaded:
			metrics[texture.get_instance_id()]["height"] = stable_height
		directional_frames[direction] = loaded
		if entry is Dictionary and entry.has("rotation"):
			rotations[direction] = _load_texture(_resource_path(str(entry["rotation"])))
	for state_name: String in manifest.get("states", {}):
		var loaded_rotations: Dictionary = {}
		for direction: String in manifest["states"][state_name].get("rotations", {}):
			loaded_rotations[direction] = _load_texture(_resource_path(str(manifest["states"][state_name]["rotations"][direction])))
		state_rotations[state_name] = loaded_rotations
	rotations = state_rotations.get("Idle", rotations)
	if rotations.has("south"):
		statics["michael"] = rotations["south"]
	elif directional_frames.has("south") and not (directional_frames["south"] as Array).is_empty():
		statics["michael"] = directional_frames["south"][0]


func _resource_path(path: String) -> String:
	return path if path.begins_with("res://") else "res://assets/michael/" + path.trim_prefix("./")


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		var used: Rect2i = texture.get_image().get_used_rect()
		metrics[texture.get_instance_id()] = {"anchor": Vector2(texture.get_width() * 0.5, used.end.y), "height": float(used.size.y), "used_rect": Rect2(used)}
	return texture


func texture_for(key: String, direction: String, visual_time: float, animation_state: String = "idle", level: int = 1) -> Texture2D:
	if key == "michael":
		var frames: Array = directional_frames.get(direction, directional_frames.get("south", []))
		if not frames.is_empty():
			return frames[int(floor(visual_time * fps)) % frames.size()] as Texture2D
		if rotations.has(direction):
			return rotations[direction] as Texture2D
	if key == "boss_dev":
		if animation_state in ["cast", "attack"]:
			if "west" in direction and not "north" in direction:
				var west: Texture2D = statics.get("boss_dev_cast_west_refined", null)
				if west == null:
					west = _load_texture("res://assets/characters/boss_dev/refino_02/cast_south_west.png")
					if west != null:
						metrics[west.get_instance_id()]["anchor"] = Vector2(32, 138)
					statics["boss_dev_cast_west_refined"] = west
				if west != null:
					return west
			if "north" in direction:
				var cast_north_tex: Texture2D = statics.get("boss_dev_cast_north", null)
				if cast_north_tex == null:
					cast_north_tex = _load_texture("res://assets/characters/boss_dev/game_ready/cast_north.png")
					statics["boss_dev_cast_north"] = cast_north_tex
				if cast_north_tex != null:
					return cast_north_tex
			var cast_tex: Texture2D = statics.get("boss_dev_cast_east", null)
			if cast_tex == null:
				cast_tex = _load_texture("res://assets/characters/boss_dev/game_ready/cast_south_east.png")
				statics["boss_dev_cast_east"] = cast_tex
			if cast_tex != null:
				return cast_tex
			return statics.get("boss_dev", null)
	if character_states.has(key):
		var states: Dictionary = character_states[key]
		var directions: Dictionary = states.get(animation_state, states.get("idle", {}))
		if level > 1:
			# Arte própria do nível (ex.: lança maior do Zumbi), quando o manifesto tiver.
			directions = states.get("%s_n%d" % [animation_state, level], directions)
		var frames: Array = directions.get(direction, directions.get("south", []))
		if not frames.is_empty():
			return frames[int(floor(visual_time * fps)) % frames.size()] as Texture2D
	return statics.get(key) as Texture2D


func _load_character_directions() -> void:
	var path: String = "res://assets/characters/manifest.json"
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("Manifesto direcional inválido: " + path)
		return
	character_manifest = parsed
	for key: String in character_manifest.get("characters", {}):
		var definition: Dictionary = character_manifest["characters"][key]
		var states: Dictionary = definition.get("states", {"idle": {"directions": definition.get("directions", {})}})
		var loaded_states: Dictionary = {}
		for state_name: String in states:
			var directions: Dictionary = states[state_name].get("directions", {})
			var loaded_directions: Dictionary = {}
			for direction: String in directions:
				var entry: Variant = directions[direction]
				var paths: Array = [entry] if entry is String else (entry if entry is Array else entry.get("frames", [entry.get("path", "")]))
				var frames: Array[Texture2D] = []
				var anchor: Array = entry.get("anchor", definition.get("anchor", [])) if entry is Dictionary else definition.get("anchor", [])
				for frame_path: Variant in paths:
					var resource_path: String = str(frame_path)
					if not resource_path.begins_with("res://"):
						resource_path = path.get_base_dir().path_join(resource_path)
					var texture: Texture2D = _load_texture(resource_path)
					if texture != null:
						frames.append(texture)
						directional_texture_count += 1
						if anchor.size() == 2:
							metrics[texture.get_instance_id()]["anchor"] = Vector2(float(anchor[0]), float(anchor[1]))
				var stable_height: float = 0.0
				var stable_y: float = 0.0
				for texture: Texture2D in frames:
					stable_height = maxf(stable_height, float(metrics[texture.get_instance_id()]["height"]))
					stable_y = maxf(stable_y, (metrics[texture.get_instance_id()]["anchor"] as Vector2).y)
				for texture: Texture2D in frames:
					metrics[texture.get_instance_id()]["height"] = stable_height
					metrics[texture.get_instance_id()]["anchor"].y = stable_y
				loaded_directions[direction] = frames
			loaded_states[state_name.to_lower()] = loaded_directions
		character_states[key] = loaded_states
		# Retratos acompanham a identidade ativa do manifesto, inclusive novos PNGs de 48px.
		var front: Array = loaded_states.get("idle", {}).get("south", [])
		if not front.is_empty():
			statics[key] = front[0]
		var focus: Variant = definition.get("portrait_focus", [])
		if focus is Array and (focus as Array).size() == 2:
			portrait_focus[key] = Vector2(float(focus[0]), float(focus[1]))
	portraits.clear()


## Recorte da cabeça/ombros da frente original para retratos da loja e do cartão.
## AtlasTexture referencia o PNG existente; nenhum arquivo novo é gravado.
func portrait_for(key: String, width: int = 26, height: int = 24) -> Texture2D:
	var cache_key: String = "%s:%d:%d" % [key, width, height]
	if portraits.has(cache_key):
		return portraits[cache_key] as Texture2D
	var source: Texture2D = statics.get(key) as Texture2D
	if source == null:
		return null
	var image: Image = source.get_image()
	var used: Rect2i = image.get_used_rect()
	var total: float = 0.0
	var count: int = 0
	for y: int in range(used.position.y, mini(used.end.y, used.position.y + 8)):
		for x: int in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a > 0.5:
				total += x
				count += 1
	var center_x: float = float(used.get_center().x)
	var head_top: float = float(used.position.y)
	if count > 0:
		center_x = total / float(count)
	if portrait_focus.has(key):
		center_x = (portrait_focus[key] as Vector2).x
		head_top = (portrait_focus[key] as Vector2).y
	var left: float = clampf(roundf(center_x - width * 0.5), 0.0, float(source.get_width() - width))
	var top: float = clampf(head_top - 1.0, 0.0, float(source.get_height() - height))
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(left, top, width, height)
	portraits[cache_key] = atlas
	return atlas


func anchor_for(texture: Texture2D, key: String) -> Vector2:
	if key == "michael" and manifest.get("anchor", []) is Array and (manifest.get("anchor", []) as Array).size() == 2:
		var anchor: Array = manifest["anchor"]
		return Vector2(float(anchor[0]), float(anchor[1]))
	return metrics.get(texture.get_instance_id(), {}).get("anchor", Vector2(texture.get_width() * 0.5, texture.get_height()))


func height_for(texture: Texture2D) -> float:
	return float(metrics.get(texture.get_instance_id(), {}).get("height", 46.0))


## Cache de recorte de PNG original; a âncora vem do clip, nunca de cada pose.
func register_animation_frame(texture: Texture2D, anchor: Vector2) -> void:
	if texture == null:
		return
	var instance_id: int = texture.get_instance_id()
	if not metrics.has(instance_id):
		var used: Rect2i = texture.get_image().get_used_rect()
		metrics[instance_id] = {"height": float(used.size.y), "used_rect": Rect2(used)}
	metrics[instance_id]["anchor"] = anchor


## Barras/aura mantêm a referência idle do nível, sem oscilar com braços ou lança.
func idle_height_for(key: String, level: int = 1) -> float:
	var idle: Texture2D = texture_for(key, "south", 0.0, "idle", level)
	return height_for(idle) if idle != null else 46.0


## Proporção de apresentação por personagem, referenciada só na frente de nível 1.
func board_scale_for(key: String) -> float:
	var target: float = float(BOARD_HEIGHT_TARGETS.get(key, 0.0))
	var front: Texture2D = statics.get(key) as Texture2D
	if target <= 0.0 or front == null:
		return 1.0
	return target / maxf(height_for(front), 1.0)


## Limites alfa relativos aos pés; seleção usa o mesmo anchor que o desenho.
func bounds_for(texture: Texture2D, key: String, clip_anchor: Variant = null) -> Rect2:
	if texture == null:
		return Rect2(-16, -46, 32, 46)
	var used: Rect2 = metrics.get(texture.get_instance_id(), {}).get("used_rect", Rect2(Vector2.ZERO, texture.get_size()))
	var anchor: Vector2 = clip_anchor if clip_anchor is Vector2 else anchor_for(texture, key)
	return Rect2(used.position - anchor, used.size)


## Vitrines (compêndio) foram calibradas para bonecos de ~52 px; arte maior (lote 04) é reduzida para caber.
func preview_factor(key: String) -> float:
	var front: Texture2D = statics.get(key) as Texture2D
	if front == null:
		return 1.0
	var height: float = height_for(front)
	return 1.0 if height <= 64.0 else 48.0 / height


## Recebe o vetor já sem o achatamento da câmera (x à direita, y em direção à câmera).
func direction_for(delta: Vector2, fallback: String = "south") -> String:
	if delta.length_squared() < 0.0001:
		return fallback
	return DIRECTIONS[posmod(int(round(delta.angle() / (PI / 4.0))), 8)]
