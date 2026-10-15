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

	client.lobby_subview = "heroes"
	client.lobby_heroes_detail_open = true
	client.lobby_preview_mode = "pose"
	client.lobby_signature = ""
	client._refresh()
	await process_frame

	print("Iniciando benchmark de desempenho e latência do menu...")

	# Teste 1: 50 trocas rápidas de estados sem rebuild de UI
	var t0_states: int = Time.get_ticks_usec()
	var test_states: Array[String] = ["stance", "walk", "attack", "stun", "death", "buff"]
	for i: int in range(50):
		var target_s: String = test_states[i % test_states.size()]
		client._set_preview_state(target_s)
	var elapsed_states_us: int = Time.get_ticks_usec() - t0_states
	var avg_state_switch_us: float = float(elapsed_states_us) / 50.0
	print("Tempo para 50 trocas de estados: %d us (média: %.2f us / %.3f ms por troca)" % [elapsed_states_us, avg_state_switch_us, avg_state_switch_us / 1000.0])
	_assert(avg_state_switch_us < 3000.0, "Troca de estado de animação deve ser ultra-rápida (< 3.0 ms)")

	# Teste 2: 50 trocas rápidas de direção sem rebuild de UI
	var t0_dirs: int = Time.get_ticks_usec()
	var test_dirs: Array[String] = ["south", "east", "north", "west"]
	for i: int in range(50):
		var target_d: String = test_dirs[i % test_dirs.size()]
		client._set_preview_direction(target_d)
	var elapsed_dirs_us: int = Time.get_ticks_usec() - t0_dirs
	var avg_dir_switch_us: float = float(elapsed_dirs_us) / 50.0
	print("Tempo para 50 trocas de direção: %d us (média: %.2f us / %.3f ms por troca)" % [elapsed_dirs_us, avg_dir_switch_us, avg_dir_switch_us / 1000.0])
	_assert(avg_dir_switch_us < 3000.0, "Troca de direção deve ser ultra-rápida (< 3.0 ms)")

	# Teste 3: Desenho de 100 frames da vitrine de VFX e palco
	var t0_draw: int = Time.get_ticks_usec()
	for i: int in range(100):
		client.visual_time = float(i) * 0.033
		if is_instance_valid(client.hero_preview_control):
			client.hero_preview_control.queue_redraw()
		for ctrl: Variant in client.card_vfx_controls:
			if is_instance_valid(ctrl):
				(ctrl as Control).queue_redraw()
	await process_frame
	var elapsed_draw_us: int = Time.get_ticks_usec() - t0_draw
	print("Tempo para agendar 100 redesenhos de preview: %d us" % elapsed_draw_us)
	_assert(elapsed_draw_us < 50000, "Enfileiramento de desenho deve ser muito eficiente")

	print("BENCHMARK MENU PERFORMANCE: %d passed, %d failed" % [passed, failed])
	client.queue_free()
	quit(0 if failed == 0 else 1)
