extends SceneTree
const View = preload("res://client/main.gd")
var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	passed += int(ok)
	failed += int(not ok)
	if not ok:
		push_error("LOBBY_BACKGROUND_FAIL: " + label)


func _run() -> void:
	var view: View = View.new()
	root.add_child(view)
	view.set_process(false)
	_check(view._phase() == "menu" and view.lobby_backdrop.active, "initial lobby activates background")
	_check(view.lobby_backdrop.poster != null and view.lobby_backdrop.poster.get_width() == 1672,
		"user image is present with original resolution")
	_check(view.start_button != null and view.player_name_input != null, "play and nickname remain usable")
	view.eco_mode = true
	view._refresh()
	_check(view.lobby_backdrop.economical, "eco selects a static background")
	view.lobby_subview = "help"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_backdrop.active and view.lobby_root.get_child_count() > 0, "help is accessible over the background")
	view.eco_mode = false
	view.lobby_subview = "none"
	view.lobby_signature = ""
	view._refresh()
	if DisplayServer.get_name() != "headless":
		for frame: int in range(90):
			await process_frame
		_check(view.lobby_backdrop.player != null and view.lobby_backdrop.player.is_playing()
			and view.lobby_backdrop.player.stream_position > 0.1, "native video advances")
		_check(view.lobby_backdrop.player.volume == 0.0, "background does not introduce audio")
		await RenderingServer.frame_post_draw
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--capture="):
				root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	view._start_match()
	_check(not view.lobby_backdrop.active, "starting a match disables lobby media immediately")
	if view.lobby_backdrop.player != null:
		_check(view.lobby_backdrop.player.paused and not view.lobby_backdrop.player.visible,
			"native player is hidden and paused during preparation/combat")
	view._show_menu()
	_check(view.lobby_backdrop.active, "returning to the menu restores its background")
	print("LOBBY_BACKGROUND_RESULT: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(int(failed > 0))
