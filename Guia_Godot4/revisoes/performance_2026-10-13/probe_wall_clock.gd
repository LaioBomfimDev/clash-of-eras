extends SceneTree
## Regressão observacional: quatro intervalos reais de 250 ms, sem sleeps.
const MainView = preload("res://client/main.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var view: MainView = MainView.new()
	root.add_child(view)
	view.set_process(false)
	view._performance_elapsed = 0.0
	view._performance_frame_ms.clear()
	view._performance_cpu_us = 0
	view._performance_last_frame_usec = 0
	view._record_performance_sample(1000000, 1000)
	for sample: int in range(1, 5):
		view._record_performance_sample(1000000 + sample * 250000, 1000)
	var metrics: Dictionary = view.get_performance_metrics()
	var frame_ok: bool = is_equal_approx(float(metrics["frame_ms"]), 250.0) and is_equal_approx(float(metrics["p95_frame_ms"]), 250.0)
	var cpu_ok: bool = is_equal_approx(float(metrics["client_cpu_ms"]), 1.0)
	print("WALL_CLOCK_PROBE: %d passed, %d failed; frame=%s p95=%s cpu=%s" % [int(frame_ok) + int(cpu_ok), 2 - int(frame_ok) - int(cpu_ok), metrics["frame_ms"], metrics["p95_frame_ms"], metrics["client_cpu_ms"]])
	view.queue_free()
	await process_frame
	quit(0 if frame_ok and cpu_ok else 1)
