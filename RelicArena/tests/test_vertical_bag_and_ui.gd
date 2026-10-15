extends SceneTree

const MainView = preload("res://client/main.gd")
var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> bool:
	if condition:
		_passed += 1
		print("  [PASS] ", message)
		return true
	_failed += 1
	push_error("  [FAIL] " + message)
	print("  [FAIL] ", message)
	return false


func _capture_screenshot(viewport: Viewport, file_path: String) -> void:
	var tex: Texture2D = viewport.get_texture()
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img != null:
		img.save_png(file_path)
		print("Screenshot salva: ", file_path)


func _run() -> void:
	print("=== INICIANDO TESTES DA BOLSA VERTICAL X1 LATERAL, CARD RPG E SINERGIAS ===")
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if not _check(scene != null, "Carregamento da cena res://main.tscn"):
		quit(1)
		return
	var view: MainView = scene.instantiate() as MainView
	root.add_child(view)
	await process_frame
	await process_frame

	# 1. Iniciar partida contra bot
	view._start_match()
	await process_frame
	await process_frame

	# 2. Escolher benefício se houver
	if view._phase() == "benefit":
		view._select_benefit(0)
		await process_frame
		await process_frame

	_check(view._phase() == "preparation", "Fase atual é preparation")

	# 3. Teste da Bolsa Vertical x1 Lateral
	_check(view.bag_panel != null and view.bag_panel.visible, "Bolsa visível na preparação")
	_check(view.bag_panel.position == Vector2(10, 312), "Bolsa ancorada na lateral esquerda X:10, Y:312")
	_check(view.bag_panel.size == Vector2(48, 398), "Bolsa vertical com largura x1 de 48px e altura de 398px")
	_check(view.bag_title.text.begins_with("ITENS"), "Título da bolsa estilizado como ITENS")
	_check(view.equip_button != null and view.fuse_button != null, "Botões EQP e FND presentes na coluna vertical")

	# Checar que os botões cabem dentro do painel
	var bag_bounds: Rect2 = Rect2(Vector2.ZERO, view.bag_panel.size)
	_check(bag_bounds.encloses(view.equip_button.get_rect()), "Botão EQP dentro do limite da coluna vertical")
	_check(bag_bounds.encloses(view.fuse_button.get_rect()), "Botão FND dentro do limite da coluna vertical")

	# Adicionar um item para checar a coluna vertical de slots
	var test_item: Dictionary = view.session._new_item(0, "blade")
	(view.session.teams[0]["bag"] as Array).append(test_item)
	view._refresh()
	await process_frame

	var item_id: String = str(test_item["id"])
	_check(view.bag_buttons.has(item_id), "Item registrado em bag_buttons")
	var slot_btn: Button = view.bag_buttons[item_id]
	_check(slot_btn.size == Vector2(36, 33), "Slot em coluna vertical x1 com tamanho 36x33")
	_check(bag_bounds.encloses(slot_btn.get_rect()), "Slot do item rigorosamente contido dentro da coluna vertical")

	# 4. Teste do Card de Inspeção do Herói (unit_card)
	view._select_unit(1)
	view._refresh()
	await process_frame

	_check(view.unit_card != null and view.unit_card.visible, "Card de inspeção visível após selecionar herói")
	_check(view.unit_card.position.x == 1040, "Card posicionado na lateral direita X:1040")
	_check(view.card_root.get_node_or_null("HpText") != null, "Indicador numérico HpText presente no card")
	_check(view.card_root.get_node_or_null("HpFill") != null, "Barra gráfica HpFill presente no card")
	_check(view.equipment_buttons.size() == 4, "4 slots de equipamentos presentes no card de herói")

	var card_bounds: Rect2 = Rect2(Vector2.ZERO, view.unit_card.size)
	for eq_slot: Button in view.equipment_buttons:
		_check(card_bounds.encloses(eq_slot.get_rect()), "Slot de equipamento dentro do limite do card")
	_check(card_bounds.encloses(view.bench_button.get_rect()), "Botão RESERVAR dentro do limite do card")
	_check(card_bounds.encloses(view.dismiss_button.get_rect()), "Botão DISPENSAR dentro do limite do card")

	# Equipar item no herói
	view.selected_items = [item_id]
	view._refresh()
	await process_frame
	_check(not view.equip_button.disabled, "Botão EQP habilitado com item selecionado")
	view.equip_button.pressed.emit()
	view._refresh()
	await process_frame

	_check(view.state["own"]["bag"].is_empty(), "Item saiu da bolsa após equipar")
	_check(view.equipment_buttons[0] != null and not view.equipment_buttons[0].disabled, "Item agora aparece no slot do card")

	# 5. Teste de Sinergias Retráteis
	_check(view.synergy_toggle_btn != null, "Botão toggle de sinergias presente")
	_check(view.synergies_collapsed == false, "Sinergias iniciam no modo expandido")
	_check(view.synergy_header_btn.text == "SINERGIAS · TESTE", "Texto do cabeçalho completo no modo expandido")

	# Alternar para modo compacto
	view.synergy_toggle_btn.pressed.emit()
	view._refresh()
	await process_frame

	_check(view.synergies_collapsed == true, "Sinergias agora estão no modo compacto")
	_check(view.synergy_header_btn.text == "SIN.", "Texto do cabeçalho abreviado para SIN.")
	_check(view.synergy_toggle_btn.text == "▶", "Ícone do botão toggle mudou para ▶")

	# Checar largura das linhas de sinergia no modo compacto
	var syn_children: Array = view.synergy_root.get_children()
	if not syn_children.is_empty():
		var first_row: Panel = syn_children[0] as Panel
		_check(first_row.size.x == 48.0, "Linha de sinergia compactada para largura 48px")

	# Alternar de volta para modo expandido
	view.synergy_toggle_btn.pressed.emit()
	view._refresh()
	await process_frame

	_check(view.synergies_collapsed == false, "Sinergias retornaram ao modo expandido")
	_check(view.synergy_header_btn.text == "SINERGIAS · TESTE", "Cabeçalho restaurado")

	print("\nVERTICAL BAG AND UI TEST RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)
