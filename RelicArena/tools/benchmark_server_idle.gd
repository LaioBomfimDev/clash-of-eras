extends "res://server/dedicated_server.gd"
## Measures idle polling in the real dedicated entry point. No external clients.

var bench_started: int = Time.get_ticks_usec()
var bench_polls: int = 0

func _process(delta: float) -> bool:
	bench_polls += 1
	var finished: bool = super._process(delta)
	var elapsed_ms: float = (Time.get_ticks_usec() - bench_started) / 1000.0
	if elapsed_ms < 2500.0:
		return finished
	var report: Dictionary = {"duration_ms": elapsed_ms, "polls": bench_polls,
		"polls_per_second": bench_polls * 1000.0 / elapsed_ms,
		"max_fps": Engine.max_fps, "clients": server.clients.size(), "rooms": server.rooms.size(),
		"scope": "Idle real headless entry point; loop count is not browser FPS or cloud capacity."}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var file: FileAccess = FileAccess.open(argument.trim_prefix("--output="), FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(report, "\t"))
	print("SERVER IDLE BENCHMARK: ", JSON.stringify(report))
	server.stop()
	quit(0)
	return true
