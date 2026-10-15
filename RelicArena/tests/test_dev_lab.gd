extends SceneTree
const MainScene: PackedScene = preload("res://main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("DEV: " + description)

func _run() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	var lab = view.dev_lab
	lab.storage_dir = "user://devtools_tests_%d" % Time.get_ticks_usec()
	check(not lab.is_open(), "painel começa fechado")
	check(not lab.edit_team(0, 30, 4, 4), "menu não permite mutações de partida")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_F6
	key.pressed = true
	lab.panel._input(key)
	check(lab.is_open() and not view.drag.is_processing_input(), "F6 abre e desativa arrasto atrás do painel")
	lab.panel.comment.text = "rascunho persistente"
	lab.panel.comment.grab_focus()
	lab.panel._input(key)
	check(not lab.is_open() and view.drag.is_processing_input(), "F6 fecha com foco no texto e restaura arrasto")
	lab.panel._input(key)
	check(lab.panel.comment.text == "rascunho persistente", "rascunho sobrevive ao fechar")
	check(lab.new_scenario(4215), "cria cenário local")
	check(lab.paused and view.session.sim.round_index == 1, "cenário começa pausado")
	var initial_shop: Array = view.session.teams[0]["shop"].duplicate(true)
	check(lab.new_scenario(4215), "repete cenário")
	check(initial_shop == view.session.teams[0]["shop"], "semente repete loja")
	check(lab.edit_team(0, 999, 5, 8), "edita economia e capacidade")
	check(not lab.edit_team(0, -1, 0, 99), "recusa limites inválidos")
	check(view.session.teams[0]["gold"] == 999 and view.session.sim.team_lives[0] == 5, "rejeição não aplica alteração parcial")
	check(lab.grant_hero(0, "obama", 3), "adiciona herói N3")
	check(view.session.teams[0]["copies"]["obama"] == 4, "N3 usa quatro cópias atuais")
	check(lab.grant_hero(0, "michael", 2), "adiciona suporte")
	check(lab.grant_hero(0, "neymar", 2), "adiciona atirador")
	check(lab.grant_hero(0, "zumbi", 1), "adiciona atacante")
	check(not lab.grant_hero(0, "inexistente", 1), "recusa herói inválido")
	check(lab.grant_item(0, "great_blade"), "adiciona item de fusão")
	while view.session.teams[0]["bag"].size() < 8:
		lab.grant_item(0, "blade")
	check(not lab.grant_item(0, "blade"), "respeita bolsa cheia")
	check(lab.edit_timing(123, 45, 20), "edita tempos")
	check(not lab.edit_timing(1, 10, 20), "recusa aceleração após duração")
	var prep: float = view.session.prep_remaining
	var visual: float = view.visual_time
	view._process(0.5)
	check(view.session.prep_remaining == prep and view.visual_time == visual, "pausa congela simulação e animação")
	lab.toggle_pause()
	lab.freeze_preparation = true
	view._process(0.5)
	check(view.session.prep_remaining == prep, "cronômetro congelado independente da animação")
	lab.step_once(0.05)
	view._process(0.5)
	check(is_equal_approx(view.session.prep_remaining, prep - 0.05), "passo manual funciona com cronômetro congelado")
	prep = view.session.prep_remaining
	lab.toggle_pause()
	lab.freeze_preparation = false
	check(lab.set_speed(4), "velocidade 4x")
	view._process(0.25)
	check(is_equal_approx(view.session.prep_remaining, prep - 1.0), "velocidade aplicada ao cronômetro")
	check(not lab.set_speed(NAN) and not lab.set_speed(9), "recusa velocidade inválida")
	check(lab.fight(), "inicia combate")
	lab.paused = true
	var tick: int = view.session.sim.tick
	check(lab.step_once(0.05), "solicita um tick")
	view._process(0.3)
	check(view.session.sim.tick == tick + 1, "passo avança exatamente 50 ms mesmo em 4x")
	view._process(0.3)
	check(view.session.sim.tick == tick + 1, "pausa mantida após passo")
	check(not lab.edit_team(0, 0, 1, 4), "economia só muda na preparação")
	check(lab.edit_unit(3, 100, 123, 45, 67), "edita atributos em combate")
	check(view.session.sim.get_unit(3).attack_damage == 123, "dano editado")
	check(not lab.edit_unit(3, 99999, 1, 1, 1), "vida não excede máximo")
	lab.panel._load_units()
	lab.panel.tabs.current_tab = 0
	view._prepare_frame()
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	await _capture("partida")
	lab.panel.tabs.current_tab = 1
	await _capture("equipes")
	lab.panel.tabs.current_tab = 3
	lab.panel.subject.text = "Fixture automatizada (não é avaliação humana)"
	lab.panel.comment.text = "Registro de teste: conferindo pausa e leitura do combate."
	await _capture("feedbacks")
	var path: String = lab.save_feedback("Bug", 2, "teste\nacentuação çã e \"aspas\"", "fixture")
	check(not path.is_empty() and FileAccess.file_exists(path), "feedback persistido")
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(report["feedback"]["comment"] == "teste\nacentuação çã e \"aspas\"", "texto preservado no JSON")
	check(report["seed"] == "4215" and report["combat"]["tick"] == tick + 1 and not report["actions"].is_empty(), "contexto reprodutível salvo")
	check(lab.saved_feedbacks().size() == 1, "relê feedback do disco")
	check(lab.save_feedback("Bug", 2, "   ").is_empty(), "não salva feedback vazio")
	check(lab.finish_combat(), "simula até resultado real")
	check(view.session.phase == "round_result" and lab.rounds.size() == 1, "histórico registra resultado")
	check(lab.next_round() and view.session.sim.round_index == 2, "próximo round normal")
	check(view.session.sim.get_unit(3).attack_damage != 123, "atributos temporários não vazam ao próximo round")
	check(lab.new_scenario(4215, 4) and view.session.sim.is_boss_round, "atalho cria round Boss")
	check(not lab.grant_hero(1, "neymar", 1), "preserva encontro Boss")
	check(lab.new_scenario(4215, 5) and not view.session.sim.is_boss_round, "cenário seguinte volta ao bot")
	view.is_online_match = true
	var before: String = JSON.stringify(view.session.sim.snapshot())
	check(not lab.edit_team(0, 0, 1, 4), "online bloqueia economia")
	check(not lab.grant_hero(0, "neymar", 3) and not lab.edit_unit(3, 1, 1, 1, 1), "online bloqueia heróis e atributos")
	check(not lab.new_scenario(123) and not lab.fight() and not lab.next_round(), "online bloqueia transições")
	check(not lab.set_speed(8) and not lab.step_once(1), "online bloqueia relógio")
	check(lab.frame_delta(0.2) == 0.2 and JSON.stringify(view.session.sim.snapshot()) == before, "online ignora velocidade e não toca simulação")
	check(not lab.context().has("teams") and not lab.context().has("seed"), "online não exporta sessão local antiga")
	view.is_online_match = false
	view._start_match()
	var random_seed: int = view.session._seed
	check(lab.new_scenario(random_seed), "repetição aceita semente gerada de 64 bits")
	view._start_match(12)
	check(not lab.paused and lab.speed == 1 and view.session.sim.round_duration == 30, "nova partida normal restaura configurações")
	check(not view.session.apply_command(0, "dev_remote", "dev_edit", {"gold": 999}).get("ok", false), "protocolo de comandos não aceita operação DEV")
	view._show_menu()
	check(not lab.paused and lab.frame_delta(0.1) == 0.1, "menu restaura relógio")
	print("DEV STORAGE: " + ProjectSettings.globalize_path("user://devtools"))
	print("DEV LAB: %d passed, %d failed" % [passed, failed])
	# Remove somente os arquivos criados por esta fixture, na pasta exclusiva acima.
	for filename: String in DirAccess.get_files_at(lab.storage_dir):
		DirAccess.remove_absolute(lab.storage_dir.path_join(filename))
	DirAccess.remove_absolute(lab.storage_dir)
	view.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://captures/devtools")
		root.get_texture().get_image().save_png("res://captures/devtools/%s.png" % label)
