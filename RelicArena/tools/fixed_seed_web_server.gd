extends SceneTree
## Fixture local: usa o servidor real, alterando somente a semente de cada sala.
## Não é o entrypoint de produção e não é exportado no bundle Web.
var server: RefCounted
var fixture_script: GDScript


func _initialize() -> void:
	Engine.max_fps = 60
	var source: String = FileAccess.get_file_as_string("res://net/online_server.gd")
	var original: String = "var match_seed: int = int(Time.get_ticks_msec()) + next_room_id * 1009"
	if source.count(original) != 1:
		push_error("Fixture source no longer matches production seed construction")
		quit(1)
		return
	fixture_script = GDScript.new()
	fixture_script.source_code = source.replace(original, "var match_seed: int = 20261013")
	if fixture_script.reload() != OK:
		quit(1)
		return
	server = fixture_script.new()
	if server.listen(8910) != OK:
		quit(1)
		return
	print("FIXED_SEED_WEB_SERVER_READY: seed=20261013; port=8910; production code except seed")


func _process(delta: float) -> bool:
	if server != null:
		server.step(delta)
	return false
