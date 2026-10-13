extends Control
## Moedas estáticas renderizadas uma vez; resplendor/faíscas seguem animados.
## O cache permanece na GPU, sem get_image(), PNG novo ou limite dos heróis.

const Kit = preload("res://client/ui_kit.gd")
const CACHE_SIZE: Vector2i = Vector2i(256, 96)
const CACHE_CENTER: Vector2 = Vector2(128, 48)
const CACHE_SCALE: int = 2

var visual_time: float = 0.0
var cache_viewport: SubViewport
var coin_texture: TextureRect
var sparks: Control
var static_draw_count: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cache_viewport = SubViewport.new()
	cache_viewport.size = CACHE_SIZE * CACHE_SCALE
	cache_viewport.transparent_bg = true
	cache_viewport.disable_3d = true
	cache_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(cache_viewport)
	var coins: Node2D = Node2D.new()
	coins.scale = Vector2.ONE * CACHE_SCALE
	coins.draw.connect(_draw_static_coins.bind(coins))
	cache_viewport.add_child(coins)
	coin_texture = TextureRect.new()
	coin_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_texture.texture = cache_viewport.get_texture()
	coin_texture.position = -CACHE_CENTER
	coin_texture.size = Vector2(CACHE_SIZE)
	coin_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	coin_texture.material = blend
	add_child(coin_texture)
	sparks = Control.new()
	sparks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sparks.draw.connect(_draw_sparks)
	add_child(sparks)
	RenderingServer.frame_post_draw.connect(_finish_cache, CONNECT_ONE_SHOT)


func _finish_cache() -> void:
	cache_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func advance(time_sec: float) -> void:
	visual_time = time_sec
	queue_redraw()
	sparks.queue_redraw()


func _draw() -> void:
	Kit.draw_gold_pile_glow(self, Vector2.ZERO, visual_time)


func _draw_static_coins(canvas: Node2D) -> void:
	static_draw_count += 1
	Kit.draw_gold_pile_coins(canvas, CACHE_CENTER)


func _draw_sparks() -> void:
	Kit.draw_gold_pile_sparks(sparks, Vector2.ZERO, visual_time)
