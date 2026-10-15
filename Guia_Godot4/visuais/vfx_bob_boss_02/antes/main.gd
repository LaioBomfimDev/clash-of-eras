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
const GoldPileCache = preload("res://client/gold_pile_cache.gd")
const LobbyBackdrop = preload("res://client/lobby_backdrop.gd")
const ArenaRenderCache = preload("res://client/arena_render_cache.gd")
const OrnateFrameCache = preload("res://client/ornate_frame_cache.gd")
const ShopCardCache = preload("res://client/shop_card_cache.gd")
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
	"lula": "Ao sofrer dano letal, demora 1.0s para descer dos céus como anjo com 40% de vida, concedendo +25% de dano à equipe e 100% de acertos críticos por 5s. No nível 3, pode voltar uma segunda vez na rodada com 30% de vida. Mantém as asas até o fim da partida.",
	"bob_marley": "Ritmo de paz e amor: aura de amplo alcance (raio 4/5/6). Aliados atacam +30% mais rápido; inimigos, 30% mais devagar.",
	"rapunzel": "Começa com 0/100 mana e ganha 25 por ataque lançado. Ao encher, puxa o inimigo mais distante e o atordoa; a mana é consumida."
}

## Propostas para a ficha visual; estas cartas não implementam novas regras de combate.
const HERO_FOUR_TECHNIQUES: Dictionary = {
	"zumbi": [
		{"name": "ESTOCADAS DE LANÇA", "type": "Técnica Passiva", "desc": "Críticos consecutivos acumulam poder progressivo (+20 de dano por acerto crítico). Concede +15% de crítico e velocidade à equipe.", "icon": "🗡️"},
		{"name": "LÍDER DOS PALMARES", "type": "Técnica Passiva", "desc": "Ganha a classe Atacantes e 25 de Crít. Ao eliminar um inimigo, ganha Fúria por 4s e regenera 10% de PV Máx.\nReforço: No início do combate, concede +15% de crítico à equipe.", "icon": "👑"},
		{"name": "INVESTIDA IMPLACÁVEL", "type": "Técnica Ativa [20/50 Mana]", "desc": "Executa estocada perfurante causando 380 (+50% Velocidade + 35% Ataque)% de dano físico e quebrando 30% da armadura do alvo por 4s.", "icon": "⚡"},
		{"name": "LANÇA ANCESTRAL", "type": "Técnica Passiva", "desc": "Após 10s de combate, a lança cresce (+20% alcance). No Nível 2 ganha corte horizontal e no Nível 3 ganha aura sagrada de chamas violetas.", "icon": "🔥"}
	],
	"neymar": [
		{"name": "DRIBLE DA VACA", "type": "Técnica Passiva", "desc": "A cada 4 ataques automáticos, esquiva do próximo golpe e avança velozmente ganhando +30% de Velocidade de Ataque.", "icon": "⚽"},
		{"name": "CAMISA 10", "type": "Técnica Passiva", "desc": "Ganha a classe Atiradores e 20 de Crít. Chutes contra inimigos isolados causam +30% de dano adicional.\nReforço: +15% de velocidade de ataque.", "icon": "👟"},
		{"name": "CHUTE RICOCHETE", "type": "Técnica Ativa [15/45 Mana]", "desc": "Dispara chute com efeito curvo que atinge até 3 inimigos (1º impacto 100%, 2º impacto 80% e 3º impacto 50% de dano).", "icon": "🎯"},
		{"name": "ROLAMENTO TÁTICO", "type": "Técnica Passiva", "desc": "Ao sofrer dano letal ou crítico, rola para trás tornando-se inalvejável por 1.5s e recupera 50 de Mana.", "icon": "🛡️"}
	],
	"michael": [
		{"name": "MOONWALK PROTETOR", "type": "Técnica Passiva", "desc": "Desliza suavemente por 3 hexágonos para escapar de atacantes. Ao parar, gera 172.5 de escudo protetor para toda a equipe.", "icon": "🎩"},
		{"name": "REI DO POP", "type": "Técnica Passiva", "desc": "Ganha a classe Apoio. Enquanto estiver vivo em campo, mantém aura mágica que cura 8.05 PV/s continuamente a todos os aliados.\nReforço: Concede +10% de vida máxima à equipe.", "icon": "⭐"},
		{"name": "THRILLER NOTURNO", "type": "Técnica Ativa [25/60 Mana]", "desc": "Conjura passos de dança sincronizada que desorientam os inimigos adjacentes por 2s e aumenta o dano de aliados em 25%.", "icon": "🧟"},
		{"name": "SMOOTH CRIMINAL", "type": "Técnica Passiva", "desc": "Após 15s de combate, todos os escudos concedidos por Michael duram o dobro do tempo e refletem 20% do dano aos atacantes.", "icon": "✨"}
	],
	"snoop": [
		{"name": "CORTINA VOLUMÉTRICA", "type": "Técnica Passiva", "desc": "Lança nuvem de fumaça verde translúcida na altura da cintura (raio 2). Inimigos na fumaça erram 30% dos ataques automáticos.", "icon": "💨"},
		{"name": "WEST COAST FLOW", "type": "Técnica Passiva", "desc": "Ganha a classe Atiradores e 25 de Magia. Aliados dentro da fumaça ganham +25% de velocidade de movimento e ataque.\nReforço: +15% de velocidade de ataque.", "icon": "🌴"},
		{"name": "NEVA NEVA", "type": "Técnica Ativa [20/50 Mana]", "desc": "Dispara baforada mágica concentrada que intoxica a retaguarda inimiga causando 340 de dano mágico contínuo.", "icon": "🌿"},
		{"name": "CHARUTÃO LENDÁRIO", "type": "Técnica Passiva", "desc": "Após 12s de combate, o charuto brilha intensamente concedendo regeneração contínua de 15 PV/s e imunidade a lentidões.", "icon": "🚬"}
	],
	"bob_marley": [
		{"name": "RITMO DE PAZ E AMOR", "type": "Técnica Passiva", "desc": "Aura musical envolvente (raio 4/5/6) com cores da Jamaica: aliados atacam +30% mais rápido e inimigos atacam 30% mais devagar.", "icon": "🎵"},
		{"name": "ONE LOVE", "type": "Técnica Passiva", "desc": "Ganha a classe Apoio. Ao conjurar, remove todos os efeitos de sangramento e lentidão de aliados no alcance da música.\nReforço: Aliados ganham +10% de vida máxima.", "icon": "💛"},
		{"name": "REDENÇÃO SONORA", "type": "Técnica Ativa [20/50 Mana]", "desc": "Toca acorde de guitarra místico que emite ondas sonoras em anéis cósmicos curando 280 PV de aliados no raio.", "icon": "🎸"},
		{"name": "POSITIVIDADE TOTAL", "type": "Técnica Passiva", "desc": "Após 10s de combate, o raio da aura de paz e amor se expande em +1 hexágono e concede +15% de armadura à equipe.", "icon": "🟢"}
	],
	"lula": [
		{"name": "VOLTA POR CIMA", "type": "Técnica Passiva", "desc": "Ao sofrer dano letal, demora 1.0s para descer dos céus como anjo com 40% de vida, dando +25% de dano e 100% de crítico por 5s.", "icon": "🪽"},
		{"name": "UNIÃO POPULAR", "type": "Técnica Passiva", "desc": "Ganha a classe Vanguarda. Concede 150 de escudo a aliados com menos de 50% de vida quando conjura.\nReforço: Reduz dano recebido em 15%.", "icon": "🤝"},
		{"name": "DISCURSO ENÉRGICO", "type": "Técnica Ativa [20/50 Mana]", "desc": "Bate com força na tribuna mística disparando onda de choque que empurra e atordoa a fileira inimiga frontal.", "icon": "📢"},
		{"name": "SEGUNDO MANDATO", "type": "Técnica Passiva", "desc": "No Nível 3, pode voltar uma segunda vez na mesma rodada com 30% de vida. Mantém as asas douradas até o final da luta.", "icon": "⭐"}
	],
	"barbie": [
		{"name": "DUO PERFEITO", "type": "Técnica Passiva", "desc": "Entra em combate invocando o Ken ao seu lado. Enquanto o Ken viver, Barbie causa +50% de dano de ataque adicional.", "icon": "🎀"},
		{"name": "FASHION ICON", "type": "Técnica Passiva", "desc": "Ganha a classe Vanguarda. Recebe +150 de Vida Máxima e +10 de Defesa por cada nível de raridade de item equipado.\nReforço: Ken recebe os mesmos bônus.", "icon": "👠"},
		{"name": "CONVERSÍVEL ROSA", "type": "Técnica Ativa [25/55 Mana]", "desc": "Acelera seu conversível cruzando a fileira inimiga, causando 420 de dano de impacto e reduzindo armaduras em 20%.", "icon": "🚗"},
		{"name": "COMANDO FASHION", "type": "Técnica Passiva", "desc": "Após 10s de combate, inspira o Ken a entrar em fúria, dobrando a velocidade de ataque dele por 6 segundos.", "icon": "✨"}
	],
	"ken": [
		{"name": "GUARDIÃO DEDICADO", "type": "Técnica Passiva", "desc": "Atrai automaticamente os golpes direcionados à Barbie e absorve 35% de todo o dano recebido por ela.", "icon": "🏄"},
		{"name": "ENERGIA DA PRAIA", "type": "Técnica Passiva", "desc": "Ganha a classe Guardião e +25 de Armadura base. Ao bloquear ataques, ganha 5 de Mana.\nReforço: Aumenta resistência mágica em +20.", "icon": "🏖️"},
		{"name": "MERGULHO PROTETOR", "type": "Técnica Ativa [15/45 Mana]", "desc": "Salta na frente do aliado mais ferido, erguendo prancha que absorve 400 de dano por 4 segundos.", "icon": "🏄‍♂️"},
		{"name": "MOJO DOJO CASA", "type": "Técnica Passiva", "desc": "Se a Barbie estiver viva após 15s de combate, Ken ganha +40% de Ataque e golpes que atordoam inimigos.", "icon": "🏠"}
	],
	"elon": [
		{"name": "MINIFOGUETES FOCADOS", "type": "Técnica Passiva", "desc": "Dispara saraivada de 3 minifoguetes nos 3 primeiros tiros; o 4º disparo é um Super Foguete explosivo.", "icon": "🚀"},
		{"name": "PROPULSÃO ESPACIAL", "type": "Técnica Passiva", "desc": "Ganha a classe Atiradores. Projéteis penetram 2 casas na retaguarda inimiga causando dano secundário.\nReforço: +15% de velocidade de ataque.", "icon": "🛰️"},
		{"name": "LANÇAMENTO STARSHIP", "type": "Técnica Ativa [20/60 Mana]", "desc": "Míssil orbital que desce dos céus explodindo em raio 2, causando 520 de dano de fogo e empurrão em área.", "icon": "🔥"},
		{"name": "BATERIA RECARREGÁVEL", "type": "Técnica Passiva", "desc": "A cada 8s de combate, recarrega instantaneamente 25 de Mana e ativa escudo de plasma de 180 PV.", "icon": "🔋"}
	],
	"obama": [
		{"name": "MALA BLINDADA", "type": "Técnica Passiva", "desc": "A mala presidencial absorve os primeiros 450 pontos de dano recebido e regenera 50 de barreira a cada 5 segundos.", "icon": "💼"},
		{"name": "YES WE CAN", "type": "Técnica Passiva", "desc": "Ganha a classe Vanguarda. Inspira aliados vizinhos com +20 de Armadura e +20 de Resistência Mágica.\nReforço: +10% de vida máxima da equipe.", "icon": "🇺🇸"},
		{"name": "DECRETO PRESIDENCIAL", "type": "Técnica Ativa [20/50 Mana]", "desc": "Ergue escudo diplomático impenetrável que anula projéteis inimigos em cone frontal por 3.5 segundos.", "icon": "📜"},
		{"name": "DIPLOMACIA PESADA", "type": "Técnica Passiva", "desc": "Inimigos que golpeiam a mala sofrem redução de 25% na velocidade de ataque e 15% de lentidão contínua.", "icon": "🏛️"}
	],
	"caramelo": [
		{"name": "INSTINTO VIRA-LATA", "type": "Técnica Passiva", "desc": "No início do combate, caça o alvo mais frágil e distante da arena. Mordidas causam sangramento contínuo.", "icon": "🐕"},
		{"name": "MORDIDA FEROZ", "type": "Técnica Passiva", "desc": "Ganha a classe Assassinos. Elimina instantaneamente inimigos com menos de 10% de vida máxima.\nReforço: Ganha +20 de Crítico permanente.", "icon": "🐾"},
		{"name": "BOTE VELOZ", "type": "Técnica Ativa [15/40 Mana]", "desc": "Salta ágil por trás do inimigo, cravando os dentes e causando 360 de dano crítico com sangramento grave.", "icon": "⚡"},
		{"name": "ESQUIVA URBANA", "type": "Técnica Passiva", "desc": "Possui 30% de chance permanente de esquivar de qualquer golpe físico ou habilidade teleguiada.", "icon": "🦴"}
	],
	"rapunzel": [
		{"name": "TRANÇA ENCANTADA", "type": "Técnica Passiva", "desc": "Começa com 0/100 de mana e acumula +25 de mana a cada ataque básico desferido com suas mechas mágicas.", "icon": "✨"},
		{"name": "LAÇO DOURADO", "type": "Técnica Passiva", "desc": "Ganha a classe Apoio. Ao atingir 100 de mana, laça o inimigo mais distante, puxa-o para frente e o atordoa.\nReforço: +10% de vida máxima.", "icon": "🎀"},
		{"name": "BRILHO DA FLOR", "type": "Técnica Ativa [25/100 Mana]", "desc": "Libera pulso luminoso que cura a si mesma e aos aliados adjacentes em 320 de vida e restaura escudos.", "icon": "🌸"},
		{"name": "CABELÃO DE 50 METROS", "type": "Técnica Passiva", "desc": "O alcance da puxada alcança qualquer canto da arena. Inimigo puxado fica isolado sofrendo +35% de dano.", "icon": "💇‍♀️"}
	],
	"nyx_guest": [
		{"name": "INSTINTO DE FERA", "type": "Técnica Passiva", "desc": "Durante 5s de Ímpeto, ganha 5 (+25% Velocidade) de Iniciativa e 5 (+25% Ataque) de Ataque a cada ativação. A cada 12 ataques, reativa as técnicas de Ímpeto.", "icon": "🐺"},
		{"name": "VISÃO AGUÇADA", "type": "Técnica Passiva", "desc": "Ganha a classe Assassino e 30 de Crít. Assassinos e Duelistas destroem instantaneamente inimigos atacados que estejam abaixo de 20 (+5 por Reforço)% de PV Máx.\nReforço.", "icon": "👁️"},
		{"name": "NATUREZA SELVAGEM", "type": "Técnica Ativa [20/50 Mana]", "desc": "Realiza um combo de 5 golpes. Cada golpe causa 100 (+50% Vel + 33% Magia + 33% Ataque)% de dano. Se o inimigo morrer durante o combo, Nyx salta para o inimigo mais próximo e conjura novamente.", "icon": "🐾"},
		{"name": "CENTELHA", "type": "Técnica Passiva", "desc": "Após 10s de Inibição aplica Queimadura, após 20s Gelo e após 30s Veneno em cada ataque automático.", "icon": "⚡"}
	],
	"ratna_guest": [
		{"name": "FASHIONISTA", "type": "Técnica Passiva", "desc": "Ganha um espaço para itens. No início do combate, ganha 45 de Magia, 3 de Regen de Mana e 6 PV/s por nível de raridade de cada item equipado.", "icon": "👑"},
		{"name": "OSTENTADORA", "type": "Técnica Passiva", "desc": "Ganha a classe Místico e 4 de Regen de Mana. Ao conjurar, outros heróis ganham 17 de Magia e 1 de Regen.\nReforço: Magos ganham 17 de Magia e 1 de Regen.", "icon": "✨"},
		{"name": "MAGNÂNIMA", "type": "Técnica Passiva", "desc": "Ganha a classe Assassino e 25 de Crít. Queda da Estrela atinge quem tiver menos vida nas primeiras 3 vezes. Ao eliminar ganha Furtividade por 4s e +5 de Crít.", "icon": "🦅"},
		{"name": "QUEDA DA ESTRELA", "type": "Técnica Ativa [20/55 Mana]", "desc": "Conjura meteoro cósmico massivo causando 3.904 de dano mágico em área com efeito de lentidão estelar.", "icon": "🌠"}
	]
}

const LOBBY_BG_PATH: String = "res://assets/ui/lobby_02/lobby.png"

const HERO_CATALOG_KEYS: Array[String] = [
	"neymar", "caramelo", "obama", "zumbi", "michael",
	"barbie", "ken", "elon", "snoop", "lula", "bob_marley", "rapunzel"
]
const SINGER_KEYS: Array[String] = ["bob_marley", "snoop", "michael"]

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
var stage_panel: Panel = null
var boss_bar_panel: Panel = null
var boss_bar_title: Label = null
var boss_bar_timer_label: Label = null
var boss_bar_track: ColorRect = null
var boss_bar_fill: ColorRect = null
var boss_bar_ghost: ColorRect = null
var boss_bar_hp_label: Label = null
var boss_bar_minions_label: Label = null
var boss_ghost_hp_ratio: float = 1.0
var boss_telegraphs: Array[Dictionary] = []
var boss_summon_portals: Array[Dictionary] = []
var lula_descents: Dictionary = {}
var ascended_units: Dictionary = {}
const REGGAE_GREEN: Color = Color("009b3a")
const REGGAE_GOLD: Color = Color("fed100")
const REGGAE_RED: Color = Color("d52b1e")
var cannabis_leaf_tex: Texture2D = null
var bob_reggae_note_tex: Texture2D = null

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
var arena_render_cache: ArenaRenderCache
var gold_pile_layer: GoldPileCache
var gold_label: Label
var income_label: Label
var capacity_label: Label
var capacity_title_label: Label = null
var capacity_btn_label: Label = null
var capacity_btn_coin: TextureRect = null
var capacity_btn_cost: Label = null
var reroll_btn_label: Label = null
var reroll_btn_coin: TextureRect = null
var reroll_btn_cost: Label = null
var fight_btn_icon: TextureRect = null
var fight_btn_label: Label = null
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
var lobby_backdrop: LobbyBackdrop
var lobby_bg: Texture2D
var lobby_root: Control
var lobby_subview: String = "none" # "none", "heroes", "settings"
var lobby_hero_synergy_filter: String = "all"
var lobby_selected_hero_key: String = "neymar"
var lobby_preview_level: int = 1
var lobby_preview_mode: String = "action" # "action" (no tabuleiro), "pose" (estudo estático)
var lobby_heroes_detail_open: bool = false
var lobby_heroes_search: String = ""
var lobby_heroes_status_filter: String = "all" # "all", "incomplete"
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
var _performance_last_frame_usec: int = 0
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
	lobby_backdrop = LobbyBackdrop.new()
	add_child(lobby_backdrop)
	board_perimeter = Board.perimeter_segments()
	_load_arena_props()
	for effect_name: String in ["explosao_fogo_roxo", "explosao_fogo_vermelho", "fogo_vermelho_projetil", "fogo_roxo_projetil", "furacao_fogo", "furacao_fogo_frame_0", "furacao_fogo_frame_1", "furacao_fogo_frame_2", "furacao_fogo_frame_3", "loot_orb_brilhante"]:
		var effect_path: String = "res://assets/vfx/boss_dev/%s.png" % effect_name
		boss_vfx_textures[effect_name] = load(effect_path) as Texture2D if ResourceLoader.exists(effect_path) else null
	if ResourceLoader.exists("res://assets/vfx/cannabis_leaf_64.png"):
		cannabis_leaf_tex = load("res://assets/vfx/cannabis_leaf_64.png") as Texture2D
	elif ResourceLoader.exists("res://assets/vfx/cannabis_leaf.png"):
		cannabis_leaf_tex = load("res://assets/vfx/cannabis_leaf.png") as Texture2D
	if ResourceLoader.exists("res://assets/vfx/bob_reggae_attack_64.png"):
		bob_reggae_note_tex = load("res://assets/vfx/bob_reggae_attack_64.png") as Texture2D
	elif ResourceLoader.exists("res://assets/vfx/bob_reggae_note.png"):
		bob_reggae_note_tex = load("res://assets/vfx/bob_reggae_note.png") as Texture2D
	arena_render_cache = ArenaRenderCache.new()
	arena_render_cache.z_index = -1
	add_child(arena_render_cache)
	arena_render_cache.setup(Vector2i(SCREEN), _draw_cached_arena)
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
	# Moeda do ouro parada conforme preferência do usuário (sem giro contínuo)
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
	_update_arena_cache()
	queue_redraw()
	units_layer.queue_redraw()
	overlay_layer.queue_redraw()
	if gold_pile_layer != null and is_instance_valid(gold_pile_layer) and gold_pile_layer.visible:
		gold_pile_layer.advance(visual_time)
	if is_instance_valid(hero_preview_control) and hero_preview_control.is_visible_in_tree():
		hero_preview_control.queue_redraw()
	_update_performance(delta, Time.get_ticks_usec() - cpu_start)


## Relógio monotônico: o delta do engine pode ser limitado em quadros lentos.
## CPU continua medindo só a atualização, sem desenho/GPU.
func _update_performance(_delta: float, cpu_us: int) -> void:
	_record_performance_sample(Time.get_ticks_usec(), cpu_us)


func _record_performance_sample(now_usec: int, cpu_us: int) -> void:
	if _performance_last_frame_usec == 0:
		_performance_last_frame_usec = now_usec
		return
	var frame_seconds: float = maxf(float(now_usec - _performance_last_frame_usec) / 1000000.0, 0.0)
	_performance_last_frame_usec = now_usec
	_performance_elapsed += frame_seconds
	_performance_cpu_us += cpu_us
	_performance_frame_ms.append(frame_seconds * 1000.0)
	if _performance_elapsed < 1.0:
		return
	var count: int = _performance_frame_ms.size()
	_performance_frame_ms.sort()
	var render_texture: ViewportTexture = get_viewport().get_texture()
	_performance_metrics = {"fps": Engine.get_frames_per_second(), "frame_ms": _performance_elapsed * 1000.0 / count,
		"p95_frame_ms": _performance_frame_ms[mini(int(count * 0.95), count - 1)],
		"client_cpu_ms": float(_performance_cpu_us) / float(count) / 1000.0,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"render_primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
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
	stage_panel = _panel(ui, Rect2(482, 8, 316, 70))
	hud_controls.append(stage_panel)
	round_label = _label(stage_panel, "", Rect2(0, 3, 316, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	phase_label = _label(stage_panel, "", Rect2(0, 19, 316, 28), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var track: ColorRect = ColorRect.new()
	track.color = Color(0, 0, 0, 0.5)
	track.position = Vector2(20, 52)
	track.size = Vector2(276, 8)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_panel.add_child(track)
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
	_build_boss_hud()


## Barra Épica de Vida do Boss no topo da tela (estilo Raid Boss / TFT)
func _build_boss_hud() -> void:
	boss_bar_panel = _panel(ui, Rect2(304, 8, 672, 56), 0.92, 10)
	boss_bar_panel.visible = false
	boss_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_controls.append(boss_bar_panel)
	var style: StyleBoxFlat = boss_bar_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = Color(GOLD, 0.9)
		style.set_border_width_all(2)
	
	boss_bar_title = _label(boss_bar_panel, "👑 O CRIADOR DA ARENA (BOSS)", Rect2(14, 3, 340, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	boss_bar_timer_label = _label(boss_bar_panel, "", Rect2(360, 3, 298, 18), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	
	boss_bar_track = ColorRect.new()
	boss_bar_track.color = Color(0.04, 0.02, 0.06, 0.95)
	boss_bar_track.position = Vector2(14, 22)
	boss_bar_track.size = Vector2(644, 13)
	boss_bar_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_panel.add_child(boss_bar_track)
	
	boss_bar_ghost = ColorRect.new()
	boss_bar_ghost.color = Color(0.95, 0.75, 0.25, 0.8)
	boss_bar_ghost.position = Vector2.ZERO
	boss_bar_ghost.size = Vector2(644, 13)
	boss_bar_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_track.add_child(boss_bar_ghost)
	
	boss_bar_fill = ColorRect.new()
	boss_bar_fill.color = Color(0.68, 0.15, 0.95)
	boss_bar_fill.position = Vector2.ZERO
	boss_bar_fill.size = Vector2(644, 13)
	boss_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_track.add_child(boss_bar_fill)
	
	boss_bar_hp_label = _label(boss_bar_panel, "10.000 / 10.000", Rect2(14, 22, 644, 13), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	boss_bar_minions_label = _label(boss_bar_panel, "", Rect2(14, 37, 644, 14), 10, Color("c2a6ff"), HORIZONTAL_ALIGNMENT_CENTER)


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
	var capacity_pill: Panel = _panel(ui, Rect2(144, 554, 150, 34), 0.88, 8)
	var cap_frame: OrnateFrameCache = OrnateFrameCache.new()
	cap_frame.show_behind_parent = true
	cap_frame.size = capacity_pill.size
	cap_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capacity_pill.add_child(cap_frame)
	cap_frame.setup(func(canvas: CanvasItem) -> void:
		Kit.draw_ornate_panel_frame(canvas, Rect2(Vector2.ZERO, cap_frame.size), "bronze")
	)
	_icon_rect(capacity_pill, Kit.icon("ui_team"), Rect2(8, 6, 22, 22))
	capacity_title_label = _label(capacity_pill, "MEMBROS:", Rect2(34, 6, 70, 22), 12, Color("e2e8f0"))
	capacity_title_label.add_theme_constant_override("outline_size", 3)
	capacity_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	capacity_label = _label(capacity_pill, "", Rect2(106, 5, 36, 22), 14, Color("fde047"))
	capacity_label.add_theme_constant_override("outline_size", 3)
	capacity_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))

	# Pilha de moedas de ouro ilustrada atrás do mostrador de ouro (concentrada no centro com brilhos)
	gold_pile_layer = GoldPileCache.new()
	gold_pile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_pile_layer.position = Vector2(1180, 546)
	gold_pile_layer.scale = Vector2(0.9, 0.9)
	ui.add_child(gold_pile_layer)

	var gold_pill: Panel = _panel(ui, Rect2(1124, 542, 112, 38), 0.88, 19)
	gold_coin_rect = _icon_rect(gold_pill, Kit.icon("ui_coin"), Rect2(10, 5, 28, 28))
	gold_label = _label(gold_pill, "", Rect2(44, 4, 62, 28), 22, Color("fde047"))
	gold_label.add_theme_constant_override("outline_size", 3)
	gold_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	income_label = _label(ui, "", Rect2(1088, 577, 180, 18), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	income_label.mouse_filter = Control.MOUSE_FILTER_PASS

	var shop: Panel = _panel(ui, Rect2(144, 596, 940, 116), 0.85, 10)
	hud_controls.append_array([capacity_pill, gold_pile_layer, gold_pill, income_label, shop])

	capacity_button = _button(shop, "", Rect2(8, 8, 114, 48), _command.bind("upgrade_capacity", {}))
	reroll_button = _button(shop, "", Rect2(8, 60, 114, 48), _command.bind("reroll", {}))
	for button: Button in [capacity_button, reroll_button]:
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_apply_ornate_button(button, "teal")

	# Conteúdo interno do capacity_button (enquadramento com folga, fonte negrita e mini-moeda)
	var cap_content: Control = Control.new()
	cap_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_content.size = Vector2(114, 48)
	capacity_button.add_child(cap_content)
	_icon_rect(cap_content, Kit.icon("ui_expand"), Rect2(8, 14, 20, 20))
	capacity_btn_label = _label(cap_content, "ESPAÇO", Rect2(30, 14, 48, 20), 12, Color.WHITE)
	capacity_btn_label.add_theme_constant_override("outline_size", 3)
	capacity_btn_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.98))
	capacity_btn_coin = _icon_rect(cap_content, Kit.icon("ui_coin"), Rect2(80, 17, 14, 14))
	capacity_btn_cost = _label(cap_content, "8", Rect2(96, 14, 14, 20), 12, Color("fde047"))
	capacity_btn_cost.add_theme_constant_override("outline_size", 3)
	capacity_btn_cost.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.98))

	# Conteúdo interno do reroll_button
	var reroll_content: Control = Control.new()
	reroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reroll_content.size = Vector2(114, 48)
	reroll_button.add_child(reroll_content)
	_icon_rect(reroll_content, Kit.icon("ui_refresh"), Rect2(8, 14, 20, 20))
	reroll_btn_label = _label(reroll_content, "RENOVAR", Rect2(29, 14, 52, 20), 11, Color.WHITE)
	reroll_btn_label.add_theme_constant_override("outline_size", 3)
	reroll_btn_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.98))
	reroll_btn_coin = _icon_rect(reroll_content, Kit.icon("ui_coin"), Rect2(82, 17, 14, 14))
	reroll_btn_cost = _label(reroll_content, "2", Rect2(98, 14, 14, 20), 12, Color("fde047"))
	reroll_btn_cost.add_theme_constant_override("outline_size", 3)
	reroll_btn_cost.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.98))

	shop_root = _container(shop)
	var fight_plate: Panel = _panel(ui, Rect2(1092, 596, 176, 116), 0.85, 10)
	hud_controls.append(fight_plate)
	fight_button = _button(fight_plate, "", Rect2(8, 8, 160, 100), _fight)
	fight_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_ornate_button(fight_button, "gold")

	# Conteúdo interno do fight_button (enquadramento centralizado perfeito e fonte negrita)
	var fight_content: Control = Control.new()
	fight_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fight_content.size = Vector2(160, 100)
	fight_button.add_child(fight_content)
	fight_btn_icon = _icon_rect(fight_content, Kit.icon("ui_fight"), Rect2(64, 16, 32, 32))
	fight_btn_label = _label(fight_content, "LUTAR", Rect2(8, 54, 144, 34), 20, Color("fef08a"), HORIZONTAL_ALIGNMENT_CENTER)
	fight_btn_label.add_theme_constant_override("outline_size", 3)
	fight_btn_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.98))


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

	var frame: OrnateFrameCache = OrnateFrameCache.new()
	frame.show_behind_parent = true
	frame.size = btn.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(frame)
	frame.setup(func(canvas: CanvasItem) -> void:
		var is_h: bool = btn.is_hovered() and not btn.disabled
		var is_p: bool = btn.button_pressed
		Kit.draw_ornate_button_frame(canvas, Rect2(Vector2.ZERO, frame.size), theme_name, is_h, btn.disabled, is_p)
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
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = rect.size
	icon.size = rect.size
	icon.position = rect.position
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	icon.size = rect.size
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
	if lobby_backdrop != null:
		lobby_backdrop.set_mode(phase == "menu", eco_mode)
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
	capacity_label.text = "%d/%d" % [_active_count(), capacity]
	var reroll_cost: int = int(config.get("reroll_cost", 2))
	var upgrade_cost: int = int(config.get("upgrade_cost", 8))
	reroll_button.disabled = not prep or gold < reroll_cost
	if reroll_btn_cost != null:
		reroll_btn_cost.text = str(reroll_cost)
	var max_cap: int = int(config.get("max_capacity", 8))
	var capacity_maximum: bool = capacity >= max_cap
	capacity_button.disabled = not prep or capacity_maximum or gold < upgrade_cost
	if capacity_btn_label != null and capacity_btn_cost != null and capacity_btn_coin != null:
		if capacity_maximum:
			capacity_btn_label.text = "CAMPO MÁX."
			capacity_btn_label.size = Vector2(74, 20)
			capacity_btn_coin.visible = false
			capacity_btn_cost.visible = false
		else:
			capacity_btn_label.text = "ESPAÇO"
			capacity_btn_label.size = Vector2(52, 20)
			capacity_btn_coin.visible = true
			capacity_btn_cost.visible = true
			capacity_btn_cost.text = str(upgrade_cost)
	var active_units: int = _active_count()
	fight_button.disabled = not prep or active_units == 0
	if fight_btn_label != null:
		if phase == "combat":
			fight_btn_label.text = "EM COMBATE"
			fight_btn_label.add_theme_color_override("font_color", Color("94a3b8"))
		elif active_units == 0 and prep:
			fight_btn_label.text = "RECRUTE"
			fight_btn_label.add_theme_color_override("font_color", Color("38bdf8"))
		else:
			fight_btn_label.text = "LUTAR"
			fight_btn_label.add_theme_color_override("font_color", Color("fef08a"))
	_refresh_status()
	_refresh_boss_hud(is_boss_round, phase)
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


func _refresh_boss_hud(is_boss_round: bool, phase: String) -> void:
	if boss_bar_panel == null:
		return
	if is_boss_round and phase in ["preparation", "combat"]:
		boss_bar_panel.visible = true
		if stage_panel != null:
			stage_panel.visible = false
		if status_panel != null:
			status_panel.visible = false
		var boss_unit: Dictionary = {}
		var minions_alive: Array[String] = []
		for u: Dictionary in state.get("combat", {}).get("units", []):
			if str(u.get("key", "")) == "boss_dev" or bool(u.get("is_boss", false)):
				boss_unit = u
			elif str(u.get("key", "")) == "slime_lodo_olho" and bool(u.get("alive", true)):
				minions_alive.append("Lodo Negro")
			elif str(u.get("key", "")) == "monstro_olho_tentaculos" and bool(u.get("alive", true)):
				minions_alive.append("Aberração Cósmica")
		if boss_unit.is_empty():
			for u: Dictionary in state.get("enemy", {}).get("units", []):
				if str(u.get("key", "")) == "boss_dev" or bool(u.get("is_boss", false)):
					boss_unit = u
		if not boss_unit.is_empty():
			var b_hp: float = maxf(0.0, float(boss_unit.get("hp", 0)))
			var b_max: float = maxf(1.0, float(boss_unit.get("max_hp", 10000)))
			var b_ratio: float = clampf(b_hp / b_max, 0.0, 1.0)
			boss_bar_fill.size = Vector2(644.0 * b_ratio, 13)
			boss_bar_ghost.size = Vector2(644.0 * maxf(b_ratio, boss_ghost_hp_ratio), 13)
			boss_ghost_hp_ratio = move_toward(boss_ghost_hp_ratio, b_ratio, 0.04)
			var is_enraged: bool = bool(boss_unit.get("boss_enraged", false))
			if is_enraged:
				boss_bar_title.text = "🔥 O CRIADOR DA ARENA · EM FÚRIA! 🔥"
				boss_bar_title.add_theme_color_override("font_color", Color("ff3322"))
				boss_bar_fill.color = Color("ff2211")
				var b_style: StyleBoxFlat = boss_bar_panel.get_theme_stylebox("panel") as StyleBoxFlat
				if b_style != null:
					b_style.border_color = Color("ff4422")
			else:
				boss_bar_title.text = "👑 O CRIADOR DA ARENA (BOSS)"
				boss_bar_title.add_theme_color_override("font_color", GOLD)
				boss_bar_fill.color = Color(0.68, 0.15, 0.95)
				var b_style: StyleBoxFlat = boss_bar_panel.get_theme_stylebox("panel") as StyleBoxFlat
				if b_style != null:
					b_style.border_color = Color(GOLD, 0.9)
			boss_bar_hp_label.text = "%d / %d (%d%%)" % [roundi(b_hp), roundi(b_max), roundi(b_ratio * 100.0)]
			var remaining: int = maxi(0, int(ceil(float(state.get("phase_remaining", 0)))))
			if boss_bar_timer_label != null:
				boss_bar_timer_label.text = ("PREPARAÇÃO · %ds" % remaining) if phase == "preparation" else ("BATALHA DE BOSS · %ds" % remaining)
			if minions_alive.is_empty():
				boss_bar_minions_label.text = "⚡ TELEPORTE: A CADA 4s · SEM LACAIOS ATIVOS" if phase == "combat" else "AGUARDANDO O COMBATE..."
			else:
				boss_bar_minions_label.text = "⚡ TELEPORTE: A CADA 4s · LACAIO NA RETAGUARDA (AGGRO): " + ", ".join(minions_alive)
			if bot_lives_label != null:
				bot_lives_label.text = "DESAFIO PVE (SEM PERDA DE VIDA)"
	else:
		boss_bar_panel.visible = false
		if stage_panel != null and phase != "menu":
			stage_panel.visible = true
		if status_panel != null and phase != "menu":
			status_panel.visible = true


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

	var frame: OrnateFrameCache = OrnateFrameCache.new()
	frame.show_behind_parent = true
	frame.size = rect.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(frame)
	button.set_meta("ornate_frame", frame)
	frame.setup(func(canvas: CanvasItem) -> void:
		var is_h: bool = button.is_hovered() and not button.disabled
		Kit.draw_ornate_card_frame(canvas, Rect2(Vector2.ZERO, frame.size), rarity_key, is_h, button.disabled)
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
		var skill_desc: String = str(KIT_TEXT.get(key, ""))
		var tags_names: Array[String] = []
		for t: String in tags:
			tags_names.append(str(SYNERGY_INFO.get(t, {}).get("name", t.capitalize())))
		var tags_text: String = " · ".join(tags_names)
		var hero_header: String = str(offer.get("name", "")).to_upper()
		if owned:
			hero_header += " (Nível %d)" % _level_for_copies(copies)
		button.tooltip_text = "%s\n[%s]\n✦ HABILIDADE: %s\n%s" % [hero_header, tags_text, skill_desc, description]
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
	ShopCardCache.attach(button, ui.theme)
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
	audio.stop_bob_music()
	visual_pulls.clear()
	for effects: Array in [kit_effects, shield_waves, slashes, floating, level_bursts, blast_zones, boss_telegraphs, boss_summon_portals]:
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
	audio.stop_bob_music()
	boss_result_view_mode = "rewards"
	if opponent_name_label != null and is_instance_valid(opponent_name_label):
		opponent_name_label.text = opponent_title
	selected_id = -1
	selected_items.clear()
	target_hit_seq.clear()
	for effects: Variant in [visual_ground, visual_directions, visual_moves, visual_attacks, visual_hits, visual_deaths, visual_pulls, shield_waves, slashes, floating, log_lines, level_bursts, kit_effects, blast_zones, boss_telegraphs, boss_summon_portals, lula_descents, ascended_units]:
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
	for effects: Variant in [visual_ground, visual_moves, visual_attacks, visual_hits, visual_deaths, visual_pulls, shield_waves, slashes, floating, level_bursts, kit_effects, blast_zones, boss_telegraphs, boss_summon_portals, lula_descents]:
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
	for effects: Array in [floating, shield_waves, slashes, level_bursts, kit_effects, blast_zones, boss_telegraphs, boss_summon_portals]:
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
	for uid: int in lula_descents.keys():
		lula_descents[uid]["remaining"] = maxf(0.0, float(lula_descents[uid]["remaining"]) - delta)
		if float(lula_descents[uid]["remaining"]) <= 0.0:
			lula_descents.erase(uid)


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


func _sync_singer_music() -> void:
	if _phase() != "combat":
		audio.stop_singer_music()
		return
	var best_singer: Dictionary = {}
	var best_score: float = -1.0
	for u: Dictionary in state.get("combat", {}).get("units", []):
		if not bool(u.get("alive", true)):
			continue
		var u_key: String = str(u.get("key", ""))
		if u_key in SINGER_KEYS:
			var lvl: int = clampi(int(u.get("level", 1)), 1, 3)
			var hp: float = float(u.get("max_hp", 0.0))
			var atk: float = float(u.get("attack_damage", 0.0))
			# Nível de estrelas tem peso decisivo absoluto (3★ > 2★ > 1★), desempate por vida e dano
			var score: float = float(lvl) * 1000000.0 + hp * 10.0 + atk
			if score > best_score:
				best_score = score
				best_singer = u
	if not best_singer.is_empty():
		var s_key: String = str(best_singer.get("key", ""))
		var s_lvl: int = clampi(int(best_singer.get("level", 1)), 1, 3)
		audio.play_singer_music(s_key, s_lvl)
	else:
		audio.stop_singer_music()


func _sync_bob_marley_music() -> void:
	_sync_singer_music()


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
		_sync_singer_music()
	elif kind == "round_finished":
		character_player.clear()
		passive_character_stamps.clear()
		audio.stop_singer_music()
		audio.play_cue("win" if int(event.get("winner", -1)) == 0 else "lose")
	elif kind == "preparation_started":
		character_player.clear()
		passive_character_stamps.clear()
		audio.stop_singer_music()
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
		var src_key: String = str(source.get("key", ""))
		if src_key == "caramelo":
			audio.play_cue("bite")
		elif src_key == "zumbi":
			audio.play_cue("thrust")
		elif src_key == "neymar":
			audio.play_cue("shoot")
		elif src_key == "elon":
			audio.play_cue("rocket")
		else:
			audio.play_cue("hit")
	if kind == "dance_shield" and not source.is_empty():
		shield_waves.append({"ground": visual_ground.get(int(source["id"]), Board.ground(_cell(source.get("cell", [])))), "life": 0.9, "duration": 0.9})
		if int(source["id"]) == selected_id:
			floating.append({"text": "ESCUDO %d" % roundi(float(event.get("amount", 0))), "position": _head_of(source) + Vector2(-30, -6), "color": GOLD, "life": 1.0, "size": 15})
	if kind == "boss_cast" and not source.is_empty():
		var u_id: int = int(source["id"])
		var cast_dir: String = "south-west"
		if event.has("to") and event.has("from"):
			var c_from: Variant = event.get("from")
			var c_to: Variant = event.get("to")
			var from_x: int = int(c_from.x) if (c_from is Vector2i or c_from is Vector2) else (int(c_from[0]) if c_from is Array and c_from.size() > 0 else 0)
			var to_x: int = int(c_to.x) if (c_to is Vector2i or c_to is Vector2) else (int(c_to[0]) if c_to is Array and c_to.size() > 0 else 0)
			cast_dir = "south-east" if to_x >= from_x else "south-west"
		visual_directions[u_id] = cast_dir
		visual_attacks[u_id] = {"remaining": 0.55, "duration": 0.55, "direction": Vector2.RIGHT if "east" in cast_dir else Vector2.LEFT}
		var spell_name: String = str(event.get("spell", ""))
		if spell_name == "fire_tornado":
			audio.play_cue("tornado")
		else:
			audio.play_cue("boss_spell")
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
	if kind == "boss_spell_telegraph" and event.has("center"):
		var tele_cell: Vector2i = _cell(event.get("center", []))
		boss_telegraphs.append({
			"spell": str(event.get("spell", "")),
			"cell": tele_cell,
			"radius": int(event.get("radius", 1)),
			"duration": float(event.get("duration", 0.8)),
			"life": float(event.get("duration", 0.8))
		})
	if kind == "boss_enrage":
		shake_remaining = 0.45
		var b_source: Dictionary = _unit_by_id(int(event.get("boss_id", -1)))
		var b_pos: Vector2 = _head_of(b_source) if not b_source.is_empty() else Vector2(640, 200)
		floating.append({"text": "🔥 FÚRIA DO CRIADOR! 🔥", "position": b_pos + Vector2(-60, -25), "color": Color("ff3311"), "life": 1.5, "duration": 1.5, "size": 18, "critical": true})
		log_lines.append("🔥 [FÚRIA] O Criador entrou em fúria aos 40% de HP! Velocidade aumentada!")
	if kind == "boss_shockwave" and event.has("center"):
		shake_remaining = 0.35
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 2)), "life": 0.85, "duration": 0.85, "color_primary": Color(1.0, 0.25, 0.1, 0.5), "color_border": Color(1.0, 0.85, 0.2, 0.95)})
	if kind == "red_fire_explosion" and event.has("center"):
		audio.play_cue("explosion")
		shake_remaining = 0.24
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 1)), "life": 0.75, "duration": 0.75, "color_primary": Color(1.0, 0.18, 0.08, 0.48), "color_border": Color(1.0, 0.55, 0.2, 0.95)})
		kit_effects.append({"kind": "red_explosion", "position": Board.project(Board.ground(_cell(event["center"]))), "life": 0.65, "duration": 0.65, "critical": false})
	if kind == "purple_fire_explosion" and event.has("center"):
		audio.play_cue("explosion")
		shake_remaining = 0.22
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 1)), "life": 0.75, "duration": 0.75, "color_primary": Color(0.68, 0.2, 0.95, 0.45), "color_border": Color(0.9, 0.55, 1.0, 0.9)})
		kit_effects.append({"kind": "purple_explosion", "position": Board.project(Board.ground(_cell(event["center"]))), "life": 0.65, "duration": 0.65, "critical": false})
	if kind == "fire_tornado" and event.has("center"):
		audio.play_cue("tornado")
		shake_remaining = 0.28
		blast_zones.append({"cell": event["center"], "radius": int(event.get("radius", 1)), "life": 1.05, "duration": 1.05, "color_primary": Color(1.0, 0.35, 0.1, 0.45), "color_border": Color(1.0, 0.75, 0.2, 0.9)})
		kit_effects.append({"kind": "fire_tornado", "position": Board.project(Board.ground(_cell(event["center"]))), "life": 0.95, "duration": 0.95, "critical": false})
	if kind == "boss_teleport":
		var boss_id: int = int(event.get("boss_id", -1))
		var dest_cell: Vector2i = _cell(event.get("to", []))
		var from_cell: Vector2i = _cell(event.get("from", []))
		visual_ground[boss_id] = Board.ground(dest_cell)
		kit_effects.append({"kind": "boss_teleport", "position": Board.project(Board.ground(from_cell)), "life": 0.55, "duration": 0.55, "critical": false})
		kit_effects.append({"kind": "boss_teleport_land", "position": Board.project(Board.ground(dest_cell)), "life": 0.55, "duration": 0.55, "critical": false})
		floating.append({"text": "⚡ TELEPORTE! ⚡", "position": Board.project(Board.ground(dest_cell)) + Vector2(-28, -42), "color": Color("c084fc"), "life": 1.2, "duration": 1.2, "size": 15, "critical": true})
		audio.play_cue("boss_spell")
		shake_remaining = 0.22
		log_lines.append("⚡ [TELEPORTE] O Criador se teletransportou para um novo setor da arena!")
	if kind == "unit_displaced":
		if str(event.get("reason", "")) != "boss_teleport":
			var victim: Dictionary = _unit_by_id(int(event.get("unit_id", -1)))
			if not victim.is_empty():
				floating.append({"text": "ARREMESSADO!", "position": _head_of(victim) + Vector2(-22, -8), "color": Color("ff9944"), "life": 0.9, "duration": 0.9, "size": 13})
				visual_pulls[int(victim["id"])] = {"from": Board.ground(_cell(event.get("from", []))), "to": Board.ground(_cell(event.get("to", []))), "remaining": 0.35, "duration": 0.35}
	if kind == "boss_summon" and event.has("cell"):
		kit_effects.append({"kind": "boss_summon", "position": Board.project(Board.ground(_cell(event["cell"]))) + Vector2(0, -10), "life": 0.85, "duration": 0.85, "critical": false})
		boss_summon_portals.append({"cell": _cell(event["cell"]), "ground": Board.ground(_cell(event["cell"])), "duration": 1.4, "life": 1.4, "key": str(event.get("key", ""))})
		floating.append({"text": "⚡ LACAIO NA RETAGUARDA! (PROVOCAÇÃO) ⚡", "position": Board.project(Board.ground(_cell(event["cell"]))) + Vector2(-54, -40), "color": Color("f87171"), "life": 1.6, "duration": 1.6, "size": 14, "critical": true})
		audio.play_cue("boss_spell")
		shake_remaining = 0.2
		log_lines.append("⚔️ [LACAIO] O Criador invocou um monstro na retaguarda! Todas as tropas foram provocadas!")
	if kind in ["hit", "execute"] and not target.is_empty() and source.get("key", "") not in ["caramelo", "zumbi"]:
		slashes.append({"position": _head_of(target) + Vector2(0, 24), "life": 0.2, "critical": bool(event.get("critical", false)), "seed": randf() * TAU})
		visual_hits[int(target["id"])] = 0.12
	if kind in ["ball_hit", "rocket_hit", "mini_rocket_hit", "splash", "smoke_hit", "lasso_hit", "purple_fire_hit", "red_fire_hit", "fire_tornado_hit"] and not target.is_empty():
		visual_hits[int(target["id"])] = 0.12
	if kind in ["hit", "execute"] and not target.is_empty():
		visual_hits[int(target["id"])] = 0.12
		if kind == "execute":
			audio.play_cue("super_bite")
		elif bool(event.get("critical", false)):
			audio.play_cue("crit")
		elif str(source.get("key", "")) == "caramelo":
			audio.play_cue("bite")
		elif str(source.get("key", "")) == "zumbi":
			audio.play_cue("thrust")
		else:
			audio.play_cue("hit")
	if kind == "death" and not target.is_empty():
		visual_deaths[int(target["id"])] = 0.6
		audio.play_cue("death")
		if str(target.get("key", "")) in SINGER_KEYS:
			_sync_singer_music()
	if kind == "revive":
		audio.play_cue("revive")
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
	elif (kind in ["hit", "reggae_hit", "reggae_impact"] and (key == "bob_marley" or str(source.get("key", "")) == "bob_marley")):
		effect_kind = "reggae_impact"
		duration = 0.42
		if not target.is_empty():
			target_point = Board.project(_ground_of(target)) + Vector2(0, -21)
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
	elif kind == "reviving":
		var target_id: int = int(target.get("id", -1))
		visual_deaths.erase(target_id)
		var dur: float = float(event.get("duration", 1.0))
		var r_cell: Vector2i = _cell(event.get("cell", target.get("cell", [])))
		var r_ground: Vector2 = Board.ground(r_cell)
		lula_descents[target_id] = {
			"duration": dur,
			"remaining": dur,
			"cell": r_cell,
			"ground": r_ground
		}
		floating.append({"text": "✨ DESCENDO DOS CÉUS... ✨", "position": Board.project(r_ground) + Vector2(-65, -70), "color": Color("fff59d"), "life": 1.0, "size": 15})
	elif kind == "revive":
		effect_kind = "revive"
		duration = 1.0
		var target_id: int = int(target.get("id", -1))
		visual_deaths.erase(target_id)
		lula_descents.erase(target_id)
		ascended_units[target_id] = true
		floating.append({"text": "😇 VOLTA POR CIMA DIVINA!", "position": target_point + Vector2(-65, -55), "color": Color("86f6a5"), "life": 1.4, "size": 17})
		floating.append({"text": "⚔ +25% DANO DO GRUPO (5s)", "position": target_point + Vector2(-70, -34), "color": Color("ffd700"), "life": 1.5, "size": 14})
		floating.append({"text": "⚡ FRENESI DIVINO (CRÍTICO 100%)", "position": target_point + Vector2(-80, -12), "color": Color("ffe082"), "life": 1.6, "size": 14})
		shield_waves.append({"ground": target_point, "life": 0.8, "duration": 0.8, "team": target.get("team", 0), "color": Color("ffd700")})
	elif kind == "lula_ascended":
		var target_id: int = int(event.get("unit_id", -1))
		ascended_units[target_id] = true
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
			data["modulate"] = Color(0.35, 0.92, 0.45, 0.65)
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
		var critical: bool = bool(effect.get("critical", false))
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
				for puff_i: int in range(6):
					var puff_ang: float = TAU * float(puff_i) / 6.0 + progress * 1.5
					var puff_dist: float = 10.0 + progress * 18.0
					var puff_p: Vector2 = point + Vector2(cos(puff_ang) * 1.4, sin(puff_ang) * 0.8) * puff_dist
					canvas.draw_circle(puff_p, 14.0 * (0.8 + 0.2 * sin(progress * PI)), Color(0.24, 0.82, 0.36, alpha * 0.42))
					canvas.draw_circle(puff_p, 8.0 * (0.8 + 0.2 * sin(progress * PI)), Color(0.38, 0.95, 0.48, alpha * 0.25))
			"reggae_impact":
				var b_rad: float = 14.0 + progress * 28.0
				# 3 anéis de choque com as cores autênticas da Jamaica/Rastafari: Verde, Ouro e Vermelho
				canvas.draw_arc(point, b_rad * 1.15, 0, TAU, 22, Color(REGGAE_GREEN, alpha * 0.85), 2.2, true)
				canvas.draw_arc(point, b_rad * 0.82, 0, TAU, 20, Color(REGGAE_GOLD, alpha * 0.9), 2.5, true)
				canvas.draw_arc(point, b_rad * 0.48, 0, TAU, 18, Color(REGGAE_RED, alpha * 0.95), 2.8, true)
				if bob_reggae_note_tex != null:
					var r_sz: Vector2 = Vector2(24, 24) * (0.8 + progress * 0.9)
					var r_rot: float = sin(progress * PI) * 0.5
					canvas.draw_set_transform(point, r_rot, Vector2.ONE)
					canvas.draw_texture_rect(bob_reggae_note_tex, Rect2(-r_sz * 0.5, r_sz), false, Color(1, 1, 1, alpha * 0.95))
					canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var r_font: Font = ThemeDB.fallback_font
				for spk_i: int in range(6):
					var spk_ang: float = TAU * float(spk_i) / 6.0 + progress * 2.2
					var spk_p: Vector2 = point + Vector2(cos(spk_ang), sin(spk_ang)) * (b_rad * 0.9)
					var note_c: String = "♪" if spk_i % 2 == 0 else "♫"
					var col_c: Color = [REGGAE_GREEN, REGGAE_GOLD, REGGAE_RED][spk_i % 3]
					canvas.draw_string_outline(r_font, spk_p, note_c, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, 2, Color(0, 0, 0, 0.7 * alpha))
					canvas.draw_string(r_font, spk_p, note_c, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(col_c, alpha))
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
			"boss_teleport":
				var tp_rad: float = 24.0 * (1.0 - progress)
				canvas.draw_arc(point, tp_rad, 0, TAU, 24, Color(0.8, 0.3, 1.0, alpha), 3.0, true)
				canvas.draw_circle(point, maxf(1.0, 8.0 * (1.0 - progress)), Color(1.0, 0.7, 1.0, alpha * 0.9))
			"boss_teleport_land":
				var land_rad: float = 28.0 * progress
				canvas.draw_arc(point, land_rad, 0, TAU, 24, Color(0.6, 0.2, 0.9, alpha), 3.5, true)
				canvas.draw_arc(point, land_rad * 0.6, 0, TAU, 18, Color(1.0, 0.8, 0.3, alpha * 0.8), 2.0, true)


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
		"fire_tornado": "Criador: furacão de fogo", "boss_summon": "Criador: invocou monstro", "boss_teleport": "Criador: teletransporte",
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
	# Arte/vídeo já compõem o fundo. Somente sombrear a faixa de navegação.
	var clear: Color = Color(0.02, 0.01, 0.05, 0.0)
	var shade: Color = Color(0.02, 0.01, 0.05, 0.62)
	draw_polygon(PackedVector2Array([Vector2(0, 565), Vector2(1280, 565), Vector2(1280, 720), Vector2(0, 720)]),
		PackedColorArray([clear, clear, shade, shade]))


func _refresh_lobby() -> void:
	var signature: String = "%s_%s_%s_%d_%s_%d_%s_%s_%s_%s_%s_%s" % [
		lobby_subview, lobby_hero_synergy_filter, lobby_selected_hero_key,
		lobby_preview_level, lobby_preview_mode, target_fps, str(eco_mode), str(audio.enabled), str(show_performance_diagnostics),
		str(lobby_heroes_detail_open), lobby_heroes_search, lobby_heroes_status_filter
	]
	if signature == lobby_signature:
		return
	lobby_signature = signature
	_clear(lobby_root)

	match lobby_subview:
		"none":
			audio.stop_singer_music()
			_refresh_lobby_main()
		"heroes":
			if lobby_selected_hero_key == "bob_marley":
				audio.play_bob_music(lobby_preview_level)
			elif lobby_selected_hero_key == "snoop":
				audio.play_snoop_music(lobby_preview_level)
			else:
				audio.stop_singer_music()
			_refresh_lobby_heroes()
		"help":
			_refresh_lobby_help()
		"settings":
			audio.stop_singer_music()
			_refresh_lobby_settings()
		"matchmaking":
			_refresh_lobby_matchmaking()


func _refresh_lobby_main() -> void:
	# Pílula de Otimização & Desempenho
	var badge_panel: Panel = _panel(lobby_root, Rect2(24, 16, 190, 38), 0.82, 19)
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

	var help: Button = _button(lobby_root, "? COMO JOGAR", Rect2(24, 66, 190, 38), func() -> void:
		lobby_subview = "help"
		lobby_signature = ""
		_refresh())
	help.add_theme_font_size_override("font_size", 13)

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
	var settings_btn: Button = _button(lobby_root, "⚙ CONFIGURAÇÕES", Rect2(302, 624, 260, 64), func() -> void:
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


func _refresh_lobby_help() -> void:
	var modal: Panel = _panel(lobby_root, Rect2(340, 190, 600, 340), 0.94, 14)
	_label(modal, "COMO JOGAR", Rect2(24, 18, 500, 32), 24, GOLD)
	_button(modal, "X", Rect2(534, 14, 42, 38), func() -> void:
		lobby_subview = "none"
		lobby_signature = ""
		_refresh())
	var tips: String = "Recrute heróis gratuitamente e posicione sua equipe nos hexágonos.\n\n2 cópias sobem para ★2; 4 cópias para ★3. A terceira cópia guarda progresso.\n\nCombine sinergias e use ouro para itens, renovar a loja e ampliar o campo.\n\nVença as rodadas para remover os corações do adversário."
	_label(modal, tips, Rect2(24, 72, 550, 240), 17, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)


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
		audio.stop_bob_music()
		lobby_subview = "none"
		lobby_signature = ""
		_refresh())


func _refresh_lobby_heroes() -> void:
	var modal: Panel = _panel(lobby_root, Rect2(36, 16, 1208, 688), 0.98, 12)
	var modal_st: StyleBoxFlat = StyleBoxFlat.new()
	modal_st.bg_color = Color(0.04, 0.12, 0.15, 0.98)
	modal_st.border_color = Color(0.12, 0.35, 0.38, 0.8)
	modal_st.set_border_width_all(1)
	modal_st.set_corner_radius_all(12)
	modal.add_theme_stylebox_override("panel", modal_st)

	if not lobby_heroes_detail_open:
		_refresh_lobby_heroes_gallery(modal)
	else:
		_refresh_lobby_heroes_sheet(modal)


## TELA 1: GALERIA DO ELENCO & MAESTRIA (Ref. 11_galeria_elenco_e_maestria.png)
func _refresh_lobby_heroes_gallery(modal: Panel) -> void:
	# 1. Barra de Navegação Superior
	var btn_voltar: Button = _button(modal, "◀ VOLTAR", Rect2(20, 14, 120, 36), func() -> void:
		audio.stop_bob_music()
		lobby_subview = "none"
		lobby_signature = ""
		_refresh())
	btn_voltar.add_theme_font_size_override("font_size", 14)
	var st_v: StyleBoxFlat = StyleBoxFlat.new()
	st_v.bg_color = Color(0.06, 0.18, 0.22, 0.8)
	st_v.border_color = Color(0.16, 0.45, 0.5)
	st_v.set_border_width_all(1)
	st_v.set_corner_radius_all(6)
	btn_voltar.add_theme_stylebox_override("normal", st_v)

	# Abas Centrais: [ ☷ HERÓIS ] [ MELHORIAS DE CLASSE ]
	var tabs_container: Panel = _panel(modal, Rect2(440, 14, 340, 36), 0.6, 6)
	var btn_herois: Button = _button(tabs_container, "☷ HERÓIS", Rect2(2, 2, 140, 32), func() -> void: pass)
	btn_herois.add_theme_font_size_override("font_size", 13)
	var st_h: StyleBoxFlat = StyleBoxFlat.new()
	st_h.bg_color = Color(0.12, 0.36, 0.4, 0.95)
	st_h.border_color = Color("5eead4")
	st_h.set_border_width_all(1)
	st_h.set_corner_radius_all(4)
	btn_herois.add_theme_stylebox_override("normal", st_h)
	btn_herois.add_theme_color_override("font_color", Color.WHITE)

	var btn_melhorias: Button = _button(tabs_container, "MELHORIAS DE CLASSE", Rect2(146, 2, 192, 32), func() -> void:
		pass)
	btn_melhorias.add_theme_font_size_override("font_size", 12)
	var st_m: StyleBoxFlat = StyleBoxFlat.new()
	st_m.bg_color = Color.TRANSPARENT
	btn_melhorias.add_theme_stylebox_override("normal", st_m)
	btn_melhorias.add_theme_color_override("font_color", Color("81a8ab"))

	# Controles Direita: Pesquisa e Filtro Dropdown
	var search_edit: LineEdit = LineEdit.new()
	search_edit.position = Vector2(850, 14)
	search_edit.size = Vector2(210, 36)
	search_edit.placeholder_text = "🔍 Pesquisar..."
	search_edit.text = lobby_heroes_search
	search_edit.add_theme_font_size_override("font_size", 13)
	var se_st: StyleBoxFlat = StyleBoxFlat.new()
	se_st.bg_color = Color(0.04, 0.12, 0.15, 0.9)
	se_st.border_color = Color(0.15, 0.4, 0.45)
	se_st.set_border_width_all(1)
	se_st.set_corner_radius_all(6)
	se_st.content_margin_left = 10
	search_edit.add_theme_stylebox_override("normal", se_st)
	search_edit.text_changed.connect(func(new_text: String) -> void:
		lobby_heroes_search = new_text
		lobby_signature = ""
		_refresh())
	modal.add_child(search_edit)

	var filter_btn: Button = _button(modal, "▼ " + ("Tudo" if lobby_heroes_status_filter == "all" else "Incompleta"), Rect2(1072, 14, 114, 36), func() -> void:
		lobby_heroes_status_filter = "incomplete" if lobby_heroes_status_filter == "all" else "all"
		lobby_signature = ""
		_refresh())
	filter_btn.add_theme_font_size_override("font_size", 13)
	var fb_st: StyleBoxFlat = StyleBoxFlat.new()
	fb_st.bg_color = Color(0.04, 0.12, 0.15, 0.9)
	fb_st.border_color = Color(0.15, 0.4, 0.45)
	fb_st.set_border_width_all(1)
	fb_st.set_corner_radius_all(6)
	filter_btn.add_theme_stylebox_override("normal", fb_st)

	# 2. Subheader de Maestria (Ref 11)
	_label(modal, "5/75 ★ TROFÉUS DE MAESTRIA", Rect2(20, 60, 450, 28), 22, GOLD)
	_label(modal, "Ganhe um troféu por vencer com cada Especialização de nível B.", Rect2(22, 88, 550, 20), 13, Color("81a8ab"))

	# Alternador Tudo / Incompleta
	var toggle_panel: Panel = _panel(modal, Rect2(1010, 64, 176, 32), 0.6, 4)
	var is_all: bool = (lobby_heroes_status_filter == "all")
	var btn_all: Button = _button(toggle_panel, "Tudo", Rect2(2, 2, 84, 28), func() -> void:
		lobby_heroes_status_filter = "all"
		lobby_signature = ""
		_refresh())
	btn_all.add_theme_font_size_override("font_size", 12)
	var st_all: StyleBoxFlat = StyleBoxFlat.new()
	st_all.bg_color = Color(0.12, 0.36, 0.4, 0.95) if is_all else Color.TRANSPARENT
	btn_all.add_theme_stylebox_override("normal", st_all)
	btn_all.add_theme_color_override("font_color", Color.WHITE if is_all else Color("81a8ab"))

	var btn_inc: Button = _button(toggle_panel, "Incompleta", Rect2(88, 2, 86, 28), func() -> void:
		lobby_heroes_status_filter = "incomplete"
		lobby_signature = ""
		_refresh())
	btn_inc.add_theme_font_size_override("font_size", 12)
	var st_inc: StyleBoxFlat = StyleBoxFlat.new()
	st_inc.bg_color = Color(0.12, 0.36, 0.4, 0.95) if not is_all else Color.TRANSPARENT
	btn_inc.add_theme_stylebox_override("normal", st_inc)
	btn_inc.add_theme_color_override("font_color", Color.WHITE if not is_all else Color("81a8ab"))

	# 3. Grade de Cards de Heróis (6 colunas)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(20, 118)
	scroll.size = Vector2(1168, 550)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	modal.add_child(scroll)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)

	# Elenco de heróis jogáveis
	for h_key: String in HERO_CATALOG_KEYS:
		if not specs.has(h_key):
			continue
		var s: UnitSpec = specs[h_key]
		var h_name: String = s.display_name.to_upper()

		if not lobby_heroes_search.is_empty():
			if not h_name.to_lower().contains(lobby_heroes_search.to_lower()):
				continue

		var card_btn: Button = Button.new()
		card_btn.custom_minimum_size = Vector2(180, 154)
		card_btn.text = ""
		card_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card_btn.pressed.connect(func() -> void:
			audio.play_cue("click")
			lobby_selected_hero_key = h_key
			lobby_heroes_detail_open = true
			lobby_signature = ""
			if h_key == "bob_marley":
				audio.play_bob_music(lobby_preview_level)
			elif h_key == "snoop":
				audio.play_snoop_music(lobby_preview_level)
			else:
				audio.stop_singer_music()
			_refresh())
		grid.add_child(card_btn)

		var card_st: StyleBoxFlat = StyleBoxFlat.new()
		card_st.bg_color = Color(0.06, 0.16, 0.19, 0.9)
		card_st.border_color = Color(0.12, 0.38, 0.42, 0.7)
		card_st.set_border_width_all(1)
		card_st.set_corner_radius_all(6)
		card_btn.add_theme_stylebox_override("normal", card_st)

		var card_hov: StyleBoxFlat = card_st.duplicate() as StyleBoxFlat
		card_hov.border_color = Color("5eead4")
		card_hov.set_border_width_all(2)
		card_hov.shadow_color = Color(0.37, 0.92, 0.83, 0.25)
		card_hov.shadow_size = 8
		card_btn.add_theme_stylebox_override("hover", card_hov)

		# Retrato do Herói
		var port_tex: Texture2D = art.portrait_for(h_key, 30, 28)
		_icon_rect(card_btn, port_tex, Rect2(12, 10, 156, 92))

		# 3 Estrelas Douradas
		_label(card_btn, "★ ★ ★", Rect2(0, 106, 180, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

		# Nome do Herói em Caixa Alta
		_label(card_btn, h_name, Rect2(0, 126, 180, 22), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# Heróis convidados e bloqueados adicionais (completando o grid como na referência 11)
	if lobby_heroes_status_filter == "all" and lobby_heroes_search.is_empty():
		var extra_heroes: Array[Dictionary] = [
			{"key": "nyx_guest", "name": "NYX", "locked": false},
			{"key": "ratna_guest", "name": "RATNA", "locked": false},
			{"key": "locked_01", "name": "BLOQUEADO", "locked": true},
			{"key": "locked_02", "name": "BLOQUEADO", "locked": true}
		]
		for ex: Dictionary in extra_heroes:
			var is_loc: bool = bool(ex.get("locked", false))
			var ex_key: String = str(ex.get("key"))
			var ex_name: String = str(ex.get("name"))

			var card_btn: Button = Button.new()
			card_btn.custom_minimum_size = Vector2(180, 154)
			card_btn.text = ""
			card_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_loc else Control.CURSOR_POINTING_HAND
			if not is_loc:
				card_btn.pressed.connect(func() -> void:
					audio.play_cue("click")
					lobby_selected_hero_key = ex_key
					lobby_heroes_detail_open = true
					lobby_signature = ""
					_refresh())
			grid.add_child(card_btn)

			var card_st: StyleBoxFlat = StyleBoxFlat.new()
			card_st.bg_color = Color(0.04, 0.08, 0.1, 0.6) if is_loc else Color(0.06, 0.16, 0.19, 0.9)
			card_st.border_color = Color(0.1, 0.15, 0.18, 0.5) if is_loc else Color(0.12, 0.38, 0.42, 0.7)
			card_st.set_border_width_all(1)
			card_st.set_corner_radius_all(6)
			card_btn.add_theme_stylebox_override("normal", card_st)

			if not is_loc:
				var card_hov: StyleBoxFlat = card_st.duplicate() as StyleBoxFlat
				card_hov.border_color = Color("5eead4")
				card_hov.set_border_width_all(2)
				card_btn.add_theme_stylebox_override("hover", card_hov)

			var p_tex: Texture2D = art.portrait_for("zumbi", 30, 28)
			_icon_rect(card_btn, p_tex, Rect2(12, 10, 156, 92))
			_label(card_btn, "☆ ☆ ☆" if is_loc else "★ ★ ★", Rect2(0, 106, 180, 18), 13, Kit.MUTED if is_loc else GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			_label(card_btn, ex_name, Rect2(0, 126, 180, 22), 15, Kit.MUTED if is_loc else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)


## TELA 2: FICHA DE COLEÇÃO & 4 TÉCNICAS (Ref. 09_ficha_nyx_colecao_e_tecnicas.png)
func _refresh_lobby_heroes_sheet(modal: Panel) -> void:
	# 1. Barra de Navegação Superior
	var btn_voltar: Button = _button(modal, "◀ VOLTAR AO ELENCO", Rect2(20, 14, 180, 36), func() -> void:
		lobby_heroes_detail_open = false
		lobby_signature = ""
		_refresh())
	btn_voltar.add_theme_font_size_override("font_size", 13)
	var st_v: StyleBoxFlat = StyleBoxFlat.new()
	st_v.bg_color = Color(0.06, 0.18, 0.22, 0.8)
	st_v.border_color = Color(0.16, 0.45, 0.5)
	st_v.set_border_width_all(1)
	st_v.set_corner_radius_all(6)
	btn_voltar.add_theme_stylebox_override("normal", st_v)

	# Mini Carrossel Horizontal de Retratos para trocar de herói com 1 clique (como no topo da Ref 09)
	var carousel_scroll: ScrollContainer = ScrollContainer.new()
	carousel_scroll.position = Vector2(214, 10)
	carousel_scroll.size = Vector2(760, 46)
	carousel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	carousel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(carousel_scroll)

	var carousel_box: HBoxContainer = HBoxContainer.new()
	carousel_box.add_theme_constant_override("separation", 8)
	carousel_scroll.add_child(carousel_box)

	for h_key: String in HERO_CATALOG_KEYS:
		var is_cur: bool = (h_key == lobby_selected_hero_key)
		var thumb_btn: Button = Button.new()
		thumb_btn.custom_minimum_size = Vector2(40, 40)
		thumb_btn.text = ""
		thumb_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		thumb_btn.pressed.connect(func() -> void:
			audio.play_cue("click")
			lobby_selected_hero_key = h_key
			lobby_signature = ""
			if h_key == "bob_marley":
				audio.play_bob_music(lobby_preview_level)
			elif h_key == "snoop":
				audio.play_snoop_music(lobby_preview_level)
			else:
				audio.stop_singer_music()
			_refresh())
		carousel_box.add_child(thumb_btn)

		var t_st: StyleBoxFlat = StyleBoxFlat.new()
		t_st.bg_color = Color(0.08, 0.2, 0.24, 0.95) if is_cur else Color(0.05, 0.12, 0.15, 0.7)
		t_st.border_color = GOLD if is_cur else Color(0.15, 0.35, 0.4)
		t_st.set_border_width_all(2 if is_cur else 1)
		t_st.set_corner_radius_all(4)
		thumb_btn.add_theme_stylebox_override("normal", t_st)

		_icon_rect(thumb_btn, art.portrait_for(h_key, 30, 28), Rect2(3, 3, 34, 34))

	# Contador de Maestria no canto superior direito
	_label(modal, "MAESTRIA · EM ESTUDO", Rect2(986, 20, 200, 22), 13, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

	var active_spec: UnitSpec = specs.get(lobby_selected_hero_key)
	var hero_name: String = active_spec.display_name.to_upper() if active_spec != null else lobby_selected_hero_key.to_upper()

	# 2. Cabeçalho do Herói (Nome grande + Estrelas + Classes + Sub-abas)
	_label(modal, hero_name + " ★★★", Rect2(326, 62, 450, 34), 28, Color.WHITE)

	# Badges de Classe / Sinergia (Duelista, Ímpeto, Atacantes, etc.)
	var badge_x: float = 328.0
	var roles_str: String = HERO_ROLES.get(lobby_selected_hero_key, "Combatente de Elite")
	var role_panel: Panel = _panel(modal, Rect2(badge_x, 102, 260, 28), 0.7, 4)
	var r_st: StyleBoxFlat = StyleBoxFlat.new()
	r_st.bg_color = Color(0.06, 0.2, 0.24, 0.6)
	r_st.border_color = Color("5eead4")
	r_st.set_border_width_all(1)
	r_st.set_corner_radius_all(4)
	role_panel.add_theme_stylebox_override("panel", r_st)
	_label(role_panel, "⚔️ " + roles_str, Rect2(8, 4, 244, 20), 12, Color("5eead4"))

	if active_spec != null:
		for tag_i: int in range(active_spec.synergy_tags.size()):
			var syn_k: String = active_spec.synergy_tags[tag_i]
			var syn_p: Panel = _panel(modal, Rect2(badge_x + 270 + tag_i * 140, 102, 132, 28), 0.7, 4)
			var sp_st: StyleBoxFlat = StyleBoxFlat.new()
			sp_st.bg_color = Color(0.06, 0.2, 0.24, 0.6)
			sp_st.border_color = GOLD
			sp_st.set_border_width_all(1)
			sp_st.set_corner_radius_all(4)
			syn_p.add_theme_stylebox_override("panel", sp_st)
			_label(syn_p, "✦ " + syn_k.capitalize(), Rect2(8, 4, 116, 20), 12, GOLD)

	# Sub-abas: [ TÉCNICAS ] [ JOGABILIDADE 🔒 ] [ PERSONALIDADE ]
	var sub_tabs_y: float = 138.0
	_label(modal, "Técnicas em estudo; combate mantém o kit atual.", Rect2(790, 144, 418, 24), 11, GOLD)
	var tab_tec: Button = _button(modal, "TÉCNICAS", Rect2(328, sub_tabs_y, 130, 32), func() -> void: pass)
	tab_tec.add_theme_font_size_override("font_size", 13)
	var tt_st: StyleBoxFlat = StyleBoxFlat.new()
	tt_st.bg_color = Color(0.08, 0.28, 0.32, 0.95)
	tt_st.border_color = Color("5eead4")
	tt_st.set_border_width_all(1)
	tt_st.set_corner_radius_all(4)
	tab_tec.add_theme_stylebox_override("normal", tt_st)
	tab_tec.add_theme_color_override("font_color", Color.WHITE)

	var tab_jog: Button = _button(modal, "JOGABILIDADE 🔒", Rect2(468, sub_tabs_y, 150, 32), func() -> void: pass)
	tab_jog.add_theme_font_size_override("font_size", 12)
	var tj_st: StyleBoxFlat = StyleBoxFlat.new()
	tj_st.bg_color = Color(0.05, 0.12, 0.14, 0.5)
	tj_st.border_color = Color(0.12, 0.25, 0.3, 0.5)
	tj_st.set_border_width_all(1)
	tj_st.set_corner_radius_all(4)
	tab_jog.add_theme_stylebox_override("normal", tj_st)
	tab_jog.add_theme_color_override("font_color", Kit.MUTED)

	var tab_per: Button = _button(modal, "PERSONALIDADE", Rect2(628, sub_tabs_y, 150, 32), func() -> void: pass)
	tab_per.add_theme_font_size_override("font_size", 12)
	tab_per.add_theme_stylebox_override("normal", tj_st)
	tab_per.add_theme_color_override("font_color", Kit.MUTED)

	# 3. COLUNA ESQUERDA: PALCO DO HERÓI (Full-body, demonstração animada, seletor de nível e cosméticos)
	var stage_panel: Panel = _panel(modal, Rect2(20, 62, 290, 610), 0.72, 10)
	var stage_st: StyleBoxFlat = StyleBoxFlat.new()
	stage_st.bg_color = Color(0.03, 0.1, 0.12, 0.85)
	stage_st.border_color = Color(0.12, 0.35, 0.38, 0.6)
	stage_st.set_border_width_all(1)
	stage_st.set_corner_radius_all(8)
	stage_panel.add_theme_stylebox_override("panel", stage_st)

	# Alternador de Demonstração (▶ AÇÃO vs ★ POSE)
	var btn_action: Button = _button(stage_panel, "▶ AÇÃO", Rect2(8, 8, 132, 28), func() -> void:
		lobby_preview_mode = "action"
		lobby_signature = ""
		_refresh())
	btn_action.add_theme_font_size_override("font_size", 12)
	var btn_pose: Button = _button(stage_panel, "★ POSE", Rect2(150, 8, 132, 28), func() -> void:
		lobby_preview_mode = "pose"
		lobby_signature = ""
		_refresh())
	btn_pose.add_theme_font_size_override("font_size", 12)

	var is_act: bool = (lobby_preview_mode == "action")
	var st_act: StyleBoxFlat = StyleBoxFlat.new()
	st_act.bg_color = Color(0.12, 0.36, 0.4, 0.95) if is_act else Color(0.04, 0.1, 0.12, 0.7)
	st_act.border_color = GOLD if is_act else Color(0.15, 0.3, 0.35)
	st_act.set_border_width_all(1)
	st_act.set_corner_radius_all(4)
	btn_action.add_theme_stylebox_override("normal", st_act)
	btn_action.add_theme_color_override("font_color", GOLD if is_act else Kit.MUTED)

	var st_pos: StyleBoxFlat = StyleBoxFlat.new()
	st_pos.bg_color = Color(0.12, 0.36, 0.4, 0.95) if not is_act else Color(0.04, 0.1, 0.12, 0.7)
	st_pos.border_color = GOLD if not is_act else Color(0.15, 0.3, 0.35)
	st_pos.set_border_width_all(1)
	st_pos.set_corner_radius_all(4)
	btn_pose.add_theme_stylebox_override("normal", st_pos)
	btn_pose.add_theme_color_override("font_color", GOLD if not is_act else Kit.MUTED)

	# Canvas do Sprite Animado
	hero_preview_control = Control.new()
	hero_preview_control.position = Vector2(8, 44)
	hero_preview_control.size = Vector2(274, 250)
	hero_preview_control.clip_contents = true
	hero_preview_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_preview_control.draw.connect(_draw_hero_preview.bind(hero_preview_control))
	stage_panel.add_child(hero_preview_control)

	# Seletor de Nível (1, 2, 3)
	var lvl_colors: Array[Color] = [Color("c58b4a"), Color("dfe7ef"), Color("f4d58a")]
	for l_idx: int in range(3):
		var lvl: int = l_idx + 1
		var is_cur_lvl: bool = (lobby_preview_level == lvl)
		var btn_lvl: Button = _button(stage_panel, "%s NÍVEL %d" % ["★".repeat(lvl), lvl], Rect2(8 + l_idx * 92, 302, 88, 30), func() -> void:
			lobby_preview_level = lvl
			lobby_signature = ""
			if lobby_selected_hero_key == "bob_marley":
				audio.play_bob_music(lvl)
			elif lobby_selected_hero_key == "snoop":
				audio.play_snoop_music(lvl)
			_refresh())
		btn_lvl.add_theme_font_size_override("font_size", 11)
		var st_lvl: StyleBoxFlat = StyleBoxFlat.new()
		st_lvl.bg_color = Color(0.15, 0.32, 0.36, 0.95) if is_cur_lvl else Color(0.04, 0.1, 0.12, 0.6)
		st_lvl.border_color = lvl_colors[l_idx] if is_cur_lvl else Color(0.15, 0.3, 0.35)
		st_lvl.set_border_width_all(2 if is_cur_lvl else 1)
		st_lvl.set_corner_radius_all(4)
		btn_lvl.add_theme_stylebox_override("normal", st_lvl)
		btn_lvl.add_theme_color_override("font_color", lvl_colors[l_idx] if is_cur_lvl else Kit.MUTED)

	# 4 Círculos de Cosméticos / Skins [ C ] [ 🔒 ] [ 🔒 ] [ 🔒 ] (como no rodapé do modelo na Ref 09)
	var skin_y: float = 340.0
	for sk_i: int in range(4):
		var sk_panel: Panel = _panel(stage_panel, Rect2(50 + sk_i * 50, skin_y, 40, 32), 0.7, 16)
		var sk_st: StyleBoxFlat = StyleBoxFlat.new()
		sk_st.bg_color = Color(0.1, 0.28, 0.32, 0.9) if sk_i == 0 else Color(0.04, 0.08, 0.1, 0.6)
		sk_st.border_color = GOLD if sk_i == 0 else Color(0.15, 0.25, 0.3)
		sk_st.set_border_width_all(1)
		sk_st.set_corner_radius_all(16)
		sk_panel.add_theme_stylebox_override("panel", sk_st)
		_label(sk_panel, "C" if sk_i == 0 else "🔒", Rect2(0, 4, 40, 22), 12, GOLD if sk_i == 0 else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	# Estatísticas do Herói
	var mult: float = [1.0, 1.5, 2.25][clampi(lobby_preview_level, 1, 3) - 1]
	var stats_p: Panel = _panel(stage_panel, Rect2(8, 382, 274, 218), 0.8, 6)
	var hp_v: int = roundi(_preview_max_hp(active_spec, lobby_preview_level, mult)) if active_spec != null else 600
	var atk_v: int = roundi(active_spec.attack_damage * mult) if active_spec != null else 50
	var aps_v: float = active_spec.attacks_per_second if active_spec != null else 0.85
	var rng_v: int = active_spec.attack_range if active_spec != null else 1
	var arm_v: int = roundi(active_spec.armor) if active_spec != null else 20
	var res_v: int = roundi(active_spec.resist) if active_spec != null else 20
	var crit_v: int = roundi(active_spec.crit_chance * 100) if active_spec != null else 15

	_label(stats_p, "VIDA (HP):", Rect2(10, 10, 100, 18), 12, Kit.MUTED)
	_label(stats_p, "%d" % hp_v, Rect2(90, 8, 80, 20), 15, Color("86eda5"))

	_label(stats_p, "ATAQUE:", Rect2(150, 10, 80, 18), 12, Kit.MUTED)
	_label(stats_p, "%d" % atk_v, Rect2(215, 8, 50, 20), 15, GOLD)

	_label(stats_p, "VEL. ATQ:", Rect2(10, 38, 100, 18), 12, Kit.MUTED)
	_label(stats_p, "%.2f/s" % aps_v, Rect2(90, 36, 80, 20), 13, Color("90e0ef"))

	_label(stats_p, "ALCANCE:", Rect2(150, 38, 80, 18), 12, Kit.MUTED)
	_label(stats_p, "%d hex" % rng_v, Rect2(215, 36, 50, 20), 13, Color.WHITE)

	_label(stats_p, "ARMADURA:", Rect2(10, 66, 100, 18), 12, Kit.MUTED)
	_label(stats_p, "%d" % arm_v, Rect2(90, 64, 80, 20), 13, Color("b1daff"))

	_label(stats_p, "RESISTÊNCIA:", Rect2(140, 66, 90, 18), 12, Kit.MUTED)
	_label(stats_p, "%d" % res_v, Rect2(225, 64, 40, 20), 13, Color("b1daff"))

	_label(stats_p, "CRÍTICO:", Rect2(10, 94, 100, 18), 12, Kit.MUTED)
	_label(stats_p, "%d%%" % crit_v, Rect2(90, 92, 80, 20), 13, Color("ffb703"))

	_label(stats_p, "MULTI PODER:", Rect2(140, 94, 90, 18), 12, Kit.MUTED)
	_label(stats_p, "x%1.2f" % mult, Rect2(225, 92, 40, 20), 13, lvl_colors[lobby_preview_level - 1])

	# 4. COLUNA DIREITA: AS 4 CARTAS DE TÉCNICAS COM MOLDURA DOURADA (Ref. 09)
	var tech_grid_x: float = 328.0
	var tech_grid_y: float = 180.0
	var card_w: float = 205.0
	var card_h: float = 492.0
	var card_gap: float = 12.0

	var tech_list: Array = HERO_FOUR_TECHNIQUES.get(lobby_selected_hero_key, [])
	if tech_list.is_empty():
		tech_list = [
			{"name": "TÉCNICA PRIMÁRIA", "type": "Técnica Passiva", "desc": str(KIT_TEXT.get(lobby_selected_hero_key, "Habilidade primária do herói.")), "icon": "⚡"},
			{"name": "SINERGIA DE CLASSE", "type": "Técnica Passiva", "desc": "Ganha atributos adicionais ao lutar com a equipe.\nReforço: Concede bônus de combate.", "icon": "👑"},
			{"name": "GOLPE ESPECIAL", "type": "Técnica Ativa [20/50 Mana]", "desc": "Consome mana para desferir habilidade de grande impacto na arena.", "icon": "🔥"},
			{"name": "ESCALONAMENTO", "type": "Técnica Passiva", "desc": "Ganha poder crescente conforme o tempo de combate avança.", "icon": "✨"}
		]

	for t_idx: int in range(mini(4, tech_list.size())):
		var t_data: Dictionary = tech_list[t_idx]
		var t_card: Panel = _panel(modal, Rect2(tech_grid_x + t_idx * (card_w + card_gap), tech_grid_y, card_w, card_h), 0.9, 8)

		# Moldura Chanfrada em Ouro Nobre
		var tc_st: StyleBoxFlat = StyleBoxFlat.new()
		tc_st.bg_color = Color(0.04, 0.1, 0.12, 0.96)
		tc_st.border_color = GOLD
		tc_st.set_border_width_all(2)
		tc_st.set_corner_radius_all(6)
		tc_st.shadow_color = Color(0.83, 0.69, 0.22, 0.15)
		tc_st.shadow_size = 10
		t_card.add_theme_stylebox_override("panel", tc_st)

		# Losango no Topo com Ícone
		var dia_panel: Panel = Panel.new()
		dia_panel.position = Vector2(card_w * 0.5 - 18, 12)
		dia_panel.size = Vector2(36, 36)
		var dia_st: StyleBoxFlat = StyleBoxFlat.new()
		dia_st.bg_color = Color(0.18, 0.14, 0.08, 0.95)
		dia_st.border_color = GOLD
		dia_st.set_border_width_all(2)
		dia_st.set_corner_radius_all(4)
		dia_panel.add_theme_stylebox_override("panel", dia_st)
		dia_panel.rotation_degrees = 45.0
		t_card.add_child(dia_panel)

		_label(t_card, str(t_data.get("icon", "✦")), Rect2(0, 16, card_w, 32), 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

		# Título da Técnica
		var title_str: String = str(t_data.get("name", "TÉCNICA")).to_upper()
		_label(t_card, title_str, Rect2(8, 66, card_w - 16, 36), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true)

		# Subtítulo (Passiva vs Ativa [Mana])
		var type_str: String = str(t_data.get("type", "Técnica Passiva"))
		var is_active_tech: bool = type_str.contains("Ativa")
		var type_color: Color = Color("38bdf8") if is_active_tech else Color("81a8ab")
		_label(t_card, type_str, Rect2(8, 104, card_w - 16, 20), 12, type_color, HORIZONTAL_ALIGNMENT_CENTER)

		# Linha Divisória Dourada Superior
		var sep_top: ColorRect = ColorRect.new()
		sep_top.color = Color(0.83, 0.69, 0.22, 0.3)
		sep_top.position = Vector2(16, 128)
		sep_top.size = Vector2(card_w - 32, 1)
		t_card.add_child(sep_top)

		# Descrição Completa das Regras
		var desc_str: String = str(t_data.get("desc", ""))
		_label(t_card, desc_str, Rect2(12, 138, card_w - 24, 300), 13, Color("cbd5e1"), HORIZONTAL_ALIGNMENT_LEFT, true)

		# Linha Divisória Inferior + "Maestria disponível ★"
		var sep_bot: ColorRect = ColorRect.new()
		sep_bot.color = Color(0.83, 0.69, 0.22, 0.3)
		sep_bot.position = Vector2(16, 452)
		sep_bot.size = Vector2(card_w - 32, 1)
		t_card.add_child(sep_bot)

		_label(t_card, "Maestria disponível ★", Rect2(0, 458, card_w, 24), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)


func _preview_max_hp(spec: UnitSpec, preview_level: int, multiplier: float) -> float:
	var index: int = clampi(preview_level, 1, 3) - 1
	if index < spec.max_hp_by_level.size():
		return float(spec.max_hp_by_level[index])
	return spec.max_hp * multiplier


func _draw_preview_vfx(canvas: CanvasItem, vfx_key: String, pos: Vector2, elapsed: float, scale_mult: float = 1.0) -> void:
	var data: Dictionary = vfx.frame_data(vfx_key, elapsed)
	if data.is_empty():
		return
	if vfx_key in ["fumaca_01", "fumaca_02"]:
		data["modulate"] = Color(0.35, 0.92, 0.45, 0.65)
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
			canvas.draw_texture_rect_region(smoke_data["texture"], Rect2(smoke_data["offset"], smoke_data["size"]), smoke_data["region"], Color(0.35, 0.92, 0.45, tint.a * 0.7))
			if cannabis_leaf_tex != null and tint.a > 0.5:
				var c_t: float = fmod(elapsed * 0.65, 1.0)
				var c_rise: float = c_t * 22.0 * cigar_scale
				var c_sway: float = sin(elapsed * 3.8) * 4.0 * cigar_scale
				var c_alpha: float = clampf(sin(c_t * PI) * 1.3, 0.0, 0.8) * tint.a
				var c_pos: Vector2 = tip_pos + Vector2(c_sway, -c_rise)
				var c_sz: float = 14.0 * cigar_scale
				canvas.draw_set_transform(c_pos.round(), sin(elapsed * 2.5) * 0.35, Vector2.ONE)
				canvas.draw_texture_rect(cannabis_leaf_tex, Rect2(-Vector2(c_sz, c_sz) * 0.5, Vector2(c_sz, c_sz)), false, Color(1, 1, 1, c_alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Desenha as notas musicais de reggae (verde, ouro e vermelho da Jamaica) do Bob Marley.
func _draw_bob_musical_notes(canvas: CanvasItem, bob_feet: Vector2, elapsed: float, scale_mult: float = 1.4, base_y: float = -34.0) -> void:
	var base_offsets: Array[Vector2] = [
		Vector2(-18.0, base_y),
		Vector2(16.0, base_y + 4.0),
		Vector2(-1.0, base_y - 8.0)
	]
	var reggae_cols: Array[Color] = [REGGAE_GREEN, REGGAE_GOLD, REGGAE_RED]
	if vfx.has_effect("notas_bob_01"):
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
				if bob_reggae_note_tex != null and n_i == 1:
					var r_pos: Vector2 = (bob_feet + base_offsets[n_i] + Vector2(sway, -rise)).round()
					var r_sz: float = 14.0 * scale_mult
					canvas.draw_set_transform(r_pos, tilt, Vector2.ONE)
					canvas.draw_texture_rect(bob_reggae_note_tex, Rect2(-Vector2(r_sz, r_sz) * 0.5, Vector2(r_sz, r_sz)), false, Color(1, 1, 1, alpha * 0.85))
					canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var music_font: Font = ThemeDB.fallback_font
	var note_chars: Array[String] = ["♪", "♫", "♪"]
	for n_i: int in range(3):
		var cycle: float = fmod(elapsed * 0.85 + float(n_i) * 0.33, 1.0)
		var rise: float = cycle * 26.0
		var sway: float = sin(elapsed * 4.2 + float(n_i) * 2.1) * 4.0
		var tilt: float = sin(elapsed * 5.0 + float(n_i) * 1.9) * 0.16
		var alpha: float = clampf(sin(cycle * PI) * 1.45, 0.25, 1.0)
		var n_pos: Vector2 = bob_feet + base_offsets[n_i] + Vector2(sway, -rise)
		if bob_reggae_note_tex != null and n_i == 1:
			var note_sz: float = 18.0 * scale_mult
			canvas.draw_set_transform(n_pos.round(), tilt, Vector2.ONE)
			canvas.draw_texture_rect(bob_reggae_note_tex, Rect2(-Vector2(note_sz, note_sz) * 0.5, Vector2(note_sz, note_sz)), false, Color(1, 1, 1, alpha))
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			canvas.draw_string_outline(music_font, n_pos, note_chars[n_i], HORIZONTAL_ALIGNMENT_CENTER, -1, int(15 * scale_mult), 3, Color(0, 0, 0, 0.85 * alpha))
			canvas.draw_string(music_font, n_pos, note_chars[n_i], HORIZONTAL_ALIGNMENT_CENTER, -1, int(15 * scale_mult), Color(reggae_cols[n_i], alpha))


## Buff visual de ritmo do Bob Marley para aliados (+30% velocidade de ataque nas cores reais da Jamaica)
func _draw_bob_song_buff(canvas: CanvasItem, ground_or_pos: Vector2, elapsed: float, scale_mult: float = 1.0, is_isometric: bool = true) -> void:
	var pulse: float = 0.91 + 0.09 * sin(elapsed * 6.5)
	# Cores oficiais do Reggae/Rastafari da Jamaica: Verde (externo), Ouro (médio), Vermelho (interno)
	var r_colors: Array[Color] = [REGGAE_GREEN, REGGAE_GOLD, REGGAE_RED]
	var radii: Array = [0.38, 0.26, 0.16] if is_isometric else [22.0, 16.0, 10.0]
	
	for c_i: int in range(3):
		var r_base: float = (radii[c_i] + (0.04 - c_i * 0.01) * sin(elapsed * 7.0 + c_i)) * pulse * scale_mult
		var ell: PackedVector2Array
		if is_isometric:
			ell = Board.ellipse(ground_or_pos, r_base, r_base * 0.58, 22)
		else:
			ell = _make_ellipse(ground_or_pos, r_base, r_base * 0.55, 22)
		ell.append(ell[0])
		# Borda de contraste preta estilo bandeira da Jamaica sob a linha colorida
		canvas.draw_polyline(ell, Color(0.06, 0.06, 0.06, 0.45), 2.4 if c_i == 0 else 1.9, true)
		canvas.draw_polyline(ell, Color(r_colors[c_i], 0.78 - float(c_i) * 0.1), 1.6, true)
	
	var center_scr: Vector2 = Board.project(ground_or_pos) if is_isometric else ground_or_pos
	var music_font: Font = ThemeDB.fallback_font
	for p_i: int in range(3):
		var p_cycle: float = fmod(elapsed * 0.9 + float(p_i) * 0.33, 1.0)
		var p_rise: float = p_cycle * (32.0 * scale_mult)
		var p_sway: float = sin(elapsed * 5.0 + float(p_i) * 2.1) * (8.0 * scale_mult)
		var p_alpha: float = clampf(sin(p_cycle * PI) * 1.5, 0.0, 1.0)
		var p_col: Color = Color(r_colors[p_i], p_alpha)
		var p_offset: Vector2 = Vector2([-14.0, 12.0, 0.0][p_i], -14.0 * scale_mult)
		var p_pos: Vector2 = center_scr + p_offset + Vector2(p_sway, -p_rise)
		var note_char: String = ["♪", "♫", "♪"][p_i]
		canvas.draw_string_outline(music_font, p_pos, note_char, HORIZONTAL_ALIGNMENT_CENTER, -1, int(13 * scale_mult), 3, Color(0, 0, 0, 0.75 * p_alpha))
		canvas.draw_string(music_font, p_pos, note_char, HORIZONTAL_ALIGNMENT_CENTER, -1, int(13 * scale_mult), p_col)
	if bob_reggae_note_tex != null:
		var n_cycle: float = fmod(elapsed * 0.75, 1.0)
		var n_rise: float = n_cycle * (38.0 * scale_mult)
		var n_sway: float = sin(elapsed * 4.0) * (6.0 * scale_mult)
		var n_alpha: float = clampf(sin(n_cycle * PI) * 1.3, 0.0, 0.85)
		var n_pos: Vector2 = center_scr + Vector2(n_sway, -18.0 * scale_mult - n_rise)
		var n_sz: float = 16.0 * scale_mult
		canvas.draw_set_transform(n_pos.round(), sin(elapsed * 3.0) * 0.25, Vector2.ONE)
		canvas.draw_texture_rect(bob_reggae_note_tex, Rect2(-Vector2(n_sz, n_sz) * 0.5, Vector2(n_sz, n_sz)), false, Color(1, 1, 1, n_alpha))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Debuff visual de lentidão do Bob Marley para inimigos (-30% desaceleração / chill nas cores profundas de dub reggae)
func _draw_bob_song_debuff(canvas: CanvasItem, ground_or_pos: Vector2, elapsed: float, scale_mult: float = 1.0, is_isometric: bool = true) -> void:
	var slow_pulse: float = 0.93 + 0.07 * sin(elapsed * 2.0)
	# Cores profundas de dub/roots reggae para desaceleração: Vermelho escuro, Ouro âmbar e Verde musgo
	var debuff_cols: Array[Color] = [Color("b71c1c"), Color("d97706"), Color("1b5e20")]
	var radii: Array = [0.36, 0.25, 0.15] if is_isometric else [22.0, 15.0, 9.0]
	
	for d_i: int in range(3):
		var r_d: float = (radii[d_i] + (0.03 - d_i * 0.01) * sin(elapsed * 2.2 + d_i)) * slow_pulse * scale_mult
		var ell: PackedVector2Array
		if is_isometric:
			ell = Board.ellipse(ground_or_pos, r_d, r_d * 0.58, 20)
		else:
			ell = _make_ellipse(ground_or_pos, r_d, r_d * 0.55, 20)
		ell.append(ell[0])
		canvas.draw_polyline(ell, Color(0.04, 0.04, 0.04, 0.4), 2.2 if d_i == 0 else 1.7, true)
		canvas.draw_polyline(ell, Color(debuff_cols[d_i], 0.68 - float(d_i) * 0.1), 1.6, true)
	
	var center_scr: Vector2 = Board.project(ground_or_pos) if is_isometric else ground_or_pos
	var music_font: Font = ThemeDB.fallback_font
	for d_i: int in range(2):
		var d_cycle: float = fmod(elapsed * 0.4 + float(d_i) * 0.5, 1.0)
		var d_fall: float = d_cycle * (18.0 * scale_mult)
		var d_sway: float = sin(elapsed * 2.0 + float(d_i) * 2.5) * (4.0 * scale_mult)
		var d_alpha: float = clampf(sin(d_cycle * PI) * 1.3, 0.0, 0.85)
		var d_col: Color = Color(debuff_cols[d_i], d_alpha)
		var d_offset: Vector2 = Vector2(-9.0 if d_i == 0 else 9.0, -28.0 * scale_mult)
		var d_pos: Vector2 = center_scr + d_offset + Vector2(d_sway, d_fall)
		var slow_char: String = "♫" if d_i == 0 else "♪"
		canvas.draw_string_outline(music_font, d_pos, slow_char, HORIZONTAL_ALIGNMENT_CENTER, -1, int(11 * scale_mult), 2, Color(0, 0, 0, 0.6 * d_alpha))
		canvas.draw_string(music_font, d_pos, slow_char, HORIZONTAL_ALIGNMENT_CENTER, -1, int(11 * scale_mult), d_col)


## Retorna a zona de fumaça ativa que cobre a unidade, ou vazio se fora da cortina.
func _unit_in_smoke_zone(unit: Dictionary) -> Dictionary:
	if _phase() != "combat":
		return {}
	var u_cell: Vector2i = _cell(unit.get("cell", []))
	for zone: Dictionary in state.get("combat", {}).get("zones", []):
		if float(zone.get("remaining", 0)) > 0.0:
			var z_cell: Vector2i = _cell(zone.get("cell", []))
			if Grid.distance(u_cell, z_cell) <= int(zone.get("radius", 2)):
				return zone
	return {}


## Desenha a fumaça verde translúcida na altura da cintura dos personagens com emotions de cannabis.
func _draw_unit_smoke_immersion(canvas: CanvasItem, feet_pos: Vector2, u_scale: float, is_ally: bool, elapsed: float) -> void:
	var waist_y: float = -20.0 * u_scale
	var mist_center: Vector2 = feet_pos + Vector2(0.0, waist_y)
	
	# Puffs ondulantes de fumaça verde translúcida ao redor da cintura e pernas
	for puff_i: int in range(4):
		var ang: float = float(puff_i) * (PI * 0.5) + elapsed * 1.8
		var dist_x: float = (16.0 + 4.0 * sin(elapsed * 2.5 + float(puff_i))) * u_scale
		var dist_y: float = (7.0 + 2.0 * cos(elapsed * 2.5 + float(puff_i))) * u_scale
		var puff_pos: Vector2 = mist_center + Vector2(cos(ang) * dist_x, sin(ang) * dist_y + 4.0 * u_scale)
		var puff_r: float = (13.0 + 3.0 * sin(elapsed * 3.0 + float(puff_i) * 1.5)) * u_scale
		canvas.draw_circle(puff_pos, puff_r, Color(0.24, 0.82, 0.36, 0.26))
		canvas.draw_circle(puff_pos, puff_r * 0.6, Color(0.38, 0.94, 0.48, 0.18))
	
	# Folha de cannabis / emotion estilizado subindo como fumaça aromática
	if cannabis_leaf_tex != null:
		var c_cycle: float = fmod(elapsed * 0.45 + (0.3 if is_ally else 0.7), 1.0)
		var c_rise: float = c_cycle * (34.0 * u_scale)
		var c_sway: float = sin(elapsed * 3.2) * (8.0 * u_scale)
		var c_alpha: float = clampf(sin(c_cycle * PI) * 1.2, 0.0, 0.85)
		var c_pos: Vector2 = mist_center + Vector2(c_sway, 6.0 * u_scale - c_rise)
		var c_size: float = 16.0 * u_scale
		canvas.draw_set_transform(c_pos.round(), sin(elapsed * 2.0) * 0.35, Vector2.ONE)
		canvas.draw_texture_rect(cannabis_leaf_tex, Rect2(-Vector2(c_size, c_size) * 0.5, Vector2(c_size, c_size)), false, Color(1, 1, 1, c_alpha))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# Bônus para aliados na fumaça (+25% velocidade de ataque)
	if is_ally:
		var speed_pulse: float = 0.85 + 0.15 * sin(elapsed * 7.0)
		var s_pts: PackedVector2Array = _make_ellipse(feet_pos + Vector2(0, waist_y * 0.5), 18.0 * u_scale * speed_pulse, 9.0 * u_scale * speed_pulse, 16)
		s_pts.append(s_pts[0])
		canvas.draw_polyline(s_pts, Color(0.35, 0.95, 0.45, 0.55), 1.6, true)
	else:
		# Penalidade para inimigos na fumaça (30% erro de ataque): névoa estonteante nos olhos
		var eye_center: Vector2 = feet_pos + Vector2(0.0, -48.0 * u_scale)
		var eye_haze: float = 0.4 + 0.2 * sin(elapsed * 4.0)
		canvas.draw_circle(eye_center, 9.0 * u_scale, Color(0.2, 0.75, 0.3, 0.22 * eye_haze))
		for h_i: int in range(3):
			var h_ang: float = elapsed * 3.5 + float(h_i) * (TAU / 3.0)
			var h_pos: Vector2 = eye_center + Vector2(cos(h_ang) * 8.0, sin(h_ang) * 4.0) * u_scale
			canvas.draw_circle(h_pos, 2.0 * u_scale, Color(0.4, 0.95, 0.5, 0.65))


## Desenha a atmosfera volumétrica e emotions de cannabis que flutuam por toda a área da cortina de fumaça.
func _draw_snoop_smoke_zone_atmosphere(canvas: CanvasItem, zone: Dictionary) -> void:
	var z_cell: Vector2i = _cell(zone.get("cell", []))
	var z_radius: int = int(zone.get("radius", 2))
	var center_ground: Vector2 = Board.ground(z_cell)
	var z_id: float = float(zone.get("id", 0))
	
	# Puffs volumétricos flutuantes à altura da cintura (meio-termo para dar profundidade de cena)
	for n_i: int in range(7):
		var n_ang: float = float(n_i) * (TAU / 7.0) + visual_time * 0.15 + z_id
		var n_dist: float = (0.28 + 0.45 * sin(float(n_i) * 2.3 + z_id)) * float(z_radius)
		var puff_ground: Vector2 = center_ground + Vector2(cos(n_ang) * n_dist, sin(n_ang) * n_dist * 0.58)
		var puff_screen: Vector2 = Board.project(puff_ground) + Vector2(sin(visual_time * 2.0 + n_i) * 5.0, -22.0 + sin(visual_time * 1.8 + n_i) * 4.0)
		var p_rad: float = 24.0 + 6.0 * sin(visual_time * 2.2 + n_i)
		canvas.draw_circle(puff_screen, p_rad, Color(0.22, 0.8, 0.32, 0.18))
		canvas.draw_circle(puff_screen, p_rad * 0.65, Color(0.35, 0.92, 0.45, 0.14))
	
	# Emotions de cannabis que sobem e dançam no ar pela área da fumaça
	if cannabis_leaf_tex != null:
		for leaf_i: int in range(6):
			var l_cycle: float = fmod(visual_time * 0.28 + float(leaf_i) * 0.166 + z_id * 0.2, 1.0)
			var l_ang: float = float(leaf_i) * (TAU / 6.0) + visual_time * 0.1
			var l_dist: float = (0.3 + 0.5 * sin(float(leaf_i) * 3.1)) * float(z_radius)
			var l_ground: Vector2 = center_ground + Vector2(cos(l_ang) * l_dist, sin(l_ang) * l_dist * 0.58)
			var l_rise: float = l_cycle * 42.0
			var l_sway: float = sin(visual_time * 2.6 + leaf_i) * 7.0
			var l_pos: Vector2 = Board.project(l_ground) + Vector2(l_sway, -6.0 - l_rise)
			var l_alpha: float = clampf(sin(l_cycle * PI) * 1.3, 0.0, 0.8)
			var l_sz: float = 18.0 + 4.0 * sin(float(leaf_i))
			canvas.draw_set_transform(l_pos.round(), sin(visual_time * 2.0 + leaf_i) * 0.4, Vector2.ONE)
			canvas.draw_texture_rect(cannabis_leaf_tex, Rect2(-Vector2(l_sz, l_sz) * 0.5, Vector2(l_sz, l_sz)), false, Color(1, 1, 1, l_alpha))
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Asas de anjo engraçadas brancas e douradas bem brilhantes do Lula.
func _draw_lula_angel_wings(canvas: CanvasItem, body_center: Vector2, height: float, scale_mult: float, elapsed: float, is_descending: bool, is_frenzy: bool) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var flap_freq: float = 24.0 if is_descending else (16.0 if is_frenzy else 7.5)
	var flap_angle: float = sin(elapsed * flap_freq) * (0.35 if is_descending else (0.28 if is_frenzy else 0.18))
	var wing_span: float = 38.0 * scale_mult
	var wing_height: float = 34.0 * scale_mult
	var shoulder_offset_y: float = -height * 0.52
	
	for side: int in [-1, 1]:
		var s_f: float = float(side)
		var root_pos: Vector2 = body_center + Vector2(s_f * (7.0 * scale_mult), shoulder_offset_y)
		var angle: float = (s_f * 0.32) + (s_f * flap_angle)
		
		# Keep each tip on its own side; the former cosine pointed both tips right.
		var tip: Vector2 = root_pos + Vector2(s_f * wing_span * 0.3, -wing_height).rotated(angle * 0.3)
		var mid_feather: Vector2 = root_pos + Vector2(s_f * wing_span * 0.95, -wing_height * 0.55).rotated(angle * 0.2)
		var low_feather: Vector2 = root_pos + Vector2(s_f * wing_span * 0.75, 4.0 * scale_mult).rotated(angle * 0.1)
		
		# Glow celestial de fundo
		if is_frenzy or is_descending:
			var glow_poly: PackedVector2Array = PackedVector2Array([
				root_pos,
				tip + Vector2(s_f * 6, -6),
				mid_feather + Vector2(s_f * 8, 0),
				low_feather + Vector2(s_f * 6, 6)
			])
			canvas.draw_colored_polygon(glow_poly, Color(1.0, 0.88, 0.3, 0.35 + 0.15 * sin(elapsed * 12.0)))
		
		# 1. Pena Superior (Maior)
		var poly_top: PackedVector2Array = PackedVector2Array([
			root_pos + Vector2(0, -6 * scale_mult),
			root_pos + Vector2(s_f * 12 * scale_mult, -wing_height * 0.7),
			tip,
			root_pos + Vector2(s_f * 16 * scale_mult, -wing_height * 0.35),
			root_pos
		])
		canvas.draw_colored_polygon(poly_top, Color(0.98, 0.98, 1.0, 0.96))
		var gold_edge_top: PackedVector2Array = PackedVector2Array([
			root_pos + Vector2(0, -6 * scale_mult),
			root_pos + Vector2(s_f * 12 * scale_mult, -wing_height * 0.7),
			tip
		])
		canvas.draw_polyline(gold_edge_top, Color("ffd700"), 2.2 * scale_mult, true)
		canvas.draw_circle(tip, 2.5 * scale_mult, Color("fff176"))
		
		# 2. Pena do Meio
		var poly_mid: PackedVector2Array = PackedVector2Array([
			root_pos,
			root_pos + Vector2(s_f * 16 * scale_mult, -wing_height * 0.35),
			mid_feather,
			root_pos + Vector2(s_f * 12 * scale_mult, -2 * scale_mult),
			root_pos
		])
		canvas.draw_colored_polygon(poly_mid, Color(0.96, 0.96, 0.99, 0.96))
		var gold_edge_mid: PackedVector2Array = PackedVector2Array([
			root_pos + Vector2(s_f * 16 * scale_mult, -wing_height * 0.35),
			mid_feather
		])
		canvas.draw_polyline(gold_edge_mid, Color("ffd700"), 1.8 * scale_mult, true)
		canvas.draw_circle(mid_feather, 2.0 * scale_mult, Color("fff176"))
		
		# 3. Pena Inferior
		var poly_low: PackedVector2Array = PackedVector2Array([
			root_pos + Vector2(0, 4 * scale_mult),
			root_pos + Vector2(s_f * 12 * scale_mult, -2 * scale_mult),
			low_feather,
			root_pos + Vector2(s_f * 4 * scale_mult, 8 * scale_mult)
		])
		canvas.draw_colored_polygon(poly_low, Color(0.94, 0.94, 0.98, 0.95))
		var gold_edge_low: PackedVector2Array = PackedVector2Array([
			root_pos + Vector2(s_f * 12 * scale_mult, -2 * scale_mult),
			low_feather
		])
		canvas.draw_polyline(gold_edge_low, Color("ffca28"), 1.6 * scale_mult, true)
		canvas.draw_circle(low_feather, 1.8 * scale_mult, Color("ffe082"))
		
		# Contorno nítido delineando a asa
		var outline: PackedVector2Array = PackedVector2Array([
			root_pos,
			root_pos + Vector2(0, -6 * scale_mult),
			root_pos + Vector2(s_f * 12 * scale_mult, -wing_height * 0.7),
			tip,
			mid_feather,
			low_feather,
			root_pos + Vector2(s_f * 4 * scale_mult, 8 * scale_mult)
		])
		canvas.draw_polyline(outline, Color(0.65, 0.48, 0.05, 0.75), 1.2, true)
		
		# Partículas que se desprendem
		if is_frenzy or is_descending:
			for spark_i: int in range(2):
				var sp_prog: float = fposmod(elapsed * 2.2 + float(spark_i) * 0.5, 1.0)
				var sp_pos: Vector2 = tip.lerp(tip + Vector2(s_f * 14, 18), sp_prog)
				canvas.draw_circle(sp_pos, 1.6 * (1.0 - sp_prog), Color("fff9c4"))


## Auréola (areola) celestial dourada brilhante sobre a cabeça do Lula.
func _draw_lula_halo(canvas: CanvasItem, feet_pos: Vector2, height: float, scale_mult: float, elapsed: float, is_frenzy: bool) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bob: float = sin(elapsed * 3.6) * 3.0
	var halo_center: Vector2 = feet_pos + Vector2(0, -height - 12.0 * scale_mult + bob)
	var tilt_angle: float = 0.22
	var rad_x: float = 16.0 * scale_mult
	var rad_y: float = 5.5 * scale_mult
	
	# Glow externo pulsante
	var pulse: float = 0.5 + 0.5 * sin(elapsed * 5.0)
	var glow_pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(16):
		var ang: float = TAU * float(i) / 16.0
		var pt: Vector2 = halo_center + Vector2(cos(ang) * (rad_x + 4.0), sin(ang) * (rad_y + 3.0)).rotated(tilt_angle)
		glow_pts.append(pt)
	glow_pts.append(glow_pts[0])
	canvas.draw_colored_polygon(glow_pts, Color(1.0, 0.9, 0.3, 0.24 + (0.2 if is_frenzy else 0.12) * pulse))
	
	# Anel principal da auréola
	var ring_pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var ang: float = TAU * float(i) / 24.0
		var pt: Vector2 = halo_center + Vector2(cos(ang) * rad_x, sin(ang) * rad_y).rotated(tilt_angle)
		ring_pts.append(pt)
	ring_pts.append(ring_pts[0])
	
	canvas.draw_polyline(ring_pts, Color("ffb300"), 3.2 * scale_mult, true)
	canvas.draw_polyline(ring_pts, Color("fffde7"), 1.6 * scale_mult, true)
	
	# Centelhas cintilantes nas extremidades
	var left_tip: Vector2 = halo_center + Vector2(-rad_x, 0).rotated(tilt_angle)
	var right_tip: Vector2 = halo_center + Vector2(rad_x, 0).rotated(tilt_angle)
	canvas.draw_circle(left_tip, 2.0 * scale_mult * (0.8 + 0.3 * sin(elapsed * 8.0)), Color("ffffff"))
	canvas.draw_circle(right_tip, 2.0 * scale_mult * (0.8 + 0.3 * cos(elapsed * 8.0)), Color("ffffff"))


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
				_draw_bob_song_buff(canvas, feet, visual_time, 1.25 * LEVEL_SCALE[lobby_preview_level - 1], false)

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
			canvas.draw_polyline(s_ring, Color(0.28, 0.95, 0.45, 0.65), 1.8, true)
			_draw_unit_smoke_immersion(canvas, opp_pos, 1.1, false, t)
			_draw_unit_smoke_immersion(canvas, hero_pos, 1.1, true, t)
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
		# 3 Anéis de Reggae expandindo com as cores oficiais da Jamaica (verde, ouro e vermelho)
		for r_i: int in range(3):
			var r_col: Color = [REGGAE_GREEN, REGGAE_GOLD, REGGAE_RED][r_i]
			var ring_r: float = (24.0 + float(r_i) * 16.0 + fmod(t * 22.0, 24.0)) * r_pulse
			var r_ell: PackedVector2Array = _make_ellipse(hero_pos + Vector2(0, 4), ring_r, ring_r * 0.52, 28)
			r_ell.append(r_ell[0])
			canvas.draw_polyline(r_ell, Color(r_col, 0.65 - float(r_i) * 0.12), 1.8, true)
		# Notas musicais em pixel art (notas_bob_01) flutuando sobre Bob Marley
		_draw_bob_musical_notes(canvas, hero_pos, visual_time, 1.45 * LEVEL_SCALE[lobby_preview_level - 1], -32.0 * LEVEL_SCALE[lobby_preview_level - 1])
		# Buff visual nos pés e corpo do Bob Marley (+30% velocidade de ataque)
		_draw_bob_song_buff(canvas, hero_pos + Vector2(0, 4), visual_time, 1.15 * LEVEL_SCALE[lobby_preview_level - 1], false)
		# Debuff visual nos pés e corpo do Zumbi oponente (-30% desaceleração / chill)
		_draw_bob_song_debuff(canvas, opp_pos + Vector2(0, 4), visual_time, 1.15, false)
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
			opp_tint = Color("f5b7b1")
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
	_draw_board_effects()
	if state.is_empty():
		return
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
		var unit_id: int = int(unit.get("id", -1))
		if bool(unit.get("has_angel_wings", false)):
			ascended_units[unit_id] = true
		if lula_descents.has(unit_id):
			var descent: Dictionary = lula_descents[unit_id]
			var prog: float = clampf(1.0 - float(descent["remaining"]) / maxf(float(descent["duration"]), 0.001), 0.0, 1.0)
			var ease_descent: float = 1.0 - pow(1.0 - prog, 2.5)
			pose["angle"] = sin(visual_time * 16.0) * 0.08 * (1.0 - ease_descent)
			pose["offset"] = Vector2(0, -360.0 * (1.0 - ease_descent))
			pose["tint"] = Color(1.0, 1.0, 1.0, clampf(prog * 2.5, 0.45, 1.0))


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


func _draw_cached_arena(canvas: CanvasItem) -> void:
	_draw_arena(canvas)
	_draw_board_base(canvas)
	if not state.is_empty():
		_draw_bench(canvas)


func _update_arena_cache() -> void:
	var phase: String = _phase()
	arena_render_cache.visible = phase != "menu"
	if not arena_render_cache.visible:
		return
	var key: String = "calm" if phase in ["combat", "round_result", "match_over"] else phase
	if phase == "preparation":
		key += ":%d:%s:%d" % [selected_id, str(hover_cell), hover_bench]
		if selected_id >= 0:
			# Só o realce de seleção pulsa a 8Hz; corpos/VFX mantêm a cadência completa.
			key += ":%d" % int(visual_time * 8.0)
			for unit: Dictionary in state.get("own", {}).get("units", []):
				key += ":%s:%s" % [unit.get("active", false), unit.get("cell", [])]
	arena_render_cache.refresh(key)


func _draw_arena(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("1a1f22"))
	if arena != null:
		canvas.draw_texture_rect(arena, Rect2(ARENA_OFFSET, arena.get_size() * ARENA_SCALE), false)
	# Vinheta suave: escurece arquibancadas e bordas para destacar a areia.
	var shade: Color = Color(0.02, 0.03, 0.04, 0.5)
	var clear: Color = Color(0.02, 0.03, 0.04, 0.0)
	canvas.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 170), Vector2(0, 170)]), PackedColorArray([shade, shade, clear, clear]))
	canvas.draw_polygon(PackedVector2Array([Vector2(0, 520), Vector2(1280, 520), Vector2(1280, 720), Vector2(0, 720)]), PackedColorArray([clear, clear, Color(shade, 0.65), Color(shade, 0.65)]))
	canvas.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(170, 0), Vector2(170, 720), Vector2(0, 720)]), PackedColorArray([Color(shade, 0.4), clear, clear, Color(shade, 0.4)]))
	canvas.draw_polygon(PackedVector2Array([Vector2(1110, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(1110, 720)]), PackedColorArray([clear, Color(shade, 0.4), Color(shade, 0.4), clear]))
	# Objetos originais do PixelLab, com os pés projetados fora das células jogáveis.
	for prop: Dictionary in arena_props:
		var texture: Texture2D = prop["texture"]
		var ground_point: Vector2 = prop["ground"]
		var scale: float = float(prop["scale"]) * Board.scale_at(ground_point.y)
		var size: Vector2 = texture.get_size() * scale
		var origin: Vector2 = Board.project(ground_point) - (prop["anchor"] as Vector2) * scale
		canvas.draw_texture_rect(texture, Rect2(origin.round(), size), false)


func _draw_board_base(canvas: CanvasItem) -> void:
	var phase: String = _phase()
	var prep: bool = phase == "preparation"
	var calm: bool = phase in ["combat", "round_result", "match_over"]
	var selected: Dictionary = _selected_own() if prep else {}
	var occupied: Dictionary = {}
	for segment: PackedVector2Array in board_perimeter:
		canvas.draw_line(segment[0] + Vector2(0, 2), segment[1] + Vector2(0, 2), Color(0.19, 0.13, 0.07, 0.32), 4.0, true)
		canvas.draw_line(segment[0], segment[1], Color(0.96, 0.85, 0.62, 0.7 if prep else 0.4), 2.0, true)
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
			canvas.draw_colored_polygon(polygon, fill)
			canvas.draw_polyline(hex_outlines_outer[cell], Color(0.33, 0.22, 0.1, 0.22 if calm else 0.4), 1.6, true)
			canvas.draw_polyline(hex_outlines_inner[cell], Color(1.0, 0.97, 0.88, 0.1 if calm else 0.2), 1.0, true)


func _draw_board_effects() -> void:
	var phase: String = _phase()
	var calm: bool = phase in ["combat", "round_result", "match_over"]
	var selected: Dictionary = _selected_own() if phase == "preparation" else {}
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
		_draw_cell_range(z_cell, z_radius, Color(0.18, 0.72, 0.28, 0.16), Color(0.28, 0.95, 0.42, 0.45))
		var cloud_frame: Dictionary = _smoke_vfx_data(zone)
		if not cloud_frame.is_empty():
			_draw_vfx_frame(self, cloud_frame)
		var z_pulse: float = 0.92 + 0.08 * sin(visual_time * 3.5 + float(zone.get("id", 0)))
		var z_ellipse: PackedVector2Array = Board.ellipse(z_ground, (0.42 + z_radius * 0.38) * z_pulse, (0.24 + z_radius * 0.22) * z_pulse, 24)
		draw_colored_polygon(z_ellipse, Color(0.2, 0.8, 0.32, 0.22))
		z_ellipse.append(z_ellipse[0])
		draw_polyline(z_ellipse, Color(0.32, 0.95, 0.45, 0.5), 1.6, true)
	# Os hexágonos reais da explosão do foguete acendem em laranja e apagam junto com o fogo.
	if phase == "combat":
		for blast: Dictionary in blast_zones:
			var b_fade: float = clampf(float(blast["life"]) / maxf(float(blast["duration"]), 0.001), 0.0, 1.0)
			var c_prim: Color = blast.get("color_primary", Color(1.0, 0.42, 0.1, 0.42))
			var c_bord: Color = blast.get("color_border", Color(1.0, 0.78, 0.35, 0.95))
			c_prim.a *= b_fade
			c_bord.a *= b_fade
			_draw_cell_range(_cell(blast["cell"]), int(blast["radius"]), c_prim, c_bord)
		# Avisos telegrafados de área do Boss (Círculos e hexágonos de perigo com anel de contagem regressiva)
		for tele: Dictionary in boss_telegraphs:
			var prog: float = 1.0 - clampf(float(tele["life"]) / maxf(float(tele["duration"]), 0.001), 0.0, 1.0)
			var is_tornado: bool = tele["spell"] == "fire_tornado"
			var t_color_fill: Color = Color(1.0, 0.25, 0.05, 0.26 + 0.16 * sin(visual_time * 16.0)) if is_tornado else Color(0.72, 0.15, 0.95, 0.26 + 0.16 * sin(visual_time * 16.0))
			var t_color_border: Color = Color(1.0, 0.75, 0.2, 0.95) if is_tornado else Color(0.95, 0.5, 1.0, 0.95)
			_draw_cell_range(_cell(tele["cell"]), int(tele["radius"]), t_color_fill, t_color_border)
			var t_ground: Vector2 = Board.ground(_cell(tele["cell"]))
			var ring_r: float = 0.85 * (1.0 - prog)
			var ring_pts: PackedVector2Array = Board.ellipse(t_ground, ring_r, ring_r * 0.58, 28)
			ring_pts.append(ring_pts[0])
			draw_polyline(ring_pts, Color.WHITE if int(visual_time * 20.0) % 2 == 0 else t_color_border, 2.5, true)
			var center_pt: Vector2 = Board.project(t_ground)
			var warn_font: Font = ThemeDB.fallback_font
			draw_string_outline(warn_font, center_pt + Vector2(-12, 6), "⚠", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, 4, Color.BLACK)
			draw_string(warn_font, center_pt + Vector2(-12, 6), "⚠", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color("ffea44"))

		# Portais de invocação de monstros do Boss (Poça de lodo negro borbulhante e vórtice cósmico)
		for portal: Dictionary in boss_summon_portals:
			var p_life: float = float(portal["life"])
			var p_dur: float = float(portal["duration"])
			var p_prog: float = 1.0 - clampf(p_life / p_dur, 0.0, 1.0)
			var p_ground: Vector2 = portal["ground"]
			var p_alpha: float = clampf(sin(p_prog * PI), 0.0, 1.0)
			var pool_r: float = 0.55 * clampf(p_prog * 2.5, 0.0, 1.0)
			draw_colored_polygon(Board.ellipse(p_ground, pool_r, pool_r * 0.55, 24), Color(0.04, 0.02, 0.07, 0.9 * p_alpha))
			var v_pts: PackedVector2Array = Board.ellipse(p_ground, pool_r * 0.85, pool_r * 0.48, 20)
			v_pts.append(v_pts[0])
			draw_polyline(v_pts, Color(0.65, 0.15, 0.9, 0.85 * p_alpha), 2.2, true)
			for b_i: int in range(6):
				var b_ang: float = visual_time * 4.0 + b_i * TAU / 6.0
				var b_dist: float = pool_r * (0.3 + 0.4 * sin(visual_time * 6.0 + b_i))
				var b_pos: Vector2 = Board.project(p_ground + Vector2(cos(b_ang) * b_dist, sin(b_ang) * b_dist * 0.55))
				var b_size: float = 2.5 + 1.5 * sin(visual_time * 8.0 + b_i)
				draw_circle(b_pos, b_size, Color(0.55, 0.1, 0.75, 0.85 * p_alpha))

		# Descida dos céus do Lula: coluna de luz sagrada, penas celestiais e círculo de pouso
		for d_uid: int in lula_descents.keys():
			var descent: Dictionary = lula_descents[d_uid]
			var d_ground: Vector2 = descent["ground"]
			var d_screen: Vector2 = Board.project(d_ground)
			var d_prog: float = clampf(1.0 - float(descent["remaining"]) / maxf(float(descent["duration"]), 0.001), 0.0, 1.0)
			var d_alpha: float = clampf(sin(d_prog * PI * 0.95), 0.3, 1.0)
			var top_y: float = -520.0
			var col_bot_w: float = 48.0
			var col_top_w: float = 28.0
			var beam_poly: PackedVector2Array = PackedVector2Array([
				d_screen + Vector2(-col_bot_w, 4),
				d_screen + Vector2(col_bot_w, 4),
				d_screen + Vector2(col_top_w, top_y),
				d_screen + Vector2(-col_top_w, top_y)
			])
			draw_polygon(beam_poly, PackedColorArray([
				Color(1.0, 0.95, 0.45, 0.45 * d_alpha),
				Color(1.0, 0.95, 0.45, 0.45 * d_alpha),
				Color(1.0, 1.0, 0.8, 0.08 * d_alpha),
				Color(1.0, 1.0, 0.8, 0.08 * d_alpha)
			]))
			var ring_ground: PackedVector2Array = Board.ellipse(d_ground, 0.52 + 0.08 * sin(visual_time * 8.0), 0.3 + 0.05 * sin(visual_time * 8.0), 24)
			ring_ground.append(ring_ground[0])
			draw_polyline(ring_ground, Color("ffd700", 0.95 * d_alpha), 2.8, true)
			draw_colored_polygon(Board.ellipse(d_ground, 0.42, 0.24, 20), Color(1.0, 0.9, 0.35, 0.32 * d_alpha))
			for f_i: int in range(6):
				var f_fall: float = fposmod(d_prog * 2.2 + float(f_i) * 0.17, 1.0)
				var f_y: float = lerpf(top_y * 0.65, 0.0, f_fall)
				var f_x: float = sin(visual_time * 5.0 + float(f_i) * 1.6) * 32.0
				var f_pos: Vector2 = d_screen + Vector2(f_x, f_y)
				draw_circle(f_pos, 2.8 * (1.0 - f_fall * 0.3), Color(1.0, 1.0, 1.0, 0.9 * (1.0 - f_fall)))
				draw_circle(f_pos + Vector2(0.5, 0.5), 1.4, Color("ffd700", 0.95 * (1.0 - f_fall)))
	# Aura musical de ritmo do Bob Marley durante o combate
	if calm:
		for entry: Dictionary in frame_entries:
			var unit: Dictionary = entry["unit"]
			if str(unit.get("key", "")) == "bob_marley" and bool(unit.get("alive", true)) and not bool(entry["ghost"]):
				var b_ground: Vector2 = entry["ground"]
				var b_lvl: int = clampi(int(unit.get("level", 1)), 1, 3)
				var b_cell: Vector2i = _cell(unit.get("cell", []))
				var b_team: int = int(unit.get("team", -1))
				var bob_spec: Variant = specs.get("bob_marley")
				var cur_radius: int = 3
				if bob_spec != null and not bob_spec.aura_radius_by_level.is_empty():
					cur_radius = bob_spec.aura_radius_by_level[mini(b_lvl - 1, bob_spec.aura_radius_by_level.size() - 1)]
				if int(unit["id"]) == selected_id:
					_draw_cell_range(b_cell, cur_radius, Color(0.25, 0.72, 0.35, 0.05), Color(0.42, 0.85, 0.52, 0.32))
				var b_pulse: float = 0.94 + 0.06 * sin(visual_time * 4.5)
				for r_i: int in range(3):
					var r_color: Color = [REGGAE_GREEN, REGGAE_GOLD, REGGAE_RED][r_i]
					var r_r: float = (0.42 + float(r_i) * 0.18 + fmod(visual_time * 0.22, 0.22)) * b_pulse * (1.0 + float(cur_radius - 3) * 0.15)
					var r_ellipse: PackedVector2Array = Board.ellipse(b_ground, r_r, r_r * 0.58, 28)
					r_ellipse.append(r_ellipse[0])
					draw_polyline(r_ellipse, Color(r_color, 0.5 - float(r_i) * 0.1), 1.8, true)
				var bob_screen: Vector2 = Board.project(b_ground)
				_draw_bob_musical_notes(self, bob_screen, visual_time + float(unit.get("id", 0)) * 0.23, 1.25 * float(entry["scale"]), -44.0 * float(entry["scale"]))
				# Buff rítmico nos aliados e debuff de lentidão nos inimigos no raio da música
				for other_entry: Dictionary in frame_entries:
					var other_u: Dictionary = other_entry["unit"]
					if not bool(other_u.get("alive", true)) or bool(other_entry.get("ghost", false)):
						continue
					if int(other_u.get("id", -1)) == int(unit.get("id", -1)):
						continue
					var o_cell: Vector2i = _cell(other_u.get("cell", []))
					if Grid.distance(b_cell, o_cell) <= cur_radius:
						var o_ground: Vector2 = other_entry["ground"]
						var o_scale: float = float(other_entry.get("scale", 1.0))
						var o_time: float = visual_time + float(other_u.get("id", 0)) * 0.35
						if int(other_u.get("team", -1)) == b_team:
							_draw_bob_song_buff(self, o_ground, o_time, o_scale, true)
						else:
							_draw_bob_song_debuff(self, o_ground, o_time, o_scale, true)
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


func _draw_bench(canvas: CanvasItem) -> void:
	var prep: bool = _phase() == "preparation"
	var selected: Dictionary = _selected_own()
	var font: Font = ThemeDB.fallback_font
	var label_at: Vector2 = Board.bench_position(0) + Vector2(-96, 5)
	canvas.draw_string_outline(font, label_at, "RESERVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 5, Color(0, 0, 0, 0.75))
	canvas.draw_string(font, label_at, "RESERVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	for slot: int in range(Board.BENCH_SLOTS):
		var polygon: PackedVector2Array = Board.bench_polygon(slot)
		var fill: Color = Color(0.2, 0.13, 0.06, 0.22)
		if prep and not selected.is_empty() and bool(selected.get("active", false)):
			fill = Color(0.18, 0.72, 0.66, 0.28)
		if prep and slot == hover_bench:
			fill = Color(fill, fill.a + 0.14)
		canvas.draw_colored_polygon(polygon, fill)
		polygon.append(polygon[0])
		canvas.draw_polyline(polygon, Color(0.33, 0.22, 0.1, 0.45), 1.6, true)
		var center: Vector2 = Board.bench_position(slot)
		canvas.draw_line(center + Vector2(-16, 12), center + Vector2(16, 12), Color(GOLD, 0.25), 1.0, true)
		canvas.draw_string(font, center + Vector2(-4, 27), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(GOLD, 0.7))


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
		if lula_descents.has(unit_id):
			var descent: Dictionary = lula_descents[unit_id]
			var prog: float = clampf(1.0 - float(descent["remaining"]) / maxf(float(descent["duration"]), 0.001), 0.0, 1.0)
			var ease_descent: float = 1.0 - pow(1.0 - prog, 2.5)
			pose["angle"] = sin(visual_time * 16.0) * 0.08 * (1.0 - ease_descent)
			pose["offset"] = Vector2(0, -360.0 * (1.0 - ease_descent))
			pose["tint"] = Color(1.0, 1.0, 1.0, clampf(prog * 2.5, 0.45, 1.0))
		else:
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
	var buff_time: float = float(unit.get("group_attack_buff_timer", 0))
	if buff_time > 0.0 and bool(unit.get("alive", true)):
		var b_pulse: float = 0.5 + 0.5 * sin(visual_time * 8.0)
		var b_ring: PackedVector2Array = Board.ellipse(ground_point, 0.36 + 0.05 * b_pulse, 0.21 + 0.03 * b_pulse, 20)
		b_ring.append(b_ring[0])
		draw_polyline(b_ring, Color("ffd700", 0.9), 2.2, true)
		for s_i: int in range(3):
			var s_rise: float = fposmod(visual_time * 1.5 + float(s_i) / 3.0 + float(unit.get("id", 0)) * 0.2, 1.0)
			var s_pos: Vector2 = (entry["feet"] as Vector2) + Vector2(sin(float(s_i) * 2.1 + visual_time * 3.0) * 14.0, -s_rise * 32.0)
			draw_circle(s_pos, 1.8 * (1.0 - s_rise), Color("fff59d", 1.0 - s_rise))


## Aura exclusiva do Boss Dev: vórtice arcano profundo, glifos cósmicos e chamas/clarão na conjuração.
func _draw_boss_aura_back(entry: Dictionary) -> void:
	var unit: Dictionary = entry["unit"]
	var u_id: int = int(unit.get("id", -1))
	var is_enraged: bool = bool(unit.get("boss_enraged", false))
	var is_casting: bool = visual_attacks.has(u_id)
	var ground_point: Vector2 = entry["ground"]
	var feet: Vector2 = entry["feet"]
	var speed_mult: float = 2.4 if is_enraged else (1.8 if is_casting else 1.0)
	var pulse: float = 0.5 + 0.5 * sin(visual_time * (2.8 * speed_mult))
	var cast_scale: float = 1.35 if is_casting else 1.0
	
	# 1. Base externa de névoa escura cósmica / chamas de vácuo (4 camadas)
	for layer: int in range(4):
		var r_x: float = (0.75 + float(layer) * 0.14) * (1.18 if is_enraged else 1.0) * cast_scale
		var r_y: float = (0.43 + float(layer) * 0.08) * (1.18 if is_enraged else 1.0) * cast_scale
		var a_col: Color
		if is_enraged:
			a_col = Color(0.42, 0.06, 0.04, (0.42 - float(layer) * 0.09) * (0.8 + 0.2 * pulse))
		elif is_casting:
			a_col = Color(0.35, 0.08, 0.50, (0.45 - float(layer) * 0.09) * (0.85 + 0.15 * pulse))
		else:
			a_col = Color(0.18, 0.02, 0.28, (0.34 - float(layer) * 0.08) * (0.8 + 0.2 * pulse))
		draw_colored_polygon(Board.ellipse(ground_point, r_x, r_y, 32), a_col)
		
	# 2. Vórtice de vácuo profundo nos pés
	var v_col: Color = Color(0.18, 0.01, 0.01, 0.94) if is_enraged else (Color(0.12, 0.01, 0.20, 0.94) if is_casting else Color(0.03, 0.01, 0.05, 0.88))
	draw_colored_polygon(Board.ellipse(ground_point, (0.58 + 0.05 * pulse) * cast_scale, (0.33 + 0.03 * pulse) * cast_scale, 28), v_col)
	
	# 3. Grande Círculo de Invocação Arcana / Runas ao Conjurar
	if is_casting:
		var circ_rad: float = 0.95 * cast_scale
		var c_ring: PackedVector2Array = Board.ellipse(ground_point, circ_rad, circ_rad * 0.57, 36)
		c_ring.append(c_ring[0])
		draw_polyline(c_ring, Color("ffd700", 0.95), 2.5, true)
		# Raios radiais do círculo mágico (8 pontas de invocação)
		for ray_i: int in range(8):
			var r_ang: float = visual_time * 2.0 + TAU * float(ray_i) / 8.0
			var p_center: Vector2 = Board.project(ground_point).round()
			var p_edge: Vector2 = Board.project(ground_point + Vector2(cos(r_ang) * circ_rad, sin(r_ang) * (circ_rad * 0.57))).round()
			draw_line(p_center, p_edge, Color("ffb3ff", 0.75), 1.4)
			
	# 4. Anéis concêntricos de energia
	var ring_dark: PackedVector2Array = Board.ellipse(ground_point, 0.72 * (0.96 + 0.04 * pulse) * cast_scale, 0.42 * (0.96 + 0.04 * pulse) * cast_scale, 36)
	ring_dark.append(ring_dark[0])
	draw_polyline(ring_dark, Color(0.98, 0.18, 0.05, 0.95) if is_enraged else (Color("d65eff", 0.95) if is_casting else Color(0.12, 0.02, 0.18, 0.95)), 3.2, true)
	
	var ring_purple: PackedVector2Array = Board.ellipse(ground_point, 0.54 * (0.95 + 0.05 * pulse) * cast_scale, 0.31 * (0.95 + 0.05 * pulse) * cast_scale, 32)
	ring_purple.append(ring_purple[0])
	draw_polyline(ring_purple, Color(1.0, 0.65, 0.15, 0.95) if is_enraged else Color(0.85, 0.28, 1.0, 0.95), 2.4, true)
	
	# 5. Ondas de choque contínuas que expandem do centro
	for wave_idx: int in range(2):
		var wave_prog: float = fmod(visual_time * (0.55 * speed_mult) + float(wave_idx) * 0.5, 1.0)
		var wave_r: float = (0.28 + 0.48 * wave_prog) * cast_scale
		var ring_wave: PackedVector2Array = Board.ellipse(ground_point, wave_r, wave_r * 0.57, 28)
		ring_wave.append(ring_wave[0])
		var w_col: Color = Color(1.0, 0.35, 0.05, 0.9 * (1.0 - wave_prog)) if is_enraged else Color(0.75, 0.2, 0.95, 0.85 * (1.0 - wave_prog))
		draw_polyline(ring_wave, w_col, 2.2, true)
		
	# 6. Coluna vertical etérea de névoa / labaredas ascendentes nas costas
	var b_height: float = float(entry["height"]) * (1.4 if is_casting else 1.25)
	var col_w: float = 38.0 * cast_scale
	var base_dark: Color = Color(0.40, 0.04, 0.04, 0.7 * (0.75 + 0.25 * pulse)) if is_enraged else (Color(0.25, 0.05, 0.35, 0.75) if is_casting else Color(0.08, 0.01, 0.12, 0.58 * (0.75 + 0.25 * pulse)))
	var top_clear: Color = Color(1.0, 0.45, 0.1, 0.0) if is_enraged else Color(0.75, 0.2, 0.95, 0.0)
	draw_polygon(PackedVector2Array([feet + Vector2(-col_w, 4), feet + Vector2(col_w, 4), feet + Vector2(col_w * 0.6, -b_height), feet + Vector2(-col_w * 0.6, -b_height)]),
		PackedColorArray([base_dark, base_dark, top_clear, top_clear]))
		
	# 7. Gavinhas/runas orbitantes (10 runas com rotação e faíscas)
	var num_runes: int = 10 if is_casting else 8
	for index: int in range(num_runes):
		var angle: float = visual_time * (1.6 * speed_mult) + TAU * float(index) / float(num_runes)
		var orbit_x: float = (0.70 + 0.06 * sin(visual_time * 3.0 + float(index))) * cast_scale
		var orbit_y: float = (0.40 + 0.04 * sin(visual_time * 3.0 + float(index))) * cast_scale
		var rune_pos: Vector2 = Board.project(ground_point + Vector2(cos(angle) * orbit_x, sin(angle) * orbit_y)).round()
		var diamond_outer: PackedVector2Array = PackedVector2Array([rune_pos + Vector2(0, -6), rune_pos + Vector2(5, 0), rune_pos + Vector2(0, 6), rune_pos + Vector2(-5, 0)])
		draw_colored_polygon(diamond_outer, Color(0.18, 0.01, 0.01, 0.95) if is_enraged else Color(0.04, 0.01, 0.06, 0.95))
		diamond_outer.append(diamond_outer[0])
		draw_polyline(diamond_outer, Color(1.0, 0.4, 0.1, 0.95) if is_enraged else Color(0.75, 0.25, 0.95, 0.9), 1.5, true)
		var diamond_inner: PackedVector2Array = PackedVector2Array([rune_pos + Vector2(0, -3), rune_pos + Vector2(3, 0), rune_pos + Vector2(0, 3), rune_pos + Vector2(-3, 0)])
		var core_col: Color = Color("ff5522") if is_enraged else (Color("ffd700") if is_casting else (Color("b24bf3") if index % 2 == 0 else Color("8a2be2")))
		draw_colored_polygon(diamond_inner, core_col)



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
		var u_id: int = int(unit.get("id", -1))
		var is_angel: bool = bool(unit.get("has_angel_wings", false)) or ascended_units.has(u_id) or lula_descents.has(u_id)
		if is_angel and (bool(unit.get("alive", true)) or lula_descents.has(u_id)):
			var is_descending: bool = lula_descents.has(u_id)
			var is_frenzy: bool = float(unit.get("divine_frenzy_timer", 0)) > 0.0
			_draw_lula_angel_wings(units_layer, origin, float(entry["height"]), display_scale, visual_time + float(u_id) * 0.35, is_descending, is_frenzy)
		units_layer.draw_set_transform(origin, float(pose["angle"]), Vector2(display_scale, display_scale))
		units_layer.draw_texture(texture, (-anchor).round(), tint)
		if bool(unit.get("alive", true)):
			var u_key: String = str(unit.get("key", ""))
			if u_key == "snoop":
				var u_dir: String = str(visual_directions.get(int(unit.get("id", -1)), "south"))
				_draw_snoop_cigar(units_layer, origin, display_scale, u_dir, visual_time + float(unit.get("id", 0)) * 0.37, tint, float(pose["angle"]))
			elif u_key == "bob_marley" and not bool(entry["ghost"]) and _phase() == "preparation":
				_draw_bob_musical_notes(units_layer, origin, visual_time + float(unit.get("id", 0)) * 0.25, 1.15 * scale, -44.0 * scale)
			var in_smoke: Dictionary = _unit_in_smoke_zone(unit)
			if not in_smoke.is_empty():
				_draw_unit_smoke_immersion(units_layer, entry["feet"], scale, int(unit.get("team", 0)) == int(in_smoke.get("team", 0)), visual_time + float(unit.get("id", 0)) * 0.41)
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
			var is_boss_enraged: bool = bool(unit.get("boss_enraged", false))
			for index: int in range(12):
				var b_rise: float = fposmod(visual_time * (0.65 if is_boss_enraged else 0.45) + float(index) / 12.0, 1.0)
				var b_sway: float = sin(float(index) * 2.1 + visual_time * 2.3) * 26.0
				var b_mote: Vector2 = (feet + Vector2(b_sway, -8 - b_rise * height * 1.12)).round()
				var b_size: float = 4.0 if index % 3 == 0 else (3.0 if index % 2 == 0 else 2.0)
				var b_fade: float = 1.0 - b_rise
				canvas.draw_rect(Rect2(b_mote - Vector2.ONE, Vector2(b_size + 2, b_size + 2)), Color(0.15, 0.01, 0.01, 0.9 * b_fade) if is_boss_enraged else Color(0.02, 0.01, 0.04, 0.9 * b_fade))
				var b_core: Color = (Color("ff3b1e") if index % 2 == 0 else Color("ffaa22")) if is_boss_enraged else (Color("c040fb") if index % 2 == 0 else Color("7918b9"))
				canvas.draw_rect(Rect2(b_mote, Vector2(b_size, b_size)), Color(b_core, b_fade * 0.95))
		var u_id: int = int(unit.get("id", -1))
		var is_angel_overlay: bool = bool(unit.get("has_angel_wings", false)) or ascended_units.has(u_id) or lula_descents.has(u_id)
		if is_angel_overlay and (bool(unit.get("alive", true)) or lula_descents.has(u_id)):
			var is_frenzy_overlay: bool = float(unit.get("divine_frenzy_timer", 0)) > 0.0
			var pose_offset: Vector2 = entry["pose"]["offset"] as Vector2 if entry.has("pose") else Vector2.ZERO
			_draw_lula_halo(canvas, feet + pose_offset, height, float(entry["display_scale"]), visual_time + float(u_id) * 0.35, is_frenzy_overlay)
	for effect: Dictionary in slashes:
		var life: float = float(effect["life"]) / 0.2
		var start: float = float(effect["seed"])
		canvas.draw_arc(effect["position"], 11.0 + (1.0 - life) * 6.0, start, start + 1.9, 10, Color(GOLD if bool(effect["critical"]) else Color("fff4de"), life), 2.5 if bool(effect["critical"]) else 1.8, true)
	_draw_library_feedback(canvas, "front")
	_draw_kit_feedback(canvas)
	if _phase() == "combat":
		for zone: Dictionary in state.get("combat", {}).get("zones", []):
			if float(zone.get("remaining", 0)) > 0.0:
				_draw_snoop_smoke_zone_atmosphere(canvas, zone)
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
	_draw_world_hero_tooltip(canvas)


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


## Tooltip flutuante exibido ao passar o mouse sobre os heróis no tabuleiro e na reserva (lê habilidades).
func _draw_world_hero_tooltip(canvas: Node2D) -> void:
	if mouse_pointer.x < -100 or mouse_pointer.y < 0:
		return
	# Se estiver sobre um ícone de item, dá prioridade ao tooltip de item
	for entry: Dictionary in world_item_hover_rects:
		if (entry["rect"] as Rect2).grow(3.0).has_point(mouse_pointer):
			return
	
	# Detecta unidade sob o mouse
	var unit: Dictionary = _unit_at_point(mouse_pointer)
	if unit.is_empty() and hover_bench >= 0:
		unit = _bench_unit(hover_bench)
	if unit.is_empty() and hover_cell != Board.INVALID:
		unit = _own_unit_at(hover_cell)
		if unit.is_empty():
			for u: Dictionary in state.get("enemy", {}).get("units", []):
				if bool(u.get("active", false)) and _cell(u.get("cell", [])) == hover_cell:
					unit = u
					break
	if unit.is_empty() or not bool(unit.get("alive", true)):
		return

	var key: String = str(unit.get("key", ""))
	if key.is_empty() or key in ["ball", "rocket", "mini_rocket", "smoke"]:
		return

	var unit_name: String = str(unit.get("name", key.capitalize()))
	var level: int = clampi(int(unit.get("level", 1)), 1, 3)
	var team: int = int(unit.get("team", 0))
	var is_ally: bool = team == 0
	var team_tag: String = " (Aliado)" if is_ally else " (Inimigo)"
	var stars_text: String = "★".repeat(level)
	var skill_desc: String = str(KIT_TEXT.get(key, "Combate tático e ataques de arena."))

	var tags: Array[String] = []
	if specs.has(key):
		tags = specs[key].synergy_tags
	var tag_names: Array[String] = []
	for t: String in tags:
		tag_names.append(str(SYNERGY_INFO.get(t, {}).get("name", t.capitalize())))
	var tags_line: String = " · ".join(tag_names) if not tag_names.is_empty() else "Neutro"

	var hp_cur: int = int(round(float(unit.get("hp", 0.0))))
	var hp_max: int = int(round(float(unit.get("max_hp", 100.0))))
	var portrait: Texture2D = art.portrait_for(key, 30, 28)

	var font: Font = ThemeDB.fallback_font
	var tip_w: float = 300.0

	# Quebra inteligente de linhas para a descrição completa da habilidade
	var words: PackedStringArray = skill_desc.split(" ")
	var desc_lines: Array[String] = []
	var cur_line: String = ""
	for w: String in words:
		var test_line: String = (cur_line + " " + w).strip_edges()
		if font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > (tip_w - 24):
			if not cur_line.is_empty():
				desc_lines.append(cur_line)
			cur_line = w
		else:
			cur_line = test_line
	if not cur_line.is_empty():
		desc_lines.append(cur_line)

	var tip_h: float = maxf(72.0 + float(desc_lines.size()) * 15.0, 95.0)
	var pos: Vector2 = mouse_pointer + Vector2(16, -tip_h - 10)
	if pos.y < 10.0:
		pos.y = mouse_pointer.y + 24.0
	if pos.x + tip_w > 1270.0:
		pos.x = mouse_pointer.x - tip_w - 16.0
	pos.x = clampf(pos.x, 10.0, 1270.0 - tip_w)
	pos.y = clampf(pos.y, 10.0, 710.0 - tip_h)

	var card_rect: Rect2 = Rect2(pos, Vector2(tip_w, tip_h))
	# Sombra e fundo sólido escuro
	canvas.draw_rect(card_rect.grow(2.5), Color(0.0, 0.0, 0.0, 0.70))
	canvas.draw_rect(card_rect, Color(0.06, 0.08, 0.12, 0.96))

	# Moldura temática chanfrada
	var border_col: Color = GOLD if level == 3 else (Color("64dcd2") if is_ally else Color("f87171"))
	canvas.draw_rect(card_rect, border_col, false, 1.5)
	canvas.draw_rect(card_rect.grow(-2.0), Color(border_col, 0.35), false, 1.0)

	# Cantoneiras ornamentadas medievais nos 4 cantos
	var corners: Array[Vector2] = [card_rect.position, Vector2(card_rect.end.x, card_rect.position.y), Vector2(card_rect.position.x, card_rect.end.y), card_rect.end]
	var corner_dirs: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i: int in range(4):
		var cp: Vector2 = corners[i]
		var cd: Vector2 = corner_dirs[i]
		canvas.draw_line(cp + Vector2(cd.x * 6, 0), cp + Vector2(0, cd.y * 6), border_col, 1.2, true)

	# Mini-retrato à esquerda
	var p_rect: Rect2 = Rect2(pos + Vector2(8, 8), Vector2(36, 36))
	canvas.draw_rect(p_rect.grow(1), Color(0.02, 0.03, 0.05, 0.9))
	if portrait != null:
		canvas.draw_texture_rect(portrait, p_rect, false)
	canvas.draw_rect(p_rect, border_col, false, 1.0)

	# Título: NOME + ESTRELAS + TIME
	var title_col: Color = GOLD if is_ally else Color("fca5a5")
	canvas.draw_string(font, pos + Vector2(50, 22), "%s  %s%s" % [unit_name.to_upper(), stars_text, team_tag], HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 56), 13, title_col)

	# Linha de Classes e HP
	canvas.draw_string(font, pos + Vector2(50, 38), "[%s]  ❤ %d/%d" % [tags_line, hp_cur, hp_max], HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 56), 11, Color("94a3b8"))

	# Divisória decorada
	canvas.draw_line(pos + Vector2(8, 48), pos + Vector2(tip_w - 8, 48), Color(border_col, 0.4), 1.0)

	# Habilidade com título dourado e linhas detalhadas
	canvas.draw_string(font, pos + Vector2(8, 63), "✦ HABILIDADE:", HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 16), 11, GOLD)
	for l_i: int in range(desc_lines.size()):
		canvas.draw_string(font, pos + Vector2(8, 78 + float(l_i) * 14.0), desc_lines[l_i], HORIZONTAL_ALIGNMENT_LEFT, int(tip_w - 16), 10, Color("f1f5f9"))

