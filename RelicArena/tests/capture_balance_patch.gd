extends SceneTree
## Script de captura para validar o patch de balanceamento (Neymar, Zumbi, Snoop, Bob Marley).

const MainScene: PackedScene = preload("res://main.tscn")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame

	# Garantir diretório de capturas
	DirAccess.make_dir_recursive_absolute("res://captures")

	# 1. Compêndio do Neymar (Decaimento 100% -> 80% -> 50%)
	view._open_hero_compendium("neymar")
	view.visual_time = 1.3 # 1º impacto
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_neymar_100.png")

	view.visual_time = 2.2 # 2º impacto ricochete
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_neymar_80.png")

	view.visual_time = 3.0 # 3º impacto retorno
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_neymar_50.png")

	# 2. Compêndio do Zumbi (Críticos progressivos e buff da equipe)
	view._open_hero_compendium("zumbi")
	view.visual_time = 0.5 # Gesto de inspiração da equipe
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_zumbi_inspiracao.png")

	view.visual_time = 2.8 # Estocada crítica acumulada
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_zumbi_critico.png")

	# 3. Compêndio do Snoop Dogg (Fumaça raio 2, miss 30% e buff +25%)
	view._open_hero_compendium("snoop")
	view.visual_time = 2.0
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_snoop_fumaca.png")

	# 4. Compêndio do Bob Marley (Música, reggae, notas musicais, buff +30% e debuff -30%)
	view._open_hero_compendium("bob_marley")
	view.visual_time = 1.8 # Ritmo positivo
	view._refresh_hero_preview()
	await process_frame
	await process_frame
	_capture("res://captures/patch_bob_marley_musica.png")

	print("CAPTURES GENERATED SUCCESSFULLY!")
	quit(0)

func _capture(path: String) -> void:
	var viewport: Viewport = root.get_viewport()
	var img: Image = viewport.get_texture().get_image()
	if img != null:
		img.save_png(path)
