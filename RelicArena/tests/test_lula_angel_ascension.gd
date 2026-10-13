extends SceneTree
## Teste unitário e de integração visual para a Ascensão Angelical do Lula:
## 1. Demora de 1.0s para voltar (descida do céu).
## 2. Buff de +25% de dano da equipe por 5s ao renascer.
## 3. Frenesi Divino por 5s (100% de ataques críticos garantidos).
## 4. Asas de anjo engraçadas brancas e douradas + auréola (areola) persistentes até o final da partida.
## 5. Capturas de tela visuais completas.

const Simulation = preload("res://simulation/arena_simulation.gd")
const UnitSpec = preload("res://data/unit_spec.gd")
const UnitState = preload("res://simulation/unit_state.gd")
const Board = preload("res://client/board_projection.gd")
const MainScene = preload("res://main.tscn")

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

func _near(a: float, b: float, description: String, tolerance: float = 0.05) -> void:
	_check(absf(a - b) <= tolerance, "%s (esperado ~%.2f, obtido %.2f)" % [description, b, a])

func _events(sim: Simulation, event_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in sim.events:
		if event["type"] == event_type:
			result.append(event)
	return result

func _run() -> void:
	print("--- INICIANDO TESTES DA ASCENSÃO ANGELICAL DO LULA ---")
	_test_specs_and_definitions()
	_test_revival_delay_1s()
	_test_divine_frenzy_and_group_buff()
	_test_persistence_next_round()
	await _test_visuals_and_captures()

	print("\nLULA ANGEL ASCENSION RESULTS: %d passed, %d failed\n" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_specs_and_definitions() -> void:
	var spec: UnitSpec = UnitSpec.new()
	spec.load_values("lula", {
		"max_hp": 1000.0,
		"revive_ratio": 0.4,
		"extra_revive_ratio": 0.3,
		"extra_revive_min_level": 3
	})
	_near(spec.revive_delay, 1.0, "Lula tem atraso padrão de 1.0s na especificação")
	_near(spec.revive_buff_duration, 5.0, "Lula tem duração de buff de 5.0s na especificação")
	_near(spec.revive_team_attack_bonus, 0.25, "Lula tem +25% de ataque da equipe na especificação")
	_near(spec.revive_divine_frenzy_duration, 5.0, "Lula tem 5.0s de frenesi divino na especificação")

func _test_revival_delay_1s() -> void:
	var sim: Simulation = Simulation.new()
	sim.units.clear()
	var spec: UnitSpec = UnitSpec.new()
	spec.load_values("lula", {
		"max_hp": 1000.0,
		"revive_ratio": 0.4,
		"revive_delay": 1.0,
		"revive_buff_duration": 5.0,
		"revive_team_attack_bonus": 0.25,
		"revive_divine_frenzy_duration": 5.0
	})
	var lula: UnitState = UnitState.new(spec, 1, 0, Vector2i(2, 6))
	var ally: UnitState = UnitState.new(spec, 2, 0, Vector2i(2, 7))
	var enemy_spec: UnitSpec = UnitSpec.new()
	enemy_spec.load_values("inimigo", {"max_hp": 1000.0, "attack_damage": 10.0, "attacks_per_second": 1.0})
	var enemy: UnitState = UnitState.new(enemy_spec, 101, 1, Vector2i(2, 2))

	sim.units = [lula, ally, enemy]
	sim.start_combat()

	# Aplica dano letal ao Lula
	sim._deal_damage(101, lula, 99999.0, false, "hit")

	_check(lula.is_reviving, "Dano letal ativa estado is_reviving no Lula")
	_near(lula.revive_delay_remaining, 1.0, "Contagem regressiva inicia em 1.0 segundo")
	_check(lula.alive, "Lula permanece alive durante a descida (não é dado como morto)")
	_check(not lula.has_angel_wings, "Ainda não possui asas antes de completar a descida")
	_check(_events(sim, "death").is_empty(), "Nenhum evento de morte disparado ao iniciar descida")
	_check(_events(sim, "reviving").size() == 1, "Evento 'reviving' disparado com sucesso")
	_check(_events(sim, "revive").is_empty(), "Evento 'revive' ainda não disparado")

	# Avança 0.5 segundos: Lula ainda está descendo
	sim.step(0.5)
	_check(lula.is_reviving, "Aos 0.5s, Lula ainda está descendo do céu")
	_near(lula.revive_delay_remaining, 0.5, "Restam ~0.5s de descida")
	_check(_events(sim, "revive").is_empty(), "Ainda não reviveu aos 0.5s")

	# Avança mais 0.5s (total 1.0s): Lula completa o renascimento
	sim.step(0.5)
	_check(not lula.is_reviving, "Após 1.0s, is_reviving se torna falso")
	_check(lula.alive and lula.revived, "Lula está vivo e revivido")
	_near(lula.hp, 400.0, "Lula renasce com 40% da vida máxima (400 HP)")
	_check(lula.has_angel_wings, "Lula ganha asas angelicais definitivas")
	_near(lula.divine_frenzy_timer, 5.0, "Lula ganha 5.0s de Frenesi Divino")
	_near(ally.group_attack_buff_timer, 5.0, "Aliado ganha 5.0s de Buff de Ataque de Equipe (+25%)")
	_check(_events(sim, "revive").size() == 1, "Evento 'revive' disparado ao tocar o solo")
	_check(_events(sim, "lula_ascended").size() == 1, "Evento 'lula_ascended' disparado")

func _test_divine_frenzy_and_group_buff() -> void:
	var sim: Simulation = Simulation.new()
	sim.units.clear()
	var lula_spec: UnitSpec = UnitSpec.new()
	lula_spec.load_values("lula", {
		"max_hp": 1000.0,
		"attack_damage": 50.0,
		"crit_chance": 0.0, # Crítico base ZERO
		"crit_multiplier": 1.5,
		"attacks_per_second": 1.0,
		"attack_range": 1
	})
	var lula: UnitState = UnitState.new(lula_spec, 1, 0, Vector2i(2, 2))
	lula.divine_frenzy_timer = 5.0 # Frenesi ativo

	var dummy_spec: UnitSpec = UnitSpec.new()
	dummy_spec.load_values("dummy", {"max_hp": 5000.0, "armor": 0.0, "resist": 0.0})
	var enemy: UnitState = UnitState.new(dummy_spec, 101, 1, Vector2i(2, 3))

	sim.units = [lula, enemy]
	sim.phase = "combat"

	# Lula ataca com Frenesi Divino: acerto crítico garantido (100%)
	sim._attack(lula, enemy)
	var hit_events: Array[Dictionary] = _events(sim, "hit")
	_check(hit_events.size() == 1, "Golpe do Lula executado com sucesso")
	_check(hit_events[0]["critical"] == true, "Ataque do Lula sob Frenesi Divino é 100% CRÍTICO garantido!")
	_near(enemy.hp, 5000.0 - (50.0 * 1.5), "Dano aplicado foi crítico (50 * 1.5 = 75)")

	# Testar o buff de +25% de dano do aliado
	var ally_spec: UnitSpec = UnitSpec.new()
	ally_spec.load_values("ally", {
		"max_hp": 1000.0,
		"attack_damage": 100.0,
		"crit_chance": 0.0,
		"crit_multiplier": 1.5,
		"attacks_per_second": 1.0,
		"attack_range": 1
	})
	var ally: UnitState = UnitState.new(ally_spec, 2, 0, Vector2i(3, 2))
	ally.group_attack_buff_timer = 5.0 # +25% dano
	sim.units.append(ally)

	var enemy_hp_before: float = enemy.hp
	sim._attack(ally, enemy)
	var ally_damage_dealt: float = enemy_hp_before - enemy.hp
	_near(ally_damage_dealt, 125.0, "Aliado sob buff de grupo causou exatamente +25% de dano (100 * 1.25 = 125)")

	# Expirar timers e testar retorno ao normal
	lula.divine_frenzy_timer = 0.0
	ally.group_attack_buff_timer = 0.0
	enemy_hp_before = enemy.hp
	sim._attack(ally, enemy)
	var normal_damage: float = enemy_hp_before - enemy.hp
	_near(normal_damage, 100.0, "Sem o buff expirado, o aliado volta a causar o dano base normal (100)")

func _test_persistence_next_round() -> void:
	var sim: Simulation = Simulation.new()
	var lula_spec: UnitSpec = UnitSpec.new()
	lula_spec.load_values("lula", {
		"max_hp": 1000.0,
		"revive_ratio": 0.4,
		"revive_delay": 1.0
	})
	var lula: UnitState = UnitState.new(lula_spec, 1, 0, Vector2i(2, 6))
	var enemy_spec: UnitSpec = UnitSpec.new()
	enemy_spec.load_values("dummy", {"max_hp": 1000.0})
	var enemy: UnitState = UnitState.new(enemy_spec, 101, 1, Vector2i(2, 2))

	sim.units = [lula, enemy]
	sim.start_combat()
	sim._deal_damage(101, lula, 99999.0, false, "hit")
	sim.step(1.0)
	_check(lula.has_angel_wings, "Lula ganhou asas após renascer")
	_check(sim._ascended_units.get(lula.id, false) == true, "ID do Lula registrado no mapa de ascensão persistente da simulação")

	# Simular início de uma nova rodada com os mesmos heróis
	sim.phase = "preparation"
	sim._setup_round()
	var lula_next_round: UnitState = sim.get_unit(lula.id)
	_check(lula_next_round != null, "Lula presente na rodada seguinte")
	if lula_next_round != null:
		_check(lula_next_round.has_angel_wings, "Lula MANTÉM o visual de asas e auréola na rodada seguinte até o final da partida!")

func _test_visuals_and_captures() -> void:
	print("--- TESTANDO RENDERIZAÇÃO E GERANDO CAPTURAS DO CLIENTE ---")
	DirAccess.make_dir_recursive_absolute("res://captures")

	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame

	# Verifica se métodos de desenho e variáveis existem
	_check(view.has_method("_draw_lula_angel_wings"), "Cliente possui método _draw_lula_angel_wings")
	_check(view.has_method("_draw_lula_halo"), "Cliente possui método _draw_lula_halo")
	_check("lula_descents" in view, "Cliente possui dicionário lula_descents")
	_check("ascended_units" in view, "Cliente possui dicionário ascended_units")

	# Simular descida do Lula (1.0s de voo do céu)
	var lula_cell: Vector2i = Vector2i(3, 4)
	var lula_ground: Vector2 = Board.ground(lula_cell)
	view.lula_descents[1] = {
		"duration": 1.0,
		"remaining": 0.5,
		"cell": lula_cell,
		"ground": lula_ground
	}
	view.visual_time = 0.5
	view.queue_redraw()
	await process_frame
	await process_frame
	_capture("res://captures/lula_descendo_do_ceu.png")
	_check(FileAccess.file_exists("res://captures/lula_descendo_do_ceu.png"), "Captura da descida celestial gerada com sucesso")

	# Simular impacto divino e despertar
	view.lula_descents.clear()
	view.ascended_units[1] = true
	var center_pos: Vector2 = Board.project(lula_ground)
	view.floating.append({"text": "😇 VOLTA POR CIMA DIVINA!", "position": center_pos + Vector2(-65, -55), "color": Color("86f6a5"), "life": 1.4, "size": 17})
	view.floating.append({"text": "⚔ +25% DANO DO GRUPO (5s)", "position": center_pos + Vector2(-70, -34), "color": Color("ffd700"), "life": 1.5, "size": 14})
	view.floating.append({"text": "⚡ FRENESI DIVINO (CRÍTICO 100%)", "position": center_pos + Vector2(-80, -12), "color": Color("ffe082"), "life": 1.6, "size": 14})
	view.shield_waves.append({"ground": center_pos, "life": 0.8, "duration": 0.8, "team": 0, "color": Color("ffd700")})
	view.visual_time = 1.0
	view.queue_redraw()
	await process_frame
	await process_frame
	_capture("res://captures/lula_impacto_divino.png")
	_check(FileAccess.file_exists("res://captures/lula_impacto_divino.png"), "Captura do impacto divino com floating texts gerada com sucesso")

	# Simular Lula angelical ativo no tabuleiro com asas e auréola
	view.visual_time = 2.0
	view.queue_redraw()
	await process_frame
	await process_frame
	_capture("res://captures/lula_angelical_em_campo.png")
	_check(FileAccess.file_exists("res://captures/lula_angelical_em_campo.png"), "Captura do Lula angelical com auréola e asas em campo gerada com sucesso")

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
