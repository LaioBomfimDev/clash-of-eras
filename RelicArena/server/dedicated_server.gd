extends SceneTree
## Executável de servidor dedicado para container / cloud (Render, Railway, Fly.io ou VPS).
## Lê a variável de ambiente PORT (usada automaticamente pelo Render).

const OnlineServer = preload("res://net/online_server.gd")
const Protocol = preload("res://net/online_protocol.gd")

var server: OnlineServer = OnlineServer.new()
var running: bool = true


func _init() -> void:
	var port_str: String = OS.get_environment("PORT")
	var port: int = int(port_str) if not port_str.is_empty() and int(port_str) > 0 else Protocol.DEFAULT_PORT
	print("==================================================")
	print("       CLASH OF ERAS — SERVIDOR DEDICADO          ")
	print("==================================================")
	print("[INFO] Godot %s" % Engine.get_version_info()["string"])
	print("[INFO] Iniciando servidor na porta %d..." % port)

	var err: Error = server.listen(port)
	if err != OK:
		printerr("[ERRO] Falha ao iniciar servidor na porta %d: %d" % [port, err])
		quit(1)
		return

	print("[SUCESSO] Servidor pronto para conexões e matchmaking!")


func _process(delta: float) -> bool:
	if not running:
		return true
	server.step(delta)
	return false
