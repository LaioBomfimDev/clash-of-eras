extends SceneTree
## Local-only opponent for browser profiling without a second WebGL renderer.
const Client = preload("res://net/online_client.gd")
var client: Client = Client.new()
var submitted: Dictionary = {}
var started_usec: int = Time.get_ticks_usec()
var queue_announced: bool = false

func _initialize() -> void:
	Engine.max_fps = 60
	client.match_ended.connect(func(_winner: int, _reason: String) -> void: quit(0))
	client.start_matchmaking("ws://127.0.0.1:8910", "PerfPeer")

func _process(delta: float) -> bool:
	client.step(delta)
	if client.state == Client.State.IN_QUEUE and not queue_announced:
		queue_announced = true
		print("PERF_PEER_QUEUE_READY")
	var state: Dictionary = client.latest_snapshot
	var phase: String = str(state.get("phase", ""))
	var own: Dictionary = state.get("own", {})
	if phase == "benefit":
		for option: Dictionary in own.get("benefit_options", []):
			var id: String = str(option["option_id"])
			if not submitted.has(id):
				submitted[id] = true
				client.send_command("choose_benefit", {"option_id": id})
			break
	elif phase == "preparation":
		for offer: Dictionary in own.get("shop", []):
			var id: String = str(offer["offer_id"])
			if str(offer.get("kind", "")) == "hero" and not submitted.has(id):
				submitted[id] = true
				client.send_command("recruit", {"offer_id": id})
		var ready_key: String = "ready:%s" % state.get("round", 1)
		if not (own.get("units", []) as Array).is_empty() and not submitted.has(ready_key):
			submitted[ready_key] = true
			client.send_command("ready")
	if Time.get_ticks_usec() - started_usec > 90000000:
		client.cancel_matchmaking()
		quit(1)
	return false
