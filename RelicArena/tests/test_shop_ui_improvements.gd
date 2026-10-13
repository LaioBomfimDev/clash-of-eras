extends SceneTree
## Testes de validação visual e lógica das melhorias de UI da loja, botões e hover de heróis.

const MainScene = preload("res://main.tscn")
const Board = preload("res://client/board_projection.gd")
const Kit = preload("res://client/ui_kit.gd")

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: %s" % description)

func _run() -> void:
	print("--- TESTANDO MELHORIAS DE UI DA LOJA, BOTÕES E HOVER ---")
	DirAccess.make_dir_recursive_absolute("res://captures")

	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame

	# Iniciar uma partida local para popular a loja e a arena
	if view.has_method("_start_local_match"):
		view._start_local_match()
	elif view.has_method("_start_match"):
		view._start_match()
	await process_frame
	await process_frame

	# Escolher primeiro benefício para abrir a fase de preparação
	if view._phase() == "benefit":
		var opts: Array = view.state.get("own", {}).get("benefit_options", [])
		if not opts.is_empty():
			var opt_id: String = str(opts[0]["option_id"])
			view._command("choose_benefit", {"option_id": opt_id})
		await process_frame
		await process_frame

	# 1. Validação dos botões enquadrados (ESPAÇO e RENOVAR)
	_check(view.capacity_btn_label != null and view.capacity_btn_label.text == "ESPAÇO", "Botão ESPAÇO possui label de texto dedicado")
	_check(view.capacity_btn_coin != null and view.capacity_btn_coin.texture != null, "Botão ESPAÇO possui mini-ícone de moeda de ouro")
	_check(view.capacity_btn_cost != null and not view.capacity_btn_cost.text.is_empty(), "Botão ESPAÇO possui label de custo numérico em amarelo")
	_check(view.reroll_btn_label != null and view.reroll_btn_label.text == "RENOVAR", "Botão RENOVAR possui label de texto dedicado")
	_check(view.reroll_btn_coin != null and view.reroll_btn_coin.texture != null, "Botão RENOVAR possui mini-ícone de moeda de ouro")
	_check(view.reroll_btn_cost != null and not view.reroll_btn_cost.text.is_empty(), "Botão RENOVAR possui label de custo numérico em amarelo")

	# 2. Validação do botão LUTAR / RECRUTE
	_check(view.fight_btn_icon != null and view.fight_btn_icon.texture != null, "Botão LUTAR possui ícone de combate centralizado")
	_check(view.fight_btn_label != null and not view.fight_btn_label.text.is_empty(), "Botão LUTAR possui label de ação negrito")

	# 3. Validação do Badge MEMBROS com ícone de time
	_check(view.capacity_title_label != null and view.capacity_title_label.text == "MEMBROS:", "Novo badge possui título 'MEMBROS:'")
	_check(view.capacity_label != null and "/" in view.capacity_label.text, "Badge de capacidade exibe contagem formatada 'X/Y'")

	# 4. Validação da Moeda Parada e Pilha Concentrada
	_check(view.gold_coin_rect != null and view.gold_coin_rect.texture != null, "Mostrador de ouro possui moeda fixa estática")
	_check(view.gold_pile_layer != null and view.gold_pile_layer.position.x == 1180, "Pilha de moedas perfeitamente alinhada no centro")

	# 5. Validação do Hover na Loja
	var shop_buttons = view.shop_root.get_children()
	var found_hero_tooltip: bool = false
	for btn in shop_buttons:
		if btn is Button and "✦ HABILIDADE:" in btn.tooltip_text:
			found_hero_tooltip = true
			break
	_check(found_hero_tooltip, "Cards de heróis na loja contêm descrição completa da habilidade no tooltip")

	# 6. Captura da barra da loja com a preparação ativa
	view.visual_time = 1.0
	view.queue_redraw()
	await process_frame
	await process_frame
	_capture("res://captures/nova_loja_botoes_enquadrados.png")
	_check(FileAccess.file_exists("res://captures/nova_loja_botoes_enquadrados.png"), "Captura da nova barra da loja gerada com sucesso")

	# 7. Recrutar um herói da loja para posicionar no tabuleiro
	var offers: Array = view.state.get("own", {}).get("shop", [])
	for off: Dictionary in offers:
		if off.get("kind", "") == "hero" and not bool(off.get("claimed", false)):
			view._command("recruit", {"offer_id": str(off["offer_id"])})
			break
	await process_frame
	await process_frame

	# 8. Testar hover sobre o herói recrutado em campo
	var own_units: Array = view.state.get("own", {}).get("units", [])
	if not own_units.is_empty():
		var h_cell: Vector2i = view._cell(own_units[0].get("cell", [2, 6]))
		var h_ground: Vector2 = Board.ground(h_cell)
		var h_screen: Vector2 = Board.project(h_ground)
		view.mouse_pointer = h_screen + Vector2(0, -35) # No centro do corpo do herói
		view.hover_cell = h_cell
		view.queue_redraw()
		await process_frame
		await process_frame
		_capture("res://captures/hover_heroi_campo.png")
		_check(FileAccess.file_exists("res://captures/hover_heroi_campo.png"), "Captura do tooltip de habilidade do herói em campo gerada com sucesso")

	print("\nSHOP UI IMPROVEMENTS RESULTS: %d passed, %d failed\n" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)

func _capture(path: String) -> void:
	var viewport: Viewport = root.get_viewport()
	if viewport == null:
		return
	var tex: Texture2D = viewport.get_texture()
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img != null:
		img.save_png(path)
