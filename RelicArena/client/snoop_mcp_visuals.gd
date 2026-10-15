extends RefCounted
## Arte e movimentos autorados no editor gratuito do MCP PixelLab.
## O charutão acompanha a mão no próprio sprite; não desenhar outro por cima.
const Bank = preload("res://client/character_animation_bank.gd")
const Visuals = preload("res://client/character_visuals.gd")
const MANIFEST: String = "res://assets/characters/snoop/detalhado_mcp_01/manifest.json"
var bank: Bank = Bank.new()
var loaded: bool = false
var visuals: Visuals
var reference_height: float = 109.0

func install(art: Visuals) -> void:
	bank.load_assets(MANIFEST)
	var idle: Dictionary = {}
	for direction: String in Bank.DIRECTIONS:
		var data: Dictionary = bank.frame_data("snoop", "stance", direction, 0.0)
		if data.is_empty() or data.get("texture") == null:
			return
		idle[direction] = [data["texture"]]
	var front: Texture2D = idle["south"][0] as Texture2D
	reference_height = float(front.get_image().get_used_rect().size.y)
	visuals = art
	for direction: String in Bank.DIRECTIONS:
		var data: Dictionary = bank.frame_data("snoop", "stance", direction, 0.0)
		art.register_animation_frame(data["texture"], data["anchor"], reference_height)
	var states: Dictionary = art.character_states.get("snoop", {})
	states["idle"] = idle
	art.character_states["snoop"] = states
	art.statics["snoop"] = front
	art.portrait_focus["snoop"] = Vector2(46, 10)
	for key: String in art.portraits.keys():
		if key.begins_with("snoop:"):
			art.portraits.erase(key)
	loaded = true

func frame_data(state: String, direction: String, elapsed: float) -> Dictionary:
	if not loaded:
		return {}
	var clip_state: String = "stance"
	if state == "walk":
		clip_state = "walk"
	elif state in ["stance", "attack", "skill", "smoke"]:
		clip_state = "attack"
	var duration: float = bank.clip_duration("snoop", clip_state, direction)
	var time: float = fposmod(elapsed, duration) if duration > 0.0 else 0.0
	var data: Dictionary = bank.frame_data("snoop", clip_state, direction, time)
	if not data.is_empty() and data.get("texture") != null:
		visuals.register_animation_frame(data["texture"], data["anchor"], reference_height)
		data["frame_count"] = 1 if clip_state == "stance" else 16
		data["fps"] = 10.0 if clip_state == "stance" else (1000.0 / 60.0 if clip_state == "walk" else 1000.0 / 90.0)
	return data
