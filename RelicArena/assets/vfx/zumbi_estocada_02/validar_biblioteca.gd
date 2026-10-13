extends "res://tests/test_vfx_library.gd"
## Checks the two new clips using the existing VFX runner's contract checks.
## Kept isolated; the shared runner and presentation code are unchanged.


func _initialize() -> void:
	var library: VfxLibrary = VfxLibrary.new()
	library.load_assets()
	_check(library.effects.size() == 15, "fifteen registered effects load")
	_test_effect(library, "zumbi_estocada_critica", {
		"frames": 7, "fps": 24.0, "size": Vector2(34, 12),
		"offset": Vector2(-5, -6), "columns": 3, "rows": 3,
		"loop": false, "clip": "whole"
	})
	_test_effect(library, "zumbi_inspiracao", {
		"frames": 7, "fps": 20.0, "size": Vector2(21, 17),
		"offset": Vector2(-10, -22), "columns": 3, "rows": 3,
		"loop": false, "clip": "part-inspiracao"
	})
	_test_safe_clip_selection(library)
	library.load_assets()
	_check(library.effects.size() == 15, "reloading fifteen registered effects is idempotent")
	print("VFX ZUMBI PILOT TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
