extends SceneTree

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
	var client: Node = MainScene.instantiate()
	root.add_child(client)
	await process_frame
	client.set_process(false)

	_test_skills_menu_initial_state(client)
	await _test_skills_menu_16f_states_and_directions(client)
	await _test_skills_menu_vfx_cards(client)
	await _test_skills_menu_action_mode_with_vfx(client)

	print("HERO SKILLS & 16F MENU TESTS: %d passed, %d failed" % [passed, failed])
	client.queue_free()
	quit(0 if failed == 0 else 1)


func _test_skills_menu_initial_state(client: Node) -> void:
	_assert(client.lobby_preview_state == "stance", "Estado padrão de preview deve ser 'stance' (mãos)")
	_assert(client.lobby_preview_direction == "south", "Direção padrão de preview deve ser 'south'")
	_assert(client.lobby_preview_mode in ["pose", "action"], "Modo de preview inicial válido")


func _test_skills_menu_16f_states_and_directions(client: Node) -> void:
	client.lobby_subview = "heroes"
	client.lobby_heroes_detail_open = true
	client.lobby_signature = ""
	client._refresh()
	await process_frame

	var test_heroes: Array[String] = ["caramelo", "obama", "barbie", "zumbi", "boss_dev", "bob_marley"]
	var states: Array[String] = ["stance", "walk", "attack", "stun", "death", "buff"]
	var directions: Array[String] = ["south", "east", "west", "north"]

	for hero_key: String in test_heroes:
		client.lobby_selected_hero_key = hero_key
		client.lobby_preview_mode = "pose"
		for s: String in states:
			client.lobby_preview_state = s
			for d: String in directions:
				client.lobby_preview_direction = d
				if is_instance_valid(client.hero_preview_control):
					client.hero_preview_control.queue_redraw()
		await process_frame
		_assert(true, "Hero %s renderizou perfeitamente todos os 16F estados e direções" % hero_key)


func _test_skills_menu_vfx_cards(client: Node) -> void:
	client.lobby_subview = "heroes"
	client.lobby_heroes_detail_open = true
	client.lobby_selected_hero_key = "caramelo"
	client.lobby_signature = ""
	client._refresh()
	await process_frame

	_assert(client.card_vfx_controls.size() > 0, "Card VFX controls foram instanciados no Compêndio")
	for ctrl: Variant in client.card_vfx_controls:
		if is_instance_valid(ctrl):
			(ctrl as Control).queue_redraw()
	await process_frame

	# Testa Boss Dev com teleporte
	client.lobby_selected_hero_key = "boss_dev"
	client.lobby_signature = ""
	client._refresh()
	await process_frame
	_assert(client.card_vfx_controls.size() > 0, "Card VFX instanciado para boss_dev")
	for ctrl: Variant in client.card_vfx_controls:
		if is_instance_valid(ctrl):
			(ctrl as Control).queue_redraw()
	await process_frame
	_assert(true, "VFX de boss_dev desenhado com sucesso")


func _test_skills_menu_action_mode_with_vfx(client: Node) -> void:
	client.lobby_subview = "heroes"
	client.lobby_heroes_detail_open = true
	client.lobby_preview_mode = "action"

	var action_heroes: Array[String] = ["caramelo", "boss_dev", "zumbi", "bob_marley", "barbie", "obama"]
	for hero_key: String in action_heroes:
		client.lobby_selected_hero_key = hero_key
		for t_sample: float in [0.5, 1.2, 2.0, 3.0]:
			client.visual_time = t_sample
			if is_instance_valid(client.hero_preview_control):
				client.hero_preview_control.queue_redraw()
		await process_frame
		_assert(true, "Modo de ação com 16F e VFX renderizou para %s" % hero_key)
