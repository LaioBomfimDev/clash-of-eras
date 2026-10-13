extends RefCounted
## Tema e peças visuais da interface: painéis translúcidos, botões, ícones e selos.
## Somente apresentação; cores e medidas são provisórias até a arte final no PixelLab.

const GOLD: Color = Color("f4d58a")
const INK: Color = Color("ece8d8")
const MUTED: Color = Color("aab6b4")
const GLASS: Color = Color(0.05, 0.075, 0.09, 0.74)
const EDGE: Color = Color(0.88, 0.74, 0.45, 0.55)
const TIER_COLORS: Dictionary = {0: Color(0.22, 0.25, 0.28, 0.9), 1: Color("a8713f"), 2: Color("a9b8c8"), 3: Color("e7bf4f")}

const RARITIES: Dictionary = {
	"common": {
		"name": "Comum",
		"border": Color("b87333"),
		"border_light": Color("e5a663"),
		"accent": Color("e0a96d"),
		"glow": Color("b87333"),
		"bg_tint": Color(0.18, 0.11, 0.06, 0.65),
		"badge_color": Color("b87333")
	},
	"rare": {
		"name": "Raro",
		"border": Color("0284c7"),
		"border_light": Color("38bdf8"),
		"accent": Color("7dd3fc"),
		"glow": Color("0ea5e9"),
		"bg_tint": Color(0.04, 0.14, 0.22, 0.65),
		"badge_color": Color("0284c7")
	},
	"epic": {
		"name": "Épico",
		"border": Color("9333ea"),
		"border_light": Color("c084fc"),
		"accent": Color("e879f9"),
		"glow": Color("a855f7"),
		"bg_tint": Color(0.16, 0.05, 0.22, 0.65),
		"badge_color": Color("9333ea")
	},
	"legendary": {
		"name": "Lendário",
		"border": Color("d97706"),
		"border_light": Color("fbbf24"),
		"accent": Color("fde68a"),
		"glow": Color("f59e0b"),
		"bg_tint": Color(0.22, 0.14, 0.02, 0.65),
		"badge_color": Color("f59e0b")
	}
}

static func rarity_info(rarity_key: String) -> Dictionary:
	return RARITIES.get(rarity_key, RARITIES["common"])

const ICON_DIR: String = "res://assets/ui/icons/"

static var _icons: Dictionary = {}


static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		var path: String = ICON_DIR + name + ".png"
		_icons[name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[name] as Texture2D


static var _coin_sheet: Texture2D = null

static func coin_sheet() -> Texture2D:
	if _coin_sheet == null:
		var path: String = ICON_DIR + "coin_sheet.png"
		if ResourceLoader.exists(path):
			_coin_sheet = load(path) as Texture2D
	return _coin_sheet


static func create_animated_coin_atlas() -> AtlasTexture:
	var sheet: Texture2D = coin_sheet()
	if sheet == null:
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, 32, 32)
	return atlas


static func update_coin_atlas_frame(atlas: AtlasTexture, time_sec: float, fps: float = 8.0, total_frames: int = 8) -> void:
	if atlas == null:
		return
	var frame_idx: int = int(fmod(time_sec * fps, float(total_frames)))
	atlas.region = Rect2(frame_idx * 32, 0, 32, 32)


static func glass(alpha: float = 0.74, radius: int = 8, edge_alpha: float = 0.55) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(GLASS, alpha)
	style.border_color = Color(EDGE, edge_alpha)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.anti_aliasing = true
	style.set_content_margin_all(6)
	return style


static func _button_box(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.anti_aliasing = true
	style.set_content_margin_all(4)
	return style


static func build_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = 15
	theme.set_stylebox("normal", "Button", _button_box(Color(0.11, 0.19, 0.21, 0.82), Color(EDGE, 0.6)))
	theme.set_stylebox("hover", "Button", _button_box(Color(0.16, 0.28, 0.3, 0.9), Color(GOLD, 0.95)))
	theme.set_stylebox("pressed", "Button", _button_box(Color(0.07, 0.12, 0.14, 0.95), GOLD, 2))
	theme.set_stylebox("disabled", "Button", _button_box(Color(0.07, 0.09, 0.1, 0.5), Color(0.6, 0.6, 0.6, 0.22)))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color(0.62, 0.64, 0.62, 0.62))
	theme.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.75))
	theme.set_constant("outline_size", "Button", 3)
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	theme.set_constant("outline_size", "Label", 4)
	theme.set_stylebox("panel", "Panel", glass())
	theme.set_stylebox("panel", "TooltipPanel", glass(0.94, 6, 0.8))
	theme.set_color("font_color", "TooltipLabel", INK)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	return theme


## Selo hexagonal desenhado sob demanda; cor indica o patamar ativo.
class Badge:
	extends Control
	var texture: Texture2D
	var tier: int = 0

	func _init(icon_texture: Texture2D, tier_value: int, badge_size: float) -> void:
		texture = icon_texture
		tier = tier_value
		custom_minimum_size = Vector2(badge_size, badge_size)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	## Hexágono com ponta para cima.
	static func hex_points(center: Vector2, radius: float) -> PackedVector2Array:
		var points: PackedVector2Array = PackedVector2Array()
		for index: int in range(6):
			var angle: float = PI / 6.0 + TAU * index / 6.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		return points

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var radius: float = minf(size.x, size.y) * 0.5
		var color: Color = TIER_COLORS.get(tier, TIER_COLORS[0])
		draw_colored_polygon(hex_points(center, radius), Color(0.04, 0.05, 0.06, 0.9))
		draw_colored_polygon(hex_points(center, radius - 2.0), color)
		var rim: PackedVector2Array = hex_points(center, radius - 2.0)
		rim.append(rim[0])
		draw_polyline(rim, Color(1, 1, 1, 0.35 if tier > 0 else 0.12), 1.0, true)
		if texture != null:
			var icon_size: Vector2 = Vector2(32, 32) if radius >= 17.0 else Vector2(16, 16)
			draw_texture_rect(texture, Rect2(center - icon_size * 0.5, icon_size), false,
				Color.WHITE if tier > 0 else Color(0.75, 0.78, 0.8, 0.7))


## Moldura decorada de carta da loja com cantoneiras ornamentadas e iluminação de raridade
static func draw_ornate_card_frame(canvas: CanvasItem, rect: Rect2, rarity_key: String, is_hover: bool = false, is_disabled: bool = false) -> void:
	var info: Dictionary = rarity_info(rarity_key)
	var b_col: Color = info["border"]
	var b_light: Color = info["border_light"]
	var bg_tint: Color = info["bg_tint"]

	if is_disabled:
		b_col = Color(b_col, 0.35)
		b_light = Color(b_light, 0.25)
		bg_tint = Color(bg_tint, 0.2)
	elif is_hover:
		b_col = b_light
		b_light = Color(1.0, 1.0, 0.95, 1.0)

	# 1. Aura / Resplendor mágico exterior no hover na cor da raridade
	if is_hover:
		canvas.draw_rect(rect.grow(4.5), Color(b_col, 0.16), false, 1.5)
		canvas.draw_rect(rect.grow(2.5), Color(b_col, 0.35), false, 1.5)
		canvas.draw_rect(rect.grow(1.0), Color(b_light, 0.65), false, 1.5)

	# 2. Fundo da carta em vinheta escura
	canvas.draw_rect(rect, Color(0.06, 0.07, 0.09, 0.96) if not is_hover else Color(0.08, 0.10, 0.13, 0.98))
	# Centro com leve resplendor na cor da raridade
	var glow_area: Rect2 = Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, rect.size.y * 0.65))
	canvas.draw_rect(glow_area, bg_tint if not is_hover else Color(bg_tint.lightened(0.2), clampf(bg_tint.a * 1.8, 0.25, 0.85)))

	# Feixe de luz horizontal decorativo no topo no hover
	if is_hover:
		canvas.draw_line(rect.position + Vector2(8, 2), Vector2(rect.end.x - 8, rect.position.y + 2), Color(b_light, 0.85), 1.5, true)

	# 3. Moldura dupla chanfrada
	var outer_w: float = 2.0 if is_hover else 1.5
	canvas.draw_rect(rect, b_col, false, outer_w)
	var inset_rect: Rect2 = rect.grow(-3.0)
	canvas.draw_rect(inset_rect, Color(b_light, 0.40 if not is_hover else 0.85), false, 1.0)

	# 4. Cantoneiras ornamentadas medievais (losangos e aletas em 45 graus)
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		Vector2(rect.position.x, rect.end.y),
		rect.end
	]
	var corner_dirs: Array[Vector2] = [
		Vector2(1, 1),
		Vector2(-1, 1),
		Vector2(1, -1),
		Vector2(-1, -1)
	]

	for idx: int in range(4):
		var cp: Vector2 = corners[idx]
		var dir: Vector2 = corner_dirs[idx]

		# Losango no vértice da esquina
		var dk: Vector2 = cp + Vector2(dir.x * 4.0, dir.y * 4.0)
		var diamond: PackedVector2Array = PackedVector2Array([
			dk + Vector2(0, -3.0),
			dk + Vector2(3.0, 0),
			dk + Vector2(0, 3.0),
			dk + Vector2(-3.0, 0)
		])
		canvas.draw_colored_polygon(diamond, b_light if is_hover else b_col)

		# Reforço nas bordas da esquina
		var line_h: Vector2 = cp + Vector2(dir.x * 12.0, dir.y * 1.5)
		var line_v: Vector2 = cp + Vector2(dir.x * 1.5, dir.y * 12.0)
		canvas.draw_line(cp + Vector2(dir.x * 1.5, dir.y * 1.5), line_h, b_light, 1.5, true)
		canvas.draw_line(cp + Vector2(dir.x * 1.5, dir.y * 1.5), line_v, b_light, 1.5, true)

		# Aleta diagonal em 45 graus com rebite central luminoso
		var inner_knot: Vector2 = cp + Vector2(dir.x * 6.5, dir.y * 6.5)
		canvas.draw_line(cp + Vector2(dir.x * 12.0, dir.y * 1.5), inner_knot, Color(b_light, 0.8), 1.2, true)
		canvas.draw_line(cp + Vector2(dir.x * 1.5, dir.y * 12.0), inner_knot, Color(b_light, 0.8), 1.2, true)
		canvas.draw_circle(inner_knot, 1.4, Color.WHITE if is_hover else b_light)

		# Cruz de brilho estelar cintilante no losango ao passar o mouse
		if is_hover:
			canvas.draw_line(dk - Vector2(3.5, 0), dk + Vector2(3.5, 0), Color.WHITE, 1.2, true)
			canvas.draw_line(dk - Vector2(0, 3.5), dk + Vector2(0, 3.5), Color.WHITE, 1.2, true)
			canvas.draw_circle(dk, 1.4, Color.WHITE)


## Pilha de moedas douradas com resplendor quente e moedas empilhadas em relevo
static func draw_gold_pile(canvas: CanvasItem, center: Vector2, gold_amount: int, visual_time: float = 0.0) -> void:
	# 1. Resplendor / Aura difusa de ouro atrás da pilha
	var pulse: float = 0.88 + 0.12 * sin(visual_time * 2.8)
	var glow_layers: Array = [
		[Vector2(135, 46), Color(1.0, 0.76, 0.2, 0.12 * pulse)],
		[Vector2(105, 36), Color(1.0, 0.84, 0.26, 0.20 * pulse)],
		[Vector2(70, 24), Color(1.0, 0.92, 0.38, 0.32 * pulse)],
		[Vector2(38, 14), Color(1.0, 0.98, 0.58, 0.48 * pulse)]
	]
	for layer: Array in glow_layers:
		var rad: Vector2 = layer[0]
		var col: Color = layer[1]
		var pts: PackedVector2Array = PackedVector2Array()
		for i: int in range(20):
			var a: float = TAU * float(i) / 20.0
			pts.append(center + Vector2(cos(a) * rad.x, sin(a) * rad.y))
		canvas.draw_colored_polygon(pts, col)

	# 2. Moedas empilhadas organicamente em camadas (monte amplo e alto)
	var coin_defs: Array = [
		# Pico traseiro superior (visível bem acima do pill)
		Vector2(0, -32), Vector2(-16, -30), Vector2(16, -29),
		Vector2(-32, -26), Vector2(32, -25), Vector2(-8, -27), Vector2(8, -26),
		Vector2(-48, -22), Vector2(48, -21), Vector2(-24, -23), Vector2(24, -22), Vector2(0, -24),
		# Camada traseira média
		Vector2(-64, -17), Vector2(64, -16), Vector2(-40, -18), Vector2(40, -17),
		Vector2(-78, -11), Vector2(78, -10), Vector2(-55, -12), Vector2(55, -11),
		Vector2(-20, -15), Vector2(20, -14), Vector2(0, -16),
		# Laterais transbordando (asas do monte)
		Vector2(-92, -4), Vector2(92, -3), Vector2(-70, -5), Vector2(70, -4),
		Vector2(-104, 5), Vector2(104, 6), Vector2(-85, 3), Vector2(85, 4),
		Vector2(-114, 14), Vector2(114, 15), Vector2(-96, 12), Vector2(96, 13),
		Vector2(-76, 9), Vector2(76, 10), Vector2(-56, 7), Vector2(56, 8),
		# Camada frontal inferior contornando e abraçando a base do pill
		Vector2(-86, 20), Vector2(86, 21), Vector2(-66, 19), Vector2(66, 20),
		Vector2(-46, 20), Vector2(46, 21), Vector2(-26, 22), Vector2(26, 23),
		Vector2(-10, 24), Vector2(10, 24), Vector2(0, 25),
		Vector2(-95, 25), Vector2(95, 26), Vector2(-75, 25), Vector2(75, 26),
		Vector2(-55, 27), Vector2(55, 27), Vector2(-35, 28), Vector2(35, 28),
		Vector2(-18, 29), Vector2(18, 29), Vector2(0, 30)
	]

	var base_rim: Color = Color("9e6c1e")
	var base_face: Color = Color("f5bf2e")
	var base_bevel: Color = Color("ffea75")
	var shadow_col: Color = Color(0.14, 0.08, 0.02, 0.55)

	for i: int in range(coin_defs.size()):
		var c_pos: Vector2 = center + coin_defs[i]
		var rx: float = 8.2
		var ry: float = 5.2

		# Gradiente de luz por altitude na pilha
		var alt_factor: float = clampf((c_pos.y - center.y + 32.0) / 60.0, 0.0, 1.0)
		var rim_col: Color = base_rim.lerp(Color("845214"), alt_factor * 0.4)
		var face_col: Color = base_face.lerp(Color("e5a820"), alt_factor * 0.35)
		var inner_bevel: Color = base_bevel.lerp(Color("f4c740"), alt_factor * 0.3)

		# Sombra na base
		var sh_pts: PackedVector2Array = PackedVector2Array()
		for step: int in range(12):
			var a: float = TAU * float(step) / 12.0
			sh_pts.append(c_pos + Vector2(0, 1.8) + Vector2(cos(a) * rx, sin(a) * ry))
		canvas.draw_colored_polygon(sh_pts, shadow_col)

		# Borda chanfrada de profundidade da moeda
		var rim_pts: PackedVector2Array = PackedVector2Array()
		for step: int in range(12):
			var a: float = TAU * float(step) / 12.0
			rim_pts.append(c_pos + Vector2(cos(a) * rx, sin(a) * ry))
		canvas.draw_colored_polygon(rim_pts, rim_col)

		# Face superior dourada
		var face_pts: PackedVector2Array = PackedVector2Array()
		for step: int in range(12):
			var a: float = TAU * float(step) / 12.0
			face_pts.append(c_pos + Vector2(0, -0.6) + Vector2(cos(a) * (rx - 1.2), sin(a) * (ry - 0.8)))
		canvas.draw_colored_polygon(face_pts, face_col)

		# Chanfro fino interno
		var bevel_pts: PackedVector2Array = PackedVector2Array()
		for step: int in range(12):
			var a: float = TAU * float(step) / 12.0
			bevel_pts.append(c_pos + Vector2(0, -0.6) + Vector2(cos(a) * (rx - 2.2), sin(a) * (ry - 1.4)))
		bevel_pts.append(bevel_pts[0])
		canvas.draw_polyline(bevel_pts, Color(inner_bevel, 0.65), 1.0, true)

		# Brasão gravado no centro das moedas frontais/visíveis
		if i % 2 == 0:
			canvas.draw_line(c_pos + Vector2(-2.2, -0.6), c_pos + Vector2(2.2, -0.6), Color(rim_col, 0.55), 1.0, true)
			canvas.draw_circle(c_pos + Vector2(0, -1.8), 0.8, Color(inner_bevel, 0.75))

		# Ponto de brilho especular no canto superior esquerdo
		canvas.draw_circle(c_pos + Vector2(-rx * 0.45, -ry * 0.45), 1.1, Color(1, 1, 0.95, 0.95))

	# 3. Faíscas sutis cintilantes sobre a pilha
	var spark_offsets: Array = [
		Vector2(-45, -24), Vector2(40, -22), Vector2(-15, -28), Vector2(10, -26), Vector2(-70, -8), Vector2(65, -10)
	]
	for s_idx: int in range(spark_offsets.size()):
		var sp_pos: Vector2 = center + spark_offsets[s_idx]
		var sp_alpha: float = clampf(sin(visual_time * 4.2 + float(s_idx) * 1.6), 0.0, 1.0)
		if sp_alpha > 0.15:
			var sp_col: Color = Color(Color("fff3a8"), sp_alpha * 0.92)
			canvas.draw_line(sp_pos - Vector2(3.5, 0), sp_pos + Vector2(3.5, 0), sp_col, 1.2, true)
			canvas.draw_line(sp_pos - Vector2(0, 3.5), sp_pos + Vector2(0, 3.5), sp_col, 1.2, true)
			canvas.draw_circle(sp_pos, 1.0, Color.WHITE)


## Moldura ornada de botões da loja (Espaço, Renovar, Lutar)
static func draw_ornate_button_frame(canvas: CanvasItem, rect: Rect2, theme_name: String = "teal", is_hover: bool = false, is_disabled: bool = false, is_pressed: bool = false) -> void:
	var bg_col: Color = Color(0.06, 0.16, 0.19, 0.95) if theme_name == "teal" else Color(0.19, 0.12, 0.05, 0.95)
	var b_col: Color = Color(0.20, 0.62, 0.68, 0.88) if theme_name == "teal" else Color(0.92, 0.70, 0.32, 0.88)
	var b_light: Color = Color(0.48, 0.88, 0.95, 1.0) if theme_name == "teal" else Color(1.0, 0.90, 0.48, 1.0)

	if is_disabled:
		bg_col = Color(bg_col, 0.4)
		b_col = Color(b_col, 0.28)
		b_light = Color(b_light, 0.28)
	elif is_pressed:
		bg_col = bg_col.darkened(0.15)
		b_col = b_light
	elif is_hover:
		bg_col = bg_col.lightened(0.20)
		b_col = b_light

	# 1. Aura / Glow exterior no hover
	if is_hover:
		canvas.draw_rect(rect.grow(3.0), Color(b_light, 0.20), false, 1.5)
		canvas.draw_rect(rect.grow(1.5), Color(b_light, 0.45), false, 1.5)

	# 2. Fundo sólido do botão
	canvas.draw_rect(rect, bg_col)
	# Reflexo de vidro chanfrado na metade superior
	var top_glow: Rect2 = Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.45))
	canvas.draw_rect(top_glow, Color(b_light, 0.12 if not is_hover else 0.24))

	# 3. Moldura dupla chanfrada
	canvas.draw_rect(rect, b_col, false, 1.5 if not is_hover else 2.0)
	canvas.draw_rect(rect.grow(-2.5), Color(b_light, 0.35 if not is_hover else 0.80), false, 1.0)

	# 4. Cantoneiras decoradas medievais nos 4 vértices
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]
	var corner_dirs: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i: int in range(4):
		var cp: Vector2 = corners[i]
		var cd: Vector2 = corner_dirs[i]
		canvas.draw_line(cp + Vector2(cd.x * 7, 0), cp + Vector2(0, cd.y * 7), b_light, 1.2, true)
		var dot_pos: Vector2 = cp + Vector2(cd.x * 3.5, cd.y * 3.5)
		canvas.draw_circle(dot_pos, 1.2, Color.WHITE if is_hover else b_light)
		if is_hover:
			canvas.draw_line(dot_pos - Vector2(2.5, 0), dot_pos + Vector2(2.5, 0), Color.WHITE, 1.0, true)
			canvas.draw_line(dot_pos - Vector2(0, 2.5), dot_pos + Vector2(0, 2.5), Color.WHITE, 1.0, true)
