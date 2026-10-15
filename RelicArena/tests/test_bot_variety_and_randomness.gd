extends SceneTree
## Teste automatizado de variedade, aleatoriedade e posicionamento tático dos Bots.
## Valida que cada partida gera ofertas diferentes e que a IA organiza sua formação com inteligência.

const Session = preload("res://simulation/match_session.gd")

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	print("--- INICIANDO TESTES DE VARIEDADE E IA DOS BOTS ---")
	_test_shop_and_seed_variety()
	_test_bot_archetype_variety()
	_test_bot_tactical_positioning()
	_test_bot_copy_upgrading()
	print("BOT VARIETY & TACTICAL TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FALHA: %s" % message)

func _test_shop_and_seed_variety() -> void:
	var seed_shops: Dictionary = {}
	var seeds: Array[int] = [101, 202, 303, 404, 505]
	for s: int in seeds:
		var sess: Session = Session.new(s)
		var shop_hero_keys: Array = []
		for offer: Dictionary in sess.teams[0]["shop"]:
			if offer["kind"] == "hero":
				shop_hero_keys.append(str(offer["key"]))
		seed_shops[s] = shop_hero_keys

	var unique_shops: Array = []
	for s: int in seeds:
		var signature: String = str(seed_shops[s])
		if not unique_shops.has(signature):
			unique_shops.append(signature)

	_check(unique_shops.size() > 1, "Sementes diferentes geram ofertas de lojas diferentes para o jogador (obtido: %d únicas de %d)" % [unique_shops.size(), seeds.size()])

func _test_bot_archetype_variety() -> void:
	var archetypes_seen: Dictionary = {}
	var titles_seen: Dictionary = {}
	for s: int in range(1, 25):
		var sess: Session = Session.new(s * 997)
		var arch: String = str(sess.teams[1].get("bot_archetype", ""))
		var title: String = str(sess.teams[1].get("bot_name", ""))
		archetypes_seen[arch] = true
		titles_seen[title] = true

	_check(archetypes_seen.size() >= 3, "Bots apresentam múltiplos arquétipos diferentes ao longo das partidas (obtidos: %d)" % archetypes_seen.size())
	_check(titles_seen.size() >= 4, "Bots apresentam múltiplos títulos/nomes temáticos diferentes (obtidos: %d)" % titles_seen.size())

func _test_bot_tactical_positioning() -> void:
	for s: int in [123, 456, 789]:
		var sess: Session = Session.new(s)
		for unit in sess.sim.units:
			if unit.team == 1 and unit.active:
				# Tanques não devem ficar no fundo da retaguarda se houver espaço
				if unit.key in ["obama", "barbie", "lula"]:
					_check(unit.cell.y in [2, 3], "Tanque %s do bot posicionado na linha de frente (linha %d)" % [unit.key, unit.cell.y])
				# Atiradores frágeis devem ficar recuados nas linhas 0 ou 1
				elif unit.key in ["neymar", "elon", "snoop"]:
					_check(unit.cell.y in [0, 1], "Atirador %s do bot posicionado na retaguarda (linha %d)" % [unit.key, unit.cell.y])
				# Bob Marley deve ficar centralizado nas linhas médias para maximizar o raio de sua aura
				elif unit.key == "bob_marley":
					_check(unit.cell.y in [1, 2] and unit.cell.x in [1, 2, 3, 4, 5, 6], "Bob Marley posicionado no centro da formação (célula %s)" % str(unit.cell))

func _test_bot_copy_upgrading() -> void:
	# Partida onde o bot recruta cópia e sobe nível
	var sess: Session = Session.new(20261011)
	sess.step(30.0)
	if sess.phase == "round_result":
		sess.apply_command(0, "next", "next_round")
		# Na rodada 2 o bot terá mais ouro e chances de subir de nível
		var bot_has_level2: bool = false
		for unit in sess.sim.units:
			if unit.team == 1 and unit.level >= 2:
				bot_has_level2 = true
				break
		_check(bot_has_level2, "O bot consegue comprar cópias e subir heróis para nível 2+")
