extends SceneTree
const MainScene: PackedScene = preload("res://main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error(label)

func _run() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(2))
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	_check(view.snoop_mcp.loaded, "MCP Snoop installed")
	for direction: String in view.art.DIRECTIONS:
		var idle: Texture2D = view.art.texture_for("snoop", direction, 0.0)
		_check(idle != null and idle.resource_path.contains("detalhado_mcp_01/base"), direction + " selects detailed body and embedded cigar")
		var walk: Dictionary = view.snoop_mcp.frame_data("walk", direction, 0.0)
		var later: Dictionary = view.snoop_mcp.frame_data("walk", direction, 0.24)
		_check(walk["texture"] != later["texture"], direction + " moves through articulated walk poses")
		var smoke: Dictionary = view.snoop_mcp.frame_data("smoke", direction, 0.63)
		_check(smoke["texture"].resource_path.contains("/smoke/"), direction + " selects cigar gesture")
		_check(is_equal_approx(view.art.board_scale_for("snoop") * view.art.height_for(smoke["texture"]), 68.0), direction + " preserves board body height")
	var portrait: Texture2D = view.art.portrait_for("snoop")
	_check(portrait != null and portrait.atlas.resource_path.contains("detalhado_mcp_01/base"), "portrait uses detailed face")
	view.menu_open = false
	var unit: Dictionary = {"id": 1, "key": "snoop", "cell": [3, 5], "team": 0, "active": true, "alive": true, "level": 1}
	view.state = {"phase": "combat", "combat": {"units": [unit]}}
	view.visual_directions[1] = "east"
	view.visual_moves[1] = true
	view._prepare_frame()
	var entry: Dictionary = view.frame_entries[0]
	_check(entry["animation_state"] == "walk", "battle selects new walk")
	_check(entry["pose"]["offset"] == Vector2.ZERO and entry["pose"]["angle"] == 0.0, "articulated motion replaces whole-body wobble")
	view.visual_moves[1] = false
	view._prepare_frame()
	_check(view.frame_entries[0]["animation_state"] == "smoke", "resting Snoop performs cigar cycle")
	unit["stun_remaining"] = 1.0
	view._prepare_frame()
	_check(view.frame_entries[0]["animation_state"] == "rest", "stun stops walking and smoking")
	unit["stun_remaining"] = 0.0
	unit["alive"] = false
	view._prepare_frame()
	_check(view.frame_entries[0]["animation_state"] == "rest", "dead Snoop stops moving cigar")
	view.menu_open = true
	view.lobby_subview = "heroes"
	view.lobby_heroes_detail_open = true
	view.lobby_selected_hero_key = "snoop"
	view.lobby_preview_mode = "pose"
	view.lobby_preview_state = "attack"
	view.lobby_preview_direction = "east"
	view.visual_time = 0.63
	view.lobby_signature = ""
	view._refresh()
	view.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://captures/snoop_mcp_01")
		root.get_texture().get_image().save_png("res://captures/snoop_mcp_01/compendio.png")
	print("SNOOP MCP VISUALS: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
