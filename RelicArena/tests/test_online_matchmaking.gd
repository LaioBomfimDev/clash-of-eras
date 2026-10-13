extends SceneTree
## Testes automatizados do protocolo, mapeador de perspectiva e matchmaking online.

const Protocol = preload("res://net/online_protocol.gd")
const Perspective = preload("res://net/perspective_mapper.gd")
const OnlineServer = preload("res://net/online_server.gd")
const OnlineClient = preload("res://net/online_client.gd")

var _checks_passed: int = 0
var _checks_failed: int = 0


func _init() -> void:
	print("INICIANDO TESTES DO MULTIPLAYER ONLINE...")
	_test_protocol()
	_test_perspective()
	_test_matchmaking_and_server()

	print("\nRESULTADO MULTIPLAYER: %d aprovados, %d falhas" % [_checks_passed, _checks_failed])
	if _checks_failed > 0:
		quit(1)
	else:
		quit(0)


func _check(condition: bool, description: String) -> void:
	if condition:
		_checks_passed += 1
	else:
		_checks_failed += 1
		printerr("FALHA: %s" % description)


func _test_protocol() -> void:
	var msg: Dictionary = {
		"type": "command",
		"op": "place",
		"cell": Vector2i(3, 5),
		"tags": ["vanguard", "hero"],
		"count": 42
	}
	var bytes: PackedByteArray = Protocol.encode(msg)
	_check(bytes.size() > 0, "Protocol.encode gera bytes")

	var decoded: Dictionary = Protocol.decode(bytes, Protocol.MAX_CLIENT_MESSAGE)
	_check(decoded.get("type") == "command", "Protocol.decode preserva tipo")
	_check(decoded.get("op") == "place", "Protocol.decode preserva operação")
	_check(decoded.get("cell") == Vector2i(3, 5), "Protocol.decode preserva Vector2i nativo")
	_check(decoded.get("count") == 42, "Protocol.decode preserva inteiros")


func _test_perspective() -> void:
	# Linha 5 (inferior/azul) vira Linha 2 (superior/vermelho) para o time 1
	var flipped_cell: Vector2i = Perspective.flip_cell_vec(Vector2i(2, 5))
	_check(flipped_cell == Vector2i(5, 2), "flip_cell_vec gira 180 graus (x=5, y=2)")

	var flipped_back: Vector2i = Perspective.flip_cell_vec(flipped_cell)
	_check(flipped_back == Vector2i(2, 5), "duplo flip_cell_vec é identidade")

	var client_payload: Dictionary = {"unit_id": 101, "cell": Vector2i(2, 5)}
	var server_payload: Dictionary = Perspective.from_client_payload(client_payload, 1)
	_check(server_payload["cell"] == Vector2i(5, 2), "payload do time 1 é mapeado para a grade real")

	_check(Perspective.flip_team(0) == 1, "flip_team(0) == 1")
	_check(Perspective.flip_team(1) == 0, "flip_team(1) == 0")


func _test_matchmaking_and_server() -> void:
	var server: OnlineServer = OnlineServer.new()
	var test_port: int = 8922
	var err: Error = server.listen(test_port)
	_check(err == OK, "Servidor abre socket na porta de teste %d" % test_port)
	if err != OK:
		return

	var url: String = "ws://127.0.0.1:%d" % test_port
	var client1: OnlineClient = OnlineClient.new()
	var client2: OnlineClient = OnlineClient.new()

	client1.start_matchmaking(url, "Laio")
	client2.start_matchmaking(url, "Navegador2")

	var counter: Array[int] = [0]
	client1.match_started.connect(func(_t: int, _opp: String) -> void: counter[0] += 1)
	client2.match_started.connect(func(_t: int, _opp: String) -> void: counter[0] += 1)

	# Simula passos de rede por alguns frames até conectar e parear
	for _frame: int in range(120):
		server.step(0.016)
		client1.step(0.016)
		client2.step(0.016)
		if counter[0] >= 2:
			break

	_check(counter[0] == 2, "Dois clientes na fila são pareados em uma partida")
	_check(client1.is_in_match(), "Cliente 1 entra no estado IN_MATCH")
	_check(client2.is_in_match(), "Cliente 2 entra no estado IN_MATCH")
	_check(client1.assigned_team != client2.assigned_team, "Clientes recebem times opostos (0 e 1)")
	_check(client1.opponent_name == "Navegador2", "Cliente 1 vê o nome real do oponente ('Navegador2')")
	_check(client2.opponent_name == "Laio", "Cliente 2 vê o nome real do oponente ('Laio')")

	# Testa envio de comando do cliente 1
	var sent: bool = client1.send_command("reroll", {})
	_check(sent, "Cliente envia comando pela conexão WebSocket")

	for _frame: int in range(10):
		server.step(0.016)
		client1.step(0.016)
		client2.step(0.016)

	_check(not client1.latest_snapshot.is_empty(), "Cliente 1 recebe snapshot autoritativo da partida")
	_check(not client2.latest_snapshot.is_empty(), "Cliente 2 recebe snapshot autoritativo da partida")

	client1.reset()
	client2.reset()
	server.stop()

	# Teste de Fallback para Bot local após 20 segundos
	var solo_client: OnlineClient = OnlineClient.new()
	var fallback_triggered: Array[bool] = [false]
	solo_client.fallback_to_bot.connect(func(_reason: String) -> void: fallback_triggered[0] = true)
	solo_client.start_matchmaking("ws://127.0.0.1:9999") # Porta fechada / sem resposta
	# Avança tempo até ultrapassar o timeout de conexão (5s)
	for _i: int in range(60):
		solo_client.step(0.1)
		if fallback_triggered[0]:
			break
	_check(fallback_triggered[0], "Cliente cai automaticamente para bot local se o servidor estiver indisponível")
