extends SceneTree
## Contratos de atualização do cliente: estado recente, interações e feedback.
## Rede é fixture; não mede latência real, equilíbrio nem FPS de aparelho físico.

const MainView = preload("res://client/main.gd")
const Session = preload("res://simulation/match_session.gd")

class CountedView extends MainView:
	var ui_refreshes: int = 0

	func _refresh_shop(own: Dictionary, prep: bool) -> void:
		ui_refreshes += 1
		super._refresh_shop(own, prep)

class CountedSession extends Session:
	var snapshots: int = 0

	func snapshot_for_team(team: int) -> Dictionary:
		snapshots += 1
		return super.snapshot_for_team(team)

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("CLIENT_PERFORMANCE_FAIL: " + label)


func _run() -> void:
	var view: CountedView = CountedView.new()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	var authority: CountedSession = CountedSession.new()
	view.session = authority
	view._start_match()
	var benefit: Dictionary = view.state["own"]["benefit_options"][0]
	view._command("choose_benefit", {"option_id": benefit["option_id"]})
	for offer: Dictionary in view.state["own"]["shop"]:
		if offer.get("kind", "") == "hero":
			view._command("recruit", {"offer_id": offer["offer_id"]})
			break
	_check(view._active_count() == 1, "fixture recruits through the real authoritative command")
	authority.snapshots = 0
	view._process(1.0 / 60.0)
	_check(authority.snapshots == 1, "one local frame obtains one authoritative snapshot")
	view.is_online_match = true
	var first: Dictionary = authority.snapshot_for_team(0)
	var latest: Dictionary = first.duplicate(true)
	first["own"]["gold"] = 37
	latest["own"]["gold"] = 43
	view.ui_refreshes = 0
	view.online_client.snapshot_received.emit(first)
	view.online_client.snapshot_received.emit(latest)
	_check(view.ui_refreshes == 0, "snapshot burst does not rebuild the UI inside network callbacks")
	view._process(1.0 / 60.0)
	_check(view.ui_refreshes == 1 and view.gold_label.text == "43", "next frame shows latest authoritative gold once")
	var old_snapshot_count: int = authority.snapshots
	for frame: int in range(5):
		view._process(1.0 / 60.0)
	_check(view.ui_refreshes == 1, "frames without a new snapshot preserve UI nodes")
	_check(authority.snapshots == old_snapshot_count, "online frames never read or step a local authority")
	var unit: Dictionary = view.state["own"]["units"][0]
	view._select_unit(int(unit["id"]))
	_check(view.unit_card.visible and view.selected_id == int(unit["id"]), "inspection responds immediately without waiting for network")
	_check(view.ui_refreshes == 2, "explicit local selection refreshes UI immediately")
	_check(not view.performance_label.visible, "HUD diagnostic starts hidden")
	view._toggle_performance_diagnostics()
	_check(view.performance_label.visible, "diagnostic can be enabled without restarting the match")
	var f3: InputEventKey = InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	view._unhandled_input(f3)
	_check(not view.performance_label.visible, "F3 toggles the optional diagnostic")
	view.toast_text = "MENSAGEM TEMPORÁRIA"
	view.toast_remaining = 0.1
	view._process(0.02)
	_check(view.status_label.text == view.toast_text, "toast appears without new network data")
	view._process(0.2)
	_check(view.status_label.text != view.toast_text, "toast expires without new network data")
	var original_outline: PackedVector2Array = view.hex_outlines_outer[Vector2i(0, 0)].duplicate()
	_check(original_outline[0] == original_outline[-1], "cached hex border remains closed")
	_check(view.character_bank.loaded_frames().all(func(frame: Dictionary) -> bool: return view.art.metrics.has(frame["texture"].get_instance_id())), "body-animation metrics are ready before their first combat frame")
	var original_boss_effects: Array[String] = ["explosao_fogo_roxo", "explosao_fogo_vermelho", "fogo_vermelho_projetil", "fogo_roxo_projetil", "furacao_fogo"]
	_check(original_boss_effects.all(func(key: String) -> bool: return view.boss_vfx_textures.get(key) is Texture2D), "five original boss effects are ready before drawing")
	view.visual_time = 0.4
	view._prepare_frame()
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	_check(view.hex_outlines_outer[Vector2i(0, 0)] == original_outline, "drawing does not mutate cached hex borders")
	view._update_performance(1.0, 1000)
	var metrics: Dictionary = view.get_performance_metrics()
	_check(metrics.has("fps") and metrics.has("p95_frame_ms") and metrics.has("client_cpu_ms"), "diagnostic exposes separate measured frame and CPU metrics")
	metrics["fps"] = -999
	_check(int(view.get_performance_metrics()["fps"]) != -999, "diagnostic output cannot mutate internal metrics")
	_check(not view.lobby_performance_label.text.contains("60 FPS"), "lobby no longer promises a fixed unmeasured 60 FPS")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture=") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	view.queue_free()
	await process_frame
	print("CLIENT_PERFORMANCE_RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
