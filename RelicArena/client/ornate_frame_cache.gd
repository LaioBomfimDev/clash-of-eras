extends Control
## Moldura decorativa reutilizada até hover, pressionado ou estado mudar.
## O Button original continua recebendo os mesmos cliques/toques.

const PADDING: int = 8
const CACHE_SCALE: int = 2
var cache_viewport: SubViewport
var painter: Node2D
var paint: Callable
var last_button_state: int = -1


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var button: Button = get_parent() as Button
	if button == null:
		return
	var state: int = int(button.disabled) + int(button.is_hovered()) * 2 + int(button.button_pressed) * 4
	if state != last_button_state:
		last_button_state = state
		queue_redraw()


func setup(callback: Callable) -> void:
	paint = callback
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cache_viewport = SubViewport.new()
	cache_viewport.size = Vector2i(size + Vector2.ONE * PADDING * 2) * CACHE_SCALE
	cache_viewport.transparent_bg = true
	cache_viewport.disable_3d = true
	cache_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(cache_viewport)
	painter = Node2D.new()
	painter.position = Vector2.ONE * PADDING * CACHE_SCALE
	painter.scale = Vector2.ONE * CACHE_SCALE
	painter.draw.connect(func() -> void: paint.call(painter))
	cache_viewport.add_child(painter)
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	material = blend
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()


func _draw() -> void:
	if cache_viewport == null:
		return
	painter.queue_redraw()
	cache_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	draw_texture_rect(cache_viewport.get_texture(), Rect2(Vector2.ONE * -PADDING,
		Vector2(cache_viewport.size) / CACHE_SCALE), false)
