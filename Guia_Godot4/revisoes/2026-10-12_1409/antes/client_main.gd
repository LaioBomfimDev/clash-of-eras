extends Node2D
## Visor local V1.4: câmera inclinada, arte direcional e efeitos PixelLab dos kits.
## Toda regra, moeda e resultado pertence a MatchSession; aqui só há comandos e apresentação.

const Session = preload("res://simulation/match_session.gd")
const Catalog = preload("res://data/character_catalog.gd")
const UnitSpec = preload("res://data/unit_spec.gd")
const Visuals = preload("res://client/character_visuals.gd")
const PrototypeAudio = preload("res://client/prototype_audio.gd")
const Board = preload("res://client/board_projection.gd")
const Grid = preload("res://simulation/hex_grid.gd")
const Kit = preload("res://client/ui_kit.gd")
## Arrastar e soltar (arquivo próprio); toques e botões continuam funcionando.
const DragController = preload("res://client/drag_controller.gd")
const VfxLibrary = preload("res://client/vfx_library.gd")
const MATCH_SEED: int = 20261011
const SCREEN: Vector2 = Vector2(1280, 720)
const TEAM_COLORS: Array[Color] = [Color("64dcd2"), Color("ec7a74")]
const GOLD: Color = Color("f4d58a")
const ARENA_PATH: String = "res://assets/arena/coliseu_estudo_02.png"
## Fundo PixelLab a 4× inteiro; o recorte evita a moldura original nas bordas.
const ARENA_SCALE: float = 4.0
const ARENA_OFFSET: Vector2 = Vector2(-92, -84)
const PIXEL_SHADER: Shader = preload("res://client/pixel_scale.gdshader")
## Nível na partida: +20% de tamanho por nível (1,2× e 1,44×), pedido do usuário.
const LEVEL_SCALE: Array[float] = [1.0, 1.2, 1.44]
const LEVEL_COLORS: Array[Color] = [Color("c58b4a"), Color("dfe7ef"), Color("f4d58a")]
const AURA: Color = Color("a45cff")
const KIT_TEXT: Dictionary = {
	"neymar": "Chuta bolas à distância. A bola ricocheteia entre dois inimigos vizinhos: até 3 impactos (A → B → A).",
	"caramelo": "Caça um alvo à distância no começo da luta. Morde e causa sangramento; elimina alvos com até 10% de vida.",
	"obama": "Tanque. A mala absorve dano e renova parte da própria proteção durante a luta.",
	"zumbi": "Estocadas de lança. Dá crítico e velocidade à equipe; os próprios críticos fortalecem o próximo.",
	"michael": "Moonwalk por 3 hexágonos; ao parar, dá escudo à equipe. Mantém uma cura pequena periódica aos aliados.",
	"barbie": "Vanguarda protetora. Entra com o Ken invocado; causa +30% de dano enquanto ele estiver vivo.",
	"ken": "Guardião invocado pela Barbie. Atrai os golpes destinados a ela; enquanto vive, fortalece o dano dela.",
	"elon": "Atirador espacial. Dispara minifoguetes de longo alcance com explosão em área nos hexágonos vizinhos.",
	"snoop": "Atirador de fumaça. Lança nuvem que causa dano mágico contínuo e cega inimigos (faz errar golpes).",
	"lula": "Vanguarda combativa. Ao cair pela primeira vez na rodada, tem a volta por cima e revive com 40% de vida.",
	"bob_marley": "Paz e amor: aliados próximos atacam mais rápido; inimigos, mais devagar. O raio aumenta com o nível.",
	"rapunzel": "Apoio estratégico. Usa laço de trança dourada para puxar o inimigo mais distante e atordoá-lo."
}

const LOBBY_BG_PATH: String = "res://assets/ui/lobby_background.png"

const HERO_CATALOG_KEYS: Array[String] = [
	"neymar", "caramelo", "obama", "zumbi", "michael",
	"barbie", "ken", "elon", "snoop", "lula", "bob_marley", "rapunzel"
]

const SYNERGY_INFO: Dictionary = {
	"vanguarda": {
		"name": "Vanguarda",
		"icon": "syn_vanguarda",
		"desc": "Tanques e defensores da linha de frente. Absorvem dano e protegem os aliados frágeis."
	},
	"atacantes": {
		"name": "Atacantes",
		"icon": "syn_atacantes",
		"desc": "+10%/20% de dano de ataque em 2/3 membros. Dano físico contínuo e finalização veloz."
	},
	"atiradores": {
		"name": "Atiradores",
		"icon": "syn_atiradores",
		"desc": "+15% de velocidade de ataque em 2 membros. Bombardeiam à distância com segurança."
	},
	"apoio": {
		"name": "Apoio",
		"icon": "syn_apoio",
		"desc": "+10% de vida máxima da equipe em 2 membros. Concedem cura, escudos e controle de grupo."
	}
}

const HERO_ROLES: Dictionary = {
	"neymar": "Atirador de Precisão · Ricochete",
	"caramelo": "Assassino Feroz · Sangramento e Execução",
	"obama": "Vanguarda Blindada · Mala Protetora",
	"zumbi": "Gladiador Atacante · Críticos Crescentes",
	"michael": "Apoio Protetor · Moonwalk e Escudos",
	"barbie": "Vanguarda Comandante · Invoca Ken",
	"ken": "Guardião Leal · Atrai Golpes Inimigos",
	"elon": "Artilharia Espacial · Foguetes em Área",
	"snoop": "Atirador Tático · Cortina de Fumaça",
	"lula": "Vanguarda Resiliente · Volta por Cima",
	"bob_marley": "Apoio de Ritmo · Aura de Paz e Amor",
	"rapunzel": "Apoio Estratégico · Laço de Trança Dourada"
}

var session: Session = Session.new()
var art: Visuals = Visuals.new()
var vfx: VfxLibrary = VfxLibrary.new()
var audio: PrototypeAudio = PrototypeAudio.new()
var specs: Dictionary = Catalog.load_specs()
var arena: Texture2D
var heart: Texture2D
var state: Dictionary = {}
var menu_open: bool = true
var selected_id: int = -1
var hover_cell: Vector2i = Board.INVALID
var hover_bench: int = -1
var command_index: int = 0
var visual_time: float = 0.0
var toast_remaining: float = 0.0
var toast_text: String = ""
var last_heal_sound: float = -1.0
var visual_ground: Dictionary = {}
var visual_directions: Dictionary = {}
var visual_moves: Dictionary = {}
var visual_attacks: Dictionary = {}
var visual_hits: Dictionary = {}
var visual_deaths: Dictionary = {}
var visual_pulls: Dictionary = {}
var shield_waves: Array[Dictionary] = []
var slashes: Array[Dictionary] = []
var floating: Array[Dictionary] = []
var target_hit_seq: Dictionary = {}
var log_lines: Array[String] = []
var selected_items: Array[String] = []
var drawer_mode: String = ""
var last_phase: String = ""
var shop_signature: String = ""
var bag_signature: String = ""
var card_signature: String = ""
var synergy_signature: String = ""
var drawer_signature: String = ""
var overlay_signature: String = ""

var ui: Control
var heart_controls: Array[Array] = [[], []]
var shop_buttons: Dictionary = {}
var benefit_buttons: Dictionary = {}
var bag_buttons: Dictionary = {}
var equipment_buttons: Array[Button] = []
var synergy_root: Control
var shop_root: Control
var bag_panel: Panel
var bag_root: Control
var bag_title: Label
var unit_card: Panel
var card_root: Control
var overlay_dim: ColorRect
var overlay: Panel
var drawer: Panel
var round_label: Label
var phase_label: Label
var timer_fill: ColorRect
var lives_label: Label
var bot_lives_label: Label
var gold_label: Label
var capacity_label: Label
var status_panel: Panel
var status_label: Label
var result_label: Label
var fight_button: Button
var reroll_button: Button
var capacity_button: Button
var bench_button: Button
var start_button: Button
var next_button: Button
var equip_button: Button
var fuse_button: Button
var sound_button: Button
var sound_icon_button: Button
var lobby_bg: Texture2D
var lobby_root: Control
var lobby_subview: String = "none" # "none", "heroes", "settings"
var lobby_hero_synergy_filter: String = "all"
var lobby_selected_hero_key: String = "neymar"
var lobby_preview_level: int = 1
var target_fps: int = 30
var eco_mode: bool = false
var lobby_signature: String = ""
var hero_preview_control: Control
var hud_controls: Array[Control] = []
var drag: Node2D
## Camadas: chão (este nó) → sprites com escala de pixel art → barras/efeitos/textos.
var units_layer: Node2D
var overlay_layer: Node2D
var frame_entries: Array[Dictionary] = []
var level_bursts: Array[Dictionary] = []
var kit_effects: Array[Dictionary] = []
var board_perimeter: Array[PackedVector2Array] = []
var arena_props: Array[Dictionary] = []


func _load_arena_props() -> void:
	arena_props.clear()
	var manifest_path: String = "res://assets/arena/props.json"
	if not FileAccess.file_exists(manifest_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		push_warning("Manifesto de elementos da arena inválido.")
		return
	for definition: Variant in parsed.get("props", []):
		if not definition is Dictionary:
			continue
		var path: String = str(definition.get("path", ""))
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path) as Texture2D
		var coordinates: Array = definition.get("ground", [])
		if texture == null or coordinates.size() != 2:
			continue
		var ground_point: Vector2 = Vector2(float(coordinates[0]), float(coordinates[1]))
		if Board.pick_cell(Board.project(ground_point)) != Board.INVALID:
			push_warning("Elemento decorativo omitido: pé dentro da grade.")
			continue
		var used: Rect2i = texture.get_image().get_used_rect()
		var anchor: Vector2 = Vector2(texture.get_width() * 0.5, used.end.y)
		var raw_anchor: Array = definition.get("anchor", [])
		if raw_anchor.size() == 2:
			anchor = Vector2(float(raw_anchor[0]), float(raw_anchor[1]))
		arena_props.append({"texture": texture, "ground": ground_point, "anchor": anchor,
			"scale": clampf(float(definition.get("scale", 1.0)), 0.25, 4.0)})


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Engine.max_fps = target_fps
	specs.merge(Catalog.load_summon_specs())
	art.load_assets()
	vfx.load_assets()
	add_child(audio)
	heart = load("res://assets/heart.png") as Texture2D
	arena = load(ARENA_PATH) as Texture2D if ResourceLoader.exists(ARENA_PATH) else null
	if ResourceLoader.exists(LOBBY_BG_PATH):
		lobby_bg = load(LOBBY_BG_PATH) as Texture2D
	board_perimeter = Board.perimeter_segments()
	_load_arena_props()
	units_layer = _layer(CanvasItem.TEXTURE_FILTER_LINEAR, _draw_units_layer)
	var pixel_material: ShaderMaterial = ShaderMaterial.new()
	pixel_material.shader = PIXEL_SHADER
	units_layer.material = pixel_material
	overlay_layer = _layer(CanvasItem.TEXTURE_FILTER_NEAREST, _draw_overlay_layer)
	_build_ui()
	drag = DragController.install(self)
	_refresh()
	print("CLIENT_READY: Clash of Eras V1.4 local; lobby de boas-vindas; 30 FPS; compêndio de heróis")


func _process(delta: float) -> void:
	visual_time += delta
	toast_remaining = maxf(0.0, toast_remaining - delta)
	if not menu_open:
		session.step(delta)
		_consume_events()
	_refresh()
	_update_visuals(delta)
	_prepare_frame()
	queue_redraw()
	units_layer.queue_redraw()
	overlay_layer.queue_redraw()
	if is_instance_valid(hero_preview_control) and hero_preview_control.is_visible_in_tree():
		hero_preview_control.queue_redraw()


func _layer(filter: CanvasItem.TextureFilter, painter: Callable) -> Node2D:
	var layer: Node2D = Node2D.new()
	layer.texture_filter = filter
	layer.draw.connect(painter)
	add_child(layer)
	return layer


# --- Construção da interface -------------------------------------------------

func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Kit.build_theme()
	layer.add_child(ui)
	_build_top_bar()
	_build_synergy_tracker()
	_build_bag()
	_build_unit_card()
	_build_shop()
	_build_lobby()
	drawer = _panel(ui, Rect2(380, 128, 520, 384), 0.9)
	drawer.visible = false
	overlay_dim = ColorRect.new()
	overlay_dim.color = Color(0.02, 0.03, 0.04, 0.55)
	overlay_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay_dim)
	overlay = _panel(ui, Rect2(340, 132, 600, 436), 0.9)
	result_label = _label(overlay, "", Rect2(20, 14, 560, 34), 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	result_label.visible = false # Estado consultável; só o título do overlay é renderizado.
	_show_menu()


func _build_top_bar() -> void:
	for team: int in range(2):
		var plate: Panel = _panel(ui, Rect2(12 if team == 0 else 976, 10, 292, 64))
		hud_controls.append(plate)
		var right: bool = team == 1
		_label(plate, "VOCÊ" if team == 0 else "BOT LOCAL", Rect2(14, 4, 264, 22), 16, TEAM_COLORS[team],
			HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT)
		for index: int in range(5):
			var icon: TextureRect = _icon_rect(plate, heart, Rect2((252 - index * 32) if right else (12 + index * 32), 27, 32, 32))
			heart_controls[team].append(icon)
		var lives: Label = _label(plate, "", Rect2(14, 33, 264, 22), 13, Kit.MUTED,
			HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT)
		if team == 0:
			lives_label = lives
		else:
			bot_lives_label = lives
	var stage: Panel = _panel(ui, Rect2(482, 8, 316, 70))
	hud_controls.append(stage)
	round_label = _label(stage, "", Rect2(0, 3, 316, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	phase_label = _label(stage, "", Rect2(0, 19, 316, 28), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var track: ColorRect = ColorRect.new()
	track.color = Color(0, 0, 0, 0.5)
	track.position = Vector2(20, 52)
	track.size = Vector2(276, 8)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(track)
	timer_fill = ColorRect.new()
	timer_fill.color = GOLD
	timer_fill.size = Vector2(276, 8)
	timer_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(timer_fill)
	status_panel = _panel(ui, Rect2(400, 86, 480, 30), 0.62, 15)
	status_label = _label(status_panel, "", Rect2(10, 3, 460, 22), 14, Color("f4e9ca"), HORIZONTAL_ALIGNMENT_CENTER)
	sound_icon_button = _icon_button(ui, "ui_sound", Rect2(1184, 80, 40, 34), _toggle_sound, "Som liga/desliga")
	hud_controls.append_array([_icon_button(ui, "ui_menu", Rect2(1228, 80, 40, 34), _open_menu, "Menu"), sound_icon_button,
		_icon_button(ui, "ui_scroll", Rect2(1140, 80, 40, 34), _toggle_drawer.bind("log"), "Eventos do combate")])


func _build_synergy_tracker() -> void:
	var header: Button = Button.new()
	header.text = "SINERGIAS · TESTE"
	header.flat = true
	header.position = Vector2(12, 84)
	header.size = Vector2(214, 26)
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Kit.MUTED)
	header.tooltip_text = "Grupos funcionais de teste; as sinergias cotidianas finais ainda serão escolhidas."
	header.pressed.connect(_toggle_drawer.bind("synergies"))
	ui.add_child(header)
	hud_controls.append(header)
	synergy_root = _container(ui)


func _build_bag() -> void:
	bag_panel = _panel(ui, Rect2(12, 380, 214, 196), 0.72)
	bag_title = _label(bag_panel, "", Rect2(10, 6, 196, 20), 14, GOLD)
	bag_root = _container(bag_panel)
	equip_button = _button(bag_panel, "EQUIPAR", Rect2(10, 144, 94, 40), _equip_selected)
	fuse_button = _button(bag_panel, "FUNDIR", Rect2(110, 144, 94, 40), _fuse_selected)
	equip_button.tooltip_text = "Marque 1 item e selecione um herói."
	fuse_button.tooltip_text = "Marque 2 itens de uma receita."


func _build_unit_card() -> void:
	unit_card = _panel(ui, Rect2(1040, 124, 228, 352), 0.78)
	card_root = _container(unit_card)
	bench_button = _button(unit_card, "RESERVAR", Rect2(10, 298, 208, 42), _bench_or_deploy)
	bench_button.add_theme_font_size_override("font_size", 14)


func _build_shop() -> void:
	var capacity_pill: Panel = _panel(ui, Rect2(190, 558, 180, 34), 0.72, 17)
	capacity_label = _label(capacity_pill, "", Rect2(10, 5, 160, 22), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var gold_pill: Panel = _panel(ui, Rect2(584, 554, 112, 38), 0.8, 20)
	_icon_rect(gold_pill, Kit.icon("ui_coin"), Rect2(12, 3, 32, 32))
	gold_label = _label(gold_pill, "", Rect2(48, 4, 56, 28), 22, GOLD)
	var shop: Panel = _panel(ui, Rect2(144, 596, 940, 116), 0.8)
	hud_controls.append_array([capacity_pill, gold_pill, shop])
	capacity_button = _button(shop, "ESPAÇO · 8", Rect2(8, 8, 114, 48), _command.bind("upgrade_capacity", {}))
	capacity_button.icon = Kit.icon("ui_expand")
	reroll_button = _button(shop, "RENOVAR · 2", Rect2(8, 60, 114, 48), _command.bind("reroll", {}))
	reroll_button.icon = Kit.icon("ui_refresh")
	for button: Button in [capacity_button, reroll_button]:
		button.add_theme_constant_override("icon_max_width", 28)
		button.add_theme_font_size_override("font_size", 12)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shop_root = _container(shop)
	var fight_plate: Panel = _panel(ui, Rect2(1092, 596, 176, 116), 0.8)
	hud_controls.append(fight_plate)
	fight_button = _button(fight_plate, "LUTAR", Rect2(8, 8, 160, 100), _fight)
	fight_button.icon = Kit.icon("ui_fight")
	fight_button.add_theme_constant_override("icon_max_width", 32)
	fight_button.add_theme_font_size_override("font_size", 20)
	fight_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _container(parent: Control) -> Control:
	var container: Control = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)
	return container


func _panel(parent: Control, rect: Rect2, alpha: float = 0.74, radius: int = 8) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", Kit.glass(alpha, radius))
	parent.add_child(panel)
	return panel


func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color = Kit.INK, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		## Quebra e largura antes do texto: a altura mínima é calculada já na largura final.
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
	label.position = rect.position
	label.size = rect.size
	parent.add_child(label)
	label.text = text
	label.size = rect.size
	return label


func _button(parent: Control, text: String, rect: Rect2, action: Callable) -> Button:
	var button: Button = Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.pressed.connect(func() -> void:
		audio.play_cue("click")
		action.call())
	parent.add_child(button)
	return button


func _icon_button(parent: Control, icon_name: String, rect: Rect2, action: Callable, tooltip: String) -> Button:
	var button: Button = _button(parent, "", rect, action)
	button.icon = Kit.icon(icon_name)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 32)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.tooltip_text = tooltip
	return button


func _icon_rect(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.texture = texture
	icon.position = rect.position
	icon.size = rect.size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon


func _clear(parent: Control) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


# --- Atualização da interface ------------------------------------------------

func _phase() -> String:
	return "menu" if menu_open else str(state.get("phase", "benefit"))


func _refresh() -> void:
	state = session.snapshot_for_team(0)
	var phase: String = _phase()
	var own: Dictionary = state.get("own", {})
	var prep: bool = phase == "preparation"
	var round_index: int = int(state.get("round", 1))
	var config: Dictionary = state.get("test_config", {})
	round_label.text = "RODADA %d" % round_index if phase != "menu" else "PROTÓTIPO LOCAL"
	var elapsed: float = float(state.get("elapsed", 0.0))
	var phase_names: Dictionary = {"menu": "CLASH OF ERAS", "benefit": "BENEFÍCIO",
		"preparation": "PREPARAÇÃO · %ds" % ceili(float(state.get("prep_remaining", 30))),
		"combat": "COMBATE · %ds" % maxi(0, ceili(30.0 - elapsed)) + ("  ⚡" if bool(state.get("accelerated", false)) else ""),
		"round_result": "RESULTADO", "match_over": "FIM DE PARTIDA"}
	phase_label.text = str(phase_names.get(phase, phase))
	var fraction: float = 1.0
	if phase == "preparation":
		fraction = float(state.get("prep_remaining", 30)) / maxf(1.0, float(config.get("preparation_seconds", 30)))
	elif phase == "combat":
		fraction = 1.0 - elapsed / 30.0
	timer_fill.size.x = 276.0 * clampf(fraction, 0.0, 1.0)
	timer_fill.color = Color("ef9f4f") if phase == "combat" and bool(state.get("accelerated", false)) else (TEAM_COLORS[0] if phase == "combat" else GOLD)
	var lives: Array = state.get("lives", [4, 4])
	lives_label.text = "%d vidas" % int(lives[0])
	bot_lives_label.text = "%d vidas" % int(lives[1])
	for team: int in range(2):
		for index: int in range(heart_controls[team].size()):
			var icon: TextureRect = heart_controls[team][index]
			icon.visible = index < maxi(4, int(lives[team]))
			icon.modulate = Color.WHITE if index < int(lives[team]) else Color(0.3, 0.3, 0.32, 0.55)
	var gold: int = int(own.get("gold", 0))
	var capacity: int = int(own.get("capacity", 4))
	gold_label.text = str(gold)
	capacity_label.text = "CAMPO %d/%d" % [_active_count(), capacity]
	var reroll_cost: int = int(config.get("reroll_cost", 2))
	var upgrade_cost: int = int(config.get("upgrade_cost", 8))
	reroll_button.text = "RENOVAR · %d" % reroll_cost
	reroll_button.disabled = not prep or gold < reroll_cost
	var max_cap: int = int(config.get("max_capacity", 8))
	var capacity_maximum: bool = capacity >= max_cap
	capacity_button.disabled = not prep or capacity_maximum or gold < upgrade_cost
	capacity_button.text = "CAMPO MÁX." if capacity_maximum else "ESPAÇO · %d" % upgrade_cost
	var active_units: int = _active_count()
	fight_button.disabled = not prep or active_units == 0
	fight_button.text = "EM COMBATE" if phase == "combat" else ("RECRUTE" if active_units == 0 and prep else "LUTAR")
	var hint: String = {"benefit": "Escolha um benefício para começar.",
		"preparation": "Arraste ou toque: heróis da loja entram em campo ou na reserva; itens equipam heróis.",
		"combat": "Combate automático · toque num herói para inspecionar.",
		"round_result": "Veja quem causou dano, curou e protegeu.", "match_over": "Recomece para testar outra formação."}.get(phase, "")
	if prep and active_units == 0:
		hint = "Recrute heróis na loja abaixo para colocar seu time em campo!"
	elif prep and _selected_own().is_empty() and selected_items.size() == 1:
		hint = "Item marcado: toque num herói, arraste o item até ele ou use EQUIPAR."
	elif prep and not _selected_own().is_empty():
		hint = "Toque ou arraste até um hexágono azul, a reserva ou outro herói para trocar."
	if toast_remaining > 0.0:
		hint = toast_text
	status_label.text = hint
	status_panel.visible = not hint.is_empty() and phase not in ["menu"]
	var in_match: bool = phase not in ["menu"]
	for control: Control in hud_controls + [bag_panel, synergy_root]:
		control.visible = in_match
	if lobby_root != null:
		lobby_root.visible = not in_match
		if not in_match:
			_refresh_lobby()
	_refresh_synergies(_displayed_synergies(phase, own))
	_refresh_shop(own, prep)
	_refresh_bag(own, prep)
	_refresh_card(own, prep)
	_refresh_overlay(phase)
	_refresh_drawer()
	if phase != last_phase:
		_on_phase_changed(phase)
		print("CLIENT_PHASE: %s; rodada %d; vidas %s" % [phase, round_index, lives])
		last_phase = phase


func _on_phase_changed(phase: String) -> void:
	if phase in ["preparation", "combat"]:
		visual_ground.clear()
		visual_moves.clear()
	if phase == "combat":
		drawer_mode = "" if drawer_mode != "log" else drawer_mode


## Durante o combate mostra o patamar congelado no início da rodada (morte não remove sinergia).
func _displayed_synergies(phase: String, own: Dictionary) -> Array:
	var frozen: Array = state.get("combat", {}).get("synergy_snapshot", [[], []])
	if phase in ["combat", "round_result", "match_over"] and frozen.size() > 0 and not (frozen[0] as Array).is_empty():
		return frozen[0]
	return own.get("synergies", [])


func _refresh_synergies(source: Array) -> void:
	var groups: Array = source.duplicate(true)
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("tier", 0)) != int(b.get("tier", 0)):
			return int(a.get("tier", 0)) > int(b.get("tier", 0))
		return int(a.get("count", 0)) > int(b.get("count", 0)))
	var signature: String = str(groups)
	if signature == synergy_signature:
		return
	synergy_signature = signature
	_clear(synergy_root)
	for index: int in range(groups.size()):
		var group: Dictionary = groups[index]
		var tier: int = int(group.get("tier", 0))
		var count: int = int(group.get("count", 0))
		var breakpoints: Array = group.get("breakpoints", [])
		var level: int = 0
		for threshold: Variant in breakpoints:
			if count >= int(threshold):
				level += 1
		var row: Panel = _panel(synergy_root, Rect2(12, 112 + index * 50, 214, 46), 0.66 if tier > 0 else 0.5)
		if tier > 0:
			(row.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(GOLD, 0.85)
		row.tooltip_text = "%s\n%s" % [str(group.get("name", "")), str(group.get("description", ""))]
		var badge_tier: int = 0 if level == 0 else (3 if level >= breakpoints.size() and breakpoints.size() > 1 else (2 if level >= breakpoints.size() else 1))
		var badge: Kit.Badge = Kit.Badge.new(Kit.icon("syn_" + str(group.get("key", ""))), badge_tier, 40.0)
		badge.position = Vector2(4, 3)
		row.add_child(badge)
		var group_name: String = str(group.get("name", "")).replace(" · TESTE", "")
		_label(row, group_name, Rect2(50, 3, 120, 20), 15, Color.WHITE if tier > 0 else Kit.MUTED)
		var steps: Array[String] = []
		for threshold: Variant in breakpoints:
			steps.append(str(int(threshold)))
		_label(row, " › ".join(steps), Rect2(50, 22, 120, 18), 12, GOLD if tier > 0 else Color(Kit.MUTED, 0.7))
		_label(row, str(count), Rect2(168, 8, 38, 28), 22, GOLD if tier > 0 else Kit.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)


func _refresh_shop(own: Dictionary, prep: bool) -> void:
	var offers: Array = own.get("shop", [])
	var signature: String = str(offers) + str(own.get("owned", []))
	if signature != shop_signature:
		shop_signature = signature
		_clear(shop_root)
		shop_buttons.clear()
		for index: int in range(mini(7, offers.size())):
			var offer: Dictionary = offers[index]
			var button: Button = _shop_card(offer, own, Rect2(128 + index * 115, 8, 110, 100))
			shop_buttons[str(offer["offer_id"])] = button
	for offer: Dictionary in offers:
		var offer_id: String = str(offer["offer_id"])
		if not shop_buttons.has(offer_id):
			continue
		var hero: bool = offer.get("kind", "item") == "hero"
		var maxed: bool = hero and _copies(own, str(offer.get("key", ""))) >= _max_copies()
		var unaffordable: bool = not hero and (int(own.get("gold", 0)) < int(offer.get("price", 0)) or (own.get("bag", []) as Array).size() >= int(own.get("bag_capacity", 8)))
		var button: Button = shop_buttons[offer_id]
		button.disabled = not prep or bool(offer.get("claimed", false)) or maxed or unaffordable
		button.modulate = Color(1, 1, 1, 0.55) if bool(offer.get("claimed", false)) or maxed else Color.WHITE


func _shop_card(offer: Dictionary, own: Dictionary, rect: Rect2) -> Button:
	var hero: bool = offer.get("kind", "item") == "hero"
	var key: String = str(offer.get("key", ""))
	var owned: bool = hero and (own.get("owned", []) as Array).has(key)
	var copies: int = _copies(own, key)
	var claimed: bool = bool(offer.get("claimed", false))
	var status: String = str(int(offer.get("price", 0)))
	if hero:
		status = "RECRUTADO" if claimed else ("GRÁTIS" if not owned else ("NÍVEL MÁX." if copies >= _max_copies() else "NÍVEL %d" % _level_for_copies(copies + 1)))
	elif claimed:
		status = "COMPRADO"
	var button: Button = _button(shop_root, "", rect, _command.bind("recruit" if hero else "buy_item", {"offer_id": str(offer["offer_id"])}))
	button.set_meta("status", status)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var accent: Color = Color("e0b45a") if hero else Color("6fb6e8")
	for state_name: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBoxFlat = (button.get_theme_stylebox(state_name) as StyleBoxFlat).duplicate() as StyleBoxFlat
		style.border_color = Color(accent, 0.95 if state_name == "hover" else (0.35 if state_name == "disabled" else 0.7))
		style.set_border_width_all(2 if state_name == "hover" else 1)
		button.add_theme_stylebox_override(state_name, style)
	var art_area: ColorRect = ColorRect.new()
	art_area.color = Color(accent.darkened(0.72), 0.85)
	art_area.position = Vector2(4, 4)
	art_area.size = Vector2(102, 56)
	art_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art_area)
	if hero:
		_icon_rect(button, art.portrait_for(key, 30, 28), Rect2(25, 4, 60, 56))
		if owned:
			_stars(button, Vector2(98, 7), _level_for_copies(copies), 11.0, true)
		var tags: Array[String] = []
		if specs.has(key):
			tags = specs[key].synergy_tags
		for index: int in range(tags.size()):
			_icon_rect(button, Kit.icon("syn_" + tags[index]), Rect2(6, 6 + index * 16, 14, 14))
	else:
		_icon_rect(button, Kit.icon("item_" + key), Rect2(31, 8, 48, 48))
	_label(button, str(offer.get("name", "")), Rect2(6, 62, 98, 16), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
	var description: String = str(state.get("item_catalog", {}).get(key, {}).get("description", ""))
	if hero:
		description = "Personagem gratuito: entra no campo ou na reserva." if not owned else "Cópia grátis (%d/%d): junta na hora e sobe de nível — maior e mais forte." % [copies + 1, _max_copies()]
	button.tooltip_text = "%s\n%s" % [str(offer.get("name", "")), description]
	if hero:
		_label(button, status, Rect2(48, 80, 56, 16), 11, Color("8ef0a8") if status == "GRÁTIS" else (GOLD if status.begins_with("NÍVEL ") and not claimed else Kit.MUTED), HORIZONTAL_ALIGNMENT_RIGHT)
		_label(button, "HERÓI", Rect2(6, 80, 42, 16), 10, Color(accent, 0.9))
	else:
		_label(button, "ITEM", Rect2(6, 80, 36, 16), 10, Color(accent, 0.9))
		if status == "COMPRADO":
			_label(button, status, Rect2(44, 80, 60, 16), 11, Kit.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		else:
			_icon_rect(button, Kit.icon("ui_coin"), Rect2(68, 80, 14, 14))
			_label(button, status, Rect2(84, 78, 22, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	return button


func _refresh_bag(own: Dictionary, prep: bool) -> void:
	var bag: Array = own.get("bag", [])
	var capacity: int = int(own.get("bag_capacity", 8))
	for item_id: String in selected_items.duplicate():
		if _item_index(bag, item_id) < 0:
			selected_items.erase(item_id)
	var signature: String = str(bag) + str(selected_items) + str(prep)
	if signature != bag_signature:
		bag_signature = signature
		_clear(bag_root)
		bag_buttons.clear()
		bag_title.text = "ITENS %d/%d" % [bag.size(), capacity]
		for index: int in range(capacity):
			var item: Dictionary = bag[index] if index < bag.size() else {}
			var item_id: String = str(item.get("id", ""))
			var slot: Button = _button(bag_root, "", Rect2(10 + (index % 4) * 49, 32 + (index / 4) * 52, 46, 46), _select_item.bind(item_id))
			slot.disabled = item.is_empty() or not prep
			if not item.is_empty():
				_icon_rect(slot, Kit.icon("item_" + str(item.get("key", ""))), Rect2(7, 7, 32, 32))
				slot.tooltip_text = "%s\n%s" % [_item_name(item), str(state.get("item_catalog", {}).get(str(item.get("key", "")), {}).get("description", ""))]
				bag_buttons[item_id] = slot
				if item_id in selected_items:
					var style: StyleBoxFlat = (slot.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
					style.border_color = GOLD
					style.set_border_width_all(3)
					style.bg_color = Color(0.32, 0.26, 0.1, 0.9)
					slot.add_theme_stylebox_override("normal", style)
					slot.add_theme_stylebox_override("hover", style)
					slot.add_theme_stylebox_override("disabled", style)
	equip_button.disabled = not prep or selected_items.size() != 1 or _selected_own().is_empty()
	fuse_button.disabled = not prep or selected_items.size() != 2


func _refresh_card(own: Dictionary, prep: bool) -> void:
	var unit: Dictionary = _unit_by_id(selected_id)
	var phase: String = _phase()
	unit_card.visible = not unit.is_empty() and phase in ["preparation", "combat"]
	if not unit_card.visible:
		card_signature = ""
		return
	var equipment: Array = (own.get("equipment", {}) as Dictionary).get(selected_id, [])
	var signature: String = str([unit.get("id"), unit.get("level"), unit.get("active"), unit.get("max_hp"), unit.get("attack_damage"), unit.get("armor"), unit.get("resist"), unit.get("effective_crit_chance"), unit.get("attack_speed_multiplier"), equipment, prep, phase])
	var hp_ratio: float = clampf(float(unit.get("hp", 0)) / maxf(1.0, float(unit.get("max_hp", 1))), 0.0, 1.0)
	if signature == card_signature:
		var fill: ColorRect = card_root.get_node_or_null("HpFill") as ColorRect
		if fill != null:
			fill.size.x = 208.0 * hp_ratio
			(card_root.get_node("HpText") as Label).text = "%d / %d" % [ceili(float(unit.get("hp", 0))), ceili(float(unit.get("max_hp", 1)))]
		return
	card_signature = signature
	_clear(card_root)
	equipment_buttons.clear()
	var key: String = str(unit.get("key", ""))
	var team: int = int(unit.get("team", 0))
	var frame: ColorRect = ColorRect.new()
	frame.color = Color(TEAM_COLORS[team].darkened(0.7), 0.9)
	frame.position = Vector2(10, 10)
	frame.size = Vector2(60, 56)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(frame)
	_icon_rect(card_root, art.portrait_for(key, 30, 28), Rect2(10, 10, 60, 56))
	_stars(card_root, Vector2(40, 60), int(unit.get("level", 1)), 14.0)
	_label(card_root, str(unit.get("name", "Herói")), Rect2(78, 8, 140, 24), 19, TEAM_COLORS[team])
	var spec: Variant = specs.get(key, null)
	var magic: bool = str(unit.get("damage_type", "physical")) == "magic"
	var reach: int = spec.attack_range if spec != null else 1
	_label(card_root, ("Mágico" if magic else "Físico") + " · alc. %d · nível %d" % [reach, int(unit.get("level", 1))], Rect2(78, 31, 146, 18), 12, Kit.MUTED)
	var tags: Array = unit.get("synergy_tags", [])
	for index: int in range(tags.size()):
		var badge: Kit.Badge = Kit.Badge.new(Kit.icon("syn_" + str(tags[index])), 2, 22.0)
		badge.position = Vector2(78 + index * 26, 48)
		card_root.add_child(badge)
	if not unit.has("max_hp"):
		_label(card_root, "Formação da rodada %d.\nAtributos e itens atuais do adversário ficam ocultos." % int(state.get("enemy", {}).get("previous_round", 0)), Rect2(10, 80, 208, 120), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		bench_button.visible = false
		return
	var track: ColorRect = ColorRect.new()
	track.color = Color(0, 0, 0, 0.55)
	track.position = Vector2(10, 74)
	track.size = Vector2(208, 16)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(track)
	var fill_bar: ColorRect = ColorRect.new()
	fill_bar.name = "HpFill"
	fill_bar.color = TEAM_COLORS[team]
	fill_bar.position = Vector2(10, 74)
	fill_bar.size = Vector2(208.0 * hp_ratio, 16)
	fill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(fill_bar)
	var hp_text: Label = _label(card_root, "%d / %d" % [ceili(float(unit.get("hp", 0))), ceili(float(unit.get("max_hp", 1)))], Rect2(10, 72, 208, 18), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	hp_text.name = "HpText"
	var speed: float = (spec.attacks_per_second if spec != null else 1.0) * float(unit.get("attack_speed_multiplier", 1.0))
	var stats: Array[String] = [
		"ATQ  %d" % roundi(float(unit.get("attack_damage", 0))), "VEL  %.2f/s" % speed,
		"ARM  %d" % roundi(float(unit.get("armor", 0))), "RES  %d" % roundi(float(unit.get("resist", 0))),
		"CRÍT  %d%%" % roundi(float(unit.get("effective_crit_chance", 0)) * 100.0), "ALC  %d" % reach]
	for index: int in range(stats.size()):
		_label(card_root, stats[index], Rect2(12 + (index % 2) * 106, 96 + (index / 2) * 20, 104, 20), 13, Color("dfe6e3"))
	_label(card_root, str(KIT_TEXT.get(key, "")), Rect2(10, 156, 208, 82), 12, Color("c9d8d2"), HORIZONTAL_ALIGNMENT_LEFT, true)
	var own_unit: bool = team == 0
	for index: int in range(4):
		var item: Dictionary = equipment[index] if index < equipment.size() else {}
		var slot: Button = _button(card_root, "", Rect2(10 + index * 54, 242, 46, 46), _command.bind("unequip", {"unit_id": selected_id, "item_id": str(item.get("id", ""))}))
		slot.disabled = item.is_empty() or not prep or not own_unit
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not item.is_empty():
			_icon_rect(slot, Kit.icon("item_" + str(item.get("key", ""))), Rect2(7, 7, 32, 32))
			slot.tooltip_text = "%s · toque para devolver à bolsa ou arraste para outro herói" % _item_name(item)
		equipment_buttons.append(slot)
	bench_button.visible = own_unit and phase == "preparation"
	bench_button.disabled = not prep
	bench_button.text = "RESERVAR" if bool(unit.get("active", false)) else "COLOCAR EM CAMPO"


func _show_menu() -> void:
	menu_open = true
	lobby_subview = "none"
	visual_pulls.clear()
	for effects: Array in [kit_effects, shield_waves, slashes, floating, level_bursts]:
		effects.clear()
	drawer_mode = ""
	overlay_signature = ""
	lobby_signature = ""
	_refresh()


func _open_menu() -> void:
	_show_menu()


func _start_match() -> void:
	session.reset(MATCH_SEED)
	menu_open = false
	lobby_subview = "none"
	selected_id = -1
	selected_items.clear()
	target_hit_seq.clear()
	for effects: Variant in [visual_ground, visual_directions, visual_moves, visual_attacks, visual_hits, visual_deaths, visual_pulls, shield_waves, slashes, floating, log_lines, level_bursts, kit_effects]:
		effects.clear()
	drawer_mode = ""
	overlay_signature = ""
	lobby_signature = ""
	_consume_events()
	_refresh()
	_update_visuals(1.0)


func _command(op: String, payload: Dictionary = {}) -> Dictionary:
	command_index += 1
	var response: Dictionary = session.apply_command(0, "ui_%d" % command_index, op, payload)
	if not bool(response.get("ok", false)):
		var message: String = _error_text(str(response.get("code", "rejeitada")))
		log_lines.push_front("Ação: " + message)
		toast_text = message
		toast_remaining = 3.0
	_consume_events()
	_refresh()
	return response


func _error_text(code: String) -> String:
	var names: Dictionary = {"not_enough_gold": "Moedas insuficientes", "bag_full": "Bolsa cheia", "capacity_full": "Campo cheio; aumente a capacidade",
		"capacity_maximum": "Capacidade máxima de campo atingida", "wrong_phase": "Ação disponível na preparação",
		"invalid_placement": "Escolha um hexágono azul livre", "equipment_full": "Máximo de quatro itens por herói",
		"already_owned": "Você já tem este herói", "invalid_recipe": "Esses itens não formam uma receita",
		"invalid_item": "Item não está disponível", "not_owned": "Herói ainda não recrutado",
		"empty_formation": "Recrute ou coloque ao menos um herói em campo para lutar", "invalid_swap": "Troca indisponível", "not_active": "Herói não está em campo",
		"max_level": "Este herói já está no nível máximo (3)"}
	return str(names.get(code, code.replace("_", " ")))


func _select_unit(unit_id: int) -> void:
	if _phase() not in ["preparation", "combat"]:
		return
	selected_id = unit_id
	card_signature = ""
	_refresh()
	queue_redraw()


func _fight() -> void:
	if _phase() == "preparation":
		_command("ready")
		drawer_mode = ""
		_refresh()


func _next_round() -> void:
	_command("next_round")
	target_hit_seq.clear()
	for effects: Variant in [visual_ground, visual_moves, visual_attacks, visual_hits, visual_deaths, visual_pulls, shield_waves, slashes, floating, level_bursts, kit_effects]:
		effects.clear()
	_refresh()


func _bench_or_deploy() -> void:
	var unit: Dictionary = _selected_own()
	if unit.is_empty():
		return
	if bool(unit.get("active", false)):
		_command("bench", {"unit_id": selected_id})
	else:
		toast_text = "Toque num hexágono azul para colocar este herói."
		toast_remaining = 3.0


# --- Entrada: toque/clique no mundo ------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_cell = Board.pick_cell((event as InputEventMouseMotion).position)
		hover_bench = Board.pick_bench((event as InputEventMouseMotion).position)
		return
	if not event is InputEventMouseButton or not drawer_mode.is_empty():
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	var phase: String = _phase()
	if phase == "combat":
		var inspected: Dictionary = _unit_at_point(mouse.position)
		selected_id = int(inspected.get("id", -1)) if not inspected.is_empty() else -1
		card_signature = ""
		return
	if phase != "preparation":
		return
	_preparation_click(mouse.position)


func _preparation_click(point: Vector2) -> void:
	var cell: Vector2i = Board.pick_cell(point)
	var slot: int = Board.pick_bench(point)
	var selected: Dictionary = _selected_own()
	if selected.is_empty():
		var picked: Dictionary = _unit_at_point(point)
		if picked.is_empty() and cell != Board.INVALID:
			picked = _own_unit_at(cell)
		if picked.is_empty() and slot >= 0:
			picked = _bench_unit(slot)
		if not picked.is_empty():
			if not selected_items.is_empty() and int(picked.get("team", 1)) == 0 and selected_items.size() == 1:
				_select_unit(int(picked["id"]))
				_equip_selected()
				return
			_select_unit(int(picked["id"]))
		return
	var active: bool = bool(selected.get("active", false))
	if cell != Board.INVALID:
		var occupant: Dictionary = _own_unit_at(cell)
		if occupant.is_empty():
			_command("place" if active else "deploy", {"unit_id": selected_id, "cell": cell})
		elif int(occupant["id"]) == selected_id:
			_select_unit(-1)
		elif not active:
			_command("swap", {"active_id": int(occupant["id"]), "bench_id": selected_id})
		else:
			_select_unit(int(occupant["id"]))
		return
	if slot >= 0:
		var resting: Dictionary = _bench_unit(slot)
		if active and resting.is_empty():
			_command("bench", {"unit_id": selected_id})
		elif active:
			_command("swap", {"active_id": selected_id, "bench_id": int(resting["id"])})
		elif not resting.is_empty() and int(resting["id"]) != selected_id:
			_select_unit(int(resting["id"]))
		else:
			_select_unit(-1)
		return
	var other: Dictionary = _unit_at_point(point)
	_select_unit(int(other.get("id", -1)) if not other.is_empty() else -1)


## Seleção pelo corpo do sprite, da frente para o fundo; calculada do estado atual.
func _unit_at_point(point: Vector2) -> Dictionary:
	var entries: Array[Dictionary] = _draw_entries()
	for index: int in range(entries.size() - 1, -1, -1):
		var unit: Dictionary = entries[index]["unit"]
		if not bool(unit.get("alive", true)):
			continue
		var feet: Vector2 = Board.project(entries[index]["ground"])
		var texture: Texture2D = art.texture_for(str(unit.get("key", "")), "south", 0.0)
		var scale: float = LEVEL_SCALE[clampi(int(unit.get("level", 1)), 1, 3) - 1]
		var height: float = (art.height_for(texture) if texture != null else 46.0) * scale
		if Rect2(feet.x - 16 * scale, feet.y - height - 2, 32 * scale, height + 8).has_point(point):
			return unit
	return {}


func _own_unit_at(cell: Vector2i) -> Dictionary:
	for unit: Dictionary in state.get("own", {}).get("units", []):
		if bool(unit.get("active", false)) and _cell(unit.get("cell", [])) == cell:
			return unit
	return {}


func _bench_unit(slot: int) -> Dictionary:
	var bench: Array = state.get("own", {}).get("bench", [])
	return _unit_by_id(int(bench[slot])) if slot >= 0 and slot < bench.size() else {}


func _bench_slot_of(unit_id: int) -> int:
	return (state.get("own", {}).get("bench", []) as Array).find(unit_id)


func _selected_own() -> Dictionary:
	for unit: Dictionary in state.get("own", {}).get("units", []):
		if int(unit.get("id", -1)) == selected_id:
			return unit
	return {}


# --- Overlays e gaveta --------------------------------------------------------

func _refresh_overlay(phase: String) -> void:
	var signature: String = phase
	if phase == "benefit":
		signature += str(state.get("own", {}).get("benefit_options", []))
	if phase in ["round_result", "match_over"]:
		signature += str(state.get("combat", {}).get("result", {}))
	if signature == overlay_signature:
		return
	overlay_signature = signature
	for child: Node in overlay.get_children():
		if child != result_label:
			overlay.remove_child(child)
			child.queue_free()
	benefit_buttons.clear()
	result_label.text = ""
	var visible: bool = phase in ["benefit", "round_result", "match_over"]
	overlay.visible = visible
	overlay_dim.visible = visible or (phase == "menu" and lobby_subview != "none")
	if phase == "menu":
		pass
	elif phase == "benefit":
		_label(overlay, "ESCOLHA 1 BENEFÍCIO", Rect2(0, 18, 600, 34), 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		var options: Array = state.get("own", {}).get("benefit_options", [])
		for index: int in range(mini(3, options.size())):
			var option: Dictionary = options[index]
			var option_id: String = str(option["option_id"])
			var button: Button = _button(overlay, "", Rect2(24 + index * 188, 70, 176, 340), _command.bind("choose_benefit", {"option_id": option_id}))
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var kind: String = str(option.get("kind", ""))
			var keys: Array = option.get("item_keys", [])
			var icon: Texture2D = heart if kind == "life" else (Kit.icon("ui_coin") if kind == "gold" else Kit.icon("item_" + str(keys[0] if not keys.is_empty() else "blade")))
			_icon_rect(button, icon, Rect2(40, 34, 96, 96))
			_label(button, str(option.get("name", "Benefício")), Rect2(8, 150, 160, 26), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
			_label(button, str(option.get("description", "")), Rect2(14, 184, 148, 120), 14, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
			_label(button, "ESCOLHER", Rect2(8, 300, 160, 24), 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			benefit_buttons[option_id] = button
	elif phase in ["round_result", "match_over"]:
		var result: Dictionary = state.get("combat", {}).get("result", {})
		var winner: int = int(state.get("match_winner", -1)) if phase == "match_over" else int(result.get("winner", -1))
		var heading: String = "EMPATE" if winner < 0 else ("VOCÊ VENCEU" if winner == 0 else "BOT VENCEU")
		result_label.text = heading + (" A PARTIDA" if phase == "match_over" else " A RODADA")
		var heading_label: Label = _label(overlay, result_label.text, Rect2(0, 14, 600, 36), 28, GOLD if winner == 0 else (TEAM_COLORS[1] if winner == 1 else Kit.INK), HORIZONTAL_ALIGNMENT_CENTER)
		heading_label.name = "ResultHeading"
		var reason: String = {"elimination": "por eliminação", "survivors": "por sobreviventes", "damage": "por dano causado", "draw": "sem perda de vida"}.get(str(result.get("reason", "")), "")
		_label(overlay, reason, Rect2(0, 50, 600, 20), 14, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		for column: Array in [["HERÓI", 86], ["DANO", 252], ["CURA", 392], ["ESCUDO", 482]]:
			_label(overlay, str(column[0]), Rect2(float(column[1]), 80, 100, 18), 13, TEAM_COLORS[0])
		var summaries: Array = result.get("units_summary", [])
		var rows: Array = summaries.filter(func(unit: Dictionary) -> bool: return int(unit.get("team", 1)) == 0 and bool(unit.get("active", true)))
		var top_damage: float = 1.0
		for unit: Dictionary in rows:
			top_damage = maxf(top_damage, float(unit.get("damage_dealt", 0)))
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.name = "ResultRows"
		scroll.position = Vector2(0, 102)
		scroll.size = Vector2(600, 264)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		overlay.add_child(scroll)
		var table: Control = Control.new()
		table.name = "Table"
		var row_height: float = 44.0 if rows.size() > 5 else 50.0
		table.custom_minimum_size = Vector2(578, rows.size() * row_height)
		table.mouse_filter = Control.MOUSE_FILTER_PASS
		scroll.add_child(table)
		for line: int in range(rows.size()):
			var unit: Dictionary = rows[line]
			var y: float = line * row_height
			_icon_rect(table, art.portrait_for(str(unit.get("key", "")), 26, 24), Rect2(28, y, 44, 40)).modulate = Color.WHITE if bool(unit.get("alive", true)) else Color(0.55, 0.55, 0.55, 0.8)
			_label(table, str(unit.get("name", "Herói")), Rect2(86, y + 2, 150, 22), 16).set_meta("unit_id", int(unit["id"]))
			_stars(table, Vector2(92, y + 32), int(unit.get("level", 1)), 12.0, true)
			var bar: ColorRect = ColorRect.new()
			bar.color = Color(GOLD, 0.75)
			bar.position = Vector2(252, y + 27)
			bar.size = Vector2(120.0 * float(unit.get("damage_dealt", 0)) / top_damage, 4)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			table.add_child(bar)
			_label(table, "%d" % roundi(float(unit.get("damage_dealt", 0))), Rect2(252, y + 4, 100, 22), 17, GOLD)
			_label(table, "%d" % roundi(float(unit.get("healing_done", 0))), Rect2(392, y + 4, 80, 22), 17, Color("86eda5"))
			_label(table, "%d" % roundi(float(unit.get("shield_absorbed", 0))), Rect2(482, y + 4, 80, 22), 17, Color("b1daff"))
		next_button = _button(overlay, "NOVA PARTIDA" if phase == "match_over" else "PRÓXIMA RODADA", Rect2(180, 374, 240, 48), _start_match if phase == "match_over" else _next_round)
		next_button.add_theme_font_size_override("font_size", 18)


func _toggle_drawer(mode: String) -> void:
	drawer_mode = "" if drawer_mode == mode else mode
	drawer_signature = ""
	_refresh_drawer()


func _refresh_drawer() -> void:
	drawer.visible = not drawer_mode.is_empty() and not menu_open and _phase() not in ["benefit", "round_result", "match_over"]
	if not drawer.visible:
		return
	var own: Dictionary = state.get("own", {})
	var signature: String = drawer_mode + str(own.get("synergies", [])) + str(log_lines)
	if signature == drawer_signature:
		return
	drawer_signature = signature
	_clear(drawer)
	_label(drawer, {"log": "EVENTOS DO COMBATE", "synergies": "SINERGIAS DO PROTÓTIPO · TESTE"}.get(drawer_mode, ""), Rect2(16, 12, 440, 24), 17, GOLD)
	_button(drawer, "X", Rect2(474, 8, 36, 32), _toggle_drawer.bind(drawer_mode))
	if drawer_mode == "synergies":
		var groups: Array = own.get("synergies", [])
		for index: int in range(groups.size()):
			var group: Dictionary = groups[index]
			var badge: Kit.Badge = Kit.Badge.new(Kit.icon("syn_" + str(group.get("key", ""))), 2 if int(group.get("tier", 0)) > 0 else 0, 40.0)
			badge.position = Vector2(16, 52 + index * 76)
			drawer.add_child(badge)
			_label(drawer, "%s · %d membros" % [str(group.get("name", "Grupo")).replace(" · TESTE", ""), int(group.get("count", 0))], Rect2(66, 52 + index * 76, 430, 22), 16, TEAM_COLORS[0] if int(group.get("tier", 0)) > 0 else GOLD)
			_label(drawer, str(group.get("description", "")), Rect2(66, 76 + index * 76, 430, 20), 14)
		_label(drawer, "Grupos funcionais de teste; as identidades cotidianas finais ainda serão escolhidas com o usuário.", Rect2(16, 300, 488, 60), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		return
	_label(drawer, "\n".join(log_lines.slice(0, 15)), Rect2(18, 48, 484, 324), 14, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)


# --- Itens --------------------------------------------------------------------

func _item_name(item: Dictionary) -> String:
	return str(state.get("item_catalog", {}).get(str(item.get("key", "")), {}).get("name", item.get("key", "Item")))


func _item_index(items: Array, item_id: String) -> int:
	for index: int in range(items.size()):
		if str(items[index].get("id", "")) == item_id:
			return index
	return -1


func _set_animation_fps(rate: int) -> void:
	art.fps = float(rate)
	lobby_signature = ""
	_refresh()


func _set_engine_fps(fps: int) -> void:
	target_fps = fps
	Engine.max_fps = fps
	lobby_signature = ""
	_refresh()


func _toggle_eco_mode() -> void:
	eco_mode = not eco_mode
	lobby_signature = ""
	_refresh()


func _toggle_sound() -> void:
	audio.set_enabled(not audio.enabled)
	if is_instance_valid(sound_button):
		sound_button.text = "SOM: LIGADO" if audio.enabled else "SOM: DESLIGADO"
	sound_icon_button.modulate = Color.WHITE if audio.enabled else Color(1, 1, 1, 0.4)


func _select_item(item_id: String) -> void:
	if item_id.is_empty():
		return
	if item_id in selected_items:
		selected_items.erase(item_id)
	else:
		if selected_items.size() >= 2:
			selected_items.pop_front()
		selected_items.append(item_id)
	bag_signature = ""
	_refresh()


func _equip_selected() -> void:
	if selected_items.size() == 1 and not _selected_own().is_empty():
		_command("equip", {"unit_id": selected_id, "item_id": selected_items[0]})
		selected_items.clear()
		bag_signature = ""
		_refresh()


func _fuse_selected() -> void:
	if selected_items.size() == 2:
		_command("fuse", {"item_ids": selected_items.duplicate()})
		selected_items.clear()
		bag_signature = ""
		_refresh()


# --- Consultas do estado -------------------------------------------------------

func _active_count() -> int:
	var count: int = 0
	for unit: Dictionary in state.get("own", {}).get("units", []):
		if bool(unit.get("active", false)):
			count += 1
	return count


func _unit_by_id(unit_id: int) -> Dictionary:
	if unit_id < 0:
		return {}
	for source: Array in [state.get("combat", {}).get("units", []) if _phase() in ["combat", "round_result", "match_over"] else [], state.get("own", {}).get("units", []), state.get("enemy", {}).get("units", [])]:
		for unit: Dictionary in source:
			if int(unit.get("id", -1)) == unit_id:
				return unit
	return {}


## Lista desenhável: {unit, ground, ghost, bench}. Reserva só aparece para o próprio jogador.
func _draw_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var phase: String = _phase()
	if phase == "menu":
		return entries
	var combat_view: bool = phase in ["combat", "round_result", "match_over"]
	var board_units: Array = state.get("combat", {}).get("units", []) if combat_view else state.get("own", {}).get("units", [])
	for unit: Dictionary in board_units:
		if bool(unit.get("active", false)):
			entries.append({"unit": unit, "ghost": false, "bench": false})
	if not combat_view:
		for unit: Dictionary in state.get("enemy", {}).get("units", []):
			entries.append({"unit": unit, "ghost": true, "bench": false})
	var bench: Array = state.get("own", {}).get("bench", [])
	for slot: int in range(mini(bench.size(), Board.BENCH_SLOTS)):
		for unit: Dictionary in state.get("own", {}).get("units", []):
			if int(unit.get("id", -1)) == int(bench[slot]):
				entries.append({"unit": unit, "ghost": false, "bench": true, "slot": slot})
	for entry: Dictionary in entries:
		var unit_id: int = int(entry["unit"]["id"])
		var target: Vector2 = Board.bench_ground(int(entry["slot"])) if bool(entry["bench"]) else Board.ground(_cell(entry["unit"].get("cell", [])))
		entry["target"] = target
		entry["ground"] = visual_ground.get(unit_id, target) if not bool(entry["bench"]) else target
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx((a["ground"] as Vector2).y, (b["ground"] as Vector2).y):
			return (a["ground"] as Vector2).y > (b["ground"] as Vector2).y
		return (a["ground"] as Vector2).x < (b["ground"] as Vector2).x)
	return entries


func _cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	return Vector2i(int(value[0]), int(value[1])) if value is Array and value.size() >= 2 else Vector2i(-1, -1)


func _pick_cell(point: Vector2) -> Vector2i:
	return Board.pick_cell(point)


func _cell_position(cell: Vector2i) -> Vector2:
	return Board.cell_position(cell)


# --- Animação e efeitos ---------------------------------------------------------

func _update_visuals(delta: float) -> void:
	var combat: bool = _phase() == "combat"
	for entry: Dictionary in _draw_entries():
		var unit: Dictionary = entry["unit"]
		var unit_id: int = int(unit["id"])
		var target: Vector2 = entry["target"]
		if bool(entry["bench"]):
			visual_ground.erase(unit_id)
			visual_directions[unit_id] = "south"
			continue
		var previous: Vector2 = visual_ground.get(unit_id, target)
		var direction: String = str(visual_directions.get(unit_id, "south"))
		if visual_pulls.has(unit_id) and float(visual_pulls[unit_id]["remaining"]) > 0.0:
			var pull: Dictionary = visual_pulls[unit_id]
			var progress: float = clampf(1.0 - float(pull["remaining"]) / float(pull["duration"]), 0.0, 1.0)
			visual_ground[unit_id] = (pull["from"] as Vector2).lerp(pull["to"], 1.0 - pow(1.0 - progress, 3.0))
			visual_moves[unit_id] = false
		elif str(unit.get("key", "")) == "michael" and combat and str(unit.get("moonwalk_stage", "")) in ["walking", "blocked", "pause"]:
			var stage: String = str(unit.get("moonwalk_stage", "walking"))
			var from: Vector2 = Board.ground(_cell(unit.get("moonwalk_from_cell", unit.get("cell", []))))
			var to: Vector2 = Board.ground(_cell(unit.get("moonwalk_to_cell", unit.get("cell", []))))
			var progress: float = clampf(1.0 - float(unit.get("moonwalk_timer", 0)) / maxf(float(unit.get("moonwalk_step_duration", 0.55)), 0.001), 0.0, 1.0)
			visual_ground[unit_id] = from.lerp(to, progress) if stage == "walking" else target
			visual_moves[unit_id] = stage == "walking"
			var facing: Vector2i = _cell(unit.get("facing_axial", [0, 1]))
			direction = art.direction_for(Board.axial_facing_vector(facing), direction)
		elif previous.distance_to(target) > 0.01 and previous.distance_to(target) < 4.0:
			direction = art.direction_for(Board.facing_vector(previous, target), direction)
			visual_ground[unit_id] = previous.move_toward(target, delta * 4.5)
			visual_moves[unit_id] = true
		else:
			visual_ground[unit_id] = target
			visual_moves[unit_id] = false
			var target_unit: Dictionary = _unit_by_id(int(unit.get("target_id", -1))) if combat else {}
			if not target_unit.is_empty():
				direction = art.direction_for(Board.facing_vector(target, Board.ground(_cell(target_unit.get("cell", [])))), direction)
			elif not combat:
				direction = "south"
		visual_directions[unit_id] = direction
	for effects: Array in [floating, shield_waves, slashes, level_bursts, kit_effects]:
		for index: int in range(effects.size() - 1, -1, -1):
			var attached_key: String = str(effects[index].get("library_key", ""))
			if effects == kit_effects and attached_key in ["cura_01", "laco_01"]:
				var attached: Dictionary = _unit_by_id(int(effects[index].get("target_id", -1)))
				var ended: bool = attached.is_empty() or not bool(attached.get("active", false)) or not bool(attached.get("alive", false))
				if attached_key == "laco_01":
					ended = ended or _phase() != "combat" or float(attached.get("stun_remaining", 0)) <= 0.0
				if ended:
					effects.remove_at(index)
					continue
			effects[index]["life"] = float(effects[index]["life"]) - delta
			if effects == floating:
				effects[index]["position"] = (effects[index]["position"] as Vector2) + Vector2(0, -26) * delta
			if float(effects[index]["life"]) <= 0.0:
				effects.remove_at(index)
	for unit_id: int in visual_attacks:
		visual_attacks[unit_id]["remaining"] = maxf(0.0, float(visual_attacks[unit_id]["remaining"]) - delta)
	for unit_id: int in visual_pulls.keys():
		visual_pulls[unit_id]["remaining"] = maxf(0.0, float(visual_pulls[unit_id]["remaining"]) - delta)
		if float(visual_pulls[unit_id]["remaining"]) <= 0.0:
			visual_pulls.erase(unit_id)
	for timers: Dictionary in [visual_hits, visual_deaths]:
		for unit_id: int in timers:
			timers[unit_id] = maxf(0.0, float(timers[unit_id]) - delta)


func _head_of(unit: Dictionary) -> Vector2:
	var unit_id: int = int(unit.get("id", -1))
	var ground_point: Vector2 = visual_ground.get(unit_id, Board.ground(_cell(unit.get("cell", []))))
	return Board.project(ground_point) + Vector2(0, -50)


func _consume_events() -> void:
	state = session.snapshot_for_team(0) # Eventos usam a posição atual revelada, sem um quadro de atraso.
	for event: Dictionary in session.drain_events():
		var kind: String = str(event.get("type", ""))
		if kind in ["item_bought", "items_fused", "capacity_upgraded", "hero_recruited"]:
			audio.play_cue("purchase")
		elif kind == "hero_upgraded":
			audio.play_cue("win")
			var upgraded: Dictionary = _unit_by_id(int(event.get("unit_id", -1)))
			if not upgraded.is_empty():
				var level: int = int(event.get("level", 2))
				var ground_point: Vector2 = _ground_of(upgraded)
				level_bursts.append({"ground": ground_point, "life": 1.1, "duration": 1.1, "level": level})
				floating.append({"text": "NÍVEL %d!" % level, "position": Board.project(ground_point) + Vector2(-30, -70 - 10 * level), "color": LEVEL_COLORS[level - 1], "life": 1.3, "size": 21})
		elif kind == "combat_started":
			audio.play_cue("start")
		elif kind == "round_finished":
			audio.play_cue("win" if int(event.get("winner", -1)) == 0 else "lose")
		elif kind in ["heal", "dance_shield"] and visual_time - last_heal_sound > 0.25:
			audio.play_cue("heal")
			last_heal_sound = visual_time
		var source: Dictionary = _unit_by_id(int(event.get("source_id", -1)))
		var target: Dictionary = _unit_by_id(int(event.get("target_id", -1)))
		_spawn_kit_feedback(event, source, target)
		if kind in ["attack", "kick", "projectile_launched"] and not source.is_empty() and not target.is_empty():
			var from: Vector2 = Board.ground(_cell(source.get("cell", [])))
			var to: Vector2 = Board.ground(_cell(target.get("cell", [])))
			var lunge: Vector2 = Board.project(to) - Board.project(from)
			visual_attacks[int(source["id"])] = {"remaining": 0.22, "duration": 0.22, "direction": lunge.normalized() if lunge.length() > 0.1 else Vector2.ZERO}
		if kind == "dance_shield" and not source.is_empty():
			shield_waves.append({"ground": visual_ground.get(int(source["id"]), Board.ground(_cell(source.get("cell", [])))), "life": 0.9, "duration": 0.9})
			if int(source["id"]) == selected_id:
				floating.append({"text": "ESCUDO %d" % roundi(float(event.get("amount", 0))), "position": _head_of(source) + Vector2(-30, -6), "color": GOLD, "life": 1.0, "size": 15})
		if kind in ["hit", "execute"] and not target.is_empty() and source.get("key", "") not in ["caramelo", "zumbi"]:
			slashes.append({"position": _head_of(target) + Vector2(0, 24), "life": 0.2, "critical": bool(event.get("critical", false)), "seed": randf() * TAU})
			visual_hits[int(target["id"])] = 0.12
		if kind in ["ball_hit", "rocket_hit", "splash", "smoke_hit", "lasso_hit"] and not target.is_empty():
			visual_hits[int(target["id"])] = 0.12
		if kind in ["hit", "execute"] and not target.is_empty():
			visual_hits[int(target["id"])] = 0.12
		if kind == "death" and not target.is_empty():
			visual_deaths[int(target["id"])] = 0.6
		if kind in ["hit", "ball_hit", "bleed", "execute", "heal", "rocket_hit", "splash", "smoke_hit", "smoke", "lasso_hit"] and not target.is_empty():
			var target_id: int = int(target.get("id", -1))
			var amount: float = float(event.get("amount", 0))
			var critical: bool = bool(event.get("critical", false))
			var damage_type: String = str(event.get("damage_type", "physical"))
			var color: Color = Color("86f6a5") if kind == "heal" else (GOLD if critical else (Color("ec8790") if kind == "bleed" else (Color("9ec5fe") if damage_type == "magic" else Color.WHITE)))
			if kind == "execute":
				color = Color("ff6b5e")
			var hit_seq: int = int(target_hit_seq.get(target_id, 0))
			target_hit_seq[target_id] = hit_seq + 1
			var slot: int = hit_seq % 3
			var jitter: Vector2 = Vector2([-14.0, 0.0, 14.0][slot], [-18.0, -28.0, -38.0][slot])
			if amount >= 1.0:
				var text: String = ("+" if kind == "heal" else "") + str(roundi(amount)) + ("!" if critical else "")
				if kind == "execute":
					text = "SUPERMORDIDA!"
				var duration: float = 1.4 if (critical or kind == "execute") else 0.9
				var font_size: int = 23 if (critical or kind == "execute") else 15
				floating.append({"text": text, "position": _head_of(target) + jitter, "color": color, "life": duration, "duration": duration, "size": font_size, "critical": critical})
			for layer: Array in [["absorbed_base", "MALA", Color("a7dfff"), -10], ["absorbed_dance", "DANÇA", GOLD, -23]]:
				var absorbed: float = float(event.get(str(layer[0]), 0))
				if absorbed >= 1.0 and target_id == selected_id:
					floating.append({"text": "%s %d" % [layer[1], roundi(absorbed)], "position": _head_of(target) + jitter + Vector2(0, float(layer[3])), "color": layer[2], "life": 0.7, "size": 11})
		var text: String = _event_text(event)
		if not text.is_empty():
			log_lines.push_front(text)
			if log_lines.size() > 40:
				log_lines.pop_back()


func _spawn_kit_feedback(event: Dictionary, source: Dictionary, target: Dictionary) -> void:
	var kind: String = str(event.get("type", ""))
	var key: String = str(source.get("key", ""))
	var source_point: Vector2 = Board.project(_ground_of(source)) + Vector2(0, -21) if not source.is_empty() else Vector2.ZERO
	var target_point: Vector2 = Board.project(_ground_of(target)) + Vector2(0, -21) if not target.is_empty() else source_point
	var effect_kind: String = ""
	var duration: float = 0.2
	var library_key: String = ""
	var angle: float = 0.0
	var scale: float = 1.0
	if kind == "kick":
		effect_kind = "kick"
		source_point += Vector2(0, 17)
		duration = 0.25
	elif kind == "ball_hit":
		effect_kind = "ball_impact"
		duration = 0.28
	elif kind in ["hit", "execute"] and key == "caramelo":
		effect_kind = "bite"
		duration = 0.24 if kind == "hit" else 0.42
	elif kind == "bleed":
		effect_kind = "bleed"
		duration = 0.35
	elif kind == "hit" and key == "zumbi":
		effect_kind = "thrust"
		duration = 0.22
		library_key = "estocada_01"
		if vfx.has_effect(library_key):
			var direction: Vector2 = (target_point - source_point).normalized()
			angle = direction.angle()
			target_point -= direction * 18.0
	elif kind == "heal" and float(event.get("amount", 0)) > 0.0 and not target.is_empty() and vfx.has_effect("cura_01"):
		effect_kind = "heal"
		library_key = "cura_01"
		scale = LEVEL_SCALE[clampi(int(target.get("level", 1)), 1, 3) - 1]
		# Um pulso por alvo: a renovação substitui o clip anterior, sem sobrepor cruzes.
		for index: int in range(kit_effects.size() - 1, -1, -1):
			if str(kit_effects[index].get("library_key", "")) == library_key and int(kit_effects[index].get("target_id", -1)) == int(target["id"]):
				kit_effects.remove_at(index)
	elif kind == "briefcase_guard":
		effect_kind = "guard"
		duration = 0.65
		if int(source.get("id", -1)) == selected_id:
			floating.append({"text": "MALA", "position": source_point + Vector2(-16, -28), "color": Color("a7dfff"), "life": 0.7, "size": 12})
	elif kind == "assassin_hunt":
		effect_kind = "hunt"
		duration = 0.6
	elif kind == "rocket_hit" and vfx.has_effect("foguete_01") and not target.is_empty():
		effect_kind = "explosion"
		library_key = "foguete_01"
	elif kind == "explosion" and not vfx.has_effect("foguete_01"):
		effect_kind = "explosion"
		duration = 0.48
		if event.has("cell"):
			target_point = Board.project(Board.ground(_cell(event["cell"])))
	elif kind == "smoke_cloud" and not vfx.has_effect("fumaca_01"):
		effect_kind = "smoke_cloud"
		duration = 0.9
		if event.has("cell"):
			target_point = Board.project(Board.ground(_cell(event["cell"])))
	elif kind == "lasso":
		effect_kind = "lasso"
		duration = 0.55
		target_point = Board.project(Board.ground(_cell(event.get("from", target.get("cell", []))))) + Vector2(0, -21)
		if not target.is_empty():
			visual_pulls[int(target["id"])] = {"from": Board.ground(_cell(event.get("from", []))), "to": Board.ground(_cell(event.get("to", []))), "remaining": 0.3, "duration": 0.3}
		_spawn_lasso_knot(source, target)
	elif kind == "revive":
		effect_kind = "revive"
		duration = 0.8
		visual_deaths.erase(int(target.get("id", -1)))
		floating.append({"text": "VOLTA POR CIMA!", "position": target_point + Vector2(-48, -36), "color": Color("86f6a5"), "life": 1.1, "size": 16})
	elif kind == "summon":
		effect_kind = "summon"
		duration = 0.55
	elif kind == "miss":
		floating.append({"text": "ERROU", "position": source_point + Vector2(-17, -34), "color": Color("c5c5d5"), "life": 0.65, "size": 12})
	elif kind == "crit_growth":
		floating.append({"text": "PRÓX. CRIT ×%.2f" % float(event.get("multiplier", 1.5)), "position": source_point + Vector2(-36, -40), "color": GOLD, "life": 0.8, "size": 11})
	if effect_kind.is_empty():
		return
	if vfx.has_effect(library_key):
		duration = vfx.duration(library_key)
	else:
		library_key = ""
	var destination: Vector2 = Board.project(Board.ground(_cell(event.get("to", [])))) + Vector2(0, -21) if kind == "lasso" else target_point
	kit_effects.append({"kind": effect_kind, "source_id": int(source.get("id", -1)), "target_id": int(target.get("id", -1)), "from": source_point, "position": target_point, "destination": destination, "life": duration, "duration": duration, "critical": bool(event.get("critical", false)) or kind == "execute", "library_key": library_key, "angle": angle, "scale": scale, "depth": "behind" if library_key == "foguete_01" else "front", "native_knot": kind == "lasso" and vfx.has_effect("laco_01")})
	while kit_effects.size() > 40:
		kit_effects.pop_front()


## O fio e o nó são independentes: o clip nunca substitui a linha do puxão.
func _spawn_lasso_knot(source: Dictionary, target: Dictionary) -> void:
	if _phase() != "combat" or not vfx.has_effect("laco_01") or target.is_empty() or not bool(target.get("active", false)) or not bool(target.get("alive", false)) or float(target.get("stun_remaining", 0)) <= 0.0:
		return
	var target_id: int = int(target["id"])
	for index: int in range(kit_effects.size() - 1, -1, -1):
		if kit_effects[index].get("library_key", "") == "laco_01" and int(kit_effects[index].get("target_id", -1)) == target_id:
			kit_effects.remove_at(index)
	var duration: float = vfx.duration("laco_01")
	var point: Vector2 = Board.project(_ground_of(target)) + Vector2(0, -21)
	kit_effects.append({"kind": "lasso_knot", "library_key": "laco_01", "source_id": int(source.get("id", -1)), "target_id": target_id,
		"from": point, "position": point, "destination": point, "life": duration, "duration": duration, "critical": false,
		"angle": 0.0, "scale": 1.0, "depth": "front"})


## Somente apresentação. A duração e os recortes pertencem ao pacote original.
func _library_effect_data(effect: Dictionary) -> Dictionary:
	var key: String = str(effect.get("library_key", ""))
	if key.is_empty():
		return {}
	var elapsed: float = float(effect["duration"]) - float(effect["life"])
	var data: Dictionary = vfx.frame_data(key, elapsed)
	if data.is_empty():
		return data
	var point: Vector2 = effect["position"]
	var scale: float = float(effect.get("scale", 1.0))
	if key in ["cura_01", "laco_01"]:
		var target: Dictionary = _unit_by_id(int(effect.get("target_id", -1)))
		if target.is_empty() or not bool(target.get("active", false)) or not bool(target.get("alive", false)):
			return {}
		if key == "laco_01" and (_phase() != "combat" or float(target.get("stun_remaining", 0)) <= 0.0):
			return {}
		point = Board.project(_ground_of(target)) + Vector2(0, (-18.0 if key == "cura_01" else -21.0) * scale)
	data["position"] = point.round()
	data["angle"] = float(effect.get("angle", 0.0))
	data["scale"] = scale
	return data


func _dance_vfx_data(unit: Dictionary) -> Dictionary:
	if _phase() != "combat" or not bool(unit.get("active", false)) or not bool(unit.get("alive", false)) or float(unit.get("dance_shield", 0)) <= 0.0:
		return {}
	var data: Dictionary = vfx.frame_data("escudo_danca_01", visual_time)
	if not data.is_empty():
		data["position"] = Board.project(_ground_of(unit)).round()
		data["angle"] = 0.0
		data["scale"] = LEVEL_SCALE[clampi(int(unit.get("level", 1)), 1, 3) - 1]
	return data


## A zona autoritativa controla existência e relógio; a vida do Snoop não decide o desenho.
func _smoke_vfx_data(zone: Dictionary) -> Dictionary:
	if _phase() != "combat" or float(zone.get("remaining", 0)) <= 0.0:
		return {}
	var elapsed: float = maxf(0.0, float(zone.get("duration", 0)) - float(zone.get("remaining", 0)))
	var data: Dictionary = vfx.frame_data("fumaca_01", elapsed)
	if not data.is_empty():
		data["position"] = Board.project(Board.ground(_cell(zone.get("cell", [])))).round()
		data["angle"] = 0.0
		data["scale"] = 2.0
		data["zone_id"] = int(zone.get("id", -1))
		data["source_id"] = int(zone.get("source_id", -1))
		data["remaining"] = float(zone.get("remaining", 0))
	return data


func _smoke_vfx_frames() -> Array[Dictionary]:
	var frames: Array[Dictionary] = []
	for zone: Dictionary in state.get("combat", {}).get("zones", []):
		var data: Dictionary = _smoke_vfx_data(zone)
		if not data.is_empty():
			frames.append(data)
	return frames


func _draw_vfx_frame(canvas: Node2D, data: Dictionary) -> void:
	if data.is_empty():
		return
	var scale: float = float(data.get("scale", 1.0))
	canvas.draw_set_transform(data["position"], float(data.get("angle", 0.0)), Vector2(scale, scale))
	canvas.draw_texture_rect_region(data["texture"], Rect2(data["offset"], data["size"]), data["region"])
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_library_feedback(canvas: Node2D, depth: String) -> void:
	for effect: Dictionary in kit_effects:
		if str(effect.get("depth", "front")) == depth:
			_draw_vfx_frame(canvas, _library_effect_data(effect))


## Usa as mesmas posições interpoladas do corpo/nó; a ondulação não desloca as pontas.
func _lasso_points(effect: Dictionary) -> PackedVector2Array:
	var progress: float = clampf(1.0 - float(effect["life"]) / maxf(float(effect["duration"]), 0.001), 0.0, 1.0)
	var source: Dictionary = _unit_by_id(int(effect.get("source_id", -1)))
	var target: Dictionary = _unit_by_id(int(effect.get("target_id", -1)))
	var from: Vector2 = effect["from"]
	var to: Vector2 = (effect["position"] as Vector2).lerp(effect["destination"], minf(1.0, progress * 1.83))
	if not source.is_empty():
		from = Board.project(_ground_of(source)) + Vector2(0, -21)
	if not target.is_empty():
		to = Board.project(_ground_of(target)) + Vector2(0, -21)
	var segments: int = 12
	var points: PackedVector2Array = PackedVector2Array()
	var normal: Vector2 = (to - from).normalized().orthogonal()
	for seg: int in range(segments + 1):
		var t: float = float(seg) / float(segments)
		var sway: float = sin(t * PI * 3.0 + progress * 8.0) * (6.0 * (1.0 - progress))
		points.append(from.lerp(to, t) + normal * sway)
	points[0] = from
	points[segments] = to
	return points


func _draw_kit_feedback(canvas: Node2D) -> void:
	for effect: Dictionary in kit_effects:
		if not str(effect.get("library_key", "")).is_empty():
			continue # O clip original substitui o desenho procedural, sem duplicar o golpe.
		var progress: float = 1.0 - float(effect["life"]) / float(effect["duration"])
		var alpha: float = clampf(1.0 - progress, 0.0, 1.0)
		var point: Vector2 = effect["position"]
		var critical: bool = bool(effect["critical"])
		match str(effect["kind"]):
			"thrust":
				var from: Vector2 = effect["from"]
				var direction: Vector2 = (point - from).normalized()
				var normal: Vector2 = direction.orthogonal()
				var tip: Vector2 = from.lerp(point, minf(1.0, progress * 4.0))
				var color: Color = Color(GOLD if critical else Color("fff0c7"), alpha)
				canvas.draw_line(tip - direction * 26, tip, color, 3.5 if critical else 2.0, true)
				canvas.draw_colored_polygon(PackedVector2Array([tip + direction * 5, tip - direction * 3 + normal * 3, tip - direction * 3 - normal * 3]), color)
			"bite":
				var radius: float = 7.0 + (1.0 - sin(progress * PI)) * (11.0 if critical else 7.0)
				var color: Color = Color(Color("f47b57") if critical else Color("ffe3aa"), alpha)
				canvas.draw_arc(point, radius, -PI * 0.45, PI * 0.45, 12, color, 2.5 if critical else 1.8, true)
				canvas.draw_arc(point, radius, PI * 0.55, PI * 1.45, 12, color, 2.5 if critical else 1.8, true)
			"bleed":
				point += Vector2(9, progress * 8)
				canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(0, -4), point + Vector2(3, 1), point + Vector2(0, 4), point + Vector2(-3, 1)]), Color(0.85, 0.17, 0.24, alpha * 0.85))
			"guard":
				point = effect["from"]
				canvas.draw_arc(point, 24.0 + progress * 7.0, -PI * 0.15, PI * 1.15, 20, Color(0.63, 0.85, 1.0, alpha * 0.9), 3.0, true)
			"kick":
				point = effect["from"]
				canvas.draw_arc(point, 5.0 + progress * 11.0, PI * 0.1, PI * 1.1, 14, Color(1.0, 0.96, 0.78, alpha), 2.2, true)
			"hunt":
				canvas.draw_arc(point + Vector2(0, 18), 12.0 + progress * 10.0, 0, PI, 10, Color(0.97, 0.58, 0.23, alpha * 0.7), 2.0, true)
			"ball_impact":
				var impact_r: float = 7.0 + progress * 17.0
				canvas.draw_arc(point, impact_r, 0, TAU, 16, Color(1.0, 0.95, 0.7, alpha * 0.85), 2.0, true)
				for spark_i: int in range(4):
					var ang: float = TAU * spark_i / 4.0 + PI * 0.25
					var spark_pos: Vector2 = point + Vector2(cos(ang), sin(ang)) * (impact_r * 0.9)
					canvas.draw_circle(spark_pos, 2.0 * alpha, Color.WHITE)
			"explosion":
				var blast_r: float = 20.0 + progress * 26.0
				canvas.draw_arc(point, blast_r, 0, TAU, 24, Color(1.0, 0.58, 0.15, alpha * 0.85), 3.0, true)
				canvas.draw_circle(point, maxf(3.0, (1.0 - progress) * 18.0), Color(1.0, 0.88, 0.35, alpha * 0.75))
				for spark_i: int in range(6):
					var spark_ang: float = TAU * spark_i / 6.0 + progress * 2.0
					var spark_p: Vector2 = point + Vector2(cos(spark_ang), sin(spark_ang)) * (blast_r * 0.85)
					canvas.draw_circle(spark_p, 2.5 * alpha, Color("ffd85c"))
			"smoke_cloud":
				for puff_i: int in range(5):
					var puff_ang: float = TAU * puff_i / 5.0 + progress * 1.5
					var puff_dist: float = 10.0 + progress * 16.0
					var puff_p: Vector2 = point + Vector2(cos(puff_ang) * 1.4, sin(puff_ang) * 0.8) * puff_dist
					canvas.draw_circle(puff_p, 13.0 * (0.8 + 0.2 * sin(progress * PI)), Color(0.48, 0.52, 0.78, alpha * 0.38))
			"lasso":
				var pts: PackedVector2Array = _lasso_points(effect)
				canvas.draw_polyline(pts, Color(Color("ffd55a"), alpha), 2.0, true)
				if not bool(effect.get("native_knot", false)):
					canvas.draw_arc(pts[-1], 6.0, 0, TAU, 14, Color(Color("fff4a3"), alpha), 1.5, true)
			"revive":
				var col_h: float = 60.0 * (1.0 - progress * 0.3)
				var col_w: float = 24.0 * (1.0 - progress)
				canvas.draw_rect(Rect2(point + Vector2(-col_w * 0.5, -col_h), Vector2(col_w, col_h)), Color(1.0, 0.25, 0.2, alpha * 0.45))
				canvas.draw_arc(point, 18.0 + progress * 24.0, 0, TAU, 20, Color(GOLD, alpha * 0.85), 2.5, true)
			"summon":
				canvas.draw_arc(point + Vector2(0, 20), 7.0 + progress * 20.0, 0, TAU, 20, Color(1.0, 0.65, 0.82, alpha * 0.8), 2.0, true)


func _event_text(event: Dictionary) -> String:
	var kind: String = str(event.get("type", ""))
	if kind in ["move", "attack", "kick", "ball_expired", "unit_placed", "moonwalk_step", "heal_pulse", "heal", "ball_impact"]:
		return ""
	var names: Dictionary = {"preparation_started": "Preparação começou", "combat_started": "Combate começou", "hit": "Golpe",
		"ball_hit": "Bola acertou", "ball_launched": "Neymar chutou", "bleed": "Sangramento", "bleed_applied": "Mordida: sangramento",
		"execute": "Supermordida", "death": "Eliminado", "round_finished": "Rodada encerrada", "acceleration": "Combate acelerado",
		"crit_growth": "Zumbi: crítico cresceu", "zumbi_buff": "Bônus da equipe", "dance_shield": "Michael: escudo da dança",
		"item_bought": "Item comprado", "hero_recruited": "Herói recrutado", "benefit_selected": "Benefício escolhido",
		"shop_refreshed": "Loja renovada", "capacity_upgraded": "Capacidade aumentada", "equipment_changed": "Equipamento alterado",
		"items_fused": "Receita concluída", "hero_upgraded": "Herói subiu de nível", "assassin_hunt": "Caramelo marcou o alvo",
		"assassin_hunt_ended": "Caramelo encerrou a caça", "briefcase_guard": "Obama renovou a proteção da mala",
		"explosion": "Elon: explosão de foguete", "smoke_cloud": "Snoop: nuvem de fumaça", "smoke": "Snoop: dano contínuo",
		"smoke_hit": "Snoop: tiro de fumaça", "lasso": "Rapunzel: puxão com laço", "lasso_hit": "Rapunzel: golpe de laço",
		"revive": "Lula: volta por cima", "summon": "Barbie: invocou Ken", "miss": "Ataque errou",
		"rocket_hit": "Foguete acertou", "splash": "Explosão atingiu", "projectile_launched": "Projétil disparado"}
	var text: String = str(names.get(kind, kind.replace("_", " ")))
	var source: Dictionary = _unit_by_id(int(event.get("source_id", -1)))
	if not source.is_empty() and kind in ["hit", "ball_hit", "execute", "death", "bleed", "explosion", "smoke_hit", "lasso_hit"]:
		text = "%s · %s" % [str(source.get("name", "")), text]
	if event.has("amount") and kind != "dance_shield":
		text += " %d" % roundi(float(event["amount"]))
	if bool(event.get("critical", false)):
		text += " · CRÍTICO"
	return text


# --- Lobby de boas-vindas & Compêndio de Heróis -------------------------------

func _make_ellipse(center: Vector2, rx: float, ry: float, segs: int = 24) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segs):
		var ang: float = TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	return pts


func _build_lobby() -> void:
	lobby_root = Control.new()
	lobby_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lobby_root)
	lobby_root.visible = false


func _draw_lobby() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("0c0e12"))
	if lobby_bg != null:
		draw_texture_rect(lobby_bg, Rect2(Vector2.ZERO, SCREEN), false)

	# Braseiros nos pilares laterais
	var flame_pulse: float = 0.85 + 0.15 * sin(visual_time * 6.5)
	draw_circle(Vector2(95, 335), 48.0 * flame_pulse, Color(0.98, 0.58, 0.15, 0.14))
	draw_circle(Vector2(1185, 335), 48.0 * flame_pulse, Color(0.98, 0.58, 0.15, 0.14))

	# Selo rúnico central no chão de pedra do coliseu
	var seal_pulse: float = 0.5 + 0.5 * sin(visual_time * 2.2)
	var center_seal: Vector2 = Vector2(640, 490)
	var seal_pts: PackedVector2Array = _make_ellipse(center_seal, 130.0, 55.0, 32)
	draw_colored_polygon(seal_pts, Color("a45cff", 0.08 * seal_pulse))
	seal_pts.append(seal_pts[0])
	draw_polyline(seal_pts, Color(GOLD, 0.22 * seal_pulse), 2.0, true)

	# Partículas de brasa/magia atmosféricas
	if not eco_mode:
		for i: int in range(14):
			var px: float = fposmod(i * 97.0 + visual_time * (12.0 + i * 3.0), 1280.0)
			var py: float = 680.0 - fposmod(i * 63.0 + visual_time * (20.0 + (i % 5) * 8.0), 550.0)
			var p_size: float = 1.5 + (i % 3)
			var p_alpha: float = (0.35 + 0.25 * sin(visual_time * 3.0 + i)) * (py / 720.0)
			draw_circle(Vector2(px, py), p_size, Color(0.95, 0.75, 0.4, p_alpha))

	# Aura mística pulsante do botão JOGAR (apenas no menu principal do lobby)
	if lobby_subview == "none":
		var play_rect: Rect2 = Rect2(1010, 616, 230, 72)
		var aura_pulse: float = 0.5 + 0.5 * sin(visual_time * 4.5)
		var purple: Color = Color("9d4edd")
		for layer: int in range(3):
			var expand: float = 4.0 + layer * 4.5 + 3.0 * aura_pulse
			var r: Rect2 = play_rect.grow(expand)
			var a: float = (0.28 - layer * 0.08) * (0.8 + 0.3 * aura_pulse)
			var box: StyleBoxFlat = StyleBoxFlat.new()
			box.bg_color = Color(purple, a)
			box.border_color = Color(GOLD, a * 1.3)
			box.set_border_width_all(1 if layer > 0 else 2)
			box.set_corner_radius_all(14 + layer * 2)
			box.draw(get_canvas_item(), r)


func _refresh_lobby() -> void:
	var signature: String = "%s_%s_%s_%d_%d_%s_%s" % [
		lobby_subview, lobby_hero_synergy_filter, lobby_selected_hero_key,
		lobby_preview_level, target_fps, str(eco_mode), str(audio.enabled)
	]
	if signature == lobby_signature:
		return
	lobby_signature = signature
	_clear(lobby_root)

	match lobby_subview:
		"none":
			_refresh_lobby_main()
		"heroes":
			_refresh_lobby_heroes()
		"settings":
			_refresh_lobby_settings()


func _refresh_lobby_main() -> void:
	# Título e cabeçalho com arte tipográfica
	var title_panel: Panel = _panel(lobby_root, Rect2(36, 28, 620, 108), 0.76, 12)
	_label(title_panel, "CLASH OF ERAS", Rect2(20, 10, 580, 52), 46, GOLD)
	_label(title_panel, "ARENA DE HERÓIS · AUTO-BATTLER TÁTICO", Rect2(22, 60, 580, 22), 15, Color("e0d8b0"))
	_label(title_panel, "12 Heróis · Sinergias TFT · Cópias sobem nível (★1 → ★2 → ★3)", Rect2(22, 82, 580, 18), 12, Kit.MUTED)

	# Pílula de Otimização & Foco em 30 FPS
	var badge_panel: Panel = _panel(lobby_root, Rect2(890, 16, 204, 38), 0.82, 19)
	_label(badge_panel, "⚡ %d FPS · OTIMIZADO" % target_fps, Rect2(8, 8, 188, 22), 13, Color("86eda5"), HORIZONTAL_ALIGNMENT_CENTER)

	# Controle Rápido de Áudio no Topo (preserva contrato smoke.gd: sound_button != null)
	sound_button = _button(lobby_root, "SOM: LIGADO" if audio.enabled else "SOM: DESLIGADO", Rect2(1106, 16, 146, 38), _toggle_sound)
	sound_button.add_theme_font_size_override("font_size", 12)

	# Painel Central com Dicas do Jogo & Sinergias
	var banner: Panel = _panel(lobby_root, Rect2(36, 154, 520, 172), 0.72, 10)
	_label(banner, "✦ SISTEMA DE COMBATE & EVOLUÇÃO ✦", Rect2(18, 14, 484, 24), 16, GOLD)
	var tip_text: String = "• Colete cópias dos seus heróis: 2 cópias sobem para ★2; 3 cópias para ★3 LENDÁRIO (+125% dano/vida, tamanho aumentado e aura mística!).\n• Combine sinergias de Vanguarda, Atacantes, Atiradores e Apoio para virar a partida.\n• Foco e calibração em 30 FPS para estabilidade mobile e PC."
	_label(banner, tip_text, Rect2(18, 42, 484, 116), 13, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)

	# Barra Inferior: HERÓIS
	var heroes_btn: Button = _button(lobby_root, "👑 COMPÊNDIO DE HERÓIS", Rect2(36, 624, 250, 64), func() -> void:
		lobby_subview = "heroes"
		lobby_signature = ""
		_refresh())
	heroes_btn.add_theme_font_size_override("font_size", 16)
	var h_style: StyleBoxFlat = (heroes_btn.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	h_style.border_color = GOLD
	h_style.set_border_width_all(2)
	heroes_btn.add_theme_stylebox_override("normal", h_style)

	# Barra Inferior: CONFIGURAÇÕES
	var settings_btn: Button = _button(lobby_root, "⚙ CONFIGURAÇÕES & 30 FPS", Rect2(302, 624, 260, 64), func() -> void:
		lobby_subview = "settings"
		lobby_signature = ""
		_refresh())
	settings_btn.add_theme_font_size_override("font_size", 16)

	# Barra Inferior Direita: Botão JOGAR com aura roxa
	start_button = _button(lobby_root, "JOGAR", Rect2(1010, 616, 230, 72), _start_match)
	var p_norm: StyleBoxFlat = StyleBoxFlat.new()
	p_norm.bg_color = Color("7b2cbf")
	p_norm.border_color = GOLD
	p_norm.set_border_width_all(2)
	p_norm.set_corner_radius_all(12)
	p_norm.shadow_color = Color("9d4edd", 0.6)
	p_norm.shadow_size = 10
	p_norm.shadow_offset = Vector2(0, 2)
	start_button.add_theme_stylebox_override("normal", p_norm)

	var p_hov: StyleBoxFlat = p_norm.duplicate() as StyleBoxFlat
	p_hov.bg_color = Color("9d4edd")
	p_hov.border_color = Color.WHITE
	start_button.add_theme_stylebox_override("hover", p_hov)

	var p_press: StyleBoxFlat = p_norm.duplicate() as StyleBoxFlat
	p_press.bg_color = Color("5a189a")
	start_button.add_theme_stylebox_override("pressed", p_press)
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.add_theme_color_override("font_color", Color.WHITE)


func _refresh_lobby_settings() -> void:
	var modal: Panel = _panel(lobby_root, Rect2(280, 70, 720, 580), 0.94, 14)
	_label(modal, "CONFIGURAÇÕES & OTIMIZAÇÃO", Rect2(24, 16, 500, 32), 24, GOLD)
	_button(modal, "X", Rect2(664, 14, 42, 38), func() -> void:
		lobby_subview = "none"
		lobby_signature = ""
		_refresh())

	# 1. Trava estrita de 30 FPS / Engine FPS
	_label(modal, "TAXA DE QUADROS MÁXIMA (ENGINE FPS):", Rect2(28, 64, 600, 22), 16, GOLD)
	_label(modal, "O jogo é calibrado com foco prioritário em 30 FPS para estabilidade térmica, economia de bateria no celular e suavidade consistente de frame-time.", Rect2(28, 88, 660, 42), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)

	var btn_30: Button = _button(modal, "⚡ 30 FPS (RECOMENDADO / FOCO)", Rect2(28, 134, 310, 48), _set_engine_fps.bind(30))
	btn_30.add_theme_font_size_override("font_size", 14)
	if target_fps == 30:
		var st30: StyleBoxFlat = (btn_30.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		st30.border_color = GOLD
		st30.set_border_width_all(2)
		st30.bg_color = Color(0.12, 0.32, 0.22, 0.95)
		btn_30.add_theme_stylebox_override("normal", st30)

	var btn_60: Button = _button(modal, "60 FPS (ALTO CONSUMO / MOBILE QUENTE)", Rect2(350, 134, 338, 48), _set_engine_fps.bind(60))
	btn_60.add_theme_font_size_override("font_size", 13)
	if target_fps == 60:
		var st60: StyleBoxFlat = (btn_60.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		st60.border_color = GOLD
		st60.set_border_width_all(2)
		btn_60.add_theme_stylebox_override("normal", st60)

	# 2. Otimização do Sistema e Modo Econômico
	_label(modal, "DESEMPENHO DO SISTEMA & BATERIA:", Rect2(28, 196, 600, 22), 16, GOLD)
	_label(modal, "Reduz partículas secundárias e efeitos visuais pesados em dispositivos menos potentes.", Rect2(28, 220, 660, 20), 13, Kit.MUTED)
	var btn_eco: Button = _button(modal, "MODO ECONÔMICO: ATIVO" if eco_mode else "MODO ECONÔMICO: DESATIVADO", Rect2(28, 246, 310, 44), _toggle_eco_mode)
	if eco_mode:
		var st_eco: StyleBoxFlat = (btn_eco.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		st_eco.border_color = Color("86eda5")
		st_eco.set_border_width_all(2)
		btn_eco.add_theme_stylebox_override("normal", st_eco)

	# 3. Velocidade de Animação dos Sprites (Ciclo de Dança)
	_label(modal, "TAXA DE ANIMAÇÃO DOS SPRITES (DANÇA):", Rect2(28, 308, 600, 22), 16, GOLD)
	_label(modal, "Velocidade de avanço dos quadros direcionais das personagens.", Rect2(28, 332, 600, 20), 13, Kit.MUTED)
	for idx: int in range(3):
		var rate: int = [8, 10, 12][idx]
		var anim_btn: Button = _button(modal, "%d FPS" % rate, Rect2(28 + idx * 110, 358, 96, 42), _set_animation_fps.bind(rate))
		if roundi(art.fps) == rate:
			var st_anim: StyleBoxFlat = (anim_btn.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
			st_anim.border_color = GOLD
			st_anim.set_border_width_all(2)
			anim_btn.add_theme_stylebox_override("normal", st_anim)

	# 4. Áudio & Som (preserva sound_button para smoke.gd)
	_label(modal, "ÁUDIO & EFEITOS SONOROS:", Rect2(28, 418, 600, 22), 16, GOLD)
	sound_button = _button(modal, "SOM: LIGADO" if audio.enabled else "SOM: DESLIGADO", Rect2(28, 444, 240, 44), _toggle_sound)

	# Fechar
	_button(modal, "VOLTAR AO LOBBY", Rect2(240, 516, 240, 48), func() -> void:
		lobby_subview = "none"
		lobby_signature = ""
		_refresh())


func _refresh_lobby_heroes() -> void:
	var modal: Panel = _panel(lobby_root, Rect2(36, 32, 1208, 656), 0.96, 12)
	_label(modal, "COMPÊNDIO DE HERÓIS", Rect2(24, 12, 500, 32), 26, GOLD)
	_label(modal, "Conheça os 12 heróis do Clash of Eras, suas sinergias e evolução de nível", Rect2(26, 42, 600, 20), 13, Kit.MUTED)
	_button(modal, "X", Rect2(1150, 14, 44, 40), func() -> void:
		lobby_subview = "none"
		lobby_signature = ""
		_refresh())

	# Abas de Filtros de Sinergia
	var filters: Array[Array] = [
		["all", "TODOS (12)"],
		["vanguarda", "VANGUARDA (4)"],
		["atacantes", "ATACANTES (3)"],
		["atiradores", "ATIRADORES (3)"],
		["apoio", "APOIO (3)"]
	]
	var tab_w: float = 226.0
	for f_idx: int in range(filters.size()):
		var f_key: String = str(filters[f_idx][0])
		var f_label: String = str(filters[f_idx][1])
		var is_active: bool = (lobby_hero_synergy_filter == f_key)
		var tab_btn: Button = _button(modal, f_label, Rect2(24 + f_idx * (tab_w + 8), 68, tab_w, 38), func() -> void:
			lobby_hero_synergy_filter = f_key
			lobby_signature = ""
			_refresh())
		tab_btn.add_theme_font_size_override("font_size", 13)
		var tab_st: StyleBoxFlat = (tab_btn.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		if is_active:
			tab_st.border_color = GOLD
			tab_st.set_border_width_all(2)
			tab_st.bg_color = Color(0.18, 0.14, 0.28, 0.95)
			tab_btn.add_theme_color_override("font_color", GOLD)
		tab_btn.add_theme_stylebox_override("normal", tab_st)

	# Coluna Esquerda: Lista Rolante de Heróis
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(24, 114)
	scroll.size = Vector2(450, 526)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	modal.add_child(scroll)

	var list_container: VBoxContainer = VBoxContainer.new()
	list_container.custom_minimum_size = Vector2(434, 0)
	list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(list_container)

	var filtered_keys: Array[String] = []
	for h_key: String in HERO_CATALOG_KEYS:
		if not specs.has(h_key):
			continue
		var s: UnitSpec = specs[h_key]
		if lobby_hero_synergy_filter == "all" or lobby_hero_synergy_filter in s.synergy_tags:
			filtered_keys.append(h_key)

	if not filtered_keys.has(lobby_selected_hero_key) and not filtered_keys.is_empty():
		lobby_selected_hero_key = filtered_keys[0]

	for h_key: String in filtered_keys:
		var s: UnitSpec = specs[h_key]
		var is_selected: bool = (h_key == lobby_selected_hero_key)
		var card: Button = Button.new()
		card.custom_minimum_size = Vector2(434, 66)
		card.text = ""
		card.pressed.connect(func() -> void:
			audio.play_cue("click")
			lobby_selected_hero_key = h_key
			lobby_signature = ""
			_refresh())
		list_container.add_child(card)

		var c_st: StyleBoxFlat = StyleBoxFlat.new()
		c_st.bg_color = Color(0.16, 0.12, 0.24, 0.9) if is_selected else Color(0.08, 0.1, 0.13, 0.75)
		c_st.border_color = GOLD if is_selected else Color(0.35, 0.4, 0.45, 0.4)
		c_st.set_border_width_all(2 if is_selected else 1)
		c_st.set_corner_radius_all(8)
		card.add_theme_stylebox_override("normal", c_st)
		var c_hov: StyleBoxFlat = c_st.duplicate() as StyleBoxFlat
		c_hov.border_color = GOLD
		card.add_theme_stylebox_override("hover", c_hov)

		# Retrato do Herói
		_icon_rect(card, art.portrait_for(h_key, 30, 28), Rect2(10, 8, 54, 50))
		_label(card, s.display_name, Rect2(72, 8, 200, 22), 17, GOLD if is_selected else Color.WHITE)
		_label(card, HERO_ROLES.get(h_key, "Combatente"), Rect2(72, 32, 240, 18), 12, Color("8ecae6"))

		# Ícones de sinergias no card
		for tag_i: int in range(s.synergy_tags.size()):
			var tag_name: String = s.synergy_tags[tag_i]
			_icon_rect(card, Kit.icon("syn_" + tag_name), Rect2(356 + tag_i * 26, 20, 22, 22))

	# Coluna Direita: Ficha de Dados do Herói
	var detail_panel: Panel = _panel(modal, Rect2(488, 114, 696, 526), 0.88, 10)
	var active_spec: UnitSpec = specs.get(lobby_selected_hero_key)
	if active_spec == null:
		return

	# Cabeçalho da Ficha
	_label(detail_panel, active_spec.display_name, Rect2(20, 12, 300, 32), 28, GOLD)
	_label(detail_panel, HERO_ROLES.get(lobby_selected_hero_key, "Combatente"), Rect2(22, 44, 380, 20), 14, Color("8ecae6"))

	# Sinergias do herói com ícones e nomes
	var syn_offset_x: float = 380.0
	for tag_i: int in range(active_spec.synergy_tags.size()):
		var syn_k: String = active_spec.synergy_tags[tag_i]
		var info: Dictionary = SYNERGY_INFO.get(syn_k, {})
		var syn_tag_panel: Panel = _panel(detail_panel, Rect2(syn_offset_x + tag_i * 150, 14, 142, 46), 0.75, 6)
		_icon_rect(syn_tag_panel, Kit.icon("syn_" + syn_k), Rect2(8, 8, 30, 30))
		_label(syn_tag_panel, str(info.get("name", syn_k.capitalize())), Rect2(44, 12, 94, 22), 14, GOLD)

	# Preview Interativo do Personagem (Sprite animado + escala de nível + aura)
	var preview_bg: Panel = _panel(detail_panel, Rect2(20, 72, 240, 200), 0.7, 8)
	hero_preview_control = Control.new()
	hero_preview_control.position = Vector2(0, 0)
	hero_preview_control.size = Vector2(240, 200)
	hero_preview_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_preview_control.draw.connect(_draw_hero_preview.bind(hero_preview_control))
	preview_bg.add_child(hero_preview_control)

	# Seletor de Nível (1, 2, 3)
	var lvl_bar: Panel = _panel(detail_panel, Rect2(276, 72, 400, 44), 0.75, 8)
	var lvl_colors: Array[Color] = [Color("c58b4a"), Color("dfe7ef"), Color("f4d58a")]
	for l_idx: int in range(3):
		var lvl: int = l_idx + 1
		var is_cur_lvl: bool = (lobby_preview_level == lvl)
		var btn_lvl: Button = _button(lvl_bar, "%s NÍVEL %d" % ["★".repeat(lvl), lvl], Rect2(8 + l_idx * 130, 4, 124, 36), func() -> void:
			lobby_preview_level = lvl
			lobby_signature = ""
			_refresh())
		btn_lvl.add_theme_font_size_override("font_size", 13)
		var st_lvl: StyleBoxFlat = (btn_lvl.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		if is_cur_lvl:
			st_lvl.border_color = lvl_colors[l_idx]
			st_lvl.set_border_width_all(2)
			st_lvl.bg_color = Color(0.2, 0.16, 0.3, 0.95)
			btn_lvl.add_theme_color_override("font_color", lvl_colors[l_idx])
		btn_lvl.add_theme_stylebox_override("normal", st_lvl)

	# Estatísticas Numéricas Recalculadas Conforme o Nível
	var mult: float = [1.0, 1.5, 2.25][clampi(lobby_preview_level, 1, 3) - 1]
	var stats_panel: Panel = _panel(detail_panel, Rect2(276, 122, 400, 150), 0.72, 8)
	var hp_val: int = roundi(active_spec.max_hp * mult)
	var atk_val: int = roundi(active_spec.attack_damage * mult)

	_label(stats_panel, "VIDA (HP):", Rect2(14, 10, 120, 20), 13, Kit.MUTED)
	_label(stats_panel, "%d" % hp_val, Rect2(110, 8, 80, 22), 17, Color("86eda5"))

	_label(stats_panel, "DANO (ATK):", Rect2(210, 10, 110, 20), 13, Kit.MUTED)
	_label(stats_panel, "%d" % atk_val, Rect2(300, 8, 80, 22), 17, GOLD)

	_label(stats_panel, "VEL. ATAQUE:", Rect2(14, 44, 120, 20), 13, Kit.MUTED)
	_label(stats_panel, "%.2f/s" % active_spec.attacks_per_second, Rect2(110, 42, 80, 22), 15, Color("90e0ef"))

	_label(stats_panel, "ALCANCE:", Rect2(210, 44, 110, 20), 13, Kit.MUTED)
	var range_str: String = "%d hex (%s)" % [active_spec.attack_range, "Corpo a corpo" if active_spec.attack_range == 1 else "Distância"]
	_label(stats_panel, range_str, Rect2(280, 42, 114, 22), 13, Color.WHITE)

	_label(stats_panel, "ARMADURA:", Rect2(14, 78, 120, 20), 13, Kit.MUTED)
	_label(stats_panel, "%d" % roundi(active_spec.armor), Rect2(110, 76, 80, 22), 15, Color("b1daff"))

	_label(stats_panel, "RESISTÊNCIA:", Rect2(210, 78, 110, 20), 13, Kit.MUTED)
	_label(stats_panel, "%d" % roundi(active_spec.resist), Rect2(300, 76, 80, 22), 15, Color("b1daff"))

	_label(stats_panel, "CRÍTICO:", Rect2(14, 112, 120, 20), 13, Kit.MUTED)
	_label(stats_panel, "%d%% (x%1.1f)" % [roundi(active_spec.crit_chance * 100), active_spec.crit_multiplier], Rect2(110, 110, 120, 22), 15, Color("ffb703"))

	_label(stats_panel, "MULTI NÍVEL:", Rect2(210, 112, 110, 20), 13, Kit.MUTED)
	_label(stats_panel, "x%1.2f Poder" % mult, Rect2(300, 110, 90, 22), 15, lvl_colors[lobby_preview_level - 1])

	# Caixa de Habilidade Especial / Kit Tático
	var skill_box: Panel = _panel(detail_panel, Rect2(20, 282, 656, 230), 0.78, 8)
	_label(skill_box, "✦ HABILIDADE ESPECIAL & ESTILO DE COMBATE ✦", Rect2(16, 12, 500, 22), 15, GOLD)
	var skill_desc: String = str(KIT_TEXT.get(lobby_selected_hero_key, "Habilidade em validação de laboratório."))
	_label(skill_box, skill_desc, Rect2(16, 40, 624, 170), 14, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)


func _draw_hero_preview(canvas: Control) -> void:
	if not specs.has(lobby_selected_hero_key):
		return
	var key: String = lobby_selected_hero_key
	var center: Vector2 = canvas.size * 0.5
	var feet: Vector2 = Vector2(center.x, center.y + 44)

	# Pedestal de pedra rúnica no chão
	var poly_base: PackedVector2Array = _make_ellipse(feet, 56.0, 24.0, 28)
	canvas.draw_colored_polygon(poly_base, Color(0.08, 0.1, 0.13, 0.85))
	poly_base.append(poly_base[0])
	canvas.draw_polyline(poly_base, Color(0.3, 0.4, 0.5, 0.6), 2.0, true)

	# Aura mística roxa e dourada de Nível 3
	if lobby_preview_level == 3:
		var pulse: float = 0.5 + 0.5 * sin(visual_time * 5.0)
		for ring: int in range(3):
			var rx: float = 58.0 + ring * 12.0 + 4.0 * pulse
			var ry: float = 25.0 + ring * 5.0 + 2.0 * pulse
			var poly: PackedVector2Array = _make_ellipse(feet, rx, ry, 28)
			poly.append(poly[0])
			var a: float = (0.6 - ring * 0.18) * (0.8 + 0.25 * pulse)
			canvas.draw_polyline(poly, Color(AURA if ring < 2 else GOLD, a), 2.5 - ring * 0.5, true)

	# Sprite do herói animado no tempo
	var tex: Texture2D = art.texture_for(key, "south", visual_time)
	if tex != null:
		var spr_scale: float = 2.4 * LEVEL_SCALE[lobby_preview_level - 1]
		var anchor: Vector2 = art.anchor_for(tex, key)
		var origin: Vector2 = feet - anchor * spr_scale
		canvas.draw_texture_rect(tex, Rect2(origin.round(), tex.get_size() * spr_scale), false)

	# Estrelas de nível desenhadas sob os pés
	var star_step: float = 18.0
	var star_y: float = feet.y + 14.0
	for s: int in range(lobby_preview_level):
		var sx: float = center.x + (s - (lobby_preview_level - 1) * 0.5) * star_step - 8.0
		var star_tex: Texture2D = Kit.icon("ui_star")
		if star_tex != null:
			canvas.draw_texture_rect(star_tex, Rect2(Vector2(sx, star_y), Vector2(16, 16)), false, LEVEL_COLORS[lobby_preview_level - 1])


# --- Desenho do mundo ----------------------------------------------------------

func _draw() -> void:
	if _phase() == "menu":
		_draw_lobby()
		return
	_draw_arena()
	_draw_board()
	if state.is_empty():
		return
	_draw_bench()
	for entry: Dictionary in frame_entries:
		_draw_ground(entry)
	for effect: Dictionary in shield_waves:
		var progress: float = 1.0 - float(effect["life"]) / float(effect["duration"])
		var ring: PackedVector2Array = Board.ellipse(effect["ground"], 0.3 + progress * 1.6, 0.2 + progress * 1.0, 32)
		ring.append(ring[0])
		draw_polyline(ring, Color(GOLD, 0.85 * (1.0 - progress)), 3.0, true)
	for burst: Dictionary in level_bursts:
		var progress: float = 1.0 - float(burst["life"]) / float(burst["duration"])
		var color: Color = LEVEL_COLORS[int(burst["level"]) - 1]
		for wave: int in range(2):
			var spread: float = clampf(progress * 1.4 - wave * 0.25, 0.0, 1.0)
			var ring: PackedVector2Array = Board.ellipse(burst["ground"], 0.25 + spread * 1.1, 0.15 + spread * 0.65, 32)
			ring.append(ring[0])
			draw_polyline(ring, Color(color, 0.9 * (1.0 - spread)), 3.0 - wave, true)
		var feet: Vector2 = Board.project(burst["ground"])
		var flash: Color = Color(color, 0.35 * (1.0 - progress))
		draw_polygon(PackedVector2Array([feet + Vector2(-22, 0), feet + Vector2(22, 0), feet + Vector2(10, -120), feet + Vector2(-10, -120)]),
			PackedColorArray([flash, flash, Color(flash, 0.0), Color(flash, 0.0)]))
	for projectile: Dictionary in state.get("combat", {}).get("projectiles", []):
		draw_colored_polygon(Board.ellipse(_projectile_ground(projectile), 0.14, 0.075, 12), Color(0, 0, 0, 0.3))
	_draw_library_feedback(self, "behind")


## Prepara a lista desenhada no quadro: textura, pose, nível, tamanho e pés na tela.
func _prepare_frame() -> void:
	frame_entries = _draw_entries()
	for entry: Dictionary in frame_entries:
		var unit: Dictionary = entry["unit"]
		var pose: Dictionary = _visual_pose(unit)
		var texture: Texture2D = art.texture_for(str(unit.get("key", "")), str(visual_directions.get(int(unit["id"]), "south")), float(pose["time"]))
		var level: int = clampi(int(unit.get("level", 1)), 1, 3)
		if drag != null and drag.dragged_unit_id() == int(unit["id"]):
			pose["tint"] = Color(1, 1, 1, 0.35) # O original fica apagado enquanto a cópia segue o dedo.
		entry["pose"] = pose
		entry["texture"] = texture
		entry["level"] = level
		entry["scale"] = LEVEL_SCALE[level - 1]
		entry["height"] = (art.height_for(texture) if texture != null else 46.0) * LEVEL_SCALE[level - 1]
		entry["feet"] = Board.project(entry["ground"])


func _projectile_ground(projectile: Dictionary) -> Vector2:
	var progress: float = clampf(1.0 - float(projectile.get("flight_left", 0)) / maxf(float(projectile.get("flight_duration", 1)), 0.001), 0.0, 1.0)
	return Board.ground(_cell(projectile.get("from_cell", []))).lerp(Board.ground(_cell(projectile.get("to_cell", []))), progress)


func _ground_of(unit: Dictionary) -> Vector2:
	if not bool(unit.get("active", false)):
		var slot: int = _bench_slot_of(int(unit.get("id", -1)))
		if slot >= 0:
			return Board.bench_ground(slot)
	return visual_ground.get(int(unit.get("id", -1)), Board.ground(_cell(unit.get("cell", []))))


func _copies(own: Dictionary, key: String) -> int:
	return int((own.get("copies", {}) as Dictionary).get(key, 0))


func _max_copies() -> int:
	var thresholds: Array = state.get("test_config", {}).get("copies_for_level", [1, 2, 3])
	return int(thresholds[thresholds.size() - 1])


func _level_for_copies(copies: int) -> int:
	return Catalog.level_for_copies(copies, {"copies_for_level": state.get("test_config", {}).get("copies_for_level", [1, 2, 3])})


## Estrelas do nível na partida (ícone 16 × 16 tingido de bronze/prata/ouro).
func _stars(parent: Control, center: Vector2, level: int, size: float, compact: bool = false) -> void:
	var step: float = size * (0.8 if compact else 0.95)
	for index: int in range(level):
		var star: TextureRect = _icon_rect(parent, Kit.icon("ui_star"), Rect2(center.x + (index - (level - 1) * 0.5) * step - size * 0.5, center.y - size * 0.5, size, size))
		star.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		star.modulate = LEVEL_COLORS[clampi(level, 1, 3) - 1]


func _draw_arena() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("1a1f22"))
	if arena != null:
		draw_texture_rect(arena, Rect2(ARENA_OFFSET, arena.get_size() * ARENA_SCALE), false)
	# Vinheta suave: escurece arquibancadas e bordas para destacar a areia.
	var shade: Color = Color(0.02, 0.03, 0.04, 0.5)
	var clear: Color = Color(0.02, 0.03, 0.04, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 170), Vector2(0, 170)]), PackedColorArray([shade, shade, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, 520), Vector2(1280, 520), Vector2(1280, 720), Vector2(0, 720)]), PackedColorArray([clear, clear, Color(shade, 0.65), Color(shade, 0.65)]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(170, 0), Vector2(170, 720), Vector2(0, 720)]), PackedColorArray([Color(shade, 0.4), clear, clear, Color(shade, 0.4)]))
	draw_polygon(PackedVector2Array([Vector2(1110, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(1110, 720)]), PackedColorArray([clear, Color(shade, 0.4), Color(shade, 0.4), clear]))
	# Objetos originais do PixelLab, com os pés projetados fora das células jogáveis.
	for prop: Dictionary in arena_props:
		var texture: Texture2D = prop["texture"]
		var ground_point: Vector2 = prop["ground"]
		var scale: float = float(prop["scale"]) * Board.scale_at(ground_point.y)
		var size: Vector2 = texture.get_size() * scale
		var origin: Vector2 = Board.project(ground_point) - (prop["anchor"] as Vector2) * scale
		draw_texture_rect(texture, Rect2(origin.round(), size), false)


func _draw_board() -> void:
	var phase: String = _phase()
	var prep: bool = phase == "preparation"
	var calm: bool = phase in ["combat", "round_result", "match_over"]
	var selected: Dictionary = _selected_own() if prep else {}
	var occupied: Dictionary = {}
	for segment: PackedVector2Array in board_perimeter:
		draw_line(segment[0] + Vector2(0, 2), segment[1] + Vector2(0, 2), Color(0.19, 0.13, 0.07, 0.32), 4.0, true)
		draw_line(segment[0], segment[1], Color(0.96, 0.85, 0.62, 0.7 if prep else 0.4), 2.0, true)
	if prep:
		for unit: Dictionary in state.get("own", {}).get("units", []):
			if bool(unit.get("active", false)):
				occupied[_cell(unit.get("cell", []))] = true
	for row: int in range(8):
		for column: int in range(8):
			var cell: Vector2i = Vector2i(column, row)
			var own_half: bool = row >= 4
			var polygon: PackedVector2Array = Board.hex_polygon(cell, 0.07)
			## Tons mais escuros que a areia clara; a borda escura dá leitura, o brilho interno dá acabamento.
			var fill: Color = Color(0.2, 0.52, 0.52, 0.1 if calm else 0.2) if own_half else Color(0.6, 0.27, 0.22, 0.08 if calm else 0.15)
			if not selected.is_empty() and own_half and not occupied.has(cell):
				fill = Color(0.18, 0.72, 0.66, 0.24 + 0.06 * sin(visual_time * 4.0))
			if prep and cell == hover_cell and own_half:
				fill = Color(fill, fill.a + 0.14)
			draw_colored_polygon(polygon, fill)
			polygon.append(polygon[0])
			draw_polyline(polygon, Color(0.33, 0.22, 0.1, 0.22 if calm else 0.4), 1.6, true)
			var inner: PackedVector2Array = Board.hex_polygon(cell, 0.16)
			inner.append(inner[0])
			draw_polyline(inner, Color(1.0, 0.97, 0.88, 0.1 if calm else 0.2), 1.0, true)
	if not selected.is_empty() and bool(selected.get("active", false)):
		var outline: PackedVector2Array = Board.hex_polygon(_cell(selected.get("cell", [])), 0.04)
		outline.append(outline[0])
		draw_polyline(outline, GOLD, 2.5, true)
	# A névoa indica exatamente as células cobertas pelo raio recebido da simulação.
	var visible_zones: Array = state.get("combat", {}).get("zones", []) if phase == "combat" else []
	for zone: Dictionary in visible_zones:
		if float(zone.get("remaining", 0)) <= 0.0:
			continue
		var z_cell: Vector2i = _cell(zone.get("cell", []))
		var z_radius: int = int(zone.get("radius", 1))
		var z_ground: Vector2 = Board.ground(z_cell)
		_draw_cell_range(z_cell, z_radius, Color(0.35, 0.4, 0.68, 0.12), Color(0.55, 0.62, 0.9, 0.3))
		var cloud_frame: Dictionary = _smoke_vfx_data(zone)
		if not cloud_frame.is_empty():
			_draw_vfx_frame(self, cloud_frame)
			continue
		var z_pulse: float = 0.92 + 0.08 * sin(visual_time * 3.5 + float(zone.get("id", 0)))
		var z_ellipse: PackedVector2Array = Board.ellipse(z_ground, (0.42 + z_radius * 0.38) * z_pulse, (0.24 + z_radius * 0.22) * z_pulse, 24)
		draw_colored_polygon(z_ellipse, Color(0.35, 0.4, 0.68, 0.24))
		z_ellipse.append(z_ellipse[0])
		draw_polyline(z_ellipse, Color(0.55, 0.62, 0.9, 0.42), 1.6, true)
	# Aura musical de ritmo do Bob Marley durante o combate
	if calm:
		for entry: Dictionary in frame_entries:
			var unit: Dictionary = entry["unit"]
			if str(unit.get("key", "")) == "bob_marley" and bool(unit.get("alive", true)) and not bool(entry["ghost"]):
				var b_ground: Vector2 = entry["ground"]
				var b_lvl: int = clampi(int(unit.get("level", 1)), 1, 3)
				# Anéis decorativos compactos; alcance real aparece ao inspecionar Bob.
				var b_radius: float = 0.36
				var bob_spec: Variant = specs.get("bob_marley")
				if int(unit["id"]) == selected_id and bob_spec != null and not bob_spec.aura_radius_by_level.is_empty():
					var radius: int = bob_spec.aura_radius_by_level[mini(b_lvl - 1, bob_spec.aura_radius_by_level.size() - 1)]
					_draw_cell_range(_cell(unit["cell"]), radius, Color(0.25, 0.72, 0.35, 0.035), Color(0.42, 0.85, 0.52, 0.22))
				var b_pulse: float = 0.94 + 0.06 * sin(visual_time * 4.0)
				for r_i: int in range(3):
					var r_color: Color = [Color("2ec756"), Color("f4c430"), Color("e63946")][r_i]
					var r_r: float = b_radius * (0.8 + float(r_i) * 0.1) * b_pulse
					var r_ellipse: PackedVector2Array = Board.ellipse(b_ground, r_r, r_r * 0.58, 28)
					r_ellipse.append(r_ellipse[0])
					draw_polyline(r_ellipse, Color(r_color, 0.28 - float(r_i) * 0.06), 1.4, true)
	# Marca de caça discreta, ligada ao alvo real; não implica salto ou teleporte.
	for hunter: Dictionary in state.get("combat", {}).get("units", []):
		if not bool(hunter.get("alive", false)) or int(hunter.get("assassin_target_id", -1)) < 0:
			continue
		var prey: Dictionary = _unit_by_id(int(hunter["assassin_target_id"]))
		if not prey.is_empty() and bool(prey.get("alive", false)):
			var marker: PackedVector2Array = Board.ellipse(_ground_of(prey), 0.22, 0.12, 18)
			marker.append(marker[0])
			draw_polyline(marker, Color(0.98, 0.53, 0.2, 0.65), 1.7, true)


func _draw_cell_range(origin: Vector2i, radius: int, fill: Color, edge: Color) -> void:
	for row: int in range(8):
		for column: int in range(8):
			var cell: Vector2i = Vector2i(column, row)
			if Grid.distance(origin, cell) > radius:
				continue
			var polygon: PackedVector2Array = Board.hex_polygon(cell, 0.1)
			draw_colored_polygon(polygon, fill)
			polygon.append(polygon[0])
			draw_polyline(polygon, edge, 1.0, true)


func _draw_bench() -> void:
	var prep: bool = _phase() == "preparation"
	var selected: Dictionary = _selected_own()
	var font: Font = ThemeDB.fallback_font
	var label_at: Vector2 = Board.bench_position(0) + Vector2(-96, 5)
	draw_string_outline(font, label_at, "RESERVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 5, Color(0, 0, 0, 0.75))
	draw_string(font, label_at, "RESERVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	for slot: int in range(Board.BENCH_SLOTS):
		var polygon: PackedVector2Array = Board.bench_polygon(slot)
		var fill: Color = Color(0.2, 0.13, 0.06, 0.22)
		if prep and not selected.is_empty() and bool(selected.get("active", false)):
			fill = Color(0.18, 0.72, 0.66, 0.28)
		if prep and slot == hover_bench:
			fill = Color(fill, fill.a + 0.14)
		draw_colored_polygon(polygon, fill)
		polygon.append(polygon[0])
		draw_polyline(polygon, Color(0.33, 0.22, 0.1, 0.45), 1.6, true)
		var center: Vector2 = Board.bench_position(slot)
		draw_line(center + Vector2(-16, 12), center + Vector2(16, 12), Color(GOLD, 0.25), 1.0, true)
		draw_string(font, center + Vector2(-4, 27), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(GOLD, 0.7))


func _visual_pose(unit: Dictionary) -> Dictionary:
	var unit_id: int = int(unit.get("id", -1))
	var key: String = str(unit.get("key", ""))
	var pose: Dictionary = {"offset": Vector2.ZERO, "angle": 0.0, "tint": Color.WHITE, "time": visual_time}
	if key == "michael":
		if _phase() == "combat" and str(unit.get("moonwalk_stage", "")) in ["pause", "blocked"]:
			pose["time"] = 8.0 / maxf(art.fps, 1.0)
	elif bool(visual_moves.get(unit_id, false)):
		pose["offset"] = Vector2(0, -absf(sin(visual_time * 13.0 + unit_id)) * 2.0)
		pose["angle"] = sin(visual_time * 13.0 + unit_id) * 0.03
	var attack: Dictionary = visual_attacks.get(unit_id, {})
	if not attack.is_empty() and float(attack.get("remaining", 0)) > 0.0 and key != "michael":
		var progress: float = 1.0 - float(attack["remaining"]) / float(attack["duration"])
		var impulse: float = sin(progress * PI)
		pose["offset"] = (pose["offset"] as Vector2) + (attack["direction"] as Vector2) * impulse * (3.0 if key == "obama" else 6.0)
		pose["angle"] = impulse * 0.05 * signf((attack["direction"] as Vector2).x)
	if float(visual_hits.get(unit_id, 0)) > 0.0:
		pose["tint"] = Color("ffb3a6")
	if not bool(unit.get("alive", true)):
		var fall: float = clampf(1.0 - float(visual_deaths.get(unit_id, 0)) / 0.6, 0.0, 1.0)
		pose["angle"] = fall * 1.2
		pose["offset"] = Vector2(0, fall * 6.0)
		pose["tint"] = Color(0.7, 0.7, 0.7, 1.0 - fall)
	return pose


## Chão: sombra, anel do time, seleção e a parte de trás da aura de nível 3.
func _draw_ground(entry: Dictionary) -> void:
	var unit: Dictionary = entry["unit"]
	var ground_point: Vector2 = entry["ground"]
	var scale: float = float(entry["scale"])
	var ghost: bool = bool(entry["ghost"])
	var tint: Color = entry["pose"]["tint"]
	if not bool(unit.get("alive", true)) and tint.a <= 0.01:
		draw_colored_polygon(Board.ellipse(ground_point, 0.12, 0.07, 10), Color(0.25, 0.18, 0.15, 0.35))
		return
	if int(entry["level"]) >= 3 and bool(unit.get("alive", true)) and not ghost:
		_draw_aura_back(entry)
	draw_colored_polygon(Board.ellipse(ground_point, 0.26 * scale, 0.14 * scale, 20), Color(0, 0, 0, 0.3 * tint.a))
	var ring: PackedVector2Array = Board.ellipse(ground_point, 0.3 * scale, 0.17 * scale, 24)
	ring.append(ring[0])
	draw_polyline(ring, Color(TEAM_COLORS[int(unit.get("team", 0))], (0.35 if ghost else 0.85) * tint.a), 1.6, true)
	if int(unit["id"]) == selected_id:
		var glow: PackedVector2Array = Board.ellipse(ground_point, 0.36 * scale, 0.21 * scale, 24)
		glow.append(glow[0])
		draw_polyline(glow, Color(GOLD, 0.7 + 0.3 * sin(visual_time * 6.0)), 2.0, true)


## Aura especial do nível 3: violeta (contrasta com a areia clara), coluna de luz e faíscas douradas.
func _draw_aura_back(entry: Dictionary) -> void:
	var ground_point: Vector2 = entry["ground"]
	var feet: Vector2 = entry["feet"]
	var pulse: float = 0.5 + 0.5 * sin(visual_time * 3.0 + float(entry["unit"]["id"]))
	for layer: int in range(3):
		draw_colored_polygon(Board.ellipse(ground_point, 0.5 + layer * 0.09, 0.29 + layer * 0.05, 28), Color(AURA, (0.3 - layer * 0.08) * (0.75 + 0.25 * pulse)))
	for radius: Vector2 in [Vector2(0.5, 0.29), Vector2(0.38, 0.22)]:
		var ring: PackedVector2Array = Board.ellipse(ground_point, radius.x * (0.96 + 0.04 * pulse), radius.y * (0.96 + 0.04 * pulse), 32)
		ring.append(ring[0])
		draw_polyline(ring, Color(AURA.darkened(0.35), 0.9) if radius.x > 0.4 else Color(GOLD, 0.85), 2.5 if radius.x > 0.4 else 1.5, true)
	var height: float = float(entry["height"]) * 1.35
	var base: Color = Color(AURA, 0.3 * (0.7 + 0.3 * pulse))
	draw_polygon(PackedVector2Array([feet + Vector2(-22, 2), feet + Vector2(22, 2), feet + Vector2(13, -height), feet + Vector2(-13, -height)]),
		PackedColorArray([base, base, Color(base, 0.0), Color(base, 0.0)]))
	for index: int in range(6):
		var angle: float = visual_time * 1.6 + TAU * index / 6.0
		var spark: Vector2 = Board.project(ground_point + Vector2(cos(angle) * 0.5, sin(angle) * 0.29)).round()
		var diamond: PackedVector2Array = PackedVector2Array([spark + Vector2(0, -4), spark + Vector2(3, 0), spark + Vector2(0, 4), spark + Vector2(-3, 0)])
		draw_colored_polygon(diamond, Color("ffd85c"))
		diamond.append(diamond[0])
		draw_polyline(diamond, Color(0.2, 0.1, 0.25, 0.9), 1.0)


## Sprites com o shader de escala de pixel art; a bola vem por último, acima dos corpos.
func _draw_units_layer() -> void:
	if state.is_empty() or _phase() == "menu":
		return
	for entry: Dictionary in frame_entries:
		var texture: Texture2D = entry.get("texture") as Texture2D
		var unit: Dictionary = entry["unit"]
		var pose: Dictionary = entry["pose"]
		var tint: Color = pose["tint"]
		if not bool(unit.get("alive", true)) and tint.a <= 0.01:
			continue
		if texture == null:
			units_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			units_layer.draw_circle(entry["feet"] + Vector2(0, -12), 8, TEAM_COLORS[int(unit.get("team", 0))])
			continue
		if bool(entry["ghost"]):
			tint = Color(0.75, 0.8, 0.9, 0.5)
		var scale: float = float(entry["scale"])
		if not bool(entry["ghost"]) and bool(unit.get("alive", true)):
			units_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var shadow_center: Vector2 = entry["feet"]
			var shadow_radius: Vector2 = Vector2(17.0 * scale, 7.5 * scale)
			var shadow_pts: PackedVector2Array = PackedVector2Array()
			for s_i: int in range(12):
				var ang: float = TAU * s_i / 12.0
				shadow_pts.append(shadow_center + Vector2(cos(ang) * shadow_radius.x, sin(ang) * shadow_radius.y))
			units_layer.draw_colored_polygon(shadow_pts, Color(0.02, 0.03, 0.05, 0.38 * tint.a))
		var anchor: Vector2 = art.anchor_for(texture, str(unit.get("key", "")))
		var origin: Vector2 = ((entry["feet"] as Vector2) + (pose["offset"] as Vector2)).round()
		units_layer.draw_set_transform(origin, float(pose["angle"]), Vector2(scale, scale))
		units_layer.draw_texture(texture, (-anchor).round(), tint)
	var ball_texture: Texture2D = Kit.icon("fx_ball")
	for projectile: Dictionary in state.get("combat", {}).get("projectiles", []):
		var progress: float = clampf(1.0 - float(projectile.get("flight_left", 0)) / maxf(float(projectile.get("flight_duration", 1)), 0.001), 0.0, 1.0)
		var kind: String = str(projectile.get("kind", "ball"))
		var p_ground: Vector2 = _projectile_ground(projectile)
		var p_from: Vector2 = Board.ground(_cell(projectile.get("from_cell", [])))
		var p_to: Vector2 = Board.ground(_cell(projectile.get("to_cell", [])))
		var flight_pos: Vector2 = Board.project(p_ground) + Vector2(0, -18 - sin(progress * PI) * (18 if kind == "rocket" else 24))
		var flight_dir: Vector2 = (Board.project(p_to) - Board.project(p_from)).normalized()
		var rot_angle: float = flight_dir.angle() if flight_dir.length_squared() > 0.01 else progress * TAU * 1.5
		if kind == "rocket":
			units_layer.draw_set_transform(flight_pos, rot_angle, Vector2(1.0, 1.0))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-9, -3), Vector2(4, -3), Vector2(9, 0), Vector2(4, 3), Vector2(-9, 3)]),
				PackedColorArray([Color("e0e0ea"), Color("e0e0ea"), Color("e84034"), Color("e0e0ea"), Color("e0e0ea")]))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-9, -5), Vector2(-6, -3), Vector2(-9, -1)]), PackedColorArray([Color("2a2a35"), Color("2a2a35"), Color("2a2a35")]))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-9, 1), Vector2(-6, 3), Vector2(-9, 5)]), PackedColorArray([Color("2a2a35"), Color("2a2a35"), Color("2a2a35")]))
			var thrust_flicker: float = 0.8 + 0.4 * sin(visual_time * 24.0)
			units_layer.draw_polygon(PackedVector2Array([Vector2(-9, -2), Vector2(-15 * thrust_flicker, 0), Vector2(-9, 2)]),
				PackedColorArray([Color(1.0, 0.7, 0.2), Color(1.0, 0.3, 0.1, 0.8), Color(1.0, 0.7, 0.2)]))
		elif kind == "smoke":
			units_layer.draw_set_transform(flight_pos, visual_time * 8.0, Vector2(1.0, 1.0))
			units_layer.draw_circle(Vector2.ZERO, 7.0, Color(0.4, 0.45, 0.7, 0.75))
			units_layer.draw_arc(Vector2.ZERO, 8.5, 0, TAU, 12, Color(0.65, 0.7, 0.9, 0.6), 2.0, true)
		else:
			units_layer.draw_set_transform(flight_pos, progress * TAU * 1.5, Vector2(0.9, 0.9))
			units_layer.draw_texture(ball_texture, Vector2(-8, -8))
	units_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Por cima de tudo: bolhas de escudo, partículas da aura, golpes, barras, estrelas e números.
func _draw_overlay_layer() -> void:
	if state.is_empty() or _phase() == "menu":
		return
	var canvas: Node2D = overlay_layer
	for entry: Dictionary in frame_entries:
		var unit: Dictionary = entry["unit"]
		if not bool(unit.get("alive", true)) or bool(entry["ghost"]):
			continue
		var feet: Vector2 = entry["feet"]
		var height: float = float(entry["height"])
		var bubble_center: Vector2 = feet + Vector2(0, -height * 0.5)
		if float(unit.get("dance_shield", 0)) > 0.0:
			var shield_frame: Dictionary = _dance_vfx_data(unit)
			if not shield_frame.is_empty():
				_draw_vfx_frame(canvas, shield_frame)
			elif not vfx.has_effect("escudo_danca_01"):
				canvas.draw_arc(bubble_center, height * 0.62, 0, TAU, 32, Color(GOLD, 0.35 + 0.15 * sin(visual_time * 5.0)), 2.0, true)
		if float(unit.get("shield", 0)) > 0.0 and _phase() == "combat":
			canvas.draw_arc(bubble_center, height * 0.56, -PI * 0.15, PI * 1.15, 24, Color(0.65, 0.86, 1.0, 0.35), 2.0, true)
		if float(unit.get("stun_remaining", 0)) > 0.0:
			for index: int in range(3):
				var angle: float = visual_time * 5.0 + index * TAU / 3.0
				var spark: Vector2 = feet + Vector2(cos(angle) * 9, -height - 19 + sin(angle) * 3)
				canvas.draw_circle(spark, 1.7, GOLD)
		if int(entry["level"]) >= 3:
			for index: int in range(7):
				var rise: float = fposmod(visual_time * 0.55 + index / 7.0 + float(unit["id"]) * 0.13, 1.0)
				var sway: float = sin(index * 2.3 + visual_time * 2.0) * 13.0 * float(entry["scale"])
				var mote: Vector2 = (feet + Vector2(sway, -6 - rise * height * 1.15)).round()
				var size: float = 3.0 if index % 3 == 0 else 2.0
				var fade: float = 1.0 - rise
				canvas.draw_rect(Rect2(mote - Vector2.ONE, Vector2(size + 2, size + 2)), Color(0.15, 0.06, 0.22, 0.75 * fade))
				canvas.draw_rect(Rect2(mote, Vector2(size, size)), Color(Color("ffd85c") if index % 2 == 0 else Color("d6a8ff"), fade))
	for effect: Dictionary in slashes:
		var life: float = float(effect["life"]) / 0.2
		var start: float = float(effect["seed"])
		canvas.draw_arc(effect["position"], 11.0 + (1.0 - life) * 6.0, start, start + 1.9, 10, Color(GOLD if bool(effect["critical"]) else Color("fff4de"), life), 2.5 if bool(effect["critical"]) else 1.8, true)
	_draw_library_feedback(canvas, "front")
	_draw_kit_feedback(canvas)
	for entry: Dictionary in frame_entries:
		_draw_bars(canvas, entry)
	var font: Font = ThemeDB.fallback_font
	for effect: Dictionary in floating:
		var alpha: float = clampf(float(effect["life"]) / 0.35, 0.0, 1.0)
		var size: int = int(effect.get("size", 15))
		var position: Vector2 = effect["position"]
		var is_crit: bool = bool(effect.get("critical", false))
		var outline_width: int = 5 if is_crit else 3
		canvas.draw_string_outline(font, position, str(effect["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_width, Color(0, 0, 0, 0.85 * alpha))
		canvas.draw_string(font, position, str(effect["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size, (effect["color"] as Color) * Color(1, 1, 1, alpha))


func _draw_bars(canvas: CanvasItem, entry: Dictionary) -> void:
	var unit: Dictionary = entry["unit"]
	if bool(entry["ghost"]) or not bool(unit.get("alive", true)) or not unit.has("max_hp"):
		if bool(entry["ghost"]) and int(entry["level"]) > 1:
			_draw_level_stars(canvas, (entry["feet"] as Vector2) + Vector2(0, -float(entry["height"]) - 10), int(entry["level"]))
		return
	var feet: Vector2 = entry["feet"]
	var height: float = float(entry["height"])
	var team: int = int(unit.get("team", 0))
	var maximum: float = maxf(float(unit.get("max_hp", 1)), 1.0)
	var width: float = 38.0
	var bar: Rect2 = Rect2((feet + Vector2(-width * 0.5, -height - 12)).round(), Vector2(width, 6))
	canvas.draw_rect(bar.grow(1), Color(0.02, 0.02, 0.03, 0.85))
	var hp_ratio: float = clampf(float(unit.get("hp", 0)) / maximum, 0.0, 1.0)
	canvas.draw_rect(Rect2(bar.position, Vector2(width * hp_ratio, 6)), TEAM_COLORS[team])
	canvas.draw_rect(Rect2(bar.position, Vector2(width * hp_ratio, 2)), Color(1, 1, 1, 0.25))
	for part: Dictionary in _shield_parts(unit, width):
		canvas.draw_rect(Rect2(bar.position + Vector2(float(part["start"]), 6), Vector2(float(part["width"]), 2)), part["color"])
	var tick_size: float = 250.0 if maximum <= 1200.0 else 500.0
	var tick: float = tick_size
	while tick < maximum:
		var x: float = bar.position.x + width * tick / maximum
		canvas.draw_line(Vector2(x, bar.position.y), Vector2(x, bar.position.y + 4), Color(0, 0, 0, 0.55), 1.0)
		tick += tick_size
	if not (unit.get("bleeds", []) as Array).is_empty():
		canvas.draw_colored_polygon(PackedVector2Array([bar.position + Vector2(-6, 0), bar.position + Vector2(-3, 3), bar.position + Vector2(-6, 7), bar.position + Vector2(-9, 3)]), Color("e0485a"))
	if team == 0:
		var items: Array = (state.get("own", {}).get("equipment", {}) as Dictionary).get(int(unit["id"]), [])
		for index: int in range(items.size()):
			canvas.draw_rect(Rect2(bar.position + Vector2(index * 6, 9), Vector2(4, 4)), GOLD)
	_draw_level_stars(canvas, bar.position + Vector2(width * 0.5, -6), int(entry["level"]))


## Faixa de escudo separada da vida: dança dourada e mala azul continuam legíveis juntas.
func _shield_parts(unit: Dictionary, width: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var base: float = maxf(0.0, float(unit.get("shield", 0)))
	var dance: float = maxf(0.0, float(unit.get("dance_shield", 0)))
	var total: float = base + dance
	if total <= 0.0:
		return result
	var full_width: float = minf(width, width * total / maxf(1.0, float(unit.get("max_hp", 1))))
	var cursor: float = width - full_width
	for layer: Array in [["dance", dance, GOLD], ["base", base, Color("a7dfff")]]:
		var part_width: float = full_width * float(layer[1]) / total
		if part_width > 0.0:
			result.append({"kind": layer[0], "start": cursor, "width": part_width, "color": layer[2]})
			cursor += part_width
	return result


## Estrelas vetoriais sobre a barra: 1 bronze, 2 prata, 3 ouro.
func _draw_level_stars(canvas: CanvasItem, center: Vector2, level: int) -> void:
	var color: Color = LEVEL_COLORS[clampi(level, 1, 3) - 1]
	for index: int in range(level):
		var star_center: Vector2 = center + Vector2((index - (level - 1) * 0.5) * 9.0, 0)
		var points: PackedVector2Array = PackedVector2Array()
		for point: int in range(10):
			var radius: float = 4.4 if point % 2 == 0 else 1.9
			var angle: float = -PI * 0.5 + point * PI / 5.0
			points.append(star_center + Vector2(cos(angle), sin(angle)) * radius)
		canvas.draw_colored_polygon(points, color)
		points.append(points[0])
		canvas.draw_polyline(points, Color(0.08, 0.06, 0.05, 0.85), 1.0, true)
