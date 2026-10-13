extends SceneTree
## Fixtures somente em memória; não dependem de animações pagas nem escrevem assets.
## Executar: godot --headless --path . --script res://tests/test_character_animation_bank.gd

const AnimationBank = preload("res://client/character_animation_bank.gd")

class FixtureBank extends AnimationBank:
	var textures: Dictionary = {}

	func _load_texture(path: String) -> Texture2D:
		return textures.get(path, null) as Texture2D

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	var bank: FixtureBank = _fixture_bank()
	_test_timing(bank)
	_test_anchor_and_direction(bank)
	_test_skill(bank)
	_test_invalid_clips(bank)
	_test_optional_manifest(bank)
	print("CHARACTER ANIMATION BANK TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _fixture_bank() -> FixtureBank:
	var bank: FixtureBank = FixtureBank.new()
	for index: int in range(3):
		var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color(float(index) / 2.0, 0.5, 1.0, 1.0))
		bank.textures["res://fixture/frame_%d.png" % index] = ImageTexture.create_from_image(image)
	bank._load_definitions(_manifest())
	return bank


func _manifest() -> Dictionary:
	return {"characters": {"neymar": {"states": {
		"walk": {"fps": 4.0, "loop": true, "directions": {
			"south": {"frames": _paths(), "anchor": [4.0, 7.0]},
			"east": {"frames": _paths(), "fps": 8.0, "anchor": [3.0, 7.0]}
		}},
		"attack": {"fps": 8.0, "loop": false, "anchor": [4.0, 7.0], "directions": {
			"south": {"frames": _paths()}
		}}
	}}}}


func _paths() -> Array[String]:
	return ["res://fixture/frame_0.png", "res://fixture/frame_1.png", "res://fixture/frame_2.png"]


func _test_timing(bank: FixtureBank) -> void:
	_check(bank.has_animation("neymar", "walk"), "action query accepts at least one direction")
	_check(bank.has_animation("neymar", "attack", "south"), "exact attack direction exists")
	_near(bank.clip_duration("neymar", "walk", "south"), 0.75, "walk duration uses clip FPS")
	_near(bank.clip_duration("neymar", "walk", "east"), 0.375, "direction overrides FPS")
	_near(bank.clip_duration("neymar", "attack", "south"), 0.375, "attack duration independent of walk")
	_frame(bank, "walk", "south", 0.0, 0, "walk starts on frame zero")
	_frame(bank, "walk", "south", 0.249, 0, "walk holds frame until its boundary")
	_frame(bank, "walk", "south", 0.25, 1, "walk advances at local FPS")
	_frame(bank, "walk", "south", 0.749, 2, "walk reaches final frame")
	_frame(bank, "walk", "south", 0.75, 0, "walk loops at exact duration")
	_frame(bank, "walk", "south", 1.0, 1, "walk loops with remainder")
	_frame(bank, "walk", "east", 0.125, 1, "direction uses its own frame rate")
	_frame(bank, "attack", "south", 0.125, 1, "attack advances at its own FPS")
	_frame(bank, "attack", "south", 0.375, 2, "attack clamps at exact duration")
	_frame(bank, "attack", "south", 1000.0, 2, "attack holds final frame after completion")
	_frame(bank, "attack", "south", 1.0e300, 2, "large finite attack time avoids integer overflow")
	_frame(bank, "walk", "south", -10.0, 0, "negative elapsed clamps to first frame")
	_frame(bank, "attack", "south", -10.0, 0, "negative attack elapsed clamps to first frame")
	for elapsed: float in [NAN, INF, -INF]:
		_check(bank.frame_data("neymar", "walk", "south", elapsed).is_empty(), "nonfinite walk time rejected")
		_check(bank.frame_data("neymar", "attack", "south", elapsed).is_empty(), "nonfinite attack time rejected")
	var huge_loop: Dictionary = bank.frame_data("neymar", "walk", "south", 1.0e300)
	_check(not huge_loop.is_empty() and int(huge_loop.get("frame_index", -1)) in range(3), "large finite loop remains a valid index")
	var definition: Dictionary = _manifest()
	definition["characters"]["neymar"]["states"]["attack"]["loop"] = true
	bank._load_definitions(definition)
	_frame(bank, "attack", "south", 0.75, 2, "attack never loops even if manifest requests it")
	definition["characters"]["neymar"]["states"]["walk"]["loop"] = false
	bank._load_definitions(definition)
	_frame(bank, "walk", "south", 1.0, 2, "walk may explicitly be non-loop")
	bank._load_definitions(_manifest())


func _test_anchor_and_direction(bank: FixtureBank) -> void:
	for index: int in range(3):
		var data: Dictionary = bank.frame_data("neymar", "walk", "south", float(index) / 4.0)
		_check(data.get("anchor") == Vector2(4, 7), "anchor stays stable on frame %d" % index)
		_check(data.get("texture") == bank.textures[_paths()[index]], "original texture order preserved on frame %d" % index)
		_near(float(data.get("duration", -1.0)), 0.75, "frame includes complete clip duration")
	var east: Dictionary = bank.frame_data("neymar", "walk", "east", 0.0)
	_check(east.get("anchor") == Vector2(3, 7), "direction has an explicit independent anchor")
	_check(not bank.has_animation("neymar", "walk", "west"), "missing orientation not invented")
	_check(bank.frame_data("neymar", "walk", "west", 0.0).is_empty(), "missing west does not mirror east")
	_check(bank.frame_data("neymar", "attack", "east", 0.0).is_empty(), "missing attack does not borrow idle or south")
	_check(bank.frame_data("neymar", "walk", "", 0.0).is_empty(), "frame lookup requires exact direction")
	_check(bank.frame_data("unknown", "walk", "south", 0.0).is_empty(), "unknown hero does not borrow another hero")
	_check(bank.frame_data("michael", "walk", "south", 0.0).is_empty(), "independent Michael bank is not imported implicitly")
	_check(bank.frame_data("neymar", "idle", "south", 0.0).is_empty(), "idle remains responsibility of existing visual loader")
	_check(not bank.has_animation("unknown", "walk"), "unknown hero action query is false")
	_check(not bank.has_animation("neymar", "unknown"), "unknown state query is false")
	_near(bank.clip_duration("neymar", "attack", "east"), 0.0, "absent direction has no duration")
	_near(bank.clip_duration("unknown", "walk", "south"), 0.0, "absent hero has no duration")


func _test_invalid_clips(bank: FixtureBank) -> void:
	for fps: Variant in [0.0, -1.0, NAN, INF, -INF, "8", true]:
		var definition: Dictionary = _manifest()
		definition["characters"]["neymar"]["states"]["walk"]["directions"]["south"]["fps"] = fps
		bank._load_definitions(definition)
		_check(not bank.has_animation("neymar", "walk", "south"), "invalid FPS rejects clip: %s" % str(fps))
		_check(bank.has_animation("neymar", "attack", "south"), "invalid walk does not discard valid attack")
	for anchor: Variant in [null, [], [4], [4, 7, 9], ["4", 7], [NAN, 7], [4, INF]]:
		var definition: Dictionary = _manifest()
		definition["characters"]["neymar"]["states"]["walk"]["directions"]["south"]["anchor"] = anchor
		bank._load_definitions(definition)
		_check(not bank.has_animation("neymar", "walk", "south"), "invalid or absent explicit anchor rejects clip")
	for paths: Variant in [[], [null], [""], ["res://fixture/frame_0.png", "res://fixture/missing.png"]]:
		var definition: Dictionary = _manifest()
		definition["characters"]["neymar"]["states"]["walk"]["directions"]["south"]["frames"] = paths
		bank._load_definitions(definition)
		_check(not bank.has_animation("neymar", "walk", "south"), "empty or incomplete sequence rejects whole clip")
	var wrong_loop: Dictionary = _manifest()
	wrong_loop["characters"]["neymar"]["states"]["walk"]["loop"] = "true"
	bank._load_definitions(wrong_loop)
	_check(not bank.has_animation("neymar", "walk", "south"), "loop must be a boolean")
	for malformed: Dictionary in [{}, {"characters": []}, {"characters": {"neymar": []}}, {"characters": {"neymar": {"states": []}}}]:
		bank._load_definitions(malformed)
		_check(not bank.has_animation("neymar", "walk"), "malformed definitions fail safely and clear stale clips")
	bank._load_definitions(_manifest())


func _test_skill(bank: FixtureBank) -> void:
	# Fixture visual: não cria uma conjuração nem altera o kit autoritativo.
	var definition: Dictionary = {"characters": {"zumbi": {"states": {
		"skill": {"fps": 4.0, "loop": true, "anchor": [4.0, 7.0], "directions": {
			"east": {"frames": _paths()},
			"north-east": {"frames": _paths(), "fps": 8.0, "anchor": [3.0, 6.0], "loop": true}
		}}
	}}}}
	bank._load_definitions(definition)
	_check(bank.has_animation("zumbi", "skill"), "skill is an accepted optional state")
	_check(bank.has_animation("zumbi", "skill", "east"), "skill exact direction exists")
	_check(not bank.has_animation("zumbi", "skill", "west"), "skill does not invent a direction")
	_near(bank.clip_duration("zumbi", "skill", "east"), 0.75, "skill duration uses its own FPS")
	_near(bank.clip_duration("zumbi", "skill", "north-east"), 0.375, "skill direction overrides FPS")
	_near(bank.clip_duration("zumbi", "skill", "west"), 0.0, "absent skill direction has no duration")
	_frame(bank, "skill", "east", 0.0, 0, "skill starts on first local frame", "zumbi")
	_frame(bank, "skill", "east", 0.249, 0, "skill holds frame before boundary", "zumbi")
	_frame(bank, "skill", "east", 0.25, 1, "skill advances at exact local boundary", "zumbi")
	_frame(bank, "skill", "east", 0.5, 2, "skill reaches final frame", "zumbi")
	_frame(bank, "skill", "east", 0.75, 2, "skill cannot loop at exact duration", "zumbi")
	_frame(bank, "skill", "east", 1000.0, 2, "skill ignores manifest loop and holds final frame", "zumbi")
	_frame(bank, "skill", "east", 1.0e300, 2, "large finite skill time avoids overflow", "zumbi")
	_frame(bank, "skill", "east", -10.0, 0, "negative skill elapsed starts on first frame", "zumbi")
	_frame(bank, "skill", "north-east", 0.125, 1, "skill direction uses its own local FPS", "zumbi")
	_frame(bank, "skill", "north-east", 0.5, 2, "skill cannot loop through direction override", "zumbi")
	for elapsed: float in [NAN, INF, -INF]:
		_check(bank.frame_data("zumbi", "skill", "east", elapsed).is_empty(), "nonfinite skill time rejected")
	for index: int in range(3):
		var data: Dictionary = bank.frame_data("zumbi", "skill", "east", float(index) / 4.0)
		_check(data.get("anchor") == Vector2(4, 7), "skill anchor stays fixed on frame %d" % index)
		_check(data.get("texture") == bank.textures[_paths()[index]], "skill preserves original frame order %d" % index)
		_near(float(data.get("duration", -1.0)), 0.75, "skill frame includes full local duration")
	_check(bank.frame_data("zumbi", "skill", "north-east", 0.0).get("anchor") == Vector2(3, 6), "skill direction keeps its explicit anchor")
	_check(bank.frame_data("zumbi", "skill", "west", 0.0).is_empty(), "skill missing direction leaves idle fallback to caller")
	_check(bank.frame_data("zumbi", "skill", "", 0.0).is_empty(), "skill lookup requires exact direction")
	_check(bank.frame_data("unknown", "skill", "east", 0.0).is_empty(), "skill cannot borrow another hero's clip")
	for invalid: Dictionary in [{"fps": NAN}, {"anchor": [4]}, {"frames": []}, {"loop": "true"}]:
		var malformed: Dictionary = definition.duplicate(true)
		malformed["characters"]["zumbi"]["states"]["skill"]["directions"]["east"].merge(invalid, true)
		bank._load_definitions(malformed)
		_check(not bank.has_animation("zumbi", "skill", "east"), "malformed skill rejects only the affected clip")
		_check(bank.has_animation("zumbi", "skill", "north-east"), "malformed skill preserves its valid sibling direction")
	bank._load_definitions(_manifest())


func _test_optional_manifest(bank: FixtureBank) -> void:
	_check(bank.has_animation("neymar", "walk"), "fixture is loaded before optional manifest check")
	bank.load_assets("res://tests/__absent_character_animations_manifest__.json")
	_check(not bank.has_animation("neymar", "walk"), "missing optional manifest safely clears previous clips")
	_check(bank.frame_data("neymar", "walk", "south", 0.0).is_empty(), "missing manifest leaves idle fallback to caller")
	bank.load_assets("res://tests/__absent_character_animations_manifest__.json")
	_check(not bank.has_animation("neymar", "attack"), "missing manifest reload is idempotent")


func _frame(bank: FixtureBank, state: String, direction: String, elapsed: float, expected: int, label: String, key: String = "neymar") -> void:
	var data: Dictionary = bank.frame_data(key, state, direction, elapsed)
	_check(not data.is_empty() and int(data.get("frame_index", -1)) == expected, label)


func _near(actual: float, expected: float, label: String) -> void:
	_check(is_finite(actual) and absf(actual - expected) < 0.0000001, label)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
