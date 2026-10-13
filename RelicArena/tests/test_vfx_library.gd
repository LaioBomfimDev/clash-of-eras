extends SceneTree
## Headless: conta falhas, lê somente os assets exportados e sempre encerra.

const VfxLibrary = preload("res://client/vfx_library.gd")
var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	var library: VfxLibrary = VfxLibrary.new()
	library.load_assets()
	_check(library.effects.size() == 17, "seventeen exported effects load")
	var expected: Dictionary = {
		"escudo_danca_01": {"frames": 12, "fps": 10.0, "size": Vector2(43, 43), "offset": Vector2(-21, -43), "columns": 4, "rows": 3, "loop": true, "clip": "part-bubble_shield"},
		"cura_01": {"frames": 11, "fps": 16.0, "size": Vector2(19, 23), "offset": Vector2(-9, -20), "columns": 4, "rows": 3, "loop": false, "clip": "part-cura"},
		"estocada_01": {"frames": 7, "fps": 24.0, "size": Vector2(24, 6), "offset": Vector2(-1, -3), "columns": 3, "rows": 3, "loop": false, "clip": "part-estocada"},
		"foguete_01": {"frames": 11, "fps": 24.0, "size": Vector2(26, 26), "offset": Vector2(-13, -13), "columns": 4, "rows": 3, "loop": false, "clip": "part-fire_blast"},
		"fumaca_01": {"frames": 16, "fps": 10.0, "size": Vector2(29, 7), "offset": Vector2(-13, -3), "columns": 4, "rows": 4, "loop": true, "clip": "part-fumaca"},
		"laco_01": {"frames": 11, "fps": 16.0, "size": Vector2(24, 15), "offset": Vector2(-12, -8), "columns": 4, "rows": 3, "loop": false, "clip": "part-laco"},
		"explosao_02": {"frames": 14, "fps": 18.0, "size": Vector2(131, 103), "offset": Vector2(-75, -68), "columns": 4, "rows": 4, "loop": false, "clip": "whole"},
		"foguete_02": {"frames": 8, "fps": 16.0, "size": Vector2(70, 12), "offset": Vector2(-58, -5), "columns": 3, "rows": 3, "loop": true, "clip": "whole"},
		"fumaca_02": {"frames": 16, "fps": 10.0, "size": Vector2(222, 131), "offset": Vector2(-110, -62), "columns": 4, "rows": 4, "loop": true, "clip": "whole"},
		"anel_fumaca_01": {"frames": 8, "fps": 16.0, "size": Vector2(49, 30), "offset": Vector2(-38, -15), "columns": 3, "rows": 3, "loop": true, "clip": "whole"},
		"charuto_01": {"frames": 12, "fps": 10.0, "size": Vector2(15, 46), "offset": Vector2(-4, -42), "columns": 4, "rows": 3, "loop": true, "clip": "whole"},
		"explosao_03": {"frames": 17, "fps": 18.0, "size": Vector2(240, 207), "offset": Vector2(-120, -132), "columns": 5, "rows": 4, "loop": false, "clip": "whole"},
		"estilhaco_01": {"frames": 10, "fps": 18.0, "size": Vector2(65, 67), "offset": Vector2(-33, -52), "columns": 4, "rows": 3, "loop": false, "clip": "whole"},
		"zumbi_estocada_critica": {"frames": 7, "fps": 24.0, "size": Vector2(34, 12), "offset": Vector2(-5, -6), "columns": 3, "rows": 3, "loop": false, "clip": "whole"},
		"zumbi_inspiracao": {"frames": 7, "fps": 20.0, "size": Vector2(21, 17), "offset": Vector2(-10, -22), "columns": 3, "rows": 3, "loop": false, "clip": "part-inspiracao"},
		"notas_bob_01": {"frames": 6, "fps": 6.0, "size": Vector2(14, 14), "offset": Vector2(-7, -7), "columns": 3, "rows": 2, "loop": true, "clip": "whole"},
		"charutao_snoop_01": {"frames": 4, "fps": 6.0, "size": Vector2(30, 28), "offset": Vector2(-1, -21), "columns": 2, "rows": 2, "loop": true, "clip": "whole"}
	}
	for key: String in expected:
		_test_effect(library, key, expected[key])
	_check(not library.has_effect("unknown") and library.frame_data("unknown", 0.0).is_empty(), "unknown effect has no drawable frame")
	_near(library.duration("unknown"), 0.0, "unknown effect has zero duration")
	_check(library.frame_data("cura_01", NAN).is_empty() and library.frame_data("cura_01", INF).is_empty(), "nonfinite time has no drawable frame")
	_test_safe_clip_selection(library)
	library.load_assets()
	_check(library.effects.size() == 17, "reloading assets is idempotent")
	print("VFX LIBRARY TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.0000001, "%s (got %s expected %s)" % [label, actual, expected])


func _test_effect(library: VfxLibrary, key: String, expected: Dictionary) -> void:
	_check(library.has_effect(key), key + ": loaded")
	if not library.has_effect(key):
		return
	var definition: Dictionary = library.effects[key]
	_check(definition["frames"] == expected["frames"] and definition["fps"] == expected["fps"] and definition["loop"] == expected["loop"], key + ": original clip timing")
	_check(definition["clip"] == expected["clip"] and str(definition["texture_path"]).get_file() == str(expected["clip"]) + ".png", key + ": selected part sheet has no embedded character")
	var first: Dictionary = library.frame_data(key, 0.0)
	_check(first["texture"] is Texture2D and first["size"] == expected["size"] and first["offset"] == expected["offset"], key + ": texture, native size and exported offset")
	_check(first["region"] == Rect2(Vector2.ZERO, expected["size"]) and first["frame_index"] == 0, key + ": first region")
	var texture: Texture2D = first["texture"]
	_check(texture.get_size() == expected["size"] * Vector2(expected["columns"], expected["rows"]), key + ": real sheet dimensions")
	var fps: float = float(expected["fps"])
	var count: int = int(expected["frames"])
	_near(library.duration(key), float(count) / fps, key + ": duration uses clip frames, not parent timeline or padding")
	_check(library.frame_data(key, -1.0)["frame_index"] == 0, key + ": negative time clamps to start")
	_check(library.frame_data(key, 1.0 / fps - 0.000001)["frame_index"] == 0, key + ": before frame boundary")
	_check(library.frame_data(key, 1.0 / fps)["frame_index"] == 1, key + ": exact frame boundary")
	var all_regions_valid: bool = true
	for index: int in range(count):
		var data: Dictionary = library.frame_data(key, (float(index) + 0.25) / fps)
		var region: Rect2 = data["region"]
		all_regions_valid = all_regions_valid and data["frame_index"] == index and Rect2(Vector2.ZERO, texture.get_size()).encloses(region)
		var expected_origin: Vector2 = Vector2(index % int(expected["columns"]), floori(float(index) / int(expected["columns"]))) * (expected["size"] as Vector2)
		all_regions_valid = all_regions_valid and region.position == expected_origin
	_check(all_regions_valid, key + ": every actual clip frame recrops in row-major order")
	_check(library.frame_data(key, library.duration(key) - 0.000001)["frame_index"] == count - 1, key + ": last actual frame excludes unused sheet cells")
	if bool(expected["loop"]):
		_check(library.frame_data(key, library.duration(key))["frame_index"] == 0, key + ": exact loop boundary wraps")
		_check(library.frame_data(key, library.duration(key) * 3.0 + 1.25 / fps)["frame_index"] == 1, key + ": repeated loop preserves frame cadence")
	else:
		_check(library.frame_data(key, library.duration(key)).is_empty() and library.frame_data(key, library.duration(key) + 10.0).is_empty(), key + ": one-shot stops at its exact duration")


func _test_safe_clip_selection(library: VfxLibrary) -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VfxLibrary.MANIFEST_PATH))
	var shield: Dictionary = (manifest["effects"] as Array)[0].duplicate(true)
	shield["clip"] = "whole-with-sprite"
	_check(library._load_effect(shield).is_empty(), "explicit whole-with-sprite request is rejected")
	shield["clip"] = "missing-part"
	_check(library._load_effect(shield).is_empty(), "missing requested part never falls back to another clip")
	shield["clip"] = "part-bubble_shield"
	shield["character_embedded"] = true
	_check(library._load_effect(shield).is_empty(), "entry marked as embedding a character is rejected")
