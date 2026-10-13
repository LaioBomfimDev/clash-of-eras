extends SceneTree
## Publicação: handshake/ping somente. Nunca envia join_queue ou comandos de jogo.
const Protocol = preload("res://net/online_protocol.gd")
var peer: WebSocketPeer = WebSocketPeer.new()
var started: int = 0
var sent: int = 0
var finished: bool = false
var output_path: String = ""
var nonce: int = 2026101301


func _initialize() -> void:
	Engine.max_fps = 60
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	started = Time.get_ticks_msec()
	var error: Error = peer.connect_to_url(Protocol.DEFAULT_SERVER_URL)
	if error != OK:
		_finish({"connected": false, "pong": false, "error": error}, 1)


func _process(_delta: float) -> bool:
	if finished:
		return false
	peer.poll()
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if sent == 0:
			sent = Time.get_ticks_msec()
			peer.put_packet(Protocol.encode({"type": "ping", "nonce": nonce}))
		while peer.get_available_packet_count() > 0:
			var message: Dictionary = Protocol.decode(peer.get_packet(), Protocol.MAX_SERVER_MESSAGE)
			if message.get("type", "") == "pong" and message.get("nonce", -1) == nonce:
				_finish({"connected": true, "pong": true, "rtt_ms": Time.get_ticks_msec() - sent,
					"handshake_ms": sent - started, "joined_queue": false}, 0)
				return false
	if sent > 0 and Time.get_ticks_msec() - sent > 6000:
		_finish({"connected": true, "pong": false, "handshake_ms": sent - started,
			"joined_queue": false, "reason": "ping response timeout"}, 2)
	elif Time.get_ticks_msec() - started > 90000:
		_finish({"connected": false, "pong": false, "joined_queue": false,
			"reason": "handshake timeout or service cold start"}, 1)
	return false


func _finish(result: Dictionary, code: int) -> void:
	finished = true
	result["endpoint"] = Protocol.DEFAULT_SERVER_URL
	result["scope"] = "WebSocket handshake/ping; no queue, room, player or gameplay"
	print("PUBLIC_WEBSOCKET_PROBE: " + JSON.stringify(result))
	if not output_path.is_empty():
		var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t") + "\n")
	peer.close()
	quit(code)
