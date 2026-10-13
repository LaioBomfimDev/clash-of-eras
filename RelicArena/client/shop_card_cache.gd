extends TextureRect
## Congela só a aparência da carta. O Button, tooltip e arrasto ficam no HUD.
## Recrutamento/compra continuam comandados pelo mesmo botão e pelo servidor.
const PADDING: int = 8
const CACHE_SCALE: int = 2
var button: Button
var cache_viewport: SubViewport
var last_button_state: int = -1


static func attach(target: Button, theme_resource: Theme) -> void:
	var cache := new()
	var children: Array[Node] = target.get_children()
	cache.button = target
	cache.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cache.position = Vector2.ONE * -PADDING
	cache.size = target.size + Vector2.ONE * PADDING * 2
	cache.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cache.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	target.add_child(cache)
	cache.cache_viewport = SubViewport.new()
	cache.cache_viewport.size = Vector2i(cache.size) * CACHE_SCALE
	cache.cache_viewport.disable_3d = true
	cache.cache_viewport.transparent_bg = true
	cache.cache_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	cache.add_child(cache.cache_viewport)
	var content: Control = Control.new()
	content.position = Vector2.ONE * PADDING * CACHE_SCALE
	content.scale = Vector2.ONE * CACHE_SCALE
	content.theme = theme_resource
	cache.cache_viewport.add_child(content)
	for child: Node in children:
		child.reparent(content, false)
	cache.texture = cache.cache_viewport.get_texture()
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	cache.material = blend
	target.set_meta("content_cache", cache)


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var state: int = int(button.disabled) + int(button.is_hovered()) * 2 + int(button.button_pressed) * 4
	if state != last_button_state:
		last_button_state = state
		cache_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
