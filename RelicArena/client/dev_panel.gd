extends CanvasLayer
## Interface independente do HUD de jogo. F6 funciona inclusive dentro de campos de texto.
const Catalog = preload("res://data/character_catalog.gd")
const Items = preload("res://data/item_catalog.gd")

var lab: Node
var opened: bool = false
var shell: PanelContainer
var badge: Button
var summary: Label
var status: Label
var pause_button: Button
var speed_select: OptionButton
var tabs: TabContainer
var seed_input: LineEdit
var round_input: SpinBox
var prep_input: SpinBox
var duration_input: SpinBox
var acceleration_input: SpinBox
var freeze_check: CheckBox
var team_select: OptionButton
var gold_input: SpinBox
var lives_input: SpinBox
var capacity_input: SpinBox
var hero_select: OptionButton
var level_input: SpinBox
var item_select: OptionButton
var unit_select: OptionButton
var hp_input: SpinBox
var damage_input: SpinBox
var armor_input: SpinBox
var resist_input: SpinBox
var unit_info: Label
var data_text: TextEdit
var category: OptionButton
var rating: SpinBox
var subject: LineEdit
var comment: TextEdit
var feedback_list: TextEdit
var mutations: Array[Button] = []
var _timer: float = 0.0

func _ready() -> void:
	layer = 30
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme_ui: Theme = Theme.new()
	theme_ui.default_font_size = 15
	root.theme = theme_ui
	badge = _button(root, "F6 · DEV", toggle)
	badge.position = Vector2(244, 80)
	badge.size = Vector2(116, 30)
	badge.tooltip_text = "Abrir laboratório: controles locais e feedbacks"
	shell = PanelContainer.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	shell.offset_left = -626
	shell.offset_right = -12
	shell.offset_top = 12
	shell.offset_bottom = -12
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("101b2b")
	style.border_color = Color("4dbdb4")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	shell.add_theme_stylebox_override("panel", style)
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	shell.add_child(body)
	var heading: HBoxContainer = _row(body)
	var title: Label = _label(heading, "LABORATÓRIO  /  DEV TOOLS")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("79e2d1"))
	title.add_theme_font_size_override("font_size", 20)
	_button(heading, "Fechar · F6", toggle)
	summary = _label(body, "")
	summary.custom_minimum_size.y = 62
	var clock_row: HBoxContainer = _row(body)
	pause_button = _button(clock_row, "Pausar", lab.toggle_pause, true)
	_button(clock_row, "+0,05 s", func() -> void: lab.step_once(0.05), true)
	_button(clock_row, "+1 s", func() -> void: lab.step_once(1.0), true)
	speed_select = OptionButton.new()
	clock_row.add_child(speed_select)
	for value: float in [0.1, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0]:
		speed_select.add_item("%.2f×" % value)
		speed_select.set_item_metadata(speed_select.item_count - 1, value)
	speed_select.select(3)
	speed_select.item_selected.connect(func(index: int) -> void: lab.set_speed(float(speed_select.get_item_metadata(index))))
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	_build_match(_tab("Partida"))
	_build_teams(_tab("Equipes"))
	_build_data(_tab("Dados"))
	_build_feedback(_tab("Feedbacks"))
	status = _label(body, "F6 abre e fecha. Alterações de teste não mudam os arquivos base.")
	status.custom_minimum_size.y = 44
	status.add_theme_color_override("font_color", Color("79e2d1"))
	lab.notice.connect(func(message: String) -> void: status.text = message)
	lab.changed.connect(_on_changed)
	shell.hide()
	_refresh_feedbacks()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6 or (opened and event.keycode == KEY_ESCAPE):
			toggle()
			get_viewport().set_input_as_handled()

func toggle() -> void:
	opened = not opened
	shell.visible = opened
	if lab.view.drag != null:
		lab.view.drag._reset()
		lab.view.drag.set_process_input(not opened)
	if opened:
		_load_team()
		_load_units()
		_refresh_feedbacks()
		_refresh_summary()

func _process(delta: float) -> void:
	badge.visible = not lab.view.menu_open or lab.view.lobby_subview in ["none", "matchmaking"]
	badge.text = "F6 · PAUSADO" if lab.paused and lab.local_match() else "F6 · DEV"
	if not opened:
		return
	_timer += delta
	if _timer >= 0.25:
		_timer = 0.0
		_refresh_summary()

func _on_changed() -> void:
	if opened:
		_refresh_summary()

func _refresh_summary() -> void:
	var local: bool = lab.local_match()
	var s = lab.view.session
	if local:
		summary.text = "LOCAL · %s  |  Round %d  |  %s\nSemente %s  ·  %.2f s  ·  Tick %d  ·  %d FPS" % ["TESTE ALTERADO" if lab.modified else "PADRÃO", s.sim.round_index, lab.view._phase(), str(s._seed), s.sim.elapsed, s.sim.tick, Engine.get_frames_per_second()]
	else:
		summary.text = "ONLINE · somente feedbacks e desempenho" if lab.view.is_online_match else "MENU · crie uma partida local abaixo para experimentar"
	for button: Button in mutations:
		button.disabled = not local
	pause_button.text = "Continuar" if lab.paused else "Pausar"
	speed_select.disabled = not local
	freeze_check.disabled = not local
	freeze_check.set_pressed_no_signal(lab.freeze_preparation)
	for i: int in range(speed_select.item_count):
		if is_equal_approx(float(speed_select.get_item_metadata(i)), lab.speed):
			speed_select.select(i)

func _tab(title: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	return box

func _row(parent: Node) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	return row

func _label(parent: Node, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable, mutation: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 34
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	if mutation:
		mutations.append(button)
	return button

func _number(parent: Node, title: String, minimum: float, maximum: float, value: float, step: float = 1.0) -> SpinBox:
	var row: HBoxContainer = _row(parent)
	_label(row, title)
	var spin: SpinBox = SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = value
	spin.custom_minimum_size.x = 155
	row.add_child(spin)
	return spin

func _build_match(box: VBoxContainer) -> void:
	_label(box, "CONTROLE DO ROUND")
	var row: HBoxContainer = _row(box)
	_button(row, "Iniciar combate", lab.fight, true)
	_button(row, "Até o resultado", lab.finish_combat, true)
	_button(row, "Próximo round", lab.next_round, true)
	freeze_check = CheckBox.new()
	freeze_check.text = "Congelar cronômetro da preparação"
	freeze_check.toggled.connect(func(value: bool) -> void:
		if lab.local_match():
			lab.freeze_preparation = value
	)
	box.add_child(freeze_check)
	prep_input = _number(box, "Preparação restante (segundos)", 1, 600, 30)
	duration_input = _number(box, "Duração do combate (segundos)", 1, 300, 30)
	acceleration_input = _number(box, "Aceleração começa em (segundos)", 0, 300, 15)
	_button(box, "Aplicar tempos na preparação", func() -> void:
		if lab.edit_timing(prep_input.value, duration_input.value, acceleration_input.value):
			status.text = "Tempos aplicados à partida de teste."
	, true)
	box.add_child(HSeparator.new())
	_label(box, "NOVA PARTIDA / CENÁRIO")
	_label(box, "Substitui a partida local e começa pausado. R4 abre o Boss. Um cenário avançado começa com recursos iniciais; não simula os rounds anteriores.")
	seed_input = LineEdit.new()
	seed_input.placeholder_text = "Semente inteira diferente de zero"
	seed_input.text = "20261015"
	box.add_child(seed_input)
	round_input = _number(box, "Round inicial", 1, 100, 1)
	row = _row(box)
	_button(row, "Criar cenário", func() -> void:
		if not seed_input.text.is_valid_int():
			status.text = "Informe uma semente inteira válida."
			return
		if not lab.new_scenario(int(seed_input.text), int(round_input.value)):
			status.text = "Cenário recusado. Use semente inteira diferente de zero, fora do online."
	)
	_button(row, "Semente aleatória", func() -> void: seed_input.text = str(randi_range(1, 2147483647)))
	_button(box, "Reiniciar R1 com a semente atual", func() -> void:
		if lab.local_match():
			lab.new_scenario(lab.view.session._seed, 1)
	, true)
	_label(box, "Mesma semente repete os sorteios iniciais. Para repetir o combate, use também as mesmas escolhas e posições. Música não muda de tom com a velocidade.")

func _build_teams(box: VBoxContainer) -> void:
	_label(box, "ECONOMIA E ELENCO · EDIÇÃO NA PREPARAÇÃO")
	team_select = OptionButton.new()
	team_select.add_item("Minha equipe", 0)
	team_select.add_item("Bot adversário", 1)
	team_select.item_selected.connect(func(_index: int) -> void: _load_team())
	box.add_child(team_select)
	gold_input = _number(box, "Ouro", 0, 99999, 20)
	lives_input = _number(box, "Vidas da partida", 1, 5, 4)
	capacity_input = _number(box, "Capacidade do campo", 4, 8, 4)
	var row: HBoxContainer = _row(box)
	_button(row, "Ler valores atuais", _load_team)
	_button(row, "Aplicar equipe", func() -> void:
		if lab.edit_team(team_select.selected, int(gold_input.value), int(lives_input.value), int(capacity_input.value)):
			status.text = "Ouro, vidas e capacidade atualizados."
	, true)
	hero_select = OptionButton.new()
	box.add_child(hero_select)
	for key: String in Catalog.KEYS:
		hero_select.add_item(str(lab.view.specs[key].display_name))
		hero_select.set_item_metadata(hero_select.item_count - 1, key)
	level_input = _number(box, "Nível na partida", 1, 3, 1)
	_button(box, "Adicionar ao campo / definir nível (gratuito)", func() -> void:
		if lab.grant_hero(team_select.selected, str(hero_select.get_selected_metadata()), int(level_input.value)):
			_load_units()
			status.text = "Herói atualizado no campo. Cópias e nível sincronizados."
	, true)
	row = _row(box)
	item_select = OptionButton.new()
	item_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(item_select)
	for key: String in Items.ITEMS:
		item_select.add_item(str(Items.ITEMS[key]["name"]))
		item_select.set_item_metadata(item_select.item_count - 1, key)
	_button(row, "Dar item", func() -> void:
		if lab.grant_item(team_select.selected, str(item_select.get_selected_metadata())):
			status.text = "Item adicionado à bolsa da equipe selecionada."
	, true)
	box.add_child(HSeparator.new())
	_label(box, "INSPETOR DE COMBATENTES")
	unit_select = OptionButton.new()
	unit_select.item_selected.connect(func(_index: int) -> void: _load_unit())
	box.add_child(unit_select)
	row = _row(box)
	_button(row, "Atualizar lista e valores", _load_units)
	_button(row, "Dispensar na preparação", func() -> void:
		if unit_select.selected >= 0 and lab.dismiss_hero(unit_select.get_selected_id()):
			_load_units()
	, true)
	unit_info = _label(box, "Selecione um herói para inspecionar.")
	hp_input = _number(box, "Vida atual", 1, 100000, 1, 0.1)
	damage_input = _number(box, "Dano de ataque", 0, 100000, 0, 0.1)
	armor_input = _number(box, "Armadura", 0, 100000, 0, 0.1)
	resist_input = _number(box, "Resistência mágica", 0, 100000, 0, 0.1)
	_button(box, "Aplicar atributos neste combate", func() -> void:
		if unit_select.selected >= 0 and lab.edit_unit(unit_select.get_selected_id(), hp_input.value, damage_input.value, armor_input.value, resist_input.value):
			status.text = "Atributos aplicados. Duram nesta rodada; itens e buffs podem recalculá-los."
	, true)
	_label(box, "Pause antes de ajustar. Atributos diretos valem só no combate atual. Nível, ouro e elenco continuam nos próximos rounds desta partida.")

func _load_team() -> void:
	if not lab.local_match():
		return
	var team: int = team_select.selected
	var data: Dictionary = lab.view.session.teams[team]
	gold_input.value = int(data["gold"])
	capacity_input.value = int(data["capacity"])
	lives_input.value = lab.view.session.sim.team_lives[team]
	prep_input.value = lab.view.session.prep_remaining
	duration_input.value = lab.view.session.sim.round_duration
	acceleration_input.value = lab.view.session.sim.acceleration_at

func _load_units() -> void:
	var selected: int = unit_select.get_selected_id()
	unit_select.clear()
	if not lab.local_match():
		unit_info.text = "Disponível durante a partida local."
		return
	for unit in lab.view.session.sim.units:
		if not unit.active and unit.key not in lab.view.session.teams[unit.team]["owned"]:
			continue
		unit_select.add_item("%s · %s · N%d · #%d" % ["Você" if unit.team == 0 else "Bot", unit.display_name, unit.level, unit.id], unit.id)
		if selected == unit.id:
			unit_select.select(unit_select.item_count - 1)
	_load_unit()

func _load_unit() -> void:
	if not lab.local_match() or unit_select.selected < 0:
		return
	var unit = lab.view.session.sim.get_unit(unit_select.get_selected_id())
	if unit == null:
		return
	hp_input.max_value = unit.max_hp
	hp_input.value = unit.hp
	damage_input.value = unit.attack_damage
	armor_input.value = unit.armor
	resist_input.value = unit.resist
	unit_info.text = "HP %.1f / %.1f · Escudo %.1f · Mana %.1f\nDano causado %.1f · Cura %.1f · Alvo #%d · Hex (%d, %d)" % [unit.hp, unit.max_hp, unit.shield, unit.mana, unit.damage_dealt, unit.healing_done, unit.target_id, unit.cell.x, unit.cell.y]

func _build_data(box: VBoxContainer) -> void:
	_label(box, "DADOS DA PARTIDA E HISTÓRICO")
	_label(box, "Estado completo do teste local, equipes, resultados, últimas 100 ações DEV e 200 eventos. Atualize quando quiser inspecionar; o texto não muda enquanto você lê.")
	var row: HBoxContainer = _row(box)
	_button(row, "Atualizar dados", func() -> void: data_text.text = JSON.stringify(lab.context(), "  "))
	_button(row, "Copiar JSON", func() -> void:
		DisplayServer.clipboard_set(JSON.stringify(lab.context(), "\t"))
		status.text = "Relatório copiado."
	)
	_button(row, "Salvar relatório", _export_report)
	data_text = TextEdit.new()
	data_text.editable = false
	data_text.custom_minimum_size.y = 320
	data_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.add_child(data_text)
	_button(box, "Abrir pasta de registros", _open_folder)
	_label(box, "Resultados são salvos automaticamente ao fim de cada round local. Semente é texto no JSON para preservar precisão. Online registra apenas modo, fase e desempenho.")

func _build_feedback(box: VBoxContainer) -> void:
	_label(box, "O QUE VOCÊ ACHOU DESTE TESTE?")
	category = OptionButton.new()
	for title: String in ["Gameplay", "Balanceamento", "Herói / habilidade", "Animação / visual", "Interface", "Bug", "Ideia"]:
		category.add_item(title)
	box.add_child(category)
	rating = _number(box, "Sua nota (1 = ruim, 5 = ótimo)", 1, 5, 3)
	subject = LineEdit.new()
	subject.placeholder_text = "Assunto: herói, round, habilidade..."
	subject.max_length = 200
	box.add_child(subject)
	comment = TextEdit.new()
	comment.placeholder_text = "O que aconteceu? O que você gostaria de mudar?"
	comment.custom_minimum_size.y = 135
	comment.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.add_child(comment)
	_button(box, "Salvar feedback + contexto da partida", func() -> void:
		var path: String = lab.save_feedback(category.get_item_text(category.selected), int(rating.value), comment.text, subject.text)
		if not path.is_empty():
			comment.clear()
			_refresh_feedbacks()
	)
	_label(box, "Salvo localmente para eu consultar na próxima revisão. Não envia mensagem automática. Inclui semente, round, eventos e alterações do teste local.")
	_button(box, "Abrir pasta dos feedbacks", _open_folder)
	_label(box, "ÚLTIMOS 30 FEEDBACKS SALVOS")
	feedback_list = TextEdit.new()
	feedback_list.editable = false
	feedback_list.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	feedback_list.custom_minimum_size.y = 160
	box.add_child(feedback_list)

func _refresh_feedbacks() -> void:
	var lines: PackedStringArray = []
	for report: Dictionary in lab.saved_feedbacks():
		var item: Dictionary = report["feedback"]
		lines.append("%s · %s · Nota %d/5 · R%s\n%s\n%s\n" % [report.get("created_at", ""), item.get("category", ""), item.get("rating", 0), report.get("round", "—"), item.get("subject", ""), item.get("comment", "")])
	feedback_list.text = "\n".join(lines) if not lines.is_empty() else "Nenhum feedback salvo ainda."

func _open_folder() -> void:
	var path: String = ProjectSettings.globalize_path(lab.storage_dir)
	DirAccess.make_dir_recursive_absolute(path)
	if OS.has_feature("web"):
		status.text = "No navegador, use Salvar relatório para baixar o teste. Os feedbacks ficam neste navegador."
	else:
		OS.shell_open(path)
		status.text = path

func _export_report() -> void:
	var report: Dictionary = lab.context()
	report["saved_feedbacks"] = lab.saved_feedbacks()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(JSON.stringify(report, "\t").to_utf8_buffer(), "clash_dev_relatorio.json", "application/json")
		status.text = "Download do relatório solicitado ao navegador."
	else:
		var path: String = lab._save("relatorio", report)
		if not path.is_empty():
			status.text = "Relatório salvo. Use Abrir pasta de registros para acessar."
