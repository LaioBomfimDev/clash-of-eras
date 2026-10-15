extends SceneTree

const MainScene: PackedScene = preload("res://main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error(message)

func _run() -> void:
	create_timer(25.0).timeout.connect(func() -> void: quit(2))
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.menu_open = false
	var boss: Dictionary = {"id": 999, "key": "boss_dev", "cell": [4, 1], "active": true, "alive": true, "team": 1, "level": 1}
	view.state = {"phase": "combat", "combat": {"units": [boss]}}
	_check(view.boss_motion_bank.has_animation("boss_dev", "walk", "south"), "MCP walk loaded")
	_check(not view.boss_motion_bank.has_animation("boss_dev", "walk", "north"), "does not pretend to have generated back view")
	view._process_game_event({"type": "boss_cast", "source_id": 999, "from": [4, 1], "to": [4, 4], "spell": "red_fire"})
	_check(is_equal_approx(view.visual_attacks[999]["duration"], 19.0 / 24.0), "cast event reserves full raise/hold/return clip")
	view._prepare_frame()
	var first: Dictionary = view.frame_entries[0].duplicate()
	_check(first["texture"].resource_path.ends_with("movimento_mcp_01/cast/frame_000.png"), "cast starts at rest")
	view.visual_attacks[999]["remaining"] -= 4.0 / 24.0
	view._prepare_frame()
	var middle: Dictionary = view.frame_entries[0]
	_check(middle["texture"] != first["texture"], "arm moves through intermediate poses")
	_check(middle["pose"]["angle"] == 0.0 and middle["pose"]["offset"] == Vector2.ZERO, "articulated animation replaces whole-body wobble")
	_check(is_equal_approx(middle["display_scale"], first["display_scale"]), "no frame-by-frame stretching")
	_check(is_equal_approx(middle["height"], 160.0), "Boss bar remains at stable height")
	view.visual_attacks.clear()
	view.visual_directions[999] = "south"
	view.visual_moves[999] = true
	view.visual_time = 0.0
	view._prepare_frame()
	var walk: Dictionary = view.frame_entries[0].duplicate()
	_check(walk["animation_state"] == "walk" and walk["texture"].resource_path.contains("movimento_mcp_01/walk"), "movement selects real MCP walk")
	view.visual_time = 0.25
	view._prepare_frame()
	_check(view.frame_entries[0]["texture"] != walk["texture"], "walk alternates generated poses")
	_check(view.frame_entries[0]["anchor"] == Vector2(45, 116), "walk uses aligned feet origin")
	_check(view.frame_entries[0]["display_scale"] == walk["display_scale"], "walking does not pulse body scale")
	view.visual_moves[999] = false
	view._prepare_frame()
	_check(view.frame_entries[0]["animation_state"] == "idle", "stopping movement restores idle")
	print("BOSS MCP MOTION: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
