extends SceneTree
## Validação gráfica: cache após lobby oculto, invalidação e botões reais.
const View = preload("res://client/main.gd")
var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	passed += int(ok)
	failed += int(not ok)
	if not ok:
		push_error("RENDER_CACHE_FAIL: " + label)


func _frame(view: View) -> void:
	view._update_arena_cache()
	await RenderingServer.frame_post_draw


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run with a real rendering driver")
		quit(1)
		return
	var view: View = View.new()
	root.add_child(view)
	view.set_process(false)
	await _frame(view)
	_check(not view.arena_render_cache.visible, "menu hides cached arena")
	view._start_match()
	await _frame(view)
	await _frame(view)
	_check(view.arena_render_cache.visible, "arena appears after leaving the lobby")
	var image: Image = view.arena_render_cache.cache_viewport.get_texture().get_image()
	_check(image.get_size() == Vector2i(1280, 720) and image.get_pixel(700, 400).get_luminance() > 0.15,
		"cached arena has rendered sand, not an empty viewport")
	_check(view.gold_pile_layer.static_draw_count == 1 and view.gold_pile_layer.cache_viewport.get_texture().get_image().get_used_rect().size.x > 200,
		"coins are rendered once even when initially hidden in the lobby")
	view._command("choose_benefit", {"option_id": view.state["own"]["benefit_options"][0]["option_id"]})
	for offer: Dictionary in view.state["own"]["shop"]:
		if offer.get("kind", "") == "hero":
			view._command("recruit", {"offer_id": offer["offer_id"]})
	await _frame(view)
	var count: int = view.arena_render_cache.rebuild_count
	await _frame(view)
	_check(view.arena_render_cache.rebuild_count == count, "unchanged preparation reuses the base")
	view._select_unit(int(view.state["own"]["units"][0]["id"]))
	await _frame(view)
	_check(view.arena_render_cache.rebuild_count > count, "selection invalidates placement highlights")
	count = view.arena_render_cache.rebuild_count
	view.hover_cell = Vector2i(7, 7)
	await _frame(view)
	_check(view.arena_render_cache.rebuild_count > count, "hover updates the placement preview")
	view._fight()
	await _frame(view)
	_check(view._phase() == "combat", "real ready command starts combat")
	count = view.arena_render_cache.rebuild_count
	view.visual_time += 2.0
	await _frame(view)
	_check(view.arena_render_cache.rebuild_count == count, "combat does not rebuild static ground each frame")
	view._show_menu()
	await _frame(view)
	_check(not view.arena_render_cache.visible, "return to lobby hides cached ground")
	print("RENDER_CACHE_RESULT: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(int(failed > 0))
