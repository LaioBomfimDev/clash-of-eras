extends SceneTree
## Captura do viewport no meio de um arrasto (sem soltar). Não lê a tela do computador.
## Uso: Godot --path RelicArena --resolution 1280x720 --script res://tools/capture_drag.gd -- [--item]

const Board = preload("res://client/board_projection.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _push(event: InputEvent) -> void:
	root.push_input(event, true)


func _press(point: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	_push(event)


func _move(point: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_push(event)


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A captura requer renderizador.")
		quit(1)
		return
	var view: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(view)
	await process_frame
	view.audio.set_enabled(false)
	view.call("_start_match")
	for option: Dictionary in view.state["own"]["benefit_options"]:
		if option["kind"] == "gold":
			view.call("_command", "choose_benefit", {"option_id": option["option_id"]})
	await create_timer(0.5).timeout
	var item_mode: bool = "--item" in OS.get_cmdline_user_args()
	var from: Vector2
	var to: Vector2
	if item_mode:
		var bought: Dictionary = view.call("_command", "buy_item", {"offer_id": view.state["own"]["shop"][0]["offer_id"]})
		await process_frame
		from = (view.bag_buttons[str(bought["data"]["id"])] as Button).get_global_rect().get_center()
		to = Board.project(view.call("_ground_of", view.call("_unit_by_id", 3))) + Vector2(0, -18)
	else:
		from = Board.project(view.call("_ground_of", view.call("_unit_by_id", 1))) + Vector2(0, -18)
		to = Board.cell_position(Vector2i(4, 6))
	_move(from)
	_press(from, true)
	for step: int in range(1, 9):
		_move(from.lerp(to, step / 8.0))
		await process_frame
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path("res://captures/v1_5_arrastar_%s.png" % ("item" if item_mode else "heroi"))
	var result: Error = root.get_texture().get_image().save_png(path)
	print("DRAG_CAPTURE: %s; result=%d" % [path, result])
	_press(to, false)
	await process_frame
	view.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
