extends SceneTree
## Comparação OpenGL de CPU dentro dos callbacks draw; não mede FPS web.
const Kit = preload("res://client/ui_kit.gd")
const GoldCache = preload("res://client/gold_pile_cache.gd")

class LegacyProbe extends Control:
	var visual_time: float = 0.0
	var times: Array[float] = []
	func _draw() -> void:
		var started: int = Time.get_ticks_usec()
		Kit.draw_gold_pile(self, Vector2.ZERO, 20, visual_time)
		times.append(float(Time.get_ticks_usec() - started))

class CachedProbe extends GoldCache:
	var times: Array[float] = []
	var glow_cpu_us: int = 0
	func _draw() -> void:
		var started: int = Time.get_ticks_usec()
		super._draw()
		glow_cpu_us = Time.get_ticks_usec() - started
	func _draw_sparks() -> void:
		var started: int = Time.get_ticks_usec()
		super._draw_sparks()
		times.append(float(glow_cpu_us + Time.get_ticks_usec() - started))

func _initialize() -> void:
	_run.call_deferred()

func _stats(values: Array[float]) -> Dictionary:
	var samples: Array[float] = values.slice(20)
	var total: float = 0.0
	for value: float in samples:
		total += value
	samples.sort()
	return {"samples": samples.size(), "mean_draw_cpu_us": total / samples.size(), "p95_draw_cpu_us": samples[int(samples.size() * 0.95)]}

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This benchmark requires real rendering")
		quit(1)
		return
	Engine.max_fps = 0
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("263a47")
	backdrop.size = Vector2(1280, 720)
	root.add_child(backdrop)
	var legacy: LegacyProbe = LegacyProbe.new()
	legacy.position = Vector2(320, 320)
	legacy.scale = Vector2(2, 2)
	root.add_child(legacy)
	var cached: CachedProbe = CachedProbe.new()
	cached.position = Vector2(960, 320)
	cached.scale = Vector2(2, 2)
	root.add_child(cached)
	for frame: int in range(180):
		var time_sec: float = float(frame) / 60.0
		legacy.visual_time = time_sec
		legacy.queue_redraw()
		cached.advance(time_sec)
		await RenderingServer.frame_post_draw
	var legacy_stats: Dictionary = _stats(legacy.times)
	var cached_stats: Dictionary = _stats(cached.times)
	var cache_once: bool = cached.static_draw_count == 1 and cached.cache_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED
	var result: Dictionary = {"scope": "Native OpenGL CPU spent inside gold draw callbacks only; not browser FPS/GPU time", "legacy": legacy_stats, "cache_dynamic": cached_stats, "static_draw_count": cached.static_draw_count, "cache_rendered_once": cache_once}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var file: FileAccess = FileAccess.open(argument.trim_prefix("--output="), FileAccess.WRITE)
			file.store_string(JSON.stringify(result, "\t") + "\n")
		elif argument.begins_with("--capture="):
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	print("GOLD_CACHE_BENCHMARK: " + JSON.stringify(result))
	legacy.queue_free()
	cached.queue_free()
	backdrop.queue_free()
	await process_frame
	quit(0 if cache_once else 1)
