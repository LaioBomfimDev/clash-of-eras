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
const CharacterBank = preload("res://client/character_animation_bank.gd")
const CharacterPlayer = preload("res://client/character_animation_player.gd")
const OnlineClient = preload("res://net/online_client.gd")
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
	"neymar": "Chute ricochete à distância: até 3 impactos (A → B → A). Dano decrescente: 1º impacto 100%, 2º impacto 80% e 3º impacto 50%.",
	"caramelo": "Caça um alvo à distância no começo da luta. Morde e causa sangramento; elimina alvos com até 10% de vida.",
	"obama": "Tanque. A mala absorve dano e renova parte da própria proteção durante a luta.",
	"zumbi": "Estocadas de lança. Concede +15% de crítico e velocidade à equipe. Críticos consecutivos acumulam poder progressivo (+20 de dano por acerto crítico).",
	"michael": "Moonwalk por 3 hexágonos; ao parar, dá escudo à equipe. Enquanto está vivo em campo, mantém uma cura periódica em toda a equipe.",
	"barbie": "Vanguarda protetora. Entra com o Ken invocado; causa +50% de dano enquanto ele estiver vivo.",
	"ken": "Guardião invocado pela Barbie. Atrai os golpes destinados a ela; enquanto vive, fortalece o dano dela.",
	"elon": "Artilharia espacial. Dispara 3 minifoguetes focados e no 4º tiro um Super Foguete com explosão que penetra 2 quadros na retaguarda inimiga.",
	"snoop": "Atirador de fumaça. Lança nuvem em grande área (raio 2) que causa dano mágico, faz inimigos errarem 30% dos ataques e acelera aliados em +25%.",
	"lula": "Ao cair, revive com 40% de vida. No nível 3, pode voltar uma segunda vez na rodada com 30% de vida.",
	"bob_marley": "Ritmo de paz e amor: aura de amplo alcance (raio 4/5/6). Aliados atacam +30% mais rápido; inimigos, 30% mais devagar.",
	"rapunzel": "Começa com 0/100 mana e ganha 25 por ataque lançado. Ao encher, puxa o inimigo mais distante e o atordoa; a mana é consumida."
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
	"elon": "Artilharia Espacial · 3 Minifoguetes + Super Foguete",
	"snoop": "Atirador Tático · Cortina de Fumaça",
	"lula": "Vanguarda Resiliente · Volta por Cima",
	"bob_marley": "Apoio de Ritmo · Aura de Paz e Amor",
	"rapunzel": "Apoio Estratégico · Laço de Trança Dourada"
}

var session: Session = Session.new()
var art: Visuals = Visuals.new()
var vfx: VfxLibrary = VfxLibrary.new()
var character_bank: CharacterBank = CharacterBank.new()
var character_player: CharacterPlayer = CharacterPlayer.new(character_bank)
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
var passive_character_stamps: Dictionary = {}
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
var boss_result_view_mode: String = "rewards"

func _boss_icon(icon_name: String) -> Texture2D:
	var path: String = "res://assets/ui/boss_dev/" + icon_name + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

var ui: Control
var heart_controls: Array[Array] = [[], []]
var shop_buttons: Dictionary = {}
var benefit_buttons: Dictionary = {}
var bag_buttons: Dictionary = {}
var equipment_buttons: Array[Button] = []
var synergy_root: Control
var synergy_hover_card: Panel
var synergy_hover_root: Control
var hovered_synergy_key: String = ""
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
var gold_pile_layer: Control
var gold_label: Label
var income_label: Label
var capacity_label: Label
var status_panel: Panel
var status_label: Label
var result_label: Label
var gold_coin_rect: TextureRect = null
var gold_coin_atlas: AtlasTexture = null
var fight_button: Button
var reroll_button: Button
var capacity_button: Button
var bench_button: Button
var dismiss_button: Button
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
var lobby_preview_mode: String = "action" # "action" (no tabuleiro), "pose" (estudo estático)
var result_view_team: int = 0 # 0: próprio, 1: bot inimigo
var result_sort_column: String = "damage" # "hero", "damage", "healing", "shield"
var result_sort_descending: bool = true
var target_fps: int = 30
var eco_mode: bool = false
var lobby_signature: String = ""
var online_client: OnlineClient = OnlineClient.new()
var is_online_match: bool = false
## A rede pode entregar vários estados no mesmo poll; desenhamos apenas o mais recente.
var _online_snapshot_pending: bool = false
var performance_label: Label
var lobby_performance_label: Label
var show_performance_diagnostics: bool = false
var _performance_elapsed: float = 0.0
var _performance_frame_ms: Array[float] = []
var _performance_cpu_us: int = 0
var _performance_metrics: Dictionary = {"fps": 0, "frame_ms": 0.0, "p95_frame_ms": 0.0, "client_cpu_ms": 0.0, "render_width": 0, "render_height": 0}
var matchmaking_seconds_left: float = 20.0
var opponent_title: String = "BOT LOCAL"
var opponent_name_label: Label = null
var queue_countdown_label: Label = null
var player_name: String = "Jogador"
var player_name_label: Label = null
var player_name_input: LineEdit = null
const PLAYER_NAME_SAVE_PATH: String = "user://player_name.cfg"

func _load_player_name() -> void:
	if FileAccess.file_exists(PLAYER_NAME_SAVE_PATH):
		var file: FileAccess = FileAccess.open(PLAYER_NAME_SAVE_PATH, FileAccess.READ)
		if file != null:
			var saved: String = file.get_as_text().strip_edges()
			if not saved.is_empty():
				player_name = saved.substr(0, 16)
			file.close()
	if player_name.is_empty() or player_name == "Jogador":
		player_name = "Jogador%d" % randi_range(100, 999)

func _save_player_name(new_name: String) -> void:
	var cleaned: String = new_name.strip_edges().substr(0, 16)
	if cleaned.is_empty():
		return
	player_name = cleaned
	var file: FileAccess = FileAccess.open(PLAYER_NAME_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(cleaned)
		file.close()

var hex_polygons_outer: Dictionary = {}
var hex_polygons_inner: Dictionary = {}
var hex_outlines_outer: Dictionary = {}
var hex_outlines_inner: Dictionary = {}
var boss_vfx_textures: Dictionary = {}
var fullscreen_button: Button = null
var hud_fullscreen_button: Button = null
var rotate_device_panel: Panel = null

func _toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
		(function() {
			var doc = window.document;
			var docEl = doc.documentElement;
			var requestFS = docEl.requestFullscreen || docEl.mozRequestFullScreen || docEl.webkitRequestFullScreen || docEl.msRequestFullscreen;
			var cancelFS = doc.exitFullscreen || doc.mozCancelFullScreen || doc.webkitExitFullscreen || doc.msExitFullscreen;
			var isFS = doc.fullscreenElement || doc.mozFullScreenElement || doc.webkitFullscreenElement || doc.msFullscreenElement;
			if (!isFS) {
				if (requestFS) { requestFS.call(docEl); }
			} else {
				if (cancelFS) { cancelFS.call(doc); }
			}
		})();
		""")
	else:
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

var hero_preview_control: Control
var hud_controls: Array[Control] = []
var drag: Node2D
## Camadas: chão (este nó) → sprites com escala de pixel art → barras/efeitos/textos.
var units_layer: Node2D
var overlay_layer: Node2D
var frame_entries: Array[Dictionary] = []
var level_bursts: Array[Dictionary] = []
var kit_effects: Array[Dictionary] = []
## Área real do foguete (célula + raio do evento) acesa por um instante; só apresentação.
var blast_zones: Array[Dictionary] = []
## Tremor curto do mundo no impacto do foguete; o HUD fica parado no CanvasLayer.
const SHAKE_DURATION: float = 0.3
const SHAKE_PIXELS: float = 5.0
## Explosão do foguete em ordem de preferência; a primeira disponível no pacote é usada.
const ROCKET_BLASTS: Array = ["explosao_03", "explosao_02", "foguete_01"]
var shake_remaining: float = 0.0
var mouse_pointer: Vector2 = Vector2(-999, -999)
var world_item_hover_rects: Array[Dictionary] = []
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
	if OS.has_feature("web"):
		Engine.max_fps = 0 # Na Web/WASM o navegador gerencia o timing perfeitamente (sem stutter)
	else:
		Engine.max_fps = target_fps

	# Pré-calcula os 64 hexágonos do tabuleiro para desempenho máximo sem alocações por frame
	for r: int in range(8):
		for c: int in range(8):
			var cell: Vector2i = Vector2i(c, r)
			hex_polygons_outer[cell] = Board.hex_polygon(cell, 0.07)
			hex_polygons_inner[cell] = Board.hex_polygon(cell, 0.16)
			var outer_outline: PackedVector2Array = hex_polygons_outer[cell].duplicate()
			outer_outline.append(outer_outline[0])
			hex_outlines_outer[cell] = outer_outline
			var inner_outline: PackedVector2Array = hex_polygons_inner[cell].duplicate()
			inner_outline.append(inner_outline[0])
			hex_outlines_inner[cell] = inner_outline

	specs.merge(Catalog.load_summon_specs())
	art.load_assets()
	character_bank.load_assets()
	for frame: Dictionary in character_bank.loaded_frames():
		art.register_animation_frame(frame["texture"], frame["anchor"])
	# A pose de conjuração também é usada pela primeira vez só no combate do Boss.
	art.texture_for("boss_dev", "south-west", 0.0, "cast")
	character_player.clear()
	vfx.load_assets()
	add_child(audio)
	heart = load("res://assets/heart.png") as Texture2D
	arena = load(ARENA_PATH) as Texture2D if ResourceLoader.exists(ARENA_PATH) else null
	if ResourceLoader.exists(LOBBY_BG_PATH):
		lobby_bg = load(LOBBY_BG_PATH) as Texture2D
	board_perimeter = Board.perimeter_segments()
	_load_arena_props()
	for effect_name: String in ["explosao_fogo_roxo", "explosao_fogo_vermelho", "fogo_vermelho_projetil", "fogo_roxo_projetil", "furacao_fogo", "furacao_fogo_frame_0", "furacao_fogo_frame_1", "furacao_fogo_frame_2", "furacao_fogo_frame_3", "loot_orb_brilhante"]:
		var effect_path: String = "res://assets/vfx/boss_dev/%s.png" % effect_name
		boss_vfx_textures[effect_name] = load(effect_path) as Texture2D if ResourceLoader.exists(effect_path) else null
	units_layer = _layer(CanvasItem.TEXTURE_FILTER_LINEAR, _draw_units_layer)
	var pixel_material: ShaderMaterial = ShaderMaterial.new()
	pixel_material.shader = PIXEL_SHADER
	units_layer.material = pixel_material
	overlay_layer = _layer(CanvasItem.TEXTURE_FILTER_NEAREST, _draw_overlay_layer)
	_load_player_name()
	_build_ui()
	drag = DragController.install(self)
	_setup_online_client()
	_refresh()
	print("CLIENT_READY: Clash of Eras protótipo local; lobby de boas-vindas; 30 FPS; compêndio de heróis")


func _setup_online_client() -> void:
	online_client.matchmaking_tick.connect(func(seconds_left: float) -> void:
		matchmaking_seconds_left = seconds_left
		if queue_countdown_label != null and is_instance_valid(queue_countdown_label):
			queue_countdown_label.text = "%d s" % ceilf(seconds_left)
	)
	online_client.fallback_to_bot.connect(func(_reason: String) -> void:
		if lobby_subview == "matchmaking":
			toast_text = "Adversário não encontrado em 20s. Jogando contra Bot."
			toast_remaining = 3.5
			is_online_match = false
			opponent_title = "BOT LOCAL"
			_start_match()
	)
	online_client.match_started.connect(func(_team: int, opp_name: String) -> void:
		is_online_match = true
		opponent_title = opp_name
		toast_text = "Partida online contra %s!" % opp_name
		toast_remaining = 3.5
		_start_match()
	)
	online_client.snapshot_received.connect(func(snap: Dictionary) -> void:
		if is_online_match:
			state = snap
			_online_snapshot_pending = true
	)
	online_client.events_received.connect(func(evs: Array[Dictionary]) -> void:
		if is_online_match:
			for ev: Dictionary in evs:
				_process_game_event(ev)
	)
	online_client.match_ended.connect(func(winner: int, reason: String) -> void:
		if is_online_match:
			var msg: String = "Fim de partida: %s" % reason
			if winner == 0:
				msg = "VITÓRIA! (%s)" % reason
			elif winner == 1:
				msg = "DERROTA! (%s)" % reason
			toast_text = msg
			toast_remaining = 4.0
	)


func _process(delta: float) -> void:
	var cpu_start: int = Time.get_ticks_usec()
	visual_time += delta
	toast_remaining = maxf(0.0, toast_remaining - delta)
	if online_client != null:
		online_client.step(delta)
	if gold_coin_atlas != null:
		Kit.update_coin_atlas_frame(gold_coin_atlas, visual_time, 8.0, 8)
	if not menu_open and not is_online_match:
		session.step(delta)
		_consume_events()
		_refresh(false) # _consume_events já obteve o estado local deste passo.
	elif is_online_match and _online_snapshot_pending:
		_online_snapshot_pending = false
		_refresh()
	else:
		_refresh_status()
	_prepare_frame()
	_update_visuals(delta)
	# Verificação inteligente de orientação para celular (avisa se estiver em pé)
	var win_size: Vector2 = DisplayServer.window_get_size()
	if rotate_device_panel != null and is_instance_valid(rotate_device_panel):
		rotate_device_panel.visible = win_size.y > (win_size.x * 1.05) and win_size.x > 0
	queue_redraw()
	units_layer.queue_redraw()
	overlay_layer.queue_redraw()
	if gold_pile_layer != null and is_instance_valid(gold_pile_layer) and gold_pile_layer.visible:
		gold_pile_layer.queue_redraw()
	if is_instance_valid(hero_preview_control) and hero_preview_control.is_visible_in_tree():
		hero_preview_control.queue_redraw()
	_update_performance(delta, Time.get_ticks_usec() - cpu_start)


## Medições locais: delta é o intervalo real entre quadros; CPU exclui draw/GPU.
func _update_performance(delta: float, cpu_us: int) -> void:
	_performance_elapsed += delta
	_performance_cpu_us += cpu_us
	_performance_frame_ms.append(delta * 1000.0)
	if _performance_elapsed < 1.0:
		return
	var count: int = _performance_frame_ms.size()
	_performance_frame_ms.sort()
	var render_texture: ViewportTexture = get_viewport().get_texture()
	_performance_metrics = {"fps": Engine.get_frames_per_second(), "frame_ms": _performance_elapsed * 1000.0 / count,
		"p95_frame_ms": _performance_frame_ms[mini(int(count * 0.95), count - 1)],
		"client_cpu_ms": float(_performance_cpu_us) / float(count) / 1000.0,
		"render_width": render_texture.get_width() if render_texture != null else 0,
		"render_height": render_texture.get_height() if render_texture != null else 0}
	var fps_text: String = "%d FPS · %.1f ms" % [int(_performance_metrics["fps"]), float(_performance_metrics["frame_ms"])]
	var network_text: String = "BOT LOCAL"
	var rtt_ms: float = -1.0
	if is_online_match:
		network_text = "REDE —"
		if online_client.has_method("get_network_metrics"):
			var network: Dictionary = online_client.call("get_network_metrics")
			rtt_ms = float(network.get("rtt_ms", -1.0))
			if rtt_ms >= 0.0:
				network_text = "REDE %.0f ms" % rtt_ms
	_performance_metrics["rtt_ms"] = rtt_ms
	if OS.has_feature("web"):
		# Somente números de desempenho; sem nome, formação ou dados da partida.
		JavaScriptBridge.eval("window.__clashPerformance = %s;" % JSON.stringify(_performance_metrics), true)
	var tooltip: String = "Intervalo médio: %.1f ms; p95: %.1f ms.\nCPU da atualização: %.2f ms (não inclui desenho/GPU).\nREDE mostra ida e volta ao servidor; é independente do FPS." % [float(_performance_metrics["frame_ms"]), float(_performance_metrics["p95_frame_ms"]), float(_performance_metrics["client_cpu_ms"])]
	if is_instance_valid(performance_label):
		performance_label.text = fps_text + "\n" + network_text
		performance_label.tooltip_text = tooltip
	if is_instance_valid(lobby_performance_label):
		lobby_performance_label.text = fps_text
		lobby_performance_label.tooltip_text = tooltip
	_performance_elapsed = 0.0
	_performance_cpu_us = 0
	_performance_frame_ms.clear()


func get_performance_metrics() -> Dictionary:
	return _performance_metrics.duplicate()


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

	# Alerta para quando o usuário segurar o celular na vertical (em pé)
	rotate_device_panel = _panel(ui, Rect2(0, 0, 1280, 720), 0.96, 0)
	rotate_device_panel.visible = false
	_label(rotate_device_panel, "📱 GIRE O SEU CELULAR", Rect2(140, 210, 1000, 50), 36, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(rotate_device_panel, "Clash of Eras foi criado para ser jogado na horizontal (deitado).\nGire o aparelho de lado e use a Tela Cheia para expandir 100%!", Rect2(140, 275, 1000, 56), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var fs_orient_btn: Button = _button(rotate_device_panel, "⛶ ATIVAR TELA CHEIA AGORA", Rect2(470, 370, 340, 54), _toggle_fullscreen)
	fs_orient_btn.add_theme_font_size_override("font_size", 18)

	_show_menu()


func _build_top_bar() -> void:
	for team: int in range(2):
		var plate: Panel = _panel(ui, Rect2(12 if team == 0 else 976, 10, 292, 64))
		hud_controls.append(plate)
		var right: bool = team == 1
		var name_lbl: Label = _label(plate, ("VOCÊ (%s)" % player_name) if team == 0 else opponent_title, Rect2(14, 4, 264, 22), 16, TEAM_COLORS[team],
			HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT)
		if team == 0:
			player_name_label = name_lbl
		else:
			opponent_name_label = name_lbl
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
	hud_fullscreen_button = _button(ui, "⛶", Rect2(1096, 80, 40, 34), _toggle_fullscreen)
	hud_fullscreen_button.tooltip_text = "Modo Tela Cheia (F11)"
	hud_fullscreen_button.add_theme_font_size_override("font_size", 16)
	hud_controls.append_array([_icon_button(ui, "ui_menu", Rect2(1228, 80, 40, 34), _open_menu, "Menu"), sound_icon_button,
		_icon_button(ui, "ui_scroll", Rect2(1140, 80, 40, 34), _toggle_drawer.bind("log"), "Eventos do combate"), hud_fullscreen_button])
	performance_label = _label(ui, "FPS —\nREDE —", Rect2(978, 80, 112, 36), 10, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hud_controls.append(performance_label)


func _build_synergy_tracker() -> void:
	var header: Button = Button.new()
	header.text = "SINERGIAS · TESTE"
	header.flat = true
	header.position = Vector2(12, 84)
	header.size = Vector2(214, 26)
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Kit.MUTED)
	header.tooltip_text = "Grupos funcionais de teste; passe o mouse nas sinergias para ver quem dá o buff e os heróis."
	header.pressed.connect(_toggle_drawer.bind("synergies"))
	ui.add_child(header)
	hud_controls.append(header)
	synergy_root = _container(ui)

	# Card flutuante rico de sinergia no mouse hover
	synergy_hover_card = _panel(ui, Rect2(232, 112, 356, 280), 0.95, 8)
	synergy_hover_card.visible = false
	synergy_hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hover_style: StyleBoxFlat = synergy_hover_card.get_theme_stylebox("panel") as StyleBoxFlat
	if hover_style != null:
		hover_style.border_color = Color(GOLD, 0.85)
		hover_style.set_border_width_all(2)
	synergy_hover_root = _container(synergy_hover_card)



func _build_bag() -> void:
	bag_panel = _panel(ui, Rect2(12, 340, 214, 196), 0.72)
	bag_title = _label(bag_panel, "", Rect2(10, 6, 196, 20), 14, GOLD)
	bag_root = _container(bag_panel)
	equip_button = _button(bag_panel, "EQUIPAR", Rect2(10, 144, 94, 40), _equip_selected)
	fuse_button = _button(bag_panel, "FUNDIR", Rect2(110, 144, 94, 40), _fuse_selected)
	equip_button.tooltip_text = "Marque 1 item e selecione um herói."
	fuse_button.tooltip_text = "Marque 2 itens de uma receita."
	_apply_ornate_button(equip_button, "teal")
	_apply_ornate_button(fuse_button, "gold")


func _build_unit_card() -> void:
	unit_card = _panel(ui, Rect2(1040, 124, 228, 352), 0.78)
	card_root = _container(unit_card)
	bench_button = _button(unit_card, "RESERVAR", Rect2(10, 298, 124, 42), _bench_or_deploy)
	bench_button.add_theme_font_size_override("font_size", 12)
	_apply_ornate_button(bench_button, "teal")
	dismiss_button = _button(unit_card, "DISPENSAR", Rect2(142, 298, 76, 42), _dismiss_selected)
	dismiss_button.add_theme_font_size_override("font_size", 11)
	dismiss_button.tooltip_text = "Dispensa o herói sem receber ouro. Todos os itens voltam à bolsa; se não houver espaço, nada é removido."
	_apply_ornate_button(dismiss_button, "gold")


func _build_shop() -> void:
	var capacity_pill: Panel = _panel(ui, Rect2(148, 558, 122, 32), 0.72, 16)
	capacity_label = _label(capacity_pill, "", Rect2(6, 5, 110, 22), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# Pilha de moedas de ouro ilustrada atrás do mostrador de ouro
	gold_pile_layer = Control.new()
	gold_pile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_pile_layer.position = Vector2(1180, 558)
	gold_pile_layer.scale = Vector2(0.6, 0.6)
	gold_pile_layer.draw.connect(_draw_gold_pile_layer)
	ui.add_child(gold_pile_layer)

	var gold_pill: Panel = _panel(ui, Rect2(1124, 542, 112, 38), 0.88, 19)
	gold_coin_atlas = Kit.create_animated_coin_atlas()
	if gold_coin_atlas != null:
		gold_coin_rect = _icon_rect(gold_pill, gold_coin_atlas, Rect2(12, 3, 32, 32))
	else:
		gold_coin_rect = _icon_rect(gold_pill, Kit.icon("ui_coin"), Rect2(12, 3, 32, 32))
	gold_label = _label(gold_pill, "", Rect2(48, 4, 56, 28), 22, GOLD)
	income_label = _label(ui, "", Rect2(1088, 577, 180, 18), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	income_label.mouse_filter = Control.MOUSE_FILTER_PASS

	var shop: Panel = _panel(ui, Rect2(144, 596, 940, 116), 0.85, 10)
	hud_controls.append_array([capacity_pill, gold_pile_layer, gold_pill, income_label, shop])

	capacity_button = _button(shop, "ESPAÇO · 8", Rect2(8, 8, 114, 48), _command.bind("upgrade_capacity", {}))
	capacity_button.icon = Kit.icon("ui_expand")
	reroll_button = _button(shop, "RENOVAR · 2", Rect2(8, 60, 114, 48), _command.bind("reroll", {}))
	reroll_button.icon = Kit.icon("ui_refresh")
	for button: Button in [capacity_button, reroll_button]:
		button.add_theme_constant_override("icon_max_width", 28)
		button.add_theme_font_size_override("font_size", 12)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_apply_ornate_button(button, "teal")

	shop_root = _container(shop)
	var fight_plate: Panel = _panel(ui, Rect2(1092, 596, 176, 116), 0.85, 10)
	hud_controls.append(fight_plate)
	fight_button = _button(fight_plate, "LUTAR", Rect2(8, 8, 160, 100), _fight)
	fight_button.icon = Kit.icon("ui_fight")
	fight_button.add_theme_constant_override("icon_max_width", 32)
	fight_button.add_theme_font_size_override("font_size", 20)
	fight_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_ornate_button(fight_button, "gold")


func _draw_gold_pile_layer() -> void:
	if gold_pile_layer == null or not is_instance_valid(gold_pile_layer):
		return
	var current_gold: int = int(state.get("own", {}).get("gold", 0))
	Kit.draw_gold_pile(gold_pile_layer, Vector2.ZERO, current_gold, visual_time)


func _apply_ornate_button(btn: Button, theme_name: String = "teal") -> void:
	var empty_box: StyleBoxEmpty = StyleBoxEmpty.new()
	for state_name: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state_name, empty_box)

	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Cores e contorno de alta legibilidade no texto do botão
	btn.add_theme_color_override("font_color", Color("f0fdf4"))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color("fef08a"))
	btn.add_theme_color_override("font_disabled_color", Color(0.65, 0.70, 0.75, 0.50))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	btn.add_theme_constant_override("outline_size", 3)

	# Cores do ícone do botão
	btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", Color("fef08a"))
	btn.add_theme_color_override("icon_disabled_color", Color(0.65, 0.70, 0.75, 0.50))

	var frame: Control = Control.new()
	frame.show_behind_parent = true
	frame.size = btn.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(frame)
	frame.draw.connect(func() -> void:
		var is_h: bool = btn.is_hovered() and not btn.disabled
		var is_p: bool = btn.button_pressed
		Kit.draw_ornate_button_frame(frame, Rect2(Vector2.ZERO, frame.size), theme_name, is_h, btn.disabled, is_p)
	)
	btn.mouse_entered.connect(frame.queue_redraw)
	btn.mouse_exited.connect(frame.queue_redraw)
	btn.button_down.connect(frame.queue_redraw)
	btn.button_up.connect(frame.queue_redraw)


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


func _rich_label(parent: Control, bbcode: String, rect: Rect2, font_size: int, default_color: Color = Color("dfe6e3")) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = false
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", default_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = rect.position
	label.size = rect.size
	parent.add_child(label)
	label.text = bbcode
	return label


func _button(parent: Control, text: String, rect: Rect2, action: Callable) -> Button:
	var button: Button = Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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


func _refresh(synchronize_local_state: bool = true) -> void:
	if not is_online_match and synchronize_local_state:
		state = session.snapshot_for_team(0)
	var phase: String = _phase()
	var own: Dictionary = state.get("own", {})
	var prep: bool = phase == "preparation"
	var round_index: int = int(state.get("round", 1))
	var config: Dictionary = state.get("test_config", {})
	var is_boss_round: bool = bool(state.get("is_boss_round", false)) or round_index == 4
	if is_online_match:
		round_label.text = ("RODADA 4 · BOSS CRIADOR · ONLINE" if is_boss_round else ("RODADA %d · ONLINE" % round_index)) if phase != "menu" else "CLASH OF ERAS"
	else:
		round_label.text = ("RODADA 4 · BOSS CRIADOR" if is_boss_round else ("RODADA %d" % round_index)) if phase != "menu" else "PROTÓTIPO LOCAL"
	if player_name_label != null and is_instance_valid(player_name_label):
		player_name_label.text = "VOCÊ (%s)" % player_name
	if opponent_name_label != null and is_instance_valid(opponent_name_label):
		opponent_name_label.text = "DESENVOLVEDOR (BOSS)" if (is_boss_round and phase != "menu") else opponent_title
	var elapsed: float = float(state.get("elapsed", 0.0))
	var phase_names: Dictionary = {"menu": "CLASH OF ERAS", "benefit": "BENEFÍCIO",
		"preparation": ("PREPARAÇÃO · BOSS DEV (%ds)" % ceili(float(state.get("prep_remaining", 30)))) if is_boss_round else ("PREPARAÇÃO · %ds" % ceili(float(state.get("prep_remaining", 30)))),
		"combat": ("BATALHA DE BOSS · %ds" % maxi(0, ceili(30.0 - elapsed))) if is_boss_round else (("COMBATE · %ds" % maxi(0, ceili(30.0 - elapsed))) + ("  ⚡" if bool(state.get("accelerated", false)) else "")),
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
	var income_view: Dictionary = _income_view(own)
	income_label.text = income_view["text"]
	income_label.tooltip_text = income_view["tooltip"]
	(gold_label.get_parent() as Control).tooltip_text = income_view["tooltip"]
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
	_refresh_status()
	var in_match: bool = phase not in ["menu"]
	for control: Control in hud_controls + [bag_panel, synergy_root]:
		control.visible = in_match
	performance_label.visible = in_match and show_performance_diagnostics
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


## Mensagens expiram mesmo quando ainda não chegou outro snapshot online.
func _refresh_status() -> void:
	var phase: String = _phase()
	var hint: String = {"benefit": "Escolha um benefício para começar.",
		"preparation": "Arraste ou toque: heróis da loja entram em campo ou na reserva; itens equipam heróis.",
		"combat": "Combate automático · toque num herói para inspecionar.",
		"round_result": "Veja quem causou dano, curou e protegeu.", "match_over": "Recomece para testar outra formação."}.get(phase, "")
	if phase == "preparation":
		if _active_count() == 0:
			hint = "Recrute heróis na loja abaixo para colocar seu time em campo!"
		elif _selected_own().is_empty() and selected_items.size() == 1:
			hint = "Item marcado: toque num herói, arraste o item até ele ou use EQUIPAR."
		elif not _selected_own().is_empty():
			hint = "Toque ou arraste até um hexágono azul, a reserva ou outro herói para trocar."
	if toast_remaining > 0.0:
		hint = toast_text
	status_label.text = hint
	status_panel.visible = not hint.is_empty() and phase != "menu"


## Valores recebidos da Session; não reproduz a fórmula de renda no cliente.
func _income_view(own: Dictionary) -> Dictionary:
	var income: Dictionary = own.get("income", {})
	if not income.has("next_round_total"):
		return {"text": "RENDA —", "tooltip": "Renda ainda não informada pela partida."}
	var streak: int = int(own.get("win_streak", 0))
	var total: int = int(income["next_round_total"])
	var tooltip: String = "Rodada %d: %d de renda + %d de bônus = %d moedas.\nVitórias seguidas: %d.\nO bônus de sequência é fixo; a rodada de Boss não gera esse bônus." % [int(income.get("next_round", 0)), int(income.get("next_round_base", 0)), int(income.get("win_bonus", 0)), total, streak]
	return {"text": "PRÓXIMA +%d · SÉRIE %d" % [total, streak], "tooltip": tooltip}


func _on_phase_changed(phase: String) -> void:
	_hide_synergy_hover()
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
	var own: Dictionary = state.get("own", {})
	var units_summary: Array = []
	for u_dict: Variant in own.get("units", []):
		if u_dict is Dictionary:
			units_summary.append([u_dict.get("key", ""), bool(u_dict.get("active", false)), int(u_dict.get("level", 1))])
	var signature: String = str(groups) + str(units_summary)
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
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var syn_y: float = 112.0 + index * 50.0
		row.mouse_entered.connect(func() -> void:
			var s_box: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
			if s_box != null:
				s_box.border_color = Color.WHITE
				s_box.set_border_width_all(2)
			_show_synergy_hover(group, syn_y)
		)
		row.mouse_exited.connect(func() -> void:
			var s_box: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
			if s_box != null:
				s_box.border_color = Color(GOLD, 0.85) if tier > 0 else Kit.EDGE
				s_box.set_border_width_all(1)
			_hide_synergy_hover()
		)
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


func _show_synergy_hover(group: Dictionary, anchor_y: float) -> void:
	if synergy_hover_card == null or synergy_hover_root == null:
		return
	var key: String = str(group.get("key", ""))
	hovered_synergy_key = key
	var own: Dictionary = state.get("own", {})
	var group_name: String = str(group.get("name", "")).replace(" · TESTE", "")
	var count: int = int(group.get("count", 0))
	var tier: int = int(group.get("tier", 0))
	var breakpoints: Array = group.get("breakpoints", [])

	var level: int = 0
	for threshold: Variant in breakpoints:
		if count >= int(threshold):
			level += 1
	var badge_tier: int = 0 if level == 0 else (3 if level >= breakpoints.size() and breakpoints.size() > 1 else (2 if level >= breakpoints.size() else 1))

	var active_heroes: Array[Dictionary] = []
	var bench_heroes: Array[Dictionary] = []
	for u_dict: Variant in own.get("units", []):
		if not u_dict is Dictionary:
			continue
		var tags: Array = u_dict.get("synergy_tags", [])
		if tags.has(key):
			if bool(u_dict.get("active", false)):
				active_heroes.append(u_dict)
			else:
				bench_heroes.append(u_dict)

	var all_class_heroes: Array[Dictionary] = []
	var owned_keys: Array = own.get("owned", []) as Array
	for h_key: String in HERO_CATALOG_KEYS:
		if specs.has(h_key):
			var spec = specs[h_key]
			if key in spec.synergy_tags:
				all_class_heroes.append({
					"key": h_key,
					"name": spec.display_name,
					"rarity": spec.rarity,
					"owned": owned_keys.has(h_key)
				})

	_clear(synergy_hover_root)

	# 1. Cabeçalho com Badge Hexagonal e Título
	var badge: Kit.Badge = Kit.Badge.new(Kit.icon("syn_" + key), badge_tier, 38.0)
	badge.position = Vector2(8, 8)
	synergy_hover_root.add_child(badge)

	_label(synergy_hover_root, group_name.to_upper(), Rect2(52, 6, 280, 22), 16, GOLD)
	var status_tag: String = "● %d EM CAMPO · ATIVO (NÍVEL %d)" % [count, level] if tier > 0 else ("○ %d EM CAMPO · INATIVO" % count if count > 0 else "○ INATIVO")
	var status_col: Color = Color("4ade80") if tier > 0 else Kit.MUTED
	_label(synergy_hover_root, status_tag, Rect2(52, 26, 280, 18), 12, status_col)

	var sep: ColorRect = ColorRect.new()
	sep.color = Color(GOLD, 0.28)
	sep.position = Vector2(8, 48)
	sep.size = Vector2(334, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	synergy_hover_root.add_child(sep)

	var y_cursor: float = 54.0

	# 2. Seção Patamares de Bônus (Painéis estilizados sem caracteres de terminal)
	_label(synergy_hover_root, "PATAMARES DE BÔNUS:", Rect2(10, y_cursor, 320, 16), 11, Color("8ecae6"))
	y_cursor += 18.0

	var bp_texts: Array[Dictionary] = []
	match key:
		"vanguarda":
			bp_texts.append({"tier_idx": 1, "text": "(2) +25 Armadura e +20 Resistência mágica"})
			bp_texts.append({"tier_idx": 2, "text": "(3) +50 Armadura e +40 Resistência mágica"})
		"atacantes":
			bp_texts.append({"tier_idx": 1, "text": "(2) +10% de Dano de Ataque"})
			bp_texts.append({"tier_idx": 2, "text": "(3) +20% de Dano de Ataque"})
		"atiradores":
			bp_texts.append({"tier_idx": 1, "text": "(2) +15% de Velocidade de Ataque"})
			bp_texts.append({"tier_idx": 2, "text": "(4) +35% de Velocidade de Ataque"})
		"apoio":
			bp_texts.append({"tier_idx": 1, "text": "(2) +10% de Vida Máxima da Equipe"})
			bp_texts.append({"tier_idx": 2, "text": "(4) +25% de Vida Máxima da Equipe"})

	for bp_info: Dictionary in bp_texts:
		var is_bp_active: bool = level >= int(bp_info["tier_idx"])
		var row_panel: Panel = _panel(synergy_hover_root, Rect2(8, y_cursor, 334, 24), 0.6 if is_bp_active else 0.35, 4)
		var r_box: StyleBoxFlat = row_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if r_box != null:
			if is_bp_active:
				r_box.bg_color = Color(0.08, 0.24, 0.15, 0.75)
				r_box.border_color = Color("4ade80", 0.75)
				r_box.set_border_width_all(1)
			else:
				r_box.bg_color = Color(0.06, 0.08, 0.10, 0.40)
				r_box.border_color = Color(1, 1, 1, 0.08)
				r_box.set_border_width_all(1)

		var bp_color: Color = Color("f0fdf4") if is_bp_active else Color(0.65, 0.72, 0.78, 0.65)
		_label(row_panel, str(bp_info["text"]), Rect2(8, 2, 260, 20), 11, bp_color)
		if is_bp_active:
			_label(row_panel, "ATIVO", Rect2(270, 2, 56, 20), 10, Color("4ade80"), HORIZONTAL_ALIGNMENT_RIGHT)
		y_cursor += 27.0

	_label(synergy_hover_root, "Bônus concedido a todos os aliados em combate.", Rect2(10, y_cursor, 330, 14), 10, Color("7e9a9a"))
	y_cursor += 18.0

	# 3. Seção Heróis em Campo (com mini-retratos pixel art)
	var sep2: ColorRect = ColorRect.new()
	sep2.color = Color(GOLD, 0.2)
	sep2.position = Vector2(8, y_cursor)
	sep2.size = Vector2(334, 1)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	synergy_hover_root.add_child(sep2)
	y_cursor += 6.0

	_label(synergy_hover_root, "HERÓIS EM CAMPO (%d):" % active_heroes.size(), Rect2(10, y_cursor, 320, 16), 11, GOLD)
	y_cursor += 18.0

	if not active_heroes.is_empty():
		for u: Dictionary in active_heroes:
			var h_key: String = str(u.get("key", ""))
			var h_name: String = str(u.get("name", h_key.capitalize()))
			var h_lvl: int = int(u.get("level", 1))

			var hero_box: Panel = _panel(synergy_hover_root, Rect2(8, y_cursor, 334, 32), 0.65, 5)
			var h_box_style: StyleBoxFlat = hero_box.get_theme_stylebox("panel") as StyleBoxFlat
			if h_box_style != null:
				h_box_style.border_color = Color(GOLD, 0.45) if tier > 0 else Color(1, 1, 1, 0.12)
				h_box_style.set_border_width_all(1)

			# Retrato pixel art do herói
			_icon_rect(hero_box, art.portrait_for(h_key, 26, 24), Rect2(4, 3, 26, 26))

			# Nome do herói
			_label(hero_box, h_name, Rect2(36, 2, 130, 16), 12, Color.WHITE)

			# Estrelas reais do nível do herói
			_stars(hero_box, Vector2(52, 22), h_lvl, 9.0, true)

			# Status à direita
			var hero_status: String = "● Ligando o buff" if tier > 0 else "○ Pronto em campo"
			var hero_status_col: Color = Color("4ade80") if tier > 0 else Color("f4a261")
			_label(hero_box, hero_status, Rect2(170, 7, 156, 18), 11, hero_status_col, HORIZONTAL_ALIGNMENT_RIGHT)

			y_cursor += 36.0
	else:
		_label(synergy_hover_root, "Nenhum herói desta classe em campo no momento.", Rect2(14, y_cursor, 320, 16), 11, Kit.MUTED)
		y_cursor += 20.0

	# 4. Seção Na Sua Reserva (se houver heróis do jogador no banco)
	if not bench_heroes.is_empty():
		_label(synergy_hover_root, "NA SUA RESERVA (%d):" % bench_heroes.size(), Rect2(10, y_cursor, 320, 16), 11, Color("f4a261"))
		y_cursor += 18.0

		for u: Dictionary in bench_heroes:
			var h_key: String = str(u.get("key", ""))
			var h_name: String = str(u.get("name", h_key.capitalize()))
			var h_lvl: int = int(u.get("level", 1))

			var bench_box: Panel = _panel(synergy_hover_root, Rect2(8, y_cursor, 334, 30), 0.5, 5)
			var b_tex: TextureRect = _icon_rect(bench_box, art.portrait_for(h_key, 24, 22), Rect2(4, 3, 24, 24))
			b_tex.modulate = Color(0.9, 0.9, 0.9, 0.85)

			_label(bench_box, h_name, Rect2(34, 2, 130, 15), 11, Color("e2e8f0"))
			_stars(bench_box, Vector2(48, 20), h_lvl, 8.0, true)
			_label(bench_box, "Coloque em campo!", Rect2(170, 6, 156, 18), 10, Color("cbd5e1"), HORIZONTAL_ALIGNMENT_RIGHT)

			y_cursor += 34.0

	# 5. Seção Todos os Heróis da Classe (Mini-compêndio horizontal com ícones)
	var sep3: ColorRect = ColorRect.new()
	sep3.color = Color(1, 1, 1, 0.1)
	sep3.position = Vector2(8, y_cursor)
	sep3.size = Vector2(334, 1)
	sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	synergy_hover_root.add_child(sep3)
	y_cursor += 6.0

	_label(synergy_hover_root, "TODOS DA CLASSE (%d):" % all_class_heroes.size(), Rect2(10, y_cursor, 320, 15), 10, Kit.MUTED)
	y_cursor += 16.0

	for i: int in range(all_class_heroes.size()):
		var hero_info: Dictionary = all_class_heroes[i]
		var h_key: String = str(hero_info["key"])
		var h_name: String = str(hero_info["name"])
		var is_owned: bool = bool(hero_info["owned"])

		var h_x: float = 8.0 + (i % 4) * 84.0
		var h_y: float = y_cursor + (i / 4) * 32.0

		var chip: Panel = _panel(synergy_hover_root, Rect2(h_x, h_y, 80, 28), 0.45, 4)
		var c_style: StyleBoxFlat = chip.get_theme_stylebox("panel") as StyleBoxFlat
		if c_style != null:
			c_style.border_color = Color(GOLD, 0.5) if is_owned else Color(1, 1, 1, 0.08)
			c_style.set_border_width_all(1)

		var chip_icon: TextureRect = _icon_rect(chip, art.portrait_for(h_key, 20, 18), Rect2(3, 3, 22, 22))
		if not is_owned:
			chip_icon.modulate = Color(0.65, 0.65, 0.65, 0.6)

		var short_name: String = h_name.split(" ")[0]
		_label(chip, short_name, Rect2(27, 4, 50, 20), 10, Color.WHITE if is_owned else Kit.MUTED)

	var class_rows: int = ceili(float(all_class_heroes.size()) / 4.0)
	y_cursor += class_rows * 32.0 + 8.0

	synergy_hover_card.size = Vector2(350, y_cursor)
	synergy_hover_card.position.x = 232.0
	synergy_hover_card.position.y = clampf(anchor_y - 10.0, 80.0, SCREEN.y - y_cursor - 10.0)
	synergy_hover_card.visible = true
	units_layer.queue_redraw()


func _hide_synergy_hover() -> void:
	hovered_synergy_key = ""
	if synergy_hover_card != null and is_instance_valid(synergy_hover_card):
		synergy_hover_card.visible = false
	if units_layer != null and is_instance_valid(units_layer):
		units_layer.queue_redraw()


func _rich_synergy_tooltip(group: Dictionary, own: Dictionary) -> String:
	var key: String = str(group.get("key", ""))
	var group_name: String = str(group.get("name", "")).replace(" · TESTE", "")
	var count: int = int(group.get("count", 0))
	var tier: int = int(group.get("tier", 0))
	var breakpoints: Array = group.get("breakpoints", [])

	var active_members: Array[String] = []
	var bench_members: Array[String] = []
	for u_dict: Variant in own.get("units", []):
		if not u_dict is Dictionary:
			continue
		var tags: Array = u_dict.get("synergy_tags", [])
		if not tags.has(key):
			continue
		var h_name: String = str(u_dict.get("name", u_dict.get("key", "")))
		var h_level: int = int(u_dict.get("level", 1))
		var level_tag: String = "Nv.%d" % h_level if h_level > 1 else ""
		var label_str: String = h_name + (" (%s)" % level_tag if not level_tag.is_empty() else "")
		if bool(u_dict.get("active", false)):
			active_members.append(label_str)
		else:
			bench_members.append(label_str)

	var all_class_heroes: Array[String] = []
	for h_key: String in HERO_CATALOG_KEYS:
		if specs.has(h_key):
			var spec = specs[h_key]
			if key in spec.synergy_tags:
				all_class_heroes.append(spec.display_name)

	var lines: Array[String] = []
	var status_text: String = ""
	if tier > 0:
		status_text = "ATIVO (Patamar %d)" % tier
	elif breakpoints.size() > 0:
		var needed: int = int(breakpoints[0]) - count
		status_text = "INATIVO (precisa de +%d em campo)" % maxi(1, needed)
	else:
		status_text = "INATIVO"
	lines.append("=== %s · %d membros [%s] ===" % [group_name.to_upper(), count, status_text])
	lines.append("")
	lines.append("PATAMARES DE BUFF:")
	match key:
		"vanguarda":
			lines.append("  %s (2) +25 Armadura e +20 Resistência mágica" % ("▶ [ATIVO]" if tier >= 2 else "•"))
			lines.append("  %s (3) +50 Armadura e +40 Resistência mágica" % ("▶ [ATIVO]" if tier >= 3 else "•"))
			lines.append("  * Bônus aplicado aos membros da Vanguarda.")
		"atacantes":
			lines.append("  %s (2) +10%% de Dano de Ataque" % ("▶ [ATIVO]" if tier >= 2 else "•"))
			lines.append("  %s (3) +20%% de Dano de Ataque" % ("▶ [ATIVO]" if tier >= 3 else "•"))
			lines.append("  * Bônus aplicado aos membros Atacantes.")
		"atiradores":
			lines.append("  %s (2) +15%% de Velocidade de Ataque" % ("▶ [ATIVO]" if tier >= 2 else "•"))
			lines.append("  %s (4) +35%% de Velocidade de Ataque" % ("▶ [ATIVO]" if tier >= 4 else "•"))
			lines.append("  * Bônus aplicado aos membros Atiradores.")
		"apoio":
			lines.append("  %s (2) +10%% de Vida Máxima da Equipe" % ("▶ [ATIVO]" if tier >= 2 else "•"))
			lines.append("  %s (4) +25%% de Vida Máxima da Equipe" % ("▶ [ATIVO]" if tier >= 4 else "•"))
			lines.append("  * Bônus aplicado a TODA a equipe aliada.")
		_:
			lines.append(str(group.get("description", "")))

	lines.append("")
	lines.append("QUEM ESTÁ DANDO O BUFF (EM CAMPO):")
	if not active_members.is_empty():
		for h: String in active_members:
			lines.append("  ✓ %s %s" % [h, "· LIGANDO O BUFF!" if tier > 0 else "· pronto para ativar"])
	else:
		lines.append("  (Nenhum herói desta classe em campo no momento)")

	if not bench_members.is_empty():
		lines.append("")
		lines.append("NA SUA RESERVA:")
		for h: String in bench_members:
			lines.append("  • %s (coloque em campo para somar!)" % h)

	lines.append("")
	lines.append("TODOS OS MEMBROS (%s):" % group_name)
	lines.append("  " + ", ".join(all_class_heroes))

	return "\n".join(lines)


func _item_summary_effect(key: String) -> String:
	match key:
		"blade": return "+20% de ataque"
		"vest": return "+20% de vida"
		"boots": return "+15% vel. ataque"
		"plate": return "+12 armadura"
		"ward": return "+12 resistência"
		"charm": return "+8% de crítico"
		"great_blade": return "+45% de ataque"
		"guard_vest": return "+25% vida · +16 res."
		_:
			var def: Dictionary = (state.get("item_catalog", {}) as Dictionary).get(key, {})
			return str(def.get("description", ""))


func _refresh_shop(own: Dictionary, prep: bool) -> void:
	var offers: Array = own.get("shop", [])
	var phase: String = _phase()
	var signature: String = str(offers) + str(own.get("owned", [])) + str(prep) + str(phase) + str(own.get("gold", 0))
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
		var can_act: bool = prep if hero else (prep or phase == "combat")
		var disabled: bool = not can_act or bool(offer.get("claimed", false)) or maxed or unaffordable
		var disabled_changed: bool = button.disabled != disabled
		button.disabled = disabled
		button.modulate = Color(1, 1, 1, 0.55) if bool(offer.get("claimed", false)) or maxed or not can_act else Color.WHITE
		if disabled_changed:
			var frame: Control = button.get_meta("ornate_frame", null) as Control
			if is_instance_valid(frame):
				frame.queue_redraw()


func _shop_card(offer: Dictionary, own: Dictionary, rect: Rect2) -> Button:
	var hero: bool = offer.get("kind", "item") == "hero"
	var key: String = str(offer.get("key", ""))
	var owned: bool = hero and (own.get("owned", []) as Array).has(key)
	var copies: int = _copies(own, key)
	var claimed: bool = bool(offer.get("claimed", false))
	var status: String = str(int(offer.get("price", 0)))
	if hero:
		status = "RECRUTADO" if claimed else ("GRÁTIS" if not owned else ("NÍVEL MÁX." if copies >= _max_copies() else "NÍVEL %d" % _level_for_copies(copies + 1)))
		if owned and not claimed and copies < _max_copies() and _level_for_copies(copies + 1) == _level_for_copies(copies):
			status = "CÓPIA %d/%d" % [copies + 1, _max_copies()]
	elif claimed:
		status = "COMPRADO"
	var button: Button = _button(shop_root, "", rect, _command.bind("recruit" if hero else "buy_item", {"offer_id": str(offer["offer_id"])}))
	button.set_meta("status", status)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Raridade e paleta visual correspondente
	var rarity_key: String = "common"
	if hero:
		if specs.has(key):
			rarity_key = specs[key].rarity
	else:
		rarity_key = str(state.get("item_catalog", {}).get(key, {}).get("rarity", "common"))
	var r_info: Dictionary = Kit.rarity_info(rarity_key)
	var accent: Color = r_info["accent"]

	var empty_box: StyleBoxEmpty = StyleBoxEmpty.new()
	for state_name: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, empty_box)

	var frame: Control = Control.new()
	frame.show_behind_parent = true
	frame.size = rect.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(frame)
	button.set_meta("ornate_frame", frame)
	frame.draw.connect(func() -> void:
		var is_h: bool = button.is_hovered() and not button.disabled
		Kit.draw_ornate_card_frame(frame, Rect2(Vector2.ZERO, frame.size), rarity_key, is_h, button.disabled)
	)
	button.mouse_entered.connect(frame.queue_redraw)
	button.mouse_exited.connect(frame.queue_redraw)
	button.button_down.connect(frame.queue_redraw)
	button.button_up.connect(frame.queue_redraw)

	if hero:
		_icon_rect(button, art.portrait_for(key, 30, 28), Rect2(25, 4, 60, 56))
		if owned:
			_stars(button, Vector2(98, 7), _level_for_copies(copies), 11.0, true)
		var tags: Array[String] = []
		if specs.has(key):
			tags = specs[key].synergy_tags
		for index: int in range(tags.size()):
			_icon_rect(button, Kit.icon("syn_" + tags[index]), Rect2(6, 6 + index * 16, 14, 14))
		# Nome original do herói centralizado e nítido com contorno escuro
		var name_lbl: Label = _label(button, str(offer.get("name", "")), Rect2(4, 61, 102, 17), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
		name_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
		name_lbl.add_theme_constant_override("outline_size", 2)

		var description: String = "Personagem gratuito: entra no campo ou na reserva." if not owned else "Cópia grátis (%d/%d): junta na hora. %s" % [copies + 1, _max_copies(), ("Sobe para o nível %d." % _level_for_copies(copies + 1)) if _level_for_copies(copies + 1) > _level_for_copies(copies) else "Avança até a próxima evolução."]
		button.tooltip_text = "%s\n%s" % [str(offer.get("name", "")), description]
		var tag_lbl: Label = _label(button, "HERÓI", Rect2(6, 80, 42, 16), 10, accent, HORIZONTAL_ALIGNMENT_LEFT, false)
		tag_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
		tag_lbl.add_theme_constant_override("outline_size", 2)

		var stat_lbl: Label = _label(button, status, Rect2(48, 80, 56, 16), 11, Color("4ade80") if status == "GRÁTIS" else (GOLD if status.begins_with("NÍVEL ") and not claimed else Kit.MUTED), HORIZONTAL_ALIGNMENT_RIGHT, false)
		stat_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
		stat_lbl.add_theme_constant_override("outline_size", 2)
	else:
		# Ícone do item centralizado
		_icon_rect(button, Kit.icon("item_" + key), Rect2(37, 6, 36, 36))

		# Nome original do item (sem palavra 'ITEM')
		var item_name: String = str(offer.get("name", ""))
		if item_name.is_empty():
			item_name = str(state.get("item_catalog", {}).get(key, {}).get("name", key.capitalize()))
		var name_lbl: Label = _label(button, item_name, Rect2(4, 43, 102, 17), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
		name_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
		name_lbl.add_theme_constant_override("outline_size", 2)

		# Efeito e informação completa sem mouse hover
		var effect_text: String = _item_summary_effect(key)
		var eff_lbl: Label = _label(button, effect_text, Rect2(4, 59, 102, 16), 10, Color("4ade80"), HORIZONTAL_ALIGNMENT_CENTER, false)
		eff_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
		eff_lbl.add_theme_constant_override("outline_size", 2)

		button.tooltip_text = _rich_item_tooltip({"key": key})

		# Linha inferior: Preço ou COMPRADO (sem a palavra ITEM)
		if status == "COMPRADO":
			var comp_lbl: Label = _label(button, "COMPRADO", Rect2(4, 78, 102, 16), 11, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, false)
			comp_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
			comp_lbl.add_theme_constant_override("outline_size", 2)
		else:
			_icon_rect(button, Kit.icon("ui_coin"), Rect2(40, 78, 14, 14))
			var price_lbl: Label = _label(button, status, Rect2(56, 76, 26, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_LEFT, false)
			price_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
			price_lbl.add_theme_constant_override("outline_size", 2)
	return button


func _rich_item_tooltip(item: Dictionary) -> String:
	var key: String = str(item.get("key", ""))
	var def: Dictionary = (state.get("item_catalog", {}) as Dictionary).get(key, {})
	var item_name: String = str(def.get("name", _item_name(item)))
	var desc: String = str(def.get("description", ""))
	var mods: Dictionary = def.get("modifiers", {})
	var stat_parts: Array[String] = []
	if mods.has("attack_mult"):
		stat_parts.append("+%d%% Ataque" % int(round((float(mods["attack_mult"]) - 1.0) * 100.0)))
	if mods.has("hp_mult"):
		stat_parts.append("+%d%% Vida" % int(round((float(mods["hp_mult"]) - 1.0) * 100.0)))
	if mods.has("attack_speed_mult"):
		stat_parts.append("+%d%% Vel. Ataque" % int(round((float(mods["attack_speed_mult"]) - 1.0) * 100.0)))
	if mods.has("armor_bonus"):
		stat_parts.append("+%d Armadura" % int(round(float(mods["armor_bonus"]))))
	if mods.has("resist_bonus"):
		stat_parts.append("+%d Resistência" % int(round(float(mods["resist_bonus"]))))
	if mods.has("crit_bonus"):
		stat_parts.append("+%d%% Crítico" % int(round(float(mods["crit_bonus"]) * 100.0)))
	var stats_text: String = " · ".join(stat_parts)
	if not stats_text.is_empty():
		return "%s\n[%s]\n%s" % [item_name, stats_text, desc]
	return "%s\n%s" % [item_name, desc]


func _refresh_bag(own: Dictionary, prep: bool) -> void:
	var bag: Array = own.get("bag", [])
	var capacity: int = int(own.get("bag_capacity", 8))
	var phase: String = _phase()
	var can_manage_bag: bool = prep or phase == "combat"
	for item_id: String in selected_items.duplicate():
		if _item_index(bag, item_id) < 0:
			selected_items.erase(item_id)
	var signature: String = str(bag) + str(selected_items) + str(can_manage_bag) + str(phase) + str(selected_id)
	if signature != bag_signature:
		bag_signature = signature
		_clear(bag_root)
		bag_buttons.clear()
		bag_title.text = "ITENS %d/%d" % [bag.size(), capacity]
		for index: int in range(capacity):
			var item: Dictionary = bag[index] if index < bag.size() else {}
			var item_id: String = str(item.get("id", ""))
			var slot: Button = _button(bag_root, "", Rect2(10 + (index % 4) * 49, 32 + (index / 4) * 52, 46, 46), _select_item.bind(item_id))
			slot.disabled = item.is_empty() or not can_manage_bag
			if not item.is_empty():
				_icon_rect(slot, Kit.icon("item_" + str(item.get("key", ""))), Rect2(7, 7, 32, 32))
				slot.tooltip_text = _rich_item_tooltip(item)
				bag_buttons[item_id] = slot
				if item_id in selected_items:
					var style: StyleBoxFlat = (slot.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
					style.border_color = GOLD
					style.set_border_width_all(3)
					style.bg_color = Color(0.32, 0.26, 0.1, 0.9)
					slot.add_theme_stylebox_override("normal", style)
					slot.add_theme_stylebox_override("hover", style)
					slot.add_theme_stylebox_override("disabled", style)
	var can_equip: bool = can_manage_bag and selected_items.size() == 1 and not _selected_own().is_empty()
	if phase == "combat":
		var sel_unit: Dictionary = _selected_own()
		can_equip = can_equip and bool(sel_unit.get("active", false)) and float(sel_unit.get("hp", 0)) > 0.0
	equip_button.disabled = not can_equip
	fuse_button.disabled = not prep or selected_items.size() != 2


func _refresh_card(own: Dictionary, prep: bool) -> void:
	var unit: Dictionary = _unit_by_id(selected_id)
	var phase: String = _phase()
	unit_card.visible = not unit.is_empty() and phase in ["preparation", "combat"]
	dismiss_button.visible = not unit.is_empty() and int(unit.get("team", -1)) == 0 and phase == "preparation"
	dismiss_button.disabled = not prep
	if not unit_card.visible:
		card_signature = ""
		return
	var team: int = int(unit.get("team", 0))
	var own_unit: bool = team == 0
	var mana_info: Dictionary = _mana_bar_data(unit)
	var mana_shift: float = 18.0 if not mana_info.is_empty() else 0.0
	unit_card.size.y = 352.0 + mana_shift
	bench_button.position.y = 298.0 + mana_shift
	dismiss_button.position.y = 298.0 + mana_shift
	var equipment: Array = []
	if own_unit:
		equipment = (own.get("equipment", {}) as Dictionary).get(selected_id, [])
	elif unit.has("equipment"):
		equipment = unit.get("equipment", [])
	var signature: String = str([unit.get("id"), unit.get("level"), unit.get("active"), unit.get("max_hp"), unit.get("max_mana"), unit.get("attack_damage"), unit.get("armor"), unit.get("resist"), unit.get("effective_crit_chance"), unit.get("attack_speed_multiplier"), equipment, prep, phase])
	var hp_ratio: float = clampf(float(unit.get("hp", 0)) / maxf(1.0, float(unit.get("max_hp", 1))), 0.0, 1.0)
	if signature == card_signature:
		var fill: ColorRect = card_root.get_node_or_null("HpFill") as ColorRect
		if fill != null:
			fill.size.x = 208.0 * hp_ratio
			var hp_node = card_root.get_node_or_null("HpText")
			if hp_node != null:
				var c_hp: int = ceili(float(unit.get("hp", 0)))
				var m_hp: int = ceili(float(unit.get("max_hp", 1)))
				var eq_mods_dyn: Dictionary = unit.get("equipment_modifiers", {})
				var hp_m_dyn: float = float(eq_mods_dyn.get("hp_mult", 1.0))
				var hp_b_dyn: float = float(eq_mods_dyn.get("hp_bonus", 0.0))
				var b_hp: int = 0
				if hp_m_dyn > 1.0001 or hp_b_dyn > 0.0001:
					var base_hp_dyn: float = (float(m_hp) - hp_b_dyn) / maxf(0.1, hp_m_dyn)
					b_hp = maxi(0, roundi(float(m_hp) - base_hp_dyn))
				if hp_node is RichTextLabel:
					var hp_code: String = "[center]%d / %d" % [c_hp, m_hp]
					if b_hp > 0:
						hp_code += " [color=#4ade80](+%d)[/color]" % b_hp
					hp_code += "[/center]"
					(hp_node as RichTextLabel).text = hp_code
				elif hp_node is Label:
					(hp_node as Label).text = "%d / %d" % [c_hp, m_hp]
		var mana_node: Label = card_root.get_node_or_null("ManaText") as Label
		if mana_node != null and not mana_info.is_empty():
			mana_node.text = "MANA  %d / %d" % [int(mana_info["value"]), int(mana_info["maximum"])]
		return
	card_signature = signature
	_clear(card_root)
	equipment_buttons.clear()
	var key: String = str(unit.get("key", ""))
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
		var prev_equip: Array = unit.get("equipment", [])
		var prev_text: String = "Formação da rodada %d.\nAtributos atuais ficam ocultos." % int(state.get("enemy", {}).get("previous_round", 0))
		if prev_equip.is_empty():
			prev_text += "\n(Sem itens na rodada anterior)"
		else:
			prev_text += "\nItens usados na rodada anterior:"
		_label(card_root, prev_text, Rect2(10, 80, 208, 60), 12, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		for index: int in range(4):
			var item: Dictionary = prev_equip[index] if index < prev_equip.size() else {}
			var slot: Button = _button(card_root, "", Rect2(10 + index * 54, 150, 46, 46), Callable())
			slot.disabled = item.is_empty()
			slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if not item.is_empty():
				_icon_rect(slot, Kit.icon("item_" + str(item.get("key", ""))), Rect2(7, 7, 32, 32))
				slot.tooltip_text = "%s\n(Usado pelo adversário na rodada %d)" % [_rich_item_tooltip(item), int(state.get("enemy", {}).get("previous_round", 0))]
			equipment_buttons.append(slot)
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
	# Modificadores de equipamento da unidade
	var item_catalog: Dictionary = state.get("item_catalog", {})
	var eq_mods: Dictionary = (unit.get("equipment_modifiers", {}) as Dictionary).duplicate(true)
	if eq_mods.is_empty() and not equipment.is_empty():
		for it: Dictionary in equipment:
			var it_key: String = str(it.get("key", ""))
			var it_def: Dictionary = item_catalog.get(it_key, {})
			var it_vals: Dictionary = it_def.get("modifiers", {})
			for m_key: String in it_vals:
				var baseline: float = 1.0 if m_key.ends_with("_mult") else 0.0
				eq_mods[m_key] = float(eq_mods.get(m_key, baseline)) + float(it_vals[m_key]) - baseline

	var cur_max_hp: float = float(unit.get("max_hp", 1))
	var hp_mult: float = float(eq_mods.get("hp_mult", 1.0))
	var hp_bon: float = float(eq_mods.get("hp_bonus", 0.0))
	var base_hp_without_items: float = (cur_max_hp - hp_bon) / maxf(0.1, hp_mult)
	var item_hp_gain: int = maxi(0, roundi(cur_max_hp - base_hp_without_items)) if (hp_mult > 1.0001 or hp_bon > 0.0001) else 0

	var cur_atk: float = float(unit.get("attack_damage", 0))
	var atk_mult: float = float(eq_mods.get("attack_mult", 1.0))
	var atk_bon: float = float(eq_mods.get("attack_bonus", 0.0))
	var base_atk_without_items: float = (cur_atk - atk_bon) / maxf(0.1, atk_mult)
	var item_atk_gain: int = maxi(0, roundi(cur_atk - base_atk_without_items)) if (atk_mult > 1.0001 or atk_bon > 0.0001) else 0

	var speed: float = (spec.attacks_per_second if spec != null else 1.0) * float(unit.get("attack_speed_multiplier", 1.0))
	var spd_mult: float = float(eq_mods.get("attack_speed_mult", 1.0))
	var base_spd_without_items: float = speed / maxf(0.1, spd_mult)
	var item_spd_gain: float = maxf(0.0, speed - base_spd_without_items) if spd_mult > 1.0001 else 0.0

	var item_arm_gain: int = roundi(float(eq_mods.get("armor_bonus", 0.0)))
	var item_res_gain: int = roundi(float(eq_mods.get("resist_bonus", 0.0)))
	var item_crit_gain: int = roundi(float(eq_mods.get("crit_bonus", 0.0)) * 100.0)

	var hp_bbcode: String = "[center]%d / %d" % [ceili(float(unit.get("hp", 0))), ceili(cur_max_hp)]
	if item_hp_gain > 0:
		hp_bbcode += " [color=#4ade80](+%d)[/color]" % item_hp_gain
	hp_bbcode += "[/center]"
	var hp_text: RichTextLabel = _rich_label(card_root, hp_bbcode, Rect2(10, 72, 208, 18), 12, Color.WHITE)
	hp_text.name = "HpText"
	if not mana_info.is_empty():
		var mana_track: ColorRect = ColorRect.new()
		mana_track.color = Color("121e2b")
		mana_track.position = Vector2(10, 92)
		mana_track.size = Vector2(208, 16)
		mana_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(mana_track)
		var mana_text: Label = _label(card_root, "MANA  %d / %d" % [int(mana_info["value"]), int(mana_info["maximum"])], Rect2(10, 91, 208, 18), 12, Color("9acbff"), HORIZONTAL_ALIGNMENT_CENTER)
		mana_text.name = "ManaText"

	var atq_text: String = "ATQ  %d" % roundi(cur_atk)
	if item_atk_gain > 0:
		atq_text += " [color=#4ade80](+%d)[/color]" % item_atk_gain

	var vel_text: String = "VEL  %.2f/s" % speed
	if item_spd_gain > 0.001:
		vel_text = "VEL  %.2f [color=#4ade80](+%.2f)[/color]" % [speed, item_spd_gain]

	var arm_text: String = "ARM  %d" % roundi(float(unit.get("armor", 0)))
	if item_arm_gain > 0:
		arm_text += " [color=#4ade80](+%d)[/color]" % item_arm_gain

	var res_text: String = "RES  %d" % roundi(float(unit.get("resist", 0)))
	if item_res_gain > 0:
		res_text += " [color=#4ade80](+%d)[/color]" % item_res_gain

	var crit_text: String = "CRÍT  %d%%" % roundi(float(unit.get("effective_crit_chance", 0)) * 100.0)
	if item_crit_gain > 0:
		crit_text += " [color=#4ade80](+%d%%)[/color]" % item_crit_gain

	var alc_text: String = "ALC  %d" % reach

	var stat_items: Array[Dictionary] = [
		{"bbcode": atq_text, "rect": Rect2(10, 96, 96, 18)},
		{"bbcode": vel_text, "rect": Rect2(108, 96, 112, 18)},
		{"bbcode": arm_text, "rect": Rect2(10, 115, 96, 18)},
		{"bbcode": res_text, "rect": Rect2(108, 115, 112, 18)},
		{"bbcode": crit_text, "rect": Rect2(10, 134, 96, 18)},
		{"bbcode": alc_text, "rect": Rect2(108, 134, 112, 18)}
	]
	for stat_data: Dictionary in stat_items:
		var stat_rect: Rect2 = stat_data["rect"]
		stat_rect.position.y += mana_shift
		_rich_label(card_root, stat_data["bbcode"], stat_rect, 12, Color("dfe6e3"))
	_label(card_root, str(KIT_TEXT.get(key, "")), Rect2(10, 156 + mana_shift, 208, 82), 12, Color("c9d8d2"), HORIZONTAL_ALIGNMENT_LEFT, true)
	for index: int in range(4):
		var item: Dictionary = equipment[index] if index < equipment.size() else {}
		var action: Callable = _command.bind("unequip", {"unit_id": selected_id, "item_id": str(item.get("id", ""))}) if (prep and own_unit) else Callable()
		var slot: Button = _button(card_root, "", Rect2(10 + index * 54, 242 + mana_shift, 46, 46), action)
		slot.disabled = item.is_empty()
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not item.is_empty():
			_icon_rect(slot, Kit.icon("item_" + str(item.get("key", ""))), Rect2(7, 7, 32, 32))
			var action_hint: String = ""
			if not own_unit:
				action_hint = "Item equipado pelo adversário"
			elif prep:
				action_hint = "Toque para devolver à bolsa ou arraste para outro herói"
			else:
				action_hint = "Ativo em combate · não pode remover durante a luta"
			slot.tooltip_text = "%s\n(%s)" % [_rich_item_tooltip(item), action_hint]
		equipment_buttons.append(slot)
	bench_button.visible = own_unit and phase == "preparation"
	bench_button.disabled = not prep
	bench_button.text = "RESERVAR" if bool(unit.get("active", false)) else "EM CAMPO"
	bench_button.tooltip_text = "Guardar na reserva" if bool(unit.get("active", false)) else "Selecione um hexágono azul livre para colocar este herói."


func _show_menu() -> void:
	menu_open = true
	is_online_match = false
	_online_snapshot_pending = false
	opponent_title = "BOT LOCAL"
	if online_client != null:
		online_client.cancel_matchmaking()
	character_player.clear()
	passive_character_stamps.clear()
	lobby_subview = "none"
	visual_pulls.clear()
	for effects: Array in [kit_effects, shield_waves, slashes, floating, level_bursts, blast_zones]:
		effects.clear()
	shake_remaining = 0.0
	position = Vector2.ZERO
	drawer_mode = ""
	overlay_signature = ""
	lobby_signature = ""
	_refresh()


func _open_menu() -> void:
	_show_menu()


func _start_match() -> void:
	if not is_online_match:
		session.reset(MATCH_SEED)
	menu_open = false
	lobby_subview = "none"
	boss_result_view_mode = "rewards"
	if opponent_name_label != null and is_instance_valid(opponent_name_label):
		opponent_name_label.text = opponent_title
	selected_id = -1
	selected_items.clear()
	target_hit_seq.clear()
	for effects: Variant in [visual_ground, visual_directions, visual_moves, visual_attacks, visual_hits, visual_deaths, visual_pulls, shield_waves, slashes, floating, log_lines, level_bursts, kit_effects, blast_zones]:
		effects.clear()
	character_player.clear()
	passive_character_stamps.clear()
	drawer_mode = ""
	overlay_signature = ""
	lobby_signature = ""
	if not is_online_match:
		_consume_events()
	_refresh()
	_update_visuals(1.0)


func _command(op: String, payload: Dictionary = {}) -> Dictionary:
	command_index += 1
	if is_online_match and online_client != null:
		var sent: bool = online_client.send_command(op, payload)
		if op in ["recruit", "buy_item", "upgrade_capacity"]:
			audio.play_cue("purchase")
		return {"ok": sent}
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
	boss_result_view_mode = "rewards"
	_command("next_round")
	target_hit_seq.clear()
	for effects: Variant in [visual_ground, visual_moves, visual_attacks, visual_hits, visual_deaths, visual_pulls, shield_waves, slashes, floating, level_bursts, kit_effects, blast_zones]:
		effects.clear()
	character_player.clear()
	passive_character_stamps.clear()
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


func _dismiss_selected() -> void:
	if _phase() != "preparation" or _selected_own().is_empty():
		return
	var response: Dictionary = _command("dismiss", {"unit_id": selected_id})
	# No online, aguardar o snapshot autoritativo; envio não significa aceitação.
	if bool(response.get("ok", false)) and not is_online_match:
		_select_unit(-1)


# --- Entrada: toque/clique no mundo ------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_toggle_performance_diagnostics()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		hover_cell = Board.pick_cell(motion.position)
		hover_bench = Board.pick_bench(motion.position)
		mouse_pointer = motion.position
		queue_redraw()
		return
	if not event is InputEventMouseButton or not drawer_mode.is_empty():
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	var phase: String = _phase()
	if phase == "combat":
		var inspected: Dictionary = _unit_at_point(mouse.position)
		if not selected_items.is_empty() and selected_items.size() == 1 and not inspected.is_empty() and int(inspected.get("team", 1)) == 0:
			_select_unit(int(inspected["id"]))
			_equip_selected()
			return
		selected_id = int(inspected.get("id", -1)) if not inspected.is_empty() else -1
		card_signature = ""
		_refresh()
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
		var key: String = str(unit.get("key", ""))
		var pose: Dictionary = _visual_pose(unit)
		var body: Dictionary = _body_frame(unit, pose)
		var texture: Texture2D = body["texture"]
		var scale: float = art.board_scale_for(key) * LEVEL_SCALE[clampi(int(unit.get("level", 1)), 1, 3) - 1]
		var origin: Vector2 = (feet + (pose["offset"] as Vector2)).round()
		var local_point: Vector2 = (point - origin).rotated(-float(pose["angle"])) / scale
		if art.bounds_for(texture, key, body["anchor"]).grow(3.0 / scale).has_point(local_point):
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
		signature += str(state.get("combat", {}).get("result", {})) + ":" + str(result_view_team) + ":" + str(result_sort_column) + ":" + str(result_sort_descending) + ":" + str(boss_result_view_mode)
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
		var combat_res: Dictionary = state.get("combat", {}).get("result", {})
		var is_boss: bool = bool(state.get("is_boss_round", false)) or int(state.get("round", 0)) == 4
		var winner: int = int(combat_res.get("winner", -1)) if is_boss else (int(state.get("match_winner", -1)) if phase == "match_over" else int(combat_res.get("winner", -1)))
		if is_boss and boss_result_view_mode == "rewards":
			_render_boss_round_result(overlay, winner, phase)
			return
		var heading: String = "EMPATE" if winner < 0 else ("VOCÊ VENCEU" if winner == 0 else "BOT VENCEU")
		result_label.text = heading + (" A PARTIDA" if phase == "match_over" else " A RODADA")
		var heading_label: Label = _label(overlay, result_label.text, Rect2(0, 6, 600, 26), 24, GOLD if winner == 0 else (TEAM_COLORS[1] if winner == 1 else Kit.INK), HORIZONTAL_ALIGNMENT_CENTER)
		heading_label.name = "ResultHeading"
		var reason: String = {"elimination": "por eliminação", "survivors": "por sobreviventes", "damage": "por dano causado", "draw": "sem perda de vida"}.get(str(combat_res.get("reason", "")), "")
		_label(overlay, reason, Rect2(0, 32, 600, 16), 12, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

		# Alternância de time para comparação do desempenho
		var team_tabs: Array = [["MEU TIME", 0, TEAM_COLORS[0]], ["BOT INIMIGO", 1, TEAM_COLORS[1]]]
		for tab_info: Array in team_tabs:
			var tab_title: String = tab_info[0]
			var t_id: int = tab_info[1]
			var t_color: Color = tab_info[2]
			var is_cur_team: bool = (result_view_team == t_id)
			var tab_x: float = 150.0 if t_id == 0 else 310.0
			var tab_btn: Button = _button(overlay, tab_title, Rect2(tab_x, 50, 140, 22), func() -> void:
				result_view_team = t_id
				overlay_signature = ""
				_refresh_overlay(_phase()))
			tab_btn.add_theme_font_size_override("font_size", 11)
			var sb: StyleBoxFlat = (tab_btn.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
			if is_cur_team:
				sb.border_color = t_color
				sb.set_border_width_all(2)
				sb.bg_color = Color(t_color, 0.25)
				tab_btn.add_theme_color_override("font_color", t_color)
			else:
				tab_btn.add_theme_color_override("font_color", Kit.MUTED)
			tab_btn.add_theme_stylebox_override("normal", sb)

		# Colunas com botões clicáveis para ordenar
		var cols: Array = [
			["HERÓI", "hero", 86.0, 120.0, HORIZONTAL_ALIGNMENT_LEFT],
			["DANO", "damage", 252.0, 100.0, HORIZONTAL_ALIGNMENT_LEFT],
			["CURA", "healing", 392.0, 80.0, HORIZONTAL_ALIGNMENT_LEFT],
			["ESCUDO", "shield", 482.0, 80.0, HORIZONTAL_ALIGNMENT_LEFT],
		]
		for col_data: Array in cols:
			var c_label: String = col_data[0]
			var c_key: String = col_data[1]
			var c_x: float = col_data[2]
			var c_w: float = col_data[3]
			var c_align: HorizontalAlignment = col_data[4]
			var indicator: String = ""
			if result_sort_column == c_key:
				indicator = " ▼" if result_sort_descending else " ▲"
			var col_btn: Button = _button(overlay, c_label + indicator, Rect2(c_x, 76, c_w, 22), func() -> void:
				if result_sort_column == c_key:
					result_sort_descending = not result_sort_descending
				else:
					result_sort_column = c_key
					result_sort_descending = true
				overlay_signature = ""
				_refresh_overlay(_phase()))
			col_btn.alignment = c_align
			col_btn.flat = true
			col_btn.add_theme_font_size_override("font_size", 12)
			if result_sort_column == c_key:
				col_btn.add_theme_color_override("font_color", GOLD)
			else:
				col_btn.add_theme_color_override("font_color", TEAM_COLORS[0])

		# Filtragem e ordenação dos dados das unidades
		var summaries: Array = combat_res.get("units_summary", [])
		var rows: Array = summaries.filter(func(unit: Dictionary) -> bool: return int(unit.get("team", 1)) == result_view_team and bool(unit.get("active", true)))
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var va: Variant
			var vb: Variant
			match result_sort_column:
				"hero":
					va = str(a.get("name", ""))
					vb = str(b.get("name", ""))
				"damage":
					va = float(a.get("damage_dealt", 0))
					vb = float(b.get("damage_dealt", 0))
				"healing":
					va = float(a.get("healing_done", 0))
					vb = float(b.get("healing_done", 0))
				"shield":
					va = float(a.get("shield_absorbed", 0))
					vb = float(b.get("shield_absorbed", 0))
				_:
					va = float(a.get("damage_dealt", 0))
					vb = float(b.get("damage_dealt", 0))
			if va != vb:
				return (va > vb) if result_sort_descending else (va < vb)
			return int(a.get("id", 0)) < int(b.get("id", 0))
		)

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

		if rows.is_empty():
			_label(table, "Nenhum combatente ativo registrado para este time.", Rect2(0, 40, 578, 24), 14, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			for line: int in range(rows.size()):
				var unit: Dictionary = rows[line]
				var y: float = line * row_height
				_icon_rect(table, art.portrait_for(str(unit.get("key", "")), 26, 24), Rect2(28, y, 44, 40)).modulate = Color.WHITE if bool(unit.get("alive", true)) else Color(0.55, 0.55, 0.55, 0.8)
				_label(table, str(unit.get("name", "Herói")), Rect2(86, y + 2, 150, 22), 16).set_meta("unit_id", int(unit["id"]))
				_stars(table, Vector2(92, y + 32), int(unit.get("level", 1)), 12.0, true)
				var bar: ColorRect = ColorRect.new()
				bar.color = Color(GOLD, 0.75) if result_view_team == 0 else Color(TEAM_COLORS[1], 0.75)
				bar.position = Vector2(252, y + 27)
				bar.size = Vector2(120.0 * float(unit.get("damage_dealt", 0)) / top_damage, 4)
				bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				table.add_child(bar)
				_label(table, "%d" % roundi(float(unit.get("damage_dealt", 0))), Rect2(252, y + 4, 100, 22), 17, GOLD if result_view_team == 0 else TEAM_COLORS[1])
				_label(table, "%d" % roundi(float(unit.get("healing_done", 0))), Rect2(392, y + 4, 80, 22), 17, Color("86eda5"))
				_label(table, "%d" % roundi(float(unit.get("shield_absorbed", 0))), Rect2(482, y + 4, 80, 22), 17, Color("b1daff"))

		next_button = _button(overlay, "NOVA PARTIDA" if phase == "match_over" else "PRÓXIMA RODADA", Rect2(180, 374, 240, 48), _start_match if phase == "match_over" else _next_round)
		next_button.add_theme_font_size_override("font_size", 18)
		if is_boss:
			var rewards_btn: Button = _button(overlay, "VER ESPÓLIOS", Rect2(20, 378, 140, 40), func() -> void:
				boss_result_view_mode = "rewards"
				overlay_signature = ""
				_refresh_overlay(_phase()))
			rewards_btn.add_theme_font_size_override("font_size", 13)


func _render_boss_round_result(parent: Control, winner: int, current_phase: String) -> void:
	var boss_rewards: Array = state.get("boss_rewards", [])
	if winner == 0:
		result_label.text = "VITÓRIA CONTRA O CRIADOR!"
		_label(parent, "ESPÓLIOS DO DESENVOLVEDOR", Rect2(0, 10, 600, 28), 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_label(parent, "O Criador foi derrotado! Suas 3 orbes místicas liberaram os seguintes prêmios:", Rect2(0, 38, 600, 18), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		
		var orb_tex: Texture2D = _boss_icon("loot_orb_brilhante")
		for index: int in range(3):
			var reward: Dictionary = boss_rewards[index] if index < boss_rewards.size() else {"kind": "gold", "amount": 3}
			var kind: String = str(reward.get("kind", "gold"))
			var card_x: float = 24.0 + index * 188.0
			var card_panel: Panel = Panel.new()
			card_panel.position = Vector2(card_x, 66)
			card_panel.size = Vector2(176, 292)
			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = Color(0.08, 0.07, 0.12, 0.95)
			sb.border_color = Color("c084fc") if kind == "item" else (Color("86f6a5") if kind == "life" else GOLD)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(8)
			card_panel.add_theme_stylebox_override("panel", sb)
			parent.add_child(card_panel)
			
			if orb_tex != null:
				_icon_rect(card_panel, orb_tex, Rect2(64, 12, 48, 48))
			
			var icon_tex: Texture2D = null
			var title_str: String = ""
			var title_col: Color = GOLD
			var desc_str: String = ""
			match kind:
				"gold":
					icon_tex = _boss_icon("drop_ouro")
					var amt: int = int(reward.get("amount", 3))
					title_str = "+%d OURO" % amt
					title_col = GOLD
					desc_str = "Moedas reluzentes concedidas pelo Criador. Fortaleça sua economia!"
				"item":
					icon_tex = _boss_icon("drop_item")
					title_str = str(reward.get("name", "ITEM MÍSTICO"))
					title_col = Color("9ec5fe")
					desc_str = str(reward.get("description", "Equipamento especial adicionado à sua mochila de combate!"))
				"life":
					icon_tex = _boss_icon("drop_vida_extra")
					title_str = "+1 CORAÇÃO!"
					title_col = Color("86f6a5")
					desc_str = "Vida extra restaurada! Coração radiante adicionado à sua reserva."
			
			if icon_tex != null:
				_icon_rect(card_panel, icon_tex, Rect2(66, 68, 44, 44))
			
			_label(card_panel, title_str, Rect2(6, 122, 164, 24), 16, title_col, HORIZONTAL_ALIGNMENT_CENTER)
			if kind == "life":
				_label(card_panel, "★ CHANCE RARA 20% ★", Rect2(6, 146, 164, 18), 11, Color("ffd700"), HORIZONTAL_ALIGNMENT_CENTER)
			_label(card_panel, desc_str, Rect2(10, 168, 156, 110), 12, Kit.MUTED if kind != "life" else Color("d4fce2"), HORIZONTAL_ALIGNMENT_CENTER, true)
		
		next_button = _button(parent, "RESGATAR & CONTINUAR", Rect2(160, 372, 280, 46), _start_match if current_phase == "match_over" else _next_round)
		next_button.add_theme_font_size_override("font_size", 18)
		
		var stats_btn: Button = _button(parent, "VER DANO", Rect2(460, 378, 120, 34), func() -> void:
			boss_result_view_mode = "stats"
			overlay_signature = ""
			_refresh_overlay(_phase()))
		stats_btn.add_theme_font_size_override("font_size", 13)
	else:
		result_label.text = "O DESENVOLVEDOR ESCAPOU!"
		_label(parent, "O DESENVOLVEDOR ESCAPOU!", Rect2(0, 12, 600, 28), 24, Color("ec8790"), HORIZONTAL_ALIGNMENT_CENTER)
		_label(parent, "O tempo de combate esgotou ou suas tropas não resistiram...", Rect2(0, 40, 600, 18), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		
		var card: Panel = Panel.new()
		card.position = Vector2(40, 72)
		card.size = Vector2(520, 282)
		var sb_loss: StyleBoxFlat = StyleBoxFlat.new()
		sb_loss.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		sb_loss.border_color = Color(0.35, 0.85, 0.55, 0.8)
		sb_loss.set_border_width_all(2)
		sb_loss.set_corner_radius_all(10)
		card.add_theme_stylebox_override("panel", sb_loss)
		parent.add_child(card)
		
		var boss_tex: Texture2D = art.texture_for("boss_dev", "south", 0.0, "idle", 1)
		if boss_tex != null:
			_icon_rect(card, boss_tex, Rect2(20, 30, 110, 160))
		
		_label(card, "🛡️ NENHUMA VIDA PERDIDA!", Rect2(148, 24, 350, 28), 19, Color("86f6a5"), HORIZONTAL_ALIGNMENT_LEFT)
		var loss_desc: String = "A Batalha contra o Desenvolvedor é um desafio especial PvE de recompensa.\n\nMesmo não vencendo a batalha, suas vidas continuam 100% preservadas e intactas!\n\nVocê apenas deixa de receber os 3 espólios deste round, mas segue firme na partida com toda a sua composição para as próximas rodadas!"
		_label(card, loss_desc, Rect2(148, 62, 350, 190), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
		
		next_button = _button(parent, "CONTINUAR PARTIDA", Rect2(160, 372, 280, 46), _start_match if current_phase == "match_over" else _next_round)
		next_button.add_theme_font_size_override("font_size", 18)
		
		var stats_btn_loss: Button = _button(parent, "VER DANO", Rect2(460, 378, 120, 34), func() -> void:
			boss_result_view_mode = "stats"
			overlay_signature = ""
			_refresh_overlay(_phase()))
		stats_btn_loss.add_theme_font_size_override("font_size", 13)


func _toggle_drawer(mode: String) -> void:
	drawer_mode = "" if drawer_mode == mode else mode
	drawer_signature = ""
	_refresh_drawer()


func _refresh_drawer() -> void:
	drawer.visible = not drawer_mode.is_empty() and not menu_open and _phase() not in ["benefit", "round_result", "match_over"]
	if not drawer.visible:
		return
	var own: Dictionary = state.get("own", {})
	var displayed_groups: Array = _displayed_synergies(_phase(), own)
	var signature: String = drawer_mode + str(displayed_groups) + str(log_lines)
	if signature == drawer_signature:
		return
	drawer_signature = signature
	_clear(drawer)
	_label(drawer, {"log": "EVENTOS DO COMBATE", "synergies": "SINERGIAS DO PROTÓTIPO · TESTE"}.get(drawer_mode, ""), Rect2(16, 12, 440, 24), 17, GOLD)
	_button(drawer, "X", Rect2(474, 8, 36, 32), _toggle_drawer.bind(drawer_mode))
	if drawer_mode == "synergies":
		var groups: Array = displayed_groups
		for index: int in range(groups.size()):
			var group: Dictionary = groups[index]
			var badge: Kit.Badge = Kit.Badge.new(Kit.icon("syn_" + str(group.get("key", ""))), 2 if int(group.get("tier", 0)) > 0 else 0, 40.0)
			badge.position = Vector2(16, 46 + index * 68)
			drawer.add_child(badge)
			_label(drawer, "%s · %d membros" % [str(group.get("name", "Grupo")).replace(" · TESTE", ""), int(group.get("count", 0))], Rect2(66, 46 + index * 68, 430, 22), 16, TEAM_COLORS[0] if int(group.get("tier", 0)) > 0 else GOLD)
			_label(drawer, str(group.get("description", "")), Rect2(66, 68 + index * 68, 430, 20), 14)
		_label(drawer, "Grupos funcionais de combate; as 4 classes ativam bônus crescentes conforme o número de membros em campo.", Rect2(16, 324, 488, 50), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
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


func _toggle_performance_diagnostics() -> void:
	show_performance_diagnostics = not show_performance_diagnostics
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
	character_player.advance(delta)
	var combat: bool = _phase() == "combat"
	var entries: Array[Dictionary] = frame_entries if not frame_entries.is_empty() else _draw_entries()
	for entry: Dictionary in entries:
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
	shake_remaining = maxf(0.0, shake_remaining - delta)
	position = _shake_offset() if combat else Vector2.ZERO
	for effects: Array in [floating, shield_waves, slashes, level_bursts, kit_effects, blast_zones]:
		for index: int in range(effects.size() - 1, -1, -1):
			var attached_key: String = str(effects[index].get("library_key", ""))
			if effects == kit_effects and attached_key in ["cura_01", "laco_01", "zumbi_inspiracao"]:
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


func _character_event_stamp(event: Dictionary, unit_id: int) -> String:
	return "%d:%s:%d:%d" % [int(event.get("round", state.get("round", 1))), str(event.get("type", "")), int(event.get("tick", -1)), unit_id]


## O buff já existe na simulação. Este clip opcional só o apresenta na abertura.
func _start_passive_character_skills(event: Dictionary) -> void:
	if _phase() != "combat":
		return
	var units: Array = state.get("combat", {}).get("units", [])
	for unit: Dictionary in units:
		if unit.get("key", "") != "zumbi" or not bool(unit.get("active", false)) or not bool(unit.get("alive", false)):
			continue
		var unit_id: int = int(unit["id"])
		var from: Vector2 = Board.ground(_cell(unit.get("cell", [])))
		var nearest: Dictionary = {}
		var nearest_distance: float = INF
		for enemy: Dictionary in units:
			if int(enemy.get("team", -1)) == int(unit.get("team", -1)) or not bool(enemy.get("active", false)) or not bool(enemy.get("alive", false)):
				continue
			var distance: float = from.distance_squared_to(Board.ground(_cell(enemy.get("cell", []))))
			if distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
		var direction: String = str(visual_directions.get(unit_id, "south"))
		if not nearest.is_empty():
			direction = art.direction_for(Board.facing_vector(from, Board.ground(_cell(nearest.get("cell", [])))), direction)
		# O gesto de liderança pode virar para a plateia: não é um golpe mirado.
		# Usa somente o clip leste existente enquanto outras vistas são produzidas.
		if not character_bank.has_animation("zumbi", "skill", direction) and character_bank.has_animation("zumbi", "skill", "east"):
			direction = "east"
		character_player.play_action(unit_id, "zumbi", "skill", direction, _character_event_stamp(event, unit_id))
		_spawn_zumbi_inspiration(unit, units, _character_event_stamp(event, unit_id))


## O buff de Zumbi é global para os ativos do próprio time, sem raio adicional.
func _spawn_zumbi_inspiration(source: Dictionary, units: Array, stamp: String) -> void:
	if passive_character_stamps.has(stamp):
		return
	passive_character_stamps[stamp] = true
	if not vfx.has_effect("zumbi_inspiracao"):
		return
	var duration: float = vfx.duration("zumbi_inspiracao")
	for target: Dictionary in units:
		if int(target.get("team", -1)) != int(source.get("team", -1)) or not bool(target.get("active", false)) or not bool(target.get("alive", false)):
			continue
		var point: Vector2 = Board.project(_ground_of(target))
		kit_effects.append({"kind": "inspiration", "library_key": "zumbi_inspiracao", "source_id": int(source["id"]), "target_id": int(target["id"]),
			"from": point, "position": point, "destination": point, "life": duration, "duration": duration, "critical": false,
			"angle": 0.0, "scale": LEVEL_SCALE[clampi(int(target.get("level", 1)), 1, 3) - 1], "depth": "front"})
	while kit_effects.size() > 40:
		kit_effects.pop_front()


func _consume_events() -> void:
	if not is_online_match:
		state = session.snapshot_for_team(0) # Eventos usam a posição atual revelada, sem um quadro de atraso.
		for event: Dictionary in session.drain_events():
			_process_game_event(event)


func _process_game_event(event: Dictionary) -> void:
	var kind: String = str(event.get("type", ""))
	if kind in ["item_bought", "items_fused", "capacity_upgraded", "hero_recruited"]:
		audio.play_cue("purchase")
	elif kind == "hero_upgraded":
		var level_changed: bool = bool(event.get("level_changed", true))
		audio.play_cue("win" if level_changed else "purchase")
		var upgraded: Dictionary = _unit_by_id(int(event.get("unit_id", -1)))
		if not upgraded.is_empty() and level_changed:
			var level: int = int(event.get("level", 2))
			var ground_point: Vector2 = _ground_of(upgraded)
			level_bursts.append({"ground": ground_point, "life": 1.1, "duration": 1.1, "level": level})
			floating.append({"text": "NÍVEL %d!" % level, "position": Board.project(ground_point) + Vector2(-30, -70 - 10 * level), "color": LEVEL_COLORS[level - 1], "life": 1.3, "size": 21})
	elif kind == "combat_started":
		audio.play_cue("start")
		_start_passive_character_skills(event)
	elif kind == "round_finished":
		character_player.clear()
		passive_character_stamps.clear()
		audio.play_cue("win" if int(event.get("winner", -1)) == 0 else "lose")
	elif kind == "preparation_started":
		character_player.clear()
		passive_character_stamps.clear()
	elif kind in ["heal", "dance_shield"] and visual_time - last_heal_sound > 0.25:
		audio.play_cue("heal")
		last_heal_sound = visual_time
	var source: Dictionary = _unit_by_id(int(event.get("source_id", -1)))
	var target: Dictionary = _unit_by_id(int(event.get("target_id", -1)))
	_spawn_kit_feedback(event, source, target)
	if kind == "attack" and not source.is_empty() and not target.is_empty():
		var from: Vector2 = Board.ground(_cell(source.get("cell", [])))
		var to: Vector2 = Board.ground(_cell(target.get("cell", [])))
		var lunge: Vector2 = Board.project(to) - Board.project(from)
		visual_attacks[int(source["id"])] = {"remaining": 0.22, "duration": 0.22, "direction": lunge.normalized() if lunge.length() > 0.1 else Vector2.ZERO}
		if str(source.get("key", "")) != "michael":
			var direction: String = art.direction_for(Board.facing_vector(from, to), str(visual_directions.get(int(source["id"]), "south")))
			character_player.play_action(int(source["id"]), str(source.get("key", "")), "attack", direction, _character_event_stamp(event, int(source["id"])))
	if kind == "dance_shield" and not source.is_empty():
		shield_waves.append({"ground": visual_ground.get(int(source["id"]), Board.ground(_cell(source.get("cell", [])))), "life": 0.9, "duration": 0.9})
		if int(source["id"]) == selected_id:
			floating.append({"text": "ESCUDO %d" % roundi(float(event.get("amount", 0))), "position": _head_of(source) + Vector2(-30, -6), "color": GOLD, "life": 1.0, "size": 15})
	if kind == "boss_cast" and not source.is_empty():
		visual_attacks[int(source["id"])] = {"remaining": 0.55, "duration": 0.55, "direction": Vector2.DOWN}
		var spell_name: String = str(event.get("spell", ""))
		var spell_label: String = "FURACÃO DE FOGO!" if spell_name == "fire_tornado" else ("FOGO VERMELHO!" if spell_name == "red_fire" else ("FOGO ROXO!" if spell_name == "purple_fire" else "CONJURAÇÃO!"))
		var spell_col: Color = Color("ff3322") if spell_name == "red_fire" else (Color("da70d6") if spell_name == "purple_fire" else Color("ff8e36"))
		floating.append({"text": spell_label, "position": _head_of(source) + Vector2(-30, -20), "color": spell_col, "life": 1.2, "duration": 1.2, "size": 17, "critical": true})
		if spell_name in ["red_fire", "purple_fire"] and event.has("from") and event.has("to"):
			var p_from: Vector2 = Board.project(Board.ground(_cell(event["from"]))) + Vector2(0, -35)
			var p_to: Vector2 = Board.project(Board.ground(_cell(event["to"])))
			kit_effects.append({
				"kind": "boss_fire_projectile",
				"spell": spell_name,
				"from": p_from,
				"position": p_from,
				"destination": p_to,
				"life": 0.32,
				"duration": 0.32,
				"critical": true
			})
	if kind == "red_fire_explosion" and event.has("center"):
		shake_remaining = 0.24
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 1)), "life": 0.75, "duration": 0.75, "color_primary": Color(1.0, 0.18, 0.08, 0.48), "color_border": Color(1.0, 0.55, 0.2, 0.95)})
		kit_effects.append({"kind": "red_explosion", "position": Board.project(Board.ground(_cell(event["center"]))), "life": 0.65, "duration": 0.65, "critical": false})
	if kind == "purple_fire_explosion" and event.has("center"):
		shake_remaining = 0.22
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 1)), "life": 0.75, "duration": 0.75, "color_primary": Color(0.68, 0.2, 0.95, 0.45), "color_border": Color(0.9, 0.55, 1.0, 0.9)})
		kit_effects.append({"kind": "purple_explosion", "position": Board.project(Board.ground(_cell(event["center"]))), "life": 0.65, "duration": 0.65, "critical": false})
	if kind == "fire_tornado" and event.has("center"):
		shake_remaining = 0.28
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 1)), "life": 1.05, "duration": 1.05, "color_primary": Color(1.0, 0.35, 0.1, 0.45), "color_border": Color(1.0, 0.75, 0.2, 0.9)})
		kit_effects.append({"kind": "fire_tornado", "position": Board.project(Board.ground(_cell(event["center"]))), "life": 0.95, "duration": 0.95, "critical": false})
	if kind == "unit_displaced":
		var victim: Dictionary = _unit_by_id(int(event.get("unit_id", -1)))
		if not victim.is_empty():
			floating.append({"text": "ARREMESSADO!", "position": _head_of(victim) + Vector2(-22, -8), "color": Color("ff9944"), "life": 0.9, "duration": 0.9, "size": 13})
			visual_pulls[int(victim["id"])] = {"from": Board.ground(_cell(event.get("from", []))), "to": Board.ground(_cell(event.get("to", []))), "remaining": 0.35, "duration": 0.35}
	if kind == "boss_summon" and event.has("cell"):
		kit_effects.append({"kind": "boss_summon", "position": Board.project(Board.ground(_cell(event["cell"]))) + Vector2(0, -10), "life": 0.85, "duration": 0.85, "critical": false})
		floating.append({"text": "INVOCAÇÃO!", "position": Board.project(Board.ground(_cell(event["cell"]))) + Vector2(-20, -35), "color": Color("b870ff"), "life": 1.1, "duration": 1.1, "size": 15})
	if kind in ["hit", "execute"] and not target.is_empty() and source.get("key", "") not in ["caramelo", "zumbi"]:
		slashes.append({"position": _head_of(target) + Vector2(0, 24), "life": 0.2, "critical": bool(event.get("critical", false)), "seed": randf() * TAU})
		visual_hits[int(target["id"])] = 0.12
	if kind in ["ball_hit", "rocket_hit", "mini_rocket_hit", "splash", "smoke_hit", "lasso_hit", "purple_fire_hit", "red_fire_hit", "fire_tornado_hit"] and not target.is_empty():
		visual_hits[int(target["id"])] = 0.12
	if kind in ["hit", "execute"] and not target.is_empty():
		visual_hits[int(target["id"])] = 0.12
	if kind == "death" and not target.is_empty():
		visual_deaths[int(target["id"])] = 0.6
	if kind in ["hit", "ball_hit", "bleed", "execute", "heal", "rocket_hit", "mini_rocket_hit", "splash", "smoke_hit", "smoke", "lasso_hit", "purple_fire_hit", "red_fire_hit", "fire_tornado_hit"] and not target.is_empty():
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
	if kind == "explosion" and event.has("cell"):
		# Mostra exatamente os hexágonos do raio enviado pela simulação, sem decidir quem é atingido.
		blast_zones.append({"cell": event["cell"], "radius": int(event.get("radius", 1)), "life": 0.9, "duration": 0.9})
		while blast_zones.size() > 8:
			blast_zones.pop_front()
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
		if bool(event.get("critical", false)) and vfx.has_effect("zumbi_estocada_critica"):
			library_key = "zumbi_estocada_critica"
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
	elif kind in ["mini_rocket_hit", "mini_rocket_impact"] and not target.is_empty():
		effect_kind = "splash_burst"
		if vfx.has_effect("estilhaco_01"):
			library_key = "estilhaco_01"
		target_point = Board.project(_ground_of(target))
		scale = Board.scale_at(_ground_of(target).y) * 0.7
	elif kind == "rocket_hit" and ROCKET_BLASTS.any(func(blast_key: String) -> bool: return vfx.has_effect(blast_key)) and not target.is_empty():
		effect_kind = "explosion"
		for blast_key: String in ROCKET_BLASTS:
			if vfx.has_effect(blast_key):
				library_key = blast_key
				break
		if library_key != "foguete_01":
			# As explosões novas nascem no chão do alvo e acompanham a perspectiva da área real.
			target_point = Board.project(_ground_of(target))
			scale = Board.scale_at(_ground_of(target).y)
		shake_remaining = SHAKE_DURATION * 1.5 if bool(event.get("is_super", false)) else SHAKE_DURATION
	elif kind == "splash" and vfx.has_effect("estilhaco_01") and not target.is_empty():
		# Cada inimigo vizinho atingido pela área ganha o próprio estouro, preso ao chão dele.
		effect_kind = "splash_burst"
		library_key = "estilhaco_01"
		target_point = Board.project(_ground_of(target))
		scale = Board.scale_at(_ground_of(target).y)
	elif kind == "explosion" and not ROCKET_BLASTS.any(func(blast_key: String) -> bool: return vfx.has_effect(blast_key)):
		effect_kind = "explosion"
		duration = 0.48
		if event.has("cell"):
			target_point = Board.project(Board.ground(_cell(event["cell"])))
	elif kind == "smoke_cloud" and not vfx.has_effect("fumaca_01") and not vfx.has_effect("fumaca_02"):
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
	kit_effects.append({"kind": effect_kind, "source_id": int(source.get("id", -1)), "target_id": int(target.get("id", -1)), "from": source_point, "position": target_point, "destination": destination, "life": duration, "duration": duration, "critical": bool(event.get("critical", false)) or kind == "execute", "library_key": library_key, "angle": angle, "scale": scale, "depth": "behind" if library_key in ["foguete_01", "explosao_02"] else "front", "native_knot": kind == "lasso" and vfx.has_effect("laco_01")})
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
	if key in ["cura_01", "laco_01", "zumbi_inspiracao"]:
		var target: Dictionary = _unit_by_id(int(effect.get("target_id", -1)))
		if target.is_empty() or not bool(target.get("active", false)) or not bool(target.get("alive", false)):
			return {}
		if key == "laco_01" and (_phase() != "combat" or float(target.get("stun_remaining", 0)) <= 0.0):
			return {}
		point = Board.project(_ground_of(target))
		if key != "zumbi_inspiracao":
			point += Vector2(0, (-18.0 if key == "cura_01" else -21.0) * scale)
	data["position"] = point.round()
	data["angle"] = float(effect.get("angle", 0.0))
	data["scale"] = scale
	if key == "explosao_03":
		# A explosão grande passa na frente dos corpos; um pouco translúcida para não esconder quem levou o golpe.
		data["modulate"] = Color(1, 1, 1, 0.88)
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
	var key: String = "fumaca_02" if vfx.has_effect("fumaca_02") else "fumaca_01"
	var data: Dictionary = vfx.frame_data(key, elapsed)
	if not data.is_empty():
		var cell: Vector2i = _cell(zone.get("cell", []))
		data["position"] = Board.project(Board.ground(cell)).round()
		data["angle"] = 0.0
		var z_rad: int = int(zone.get("radius", 1))
		var scale_boost: float = 1.0 + float(z_rad - 1) * 0.45
		data["scale"] = (Board.cell_scale(cell) * scale_boost) if key == "fumaca_02" else (2.0 * scale_boost)
		if key == "fumaca_02":
			data["modulate"] = Color(1, 1, 1, 0.85)
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


func _draw_vfx_frame(canvas: CanvasItem, data: Dictionary) -> void:
	if data.is_empty():
		return
	var scale: float = float(data.get("scale", 1.0))
	canvas.draw_set_transform(data["position"], float(data.get("angle", 0.0)), Vector2(scale, scale))
	canvas.draw_texture_rect_region(data["texture"], Rect2(data["offset"], data["size"]), data["region"], data.get("modulate", Color.WHITE))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Deslocamento inteiro e decrescente do mundo durante o tremor; zero fora dele.
func _shake_offset() -> Vector2:
	if shake_remaining <= 0.0:
		return Vector2.ZERO
	var strength: float = SHAKE_PIXELS * shake_remaining / SHAKE_DURATION
	return (Vector2(sin(visual_time * 91.0), cos(visual_time * 73.0)) * strength).round()


## Projéteis do pacote: loop pelo relógio visual, girado na direção do voo (base +x).
func _projectile_vfx_data(key: String, point: Vector2, angle: float) -> Dictionary:
	var data: Dictionary = vfx.frame_data(key, visual_time)
	if not data.is_empty():
		data["position"] = point.round()
		data["angle"] = angle
		data["scale"] = 1.0
	return data


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
			"purple_explosion":
				var b_rad: float = 16.0 + progress * 34.0
				canvas.draw_arc(point, b_rad, 0, TAU, 24, Color(0.85, 0.35, 1.0, alpha * 0.9), 3.5, true)
				canvas.draw_circle(point, maxf(4.0, (1.0 - progress) * 22.0), Color(0.65, 0.15, 0.9, alpha * 0.75))
				var p_tex: Texture2D = boss_vfx_textures.get("explosao_fogo_roxo") as Texture2D
				if p_tex != null:
					var p_sz: Vector2 = p_tex.get_size() * (0.8 + progress * 1.5)
					var p_rot: float = progress * TAU * 2.0
					canvas.draw_set_transform(point, p_rot, Vector2.ONE)
					canvas.draw_texture_rect(p_tex, Rect2(-p_sz * 0.5, p_sz), false, Color(1, 1, 1, alpha * 0.96))
					canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for spk_i: int in range(10):
					var spk_ang: float = TAU * float(spk_i) / 10.0 + progress * 3.5
					var spk_p: Vector2 = point + Vector2(cos(spk_ang), sin(spk_ang)) * (b_rad * 0.92)
					canvas.draw_circle(spk_p, 2.5 * alpha, Color("ffb3ff"))
			"red_explosion":
				var b_rad: float = 18.0 + progress * 36.0
				canvas.draw_arc(point, b_rad, 0, TAU, 24, Color(1.0, 0.28, 0.1, alpha * 0.95), 3.5, true)
				canvas.draw_circle(point, maxf(4.0, (1.0 - progress) * 24.0), Color(0.95, 0.2, 0.05, alpha * 0.8))
				var r_tex: Texture2D = boss_vfx_textures.get("explosao_fogo_vermelho") as Texture2D
				if r_tex != null:
					var r_sz: Vector2 = r_tex.get_size() * (0.8 + progress * 1.5)
					var r_rot: float = -progress * TAU * 2.0
					canvas.draw_set_transform(point, r_rot, Vector2.ONE)
					canvas.draw_texture_rect(r_tex, Rect2(-r_sz * 0.5, r_sz), false, Color(1, 1, 1, alpha * 0.96))
					canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for spk_i: int in range(10):
					var spk_ang: float = TAU * float(spk_i) / 10.0 + progress * 3.5
					var spk_p: Vector2 = point + Vector2(cos(spk_ang), sin(spk_ang)) * (b_rad * 0.92)
					canvas.draw_circle(spk_p, 2.5 * alpha, Color("ffcc44"))
			"boss_fire_projectile":
				var p_cur: Vector2 = (effect.get("from", point) as Vector2).lerp(effect.get("destination", point) as Vector2, progress)
				var is_red: bool = str(effect.get("spell", "red_fire")) == "red_fire"
				var proj_tex: Texture2D = boss_vfx_textures.get("fogo_vermelho_projetil" if is_red else "fogo_roxo_projetil") as Texture2D
				var flame_col: Color = Color("ff4411") if is_red else Color("da70d6")
				var core_col: Color = Color("ffea77") if is_red else Color("ffffff")
				canvas.draw_line(effect.get("from", point) as Vector2, p_cur, Color(flame_col.r, flame_col.g, flame_col.b, alpha * 0.55), 3.5)
				canvas.draw_circle(p_cur, 8.0 * (1.0 + sin(progress * PI) * 0.5), Color(flame_col.r, flame_col.g, flame_col.b, alpha * 0.65))
				canvas.draw_circle(p_cur, 4.0, Color(core_col.r, core_col.g, core_col.b, alpha * 0.95))
				if proj_tex != null:
					var p_sz: Vector2 = proj_tex.get_size() * 1.3
					var move_vec: Vector2 = (effect.get("destination", point) as Vector2) - (effect.get("from", point) as Vector2)
					var p_rot: float = move_vec.angle()
					canvas.draw_set_transform(p_cur, p_rot, Vector2.ONE)
					canvas.draw_texture_rect(proj_tex, Rect2(-p_sz * 0.5, p_sz), false, Color(1, 1, 1, alpha * 0.98))
					canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"fire_tornado":
				var f_idx: int = int(floor(progress * 14.0)) % 4
				var t_tex: Texture2D = boss_vfx_textures.get("furacao_fogo_frame_%d" % f_idx) as Texture2D
				if t_tex == null:
					t_tex = boss_vfx_textures.get("furacao_fogo") as Texture2D
				if t_tex != null:
					var t_rot: float = sin(progress * TAU * 2.5) * 0.2
					var t_sz: Vector2 = t_tex.get_size() * (1.35 + sin(progress * PI) * 0.2)
					canvas.draw_set_transform(point + Vector2(0, -16), t_rot, Vector2.ONE)
					canvas.draw_texture_rect(t_tex, Rect2(-t_sz * 0.5, t_sz), false, Color(1, 1, 1, alpha * 0.95))
					canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var sw_rad: float = 24.0 + sin(progress * PI) * 14.0
				canvas.draw_arc(point, sw_rad, progress * TAU * 1.5, progress * TAU * 1.5 + PI * 1.4, 18, Color(1.0, 0.55, 0.1, alpha * 0.85), 3.2, true)
				canvas.draw_arc(point, sw_rad * 0.65, -progress * TAU * 1.5, -progress * TAU * 1.5 + PI * 1.2, 14, Color(1.0, 0.8, 0.2, alpha * 0.9), 2.5, true)
			"boss_summon":
				var r_rad: float = 18.0 + sin(progress * PI) * 8.0
				canvas.draw_arc(point + Vector2(0, 10), r_rad, 0, TAU, 20, Color(0.7, 0.2, 0.9, alpha * 0.85), 2.5, true)
				for sm_i: int in range(5):
					var sm_up: Vector2 = point + Vector2((sm_i - 2) * 8.0, 10 - progress * 40.0 - float(sm_i % 3) * 6.0)
					canvas.draw_circle(sm_up, maxf(1.0, 3.0 * (1.0 - progress)), Color(0.5, 0.1, 0.8, alpha * 0.8))


func _event_text(event: Dictionary) -> String:
	var kind: String = str(event.get("type", ""))
	if kind == "hero_upgraded" and not bool(event.get("level_changed", true)):
		return "Cópia incorporada (%d/%d)" % [int(event.get("copies", 0)), _max_copies()]
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
		"revive": "Lula: volta por cima", "summon": "Barbie: invocou Ken", "miss": "Ataque errou", "hero_dismissed": "Herói dispensado; itens devolvidos à bolsa",
		"boss_cast": "Criador: conjuração mágica", "purple_fire_explosion": "Criador: explosão de fogo roxo",
		"red_fire_explosion": "Criador: explosão de fogo vermelho",
		"fire_tornado": "Criador: furacão de fogo", "boss_summon": "Criador: invocou monstro",
		"unit_displaced": "Unidade arremessada", "purple_fire_hit": "Impacto de fogo roxo", "red_fire_hit": "Impacto de fogo vermelho", "fire_tornado_hit": "Dano do furacão",
		"rocket_hit": "Super Foguete acertou", "mini_rocket_hit": "Minifoguete acertou", "super_attack": "Super Ataque disparado", "splash": "Explosão atingiu", "projectile_launched": "Projétil disparado"}
	var text: String = str(names.get(kind, kind.replace("_", " ")))
	var source: Dictionary = _unit_by_id(int(event.get("source_id", -1)))
	if not source.is_empty() and kind in ["hit", "ball_hit", "execute", "death", "bleed", "explosion", "smoke_hit", "lasso_hit", "mini_rocket_hit"]:
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
	var signature: String = "%s_%s_%s_%d_%s_%d_%s_%s_%s" % [
		lobby_subview, lobby_hero_synergy_filter, lobby_selected_hero_key,
		lobby_preview_level, lobby_preview_mode, target_fps, str(eco_mode), str(audio.enabled), str(show_performance_diagnostics)
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
		"matchmaking":
			_refresh_lobby_matchmaking()


func _refresh_lobby_main() -> void:
	# Título e cabeçalho com arte tipográfica
	var title_panel: Panel = _panel(lobby_root, Rect2(36, 28, 620, 108), 0.76, 12)
	_label(title_panel, "CLASH OF ERAS", Rect2(20, 10, 580, 52), 46, GOLD)
	_label(title_panel, "ARENA DE HERÓIS · AUTO-BATTLER TÁTICO", Rect2(22, 60, 580, 22), 15, Color("e0d8b0"))
	_label(title_panel, "12 Heróis · Sinergias TFT · Cópias sobem nível (★1 → ★2 → ★3)", Rect2(22, 82, 580, 18), 12, Kit.MUTED)

	# Pílula de Otimização & Desempenho
	var badge_panel: Panel = _panel(lobby_root, Rect2(720, 16, 190, 38), 0.82, 19)
	lobby_performance_label = _label(badge_panel, "MEDINDO FPS…", Rect2(8, 8, 174, 22), 13, Color("86eda5"), HORIZONTAL_ALIGNMENT_CENTER)

	# Botão de Tela Cheia (F11 / Mobile Fullscreen)
	fullscreen_button = _button(lobby_root, "⛶ TELA CHEIA", Rect2(924, 16, 166, 38), _toggle_fullscreen)
	fullscreen_button.add_theme_font_size_override("font_size", 13)
	var fs_style: StyleBoxFlat = (fullscreen_button.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	fs_style.border_color = GOLD
	fs_style.set_border_width_all(1)
	fullscreen_button.add_theme_stylebox_override("normal", fs_style)

	# Controle Rápido de Áudio no Topo (preserva contrato smoke.gd: sound_button != null)
	sound_button = _button(lobby_root, "SOM: LIGADO" if audio.enabled else "SOM: DESLIGADO", Rect2(1106, 16, 146, 38), _toggle_sound)
	sound_button.add_theme_font_size_override("font_size", 12)

	# Painel Central com Dicas do Jogo & Sinergias
	var banner: Panel = _panel(lobby_root, Rect2(36, 154, 520, 172), 0.72, 10)
	_label(banner, "✦ SISTEMA DE COMBATE & EVOLUÇÃO ✦", Rect2(18, 14, 484, 24), 16, GOLD)
	var tip_text: String = "• Colete cópias: 2 cópias sobem para ★2; 4 cópias para ★3. A terceira cópia avança o progresso. A raridade do herói não muda.\n• Combine Vanguarda, Atacantes, Atiradores e Apoio para virar a partida.\n• Itens e vagas usam ouro; recrutar e juntar cópias é gratuito."
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

	# Barra Inferior Central: SEU APELIDO / NICKNAME
	var name_box: Panel = _panel(lobby_root, Rect2(582, 616, 408, 72), 0.85, 12)
	var n_box_style: StyleBoxFlat = (name_box.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	n_box_style.border_color = Color("64dcd2")
	n_box_style.set_border_width_all(1)
	name_box.add_theme_stylebox_override("panel", n_box_style)
	_label(name_box, "SEU APELIDO ONLINE:", Rect2(16, 6, 376, 18), 11, Color("64dcd2"))

	player_name_input = LineEdit.new()
	player_name_input.position = Vector2(16, 26)
	player_name_input.size = Vector2(376, 36)
	player_name_input.text = player_name
	player_name_input.placeholder_text = "Digite seu nome..."
	player_name_input.max_length = 16
	player_name_input.add_theme_font_size_override("font_size", 16)
	player_name_input.add_theme_color_override("font_color", Color.WHITE)
	player_name_input.add_theme_color_override("font_placeholder_color", Color("8c92a4"))
	var edit_style: StyleBoxFlat = StyleBoxFlat.new()
	edit_style.bg_color = Color(0.12, 0.14, 0.19, 0.95)
	edit_style.set_corner_radius_all(6)
	edit_style.content_margin_left = 10
	edit_style.content_margin_right = 10
	player_name_input.add_theme_stylebox_override("normal", edit_style)
	player_name_input.add_theme_stylebox_override("focus", edit_style)
	player_name_input.text_changed.connect(func(new_text: String) -> void:
		_save_player_name(new_text)
	)
	name_box.add_child(player_name_input)

	# Barra Inferior Direita: Botão JOGAR com aura roxa
	start_button = _button(lobby_root, "JOGAR", Rect2(1010, 616, 230, 72), _on_play_clicked)
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


func _on_play_clicked() -> void:
	if player_name_input != null and is_instance_valid(player_name_input):
		_save_player_name(player_name_input.text)
	if DisplayServer.get_name() == "headless":
		_start_match()
		return
	_open_matchmaking()


func _open_matchmaking() -> void:
	lobby_subview = "matchmaking"
	lobby_signature = ""
	matchmaking_seconds_left = 20.0
	_refresh()
	online_client.start_matchmaking("", player_name)


func _refresh_lobby_matchmaking() -> void:
	var modal: Panel = _panel(lobby_root, Rect2(330, 150, 620, 420), 0.95, 16)
	_label(modal, "BUSCANDO ADVERSÁRIO ONLINE", Rect2(20, 20, 580, 32), 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal, "Jogando como:  %s" % player_name, Rect2(20, 54, 580, 24), 17, Color("64dcd2"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal, "Partida 1v1 em Tempo Real na Nuvem", Rect2(20, 80, 580, 18), 13, Color("d1d5db"), HORIZONTAL_ALIGNMENT_CENTER)

	queue_countdown_label = _label(modal, "%d s" % ceilf(matchmaking_seconds_left), Rect2(20, 108, 580, 64), 54, Color("86eda5"), HORIZONTAL_ALIGNMENT_CENTER)

	_label(modal, "Procurando outro jogador na fila (20s)...\nPara jogar contra, abra outro navegador com outro nome e clique em JOGAR!\nSe ninguém entrar a tempo, a partida começará contra o Bot local.", Rect2(30, 184, 560, 64), 13, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	# Botão para pular a espera e jogar contra o Bot imediatamente
	var bot_btn: Button = _button(modal, "JOGAR CONTRA BOT AGORA", Rect2(60, 290, 260, 52), func() -> void:
		online_client.cancel_matchmaking()
		is_online_match = false
		opponent_title = "BOT LOCAL"
		_start_match()
	)
	bot_btn.add_theme_font_size_override("font_size", 14)

	# Botão para cancelar e voltar ao menu
	var cancel_btn: Button = _button(modal, "CANCELAR", Rect2(340, 290, 220, 52), func() -> void:
		online_client.cancel_matchmaking()
		lobby_subview = "none"
		lobby_signature = ""
		_refresh()
	)
	cancel_btn.add_theme_font_size_override("font_size", 14)


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
	var diagnostic_button: Button = _button(modal, "DIAGNÓSTICO: %s · F3" % ("ATIVO" if show_performance_diagnostics else "DESATIVADO"), Rect2(280, 444, 408, 44), _toggle_performance_diagnostics)
	diagnostic_button.tooltip_text = "Mostra FPS real, intervalo entre quadros e tempo de rede durante a partida."

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

	# Preview Interativo do Personagem (Sprite animado + escala de nível + aura + demonstração de habilidades)
	var preview_bg: Panel = _panel(detail_panel, Rect2(20, 72, 240, 200), 0.7, 8)

	# Alternador de Modo de Demonstração (Ação no Tabuleiro vs Pose Clássica)
	var btn_action: Button = _button(preview_bg, "▶ AÇÃO", Rect2(6, 6, 110, 24), func() -> void:
		lobby_preview_mode = "action"
		lobby_signature = ""
		_refresh())
	btn_action.add_theme_font_size_override("font_size", 11)
	var btn_pose: Button = _button(preview_bg, "★ POSE", Rect2(124, 6, 110, 24), func() -> void:
		lobby_preview_mode = "pose"
		lobby_signature = ""
		_refresh())
	btn_pose.add_theme_font_size_override("font_size", 11)

	var is_act: bool = (lobby_preview_mode == "action")
	var st_act: StyleBoxFlat = (btn_action.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	var st_pos: StyleBoxFlat = (btn_pose.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	if is_act:
		st_act.border_color = GOLD
		st_act.set_border_width_all(2)
		st_act.bg_color = Color(0.24, 0.18, 0.35, 0.95)
		btn_action.add_theme_color_override("font_color", GOLD)
		btn_pose.add_theme_color_override("font_color", Kit.MUTED)
	else:
		st_pos.border_color = GOLD
		st_pos.set_border_width_all(2)
		st_pos.bg_color = Color(0.24, 0.18, 0.35, 0.95)
		btn_pose.add_theme_color_override("font_color", GOLD)
		btn_action.add_theme_color_override("font_color", Kit.MUTED)
	btn_action.add_theme_stylebox_override("normal", st_act)
	btn_pose.add_theme_stylebox_override("normal", st_pos)

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
	var hp_val: int = roundi(_preview_max_hp(active_spec, lobby_preview_level, mult))
	var atk_val: int = roundi(active_spec.attack_damage * mult)

	_label(stats_panel, "VIDA (HP):", Rect2(14, 10, 120, 20), 13, Kit.MUTED)
	var hp_value_label: Label = _label(stats_panel, "%d" % hp_val, Rect2(110, 8, 80, 22), 17, Color("86eda5"))
	hp_value_label.name = "PreviewHp"

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


func _preview_max_hp(spec: UnitSpec, preview_level: int, multiplier: float) -> float:
	var index: int = clampi(preview_level, 1, 3) - 1
	if index < spec.max_hp_by_level.size():
		return float(spec.max_hp_by_level[index])
	return spec.max_hp * multiplier


func _draw_preview_vfx(canvas: CanvasItem, vfx_key: String, pos: Vector2, elapsed: float, scale_mult: float = 1.0) -> void:
	var data: Dictionary = vfx.frame_data(vfx_key, elapsed)
	if data.is_empty():
		return
	data["position"] = pos
	data["scale"] = scale_mult
	_draw_vfx_frame(canvas, data)


func _draw_preview_mini_rocket(canvas: CanvasItem, pos: Vector2, visual_time: float) -> void:
	canvas.draw_set_transform(pos, 0.0, Vector2(0.7, 0.7))
	canvas.draw_polygon(PackedVector2Array([Vector2(-7, -2), Vector2(3, -2), Vector2(7, 0), Vector2(3, 2), Vector2(-7, 2)]),
		PackedColorArray([Color("e8e8f2"), Color("e8e8f2"), Color("ff3b30"), Color("e8e8f2"), Color("e8e8f2")]))
	canvas.draw_polygon(PackedVector2Array([Vector2(-7, -4), Vector2(-4, -2), Vector2(-7, -1)]), PackedColorArray([Color("1c1c24"), Color("1c1c24"), Color("1c1c24")]))
	canvas.draw_polygon(PackedVector2Array([Vector2(-7, 1), Vector2(-4, 2), Vector2(-7, 4)]), PackedColorArray([Color("1c1c24"), Color("1c1c24"), Color("1c1c24")]))
	var thrust_flicker: float = 0.8 + 0.4 * sin(visual_time * 32.0)
	canvas.draw_polygon(PackedVector2Array([Vector2(-7, -1.5), Vector2(-12 * thrust_flicker, 0), Vector2(-7, 1.5)]),
		PackedColorArray([Color(1.0, 0.8, 0.2), Color(1.0, 0.4, 0.1, 0.85), Color(1.0, 0.8, 0.2)]))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Desenha o charutão aceso do Snoop Dogg (Sprite Fusion charutao_snoop_01 + fumaça ascendente charuto_01).
func _draw_snoop_cigar(canvas: CanvasItem, feet_pos: Vector2, hero_scale: float, direction: String, elapsed: float, tint: Color = Color.WHITE, body_angle: float = 0.0) -> void:
	if not vfx.has_effect("charutao_snoop_01"):
		return
	var flip: float = -1.0 if direction in ["west", "south-west", "north-west"] else 1.0
	var mouth_rel: Vector2 = Vector2(2.0, -40.0)
	match direction:
		"east":
			mouth_rel = Vector2(5.0, -41.0)
		"west":
			mouth_rel = Vector2(-5.0, -41.0)
		"south-east", "north-east":
			mouth_rel = Vector2(4.0, -41.0)
		"south-west", "north-west":
			mouth_rel = Vector2(-4.0, -41.0)
		"north":
			mouth_rel = Vector2(3.0, -41.0)
	var mouth_pos: Vector2 = feet_pos + (mouth_rel * hero_scale).rotated(body_angle)
	var cigar_scale: float = hero_scale * 0.52
	var data: Dictionary = vfx.frame_data("charutao_snoop_01", elapsed)
	if not data.is_empty():
		canvas.draw_set_transform(mouth_pos.round(), body_angle, Vector2(cigar_scale * flip, cigar_scale))
		canvas.draw_texture_rect_region(data["texture"], Rect2(data["offset"], data["size"]), data["region"], tint)
	if vfx.has_effect("charuto_01") and tint.a > 0.6:
		var smoke_data: Dictionary = vfx.frame_data("charuto_01", elapsed)
		if not smoke_data.is_empty():
			var tip_pos: Vector2 = mouth_pos + Vector2(22.0 * flip * cigar_scale, -2.0 * cigar_scale).rotated(body_angle)
			var smoke_scale: float = cigar_scale * 0.72
			canvas.draw_set_transform(tip_pos.round(), 0.0, Vector2(smoke_scale, smoke_scale))
			canvas.draw_texture_rect_region(smoke_data["texture"], Rect2(smoke_data["offset"], smoke_data["size"]), smoke_data["region"], Color(tint.r, tint.g, tint.b, tint.a * 0.62))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Desenha as notas musicais de reggae (verde, ouro e vermelho) do Bob Marley usando notas_bob_01 (Sprite Fusion).
func _draw_bob_musical_notes(canvas: CanvasItem, bob_feet: Vector2, elapsed: float, scale_mult: float = 1.4, base_y: float = -34.0) -> void:
	var base_offsets: Array[Vector2] = [
		Vector2(-18.0, base_y),
		Vector2(16.0, base_y + 4.0),
		Vector2(-1.0, base_y - 8.0)
	]
	if vfx.has_effect("notas_bob_01"):
		# 6 frames a 6 fps: 0=Verde ♪, 1=Ouro ♫, 2=Vermelho ♪, 3=Verde ♫, 4=Ouro ♪, 5=Vermelho ♫
		for n_i: int in range(3):
			var cycle: float = fmod(elapsed * 0.85 + float(n_i) * 0.33, 1.0)
			var rise: float = cycle * 24.0
			var sway: float = sin(elapsed * 4.2 + float(n_i) * 2.1) * 3.5
			var tilt: float = sin(elapsed * 5.0 + float(n_i) * 1.9) * 0.14
			var alpha: float = clampf(sin(cycle * PI) * 1.45, 0.25, 1.0)
			var variant_shift: int = 3 if (int(floor(elapsed * 1.5 + float(n_i) * 0.7)) % 2 == 1) else 0
			var frame_idx: int = n_i + variant_shift
			var frame_time: float = (float(frame_idx) + 0.25) / 6.0
			var data: Dictionary = vfx.frame_data("notas_bob_01", frame_time)
			if not data.is_empty():
				data["position"] = (bob_feet + base_offsets[n_i] + Vector2(sway, -rise)).round()
				data["angle"] = tilt
				data["scale"] = scale_mult
				data["modulate"] = Color(1.0, 1.0, 1.0, alpha)
				_draw_vfx_frame(canvas, data)
		return
	var music_font: Font = ThemeDB.fallback_font
	var note_chars: Array[String] = ["♪", "♫", "♪"]
	var note_cols: Array[Color] = [Color("2ec756"), Color("f4c430"), Color("e63946")]
	for n_i: int in range(3):
		var n_pos: Vector2 = bob_feet + base_offsets[n_i] + Vector2(0.0, -fmod((elapsed + float(n_i) * 0.4) * 22.0, 26.0))
		canvas.draw_string_outline(music_font, n_pos, note_chars[n_i], HORIZONTAL_ALIGNMENT_CENTER, -1, 15, 3, Color(0, 0, 0, 0.75))
		canvas.draw_string(music_font, n_pos, note_chars[n_i], HORIZONTAL_ALIGNMENT_CENTER, -1, 15, note_cols[n_i])


func _draw_arena_cell(canvas: Control, hex_center: Vector2, fill_color: Color, border_color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		hex_center + Vector2(0, -11),
		hex_center + Vector2(22, -5),
		hex_center + Vector2(22, 5),
		hex_center + Vector2(0, 11),
		hex_center + Vector2(-22, 5),
		hex_center + Vector2(-22, -5)
	])
	canvas.draw_colored_polygon(pts, fill_color)
	pts.append(pts[0])
	canvas.draw_polyline(pts, border_color, 1.2, true)


func _draw_hero_preview(canvas: Control) -> void:
	if not specs.has(lobby_selected_hero_key):
		return
	var key: String = lobby_selected_hero_key
	var center: Vector2 = canvas.size * 0.5
	var font: Font = ThemeDB.fallback_font

	if lobby_preview_mode == "pose":
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
		var tex: Texture2D = art.texture_for(key, "south", visual_time, "idle", lobby_preview_level)
		if tex != null:
			var spr_scale: float = 2.4 * LEVEL_SCALE[lobby_preview_level - 1] * art.preview_factor(key)
			var anchor: Vector2 = art.anchor_for(tex, key)
			var origin: Vector2 = feet - anchor * spr_scale
			canvas.draw_texture_rect(tex, Rect2(origin.round(), tex.get_size() * spr_scale), false)
			if key == "snoop":
				_draw_snoop_cigar(canvas, feet, spr_scale, "south", visual_time)
			elif key == "bob_marley":
				_draw_bob_musical_notes(canvas, feet, visual_time, 1.55 * LEVEL_SCALE[lobby_preview_level - 1], -58.0 * LEVEL_SCALE[lobby_preview_level - 1])

		# Estrelas de nível desenhadas sob os pés
		var star_step: float = 18.0
		var star_y: float = feet.y + 14.0
		for s: int in range(lobby_preview_level):
			var sx: float = center.x + (s - (lobby_preview_level - 1) * 0.5) * star_step - 8.0
			var star_tex: Texture2D = Kit.icon("ui_star")
			if star_tex != null:
				canvas.draw_texture_rect(star_tex, Rect2(Vector2(sx, star_y), Vector2(16, 16)), false, LEVEL_COLORS[lobby_preview_level - 1])
		return

	# --- MODO AÇÃO: ARENA REAL DO JOGO EM TEMPO REAL ---
	# Fundo oficial do Coliseu recortado com areia e arquibancadas
	if arena != null:
		var src_rect: Rect2 = Rect2(65, 32, 220, 160)
		canvas.draw_texture_rect_region(arena, Rect2(Vector2.ZERO, canvas.size), src_rect)
		# Vinheta suave para realçar a batalha
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.04, 0.05, 0.08, 0.22))

	# Hexágonos reais da arena projetados na areia
	var hero_y: float = 142.0
	var cell_hero: Vector2 = Vector2(58, hero_y)
	var cell_mid: Vector2 = Vector2(115, hero_y)
	var cell_enemy: Vector2 = Vector2(178, hero_y)

	_draw_arena_cell(canvas, cell_hero, Color(0.18, 0.45, 0.8, 0.18), Color(0.35, 0.65, 0.95, 0.4))
	_draw_arena_cell(canvas, cell_mid, Color(0.9, 0.8, 0.5, 0.12), Color(0.9, 0.8, 0.5, 0.3))
	_draw_arena_cell(canvas, cell_enemy, Color(0.8, 0.2, 0.2, 0.18), Color(0.95, 0.35, 0.35, 0.4))

	# Ciclo de 4.0 segundos de demonstração
	var t: float = fmod(visual_time, 4.0)

	# Combatente inimigo real na arena (sem bonecos de madeira)
	var opp_key: String = "zumbi" if key != "zumbi" else "caramelo"
	var opp_pos: Vector2 = cell_enemy
	var opp_wobble: float = 0.0
	var opp_tint: Color = Color.WHITE
	var combat_msg: String = ""
	var combat_msg_col: Color = GOLD
	var combat_msg_target: String = "opp"

	var hero_pos: Vector2 = cell_hero
	var hero_dir: String = "east"
	var hero_anim_time: float = visual_time
	var hero_clip_state: String = ""
	var hero_clip_elapsed: float = 0.0
	var hero_tag: String = "EM COMBATE"
	var tag_col: Color = GOLD

	# Ken invocado pela Barbie
	var draw_ken: bool = false
	var ken_pos: Vector2 = cell_mid
	var ken_wobble: float = 0.0
	var ken_tint: Color = Color.WHITE

	# --- COMPORTAMENTO DETALHADO POR PERSONAGEM ---
	if key == "michael":
		opp_key = "zumbi"
		if t < 0.8:
			hero_pos = cell_mid + Vector2(-10, 0)
			hero_dir = "east"
			hero_tag = "CONCENTRAÇÃO"
			tag_col = Color("8ecae6")
		elif t < 2.2:
			# MOONWALK REAL NA AREIA DO COLISEU!
			var prog: float = (t - 0.8) / 1.4
			hero_pos = (cell_mid + Vector2(-10, 0)).lerp(cell_hero + Vector2(-8, 0), prog)
			hero_dir = "east"
			hero_tag = "MOONWALK ✦"
			tag_col = Color("86eda5")
			# Rastro sutil de areia dourada
			var dust: PackedVector2Array = _make_ellipse(hero_pos + Vector2(prog * 10.0, 2), 12.0 * (1.0 - prog * 0.4), 4.5, 14)
			canvas.draw_colored_polygon(dust, Color(0.9, 0.8, 0.5, 0.35))
		elif t < 3.2:
			# Pose clássica estática na ponta dos pés
			hero_pos = cell_hero + Vector2(-8, 0)
			hero_dir = "east"
			hero_anim_time = 8.0 / maxf(art.fps, 1.0)
			hero_tag = "ESCUDO DA DANÇA ★"
			tag_col = GOLD
			combat_msg = "+ESCUDO DA DANÇA"
			combat_msg_col = Color("b1daff")
			combat_msg_target = "hero"
			# Onda rúnica expansiva na areia
			var wave_p: float = (t - 2.2) / 1.0
			var ring: PackedVector2Array = _make_ellipse(hero_pos, 16.0 + wave_p * 46.0, 8.0 + wave_p * 23.0, 24)
			ring.append(ring[0])
			canvas.draw_polyline(ring, Color(GOLD, 0.85 * (1.0 - wave_p)), 2.2, true)
			# Bolha real do PixelLab (escudo_danca_01)
			_draw_preview_vfx(canvas, "escudo_danca_01", hero_pos + Vector2(0, 4), visual_time, 1.35)
		else:
			hero_pos = cell_hero + Vector2(-8, 0)
			hero_dir = "east"
			hero_tag = "CURA CONTÍNUA ❤"
			tag_col = Color("86eda5")
			combat_msg = "+CURA"
			combat_msg_col = Color("86eda5")
			combat_msg_target = "hero"
			# Cura real do PixelLab (cura_01)
			_draw_preview_vfx(canvas, "cura_01", hero_pos + Vector2(0, -6), (t - 3.2), 1.25)
			_draw_preview_vfx(canvas, "escudo_danca_01", hero_pos + Vector2(0, 4), visual_time, 1.1)

	elif key == "elon":
		opp_key = "zumbi"
		hero_pos = cell_hero + Vector2(0, sin(visual_time * 7.0) * 3.0)
		hero_dir = "east"
		if t < 0.6:
			hero_tag = "PROPULSÃO A JATO"
			tag_col = Color("8ecae6")
		elif t < 1.0:
			hero_tag = "MINIFOGUETE 1/3 🚀"
			tag_col = Color("ffd166")
			var p1: float = (t - 0.6) / 0.4
			var m1_pos: Vector2 = (cell_hero + Vector2(16, -14)).lerp(opp_pos + Vector2(0, -14), p1)
			_draw_preview_mini_rocket(canvas, m1_pos, visual_time)
			if p1 > 0.75:
				opp_wobble = sin(t * 36.0) * 2.0
				combat_msg = "MINIFOGUETE 1: -52"
				combat_msg_col = Color("ffd166")
		elif t < 1.4:
			hero_tag = "MINIFOGUETE 2/3 🚀"
			tag_col = Color("ffd166")
			var p2: float = (t - 1.0) / 0.4
			var m2_pos: Vector2 = (cell_hero + Vector2(16, -14)).lerp(opp_pos + Vector2(0, -14), p2)
			_draw_preview_mini_rocket(canvas, m2_pos, visual_time)
			if p2 > 0.75:
				opp_wobble = sin(t * 36.0) * 2.0
				combat_msg = "MINIFOGUETE 2: -52"
				combat_msg_col = Color("ffd166")
		elif t < 1.8:
			hero_tag = "MINIFOGUETE 3/3 🚀"
			tag_col = Color("ffd166")
			var p3: float = (t - 1.4) / 0.4
			var m3_pos: Vector2 = (cell_hero + Vector2(16, -14)).lerp(opp_pos + Vector2(0, -14), p3)
			_draw_preview_mini_rocket(canvas, m3_pos, visual_time)
			if p3 > 0.75:
				opp_wobble = sin(t * 36.0) * 2.0
				combat_msg = "MINIFOGUETE 3: -52"
				combat_msg_col = Color("ffd166")
		elif t < 3.2:
			hero_tag = "SUPER ATAQUE: MEGA FOGUETE 💥"
			tag_col = Color("ff4d6d")
			var rkt_p: float = clampf((t - 1.8) / 0.6, 0.0, 1.0)
			var rkt_pos: Vector2 = (cell_hero + Vector2(16, -16)).lerp(opp_pos + Vector2(0, -18), rkt_p)
			if rkt_p < 0.95:
				_draw_preview_vfx(canvas, "foguete_02", rkt_pos, (t - 1.8), 1.5)
			else:
				var blast_t: float = t - 2.4
				_draw_preview_vfx(canvas, "explosao_03", opp_pos + Vector2(0, -14), blast_t, 1.6)
				_draw_preview_vfx(canvas, "estilhaco_01", opp_pos + Vector2(0, -8), blast_t, 1.3)
				# Projeção visual dos 2 quadros penetrando para trás da retaguarda
				var back_area: PackedVector2Array = _make_ellipse(opp_pos + Vector2(28, -6), 34.0, 14.0, 20)
				back_area.append(back_area[0])
				canvas.draw_colored_polygon(back_area, Color(1.0, 0.35, 0.1, 0.3 * (1.0 - (t - 2.4) / 0.8)))
				canvas.draw_polyline(back_area, Color(1.0, 0.65, 0.2, 0.6 * (1.0 - (t - 2.4) / 0.8)), 2.0, true)
				opp_wobble = sin(t * 36.0) * 4.5
				opp_tint = Color("ff7777")
				combat_msg = "SUPER EXPLOSÃO! RETAGUARDA -380 💥"
				combat_msg_col = Color("ff4d6d")
		else:
			hero_tag = "VOO ORBITAL CONCLUÍDO ✨"
			tag_col = Color("86eda5")
			var fly_p: float = (t - 3.2) / 1.0
			hero_pos = cell_hero.lerp(cell_mid + Vector2(25, -12), fly_p)

	elif key == "barbie":
		opp_key = "zumbi"
		hero_pos = cell_hero + Vector2(-8, 0)
		hero_dir = "east"
		draw_ken = (t >= 0.8)
		if t < 0.8:
			hero_tag = "BARBIE COMANDANTE"
			tag_col = Color("f72585")
		elif t < 1.4:
			hero_tag = "INVOCAÇÃO: KEN"
			tag_col = GOLD
			combat_msg = "KEN INVOCADO!"
			combat_msg_col = GOLD
			combat_msg_target = "ken"
			# Brilho de invocação no hexágono do Ken
			var s_ring: PackedVector2Array = _make_ellipse(ken_pos, 18.0, 9.0, 16)
			s_ring.append(s_ring[0])
			canvas.draw_polyline(s_ring, Color(GOLD, 0.9), 2.0, true)
		elif t < 2.4:
			# Ken se coloca à frente e atrai os ataques (Taunt do Guardião Leal)
			hero_tag = "KEN: GUARDIÃO LEAL"
			tag_col = Color("4cc9f0")
			combat_msg = "TAUNT! KEN ABSORVE"
			combat_msg_col = Color("4cc9f0")
			combat_msg_target = "ken"
			ken_wobble = sin(t * 30.0) * 3.0
			ken_tint = Color("ffffaa")
		elif t < 3.4:
			# Demonstração visual do bônus atual enquanto Ken vive.
			hero_tag = "COMANDANTE (+50% DANO)"
			tag_col = Color("f72585")
			combat_msg = "+50% DANO!"
			combat_msg_col = Color("f72585")
			combat_msg_target = "opp"
			opp_wobble = sin(t * 30.0) * 4.0
			opp_tint = Color("ff8888")
			# Aura de comando rosa/dourada na Barbie
			var b_aura: PackedVector2Array = _make_ellipse(hero_pos, 22.0, 11.0, 16)
			b_aura.append(b_aura[0])
			canvas.draw_polyline(b_aura, Color("f72585", 0.85), 2.0, true)
		else:
			hero_tag = "COMANDO VITORIOSO ★"
			tag_col = GOLD

	elif key == "snoop":
		opp_key = "zumbi"
		hero_pos = cell_hero
		hero_dir = "east"
		if t < 0.8:
			hero_tag = "TRANQUILO"
			tag_col = Color("8ecae6")
		elif t < 3.4:
			hero_tag = "FUMAÇA (RAIO 2) ☁"
			tag_col = Color("80ed99")
			# Nuvem real de fumaça ampliada do PixelLab (fumaca_02)
			_draw_preview_vfx(canvas, "fumaca_02", opp_pos + Vector2(0, -12), (t - 0.8), 1.6)
			opp_wobble = sin(t * 12.0) * 1.5
			var s_ring: PackedVector2Array = _make_ellipse(opp_pos + Vector2(0, -4), 48.0, 24.0, 24)
			s_ring.append(s_ring[0])
			canvas.draw_polyline(s_ring, Color(0.5, 0.9, 0.6, 0.45), 1.8, true)
			if fmod(t, 0.8) < 0.4:
				combat_msg = "ERROU! 30% MISS ☁"
				combat_msg_col = Color("b1daff")
				combat_msg_target = "opp"
			else:
				combat_msg = "+25% VELOCIDADE 💨"
				combat_msg_col = Color("80ed99")
				combat_msg_target = "hero"
		else:
			hero_tag = "RELAXANDO"
			tag_col = Color("8ecae6")

	elif key == "neymar":
		opp_key = "zumbi"
		hero_pos = cell_hero
		hero_dir = "east"
		var ball_pos: Vector2 = hero_pos + Vector2(16, -6)
		if t < 0.8:
			hero_tag = "DRIBLE"
			tag_col = Color("8ecae6")
			ball_pos.y += sin(t * 12.0) * 4.0
		elif t < 1.6:
			# 1º impacto no alvo A: 100% de dano
			var p1: float = (t - 0.8) / 0.8
			ball_pos = (hero_pos + Vector2(16, -6)).lerp(opp_pos + Vector2(0, -16), p1)
			hero_tag = "1º IMPACTO: 100% ⚽"
			tag_col = GOLD
			if p1 > 0.8:
				opp_wobble = sin(t * 35.0) * 4.0
				opp_tint = Color("ff9999")
				combat_msg = "100% DANO (-41)"
				combat_msg_col = Color("ffb703")
				combat_msg_target = "opp"
		elif t < 2.5:
			# 2º impacto no alvo B (vizinho): 80% de dano
			var p2: float = (t - 1.6) / 0.9
			ball_pos = (opp_pos + Vector2(0, -16)).lerp(cell_mid + Vector2(0, -50), p2)
			hero_tag = "RICOCHETE: 80% ⚽"
			tag_col = Color("90e0ef")
			if p2 > 0.8:
				combat_msg = "80% DANO (-33)"
				combat_msg_col = Color("90e0ef")
				combat_msg_target = "opp"
		elif t < 3.4:
			# 3º impacto de retorno no alvo A: 50% de dano
			var p3: float = (t - 2.5) / 0.9
			ball_pos = (cell_mid + Vector2(0, -50)).lerp(opp_pos + Vector2(0, -16), p3)
			hero_tag = "RETORNO: 50% ⚽"
			tag_col = Color("ffb703")
			if p3 > 0.8:
				opp_wobble = sin(t * 30.0) * 3.5
				opp_tint = Color("ff7777")
				combat_msg = "50% DANO (-20)"
				combat_msg_col = Color("ffb703")
				combat_msg_target = "opp"
		else:
			hero_tag = "COMEMORAÇÃO ★"
			tag_col = GOLD
			ball_pos = hero_pos + Vector2(16, -6)
		# Bola de futebol na arena
		canvas.draw_circle(ball_pos, 5.0, Color.WHITE)
		canvas.draw_circle(ball_pos, 2.5, Color(0.1, 0.1, 0.1))

	elif key == "caramelo":
		opp_key = "zumbi"
		if t < 0.8:
			hero_pos = cell_hero
			hero_dir = "east"
			hero_tag = "ABANANDO O RABO"
			tag_col = Color("8ecae6")
		elif t < 1.5:
			var dash_p: float = (t - 0.8) / 0.7
			hero_pos = cell_hero.lerp(opp_pos + Vector2(-16, 0), dash_p)
			hero_dir = "east"
			hero_tag = "AVANÇO FEROZ 🐾"
			tag_col = Color("ffb703")
		elif t < 2.5:
			hero_pos = opp_pos + Vector2(-16, sin(t * 25.0) * 2.0)
			hero_dir = "east"
			hero_tag = "MORDIDA CONTÍNUA 🐶"
			tag_col = Color("e63946")
			opp_wobble = sin(t * 30.0) * 4.0
			opp_tint = Color("ff8888")
			combat_msg = "MORDIDA! -140"
			combat_msg_col = Color("ffb703")
		else:
			var ret_p: float = (t - 2.5) / 1.5
			hero_pos = (opp_pos + Vector2(-16, 0)).lerp(cell_hero, ret_p)
			hero_dir = "west"
			hero_tag = "RETORNO ALEGRE"
			tag_col = Color("86eda5")

	elif key == "zumbi" and (character_bank.has_animation(key, "walk", "east") or character_bank.has_animation(key, "attack", "east") or character_bank.has_animation(key, "skill", "east")):
		# Coreografia oficial do Zumbi com os clips aprovados do PixelLab (Skill -> Walk -> Attack)
		if t < 0.9:
			# Gesto imponente de liderança / inspiração (buff passivo de crítico e velocidade)
			hero_clip_state = "skill"
			hero_clip_elapsed = t
			hero_pos = cell_hero
			hero_tag = "INSPIRAÇÃO DA EQUIPE ✦"
			tag_col = GOLD
			combat_msg = "+CRÍTICO & VELOCIDADE! ⚔️"
			combat_msg_col = GOLD
			combat_msg_target = "hero"
			_draw_preview_vfx(canvas, "zumbi_inspiracao", hero_pos + Vector2(0, -18), t, 1.4)
		elif t < 2.2:
			# Caminhada articulada sem pedra avançando pelo Coliseu
			hero_clip_state = "walk"
			hero_clip_elapsed = t - 0.9
			hero_pos = cell_hero.lerp(cell_mid + Vector2(8, 0), (t - 0.9) / 1.3)
			hero_tag = "PASSOS NO COLISEU 🐾"
			tag_col = Color("8ecae6")
		else:
			# Estocada frontal com lança horizontal e impacto crítico no oponente
			hero_clip_state = "attack"
			hero_clip_elapsed = t - 2.2
			hero_pos = cell_mid + Vector2(8, 0)
			hero_tag = "ESTOCADA CRÍTICA ⚡"
			tag_col = Color("ff4d6d")
			if t >= 2.4:
				_draw_preview_vfx(canvas, "zumbi_estocada_critica", opp_pos + Vector2(-10, -10), (t - 2.4), 1.5)
				opp_wobble = sin(t * 35.0) * 4.2
				opp_tint = Color("ff7777")
				combat_msg = "CRÍTICO! 100 ➔ 120 ➔ 140 ⚡"
				combat_msg_col = Color("ffb703")
				combat_msg_target = "opp"

	elif key == "bob_marley":
		opp_key = "zumbi"
		hero_pos = cell_hero
		hero_dir = "east"
		var r_pulse: float = 0.92 + 0.08 * sin(t * 5.0)
		# 3 Anéis de Reggae expandindo (verde, amarelo e vermelho)
		for r_i: int in range(3):
			var r_col: Color = [Color("2ec756"), Color("f4c430"), Color("e63946")][r_i]
			var ring_r: float = (24.0 + float(r_i) * 16.0 + fmod(t * 22.0, 24.0)) * r_pulse
			var r_ell: PackedVector2Array = _make_ellipse(hero_pos + Vector2(0, 4), ring_r, ring_r * 0.52, 28)
			r_ell.append(r_ell[0])
			canvas.draw_polyline(r_ell, Color(r_col, 0.45 - float(r_i) * 0.1), 1.8, true)
		# Notas musicais em pixel art (notas_bob_01) flutuando sobre Bob Marley
		_draw_bob_musical_notes(canvas, hero_pos, visual_time, 1.45 * LEVEL_SCALE[lobby_preview_level - 1], -32.0 * LEVEL_SCALE[lobby_preview_level - 1])
		if t < 1.0:
			hero_tag = "AURA DE PAZ E AMOR ♫"
			tag_col = Color("f4c430")
		elif t < 2.5:
			hero_tag = "RITMO POSITIVO (+30% VEL)"
			tag_col = Color("2ec756")
			combat_msg = "+30% VELOCIDADE ♪"
			combat_msg_col = Color("2ec756")
			combat_msg_target = "hero"
		else:
			hero_tag = "VIBRAÇÃO TRANQUILA (-30% LENTO)"
			tag_col = Color("e63946")
			combat_msg = "-30% LENTO ♫"
			combat_msg_col = Color("e63946")
			combat_msg_target = "opp"
			opp_wobble = sin(t * 8.0) * 1.5
	else:
		# Padrão para os demais heróis (Obama, Ken, Lula, Rapunzel, Cleopatra, Julio Cesar, Einstein, Napoleao)
		opp_key = "caramelo" if key == "zumbi" else "zumbi"
		var spec: UnitSpec = specs[key]
		var is_ranged: bool = spec.attack_range > 1
		hero_pos = cell_hero
		hero_dir = "east"
		if t < 0.9:
			hero_tag = "POSTURA DE COMBATE"
			tag_col = Color("8ecae6")
		elif t < 2.2:
			if is_ranged:
				hero_tag = "DISPARO TÁTICO ✦"
				tag_col = GOLD
				var proj_p: float = (t - 0.9) / 1.3
				var p_pos: Vector2 = hero_pos.lerp(opp_pos + Vector2(0, -16), proj_p)
				canvas.draw_circle(p_pos, 4.5, GOLD)
				canvas.draw_line(p_pos - Vector2(8, 0), p_pos, Color("ffb703"), 2.0)
				if proj_p > 0.8:
					opp_wobble = sin(t * 30.0) * 3.5
					opp_tint = Color("ff9999")
					combat_msg = "-%d DANO" % roundi(spec.attack_damage)
					combat_msg_col = GOLD
			else:
				var strike_p: float = sin(((t - 0.9) / 1.3) * PI)
				hero_pos = cell_hero.lerp(opp_pos + Vector2(-22, 0), strike_p)
				hero_tag = "GOLPE FÍSICO ⚔"
				tag_col = Color("ffb703")
				if strike_p > 0.7:
					opp_wobble = sin(t * 30.0) * 3.5
					opp_tint = Color("ff9999")
					combat_msg = "-%d CRÍTICO!" % roundi(spec.attack_damage * 1.5)
					combat_msg_col = Color("ffb703")
		else:
			hero_tag = "PRONTO PARA AÇÃO"
			tag_col = Color("86eda5")

	# --- DESENHO DO OPONENTE REAL NO COLISEU ---
	var final_opp: Vector2 = opp_pos + Vector2(opp_wobble, 0)
	var opp_shadow: PackedVector2Array = _make_ellipse(final_opp, 16.0, 7.0, 16)
	canvas.draw_colored_polygon(opp_shadow, Color(0, 0, 0, 0.45))
	var opp_tex: Texture2D = art.texture_for(opp_key, "west", visual_time, "idle", 1)
	if opp_tex != null:
		var opp_scale: float = 2.0 * art.preview_factor(opp_key)
		var opp_anchor: Vector2 = art.anchor_for(opp_tex, opp_key)
		var opp_origin: Vector2 = final_opp - opp_anchor * opp_scale
		canvas.draw_texture_rect(opp_tex, Rect2(opp_origin.round(), opp_tex.get_size() * opp_scale), false, opp_tint)

	# --- DESENHO DO KEN INVOCADO (CASO BARBIE) ---
	if draw_ken:
		var final_ken: Vector2 = ken_pos + Vector2(ken_wobble, 0)
		var ken_shadow: PackedVector2Array = _make_ellipse(final_ken, 16.0, 7.0, 16)
		canvas.draw_colored_polygon(ken_shadow, Color(0, 0, 0, 0.45))
		var ken_tex: Texture2D = art.texture_for("ken", "east", visual_time, "idle", 1)
		if ken_tex != null:
			var k_scale: float = 2.0 * art.preview_factor("ken")
			var k_anchor: Vector2 = art.anchor_for(ken_tex, "ken")
			var k_origin: Vector2 = final_ken - k_anchor * k_scale
			canvas.draw_texture_rect(ken_tex, Rect2(k_origin.round(), ken_tex.get_size() * k_scale), false, ken_tint)

	# --- DESENHO DO HERÓI PRINCIPAL ---
	if lobby_preview_mode == "pose" and lobby_preview_level > 1:
		hero_pos.y += 24.0 * (LEVEL_SCALE[lobby_preview_level - 1] - 1.0)
	var spr_scale: float = 2.2 * LEVEL_SCALE[lobby_preview_level - 1] * art.preview_factor(key)
	var hero_shadow: PackedVector2Array = _make_ellipse(hero_pos, 16.0 * LEVEL_SCALE[lobby_preview_level - 1], 7.0, 16)
	canvas.draw_colored_polygon(hero_shadow, Color(0, 0, 0, 0.45))

	# Aura mística do Nível 3
	if lobby_preview_level == 3:
		var pulse: float = 0.5 + 0.5 * sin(visual_time * 5.0)
		var aura_pts: PackedVector2Array = _make_ellipse(hero_pos, 28.0 + 4.0 * pulse, 14.0 + 2.0 * pulse, 24)
		aura_pts.append(aura_pts[0])
		canvas.draw_polyline(aura_pts, Color(GOLD, 0.7 * pulse), 2.0, true)

	var tex: Texture2D = art.texture_for(key, hero_dir, hero_anim_time, "idle", lobby_preview_level)
	var clip: Dictionary = {}
	if not hero_clip_state.is_empty() and (hero_clip_state == "walk" or hero_clip_elapsed < character_bank.clip_duration(key, hero_clip_state, hero_dir)):
		clip = character_bank.frame_data(key, hero_clip_state, hero_dir, hero_clip_elapsed)
		if not clip.is_empty():
			tex = clip["texture"] as Texture2D
	if tex != null:
		var anchor: Vector2 = clip["anchor"] if not clip.is_empty() else art.anchor_for(tex, key)
		if not clip.is_empty():
			art.register_animation_frame(tex, anchor)
		var origin: Vector2 = hero_pos - anchor * spr_scale
		canvas.draw_texture_rect(tex, Rect2(origin.round(), tex.get_size() * spr_scale), false)
		if key == "snoop":
			_draw_snoop_cigar(canvas, hero_pos, spr_scale, hero_dir, visual_time)

	# Estrelas de Nível desenhadas na base do herói
	var star_step: float = 14.0
	var star_y: float = hero_pos.y + 6.0
	for s: int in range(lobby_preview_level):
		var sx: float = hero_pos.x + (s - (lobby_preview_level - 1) * 0.5) * star_step - 6.0
		var star_tex: Texture2D = Kit.icon("ui_star")
		if star_tex != null:
			canvas.draw_texture_rect(star_tex, Rect2(Vector2(sx, star_y), Vector2(12, 12)), false, LEVEL_COLORS[lobby_preview_level - 1])

	# Etiqueta / Badge de Ação no topo da mini-arena
	var badge_w: float = 180.0
	var badge_h: float = 20.0
	var badge_rect: Rect2 = Rect2(center.x - badge_w * 0.5, 34.0, badge_w, badge_h)
	canvas.draw_rect(badge_rect, Color(0.06, 0.08, 0.12, 0.88))
	canvas.draw_rect(badge_rect, Color(tag_col, 0.65), false, 1.0)
	canvas.draw_string(font, Vector2(center.x - badge_w * 0.5, 48.0), hero_tag, HORIZONTAL_ALIGNMENT_CENTER, int(badge_w), 11, tag_col)

	# Mensagem de combate flutuante com moldura elegante sobre o combatente
	if not combat_msg.is_empty():
		var msg_anchor: Vector2 = final_opp
		if combat_msg_target == "hero":
			msg_anchor = hero_pos
		elif combat_msg_target == "ken":
			msg_anchor = ken_pos + Vector2(ken_wobble, 0)
		var txt_size: Vector2 = font.get_string_size(combat_msg, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		var pill_rect: Rect2 = Rect2(msg_anchor.x - txt_size.x * 0.5 - 5, msg_anchor.y - 48, txt_size.x + 10, 15)
		canvas.draw_rect(pill_rect, Color(0.04, 0.06, 0.09, 0.88))
		canvas.draw_rect(pill_rect, Color(combat_msg_col, 0.6), false, 1.0)
		canvas.draw_string(font, Vector2(msg_anchor.x - txt_size.x * 0.5, msg_anchor.y - 36), combat_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, combat_msg_col)


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


## Desenho e seleção consultam o mesmo quadro e a mesma âncora, sem avançar tempo.
func _body_frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var key: String = str(unit.get("key", ""))
	var level: int = clampi(int(unit.get("level", 1)), 1, 3)
	var direction: String = str(visual_directions.get(int(unit.get("id", -1)), "south"))
	var texture: Texture2D = art.texture_for(key, direction, float(pose["time"]), "idle", level)
	var anchor: Vector2 = art.anchor_for(texture, key) if texture != null else Vector2.ZERO
	var height: float = art.height_for(texture) if texture != null else 46.0
	var animation_state: String = "idle"
	if key == "boss_dev":
		var u_id: int = int(unit.get("id", -1))
		if visual_attacks.has(u_id):
			animation_state = "cast"
			texture = art.texture_for(key, direction, float(pose["time"]), "cast", level)
			anchor = art.anchor_for(texture, key) if texture != null else Vector2.ZERO
			height = art.idle_height_for(key, level)
	elif key != "michael":
		var animation_unit: Dictionary = unit
		if _phase() != "combat":
			animation_unit = unit.duplicate()
			animation_unit["active"] = false
		var animated: Dictionary = character_player.frame_for(animation_unit, direction, bool(visual_moves.get(int(unit.get("id", -1)), false)))
		if not animated.is_empty():
			texture = animated["texture"] as Texture2D
			anchor = animated["anchor"]
			animation_state = str(animated["state"])
			art.register_animation_frame(texture, anchor)
			height = art.idle_height_for(key, level)
			if bool(unit.get("alive", true)):
				pose["offset"] = Vector2.ZERO
				pose["angle"] = 0.0
	return {"texture": texture, "anchor": anchor, "height": height, "state": animation_state}


## Prepara a lista desenhada no quadro: textura, pose, nível, tamanho e pés na tela.
func _prepare_frame() -> void:
	frame_entries = _draw_entries()
	for entry: Dictionary in frame_entries:
		var unit: Dictionary = entry["unit"]
		var pose: Dictionary = _visual_pose(unit)
		var level: int = clampi(int(unit.get("level", 1)), 1, 3)
		var body: Dictionary = _body_frame(unit, pose)
		var texture: Texture2D = body["texture"]
		if drag != null and drag.dragged_unit_id() == int(unit["id"]):
			pose["tint"] = Color(1, 1, 1, 0.35) # O original fica apagado enquanto a cópia segue o dedo.
		entry["pose"] = pose
		entry["texture"] = texture
		entry["anchor"] = body["anchor"]
		entry["animation_state"] = body["state"]
		entry["level"] = level
		entry["scale"] = LEVEL_SCALE[level - 1]
		entry["display_scale"] = LEVEL_SCALE[level - 1] * art.board_scale_for(str(unit.get("key", "")))
		entry["height"] = float(body["height"]) * float(entry["display_scale"])
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
	var thresholds: Array = state.get("test_config", {}).get("copies_for_level", [1, 2, 4])
	return int(thresholds[thresholds.size() - 1])


func _level_for_copies(copies: int) -> int:
	return Catalog.level_for_copies(copies, {"copies_for_level": state.get("test_config", {}).get("copies_for_level", [1, 2, 4])})


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
			var polygon: PackedVector2Array = hex_polygons_outer[cell]
			## Tons mais escuros que a areia clara; a borda escura dá leitura, o brilho interno dá acabamento.
			var fill: Color = Color(0.2, 0.52, 0.52, 0.1 if calm else 0.2) if own_half else Color(0.6, 0.27, 0.22, 0.08 if calm else 0.15)
			if not selected.is_empty() and own_half and not occupied.has(cell):
				fill = Color(0.18, 0.72, 0.66, 0.24 + 0.06 * sin(visual_time * 4.0))
			if prep and cell == hover_cell and own_half:
				fill = Color(fill, fill.a + 0.14)
			draw_colored_polygon(polygon, fill)
			draw_polyline(hex_outlines_outer[cell], Color(0.33, 0.22, 0.1, 0.22 if calm else 0.4), 1.6, true)
			draw_polyline(hex_outlines_inner[cell], Color(1.0, 0.97, 0.88, 0.1 if calm else 0.2), 1.0, true)
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
	# Os hexágonos reais da explosão do foguete acendem em laranja e apagam junto com o fogo.
	if phase == "combat":
		for blast: Dictionary in blast_zones:
			var b_fade: float = clampf(float(blast["life"]) / maxf(float(blast["duration"]), 0.001), 0.0, 1.0)
			var c_prim: Color = blast.get("color_primary", Color(1.0, 0.42, 0.1, 0.42))
			var c_bord: Color = blast.get("color_border", Color(1.0, 0.78, 0.35, 0.95))
			c_prim.a *= b_fade
			c_bord.a *= b_fade
			_draw_cell_range(_cell(blast["cell"]), int(blast["radius"]), c_prim, c_bord)
	# Aura musical de ritmo do Bob Marley durante o combate
	if calm:
		for entry: Dictionary in frame_entries:
			var unit: Dictionary = entry["unit"]
			if str(unit.get("key", "")) == "bob_marley" and bool(unit.get("alive", true)) and not bool(entry["ghost"]):
				var b_ground: Vector2 = entry["ground"]
				var b_lvl: int = clampi(int(unit.get("level", 1)), 1, 3)
				var bob_spec: Variant = specs.get("bob_marley")
				var cur_radius: int = 3
				if bob_spec != null and not bob_spec.aura_radius_by_level.is_empty():
					cur_radius = bob_spec.aura_radius_by_level[mini(b_lvl - 1, bob_spec.aura_radius_by_level.size() - 1)]
				if int(unit["id"]) == selected_id:
					_draw_cell_range(_cell(unit["cell"]), cur_radius, Color(0.25, 0.72, 0.35, 0.05), Color(0.42, 0.85, 0.52, 0.32))
				var b_pulse: float = 0.94 + 0.06 * sin(visual_time * 4.5)
				for r_i: int in range(3):
					var r_color: Color = [Color("2ec756"), Color("f4c430"), Color("e63946")][r_i]
					var r_r: float = (0.42 + float(r_i) * 0.18 + fmod(visual_time * 0.22, 0.22)) * b_pulse * (1.0 + float(cur_radius - 3) * 0.15)
					var r_ellipse: PackedVector2Array = Board.ellipse(b_ground, r_r, r_r * 0.58, 28)
					r_ellipse.append(r_ellipse[0])
					draw_polyline(r_ellipse, Color(r_color, 0.38 - float(r_i) * 0.08), 1.6, true)
				var bob_screen: Vector2 = Board.project(b_ground)
				_draw_bob_musical_notes(self, bob_screen, visual_time + float(unit.get("id", 0)) * 0.23, 1.25 * float(entry["scale"]), -44.0 * float(entry["scale"]))
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
	var is_boss: bool = str(unit.get("key", "")) == "boss_dev" or bool(unit.get("is_boss", false))
	if is_boss and bool(unit.get("alive", true)):
		_draw_boss_aura_back(entry)
	elif int(entry["level"]) >= 3 and bool(unit.get("alive", true)) and not ghost:
		_draw_aura_back(entry)
	var ground_scale: float = scale
	if is_boss:
		ground_scale = scale * 1.55
	elif str(unit.get("key", "")) in ["slime_lodo_olho", "monstro_olho_tentaculos"]:
		ground_scale = scale * 1.3
	draw_colored_polygon(Board.ellipse(ground_point, 0.26 * ground_scale, 0.14 * ground_scale, 20), Color(0, 0, 0, 0.3 * tint.a))
	var ring: PackedVector2Array = Board.ellipse(ground_point, 0.3 * ground_scale, 0.17 * ground_scale, 24)
	ring.append(ring[0])
	draw_polyline(ring, Color(TEAM_COLORS[int(unit.get("team", 0))], (0.85 if is_boss else (0.35 if ghost else 0.85)) * tint.a), 1.6, true)
	if int(unit["id"]) == selected_id:
		var glow: PackedVector2Array = Board.ellipse(ground_point, 0.36 * ground_scale, 0.21 * ground_scale, 24)
		glow.append(glow[0])
		draw_polyline(glow, Color(GOLD, 0.7 + 0.3 * sin(visual_time * 6.0)), 2.0, true)


## Aura exclusiva do Boss Dev: vórtice de vácuo negro e púrpura mística ao redor dos pés e coluna de sombras.
func _draw_boss_aura_back(entry: Dictionary) -> void:
	var ground_point: Vector2 = entry["ground"]
	var feet: Vector2 = entry["feet"]
	var pulse: float = 0.5 + 0.5 * sin(visual_time * 2.8)
	# 1. Base externa de névoa escura e púrpura profunda
	for layer: int in range(3):
		var r_x: float = 0.72 + float(layer) * 0.12
		var r_y: float = 0.42 + float(layer) * 0.07
		var a_col: Color = Color(0.18, 0.02, 0.26, (0.32 - float(layer) * 0.09) * (0.8 + 0.2 * pulse))
		draw_colored_polygon(Board.ellipse(ground_point, r_x, r_y, 32), a_col)
	# 2. Vórtice de escuridão negra profunda no centro dos pés
	draw_colored_polygon(Board.ellipse(ground_point, 0.55 + 0.04 * pulse, 0.32 + 0.03 * pulse, 28), Color(0.03, 0.01, 0.05, 0.88))
	# 3. Anel de vácuo ébano grosso com bordas escuras
	var ring_dark: PackedVector2Array = Board.ellipse(ground_point, 0.70 * (0.96 + 0.04 * pulse), 0.41 * (0.96 + 0.04 * pulse), 36)
	ring_dark.append(ring_dark[0])
	draw_polyline(ring_dark, Color(0.08, 0.01, 0.12, 0.95), 3.2, true)
	# 4. Anel interno de energia mística roxa cintilante
	var ring_purple: PackedVector2Array = Board.ellipse(ground_point, 0.52 * (0.95 + 0.05 * pulse), 0.30 * (0.95 + 0.05 * pulse), 32)
	ring_purple.append(ring_purple[0])
	draw_polyline(ring_purple, Color(0.72, 0.18, 0.98, 0.9), 2.2, true)
	# 5. Onda de choque pulsante que expande do centro
	var wave_prog: float = fmod(visual_time * 0.45, 1.0)
	var wave_r: float = 0.32 + 0.38 * wave_prog
	var ring_wave: PackedVector2Array = Board.ellipse(ground_point, wave_r, wave_r * 0.58, 28)
	ring_wave.append(ring_wave[0])
	draw_polyline(ring_wave, Color(0.55, 0.1, 0.85, 0.7 * (1.0 - wave_prog)), 1.8, true)
	# 6. Coluna vertical etérea de névoa escura/roxa ascendente
	var b_height: float = float(entry["height"]) * 1.2
	var base_dark: Color = Color(0.06, 0.01, 0.09, 0.55 * (0.75 + 0.25 * pulse))
	var top_clear: Color = Color(0.45, 0.08, 0.65, 0.0)
	draw_polygon(PackedVector2Array([feet + Vector2(-34, 4), feet + Vector2(34, 4), feet + Vector2(20, -b_height), feet + Vector2(-20, -b_height)]),
		PackedColorArray([base_dark, base_dark, top_clear, top_clear]))
	# 7. Gavinhas/runas orbitantes de sombra escura com miolo roxo
	for index: int in range(8):
		var angle: float = visual_time * 1.5 + TAU * float(index) / 8.0
		var orbit_x: float = 0.65 + 0.05 * sin(visual_time * 3.0 + float(index))
		var orbit_y: float = 0.38 + 0.03 * sin(visual_time * 3.0 + float(index))
		var rune_pos: Vector2 = Board.project(ground_point + Vector2(cos(angle) * orbit_x, sin(angle) * orbit_y)).round()
		var diamond_outer: PackedVector2Array = PackedVector2Array([rune_pos + Vector2(0, -5), rune_pos + Vector2(4, 0), rune_pos + Vector2(0, 5), rune_pos + Vector2(-4, 0)])
		draw_colored_polygon(diamond_outer, Color(0.02, 0.01, 0.04, 0.95))
		diamond_outer.append(diamond_outer[0])
		draw_polyline(diamond_outer, Color(0.58, 0.12, 0.85, 0.85), 1.2, true)
		var diamond_inner: PackedVector2Array = PackedVector2Array([rune_pos + Vector2(0, -3), rune_pos + Vector2(2, 0), rune_pos + Vector2(0, 3), rune_pos + Vector2(-2, 0)])
		draw_colored_polygon(diamond_inner, Color("b24bf3") if index % 2 == 0 else Color("7918b9"))



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
		var is_boss: bool = str(unit.get("key", "")) == "boss_dev" or bool(unit.get("is_boss", false))
		if bool(entry["ghost"]):
			if is_boss:
				tint = Color(1.0, 1.0, 1.0, 0.95)
			else:
				tint = Color(0.75, 0.8, 0.9, 0.5)
		var scale: float = float(entry["scale"])
		if (not bool(entry["ghost"]) or is_boss) and bool(unit.get("alive", true)):
			units_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var shadow_center: Vector2 = entry["feet"]
			var shadow_scale: float = scale
			if is_boss:
				shadow_scale = scale * 1.55
			elif str(unit.get("key", "")) in ["slime_lodo_olho", "monstro_olho_tentaculos"]:
				shadow_scale = scale * 1.3
			var shadow_radius: Vector2 = Vector2(17.0 * shadow_scale, 7.5 * shadow_scale)
			var shadow_pts: PackedVector2Array = PackedVector2Array()
			for s_i: int in range(12):
				var ang: float = TAU * s_i / 12.0
				shadow_pts.append(shadow_center + Vector2(cos(ang) * shadow_radius.x, sin(ang) * shadow_radius.y))
			units_layer.draw_colored_polygon(shadow_pts, Color(0.02, 0.03, 0.05, 0.38 * tint.a))
			if not hovered_synergy_key.is_empty() and int(unit.get("team", 0)) == 0 and hovered_synergy_key in (unit.get("synergy_tags", []) as Array):
				var pulse: float = 0.8 + 0.2 * sin(visual_time * 7.5)
				var syn_rad: Vector2 = shadow_radius * 1.55
				var syn_pts: PackedVector2Array = PackedVector2Array()
				for syn_i: int in range(20):
					var a: float = TAU * float(syn_i) / 20.0
					syn_pts.append(shadow_center + Vector2(cos(a) * syn_rad.x, sin(a) * syn_rad.y))
				units_layer.draw_colored_polygon(syn_pts, Color(GOLD.r, GOLD.g, GOLD.b, 0.26 * pulse * tint.a))
				syn_pts.append(syn_pts[0])
				units_layer.draw_polyline(syn_pts, Color(GOLD.r, GOLD.g, GOLD.b, 0.95 * pulse * tint.a), 2.2, true)
		var anchor: Vector2 = entry["anchor"]
		var origin: Vector2 = ((entry["feet"] as Vector2) + (pose["offset"] as Vector2)).round()
		var display_scale: float = float(entry["display_scale"])
		units_layer.draw_set_transform(origin, float(pose["angle"]), Vector2(display_scale, display_scale))
		units_layer.draw_texture(texture, (-anchor).round(), tint)
		if bool(unit.get("alive", true)):
			var u_key: String = str(unit.get("key", ""))
			if u_key == "snoop":
				var u_dir: String = str(visual_directions.get(int(unit.get("id", -1)), "south"))
				_draw_snoop_cigar(units_layer, origin, display_scale, u_dir, visual_time + float(unit.get("id", 0)) * 0.37, tint, float(pose["angle"]))
			elif u_key == "bob_marley" and not bool(entry["ghost"]) and _phase() == "preparation":
				_draw_bob_musical_notes(units_layer, origin, visual_time + float(unit.get("id", 0)) * 0.25, 1.15 * scale, -44.0 * scale)
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
		if kind == "rocket" and bool(projectile.get("is_super", false)) and vfx.has_effect("foguete_02"):
			_draw_vfx_frame(units_layer, _projectile_vfx_data("foguete_02", flight_pos, rot_angle))
		elif kind == "smoke" and vfx.has_effect("anel_fumaca_01"):
			_draw_vfx_frame(units_layer, _projectile_vfx_data("anel_fumaca_01", flight_pos, rot_angle))
		elif kind == "mini_rocket":
			units_layer.draw_set_transform(flight_pos, rot_angle, Vector2(0.7, 0.7))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-7, -2), Vector2(3, -2), Vector2(7, 0), Vector2(3, 2), Vector2(-7, 2)]),
				PackedColorArray([Color("e8e8f2"), Color("e8e8f2"), Color("ff3b30"), Color("e8e8f2"), Color("e8e8f2")]))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-7, -4), Vector2(-4, -2), Vector2(-7, -1)]), PackedColorArray([Color("1c1c24"), Color("1c1c24"), Color("1c1c24")]))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-7, 1), Vector2(-4, 2), Vector2(-7, 4)]), PackedColorArray([Color("1c1c24"), Color("1c1c24"), Color("1c1c24")]))
			var thrust_flicker: float = 0.8 + 0.4 * sin(visual_time * 32.0)
			units_layer.draw_polygon(PackedVector2Array([Vector2(-7, -1.5), Vector2(-12 * thrust_flicker, 0), Vector2(-7, 1.5)]),
				PackedColorArray([Color(1.0, 0.8, 0.2), Color(1.0, 0.4, 0.1, 0.85), Color(1.0, 0.8, 0.2)]))
		elif kind == "rocket":
			var rocket_scale: float = 1.35 if bool(projectile.get("is_super", false)) else 1.0
			units_layer.draw_set_transform(flight_pos, rot_angle, Vector2(rocket_scale, rocket_scale))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-10, -4), Vector2(5, -4), Vector2(11, 0), Vector2(5, 4), Vector2(-10, 4)]),
				PackedColorArray([Color("f0f0ff"), Color("f0f0ff"), Color("ff2a2a"), Color("f0f0ff"), Color("f0f0ff")]))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-10, -6), Vector2(-7, -4), Vector2(-10, -2)]), PackedColorArray([Color("2a2a35"), Color("2a2a35"), Color("2a2a35")]))
			units_layer.draw_polygon(PackedVector2Array([Vector2(-10, 2), Vector2(-7, 4), Vector2(-10, 6)]), PackedColorArray([Color("2a2a35"), Color("2a2a35"), Color("2a2a35")]))
			var thrust_flicker: float = 0.85 + 0.45 * sin(visual_time * 26.0)
			units_layer.draw_polygon(PackedVector2Array([Vector2(-10, -3), Vector2(-18 * thrust_flicker, 0), Vector2(-10, 3)]),
				PackedColorArray([Color(1.0, 0.85, 0.25), Color(1.0, 0.35, 0.05, 0.95), Color(1.0, 0.85, 0.25)]))
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
	world_item_hover_rects.clear()
	var canvas: Node2D = overlay_layer
	for entry: Dictionary in frame_entries:
		var unit: Dictionary = entry["unit"]
		var is_boss_overlay: bool = str(unit.get("key", "")) == "boss_dev" or bool(unit.get("is_boss", false))
		if not bool(unit.get("alive", true)) or (bool(entry["ghost"]) and not is_boss_overlay):
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
		if int(entry["level"]) >= 3 and not bool(entry["ghost"]):
			for index: int in range(7):
				var rise: float = fposmod(visual_time * 0.55 + index / 7.0 + float(unit["id"]) * 0.13, 1.0)
				var sway: float = sin(index * 2.3 + visual_time * 2.0) * 13.0 * float(entry["scale"])
				var mote: Vector2 = (feet + Vector2(sway, -6 - rise * height * 1.15)).round()
				var size: float = 3.0 if index % 3 == 0 else 2.0
				var fade: float = 1.0 - rise
				canvas.draw_rect(Rect2(mote - Vector2.ONE, Vector2(size + 2, size + 2)), Color(0.15, 0.06, 0.22, 0.75 * fade))
				canvas.draw_rect(Rect2(mote, Vector2(size, size)), Color(Color("ffd85c") if index % 2 == 0 else Color("d6a8ff"), fade))
		if is_boss_overlay and bool(unit.get("alive", true)):
			for index: int in range(12):
				var b_rise: float = fposmod(visual_time * 0.45 + float(index) / 12.0, 1.0)
				var b_sway: float = sin(float(index) * 2.1 + visual_time * 2.3) * 26.0
				var b_mote: Vector2 = (feet + Vector2(b_sway, -8 - b_rise * height * 1.12)).round()
				var b_size: float = 4.0 if index % 3 == 0 else (3.0 if index % 2 == 0 else 2.0)
				var b_fade: float = 1.0 - b_rise
				canvas.draw_rect(Rect2(b_mote - Vector2.ONE, Vector2(b_size + 2, b_size + 2)), Color(0.02, 0.01, 0.04, 0.9 * b_fade))
				var b_core: Color = Color("c040fb") if index % 2 == 0 else Color("7918b9")
				canvas.draw_rect(Rect2(b_mote, Vector2(b_size, b_size)), Color(b_core, b_fade * 0.95))
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
	_draw_world_item_tooltip(canvas)


func _draw_bars(canvas: CanvasItem, entry: Dictionary) -> void:
	var unit: Dictionary = entry["unit"]
	var is_boss_bar: bool = str(unit.get("key", "")) == "boss_dev" or bool(unit.get("is_boss", false))
	if (bool(entry["ghost"]) and not is_boss_bar) or not bool(unit.get("alive", true)) or not unit.has("max_hp"):
		if bool(entry["ghost"]) and int(entry["level"]) > 1:
			_draw_level_stars(canvas, (entry["feet"] as Vector2) + Vector2(0, -float(entry["height"]) - 10), int(entry["level"]))
		return
	var feet: Vector2 = entry["feet"]
	var height: float = float(entry["height"])
	var team: int = int(unit.get("team", 0))
	var maximum: float = maxf(float(unit.get("max_hp", 1)), 1.0)
	var is_boss_bar: bool = str(unit.get("key", "")) == "boss_dev" or bool(unit.get("is_boss", false))
	var width: float = 64.0 if is_boss_bar else (48.0 if str(unit.get("key", "")) in ["slime_lodo_olho", "monstro_olho_tentaculos"] else 38.0)
	var bar: Rect2 = Rect2((feet + Vector2(-width * 0.5, -height - 12)).round(), Vector2(width, 6))
	canvas.draw_rect(bar.grow(1), Color(0.02, 0.02, 0.03, 0.85))
	var hp_ratio: float = clampf(float(unit.get("hp", 0)) / maximum, 0.0, 1.0)
	canvas.draw_rect(Rect2(bar.position, Vector2(width * hp_ratio, 6)), TEAM_COLORS[team])
	canvas.draw_rect(Rect2(bar.position, Vector2(width * hp_ratio, 2)), Color(1, 1, 1, 0.25))
	for part: Dictionary in _shield_parts(unit, width):
		canvas.draw_rect(Rect2(bar.position + Vector2(float(part["start"]), 6), Vector2(float(part["width"]), 2)), part["color"])
	var mana: Dictionary = _mana_bar_data(unit, width)
	if not mana.is_empty():
		var mana_rect: Rect2 = Rect2(bar.position + Vector2(0, 10), Vector2(width, 3))
		canvas.draw_rect(mana_rect.grow(1), Color(0.02, 0.06, 0.13, 0.9))
		canvas.draw_rect(mana_rect, Color(0.13, 0.22, 0.38))
		canvas.draw_rect(Rect2(mana_rect.position, Vector2(float(mana["width"]), 3)), Color("58aaff"))
	var tick_size: float = 1000.0 if maximum >= 5000.0 else (250.0 if maximum <= 1200.0 else 500.0)
	var tick: float = tick_size
	while tick < maximum:
		var x: float = bar.position.x + width * tick / maximum
		canvas.draw_line(Vector2(x, bar.position.y), Vector2(x, bar.position.y + 4), Color(0, 0, 0, 0.55), 1.0)
		tick += tick_size
	if not (unit.get("bleeds", []) as Array).is_empty():
		canvas.draw_colored_polygon(PackedVector2Array([bar.position + Vector2(-6, 0), bar.position + Vector2(-3, 3), bar.position + Vector2(-6, 7), bar.position + Vector2(-9, 3)]), Color("e0485a"))

	# Ícone indicador de sinergia ao lado da barra quando a sinergia está sob mouse hover
	if not hovered_synergy_key.is_empty() and team == 0 and hovered_synergy_key in (unit.get("synergy_tags", []) as Array):
		var syn_icon: Texture2D = Kit.icon("syn_" + hovered_synergy_key)
		if syn_icon != null:
			var syn_badge_rect: Rect2 = Rect2(bar.position.x + width + 4, bar.position.y - 5, 16, 16)
			canvas.draw_texture_rect(syn_icon, syn_badge_rect, false)
			canvas.draw_rect(syn_badge_rect, Color(GOLD, 0.85), false, 1.0)
	
	# Mini-ícones de itens equipados (tanto na preparação quanto em combate)
	var items: Array = []
	if team == 0:
		items = (state.get("own", {}).get("equipment", {}) as Dictionary).get(int(unit["id"]), [])
	elif unit.has("equipment"):
		items = unit.get("equipment", [])
	var is_selected: bool = selected_id == int(unit["id"])
	if not items.is_empty() or is_selected:
		var slot_w: float = 14.0
		var slot_h: float = 14.0
		var gap: float = 2.0
		var display_slots: int = maxi(items.size(), 4 if is_selected else 0)
		var total_w: float = display_slots * slot_w + (display_slots - 1) * gap
		var start_x: float = bar.position.x + (width - total_w) * 0.5
		var items_y: float = bar.position.y + (16.0 if not mana.is_empty() else 10.0)
		for slot_idx: int in range(display_slots):
			var slot_rect: Rect2 = Rect2(start_x + slot_idx * (slot_w + gap), items_y, slot_w, slot_h)
			if slot_idx < items.size():
				var item_data: Dictionary = items[slot_idx]
				var item_key: String = str(item_data.get("key", ""))
				var icon: Texture2D = Kit.icon("item_" + item_key)
				var is_fused: bool = item_key in ["great_blade", "guard_vest"]
				var border_col: Color = GOLD if is_fused else (Color(0.95, 0.45, 0.45, 0.9) if team == 1 else Color(0.45, 0.65, 0.95, 0.9))
				canvas.draw_rect(slot_rect, Color(0.06, 0.05, 0.1, 0.9))
				if icon != null:
					canvas.draw_texture_rect(icon, slot_rect.grow(-1), false)
				canvas.draw_rect(slot_rect, border_col, false, 1.0)
				world_item_hover_rects.append({
					"rect": slot_rect,
					"item": item_data,
					"unit_name": str(unit.get("name", "Herói")),
					"unit_id": int(unit["id"]),
					"team": team
				})
			elif is_selected:
				canvas.draw_rect(slot_rect, Color(0.03, 0.03, 0.06, 0.45))
				var empty_border: Color = Color(0.65, 0.35, 0.35, 0.45) if team == 1 else Color(0.35, 0.4, 0.5, 0.45)
				canvas.draw_rect(slot_rect, empty_border, false, 1.0)
	
	_draw_level_stars(canvas, bar.position + Vector2(width * 0.5, -6), int(entry["level"]))


## Somente leitura do snapshot; ausência de max_mana não inventa um recurso.
func _mana_bar_data(unit: Dictionary, width: float = 38.0) -> Dictionary:
	var maximum: float = float(unit.get("max_mana", 0.0))
	var mana: float = float(unit.get("mana", 0.0))
	if not is_finite(maximum) or not is_finite(mana) or maximum <= 0.0:
		return {}
	var ratio: float = clampf(mana / maximum, 0.0, 1.0)
	return {"value": mana, "maximum": maximum, "ratio": ratio, "width": maxf(0.0, width) * ratio}


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


## Tooltip flutuante exibido ao passar o mouse sobre os itens do personagem no campo/combate.
func _draw_world_item_tooltip(canvas: Node2D) -> void:
	if world_item_hover_rects.is_empty() or mouse_pointer.x < -100:
		return
	var hovered_entry: Dictionary = {}
	for entry: Dictionary in world_item_hover_rects:
		var rect: Rect2 = entry["rect"]
		if rect.grow(3.0).has_point(mouse_pointer):
			hovered_entry = entry
			break
	if hovered_entry.is_empty():
		return
	
	var item: Dictionary = hovered_entry["item"]
	var key: String = str(item.get("key", ""))
	var def: Dictionary = (state.get("item_catalog", {}) as Dictionary).get(key, {})
	var item_name: String = str(def.get("name", _item_name(item)))
	var desc: String = str(def.get("description", ""))
	var unit_name: String = str(hovered_entry.get("unit_name", ""))
	var icon: Texture2D = Kit.icon("item_" + key)
	var is_fused: bool = key in ["great_blade", "guard_vest"]
	
	var font: Font = ThemeDB.fallback_font
	var item_team: int = int(hovered_entry.get("team", 0))
	var owner_tag: String = " (Inimigo)" if item_team == 1 else ""
	var line_name: String = item_name.to_upper()
	var line_desc: String = desc
	var line_owner: String = "Equipado em: " + unit_name + owner_tag
	
	var tip_w: float = 230.0
	var tip_h: float = 68.0
	var pos: Vector2 = mouse_pointer + Vector2(14, -tip_h - 6)
	if pos.y < 10.0:
		pos.y = mouse_pointer.y + 20.0
	if pos.x + tip_w > 1270.0:
		pos.x = mouse_pointer.x - tip_w - 14.0
	pos.x = clampf(pos.x, 10.0, 1270.0 - tip_w)
	pos.y = clampf(pos.y, 10.0, 710.0 - tip_h)
	
	var card_rect: Rect2 = Rect2(pos, Vector2(tip_w, tip_h))
	canvas.draw_rect(card_rect.grow(2), Color(0.0, 0.0, 0.0, 0.6))
	canvas.draw_rect(card_rect, Color(0.08, 0.07, 0.13, 0.95))
	var border_col: Color = GOLD if is_fused else (Color(0.95, 0.45, 0.45, 0.9) if item_team == 1 else Color(0.45, 0.68, 0.98, 0.9))
	canvas.draw_rect(card_rect, border_col, false, 1.5)
	
	if icon != null:
		var icon_rect: Rect2 = Rect2(pos + Vector2(8, 8), Vector2(24, 24))
		canvas.draw_rect(icon_rect, Color(0.04, 0.03, 0.07, 0.8))
		canvas.draw_texture_rect(icon, icon_rect, false)
		canvas.draw_rect(icon_rect, border_col, false, 1.0)
	
	canvas.draw_string(font, pos + Vector2(38, 22), line_name, HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 44), 13, border_col)
	canvas.draw_string(font, pos + Vector2(10, 44), line_desc, HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 20), 11, Color("dfe6e3"))
	var owner_col: Color = Color("f87171") if item_team == 1 else Color("9eb3c2")
	canvas.draw_string(font, pos + Vector2(10, 60), line_owner, HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 20), 10, owner_col)
