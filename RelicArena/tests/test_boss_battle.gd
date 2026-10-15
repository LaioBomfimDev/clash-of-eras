extends SceneTree
## Teste e validação visual da Batalha de Boss PvE contra o Criador/Desenvolvedor no Round 4.

const MainScene: PackedScene = preload("res://main.tscn")
var passed: int = 0
var failed: int = 0

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame

	DirAccess.make_dir_recursive_absolute("res://captures")

	# Iniciar partida local
	view._start_match()
	await process_frame
	_assert(view._phase() in ["benefit", "preparation"], "Partida iniciou com sucesso")

	# Escolher benefício se necessário
	if view._phase() == "benefit":
		var opts: Array = view.state.get("own", {}).get("benefit_options", [])
		if not opts.is_empty():
			view._command("choose_benefit", {"option_id": opts[0]["option_id"]})
		await process_frame

	# Colocar heróis em campo para o jogador
	for offer: Dictionary in view.state.get("own", {}).get("shop", []):
		if offer["kind"] == "hero":
			view._command("recruit", {"offer_id": offer["offer_id"]})
			break
	await process_frame

	# Avançar rodadas 1, 2 e 3 até chegar na Rodada 4 (Boss)
	while int(view.state.get("round", 1)) < 4:
		var r_idx: int = int(view.state.get("round", 1))
		if view._phase() == "benefit":
			var opts2: Array = view.state.get("own", {}).get("benefit_options", [])
			if not opts2.is_empty():
				view._command("choose_benefit", {"option_id": opts2[0]["option_id"]})
		view._command("ready")
		# Avançar preparação e combate
		view.session.step(31.0)
		view._consume_events()
		view._refresh()
		await process_frame
		_assert(view._phase() in ["round_result", "match_over"], "Rodada %d concluída" % r_idx)
		if view._phase() == "round_result":
			view._next_round()
			await process_frame

	# Chegamos na Rodada 4
	var current_round: int = int(view.state.get("round", 1))
	_assert(current_round == 4, "Chegou na Rodada 4 (atual: %d)" % current_round)
	_assert(bool(view.state.get("is_boss_round", false)), "Estado marca is_boss_round = true")
	_assert(view.round_label.text.find("BOSS CRIADOR") != -1, "HUD exibe 'RODADA 4 · BOSS CRIADOR'")
	_assert(view.opponent_name_label.text == "DESENVOLVEDOR (BOSS)", "Oponente identificado como 'DESENVOLVEDOR (BOSS)'")

	# Validar prévia do Boss Dev durante a fase de preparação (Round 4)
	var enemy_units_prep: Array = view.state.get("enemy", {}).get("units", [])
	_assert(enemy_units_prep.size() == 1, "Prévia no Round 4 exibe apenas o Boss (1 unidade, e não o bot anterior) (tamanho: %d)" % enemy_units_prep.size())
	if not enemy_units_prep.is_empty():
		var boss_prep: Dictionary = enemy_units_prep[0]
		_assert(boss_prep.get("key", "") == "boss_dev", "Unidade exibida na prévia é o 'boss_dev'")
		_assert(boss_prep.get("cell", []) == [4, 1], "Boss posicionado no topo do mapa em cell (4, 1)")
		_assert(float(boss_prep.get("max_hp", 0)) == 10000.0, "Boss na prévia tem max_hp 10.000")

	# Validar que a Barra Épica de Boss no Topo da Tela NÃO aparece durante a preparação (aparece apenas na luta do Boss)
	_assert(view.boss_bar_panel != null and not view.boss_bar_panel.visible, "Barra Épica de Boss oculta durante a fase de preparação")

	# Capturar tela da prévia do Boss no mapa aguardando os combatentes
	view.queue_redraw()
	await process_frame
	await process_frame
	_capture("res://captures/boss_previa_preparacao.png")

	# Recrutar tropas adicionais para a batalha do Boss
	for offer: Dictionary in view.state.get("own", {}).get("shop", []):
		if offer["kind"] == "hero":
			view._command("recruit", {"offer_id": offer["offer_id"]})
	# Garantir que heróis sobrevivam ao dano aumentado para testar todo o ciclo de feitiços e invocações
	for u in view.session.sim.units:
		if u.team == 0:
			u.max_hp = 12000.0
			u.hp = 12000.0

	# Verificar que o Boss 999 está no campo do inimigo com 10.000 HP (+2k HP)
	var boss_found: bool = false
	for u in view.session.sim.units:
		if u.id == 999 and u.is_boss and u.key == "boss_dev":
			boss_found = true
			_assert(u.hp == 10000.0, "Boss Desenvolvedor tem exatamente 10.000 HP (+2k de vida) (HP: %f)" % u.hp)
			_assert(u.cell == Vector2i(4, 1), "Boss posicionado no topo do campo inimigo")
	_assert(boss_found, "Boss Desenvolvedor (ID 999) ativo na simulação")

	# Iniciar combate do Boss passo a passo
	view._command("ready")
	view.session.step(0.1) # Transita de preparation para combat
	view._consume_events()
	view._refresh()
	await process_frame
	_assert(view._phase() == "combat", "Entrou na fase de combate contra o Boss")
	_assert(view.boss_bar_panel != null and view.boss_bar_panel.visible, "Barra Épica de Boss ativa e visível no topo da tela durante o combate")
	_assert(view.boss_bar_title != null and view.boss_bar_title.text.find("CRIADOR") != -1, "Título da Boss Bar identifica 'O CRIADOR DA ARENA (BOSS)'")
	_assert(view.boss_bar_hp_label != null and view.boss_bar_hp_label.text.find("10000") != -1, "Rótulo de HP exibe valor total de 10.000 HP")
	for u in view.session.sim.units:
		if u.team == 0:
			u.max_hp = 15000.0
			u.hp = 15000.0

	# Avançar o combate em passos de 1.0s para coletar invocações e feitiços
	var summons_seen: int = 0
	var casts_seen: int = 0
	var red_fire_seen: bool = false
	var purple_fire_seen: bool = false
	var aggro_transferred_to_summon: bool = false
	var telegraph_seen: bool = false
	var portals_seen: bool = false
	var teleports_seen: int = 0
	var backline_summon_seen: bool = false

	for step_i: int in range(25):
		for u in view.session.sim.units:
			if u.team == 0:
				u.hp = 15000.0
			elif u.id == 999 and u.is_boss:
				u.hp = max(u.hp, 6000.0)
		view.session.step(1.0)
		view._consume_events()
		view._refresh()
		await process_frame

		if not view.boss_telegraphs.is_empty():
			telegraph_seen = true
		if not view.boss_summon_portals.is_empty():
			portals_seen = true

		for u in view.session.sim.units:
			if u.summoned and u.team == 1:
				summons_seen += 1
				if u.cell.y in [5, 6, 7]:
					backline_summon_seen = true
				if u.key == "slime_lodo_olho":
					_assert(u.max_hp == 4000.0, "Lodo Negro tem 4.000 HP (+2k de vida) (HP: %f)" % u.max_hp)
				elif u.key == "monstro_olho_tentaculos":
					_assert(u.max_hp == 5000.0, "Aberração Cósmica tem 5.000 HP (+2k de vida) (HP: %f)" % u.max_hp)
		for line: String in view.log_lines:
			if line.find("Criador") != -1 or line.find("Fogo") != -1 or line.find("Furacão") != -1 or line.find("monstro") != -1:
				casts_seen += 1
			if line.find("fogo vermelho") != -1 or line.find("Fogo Vermelho") != -1 or line.find("FOGO VERMELHO") != -1:
				red_fire_seen = true
			if line.find("fogo roxo") != -1 or line.find("Fogo Roxo") != -1 or line.find("FOGO ROXO") != -1:
				purple_fire_seen = true
			if line.find("teletransporte") != -1 or line.find("TELEPORTE") != -1:
				teleports_seen += 1

		# Validar que mob invocado toma aggro das tropas do jogador
		var summoned_mobs: Array = []
		for u in view.session.sim.units:
			if u.summoned and u.team == 1 and u.hp > 0:
				summoned_mobs.append(u.id)
		if not summoned_mobs.is_empty():
			for u in view.session.sim.units:
				if u.team == 0 and u.target_id in summoned_mobs:
					aggro_transferred_to_summon = true

		if step_i == 2:
			view.queue_redraw()
			await process_frame
			await process_frame
			_capture("res://captures/boss_desenvolvedor_combate.png")
		elif step_i == 17:
			view.queue_redraw()
			await process_frame
			await process_frame
			_capture("res://captures/boss_desenvolvedor_com_monstros.png")

	_assert(summons_seen > 0, "Monstros invocados pelo Boss durante a luta (%d registros)" % summons_seen)
	_assert(backline_summon_seen, "Monstro invocado no fundo da arena (fileira 5, 6 ou 7)")
	_assert(aggro_transferred_to_summon, "Monstros invocados puxaram o aggro das tropas do jogador com sucesso")
	_assert(teleports_seen > 0, "Boss realizou teletransporte a cada 4 segundos durante a luta (%d registros)" % teleports_seen)
	_assert(casts_seen > 0, "Feitiços do Boss conjurados e registrados no log (%d registros)" % casts_seen)
	_assert(red_fire_seen, "Boss utilizou Fogo Vermelho em combate")
	_assert(purple_fire_seen, "Boss utilizou Fogo Roxo em combate")
	_assert(telegraph_seen, "Telegrafia de aviso prévio de área disparada e capturada pelo cliente")
	_assert(portals_seen, "Portais de invocação com vórtice e lodo renderizados no chão")

	# Testar o Modo de Fúria (Enrage) aos 40% de vida (<= 4.000 HP)
	var boss_unit_sim = null
	for u in view.session.sim.units:
		if u.id == 999 and u.is_boss:
			boss_unit_sim = u
			break
	if boss_unit_sim != null:
		boss_unit_sim.hp = 3500.0 # Reduz para 35% de vida
		view.session.step(0.1)
		view._consume_events()
		view._refresh()
		await process_frame
		_assert(boss_unit_sim.boss_enraged, "Boss entrou no estado de Fúria aos 40% de HP")
		_assert(view.boss_bar_title.text.find("FÚRIA") != -1, "Título da Boss Bar no topo atualizado para 'FÚRIA'")
		view.queue_redraw()
		await process_frame
		await process_frame
		_capture("res://captures/boss_modo_furia_enrage.png")

	# Concluir combate
	while view._phase() == "combat":
		view.session.step(2.0)
		view._consume_events()
		view._refresh()
		await process_frame

	_assert(view._phase() in ["round_result", "match_over"], "Combate contra o Boss finalizado")

	# Testar overlay de vitória do Boss
	view.state["boss_rewards"] = [
		{"kind": "gold", "amount": 4},
		{"kind": "life"},
		{"kind": "item", "key": "great_blade", "name": "Espada da Fúria", "description": "+45 de Ataque e Fúria Berserker"}
	]
	for child in view.overlay.get_children():
		if child != view.result_label:
			child.queue_free()
	view._render_boss_round_result(view.overlay, 0, "round_result")
	await process_frame
	await process_frame

	_assert(view.result_label.text == "VITÓRIA CONTRA O CRIADOR!", "Título do overlay indica Vitória Contra o Criador")
	_assert(view.next_button != null and view.next_button.text == "RESGATAR & CONTINUAR", "Botão de Resgatar & Continuar ativo")
	_capture("res://captures/boss_desenvolvedor_recompensas.png")

	# Testar overlay de derrota/tempo esgotado garantindo que vidas não são perdidas
	for child in view.overlay.get_children():
		if child != view.result_label:
			child.queue_free()
	view._render_boss_round_result(view.overlay, 1, "round_result")
	await process_frame
	await process_frame

	_assert(view.result_label.text == "O DESENVOLVEDOR ESCAPOU!", "Título do overlay indica Derrota/Tempo Esgotado")
	_capture("res://captures/boss_desenvolvedor_derrota_sem_perda.png")

	# Testar transição para a Rodada 5 após a luta do Boss
	view._next_round()
	await process_frame
	await process_frame
	_assert(view.session.sim.round_index == 5, "Avançou com sucesso para a Rodada 5")
	_assert(view._phase() == "preparation", "Fase atual é preparação da Rodada 5")
	_assert(not view.boss_bar_panel.visible, "Barra de vida do Boss invisível na Rodada 5")
	var enemy_units_r5: Array = view.state.get("enemy", {}).get("units", [])
	_assert(not enemy_units_r5.is_empty(), "Prévia da Rodada 5 contém unidades da equipe do adversário (tamanho: %d)" % enemy_units_r5.size())
	var has_boss_in_r5: bool = false
	for u in enemy_units_r5:
		if str(u.get("key", "")) == "boss_dev" or bool(u.get("is_boss", false)):
			has_boss_in_r5 = true
	_assert(not has_boss_in_r5, "Prévia da Rodada 5 retornou à equipe normal do bot, SEM o Boss Dev")
	_capture("res://captures/pos_boss_rodada5_previa_adversario.png")

	print("\nBOSS BATTLE TEST RESULTS: %d passed, %d failed" % [passed, failed])
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
