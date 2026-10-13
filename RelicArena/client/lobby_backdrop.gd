extends Node2D
## Fundo do lobby: MP4 nativo do navegador; OGV separado no Godot desktop/mobile.
## Imagem permanece disponível quando animação está desativada/indisponível.
const POSTER: String = "res://assets/ui/lobby_02/lobby.png"
const NATIVE_VIDEO: String = "res://assets/ui/lobby_02/lobby_loop.ogv"
const SCREEN: Vector2 = Vector2(1280, 720)
var poster: Texture2D
var player: VideoStreamPlayer
var active: bool = false
var economical: bool = false
var web_layer: bool = false
var focused: bool = true
var configured: bool = false


func _ready() -> void:
	z_index = -2
	poster = load(POSTER) as Texture2D if ResourceLoader.exists(POSTER) else null
	if OS.has_feature("web"):
		web_layer = bool(JavaScriptBridge.eval("typeof window.clashLobbyBackground === 'object'", true))


func set_mode(in_lobby: bool, eco: bool) -> void:
	if configured and active == in_lobby and economical == eco:
		return
	configured = true
	active = in_lobby
	economical = eco
	visible = active
	if web_layer:
		get_viewport().transparent_bg = active
		JavaScriptBridge.eval("window.clashLobbyBackground.setActive(%s, %s);" %
			[str(active).to_lower(), str(economical).to_lower()], true)
	else:
		_update_native_video()
	queue_redraw()


func _update_native_video() -> void:
	var animate: bool = active and not economical and focused and DisplayServer.get_name() != "headless"
	if animate and player == null and ResourceLoader.exists(NATIVE_VIDEO):
		player = VideoStreamPlayer.new()
		player.stream = load(NATIVE_VIDEO) as VideoStream
		player.expand = true
		player.size = SCREEN
		player.loop = true
		player.volume = 0.0
		player.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(player)
	if player != null:
		player.visible = animate
		if animate and not player.is_playing():
			player.play()
		player.paused = not animate


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
	else:
		return
	if not web_layer and configured:
		_update_native_video()
		queue_redraw()


func _draw() -> void:
	if not active or web_layer:
		return
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("0c0e12"))
	if poster != null:
		draw_texture_rect(poster, Rect2(Vector2.ZERO, SCREEN), false)


func _exit_tree() -> void:
	if web_layer:
		JavaScriptBridge.eval("window.clashLobbyBackground?.setActive(false, true);", true)
