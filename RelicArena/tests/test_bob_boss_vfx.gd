extends SceneTree
## Integração dos clips, da trajetória e da pose do braço; também permite captura OpenGL.
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
	create_timer(25.0).timeout.connect(func() -> void: quit(2))
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	var source: Dictionary = {"id": 1, "key": "bob_marley", "cell": [2, 4], "level": 1, "active": true, "alive": true}
	var target: Dictionary = {"id": 2, "key": "zumbi", "cell": [3, 3], "level": 1, "active": true, "alive": true}
	view.kit_effects.clear()
	view._spawn_kit_feedback({"type": "hit"}, source, target)
	_check(view.kit_effects.size() == 1, "Bob produces one impact")
	var impact: Dictionary = view.kit_effects[0]
	_check(impact["library_key"] == "bob_impacto_02", "Bob hit uses refined clip")
	_check(is_equal_approx(impact["duration"], 16.0 / 24.0), "Bob plays all sixteen frames")
	impact["life"] = 0.0
	_check(view._library_effect_data(impact).is_empty(), "Bob impact ends without repeating")
	for kind: String in ["red_explosion", "purple_explosion", "fire_tornado", "boss_fire_projectile"]:
		var effect: Dictionary = {"kind": kind, "spell": "red_fire", "position": Vector2(200, 200), "from": Vector2(200, 200), "destination": Vector2(100, 200), "duration": 0.8, "life": 0.4}
		var data: Dictionary = view._refined_boss_vfx_data(effect)
		_check(not data.is_empty(), kind + " uses refined animation")
		if kind == "boss_fire_projectile":
			_check(data["position"].is_equal_approx(Vector2(150, 200)), "projectile follows trajectory")
			_check(is_equal_approx(absf(data["angle"]), PI), "left projectile points toward target")
			effect["spell"] = "purple_fire"
			_check(view._refined_boss_vfx_data(effect)["texture"] != data["texture"], "purple projectile has distinct artwork")
		elif kind.ends_with("explosion"):
			_check(data["frame_index"] == 8, "explosion follows event lifetime")
	_check(view._refined_boss_vfx_data({"kind": "bite"}).is_empty(), "other characters retain their rendering")
	var boss: Dictionary = {"id": 999, "key": "boss_dev", "level": 1, "cell": [4, 1], "active": true, "alive": true, "team": 1}
	view.state = {"phase": "combat", "combat": {"units": [boss]}}
	view.menu_open = false
	view.visual_directions[999] = "south-west"
	view.visual_attacks[999] = {"remaining": 0.4, "duration": 0.55, "direction": Vector2.LEFT}
	view._prepare_frame()
	var entry: Dictionary = view.frame_entries[0]
	_check(entry["texture"].resource_path.ends_with("refino_02/cast_south_west.png"), "Boss selects corrected left arm")
	_check(entry["anchor"] == Vector2(32, 138), "feet remain the pose origin")
	_check(is_equal_approx(view.art.height_for(entry["texture"]) * entry["display_scale"], 160.0), "higher resolution pose remains 160 pixels tall")
	_check(is_equal_approx(entry["height"], 160.0), "Boss health bar retains stable height")
	view.visual_attacks.clear()
	view._prepare_frame()
	_check(is_equal_approx(view.frame_entries[0]["height"], 160.0), "idle retains same height")
	# Captura do compêndio real, usando o renderer do jogo.
	view.state = {}
	view.menu_open = true
	view.lobby_subview = "heroes"
	view.lobby_heroes_detail_open = true
	view.lobby_selected_hero_key = "bob_marley"
	view.visual_time = 3.1
	view.lobby_signature = ""
	view._refresh()
	view.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://captures/refino_bob_boss_02")
		root.get_texture().get_image().save_png("res://captures/refino_bob_boss_02/bob_compendio.png")
	print("BOB BOSS VFX: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
