extends SceneTree
## Testes de apresentação com PNGs em memória; sem simulação, MCP ou geração.
## godot --headless --path RelicArena --script res://tests/test_character_animation_player.gd

const AnimationBank = preload("res://client/character_animation_bank.gd")
const CharacterPlayer = preload("res://client/character_animation_player.gd")

class FixtureBank extends AnimationBank:
	var textures: Dictionary = {}

	func _load_texture(path: String) -> Texture2D:
		return textures.get(path, null) as Texture2D

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	_test_action_clock_and_dedup()
	_test_walk_clock_and_priority()
	_test_interruptions_and_clear()
	_test_missing_assets_and_inputs()
	_test_grounded_stance()
	print("CHARACTER ANIMATION PLAYER TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _bank() -> FixtureBank:
	var bank: FixtureBank = FixtureBank.new()
	var paths: Array[String] = []
	for index: int in range(4):
		var path: String = "res://fixture/player_%d.png" % index
		var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color(float(index) / 4.0, 1.0, 0.5, 1.0))
		bank.textures[path] = ImageTexture.create_from_image(image)
		paths.append(path)
	bank._load_definitions({"characters": {"zumbi": {"states": {
		"walk": {"fps": 4.0, "loop": true, "anchor": [4, 7], "directions": {
			"east": {"frames": paths}, "north": {"frames": paths, "anchor": [3, 6]}
		}},
		"attack": {"fps": 8.0, "anchor": [4, 7], "directions": {"east": {"frames": paths}}},
		"skill": {"fps": 4.0, "anchor": [4, 7], "directions": {"east": {"frames": paths}}}
	}}}})
	return bank


func _unit(unit_id: int = 1) -> Dictionary:
	return {"id": unit_id, "key": "zumbi", "alive": true, "active": true, "stun_remaining": 0.0}


func _test_action_clock_and_dedup() -> void:
	var bank: FixtureBank = _bank()
	var player: RefCounted = CharacterPlayer.new(bank)
	var unit: Dictionary = _unit()
	_check(player.play_action(1, "zumbi", "attack", "east", "1:attack:1"), "new exact attack accepted")
	_frame(player.frame_for(unit, "north", false), "attack", 0, "attack begins at local zero and locks east")
	_check(player.frame_for(unit, "north", false).get("texture") == bank.textures["res://fixture/player_0.png"], "locked attack uses its original exact texture")
	for iteration: int in range(5):
		_frame(player.frame_for(unit, "east", false), "attack", 0, "repeated lookups never advance clock")
	player.advance(0.125)
	_frame(player.frame_for(unit, "north", false), "attack", 1, "client advance reaches frame boundary")
	_check(not player.play_action(1, "zumbi", "attack", "east", "1:attack:1"), "duplicate event stamp rejected")
	_frame(player.frame_for(unit, "east", false), "attack", 1, "duplicate event cannot reset elapsed time")
	for delta: float in [-10.0, 0.0, NAN, INF, -INF]:
		player.advance(delta)
		_frame(player.frame_for(unit, "east", false), "attack", 1, "invalid/nonpositive delta does not change clock")
	player.advance(0.375)
	_check(player.frame_for(unit, "east", false).is_empty(), "finished attack returns idle fallback at exact duration")
	_check(not player.play_action(1, "zumbi", "attack", "east", "1:attack:1"), "finished event remains deduplicated")
	_check(player.play_action(1, "zumbi", "attack", "east", "1:attack:2"), "next authoritative attack can replace action")
	player.advance(0.25)
	_check(player.play_action(1, "zumbi", "attack", "east", "1:attack:3"), "new attack interrupts prior visual action")
	_frame(player.frame_for(unit, "east", false), "attack", 0, "new stamp restarts action at zero")
	_check(not player.play_action(1, "zumbi", "attack", "east", "1:attack:2"), "older accepted stamp cannot replay after a newer attack")
	_check(player.play_action(2, "zumbi", "attack", "east", "1:attack:3"), "stamp is scoped to unit id")
	_check(player.play_action(1, "zumbi", "skill", "east", "1:skill:0"), "explicit skill action accepted")
	player.advance(0.5)
	_frame(player.frame_for(unit, "east", false), "skill", 2, "skill uses its own clip duration and FPS")
	player.advance(0.5)
	_check(player.frame_for(unit, "east", false).is_empty(), "skill ends instead of looping or holding final body pose")


func _test_walk_clock_and_priority() -> void:
	var player: RefCounted = CharacterPlayer.new(_bank())
	var unit: Dictionary = _unit()
	player.advance(20.0)
	_frame(player.frame_for(unit, "east", true), "walk", 0, "entering walk starts at zero instead of global time")
	player.advance(0.25)
	_frame(player.frame_for(unit, "east", true), "walk", 1, "walk advances only from controller clock")
	_check(player.frame_for(unit, "east", true).get("anchor") == Vector2(4, 7), "walk keeps declared anchor")
	player.advance(0.75)
	_frame(player.frame_for(unit, "east", true), "walk", 0, "walk loops at exact duration")
	player.advance(0.5)
	_frame(player.frame_for(unit, "north", true), "walk", 0, "changing direction restarts local walk clock")
	_check(player.frame_for(unit, "north", true).get("anchor") == Vector2(3, 6), "changed direction uses its own explicit anchor")
	player.advance(0.25)
	_frame(player.frame_for(unit, "north", true), "walk", 1, "new direction clock advances normally")
	_check(player.frame_for(unit, "north", false).is_empty(), "stopping walk leaves idle fallback")
	player.advance(4.0)
	_frame(player.frame_for(unit, "north", true), "walk", 0, "walking after stop restarts at zero")
	_check(player.play_action(1, "zumbi", "attack", "east", "attack"), "attack can preempt walk")
	_frame(player.frame_for(unit, "north", true), "attack", 0, "action is prioritized over walking and keeps strike direction")
	player.advance(0.25)
	_frame(player.frame_for(unit, "north", true), "attack", 2, "walking query cannot replace active attack")
	_check(player.frame_for(unit, "north", true).get("anchor") == Vector2(4, 7), "attack anchor stays fixed despite changed facing")
	player.advance(0.25)
	_frame(player.frame_for(unit, "north", true), "walk", 0, "walk resumes at zero after action finishes")
	_frame(player.frame_for(_unit(2), "east", true), "walk", 0, "second unit owns an independent walk clock")
	player.advance(0.25)
	_frame(player.frame_for(_unit(2), "east", true), "walk", 1, "second unit advances independently from queries")
	_check(player.frame_for(unit, "west", true).is_empty(), "missing walk direction does not mirror or reuse north")
	_frame(player.frame_for(unit, "north", true), "walk", 0, "return from missing direction restarts valid walk")


func _test_interruptions_and_clear() -> void:
	for field: String in ["alive", "active", "stun_remaining"]:
		var player: RefCounted = CharacterPlayer.new(_bank())
		var unit: Dictionary = _unit()
		_check(player.play_action(1, "zumbi", "attack", "east", "attack"), "interrupt fixture starts action")
		player.advance(0.125)
		unit[field] = 1.0 if field == "stun_remaining" else false
		_check(player.frame_for(unit, "east", true).is_empty(), "%s interrupts action and walk" % field)
		unit[field] = 0.0 if field == "stun_remaining" else true
		_check(player.frame_for(unit, "east", false).is_empty(), "%s recovery does not resurrect old attack" % field)
		_frame(player.frame_for(unit, "east", true), "walk", 0, "%s recovery starts fresh walk" % field)
		player.advance(0.25)
		unit[field] = 1.0 if field == "stun_remaining" else false
		_check(player.frame_for(unit, "east", true).is_empty(), "%s also interrupts an active walk" % field)
		unit[field] = 0.0 if field == "stun_remaining" else true
		_frame(player.frame_for(unit, "east", true), "walk", 0, "%s interrupted walk cannot resume old clock" % field)
	var player: RefCounted = CharacterPlayer.new(_bank())
	_check(player.play_action(1, "zumbi", "skill", "east", "same"), "clear fixture accepts skill")
	player.advance(0.25)
	player.clear()
	_check(player.frame_for(_unit(), "east", false).is_empty(), "clear drops all active body actions")
	_check(player.play_action(1, "zumbi", "skill", "east", "same"), "clear permits same stamp in new round")
	_frame(player.frame_for(_unit(), "east", false), "skill", 0, "clear resets action clock")
	player.clear()
	_frame(player.frame_for(_unit(), "east", true), "walk", 0, "clear resets walk clock too")
	var changed: Dictionary = _unit()
	changed["key"] = "other"
	_check(player.frame_for(changed, "east", true).is_empty(), "reused unit id cannot borrow previous hero's walk")


func _test_missing_assets_and_inputs() -> void:
	var bank: FixtureBank = _bank()
	var player: RefCounted = CharacterPlayer.new(bank)
	_check(not player.play_action(-1, "zumbi", "attack", "east", "x"), "negative unit id rejected")
	_check(not player.play_action(1, "", "attack", "east", "x"), "empty hero key rejected")
	_check(not player.play_action(1, "zumbi", "attack", "east", ""), "empty event stamp rejected")
	for state: String in ["walk", "idle", "kick", "crit_growth", "ball_hit"]:
		_check(not player.play_action(1, "zumbi", state, "east", "x"), "non-authoritative action trigger rejected: " + state)
	_check(not player.play_action(1, "zumbi", "attack", "north", "x"), "missing exact attack orientation rejected")
	_check(not player.play_action(1, "zumbi", "skill", "west", "x"), "missing exact skill orientation rejected")
	_check(not player.play_action(1, "zumbi", "attack", "", "x"), "empty attack direction rejected")
	_check(player.play_action(1, "zumbi", "attack", "east", "x"), "failed action does not consume event stamp")
	player.advance(0.125)
	_check(not player.play_action(1, "zumbi", "attack", "west", "invalid"), "invalid replacement rejected")
	_frame(player.frame_for(_unit(), "east", false), "attack", 1, "invalid replacement leaves valid action untouched")
	var before: Dictionary = bank.frame_data("zumbi", "attack", "east", 0.0)
	player.frame_for(_unit(), "east", false)
	_check(not before.has("state"), "player never writes presentation state into bank result")
	bank._load_definitions({})
	_check(player.frame_for(_unit(), "east", true).is_empty(), "unloaded asset interrupts safely without stale sprite")
	_check(player.frame_for({}, "east", true).is_empty(), "missing unit identity has no frame")
	var invalid_stun: Dictionary = _unit()
	invalid_stun["stun_remaining"] = NAN
	_check(player.frame_for(invalid_stun, "east", true).is_empty(), "nonfinite status cannot advance body animation")
	var empty_bank: RefCounted = RefCounted.new()
	var invalid_player: RefCounted = CharacterPlayer.new(empty_bank)
	_check(not invalid_player.play_action(1, "zumbi", "attack", "east", "x"), "incompatible injected bank fails safely")
	_check(invalid_player.frame_for(_unit(), "east", true).is_empty(), "incompatible bank leaves caller idle fallback")
	var optional_player: RefCounted = CharacterPlayer.new()
	_check(optional_player.frame_for({"id": 1, "key": "unknown"}, "east", true).is_empty(), "default optional bank safely handles absent hero")


func _test_grounded_stance() -> void:
	var bank: FixtureBank = _bank()
	bank._load_definitions({"characters": {"zumbi": {"states": {
		"stance": {"fps": 1.0, "loop": false, "directions": {
			"east": {"frames": ["res://fixture/player_0.png"], "anchor": [4, 7]}
		}}
	}}}})
	var player: RefCounted = CharacterPlayer.new(bank)
	_frame(player.frame_for(_unit(), "east", false), "stance", 0, "grounded stance replaces portrait during combat pause")
	player.advance(10.0)
	_frame(player.frame_for(_unit(), "east", false), "stance", 0, "stance stays fixed instead of advancing or bobbing")
	_frame(player.frame_for(_unit(), "east", true), "stance", 0, "missing walk clip can retain exact grounded stance")
	_check(player.frame_for(_unit(), "north", false).is_empty(), "stance never substitutes another facing")
	_check(not player.play_action(1, "zumbi", "stance", "east", "x"), "stance cannot be triggered as an attack")
	var unit: Dictionary = _unit()
	unit["alive"] = false
	_check(player.frame_for(unit, "east", false).is_empty(), "death keeps existing death presentation, not stance")
	unit["alive"] = true
	unit["active"] = false
	_check(player.frame_for(unit, "east", false).is_empty(), "preparation and bench preserve original portraits")
	unit["active"] = true
	unit["stun_remaining"] = 1.0
	_check(player.frame_for(unit, "east", false).is_empty(), "stun preserves interrupted presentation")


func _frame(data: Dictionary, state: String, expected: int, label: String) -> void:
	_check(not data.is_empty() and str(data.get("state", "")) == state and int(data.get("frame_index", -1)) == expected, label)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
