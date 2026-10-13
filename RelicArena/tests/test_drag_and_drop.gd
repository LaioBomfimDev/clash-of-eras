extends SceneTree
## Arrastar e soltar com eventos reais de mouse empurrados no viewport (_input → GUI → _unhandled_input).
## Run: Godot --headless --path RelicArena --script res://tests/test_drag_and_drop.gd
## Não substitui teste humano com mouse/toque em aparelho.

const MainView = preload("res://client/main.gd")
const Board = preload("res://client/board_projection.gd")
var passed: int = 0
var failed: int = 0
var view: MainView


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("DRAG_FAIL: " + label)


func _mouse(point: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	root.push_input(event, true) # coordenadas do jogo (1280×720), independentes da janela


func _move(point: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true) # coordenadas do jogo (1280×720), independentes da janela


## Arrasto em etapas, como uma mão real, aguardando quadros para a interface atualizar.
func _drag(from: Vector2, to: Vector2) -> void:
	_move(from)
	_mouse(from, true)
	for step: int in range(1, 7):
		_move(from.lerp(to, step / 6.0))
		await process_frame
	_mouse(to, false)
	await process_frame
	await _settle()


## Espera a animação de deslizar terminar: o alvo do teste é o boneco parado, como um jogador miraria.
func _settle() -> void:
	await create_timer(0.8).timeout


func _tap(point: Vector2) -> void:
	_move(point)
	_mouse(point, true)
	_mouse(point, false)
	await process_frame


func _body(unit_id: int) -> Vector2:
	var unit: Dictionary = view._unit_by_id(unit_id)
	return Board.project(view._ground_of(unit)) + Vector2(0, -18)


func _cell_of(unit_id: int) -> Vector2i:
	return view._cell(view._unit_by_id(unit_id).get("cell", []))


func _center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	view = scene.instantiate() as MainView
	root.add_child(view)
	await process_frame
	view.audio.set_enabled(false)
	view.start_button.pressed.emit()
	for option: Dictionary in view.state["own"]["benefit_options"]:
		if option["kind"] == "gold":
			(view.benefit_buttons[str(option["option_id"])] as Button).pressed.emit()
	await process_frame
	await process_frame
	_check(view._phase() == "preparation" and view.drag != null, "preparação com controlador de arrasto instalado")

	# Setup de teste: recruta 4 heróis para povoar o campo antes dos testes de arrasto
	for key: String in ["neymar", "caramelo", "obama", "michael"]:
		var setup_offer = view.session._offer(0, 90 + view.session.teams[0]["owned"].size(), "hero", key, key, 0)
		(view.session.teams[0]["shop"] as Array).append(setup_offer)
		view.session.apply_command(0, "setup_" + key, "recruit", {"offer_id": setup_offer["offer_id"]})
	view._refresh()
	await process_frame
	await process_frame

	# 1. Toque simples continua selecionando (o toque guardado é reenviado ao soltar).
	await _tap(_body(1))
	_check(view.selected_id == 1, "toque sem arrasto seleciona o herói como antes")
	await _tap(_body(1))
	_check(view.selected_id == -1, "segundo toque desfaz a seleção como antes")

	# 2. Arrastar herói para outro hexágono da própria metade.
	await _drag(_body(1), Board.cell_position(Vector2i(0, 7)))
	_check(_cell_of(1) == Vector2i(0, 7), "arrastar move o herói para o hexágono solto")
	_check(view.selected_id == 1, "herói arrastado fica selecionado (cartão aberto)")

	# 3. Soltar na metade inimiga não move.
	await _drag(_body(1), Board.cell_position(Vector2i(3, 1)))
	_check(_cell_of(1) == Vector2i(0, 7) and view.toast_remaining > 0.0, "metade inimiga recusada com aviso")

	# 4. Campo → reserva e reserva → campo.
	await _drag(_body(1), Board.bench_position(0))
	_check(not bool(view._unit_by_id(1).get("active", true)), "arrastar para a reserva guarda o herói")
	await _drag(Board.bench_position(view._bench_slot_of(1)) + Vector2(0, -18), Board.cell_position(Vector2i(1, 7)))
	_check(bool(view._unit_by_id(1).get("active", false)) and _cell_of(1) == Vector2i(1, 7), "arrastar da reserva coloca em campo")

	# 5. Herói sobre herói troca de lugar.
	var cell_a: Vector2i = _cell_of(1)
	var cell_b: Vector2i = _cell_of(3)
	await _drag(_body(1), Board.cell_position(cell_b))
	_check(_cell_of(1) == cell_b and _cell_of(3) == cell_a and view._active_count() == 4, "arrastar sobre outro herói troca os dois de lugar")

	# 6. Oferta de herói da loja para a reserva (campo cheio).
	var hero_offer: Dictionary = {}
	for offer: Dictionary in view.state["own"]["shop"]:
		if offer["kind"] == "hero" and not view.state["own"]["owned"].has(offer["key"]):
			hero_offer = offer
			break
	if not hero_offer.is_empty():
		var card: Button = view.shop_buttons[str(hero_offer["offer_id"])]
		await _drag(_center(card), Board.bench_position(2))
		_check(view.state["own"]["owned"].has(hero_offer["key"]) and not view.state["own"]["bench"].is_empty(), "arrastar herói da loja recruta para a reserva")
	else:
		_check(false, "loja inicial tem herói novo para recrutar")

	# 7. Oferta de item da loja direto no herói: compra e equipa.
	var item_offer: Dictionary = view.state["own"]["shop"][0]
	var gold: int = int(view.state["own"]["gold"])
	await _drag(_center(view.shop_buttons[str(item_offer["offer_id"])]), _body(3))
	var equipped: Array = view.state["own"]["equipment"].get(3, [])
	_check(equipped.size() == 1 and int(view.state["own"]["gold"]) == gold - int(item_offer["price"]), "item da loja arrastado para o herói é comprado e equipado")

	# 8. Item da bolsa para o herói.
	var bag_item: Dictionary = view.session._new_item(0, "blade")
	(view.session.teams[0]["bag"] as Array).append(bag_item)
	view._refresh()
	await process_frame
	await _drag(_center(view.bag_buttons[str(bag_item["id"])]), _body(5))
	_check(view.state["own"]["equipment"].get(5, []).size() == 1 and view.state["own"]["bag"].is_empty(), "item da bolsa arrastado equipa o herói")

	# 9. Item equipado do cartão de volta para a bolsa.
	view._select_unit(5)
	view._refresh()
	await process_frame
	await _drag(_center(view.equipment_buttons[0]), _center(view.bag_panel))
	_check(view.state["own"]["equipment"].get(5, []).is_empty() and view.state["own"]["bag"].size() == 1, "item equipado arrastado para a bolsa volta para ela")

	# 10. Item sobre item da bolsa funde a receita.
	var second: Dictionary = view.session._new_item(0, "blade")
	(view.session.teams[0]["bag"] as Array).append(second)
	view._refresh()
	await process_frame
	var first_id: String = str(view.state["own"]["bag"][0]["id"])
	await _drag(_center(view.bag_buttons[first_id]), _center(view.bag_buttons[str(second["id"])]))
	_check(view.state["own"]["bag"].size() == 1 and view.state["own"]["bag"][0]["key"] == "great_blade", "duas lâminas arrastadas uma sobre a outra viram lâmina dupla")

	# 11. Item equipado de um herói para outro.
	await _drag(_center(view.bag_buttons[str(view.state["own"]["bag"][0]["id"])]), _body(5))
	view._select_unit(5)
	view._refresh()
	await process_frame
	await _drag(_center(view.equipment_buttons[0]), _body(2))
	_check(view.state["own"]["equipment"].get(5, []).is_empty() and view.state["own"]["equipment"].get(2, []).size() == 1, "item equipado passa direto para outro herói")

	# 12. Fora da preparação o arrasto não age.
	view.fight_button.pressed.emit()
	view.set_process(false) # congela o combate: só o arrasto poderia mover o herói
	var before: Vector2i = _cell_of(2)
	await _drag(_body(2), Board.cell_position(Vector2i(7, 7)))
	_check(view._phase() == "combat" and _cell_of(2) == before, "combate ignora arrasto de posicionamento")
	_check(view.drag.payload.is_empty() and not view.drag.dragging, "estado do arrasto limpo")

	# 13. Durante o combate, arrastar item da bolsa para o herói lutando equipa na hora.
	var combat_item: Dictionary = view.session._new_item(0, "boots")
	(view.session.teams[0]["bag"] as Array).append(combat_item)
	view.bag_signature = ""
	view._refresh()
	await process_frame
	var hero_items_before: int = view.state["own"]["equipment"].get(5, []).size()
	await _drag(_center(view.bag_buttons[str(combat_item["id"])]), _body(5))
	_check(view.state["own"]["equipment"].get(5, []).size() == hero_items_before + 1 and view.state["own"]["bag"].is_empty(), "arrastar item da bolsa durante o combate equipa o herói lutando")

	print("DRAG_AND_DROP_TESTS: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(1 if failed > 0 else 0)
