extends SceneTree
## Fila real de loopback, limites de pacotes determinísticos e entrega integral.
## Não depende de o PC concluir N decodificações dentro de um tempo específico.
const Client = preload("res://net/online_client.gd")
const Server = preload("res://net/online_server.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_test_bounded_receive_queue()
	print("ONLINE RECEIVE BUDGET TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("ONLINE RECEIVE BUDGET FAIL: ", description)

func _test_bounded_receive_queue() -> void:
	var server: Server = Server.new()
	var error: Error = server.listen(8937)
	_check(error == OK, "loopback server opens")
	if error != OK:
		return
	var client: Client = Client.new()
	client.start_matchmaking("ws://127.0.0.1:8937", "Budget")
	for _index: int in range(2000):
		server.step(0.001)
		client.step(0.001)
		if client.state == Client.State.IN_QUEUE and not server.clients.is_empty() and client.get_network_metrics()["rx_packets"] > 0:
			break
		OS.delay_usec(1000)
	_check(client.state == Client.State.IN_QUEUE and not server.clients.is_empty(), "client finishes actual WebSocket handshake")
	if server.clients.is_empty():
		client.reset()
		server.stop()
		return
	var delivered: Array[int] = []
	client.events_received.connect(func(events: Array[Dictionary]) -> void:
		for event: Dictionary in events:
			delivered.append(int(event["sequence"]))
	)
	var packet_count: int = Client.MAX_RECEIVED_PACKETS_PER_STEP + 6
	for sequence: int in range(packet_count):
		server._send_to_client(server.clients[0], {"type": "events", "events": [{"type": "budget_probe", "sequence": sequence}]})
	# Acumula a fila como após uma aba suspensa, sem consumir mensagens do cliente.
	for _index: int in range(2000):
		server.step(0.0)
		client.ws.poll()
		if client.ws.get_available_packet_count() >= packet_count:
			break
		OS.delay_usec(1000)
	_check(client.ws.get_available_packet_count() == packet_count, "all probe packets are queued before deterministic drain")
	_check(client._drain_incoming_packets(3, 0) == 3, "explicit packet cap consumes exactly three packets")
	_check(delivered == [0, 1, 2], "first bounded batch preserves event sequence")
	_check(client.ws.get_available_packet_count() == packet_count - 3, "remaining events stay queued without being discarded")
	_check(int(client.get_network_metrics()["queued_inbound_packets"]) == packet_count - 3, "diagnostic exposes remaining receive queue")
	var received_before: int = int(client.get_network_metrics()["rx_packets"])
	client.step(0.001)
	var packets_this_step: int = int(client.get_network_metrics()["rx_packets"]) - received_before
	_check(packets_this_step > 0 and packets_this_step <= Client.MAX_RECEIVED_PACKETS_PER_STEP, "production step consumes at most configured packet cap")
	_check(client.ws.get_available_packet_count() > 0, "queue larger than production cap spills into later frames")
	while client.ws.get_available_packet_count() > 0:
		var pending_before: int = client.ws.get_available_packet_count()
		var consumed: int = client._drain_incoming_packets(7, 0)
		_check(consumed == mini(7, pending_before), "later bounded batch consumes predictable packet count")
	_check(delivered.size() == packet_count, "every event is eventually delivered")
	var ordered: bool = true
	for index: int in range(delivered.size()):
		ordered = ordered and delivered[index] == index
	_check(ordered, "events across all frame boundaries retain original order with no duplicates")
	_check(client.get_network_metrics()["queued_inbound_packets"] == 0, "receive queue fully drains")
	print("RECEIVE BUDGET EVIDENCE: queued=%d first_batch=3 production_step=%d final_delivered=%d" % [packet_count, packets_this_step, delivered.size()])
	client.reset()
	server.stop()
