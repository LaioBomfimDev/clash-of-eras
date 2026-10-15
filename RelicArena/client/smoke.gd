extends SceneTree
## Integração por métodos/sinais. Não substitui teste de toque real ou renderização.

const MainView = preload("res://client/main.gd")
const Board = preload("res://client/board_projection.gd")
const Kit = preload("res://client/ui_kit.gd")
const ClientTransport = preload("res://net/online_client.gd")

## O botão real pode abrir a fila; esta fixture registra a chamada sem rede.
class NoNetworkClient extends ClientTransport:
	var matchmaking_calls: int = 0

	func start_matchmaking(_custom_url: String = "", _custom_name: String = "") -> void:
		matchmaking_calls += 1

var passed: int = 0
var failed: int = 0
var completed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> bool:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("CLIENT_SMOKE_FAIL: " + label)
	return condition

func _timeout() -> void:
	if not completed:
		printerr("CLIENT_SMOKE_FAIL: timeout de 20 segundos")
		quit(1)

func _finish(view: MainView) -> void:
	completed = true
	print("CLIENT_SMOKE_RESULT: %d passed, %d failed" % [passed, failed])
	if view != null:
		view.queue_free()
	await process_frame
	quit(1 if failed > 0 else 0)

func _choose_gold(view: MainView) -> void:
	for option: Dictionary in view.state.get("own", {}).get("benefit_options", []):
		if option.get("kind", "") == "gold":
			(view.benefit_buttons[str(option["option_id"])] as Button).pressed.emit()
			return
	_check(false, "benefício de ouro oferecido")


func _check_play_button_without_network(view: MainView) -> void:
	var original_client: ClientTransport = view.online_client
	var fixture: NoNetworkClient = NoNetworkClient.new()
	view.online_client = fixture
	view.start_button.pressed.emit()
	if DisplayServer.get_name() == "headless":
		_check(fixture.matchmaking_calls == 0, "JOGAR headless inicia bot sem buscar rede")
		_check(view._phase() == "benefit", "JOGAR headless abre a partida local")
	else:
		_check(fixture.matchmaking_calls == 1, "JOGAR gráfico solicita matchmaking ao transporte injetado")
		_check(view._phase() == "menu" and view.lobby_subview == "matchmaking", "JOGAR gráfico abre a fila sem presumir partida local imediata")
	_check(fixture.ws.get_ready_state() == WebSocketPeer.STATE_CLOSED, "fixture do botão não abriu conexão WebSocket")
	view.online_client = original_client
	view._show_menu()

func _advance_combat(view: MainView) -> Dictionary:
	var observed: Dictionary = {"projectile": false, "heal": false, "damage": false, "dance_shield": false, "moonwalk": false, "native_heal": false, "native_thrust": false, "native_shield": false, "shield_follows_state": true, "base_without_dance": false, "heals_on_living_only": true, "shield_stopped": false}
	var michael_cells: Dictionary = {}
	var shielded_before: Dictionary = {}
	for iteration: int in range(710):
		view._process(0.05)
		observed["projectile"] = bool(observed["projectile"]) or not view.state.get("combat", {}).get("projectiles", []).is_empty()
		observed["dance_shield"] = bool(observed["dance_shield"]) or not view.shield_waves.is_empty()
		for effect: Dictionary in view.floating:
			observed["heal"] = bool(observed["heal"]) or str(effect.get("text", "")).begins_with("+")
			observed["damage"] = bool(observed["damage"]) or str(effect.get("text", "")).is_valid_int()
		for effect: Dictionary in view.kit_effects:
			observed["native_heal"] = bool(observed["native_heal"]) or effect.get("library_key", "") == "cura_01"
			observed["native_thrust"] = bool(observed["native_thrust"]) or effect.get("library_key", "") == "estocada_01"
			if effect.get("library_key", "") == "cura_01":
				var healed: Dictionary = view._unit_by_id(int(effect.get("target_id", -1)))
				observed["heals_on_living_only"] = bool(observed["heals_on_living_only"]) and not healed.is_empty() and bool(healed.get("alive", false)) and bool(healed.get("active", false))
		for unit: Dictionary in view.state.get("combat", {}).get("units", []):
			var visible_shield: bool = not view._dance_vfx_data(unit).is_empty()
			observed["native_shield"] = bool(observed["native_shield"]) or visible_shield
			var expected_shield: bool = view._phase() == "combat" and bool(unit.get("active", false)) and bool(unit.get("alive", false)) and float(unit.get("dance_shield", 0)) > 0.0
			observed["shield_follows_state"] = bool(observed["shield_follows_state"]) and visible_shield == expected_shield
			if visible_shield:
				shielded_before[int(unit["id"])] = true
			elif shielded_before.has(int(unit["id"])):
				observed["shield_stopped"] = true
			if float(unit.get("shield", 0)) > 0.0 and float(unit.get("dance_shield", 0)) <= 0.0 and view._phase() == "combat":
				observed["base_without_dance"] = bool(observed["base_without_dance"]) or not visible_shield
		var michael: Dictionary = view._unit_by_id(5)
		if not michael.is_empty() and bool(michael.get("alive", false)):
			michael_cells[str(michael.get("cell", []))] = true
		if iteration % 25 == 0:
			await process_frame
		if view._phase() in ["round_result", "match_over"]:
			break
	observed["moonwalk"] = michael_cells.size() > 1
	return observed

func _click_point(view: MainView, point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	view._unhandled_input(event)

func _click_cell(view: MainView, cell: Vector2i) -> void:
	_click_point(view, view._cell_position(cell))

func _cell_of(view: MainView, unit_id: int) -> Vector2i:
	return view._cell(view._unit_by_id(unit_id).get("cell", []))

func _click_bench_unit(view: MainView, unit_id: int) -> void:
	_click_point(view, Board.bench_position(view._bench_slot_of(unit_id)))

func _children_inside(panel: Control, bounds: Vector2 = Vector2.ZERO) -> bool:
	var inside: bool = true
	var limit: Rect2 = Rect2(Vector2.ZERO, bounds if bounds != Vector2.ZERO else panel.size)
	for child: Node in panel.get_children():
		if child is Control and (child as Control).visible:
			var rect: Rect2 = (child as Control).get_rect()
			var ok: bool = rect.size == Vector2.ZERO or limit.encloses(rect)
			if not ok:
				print("PANEL_OVERFLOW: ", child.name, " ", rect)
			inside = inside and ok
	return inside

## Injeta ofertas de cópia do Neymar na loja local (somente teste) e confere nível, tamanho e aura.
func _check_copies(view: MainView) -> void:
	if not (view.session.teams[0]["owned"] as Array).has("neymar"):
		var recruit_offer = view.session._offer(0, 88, "hero", "neymar", "Neymar", 0)
		(view.session.teams[0]["shop"] as Array)[3] = recruit_offer
		view.session.apply_command(0, "smoke_recruit_neymar", "recruit", {"offer_id": recruit_offer["offer_id"]})
		view._refresh()
	var base_hp: float = float(view._unit_by_id(1).get("max_hp", 0))
	for total_copies: int in [2, 3, 4]:
		var expected: int = 2 if total_copies < 4 else 3
		var copy_offer = view.session._offer(0, 90 + total_copies, "hero", "neymar", "Neymar", 0)
		copy_offer["offer_id"] += ":copia%d" % total_copies
		(view.session.teams[0]["shop"] as Array)[3] = copy_offer
		view._refresh()
		var offer_id: String = str(copy_offer["offer_id"])
		var button: Button = view.shop_buttons[offer_id]
		var expected_status: String = "CÓPIA 3/4" if total_copies == 3 else "NÍVEL %d" % expected
		_check(str(button.get_meta("status", "")) == expected_status and not button.disabled, "oferta descreve a cópia %d corretamente" % total_copies)
		var gold: int = int(view.state["own"]["gold"])
		var burst_count: int = view.level_bursts.size()
		button.pressed.emit()
		var neymar: Dictionary = view._unit_by_id(1)
		_check(int(neymar.get("level", 1)) == expected and int(view.state["own"]["gold"]) == gold, "cópia grátis leva Neymar ao nível %d" % expected)
		_check(str((view.shop_buttons[offer_id] as Button).get_meta("status", "")) == "RECRUTADO", "oferta usada vira RECRUTADO")
		view._prepare_frame()
		var entry: Dictionary = {}
		for candidate: Dictionary in view.frame_entries:
			if int(candidate["unit"]["id"]) == 1:
				entry = candidate
		_check(not entry.is_empty() and is_equal_approx(float(entry["scale"]), [1.0, 1.2, 1.44][expected - 1]), "sprite cresce 20%% por nível (nível %d)" % expected)
		_check(not entry.is_empty() and is_equal_approx(float(entry["display_scale"]), view.art.board_scale_for("neymar") * [1.0, 1.2, 1.44][expected - 1]), "escala base preserva crescimento de cópias (nível %d)" % expected)
		if total_copies == 3:
			_check(view.level_bursts.size() == burst_count, "terceira cópia guarda progresso sem anunciar evolução falsa")
			_check(view.log_lines.any(func(line: String) -> bool: return line.contains("Cópia incorporada (3/4)")), "log da terceira cópia anuncia progresso, não evolução")
		else:
			_check(view.level_bursts.size() > burst_count and view.floating.any(func(effect: Dictionary) -> bool: return str(effect["text"]) == "NÍVEL %d!" % expected), "efeito e texto da evolução real")
	_check(is_equal_approx(float(view._unit_by_id(1).get("max_hp", 0)), base_hp * 2.25), "nível 3 aplica o multiplicador de vida da Session")
	var max_offer = view.session._offer(0, 94, "hero", "neymar", "Neymar", 0)
	max_offer["offer_id"] += ":copia5"
	(view.session.teams[0]["shop"] as Array)[3] = max_offer
	view._refresh()
	var maxed: Button = view.shop_buttons[str(max_offer["offer_id"])]
	_check(maxed.disabled and str(maxed.get_meta("status", "")) == "NÍVEL MÁX.", "quinta cópia aparece bloqueada no nível máximo")
	await process_frame


## Tamanho no tabuleiro é independente dos PNGs, retratos e vitrines.
func _check_board_display(view: MainView) -> void:
	var targets: Dictionary = {"neymar": 68.0, "caramelo": 56.0, "obama": 70.0, "zumbi": 76.0, "michael": 68.0, "barbie": 72.0, "ken": 74.0, "elon": 68.0, "snoop": 68.0, "lula": 70.0, "bob_marley": 68.0, "rapunzel": 68.0}
	for key: String in targets:
		var front: Texture2D = view.art.statics.get(key) as Texture2D
		if not _check(front != null, "frente N1 disponível para medir " + key):
			continue
		_check(is_equal_approx(view.art.height_for(front) * view.art.board_scale_for(key), float(targets[key])), "altura frontal de teste no tabuleiro: " + key)
		_check(view.art.bounds_for(front, key).end.y <= 0.01, "limites de seleção permanecem alinhados aos pés: " + key)
	_check(view.art.board_scale_for("zumbi") < 1.0 and view.art.board_scale_for("neymar") > 1.0, "Zumbi reduzido e humanoide pequeno ampliado")
	_check(view.art.board_scale_for("unknown") == 1.0, "personagem sem configuração mantém escala nativa")
	var zumbi: Texture2D = view.art.texture_for("zumbi", "south", 0.0)
	if _check(zumbi != null, "Zumbi ativo para conferir lâmina e vitrine"):
		var base_height: float = view.art.height_for(zumbi)
		for level: int in [2, 3]:
			var evolved: Texture2D = view.art.texture_for("zumbi", "south", 0.0, "idle", level)
			_check(evolved != null and view.art.height_for(evolved) > base_height, "lâmina mantém extensão própria no nível %d" % level)
		_check(is_equal_approx(view.art.preview_factor("zumbi"), 48.0 / base_height), "vitrine continua independente da escala do tabuleiro")
	view._prepare_frame()
	for entry: Dictionary in view.frame_entries:
		var unit: Dictionary = entry["unit"]
		var texture: Texture2D = entry.get("texture") as Texture2D
		if texture == null or bool(entry["ghost"]):
			continue
		var key: String = str(unit["key"])
		var display_scale: float = float(entry["display_scale"])
		_check(is_equal_approx(float(entry["height"]), view.art.height_for(texture) * display_scale), "barras seguem a altura desenhada de " + key)
		var pose: Dictionary = entry["pose"]
		var origin: Vector2 = ((entry["feet"] as Vector2) + (pose["offset"] as Vector2)).round()
		var center: Vector2 = view.art.bounds_for(texture, key).get_center() * display_scale
		var picked: Dictionary = view._unit_at_point(origin + center.rotated(float(pose["angle"])))
		_check(int(picked.get("id", -1)) == int(unit["id"]), "clique usa corpo redimensionado de " + key)


func _check_visual_contracts(view: MainView) -> void:
	_check(view.board_perimeter.size() == 62, "grade 8×8 tem somente as 62 arestas externas")
	_check(view.specs.size() >= 12 and view.specs.has("ken"), "onze heróis e a invocação têm descrição de combate")
	_check_board_display(view)
	for key: String in ["neymar", "caramelo", "obama", "zumbi", "michael", "barbie", "ken", "elon", "snoop", "lula", "bob_marley", "rapunzel"]:
		var complete: bool = true
		for direction: String in view.art.DIRECTIONS:
			complete = complete and view.art.texture_for(key, direction, 0) != null
		_check(complete and view.art.portrait_for(key, 30, 28) != null, "arte direcional ou fallback preservado: " + key)
	for key: String in view.art.character_manifest.get("characters", {}):
		var directions: Dictionary = view.art.character_manifest["characters"][key].get("states", {}).get("idle", {}).get("directions", {})
		if directions.get("south", null) is String:
			var front: Texture2D = view.art.texture_for(key, "south", 0)
			_check(front != null and front.resource_path == directions["south"] and view.art.statics[key] == front, "frente e retrato seguem a identidade do manifesto: " + key)
	_check(view.arena_props.size() == 4, "quatro braseiros PixelLab carregados pelo manifesto")
	for prop: Dictionary in view.arena_props:
		_check((prop["texture"] as Texture2D).get_size() == Vector2(32, 48) and Board.pick_cell(Board.project(prop["ground"])) == Board.INVALID, "braseiro nativo fora da grade")
	var parts: Array[Dictionary] = view._shield_parts({"max_hp": 100, "shield": 100, "dance_shield": 50}, 38)
	_check(parts.size() == 2 and parts[0]["kind"] == "dance" and parts[1]["kind"] == "base" and parts[0]["color"] != parts[1]["color"], "dança e mala continuam distinguíveis juntas")
	if parts.size() == 2:
		_check(is_equal_approx(float(parts[0]["width"]) + float(parts[1]["width"]), 38.0) and float(parts[0]["start"]) >= 0, "escudos elevados cabem na largura da barra")
	parts = view._shield_parts({"max_hp": 100, "shield": 30, "dance_shield": 0}, 38)
	_check(parts.size() == 1 and parts[0]["kind"] == "base", "consumir a dança preserva a faixa azul da mala")
	var source: Dictionary = view._unit_by_id(1).duplicate(true)
	var target: Dictionary = view._unit_by_id(3).duplicate(true)
	var original_cell: Vector2i = view._cell(target.get("cell", []))
	for fixture: Array in [["kick", "neymar", "kick"], ["ball_hit", "neymar", "ball_impact"], ["hit", "caramelo", "bite"], ["execute", "caramelo", "bite"], ["bleed", "caramelo", "bleed"], ["hit", "zumbi", "thrust"], ["briefcase_guard", "obama", "guard"], ["assassin_hunt", "caramelo", "hunt"], ["rocket_hit", "elon", "explosion"], ["heal", "michael", "heal"], ["summon", "barbie", "summon"], ["revive", "lula", "revive"]]:
		view.kit_effects.clear()
		source["key"] = fixture[1]
		view._spawn_kit_feedback({"type": fixture[0], "critical": true, "amount": 7, "cell": [3, 3]}, source, target)
		_check(view.kit_effects.size() == 1 and view.kit_effects[0]["kind"] == fixture[2], "feedback distinto: " + fixture[0] + "/" + fixture[1])
	view.kit_effects.clear()
	for duplicate_kind: String in ["ball_launched", "ball_impact", "explosion"]:
		view._spawn_kit_feedback({"type": duplicate_kind}, source, target)
	_check(view.kit_effects.is_empty(), "eventos auxiliares não duplicam bola ou explosão nativa")
	view._spawn_kit_feedback({"type": "splash"}, source, target)
	_check(view.kit_effects.size() == 1 and view.kit_effects[0].get("library_key", "") == "estilhaco_01", "splash mostra só o estouro do vizinho, nunca outra explosão grande")
	view.kit_effects.clear()
	view._spawn_kit_feedback({"type": "lasso", "from": [7, 0], "to": [1, 4]}, source, target)
	_check(view.visual_pulls.has(3) and view.kit_effects[0]["kind"] == "lasso", "laço interpola a posição visual do alvo")
	view._update_visuals(0.15)
	_check(view._cell(view._unit_by_id(3).get("cell", [])) == original_cell, "interpolação do laço não altera célula autoritativa")
	view.floating.clear()
	for kind: String in ["rocket_hit", "splash", "smoke_hit", "smoke", "lasso_hit"]:
		view.session.events.append({"type": kind, "source_id": 1, "target_id": 3, "amount": 7, "critical": false})
	view._consume_events()
	_check(view.floating.filter(func(effect: Dictionary) -> bool: return effect.get("text", "") == "7").size() == 5, "danos dos seis kits novos geram números no cliente")
	view.floating.clear()
	view.selected_id = -1
	view.session.events.append({"type": "hit", "source_id": 1, "target_id": 3, "amount": 0, "absorbed_base": 7, "absorbed_dance": 4})
	view._consume_events()
	_check(view.floating.is_empty(), "absorção não cria textos extras sobre herói não inspecionado")
	view.selected_id = 3
	view.session.events.append({"type": "hit", "source_id": 1, "target_id": 3, "amount": 0, "absorbed_base": 7, "absorbed_dance": 4})
	view._consume_events()
	_check(view.floating.any(func(effect: Dictionary) -> bool: return effect.get("text", "") == "MALA 7") and view.floating.any(func(effect: Dictionary) -> bool: return effect.get("text", "") == "DANÇA 4"), "herói inspecionado mostra absorção de cada escudo")
	view.selected_id = -1
	view._update_visuals(2.0)
	_check(view.kit_effects.is_empty() and view.visual_pulls.is_empty(), "efeitos temporários e puxão são removidos")
	view.floating.clear()
	view.visual_ground.clear()


func _check_vfx_contracts(view: MainView) -> void:
	for key: String in ["escudo_danca_01", "cura_01", "estocada_01", "foguete_01", "fumaca_01", "laco_01", "explosao_02", "foguete_02", "fumaca_02", "anel_fumaca_01", "explosao_03", "estilhaco_01"]:
		_check(view.vfx.has_effect(key), "pacote PixelLab disponível no cliente: " + key)
	_check(view.overlay_layer.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "efeitos frontais usam filtro nearest")
	var source: Dictionary = view._unit_by_id(1).duplicate(true)
	var target: Dictionary = view._unit_by_id(3).duplicate(true)
	var before: String = JSON.stringify(view.session.sim.snapshot())
	view.kit_effects.clear()
	view._spawn_kit_feedback({"type": "heal", "amount": 0}, source, target)
	_check(view.kit_effects.is_empty(), "cura sem vida recuperada não reproduz clip")
	for amount: int in [5, 8]:
		view._spawn_kit_feedback({"type": "heal", "amount": amount}, source, target)
	_check(view.kit_effects.size() == 1 and view.kit_effects[0].get("library_key", "") == "cura_01", "renovação mantém somente um clip de cura por alvo")
	if not view.kit_effects.is_empty():
		var effect: Dictionary = view.kit_effects[0]
		var data: Dictionary = view._library_effect_data(effect)
		_check(not data.is_empty() and data.get("offset", Vector2.ZERO) == Vector2(-9, -20), "cura preserva offset do clip recortado")
		if not data.is_empty():
			_check(data["position"] == (Board.project(view._ground_of(target)) + Vector2(0, -18)).round(), "cura fica presa à posição visual do alvo")
		effect["life"] = 0.0
		_check(view._library_effect_data(effect).is_empty(), "clip de cura não repete após o final")
	view.kit_effects.clear()
	source["key"] = "zumbi"
	view._spawn_kit_feedback({"type": "hit"}, source, target)
	if _check(view.kit_effects.size() == 1, "estocada cria um único feedback"):
		var thrust: Dictionary = view.kit_effects[0]
		_check(thrust.get("library_key", "") == "estocada_01" and is_equal_approx(float(thrust["duration"]), 7.0 / 24.0), "estocada usa os sete quadros e tempo nativos")
		_check(is_equal_approx(float(thrust["angle"]), (view._head_of(target) - view._head_of(source)).angle()), "estocada gira em direção ao alvo sem espelhar pixels")
	view.kit_effects.clear()
	source["key"] = "elon"
	view.blast_zones.clear()
	view.shake_remaining = 0.0
	for kind: String in ["rocket_hit", "explosion", "splash"]:
		view._spawn_kit_feedback({"type": kind, "cell": [3, 3], "radius": 1, "amount": 10}, source, target)
	if _check(view.kit_effects.size() == 2, "impacto gera uma explosão grande e o splash um estouro no vizinho atingido"):
		var blast: Dictionary = view.kit_effects[0]
		_check(blast.get("library_key", "") == "explosao_03" and blast.get("depth", "") == "front" and view._library_effect_data(blast).get("modulate", Color.WHITE).a < 1.0, "explosão grande passa na frente dos corpos, levemente translúcida")
		_check(blast["position"] == Board.project(view._ground_of(target)) and is_equal_approx(float(blast["scale"]), Board.scale_at(view._ground_of(target).y)), "explosão grande nasce no chão do alvo com a perspectiva da célula")
		_check(is_equal_approx(float(blast["duration"]), 17.0 / 18.0), "explosão grande usa os 17 quadros e o tempo nativos")
		var shrapnel: Dictionary = view.kit_effects[1]
		_check(shrapnel.get("library_key", "") == "estilhaco_01" and shrapnel.get("depth", "") == "front" and shrapnel["position"] == Board.project(view._ground_of(target)), "vizinho atingido ganha estouro próprio nos pés")
	_check(view.blast_zones.size() == 1 and int(view.blast_zones[0]["radius"]) == 1 and view._cell(view.blast_zones[0]["cell"]) == Vector2i(3, 3), "área real do evento de explosão acende os hexágonos do raio")
	_check(is_equal_approx(view.shake_remaining, view.SHAKE_DURATION), "impacto do foguete inicia o tremor")
	var shake: Vector2 = view._shake_offset()
	_check(shake == shake.round() and absf(shake.x) <= view.SHAKE_PIXELS and absf(shake.y) <= view.SHAKE_PIXELS, "tremor usa pixels inteiros dentro do limite")
	_check(JSON.stringify(view.session.sim.snapshot()) == before, "efeitos não alteram o estado da simulação")
	view._update_visuals(2.0)
	_check(view.kit_effects.is_empty() and view.blast_zones.is_empty(), "clips one-shot e área acesa são descartados após duração")
	_check(view.shake_remaining == 0.0 and view.position == Vector2.ZERO, "tremor termina e o mundo volta à origem")
	var saved_library = view.vfx
	view.vfx = view.VfxLibrary.new()
	source["key"] = "zumbi"
	view._spawn_kit_feedback({"type": "hit"}, source, target)
	view._spawn_kit_feedback({"type": "explosion", "cell": [3, 3]}, source, target)
	_check(view.kit_effects.size() == 2 and view.kit_effects.all(func(effect: Dictionary) -> bool: return effect.get("library_key", "") == ""), "biblioteca ausente preserva desenhos de estocada e explosão")
	view.vfx = saved_library
	view.kit_effects.clear()
	view._spawn_kit_feedback({"type": "heal", "amount": 5}, source, target)
	var saved_state: Dictionary = view.state.duplicate(true)
	for unit: Dictionary in view.state["own"]["units"]:
		if int(unit["id"]) == int(target["id"]):
			unit["alive"] = false
	_check(view._library_effect_data(view.kit_effects[0]).is_empty(), "cura não é desenhada sobre alvo morto no snapshot")
	view._update_visuals(0.01)
	_check(view.kit_effects.is_empty(), "morte do alvo remove o clip de cura imediatamente")
	view.state = saved_state
	_check(JSON.stringify(view.session.sim.snapshot()) == before, "teste de apresentação não altera a morte ou a vida do núcleo")
	view.floating.clear()
	view.selected_id = -1
	view.session.events.append({"type": "dance_shield", "source_id": 5, "amount": 120})
	view._consume_events()
	_check(view.floating.is_empty(), "quantidade da dança não cria texto sobre Michael não inspecionado")
	view.selected_id = 5
	view.session.events.append({"type": "dance_shield", "source_id": 5, "amount": 120})
	view._consume_events()
	_check(view.floating.size() == 1 and view.floating[0]["text"] == "ESCUDO 120", "Michael inspecionado mostra a quantidade do pulso")
	view.selected_id = -1
	view.floating.clear()
	view.shield_waves.clear()
	view.visual_ground.clear()


func _check_support_vfx_contracts(view: MainView) -> void:
	var saved_state: Dictionary = view.state.duplicate(true)
	var before: String = JSON.stringify(view.session.sim.snapshot())
	var source: Dictionary = view._unit_by_id(1).duplicate(true)
	var target: Dictionary = view._unit_by_id(3).duplicate(true)
	source["active"] = true
	source["alive"] = true
	target["active"] = true
	target["alive"] = true
	source["key"] = "rapunzel"
	target["stun_remaining"] = 1.0
	var zone: Dictionary = {"id": 9001, "source_id": source["id"], "cell": [3, 3], "radius": 1, "remaining": 4.0, "duration": 5.0}
	view.state["phase"] = "combat"
	view.state["combat"] = {"units": [source, target], "zones": [zone]}
	var cloud: Dictionary = view._smoke_vfx_data(zone)
	if _check(not cloud.is_empty(), "zona revelada produz um clip de fumaça"):
		_check(cloud["position"] == Board.cell_position(Vector2i(3, 3)).round() and is_equal_approx(float(cloud["scale"]), Board.cell_scale(Vector2i(3, 3))), "nuvem nova fica no centro da área real com a perspectiva da célula")
		_check(cloud["frame_index"] == view.vfx.frame_data("fumaca_02", 1.0)["frame_index"], "relógio da fumaça usa duration menos remaining")
		_check(cloud.get("modulate", Color.WHITE).a < 1.0, "nuvem nova deixa a grade da área aparecer por baixo")
	var rocket_frame: Dictionary = view._projectile_vfx_data("foguete_02", Vector2(100.4, 50.6), 0.5)
	_check(not rocket_frame.is_empty() and rocket_frame["position"] == Vector2(100, 51) and is_equal_approx(float(rocket_frame["angle"]), 0.5) and rocket_frame["offset"] == Vector2(-58, -5), "foguete em voo usa o clip nativo girado na direção do alvo")
	var ring_frame: Dictionary = view._projectile_vfx_data("anel_fumaca_01", Vector2(10, 10), -1.0)
	_check(not ring_frame.is_empty() and ring_frame["offset"] == Vector2(-38, -15), "tiro do Snoop usa o anel de fumaça nativo")
	zone["remaining"] = 1.0
	_check(not view._smoke_vfx_data(zone).is_empty(), "fumaça continua após vários ciclos do clip nativo")
	source["alive"] = false
	_check(view._smoke_vfx_frames().size() == 1, "morte da fonte não cancela uma zona ainda ativa")
	source["alive"] = true
	zone["remaining"] = 0.0
	_check(view._smoke_vfx_frames().is_empty(), "zona expirada não deixa fumaça visual")
	var replacement: Dictionary = zone.duplicate(true)
	replacement["id"] = 9002
	replacement["cell"] = [4, 3]
	replacement["remaining"] = 5.0
	view.state["combat"]["zones"] = [replacement]
	var clouds: Array[Dictionary] = view._smoke_vfx_frames()
	_check(clouds.size() == 1 and int(clouds[0]["zone_id"]) == 9002 and clouds[0]["position"] == Board.cell_position(Vector2i(4, 3)).round(), "zona substituída não deixa clip no hexágono anterior")
	view.kit_effects.clear()
	for kind: String in ["smoke_cloud", "smoke", "smoke_hit"]:
		view._spawn_kit_feedback({"type": kind, "cell": [4, 3], "amount": 7}, source, target)
	_check(view.kit_effects.is_empty(), "nuvem e dano periódico não criam clips extras por evento")
	for phase: String in ["preparation", "benefit", "menu", "round_result"]:
		view.state["phase"] = phase
		view._spawn_lasso_knot(source, target)
		_check(view._smoke_vfx_frames().is_empty() and view.kit_effects.is_empty(), "fumaça e nó ocultos fora do combate: " + phase)
	view.state["phase"] = "combat"
	view._spawn_kit_feedback({"type": "lasso", "from": [7, 0], "to": target["cell"]}, source, target)
	var knots: Array = view.kit_effects.filter(func(effect: Dictionary) -> bool: return effect.get("kind", "") == "lasso_knot")
	if _check(knots.size() == 1, "um laço cria um nó nativo separado"):
		_check(view.kit_effects.any(func(effect: Dictionary) -> bool: return effect.get("kind", "") == "lasso" and effect.get("library_key", "") == "" and bool(effect.get("native_knot", false))), "fio procedural permanece, sem repetir o arco final")
		var knot: Dictionary = knots[0]
		var first: Dictionary = view._library_effect_data(knot)
		view.visual_ground[int(target["id"])] = Board.ground(Vector2i(3, 4))
		var moved: Dictionary = view._library_effect_data(knot)
		_check(not first.is_empty() and not moved.is_empty() and first["position"] != moved["position"] and moved["position"] == (Board.project(view._ground_of(target)) + Vector2(0, -21)).round(), "nó acompanha o chão interpolado do alvo")
		view._spawn_kit_feedback({"type": "lasso_hit", "amount": 10}, source, target)
		_check(view.kit_effects.filter(func(effect: Dictionary) -> bool: return effect.get("kind", "") == "lasso_knot").size() == 1, "dano do laço não reproduz um segundo nó")
		knot["life"] = 0.0
		_check(view._library_effect_data(knot).is_empty(), "nó one-shot para no fim do clip original")
	# BUG-017: mede os vértices usados pelo desenho em passos reais da interpolação.
	view.kit_effects.clear()
	view.visual_pulls.clear()
	view.visual_ground.clear()
	view._spawn_kit_feedback({"type": "lasso", "from": [7, 0], "to": target["cell"]}, source, target)
	var wires: Array = view.kit_effects.filter(func(effect: Dictionary) -> bool: return effect.get("kind", "") == "lasso")
	if _check(wires.size() == 1, "preparar regressão geométrica do laço"):
		for frame: int in range(6):
			view._update_visuals(0.05)
			var points: PackedVector2Array = view._lasso_points(wires[0])
			var body_point: Vector2 = Board.project(view._ground_of(target)) + Vector2(0, -21)
			var source_point: Vector2 = Board.project(view._ground_of(source)) + Vector2(0, -21)
			_check(points.size() == 13 and points[-1].distance_to(body_point) < 0.001 and points[0].distance_to(source_point) < 0.001, "pontas presas ao corpo durante puxão, passo %d" % frame)
		view.visual_ground[int(source["id"])] = Board.ground(Vector2i(1, 4))
		_check(view._lasso_points(wires[0])[0].distance_to(Board.project(view._ground_of(source)) + Vector2(0, -21)) < 0.001, "origem acompanha uma fonte que mudou de posição visual")
		var orphan: Dictionary = (wires[0] as Dictionary).duplicate(true)
		orphan["source_id"] = -999
		orphan["target_id"] = -998
		var fallback: PackedVector2Array = view._lasso_points(orphan)
		_check(fallback.size() == 13 and fallback[0] == orphan["from"] and fallback[-1].is_finite(), "fio mantém fallback finito quando unidades estão ausentes")
	for stop: String in ["death", "inactive", "stun_ended"]:
		view.kit_effects.clear()
		target["alive"] = true
		target["active"] = true
		target["stun_remaining"] = 1.0
		view._spawn_lasso_knot(source, target)
		if not _check(view.kit_effects.size() == 1, "preparar nó antes de " + stop):
			continue
		if stop == "death":
			target["alive"] = false
		elif stop == "inactive":
			target["active"] = false
		else:
			target["stun_remaining"] = 0.0
		_check(view._library_effect_data(view.kit_effects[0]).is_empty(), "nó deixa de desenhar após " + stop)
		view._update_visuals(0.01)
		_check(view.kit_effects.is_empty(), "nó é removido após " + stop)
	view.kit_effects.clear()
	var saved_library = view.vfx
	view.vfx = view.VfxLibrary.new()
	view._spawn_kit_feedback({"type": "smoke_cloud", "cell": [3, 3]}, source, target)
	view._spawn_kit_feedback({"type": "lasso", "from": [7, 0], "to": [2, 4]}, source, target)
	_check(view.kit_effects.size() == 2 and not bool(view.kit_effects[1].get("native_knot", true)) and view._smoke_vfx_frames().is_empty(), "assets ausentes preservam puffs, fio e arco procedurais")
	_check(view._lasso_points(view.kit_effects[1])[-1].distance_to(Board.project(view._ground_of(target)) + Vector2(0, -21)) < 0.001, "fio continua ancorado sem a biblioteca de assets")
	view.vfx = saved_library
	view.state = saved_state
	view.kit_effects.clear()
	view.visual_pulls.clear()
	view.visual_ground.clear()
	_check(view.state.get("combat", {}).is_empty() and view._smoke_vfx_frames().is_empty(), "snapshot real da preparação não revela zonas do bot")
	_check(JSON.stringify(view.session.sim.snapshot()) == before, "fumaça e nó não alteram o núcleo")


## Elenco de teste montado por comandos da Session, sem alterar vida, dano ou resultado.
func _check_new_kits_match(view: MainView) -> void:
	view._start_match()
	_choose_gold(view)
	var lineups: Array = [["barbie", "elon", "snoop", "lula", "bob_marley"], ["rapunzel", "neymar", "obama", "caramelo", "michael"]]
	var fixture_id: int = 0
	for team: int in range(2):
		if int(view.session.teams[team]["capacity"]) < 5:
			fixture_id += 1
			var expansion: Dictionary = view.session.apply_command(team, "visual_fixture_%d" % fixture_id, "upgrade_capacity")
			if not _check(bool(expansion.get("ok", false)), "expandir formação de teste do time %d" % team):
				return
		for unit in view.session.sim.units:
			if unit.team == team and unit.active and not lineups[team].has(unit.key):
				fixture_id += 1
				var reserve: Dictionary = view.session.apply_command(team, "visual_fixture_%d" % fixture_id, "bench", {"unit_id": unit.id})
				if not _check(bool(reserve.get("ok", false)), "guardar inicial para testar novo elenco"):
					return
		for key: String in lineups[team]:
			if (view.session.teams[team]["owned"] as Array).has(key):
				continue
			fixture_id += 1
			view.session.teams[team]["shop"][3] = view.session._offer(team, 3, "hero", key, view.specs[key].display_name, 0)
			view.session.teams[team]["shop"][3]["offer_id"] += ":visual%d" % fixture_id
			var recruit: Dictionary = view.session.apply_command(team, "visual_fixture_%d" % fixture_id, "recruit", {"offer_id": view.session.teams[team]["shop"][3]["offer_id"]})
			if not _check(bool(recruit.get("ok", false)), "recrutar grátis para teste visual: " + key):
				return
	view._consume_events()
	view._refresh()
	for unit_id: int in [6, 7, 8, 9, 10]:
		view._select_unit(unit_id)
		_check(view.unit_card.visible and _children_inside(view.card_root, view.unit_card.size), "cartão do novo herói cabe no painel: %d" % unit_id)
	view._fight()
	if not _check(view._phase() == "combat", "formação dos novos kits começa combate"):
		return
	var seen: Dictionary = {"ken": false, "rocket": false, "smoke": false, "zone": false, "lasso": false, "native_rocket": false, "native_smoke": false, "native_knot": false, "moving_knot": false, "replaced_zone": false, "blast_zone": false, "mana_fill": false}
	var knot_positions: Dictionary = {}
	var source_zones: Dictionary = {}
	var zones_match: bool = true
	var lasso_samples: int = 0
	var lasso_anchors_match: bool = true
	var captured_mana: bool = false
	for iteration: int in range(710):
		view._process(0.05)
		for unit: Dictionary in view.state.get("combat", {}).get("units", []):
			seen["ken"] = bool(seen["ken"]) or unit.get("key", "") == "ken"
			if unit.get("key", "") == "rapunzel" and float(unit.get("mana", 0)) > 0.0:
				var mana: Dictionary = view._mana_bar_data(unit)
				seen["mana_fill"] = bool(seen["mana_fill"]) or (not mana.is_empty() and float(mana["width"]) > 0.0)
				if not captured_mana:
					var previous_selection: int = view.selected_id
					view._select_unit(int(unit["id"]))
					var combat_mana_text: Label = view.card_root.get_node_or_null("ManaText") as Label
					_check(combat_mana_text != null and combat_mana_text.text == "MANA  %d / %d" % [int(unit["mana"]), int(unit["max_mana"])], "cartão atualiza mana real em linha própria durante o combate")
					await _capture_ui_if_requested(view, "mana_combate")
					view._select_unit(previous_selection)
					captured_mana = true
		for projectile: Dictionary in view.state.get("combat", {}).get("projectiles", []):
			var kind: String = str(projectile.get("kind", "ball"))
			if seen.has(kind):
				seen[kind] = true
		seen["zone"] = bool(seen["zone"]) or not view.state.get("combat", {}).get("zones", []).is_empty()
		seen["lasso"] = bool(seen["lasso"]) or view.kit_effects.any(func(effect: Dictionary) -> bool: return effect.get("kind", "") == "lasso")
		seen["native_rocket"] = bool(seen["native_rocket"]) or view.kit_effects.any(func(effect: Dictionary) -> bool: return effect.get("library_key", "") == "explosao_03")
		seen["blast_zone"] = bool(seen["blast_zone"]) or not view.blast_zones.is_empty()
		var smoke_frames: Array[Dictionary] = view._smoke_vfx_frames()
		seen["native_smoke"] = bool(seen["native_smoke"]) or not smoke_frames.is_empty()
		zones_match = zones_match and smoke_frames.size() == (view.state.get("combat", {}).get("zones", []) as Array).size()
		for cloud: Dictionary in smoke_frames:
			var source_id: int = int(cloud["source_id"])
			if source_zones.has(source_id) and int(source_zones[source_id]) != int(cloud["zone_id"]):
				seen["replaced_zone"] = true
			source_zones[source_id] = int(cloud["zone_id"])
		for effect: Dictionary in view.kit_effects:
			if effect.get("kind", "") == "lasso":
				var pulled: Dictionary = view._unit_by_id(int(effect.get("target_id", -1)))
				var caster: Dictionary = view._unit_by_id(int(effect.get("source_id", -1)))
				if not pulled.is_empty() and not caster.is_empty():
					var wire_points: PackedVector2Array = view._lasso_points(effect)
					lasso_samples += 1
					lasso_anchors_match = lasso_anchors_match and wire_points[-1].distance_to(Board.project(view._ground_of(pulled)) + Vector2(0, -21)) < 0.001 and wire_points[0].distance_to(Board.project(view._ground_of(caster)) + Vector2(0, -21)) < 0.001
			if effect.get("library_key", "") != "laco_01":
				continue
			var knot_data: Dictionary = view._library_effect_data(effect)
			if knot_data.is_empty():
				continue
			seen["native_knot"] = true
			var target_id: int = int(effect["target_id"])
			if knot_positions.has(target_id) and (knot_positions[target_id] as Vector2).distance_to(knot_data["position"]) > 1.0:
				seen["moving_knot"] = true
			knot_positions[target_id] = knot_data["position"]
		if iteration % 25 == 0:
			await process_frame
		if view._phase() in ["round_result", "match_over"]:
			break
	for kind: String in seen:
		_check(bool(seen[kind]), "novo combate integrado apresentou " + kind)
	_check(lasso_samples > 5 and lasso_anchors_match, "fio acompanha fonte e alvo em todos os quadros amostrados do combate real")
	_check(view._phase() in ["round_result", "match_over"], "combate com novos kits termina sem interromper interface")
	_check(zones_match and view._smoke_vfx_frames().is_empty() and view.state.get("combat", {}).get("zones", []).is_empty(), "zonas visuais acompanham o snapshot real e somem ao terminar")
	_check(not view.kit_effects.any(func(effect: Dictionary) -> bool: return effect.get("library_key", "") == "laco_01"), "fim do combate remove nós nativos")
	await process_frame
	var result_rows: ScrollContainer = view.overlay.get_node_or_null("ResultRows") as ScrollContainer
	if _check(result_rows != null, "tabela de resultados tem área própria de rolagem"):
		_check(result_rows.get_rect().end.y < view.next_button.position.y and result_rows.clip_contents, "resultado não cruza o botão da próxima rodada")
		var table: Control = result_rows.get_node("Table") as Control
		_check(table.custom_minimum_size.y == 6 * 44 and table.size.y <= result_rows.size.y, "seis unidades, incluindo Ken, cabem na área reservada")
		_check(_children_inside(table), "todos os controles das seis linhas ficam dentro da tabela")
		result_rows.scroll_vertical = 1000
		await process_frame
		_check(result_rows.scroll_vertical == 0, "as seis linhas permanecem visíveis sem deslocar a tabela ou o botão")

## Fixture independente: saldo elevado só para povoar a bolsa, sem testar balanceamento.
func _check_dismiss_controls(scene: PackedScene) -> void:
	var probe: MainView = scene.instantiate() as MainView
	root.add_child(probe)
	await process_frame
	probe.set_process(false)
	probe.audio.set_enabled(false)
	probe._start_match()
	_choose_gold(probe)
	probe.session.teams[0]["gold"] = 100
	for key: String in ["neymar", "rapunzel"]:
		var offer: Dictionary = probe.session._offer(0, 3, "hero", key, key, 0)
		offer["offer_id"] += ":dismiss_" + key
		probe.session.teams[0]["shop"][3] = offer
		if not _check(bool(probe._command("recruit", {"offer_id": offer["offer_id"]}).get("ok", false)), "recrutar fixture de dispensar: " + key):
			probe.queue_free()
			return
	var rapunzel_id: int = -1
	for unit: Dictionary in probe.state["own"]["units"]:
		if unit.get("key", "") == "rapunzel":
			rapunzel_id = int(unit["id"])
	if not _check(rapunzel_id > 0, "Rapunzel disponível para fixture de reserva/mana"):
		probe.queue_free()
		return
	probe._select_unit(1)
	var gold: int = int(probe.state["own"]["gold"])
	_check(probe.dismiss_button.visible and not probe.dismiss_button.disabled and _children_inside(probe.unit_card), "dispensar cabe no cartão e fica ativo na preparação")
	probe.dismiss_button.pressed.emit()
	_check(not (probe.state["own"]["owned"] as Array).has("neymar") and probe.selected_id == -1, "botão dispensa herói do campo e limpa seleção")
	_check(int(probe.state["own"]["gold"]) == gold, "dispensar não vende por ouro")
	var replacement: Dictionary = probe.session._offer(0, 3, "hero", "neymar", "Neymar", 0)
	replacement["offer_id"] += ":dismiss_replacement"
	probe.session.teams[0]["shop"][3] = replacement
	probe._command("recruit", {"offer_id": replacement["offer_id"]})
	probe._select_unit(rapunzel_id)
	_check(probe._mana_bar_data(probe._selected_own()).get("maximum", 0) == 100.0, "mana de Rapunzel vem do snapshot real")
	var mana_text: Label = probe.card_root.get_node_or_null("ManaText") as Label
	var hp_text: RichTextLabel = probe.card_root.get_node_or_null("HpText") as RichTextLabel
	_check(mana_text != null and hp_text != null and not hp_text.text.contains("MANA") and mana_text.position.y >= hp_text.position.y + hp_text.size.y and _children_inside(probe.unit_card), "mana tem linha própria e cartão ampliado preserva limites dos controles")
	await _capture_ui_if_requested(probe, "dispensar_preparacao")
	for index: int in range(2):
		var item: Dictionary = _buy_dismiss_fixture_item(probe, index)
		if item.is_empty():
			probe.queue_free()
			return
		probe._command("equip", {"unit_id": rapunzel_id, "item_id": item["id"]})
	probe._bench_or_deploy()
	_check(not bool(probe._selected_own().get("active", true)) and probe.dismiss_button.visible, "dispensar também atende herói da reserva")
	for index: int in range(8):
		if _buy_dismiss_fixture_item(probe, 10 + index).is_empty():
			probe.queue_free()
			return
	var before_bag: String = JSON.stringify(probe.state["own"]["bag"])
	var before_equipment: String = JSON.stringify(probe.state["own"]["equipment"])
	gold = int(probe.state["own"]["gold"])
	probe.dismiss_button.pressed.emit()
	_check((probe.state["own"]["owned"] as Array).has("rapunzel") and probe.selected_id == rapunzel_id, "bolsa cheia preserva herói e seleção")
	_check(JSON.stringify(probe.state["own"]["bag"]) == before_bag and JSON.stringify(probe.state["own"]["equipment"]) == before_equipment and int(probe.state["own"]["gold"]) == gold, "falha de dispensar é atômica para bolsa/equipamento/ouro")
	_check(probe.toast_text == "Bolsa cheia", "recusa de bolsa cheia fica visível")
	await _capture_ui_if_requested(probe, "dispensar_bolsa_cheia")
	for index: int in range(2):
		var bag: Array = probe.state["own"]["bag"]
		probe._command("equip", {"unit_id": 1, "item_id": bag[-1]["id"]})
	probe.dismiss_button.pressed.emit()
	_check(not (probe.state["own"]["owned"] as Array).has("rapunzel") and (probe.state["own"]["bag"] as Array).size() == 8, "com espaço, dispensar reserva devolve todos os itens")
	_check(int(probe.state["own"]["gold"]) == gold and probe.selected_id == -1, "dispensar equipado não altera ouro e fecha o cartão")
	probe._select_unit(1)
	probe._fight()
	var command_index: int = probe.command_index
	probe._dismiss_selected()
	_check(not probe.dismiss_button.visible and probe.command_index == command_index and (probe.state["own"]["owned"] as Array).has("neymar"), "combate oculta dispensar e não envia comando proibido")
	probe.queue_free()
	await process_frame


func _buy_dismiss_fixture_item(probe: MainView, index: int) -> Dictionary:
	var price: int = int(probe.state["item_catalog"]["charm"]["price"])
	var offer: Dictionary = probe.session._offer(0, 0, "item", "charm", "Trevo", price)
	offer["offer_id"] += ":dismiss_item%d" % index
	probe.session.teams[0]["shop"][0] = offer
	if not _check(bool(probe._command("buy_item", {"offer_id": offer["offer_id"]}).get("ok", false)), "comprar item de fixture %d" % index):
		return {}
	var bag: Array = probe.state["own"]["bag"]
	return bag[-1] if not bag.is_empty() else {}


## Captura opcional somente do viewport desta aplicação, sem ler a tela do computador.
func _capture_ui_if_requested(view: MainView, name: String) -> void:
	if not "--capture-ui" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	view._prepare_frame()
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://captures")
	var image: Image = root.get_texture().get_image()
	var path: String = folder.path_join("tabuleiro_maior_" + name + ".png")
	if not _check(image != null and not image.is_empty() and image.save_png(path) == OK, "capturar viewport da UI: " + name):
		return
	var report: FileAccess = FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"viewport": [1280, 720], "phase": view._phase(), "selected_unit": view._unit_by_id(view.selected_id), "income": view.state.get("own", {}).get("income", {}), "win_streak": view.state.get("own", {}).get("win_streak", 0), "front_hex_width": Board.FRONT_HEX_WIDTH}, "\t"))
		report.close()


func _run() -> void:
	create_timer(20).timeout.connect(_timeout)
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if not _check(scene != null, "carregar cena"):
		await _finish(null)
		return
	var view: MainView = scene.instantiate() as MainView
	if not _check(view != null, "instanciar visor"):
		await _finish(null)
		return
	root.add_child(view)
	await process_frame
	view.set_process(false)
	_check(view._phase() == "menu" and view.start_button != null, "inicia no menu")
	_check(view.arena != null and view.arena.resource_path == MainView.ARENA_PATH and view.arena.get_width() > 0, "fundo ativo da arena HD carregado")
	for team: int in range(2):
		var visible_hearts: int = 0
		for icon: TextureRect in view.heart_controls[team]:
			_check(icon.texture == view.heart and view.ui.is_ancestor_of(icon), "coração pertence à interface")
			visible_hearts += 1 if icon.visible else 0
		_check(visible_hearts == 4, "quatro corações visíveis no início")
	var coin_definition: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/icons/coin_sheet.json"))
	var coin_frame: Vector2i = Vector2i.ZERO
	if coin_definition is Dictionary:
		var coin_meta: Dictionary = coin_definition.get("meta", {})
		coin_frame = Vector2i(int(coin_meta.get("frame_width", 0)), int(coin_meta.get("frame_height", 0)))
	_check(coin_frame.x > 0 and coin_frame.y > 0, "manifesto da moeda HD declara tamanho do quadro")
	for icon_name: String in ["fx_ball", "ui_star", "syn_atacantes", "syn_atiradores", "syn_apoio", "item_blade", "item_great_blade", "item_vest", "item_guard_vest", "item_boots", "item_plate", "item_ward", "item_charm", "ui_coin", "ui_refresh"]:
		var texture: Texture2D = Kit.icon(icon_name)
		var expected_size: Vector2i = coin_frame if icon_name == "ui_coin" else Vector2i(16, 16)
		_check(texture != null and texture.get_size() == Vector2(expected_size), "dimensões originais do ícone " + icon_name)
	for key: String in ["neymar", "caramelo", "obama", "zumbi", "michael"]:
		_check(view.art.portrait_for(key, 30, 28) != null, "retrato recortado de " + key)
	_check(view.audio.streams.size() >= 20 and not view.audio.streams["heal"].data.is_empty() and view.audio.streams.has("bob_marley_8bit"), "efeitos de combate e single 8-bit de Bob Marley sintetizados em memória")
	view.sound_button.pressed.emit()
	_check(not view.audio.enabled, "controle de som desativa")
	view.sound_button.pressed.emit()
	_check(view.audio.enabled, "controle de som ativa")
	_check(view.art.frame_count == 72, "72 quadros originais de dança carregados")
	_check(view.art.directional_frames.size() == 8, "oito direções animadas carregadas")
	_check(view.art.state_rotations.size() == 2, "dois conjuntos originais de rotações preservados")
	for direction: String in view.art.DIRECTIONS:
		var frames: Array = view.art.directional_frames.get(direction, [])
		if _check(frames.size() == 9, "nove quadros em " + direction):
			_check(view.art.anchor_for(frames[0], "michael") == view.art.anchor_for(frames[8], "michael"), "âncora fixa em " + direction)
			_check(view.art.texture_for("michael", direction, 0) != view.art.texture_for("michael", direction, 0.11), "tempo contínuo avança quadro " + direction)
	view._set_animation_fps(12)
	_check(view.art.fps == 12, "ajuste visual de FPS")
	view._set_animation_fps(10)
	_check_play_button_without_network(view)
	view._start_match() # As próximas fixtures exercitam deliberadamente o bot local.
	_check(view._phase() == "benefit" and view.benefit_buttons.size() == 3, "nova partida mostra três benefícios")
	_check(view.overlay.visible and view.overlay_dim.visible, "benefício aparece sobre fundo escurecido")
	var initial_gold: int = int(view.state["own"]["gold"])
	var gold_benefit: int = 0
	for option: Dictionary in view.state["own"]["benefit_options"]:
		if option.get("kind", "") == "gold":
			gold_benefit = int(option.get("gold", 0))
	_check(initial_gold == 20, "partida recebe as 20 moedas iniciais da Session")
	_choose_gold(view)
	_check(view._phase() == "preparation" and not view.overlay.visible, "benefício leva à preparação")
	_check(int(view.state["own"]["gold"]) == initial_gold + gold_benefit, "visor recebe ouro inicial e benefício da Session")
	_check(view._active_count() == 0, "campo limpo aguardando recrutamento inicial")
	_check(not bool(view._unit_by_id(5).get("active", false)), "Michael fora do campo inicialmente")
	_check(view.state["enemy"]["units"].is_empty(), "preparação inicial sem formação secreta do bot")
	_check(view.shop_buttons.size() == 7, "sete ofertas renderizadas na nova loja ampliada")

	# Povoa o campo de teste recrutando 4 heróis para validar contratos visuais e manuseio no tabuleiro
	for key: String in ["neymar", "caramelo", "obama", "michael"]:
		var setup_offer = view.session._offer(0, 80 + view.session.teams[0]["owned"].size(), "hero", key, key, 0)
		(view.session.teams[0]["shop"] as Array).append(setup_offer)
		view.session.apply_command(0, "smoke_setup_" + key, "recruit", {"offer_id": setup_offer["offer_id"]})
	view._refresh()
	await process_frame

	_check_visual_contracts(view)
	_check_vfx_contracts(view)
	_check_support_vfx_contracts(view)
	for row: int in range(8):
		for column: int in range(8):
			var cell: Vector2i = Vector2i(column, row)
			_check(view._pick_cell(view._cell_position(cell)) == cell, "projeção/seleção " + str(cell))
	_check(Board.cell_scale(Vector2i(0, 0)) < Board.cell_scale(Vector2i(0, 7)), "perspectiva: fundo menor que a frente")
	_check(Board.FRONT_HEX_WIDTH == 90.0, "hexágono frontal ampliado de 76 para 90 pixels")
	var clear_layout: bool = true
	var reserve_separated: bool = true
	for row: int in range(8):
		for column: int in range(8):
			var polygon: PackedVector2Array = Board.hex_polygon(Vector2i(column, row))
			for point: Vector2 in polygon:
				clear_layout = clear_layout and point.x > 226.0 and point.x < 1040.0 and point.y > 120.0 and point.y < 596.0
			for slot: int in range(Board.BENCH_SLOTS):
				reserve_separated = reserve_separated and Geometry2D.intersect_polygons(polygon, Board.bench_polygon(slot)).is_empty()
	_check(clear_layout, "perímetro maior não atravessa HUD lateral nem loja")
	_check(reserve_separated, "todos os hexágonos da reserva permanecem separados da grade")
	_check(view.income_label.text == "PRÓXIMA +%d · SÉRIE %d" % [int(view.state["own"]["income"]["next_round_total"]), int(view.state["own"]["win_streak"])], "HUD mostra renda e sequência reais da Session")
	_check(view._income_view({})["text"] == "RENDA —", "snapshot sem renda não ganha valor inventado")
	_check(view._mana_bar_data({"hp": 100}).is_empty(), "unidade sem mana não ganha barra falsa")
	_check(is_equal_approx(float(view._mana_bar_data({"mana": 25, "max_mana": 100})["width"]), 9.5), "barra de mana representa fração do estado")
	_check(float(view._mana_bar_data({"mana": -10, "max_mana": 100})["width"]) == 0.0 and float(view._mana_bar_data({"mana": 120, "max_mana": 100})["width"]) == 38.0, "desenho de mana fica dentro dos limites da barra")
	_check(view._preview_max_hp(view.specs["barbie"], 3, 2.25) == 1200.0 and view._preview_max_hp(view.specs["ken"], 3, 2.25) == 2300.0, "compêndio respeita HP específico por nível de Barbie e Ken")
	for slot: int in range(Board.BENCH_SLOTS):
		_check(Board.pick_bench(Board.bench_position(slot)) == slot and Board.pick_cell(Board.bench_position(slot)) == Board.INVALID, "reserva no chão separada do tabuleiro " + str(slot))
	_click_cell(view, _cell_of(view, 1))
	_check(view.selected_id == 1 and view.unit_card.visible, "toque no herói seleciona e abre cartão")
	_click_cell(view, Vector2i(0, 7))
	_check(_cell_of(view, 1) == Vector2i(0, 7), "posicionamento válido via Session")
	_click_cell(view, Vector2i(0, 0))
	_check(_cell_of(view, 1) == Vector2i(0, 7) and view.toast_remaining > 0.0, "posicionamento inimigo rejeitado com aviso")
	view.bench_button.pressed.emit()
	_check(not bool(view._unit_by_id(1).get("active", true)) and view._bench_slot_of(1) == 0, "botão envia herói à reserva")
	_click_cell(view, Vector2i(0, 7))
	_check(bool(view._unit_by_id(1).get("active", false)), "clique coloca reserva em campo")
	_click_cell(view, Vector2i(0, 7))
	_check(view.selected_id == -1, "tocar no herói selecionado desfaz a seleção")
	_click_cell(view, _cell_of(view, 1))
	_click_point(view, Board.bench_position(0))
	_check(not bool(view._unit_by_id(1).get("active", true)), "tocar na reserva vazia guarda o herói selecionado")
	_click_bench_unit(view, 1)
	_check(view.selected_id == -1, "tocar no próprio herói da reserva desfaz a seleção")
	_click_bench_unit(view, 1)
	_check(view.selected_id == 1, "tocar no herói da reserva o seleciona")
	_click_cell(view, Vector2i(0, 7))
	_check(bool(view._unit_by_id(1).get("active", false)), "herói volta da reserva pelo chão")
	_click_cell(view, Vector2i(0, 7))
	var zumbi_offer = view.session._offer(0, 3, "hero", "zumbi", "Zumbi", 0)
	view.session.teams[0]["shop"][3] = zumbi_offer
	view._refresh()
	(view.shop_buttons[str(zumbi_offer["offer_id"])] as Button).pressed.emit()
	_check(view.state["own"]["bench"].has(4), "herói gratuito entra na reserva com campo cheio")
	var obama_cell: Vector2i = _cell_of(view, 3)
	_click_cell(view, obama_cell)
	_click_bench_unit(view, 4)
	_check(_cell_of(view, 4) == obama_cell and not bool(view._unit_by_id(3).get("active", true)), "troca herói em campo com a reserva")
	_check(view.selected_id == 3, "herói trocado continua selecionado na reserva")
	_click_cell(view, obama_cell)
	_check(_cell_of(view, 3) == obama_cell and not bool(view._unit_by_id(4).get("active", true)), "troca da reserva para o campo")
	_click_cell(view, obama_cell)
	var expansion_gold_before: int = int(view.state["own"]["gold"])
	var expansion_price: int = int(view.state["test_config"]["upgrade_cost"])
	view.capacity_button.pressed.emit()
	_check(int(view.state["own"]["capacity"]) == 5 and int(view.state["own"]["gold"]) == expansion_gold_before - expansion_price, "capacidade e moedas vêm da Session")
	view.session.teams[0]["capacity"] = 8
	view._refresh()
	_check(view.capacity_button.disabled and view.capacity_btn_label != null and view.capacity_btn_label.text == "CAMPO MÁX.", "capacidade máxima desativa compra")
	view.session.teams[0]["capacity"] = 5
	view._refresh()
	_click_bench_unit(view, 4)
	_check(view.selected_id == 4, "herói da reserva selecionado pelo chão")
	_click_cell(view, Vector2i(0, 4))
	_check(view._active_count() == 5, "quinto herói colocado após expansão")
	var first_offer: Dictionary = view.state["own"]["shop"][0]
	(view.shop_buttons[str(first_offer["offer_id"])] as Button).pressed.emit()
	_check(view.state["own"]["bag"].size() == 1 and view.bag_buttons.size() == 1, "comprar item adiciona à bolsa visível")
	_check(_children_inside(view.bag_panel) and _children_inside(view.bag_root, view.bag_panel.size), "slots e botões dentro do painel de itens")
	var item_id: String = str(view.state["own"]["bag"][0]["id"])
	(view.bag_buttons[item_id] as Button).pressed.emit()
	_check(view.selected_items == [item_id] and not view.equip_button.disabled, "item marcado habilita EQUIPAR com herói selecionado")
	view.equip_button.pressed.emit()
	_check(view.state["own"]["bag"].is_empty() and view.state["own"]["equipment"][4].size() == 1, "equipar por controles")
	_check(view.equipment_buttons.size() == 4 and not view.equipment_buttons[0].disabled, "cartão mostra item equipado")
	view.equipment_buttons[0].pressed.emit()
	_check(view.state["own"]["bag"].size() == 1 and view.state["own"]["equipment"][4].is_empty(), "retirar equipamento devolve bolsa")
	_click_cell(view, Vector2i(0, 4))
	_check(view.selected_id == -1, "seleção desfeita antes do toque-para-equipar")
	item_id = str(view.state["own"]["bag"][0]["id"])
	(view.bag_buttons[item_id] as Button).pressed.emit()
	_click_cell(view, Vector2i(0, 4))
	_check(view.state["own"]["equipment"][4].size() == 1 and view.selected_id == 4, "item marcado + toque no herói equipa")
	view.equipment_buttons[0].pressed.emit()
	var gold_before: int = int(view.state["own"]["gold"])
	view.reroll_button.pressed.emit()
	_check(int(view.state["own"]["gold"]) == gold_before - 2 and view.shop_buttons.size() == 7, "renovação custa duas moedas")
	view._toggle_drawer("synergies")
	_check(view.drawer.visible and _children_inside(view.drawer), "gaveta mostra sinergias de teste")
	view._toggle_drawer("synergies")
	await _check_copies(view)
	var prep_time: float = float(view.state["prep_remaining"])
	view._process(1)
	_check(float(view.state["prep_remaining"]) == prep_time - 1, "preparação usa relógio da Session")
	view.fight_button.pressed.emit()
	if not _check(view._phase() == "combat", "LUTAR inicia combate"):
		await _finish(view)
		return
	var expected_active: int = 0
	for authoritative_unit: Variant in view.session.sim.units:
		if authoritative_unit.active:
			expected_active += 1
	_check(view.state["combat"]["units"].size() == expected_active and expected_active >= 5, "revelação contém todos os ativos da formação real do bot e do jogador")
	var before_cell: Vector2i = _cell_of(view, 1)
	_click_cell(view, Vector2i(1, 7))
	_check(_cell_of(view, 1) == before_cell, "combate bloqueia posicionamento")
	var enemy_unit: Dictionary = {}
	for u: Dictionary in view.state["combat"]["units"]:
		if int(u.get("team", 0)) == 1:
			enemy_unit = u
			break
	if not enemy_unit.is_empty():
		var enemy_id: int = int(enemy_unit["id"])
		_click_cell(view, _cell_of(view, enemy_id))
		_check(view.selected_id == enemy_id and view.unit_card.visible, "combate permite inspecionar inimigo")
	var observed: Dictionary = await _advance_combat(view)
	_check(view._phase() == "round_result", "combate chega ao resultado")
	_check(bool(observed["projectile"]), "bola recebida e interpolada pelo visor")
	_check(bool(observed["damage"]), "números de dano exibidos")
	_check(bool(observed["heal"]), "números de cura de Michael exibidos")
	_check(bool(observed["dance_shield"]), "onda do escudo da dança exibida")
	_check(bool(observed["moonwalk"]), "Michael muda de hexágono durante o moonwalk")
	_check(bool(observed["native_heal"]) and bool(observed["native_thrust"]) and bool(observed["native_shield"]), "combate real reproduz cura, estocada e escudo PixelLab")
	_check(bool(observed["shield_follows_state"]), "escudo PixelLab acompanha consumo, morte e fase reais")
	_check(bool(observed["base_without_dance"]), "mala real absorve dano sem criar a bolha dourada da dança")
	_check(bool(observed["shield_stopped"]), "bolha dourada some ao encerrar a proteção real")
	_check(bool(observed["heals_on_living_only"]), "clips de cura no combate real pertencem a alvos vivos em campo")
	_check(not view.result_label.text.is_empty() and view.next_button != null, "resultado e próximo botão visíveis")
	_check(not view.result_label.visible and view.overlay.get_node_or_null("ResultHeading") != null, "resultado tem apenas título do overlay visível")
	_check(not view.state["combat"]["result"].get("units_summary", []).is_empty(), "estatísticas reais presentes")
	var gold_end: int = int(view.state["own"]["gold"])
	var next_income: int = int(view.state["own"]["income"]["next_round_total"])
	view.next_button.pressed.emit()
	_check(view.kit_effects.is_empty(), "próxima rodada limpa os clips transitórios")
	_check(view._smoke_vfx_frames().is_empty() and view.visual_pulls.is_empty(), "próxima rodada não mantém fumaça ou puxões")
	_check(view._phase() == "preparation" and int(view.state["round"]) == 2, "próxima rodada")
	_check(int(view.state["own"]["gold"]) == gold_end + next_income, "renda de rodada recebida conforme previsão autoritativa")
	_check(not view.state["enemy"]["units"].is_empty() and int(view.state["enemy"]["previous_round"]) == 1, "somente formação inimiga anterior recebida")
	_click_cell(view, view._cell(view.state["enemy"]["units"][0]["cell"]))
	_check(view.unit_card.visible and not view.bench_button.visible, "formação anterior inimiga é só consulta")
	# Várias rodadas normais exercitam fim de partida; sem alterar HP ou vidas.
	for round_test: int in range(12):
		if view._phase() == "match_over":
			break
		if view._phase() == "benefit":
			_choose_gold(view)
		if view._phase() == "preparation":
			view.fight_button.pressed.emit()
			await _advance_combat(view)
		if view._phase() == "round_result":
			view.next_button.pressed.emit()
	_check(view._phase() == "match_over" and int(view.state["match_winner"]) >= 0, "ciclo normal chega ao fim da partida")
	if view._phase() == "match_over":
		view.next_button.pressed.emit()
		_check(view._phase() == "benefit" and view.state["lives"] == [4, 4], "nova partida restaura vidas e benefício")
		for option: Dictionary in view.state["own"]["benefit_options"]:
			if option.get("kind", "") == "life":
				(view.benefit_buttons[str(option["option_id"])] as Button).pressed.emit()
				break
		_check(int(view.state["lives"][0]) == 5 and (view.heart_controls[0][4] as TextureRect).visible, "benefício de vida mostra quinto coração")
	await _check_new_kits_match(view)
	view._spawn_kit_feedback({"type": "heal", "amount": 5}, {"id": 5, "key": "michael"}, view._unit_by_id(1))
	view._open_menu()
	_check(view._phase() == "menu", "retorno ao menu")
	_check(view.kit_effects.is_empty(), "menu limpa os clips transitórios")
	_check(view._smoke_vfx_frames().is_empty() and view.visual_pulls.is_empty(), "menu oculta zonas e limpa puxões")
	# A fixture abaixo instancia outra cena; esconder também o CanvasLayer original
	# evita capturar dois lobbies/HUDs sobrepostos no mesmo viewport.
	view.visible = false
	view.ui.visible = false
	await _check_dismiss_controls(scene)
	view.visible = true
	view.ui.visible = true
	await _finish(view)
