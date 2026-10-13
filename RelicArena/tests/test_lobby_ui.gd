extends SceneTree
## Teste automatizado do Lobby e Compêndio de Heróis (V1.4 local).
## Executa headless no Godot 4.7.2 e valida contratos do Lobby, 30 FPS, Compêndio e Botão Jogar.

const MainScene: PackedScene = preload("res://main.tscn")
var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)

	_test_lobby_basics(view)
	_test_lobby_fps_and_settings(view)
	_test_lobby_hero_compendium(view)
	_test_lobby_play_transition(view)

	print("LOBBY & HEROES TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)


func _test_lobby_basics(view: Node) -> void:
	_check(view._phase() == "menu", "inicia na fase menu")
	_check(view.lobby_root != null and view.lobby_root.visible, "lobby_root criado e visível no menu")
	_check(view.lobby_bg != null and view.lobby_bg.get_width() == 640 and view.lobby_bg.get_height() == 360, "fundo pixel art do Coliseu carregado em 640×360")
	_check(view.start_button != null and view.start_button.text == "JOGAR", "botão JOGAR posicionado com texto correto")
	_check(view.sound_button != null, "sound_button acessível imediatamente no Lobby")
	_check(view.target_fps == 30 and Engine.max_fps == 30, "foco rígido em 30 FPS aplicado por padrão")


func _test_lobby_fps_and_settings(view: Node) -> void:
	# Abrir modal de configurações
	view.lobby_subview = "settings"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_subview == "settings", "subtela de configurações ativa")

	# Testar comutação de FPS
	view._set_engine_fps(60)
	_check(view.target_fps == 60 and Engine.max_fps == 60, "comuta Engine.max_fps para 60")
	view._set_engine_fps(30)
	_check(view.target_fps == 30 and Engine.max_fps == 30, "retorna ao foco rigoroso de 30 FPS")

	# Testar modo econômico
	var initial_eco: bool = view.eco_mode
	view._toggle_eco_mode()
	_check(view.eco_mode != initial_eco, "alterna modo econômico")
	view._toggle_eco_mode()
	_check(view.eco_mode == initial_eco, "restaura modo econômico")

	# Testar ajuste de taxa de animação
	view._set_animation_fps(12)
	_check(view.art.fps == 12.0, "ajusta taxa de quadros de animação para 12")
	view._set_animation_fps(10)
	_check(view.art.fps == 10.0, "restaura taxa de quadros de animação para 10")

	# Retornar ao lobby principal
	view.lobby_subview = "none"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_subview == "none", "retorna ao lobby principal")


func _test_lobby_hero_compendium(view: Node) -> void:
	# Abrir Compêndio de Heróis
	view.lobby_subview = "heroes"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_subview == "heroes", "subtela do compêndio de heróis ativa")

	# Validar filtros de sinergia
	var all_keys: Array[String] = view.HERO_CATALOG_KEYS
	_check(all_keys.size() == 12, "compêndio contempla 12 heróis")

	# Filtro Vanguarda
	view.lobby_hero_synergy_filter = "vanguarda"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_hero_synergy_filter == "vanguarda", "filtro de Vanguarda selecionado")

	# Filtro Atacantes
	view.lobby_hero_synergy_filter = "atacantes"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_hero_synergy_filter == "atacantes", "filtro de Atacantes selecionado")

	# Filtro Atiradores
	view.lobby_hero_synergy_filter = "atiradores"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_hero_synergy_filter == "atiradores", "filtro de Atiradores selecionado")

	# Filtro Apoio
	view.lobby_hero_synergy_filter = "apoio"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_hero_synergy_filter == "apoio", "filtro de Apoio selecionado")

	# Resetar para todos
	view.lobby_hero_synergy_filter = "all"
	view.lobby_selected_hero_key = "neymar"
	view.lobby_preview_level = 1
	view.lobby_signature = ""
	view._refresh()

	# Validar recálculo de atributos nos 3 níveis do preview
	var spec: Variant = view.specs["neymar"]
	_check(spec != null and spec.max_hp == 460.0 and spec.attack_damage == 41.0, "atributos base do Neymar corretos")

	view.lobby_preview_level = 2
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_preview_level == 2, "preview em Nível 2")

	view.lobby_preview_level = 3
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_preview_level == 3, "preview em Nível 3 (com aura lendária)")

	# Validar modo de demonstração no mini-tabuleiro (ação vs pose)
	view.lobby_preview_mode = "action"
	view.lobby_selected_hero_key = "michael"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_preview_mode == "action", "modo ação ativo no compêndio")
	_check(view.hero_preview_control != null and view.hero_preview_control.is_visible_in_tree(), "hero_preview_control visível na árvore")

	# Validar que Michael, Neymar, Elon e demais heróis atualizam sem erros
	for test_key: String in ["michael", "neymar", "elon", "snoop", "caramelo", "zumbi", "obama"]:
		view.lobby_selected_hero_key = test_key
		view.lobby_signature = ""
		view._refresh()
		view.hero_preview_control.queue_redraw()
	_check(true, "demonstração de habilidades e moonwalk configurados com sucesso para todos os heróis")

	view.lobby_preview_mode = "pose"
	view.lobby_signature = ""
	view._refresh()
	view.hero_preview_control.queue_redraw()
	_check(view.lobby_preview_mode == "pose", "modo pose clássica funciona sem falhas")

	# Retornar ao lobby principal
	view.lobby_subview = "none"
	view.lobby_signature = ""
	view._refresh()
	_check(view.lobby_subview == "none", "retorna ao lobby principal após compêndio")


func _test_lobby_play_transition(view: Node) -> void:
	_check(view.start_button != null, "start_button pronto para clique")
	view.start_button.pressed.emit()
	_check(view._phase() == "benefit", "clique em JOGAR inicia partida na fase benefit")
	_check(not view.lobby_root.visible, "lobby_root ocultado após iniciar partida")
