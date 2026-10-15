extends CanvasLayer
## Interface moderna e transparente do Laboratório DEV (F6).
const Catalog = preload("res://data/character_catalog.gd")
const Items = preload("res://data/item_catalog.gd")
const PREFS_PATH = "user://devtools/devtools_prefs.json"

enum ButtonVariant {
	PRIMARY,
	SECONDARY,
	ACCENT,
	WARN,
	DANGER,
	CHIP
}

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
var shield_input: SpinBox
var mana_input: SpinBox
var speed_unit_input: SpinBox
var crit_input: SpinBox
var unit_info: Label
var boss_box: HBoxContainer
var data_text: TextEdit
var category: OptionButton
var rating: SpinBox
var subject: LineEdit
var comment: TextEdit
var feedback_list: TextEdit
var mutations: Array[Button] = []
var rating_buttons: Array[Button] = []
var panel_opacity: float = 0.90
var opacity_slider: HSlider
var opacity_label: Label
var _timer: float = 0.0

func _ready() -> void:
	layer = 30
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var theme_ui: Theme = Theme.new()
	theme_ui.default_font_size = 14
	root.theme = theme_ui

	badge = _button(root, "🛠️ F6 · DEV", toggle, false, ButtonVariant.ACCENT)
	badge.position = Vector2(244, 80)
	badge.size = Vector2(130, 32)
	badge.tooltip_text = "Abrir laboratório: controles locais, ajustes e feedbacks (F6)"

	shell = PanelContainer.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	shell.offset_left = -640
	shell.offset_right = -10
	shell.offset_top = 10
	shell.offset_bottom = -10

	var shell_style: StyleBoxFlat = StyleBoxFlat.new()
	shell_style.bg_color = Color(0.06, 0.10, 0.17, 0.92)
	shell_style.border_color = Color("38bdf8")
	shell_style.set_border_width_all(2)
	shell_style.set_corner_radius_all(12)
	shell_style.content_margin_left = 14
	shell_style.content_margin_right = 14
	shell_style.content_margin_top = 10
	shell_style.content_margin_bottom = 10
	shell.add_theme_stylebox_override("panel", shell_style)

	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	shell.add_child(body)

	# --- Cabeçalho com Título, Slider de Transparência e Fechar ---
	var heading: HBoxContainer = _row(body)
	var title: Label = Label.new()
	title.text = "🛠️ DEV TOOLS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("79e2d1"))
	title.add_theme_font_size_override("font_size", 18)
	heading.add_child(title)

	# Controle de Transparência (Atende: 'consigo mexer na transparencia desse painel tbm')
	var opacity_box: HBoxContainer = HBoxContainer.new()
	opacity_box.add_theme_constant_override("separation", 4)
	opacity_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(opacity_box)

	var eye_icon: Label = Label.new()
	eye_icon.text = "👁️"
	eye_icon.tooltip_text = "Opacidade do painel: deslize ou clique para ver o jogo através do menu"
	opacity_box.add_child(eye_icon)

	opacity_slider = HSlider.new()
	opacity_slider.min_value = 20.0
	opacity_slider.max_value = 100.0
	opacity_slider.step = 5.0
	opacity_slider.value = panel_opacity * 100.0
	opacity_slider.custom_minimum_size = Vector2(75, 20)
	opacity_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	opacity_slider.tooltip_text = "Opacidade: 20% a 100%"
	opacity_slider.value_changed.connect(func(val: float) -> void: _set_opacity(val / 100.0))
	opacity_box.add_child(opacity_slider)

	opacity_label = Label.new()
	opacity_label.text = "%d%%" % int(panel_opacity * 100.0)
	opacity_label.custom_minimum_size.x = 36
	opacity_label.add_theme_font_size_override("font_size", 12)
	opacity_label.add_theme_color_override("font_color", Color("79e2d1"))
	opacity_box.add_child(opacity_label)

	for pct in [50, 75, 90, 100]:
		var chip_pct: Button = _chip(opacity_box, "%d%%" % pct, func() -> void: _set_opacity(float(pct) / 100.0))
		chip_pct.tooltip_text = "Definir transparência em %d%%" % pct

	var close_btn: Button = _button(heading, "✖ Fechar · F6", toggle, false, ButtonVariant.DANGER)
	close_btn.tooltip_text = "Fechar o painel DEV (F6 ou Esc)"

	# --- Telemetria Resumida da Partida ---
	var summary_card: PanelContainer = PanelContainer.new()
	var summary_style: StyleBoxFlat = StyleBoxFlat.new()
	summary_style.bg_color = Color(0.09, 0.15, 0.23, 0.85)
	summary_style.border_color = Color("1e3a5f")
	summary_style.set_border_width_all(1)
	summary_style.set_corner_radius_all(6)
	summary_style.content_margin_left = 10
	summary_style.content_margin_right = 10
	summary_style.content_margin_top = 6
	summary_style.content_margin_bottom = 6
	summary_card.add_theme_stylebox_override("panel", summary_style)
	body.add_child(summary_card)

	summary = _label(summary_card, "")
	summary.custom_minimum_size.y = 42

	# --- Barra Rápida de Controle de Tempo e Relógio ---
	var clock_card: PanelContainer = PanelContainer.new()
	var clock_style: StyleBoxFlat = StyleBoxFlat.new()
	clock_style.bg_color = Color(0.08, 0.13, 0.20, 0.85)
	clock_style.border_color = Color("233c56")
	clock_style.set_border_width_all(1)
	clock_style.set_corner_radius_all(6)
	clock_style.content_margin_left = 8
	clock_style.content_margin_right = 8
	clock_style.content_margin_top = 6
	clock_style.content_margin_bottom = 6
	clock_card.add_theme_stylebox_override("panel", clock_style)
	body.add_child(clock_card)

	var clock_row: HBoxContainer = _row(clock_card)
	pause_button = _button(clock_row, "⏸️ Pausar", lab.toggle_pause, true, ButtonVariant.WARN)
	pause_button.custom_minimum_size.x = 100

	_button(clock_row, "⏱️ +0,05s", func() -> void: lab.step_once(0.05), true, ButtonVariant.ACCENT)
	_button(clock_row, "⏯️ +0,25s", func() -> void: lab.step_once(0.25), true, ButtonVariant.ACCENT)
	_button(clock_row, "⏭️ +1s", func() -> void: lab.step_once(1.0), true, ButtonVariant.ACCENT)

	var spd_lbl: Label = Label.new()
	spd_lbl.text = "Vel:"
	spd_lbl.add_theme_font_size_override("font_size", 12)
	spd_lbl.add_theme_color_override("font_color", Color("94a3b8"))
	clock_row.add_child(spd_lbl)

	for quick_spd: float in [0.5, 1.0, 2.0, 4.0]:
		var chip_spd: Button = _chip(clock_row, "%.1f×" % quick_spd, func() -> void: lab.set_speed(quick_spd), true)
		chip_spd.tooltip_text = "Velocidade %.1f×" % quick_spd

	speed_select = OptionButton.new()
	_style_button(speed_select, ButtonVariant.SECONDARY)
	clock_row.add_child(speed_select)
	for value: float in [0.1, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0]:
		speed_select.add_item("%.2f×" % value)
		speed_select.set_item_metadata(speed_select.item_count - 1, value)
	speed_select.select(3)
	speed_select.item_selected.connect(func(index: int) -> void: lab.set_speed(float(speed_select.get_item_metadata(index))))

	# --- TabContainer Estilizado ---
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_setup_tab_theme()
	body.add_child(tabs)

	_build_match(_tab("Partida"))
	_build_teams(_tab("Equipes"))
	_build_data(_tab("Dados"))
	_build_feedback(_tab("Feedbacks"))

	# --- Barra de Notificação e Status Inferior ---
	var status_card: PanelContainer = PanelContainer.new()
	var status_style: StyleBoxFlat = StyleBoxFlat.new()
	status_style.bg_color = Color(0.07, 0.11, 0.17, 0.90)
	status_style.border_color = Color("233c56")
	status_style.set_border_width_all(1)
	status_style.set_corner_radius_all(6)
	status_style.content_margin_left = 10
	status_style.content_margin_right = 10
	status_style.content_margin_top = 6
	status_style.content_margin_bottom = 6
	status_card.add_theme_stylebox_override("panel", status_style)
	body.add_child(status_card)

	status = _label(status_card, "F6 abre e fecha. Ajustes de teste locais não alteram os arquivos base.")
	status.custom_minimum_size.y = 36
	status.add_theme_color_override("font_color", Color("79e2d1"))
	status.add_theme_font_size_override("font_size", 13)

	lab.notice.connect(func(message: String) -> void: status.text = message)
	lab.changed.connect(_on_changed)

	_load_prefs()
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
	if lab.paused and lab.local_match():
		badge.text = "⏸️ F6 · PAUSADO"
		_style_button(badge, ButtonVariant.WARN)
	else:
		badge.text = "🛠️ F6 · DEV"
		_style_button(badge, ButtonVariant.ACCENT)

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
		var state_str: String = "⚠️ TESTE ALTERADO" if lab.modified else "🟢 PADRÃO"
		summary.text = "%s  |  Round %d  |  %s\nSemente %s  ·  %.2f s  ·  Tick %d  ·  %d FPS" % [
			state_str, s.sim.round_index, lab.view._phase().to_upper(), str(s._seed), s.sim.elapsed, s.sim.tick, Engine.get_frames_per_second()
		]
	else:
		summary.text = "🌐 ONLINE · Telemetria e feedbacks disponíveis" if lab.view.is_online_match else "🏠 MENU PRINCIPAL · Inicie ou configure um cenário local abaixo"

	for button: Button in mutations:
		button.disabled = not local

	if lab.paused:
		pause_button.text = "▶️ Continuar"
		_style_button(pause_button, ButtonVariant.PRIMARY)
	else:
		pause_button.text = "⏸️ Pausar"
		_style_button(pause_button, ButtonVariant.WARN)

	speed_select.disabled = not local
	freeze_check.disabled = not local
	freeze_check.set_pressed_no_signal(lab.freeze_preparation)
	for i: int in range(speed_select.item_count):
		if is_equal_approx(float(speed_select.get_item_metadata(i)), lab.speed):
			speed_select.select(i)

func _setup_tab_theme() -> void:
	var tab_sel: StyleBoxFlat = StyleBoxFlat.new()
	tab_sel.bg_color = Color("143b45")
	tab_sel.border_color = Color("38bdf8")
	tab_sel.border_width_bottom = 3
	tab_sel.set_corner_radius_all(4)
	tab_sel.content_margin_left = 14
	tab_sel.content_margin_right = 14
	tab_sel.content_margin_top = 8
	tab_sel.content_margin_bottom = 8

	var tab_unsel: StyleBoxFlat = StyleBoxFlat.new()
	tab_unsel.bg_color = Color("0d1622")
	tab_unsel.border_color = Color("1e2f42")
	tab_unsel.set_border_width_all(1)
	tab_unsel.set_corner_radius_all(4)
	tab_unsel.content_margin_left = 12
	tab_unsel.content_margin_right = 12
	tab_unsel.content_margin_top = 8
	tab_unsel.content_margin_bottom = 8

	var tab_hov: StyleBoxFlat = tab_unsel.duplicate()
	tab_hov.bg_color = Color("182d3b")
	tab_hov.border_color = Color("38bdf8")

	tabs.add_theme_stylebox_override("tab_selected", tab_sel)
	tabs.add_theme_stylebox_override("tab_unselected", tab_unsel)
	tabs.add_theme_stylebox_override("tab_hovered", tab_hov)
	tabs.add_theme_color_override("font_selected_color", Color("ffffff"))
	tabs.add_theme_color_override("font_unselected_color", Color("94a3b8"))
	tabs.add_theme_color_override("font_hovered_color", Color("e0f2fe"))

	var tabs_panel: StyleBoxFlat = StyleBoxFlat.new()
	tabs_panel.bg_color = Color(0.07, 0.11, 0.17, 0.50)
	tabs_panel.border_color = Color("1e2f42")
	tabs_panel.set_border_width_all(1)
	tabs_panel.set_corner_radius_all(8)
	tabs_panel.content_margin_left = 6
	tabs_panel.content_margin_right = 6
	tabs_panel.content_margin_top = 8
	tabs_panel.content_margin_bottom = 8
	tabs.add_theme_stylebox_override("panel", tabs_panel)

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

func _card(parent: Node, title: String, badge_text: String = "") -> VBoxContainer:
	var panel_card: PanelContainer = PanelContainer.new()
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.13, 0.20, 0.85)
	card_style.border_color = Color("233c56")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(8)
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	panel_card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(panel_card)

	var card_body: VBoxContainer = VBoxContainer.new()
	card_body.add_theme_constant_override("separation", 8)
	panel_card.add_child(card_body)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	card_body.add_child(header_row)

	var title_lbl: Label = Label.new()
	title_lbl.text = title
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color("79e2d1"))
	header_row.add_child(title_lbl)

	if not badge_text.is_empty():
		var badge_lbl: Label = Label.new()
		badge_lbl.text = badge_text
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.add_theme_color_override("font_color", Color("94a3b8"))
		header_row.add_child(badge_lbl)

	return card_body

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

func _style_button(button: Button, variant: int = ButtonVariant.SECONDARY) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bg_normal: Color
	var bg_hover: Color
	var bg_pressed: Color
	var border_normal: Color
	var border_hover: Color
	var text_color: Color = Color("ffffff")
	var corner_radius: int = 6
	var pad_x: int = 10
	var pad_y: int = 6

	match variant:
		ButtonVariant.PRIMARY:
			bg_normal = Color("0d3d30")
			bg_hover = Color("145342")
			bg_pressed = Color("092b22")
			border_normal = Color("10b981")
			border_hover = Color("34d399")
			text_color = Color("ecfdf5")
		ButtonVariant.ACCENT:
			bg_normal = Color("0d3342")
			bg_hover = Color("15465b")
			bg_pressed = Color("082430")
			border_normal = Color("06b6d4")
			border_hover = Color("38bdf8")
			text_color = Color("f0fdfa")
		ButtonVariant.WARN:
			bg_normal = Color("422a0c")
			bg_hover = Color("573810")
			bg_pressed = Color("2e1c07")
			border_normal = Color("f59e0b")
			border_hover = Color("fbbf24")
			text_color = Color("fffbeb")
		ButtonVariant.DANGER:
			bg_normal = Color("3d1419")
			bg_hover = Color("521a22")
			bg_pressed = Color("2b0c10")
			border_normal = Color("ef4444")
			border_hover = Color("f87171")
			text_color = Color("fef2f2")
		ButtonVariant.CHIP:
			bg_normal = Color("131f2e")
			bg_hover = Color("1e3148")
			bg_pressed = Color("0d1622")
			border_normal = Color("2b435d")
			border_hover = Color("38bdf8")
			text_color = Color("cbd5e1")
			corner_radius = 4
			pad_x = 6
			pad_y = 3
			button.add_theme_font_size_override("font_size", 12)
		_: # SECONDARY
			bg_normal = Color("142030")
			bg_hover = Color("1c2d44")
			bg_pressed = Color("0d1724")
			border_normal = Color("2b435d")
			border_hover = Color("4dbdb4")
			text_color = Color("e2e8f0")

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = bg_normal
	normal.border_color = border_normal
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(corner_radius)
	normal.content_margin_left = pad_x
	normal.content_margin_right = pad_x
	normal.content_margin_top = pad_y
	normal.content_margin_bottom = pad_y
	button.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = bg_hover
	hover.border_color = border_hover
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = bg_pressed
	pressed.border_color = border_hover
	button.add_theme_stylebox_override("pressed", pressed)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.1, 0.12, 0.16, 0.5)
	disabled.border_color = Color("232f3e")
	button.add_theme_stylebox_override("disabled", disabled)

	var empty_focus: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("focus", empty_focus)

	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color("64748b"))

func _button(parent: Node, text: String, callback: Callable, mutation: bool = false, variant: int = ButtonVariant.SECONDARY) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	_style_button(button, variant)
	button.pressed.connect(callback)
	parent.add_child(button)
	if mutation:
		mutations.append(button)
	return button

func _chip(parent: Node, text: String, callback: Callable, mutation: bool = false, variant: int = ButtonVariant.CHIP) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(36, 24)
	_style_button(button, variant)
	button.pressed.connect(callback)
	parent.add_child(button)
	if mutation:
		mutations.append(button)
	return button

func _number(parent: Node, title: String, minimum: float, maximum: float, value: float, step: float = 1.0) -> SpinBox:
	var row: HBoxContainer = _row(parent)
	var lbl: Label = _label(row, title)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spin: SpinBox = SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = value
	spin.custom_minimum_size.x = 155
	var line_edit: LineEdit = spin.get_line_edit()
	if line_edit != null:
		_style_input(line_edit)
	row.add_child(spin)
	return spin

func _style_input(control: Control) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b121c")
	style.border_color = Color("233c56")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	control.add_theme_stylebox_override("normal", style)
	var focus: StyleBoxFlat = style.duplicate()
	focus.border_color = Color("38bdf8")
	focus.set_border_width_all(2)
	control.add_theme_stylebox_override("focus", focus)

func _set_opacity(val: float, save_pref: bool = true) -> void:
	panel_opacity = clampf(val, 0.20, 1.0)
	shell.modulate.a = panel_opacity
	if opacity_label != null:
		opacity_label.text = "%d%%" % int(panel_opacity * 100.0)
	if opacity_slider != null and not is_equal_approx(opacity_slider.value, panel_opacity * 100.0):
		opacity_slider.set_value_no_signal(panel_opacity * 100.0)
	if save_pref:
		_save_prefs()

func _load_prefs() -> void:
	if FileAccess.file_exists(PREFS_PATH):
		var text: String = FileAccess.get_file_as_string(PREFS_PATH)
		var json: Variant = JSON.parse_string(text)
		if json is Dictionary and json.has("opacity"):
			_set_opacity(float(json["opacity"]), false)

func _save_prefs() -> void:
	var dir_path: String = ProjectSettings.globalize_path("user://devtools")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file: FileAccess = FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if file != null:
		var data: Dictionary = {"opacity": panel_opacity}
		file.store_string(JSON.stringify(data))
		file.close()

# --- ABA 0: PARTIDA ---
func _build_match(box: VBoxContainer) -> void:
	var card_round: VBoxContainer = _card(box, "⚔️ CONTROLE DO ROUND & COMBATE", "Ações imediatas")
	var row: HBoxContainer = _row(card_round)
	_button(row, "⚔️ Iniciar Combate", lab.fight, true, ButtonVariant.PRIMARY)
	_button(row, "⚡ Até o Resultado", lab.finish_combat, true, ButtonVariant.ACCENT)
	_button(row, "⏭️ Próximo Round", lab.next_round, true, ButtonVariant.ACCENT)

	var row_fast: HBoxContainer = _row(card_round)
	var win_btn: Button = _button(row_fast, "💥 Vitória Rápida (Kill Bot)", func() -> void: lab.instant_win(0), true, ButtonVariant.WARN)
	win_btn.tooltip_text = "Elimina todas as tropas adversárias imediatamente"
	var loss_btn: Button = _button(row_fast, "🏳️ Derrota Rápida (Kill Player)", func() -> void: lab.instant_win(1), true, ButtonVariant.DANGER)
	loss_btn.tooltip_text = "Elimina todas as tropas aliadas imediatamente"

	var card_timing: VBoxContainer = _card(box, "⏱️ TEMPOS DO ROUND", "Preparação e Combate")
	freeze_check = CheckBox.new()
	freeze_check.text = "❄️ Congelar cronômetro da preparação"
	freeze_check.toggled.connect(func(value: bool) -> void:
		if lab.local_match():
			lab.freeze_preparation = value
	)
	card_timing.add_child(freeze_check)

	prep_input = _number(card_timing, "Preparação restante (segundos)", 1, 600, 30)
	duration_input = _number(card_timing, "Duração do combate (segundos)", 1, 300, 30)
	acceleration_input = _number(card_timing, "Aceleração começa em (segundos)", 0, 300, 15)
	_button(card_timing, "⏱️ Aplicar Novos Tempos na Preparação", func() -> void:
		if lab.edit_timing(prep_input.value, duration_input.value, acceleration_input.value):
			status.text = "Novos tempos aplicados à partida de teste."
	, true, ButtonVariant.ACCENT)

	var card_scene: VBoxContainer = _card(box, "🎬 NOVO CENÁRIO & SEMENTE", "Inicia pausado")
	_label(card_scene, "Substitui a partida local pelo cenário escolhido. Sementes idênticas reproduzem sorteios.")

	var seed_row: HBoxContainer = _row(card_scene)
	seed_input = LineEdit.new()
	seed_input.placeholder_text = "Semente inteira diferente de zero"
	seed_input.text = "20261015"
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_input(seed_input)
	seed_row.add_child(seed_input)
	_button(seed_row, "🎲 Aleatória", func() -> void: seed_input.text = str(randi_range(1, 2147483647)), false, ButtonVariant.SECONDARY)

	round_input = _number(card_scene, "Round inicial do teste", 1, 100, 1)

	var chips_round: HBoxContainer = _row(card_scene)
	var lbl_at: Label = Label.new()
	lbl_at.text = "Atalhos:"
	lbl_at.add_theme_font_size_override("font_size", 12)
	lbl_at.add_theme_color_override("font_color", Color("94a3b8"))
	chips_round.add_child(lbl_at)
	_chip(chips_round, "R1 Início", func() -> void: round_input.value = 1)
	_chip(chips_round, "R2 Normal", func() -> void: round_input.value = 2)
	_chip(chips_round, "R3 Avançado", func() -> void: round_input.value = 3)
	var boss_chip: Button = _chip(chips_round, "👹 R4 BOSS DEV", func() -> void: round_input.value = 4, false, ButtonVariant.WARN)
	boss_chip.tooltip_text = "Abre diretamente a batalha contra o Boss Desenvolvedor"
	_chip(chips_round, "R5 Endgame", func() -> void: round_input.value = 5)

	var row_scene_btns: HBoxContainer = _row(card_scene)
	_button(row_scene_btns, "🎬 Criar Cenário (Pausado)", func() -> void:
		if not seed_input.text.is_valid_int():
			status.text = "Informe uma semente inteira válida."
			return
		if not lab.new_scenario(int(seed_input.text), int(round_input.value)):
			status.text = "Cenário recusado. Use semente inteira diferente de zero, fora do online."
	, false, ButtonVariant.PRIMARY)

	_button(row_scene_btns, "🔄 Reiniciar R1 (Semente Atual)", func() -> void:
		if lab.local_match():
			lab.new_scenario(lab.view.session._seed, 1)
	, true, ButtonVariant.SECONDARY)

# --- ABA 1: EQUIPES & COMBATENTES ---
func _build_teams(box: VBoxContainer) -> void:
	var card_econ: VBoxContainer = _card(box, "💰 ECONOMIA E GESTÃO DA EQUIPE", "Edição na preparação")

	team_select = OptionButton.new()
	team_select.add_item("Minha equipe (Jogador)", 0)
	team_select.add_item("Bot adversário", 1)
	_style_button(team_select, ButtonVariant.SECONDARY)
	team_select.item_selected.connect(func(_index: int) -> void: _load_team())
	card_econ.add_child(team_select)

	gold_input = _number(card_econ, "Ouro disponível", 0, 99999, 20)
	var gold_chips: HBoxContainer = _row(card_econ)
	_chip(gold_chips, "+10", func() -> void: gold_input.value = clampi(int(gold_input.value) + 10, 0, 99999))
	_chip(gold_chips, "+50", func() -> void: gold_input.value = clampi(int(gold_input.value) + 50, 0, 99999))
	_chip(gold_chips, "+100", func() -> void: gold_input.value = clampi(int(gold_input.value) + 100, 0, 99999))
	_chip(gold_chips, "Max 999", func() -> void: gold_input.value = 999)
	_chip(gold_chips, "Zerar 0", func() -> void: gold_input.value = 0)

	lives_input = _number(card_econ, "Vidas da partida (Corações)", 1, 5, 4)
	var lives_chips: HBoxContainer = _row(card_econ)
	_chip(lives_chips, "❤️ +1", func() -> void: lives_input.value = clampi(int(lives_input.value) + 1, 1, 5))
	_chip(lives_chips, "💔 -1", func() -> void: lives_input.value = clampi(int(lives_input.value) - 1, 1, 5))
	_chip(lives_chips, "Max 5", func() -> void: lives_input.value = 5)
	_chip(lives_chips, "1 Vida (Crítico)", func() -> void: lives_input.value = 1)

	capacity_input = _number(card_econ, "Capacidade do campo (vagas)", 4, 8, 4)
	var cap_chips: HBoxContainer = _row(card_econ)
	_chip(cap_chips, "4 Vagas", func() -> void: capacity_input.value = 4)
	_chip(cap_chips, "6 Vagas", func() -> void: capacity_input.value = 6)
	_chip(cap_chips, "8 Vagas (Máx)", func() -> void: capacity_input.value = 8)

	var team_action_row: HBoxContainer = _row(card_econ)
	_button(team_action_row, "🔄 Ler Valores Atuais", _load_team, false, ButtonVariant.SECONDARY)
	_button(team_action_row, "💾 Aplicar Equipe", func() -> void:
		if lab.edit_team(team_select.selected, int(gold_input.value), int(lives_input.value), int(capacity_input.value)):
			status.text = "Ouro, vidas e capacidade atualizados com sucesso."
	, true, ButtonVariant.ACCENT)

	var mgmt_row: HBoxContainer = _row(card_econ)
	_button(mgmt_row, "🎲 Renovar Loja Grátis", func() -> void: lab.reroll_shop_free(team_select.selected), true, ButtonVariant.SECONDARY)
	_button(mgmt_row, "🗑️ Limpar Bolsa", func() -> void: lab.clear_bag(team_select.selected), true, ButtonVariant.SECONDARY)
	_button(mgmt_row, "📦 Kit Básico", func() -> void: lab.grant_sample_items(team_select.selected), true, ButtonVariant.SECONDARY)
	_button(mgmt_row, "👥 Preencher Equipe N2", func() -> void: lab.quick_fill_team(team_select.selected, 2), true, ButtonVariant.SECONDARY)

	# Adição de Heróis
	var hero_card: VBoxContainer = _card(box, "🦸 ADICIONAR HERÓI AO CAMPO", "Gratuito no teste")
	hero_select = OptionButton.new()
	_style_button(hero_select, ButtonVariant.SECONDARY)
	hero_card.add_child(hero_select)
	for key: String in Catalog.KEYS:
		hero_select.add_item(str(lab.view.specs[key].display_name))
		hero_select.set_item_metadata(hero_select.item_count - 1, key)

	level_input = _number(hero_card, "Nível da unidade (cópias)", 1, 3, 1)
	_button(hero_card, "➕ Adicionar ao Campo / Definir Nível", func() -> void:
		if lab.grant_hero(team_select.selected, str(hero_select.get_selected_metadata()), int(level_input.value)):
			_load_units()
			status.text = "Herói atualizado no campo. Cópias e nível sincronizados."
	, true, ButtonVariant.PRIMARY)

	# Equipamentos
	var item_card: VBoxContainer = _card(box, "🎁 ITENS & EQUIPAMENTOS", "Bolsa de itens")
	var item_row: HBoxContainer = _row(item_card)
	item_select = OptionButton.new()
	item_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(item_select, ButtonVariant.SECONDARY)
	item_row.add_child(item_select)
	for key: String in Items.ITEMS:
		item_select.add_item(str(Items.ITEMS[key]["name"]))
		item_select.set_item_metadata(item_select.item_count - 1, key)

	_button(item_row, "🎁 Dar Item", func() -> void:
		if lab.grant_item(team_select.selected, str(item_select.get_selected_metadata())):
			status.text = "Item adicionado à bolsa da equipe selecionada."
	, true, ButtonVariant.ACCENT)

	# Inspetor de Combatentes
	var card_inspector: VBoxContainer = _card(box, "🛡️ INSPETOR E MODIFICADOR DE COMBATENTES", "Em combate")
	unit_select = OptionButton.new()
	_style_button(unit_select, ButtonVariant.SECONDARY)
	unit_select.item_selected.connect(func(_index: int) -> void: _load_unit())
	card_inspector.add_child(unit_select)

	var inspector_ctrl_row: HBoxContainer = _row(card_inspector)
	_button(inspector_ctrl_row, "🔄 Atualizar Lista", _load_units, false, ButtonVariant.SECONDARY)
	_button(inspector_ctrl_row, "🗑️ Dispensar na Preparação", func() -> void:
		if unit_select.selected >= 0 and lab.dismiss_hero(unit_select.get_selected_id()):
			_load_units()
	, true, ButtonVariant.DANGER)

	# Card com telemetria detalhada
	var unit_telemetry_box: PanelContainer = PanelContainer.new()
	var ut_style: StyleBoxFlat = StyleBoxFlat.new()
	ut_style.bg_color = Color(0.06, 0.10, 0.16, 0.8)
	ut_style.border_color = Color("1e3a5f")
	ut_style.set_border_width_all(1)
	ut_style.set_corner_radius_all(6)
	ut_style.content_margin_left = 10
	ut_style.content_margin_right = 10
	ut_style.content_margin_top = 8
	ut_style.content_margin_bottom = 8
	unit_telemetry_box.add_theme_stylebox_override("panel", ut_style)
	card_inspector.add_child(unit_telemetry_box)

	unit_info = _label(unit_telemetry_box, "Selecione um herói para inspecionar.")
	unit_info.add_theme_font_size_override("font_size", 13)

	# Atributos editáveis
	hp_input = _number(card_inspector, "Vida atual (HP)", 1, 100000, 1, 0.1)
	var hp_chips: HBoxContainer = _row(card_inspector)
	_chip(hp_chips, "❤️ 100% Full", func() -> void: hp_input.value = hp_input.max_value)
	_chip(hp_chips, "🩹 50% HP", func() -> void: hp_input.value = maxf(1.0, hp_input.max_value * 0.5))
	_chip(hp_chips, "⚠️ 1 HP", func() -> void: hp_input.value = 1.0)

	shield_input = _number(card_inspector, "Escudo de absorção", 0, 100000, 0, 10.0)
	var shield_chips: HBoxContainer = _row(card_inspector)
	_chip(shield_chips, "🛡️ +300", func() -> void: shield_input.value += 300.0)
	_chip(shield_chips, "🛡️ +600", func() -> void: shield_input.value += 600.0)
	_chip(shield_chips, "Zerar 0", func() -> void: shield_input.value = 0.0)

	mana_input = _number(card_inspector, "Mana atual (0 a 100)", 0, 100, 0, 5.0)
	var mana_chips: HBoxContainer = _row(card_inspector)
	_chip(mana_chips, "⚡ 100 Mana (Ult)", func() -> void: mana_input.value = 100.0)
	_chip(mana_chips, "Zerar 0", func() -> void: mana_input.value = 0.0)

	damage_input = _number(card_inspector, "Dano de ataque (AD)", 0, 100000, 0, 1.0)
	armor_input = _number(card_inspector, "Armadura física", 0, 100000, 0, 1.0)
	resist_input = _number(card_inspector, "Resistência mágica", 0, 100000, 0, 1.0)
	speed_unit_input = _number(card_inspector, "Velocidade de ataque (mult)", 0.1, 10.0, 1.0, 0.1)
	crit_input = _number(card_inspector, "Chance de crítico (%)", 0, 100, 0, 5.0)

	_button(card_inspector, "🛡️ Aplicar Atributos Neste Combate", func() -> void:
		if unit_select.selected >= 0:
			if lab.edit_unit(
				unit_select.get_selected_id(),
				hp_input.value,
				damage_input.value,
				armor_input.value,
				resist_input.value,
				shield_input.value,
				mana_input.value,
				speed_unit_input.value,
				crit_input.value
			):
				_load_unit()
				status.text = "Atributos aplicados. Duram nesta rodada; itens e buffs podem recalculá-los."
	, true, ButtonVariant.PRIMARY)

	var quick_combat_actions: HBoxContainer = _row(card_inspector)
	_button(quick_combat_actions, "💫 Stun 2s", func() -> void:
		if unit_select.selected >= 0:
			lab.stun_unit(unit_select.get_selected_id(), 2.0)
			_load_unit()
	, true, ButtonVariant.WARN)

	_button(quick_combat_actions, "✨ Limpar Stun", func() -> void:
		if unit_select.selected >= 0:
			lab.stun_unit(unit_select.get_selected_id(), 0.0)
			_load_unit()
	, true, ButtonVariant.SECONDARY)

	_button(quick_combat_actions, "💀 Eliminar Combatente", func() -> void:
		if unit_select.selected >= 0:
			lab.kill_unit(unit_select.get_selected_id())
			_load_unit()
	, true, ButtonVariant.DANGER)

	# Seção Especial do Boss Desenvolvedor
	boss_box = _row(card_inspector)
	boss_box.visible = false
	var boss_tp: Button = _button(boss_box, "🔥 Forçar Teleporte do Boss", func() -> void:
		if unit_select.selected >= 0:
			lab.boss_force_teleport(unit_select.get_selected_id())
	, true, ButtonVariant.WARN)
	boss_tp.tooltip_text = "Zera a recarga de teleporte do Boss para disparar no próximo tick"

	var boss_rage: Button = _button(boss_box, "😡 Ativar Modo Fúria", func() -> void:
		if unit_select.selected >= 0:
			lab.boss_trigger_rage(unit_select.get_selected_id())
			_load_unit()
	, true, ButtonVariant.DANGER)
	boss_rage.tooltip_text = "Ativa imediatamente o modo fúria com buffs e onda de choque"

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
		var tag: String = "Você" if unit.team == 0 else "Bot"
		var boss_tag: String = " 👹 BOSS" if unit.is_boss else ""
		unit_select.add_item("%s · %s%s · N%d · #%d" % [tag, unit.display_name, boss_tag, unit.level, unit.id], unit.id)
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
	shield_input.value = unit.shield
	mana_input.value = unit.mana
	speed_unit_input.value = unit.attack_speed_multiplier
	crit_input.value = unit.effective_crit_chance * 100.0

	boss_box.visible = unit.is_boss

	var state_desc: String = "VIVO" if unit.alive else "ELIMINADO"
	if unit.stun_remaining > 0.0:
		state_desc += " [STUN %.1fs]" % unit.stun_remaining
	if unit.is_boss and unit.boss_enraged:
		state_desc += " [FÚRIA ATIVA]"

	unit_info.text = "HP %.0f / %.0f · Escudo %.0f · Mana %.0f / 100 · %s\nAD %.1f · Arm %.0f · Res %.0f · Vel %.2f× · Crít %.0f%%\nAlvo: #%d · Hex: (%d, %d) · Dano: %.0f · Cura: %.0f · Kills: %d" % [
		unit.hp, unit.max_hp, unit.shield, unit.mana, state_desc,
		unit.attack_damage, unit.armor, unit.resist, unit.attack_speed_multiplier, unit.effective_crit_chance * 100.0,
		unit.target_id, unit.cell.x, unit.cell.y, unit.damage_dealt, unit.healing_done, unit.kills
	]

# --- ABA 2: DADOS & HISTÓRICO ---
func _build_data(box: VBoxContainer) -> void:
	var card_data: VBoxContainer = _card(box, "📊 TELEMETRIA E RELATÓRIO DA SESSÃO", "Exportação JSON")
	_label(card_data, "Snapshot do teste local: equipes, resultados, últimas 100 ações DEV e 200 eventos.")

	var row: HBoxContainer = _row(card_data)
	_button(row, "🔄 Atualizar Dados", func() -> void: data_text.text = JSON.stringify(lab.context(), "  "), false, ButtonVariant.SECONDARY)
	_button(row, "📋 Copiar JSON", func() -> void:
		DisplayServer.clipboard_set(JSON.stringify(lab.context(), "\t"))
		status.text = "Relatório completo copiado para a área de transferência."
	, false, ButtonVariant.ACCENT)
	_button(row, "💾 Salvar Relatório", _export_report, false, ButtonVariant.PRIMARY)
	_button(row, "📁 Abrir Pasta", _open_folder, false, ButtonVariant.SECONDARY)

	data_text = TextEdit.new()
	data_text.editable = false
	data_text.custom_minimum_size.y = 320
	data_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_input(data_text)
	card_data.add_child(data_text)

	_label(card_data, "Resultados são salvos automaticamente ao fim de cada round local em user://devtools.")

# --- ABA 3: FEEDBACKS ---
func _build_feedback(box: VBoxContainer) -> void:
	var card_fb: VBoxContainer = _card(box, "📝 REGISTRO DE FEEDBACK COM TELEMETRIA", "Salvo localmente")

	category = OptionButton.new()
	_style_button(category, ButtonVariant.SECONDARY)
	for title: String in ["🎮 Gameplay", "⚖️ Balanceamento", "🦸 Herói / Habilidade", "🎨 Animação / Visual", "🖥️ Interface", "🐛 Bug", "💡 Ideia"]:
		category.add_item(title)
	card_fb.add_child(category)

	var stars_row: HBoxContainer = _row(card_fb)
	var lbl_rating: Label = Label.new()
	lbl_rating.text = "Avaliação:"
	lbl_rating.add_theme_font_size_override("font_size", 13)
	stars_row.add_child(lbl_rating)

	rating = SpinBox.new()
	rating.min_value = 1
	rating.max_value = 5
	rating.value = 3
	rating.visible = false
	stars_row.add_child(rating)

	rating_buttons.clear()
	for star in [1, 2, 3, 4, 5]:
		var star_btn: Button = _chip(stars_row, "%d ⭐" % star, func() -> void: _select_star(star))
		rating_buttons.append(star_btn)
	_select_star(3)

	subject = LineEdit.new()
	subject.placeholder_text = "Assunto: herói, round, habilidade, animação..."
	subject.max_length = 200
	_style_input(subject)
	card_fb.add_child(subject)

	comment = TextEdit.new()
	comment.placeholder_text = "O que aconteceu? O que você gostaria de mudar? Deixe seus comentários para a próxima revisão."
	comment.custom_minimum_size.y = 120
	comment.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_input(comment)
	card_fb.add_child(comment)

	var fb_btn_row: HBoxContainer = _row(card_fb)
	_button(fb_btn_row, "💾 Salvar Feedback + Contexto da Partida", func() -> void:
		var cat_name: String = category.get_item_text(category.selected).split(" ")[-1]
		var path: String = lab.save_feedback(cat_name, int(rating.value), comment.text, subject.text)
		if not path.is_empty():
			comment.clear()
			_refresh_feedbacks()
	, false, ButtonVariant.PRIMARY)

	_button(fb_btn_row, "📁 Abrir Pasta", _open_folder, false, ButtonVariant.SECONDARY)

	var card_history: VBoxContainer = _card(box, "📁 ÚLTIMOS FEEDBACKS SALVOS", "Até 30 registros")
	feedback_list = TextEdit.new()
	feedback_list.editable = false
	feedback_list.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	feedback_list.custom_minimum_size.y = 150
	_style_input(feedback_list)
	card_history.add_child(feedback_list)

func _select_star(star_value: int) -> void:
	rating.value = star_value
	for i in range(rating_buttons.size()):
		var btn: Button = rating_buttons[i]
		if (i + 1) == star_value:
			_style_button(btn, ButtonVariant.WARN)
		else:
			_style_button(btn, ButtonVariant.CHIP)

func _refresh_feedbacks() -> void:
	var lines: PackedStringArray = []
	for report: Dictionary in lab.saved_feedbacks():
		var item: Dictionary = report["feedback"]
		lines.append("📅 %s · %s · Nota %d/5 · R%s\nAssunto: %s\n%s\n----------------------------------------" % [
			report.get("created_at", ""),
			item.get("category", ""),
			item.get("rating", 0),
			report.get("round", "—"),
			item.get("subject", ""),
			item.get("comment", "")
		])
	feedback_list.text = "\n".join(lines) if not lines.is_empty() else "Nenhum feedback salvo ainda."

func _open_folder() -> void:
	var path: String = ProjectSettings.globalize_path(lab.storage_dir)
	DirAccess.make_dir_recursive_absolute(path)
	if OS.has_feature("web"):
		status.text = "No navegador, use Salvar relatório para baixar o teste."
	else:
		OS.shell_open(path)
		status.text = "Pasta aberta: " + path

func _export_report() -> void:
	var report: Dictionary = lab.context()
	report["saved_feedbacks"] = lab.saved_feedbacks()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(JSON.stringify(report, "\t").to_utf8_buffer(), "clash_dev_relatorio.json", "application/json")
		status.text = "Download do relatório solicitado ao navegador."
	else:
		var path: String = lab._save("relatorio", report)
		if not path.is_empty():
			status.text = "Relatório salvo com sucesso em user://devtools."
