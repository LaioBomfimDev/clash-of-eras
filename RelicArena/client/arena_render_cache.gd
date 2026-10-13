extends Node2D
## Arena/tabuleiro/reserva em cache de GPU; unidades e efeitos ficam fora dele.
## Só reprocessa a base quando fase, seleção, ocupação ou hover mudam.

var cache_viewport: SubViewport
var painter: Node2D
var draw_base: Callable
var last_key: String = ""
var rebuild_count: int = 0


func setup(size: Vector2i, callback: Callable) -> void:
	draw_base = callback
	cache_viewport = SubViewport.new()
	cache_viewport.size = size
	cache_viewport.disable_3d = true
	cache_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(cache_viewport)
	painter = Node2D.new()
	painter.draw.connect(_paint)
	cache_viewport.add_child(painter)
	queue_redraw()


func refresh(key: String) -> void:
	if key == last_key:
		return
	last_key = key
	painter.queue_redraw()
	cache_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _paint() -> void:
	rebuild_count += 1
	draw_base.call(painter)


func _draw() -> void:
	if cache_viewport != null:
		draw_texture(cache_viewport.get_texture(), Vector2.ZERO)
