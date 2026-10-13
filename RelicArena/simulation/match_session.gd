extends RefCounted
## Authoritative local match wrapper. The UI sends commands; it never spends gold.
## V1 numbers below are test configuration, not approved balancing or monetization.

const Core = preload("res://simulation/arena_simulation.gd")
const Grid = preload("res://simulation/hex_grid.gd")
const Catalog = preload("res://data/character_catalog.gd")
const Items = preload("res://data/item_catalog.gd")
const UnitState = preload("res://simulation/unit_state.gd")
const UnitSpec = preload("res://data/unit_spec.gd")
const INITIAL_GOLD: int = 20
const ROUND_INCOME: int = 9
const ROUND_INCOME_GROWTH: int = 3
const WIN_STREAK_BONUS: int = 1
const REROLL_COST: int = 2
const INITIAL_CAPACITY: int = 4
const MAX_CAPACITY: int = 8
const UPGRADE_COST: int = 8
const BAG_CAPACITY: int = 8
const EQUIPMENT_SLOTS: int = 4
const PREPARATION_SECONDS: float = 30.0
const MAX_LIVES: int = 5
## Cinco espaços de reserva, mantidos nesta revisão.
const BENCH_CAPACITY: int = 5
const INITIAL_KEYS: Array[String] = []


var sim: Core = Core.new()
var phase: String = "benefit"
var prep_remaining: float = PREPARATION_SECONDS
var teams: Array[Dictionary] = []
var events: Array[Dictionary] = []
var _rngs: Array[RandomNumberGenerator] = []
var _commands: Array[Dictionary] = [{}, {}]
var _previous_formations: Array = [[], []]
var _previous_round: int = 0
var _seed: int = 20261011
var _item_counters: Array[int] = [0, 0]
var _bot_counter: int = 0
var _settled_economy_rounds: Dictionary = {}
## Partida online (servidor): o time 1 é outro jogador humano, então o bot não prepara nada.
var bot_enabled: bool = true

func _init(seed_value: int = 20261011) -> void:
	reset(seed_value)

func reset(seed_value: int = 20261011) -> void:
	_seed = seed_value
	sim.reset(seed_value)
	sim.synergy_enabled = true
	teams.clear()
	_rngs.clear()
	events.clear()
	_commands = [{}, {}]
	_previous_formations = [[], []]
	_previous_round = 0
	_item_counters = [0, 0]
	_bot_counter = 0
	_settled_economy_rounds.clear()
	for team: int in range(2):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value + team * 104729
		_rngs.append(rng)
		teams.append({"gold": INITIAL_GOLD, "capacity": INITIAL_CAPACITY,
			"owned": [], "copies": _initial_copies(), "bag": [], "equipment": {}, "shop": [],
			"shop_revision": 0, "benefit_options": [], "benefit_rounds": [],
			"extra_life_used": false, "ready": false, "win_streak": 0,
			"pending_win_bonus": 0, "last_income_paid": 0})
	var roster: Array[Dictionary] = []
	for team: int in range(2):
		for index: int in range(Catalog.KEYS.size()):
			var key: String = Catalog.KEYS[index]
			roster.append({"id": team * 100 + index + 1, "key": key,
				"team": team, "cell": Grid.INVALID, "active": false})
	sim.preparation_setup(roster)
	_open_preparation()

func _initial_copies() -> Dictionary:
	return {}

func _max_copies() -> int:
	var thresholds: Array = sim.level_rules.get("copies_for_level", [1, 2, 4])
	return int(thresholds[thresholds.size() - 1])

func _open_preparation() -> void:
	phase = "preparation"
	prep_remaining = PREPARATION_SECONDS
	for team: int in range(2):
		teams[team]["ready"] = false
		teams[team]["shop_revision"] = 0
		_refresh_shop(team)
		teams[team]["benefit_options"] = []
		if sim.round_index == 1:
			_offer_benefits(team)
		_apply_all_equipment(team)
	if sim.round_index == 4:
		_setup_boss_round()
	else:
		_cleanup_boss_round()
		if bot_enabled:
			_bot_prepare()
	_sync_preparation_phase()
	_collect_core_events()
	_emit("preparation_started", {"round": sim.round_index, "is_boss": sim.is_boss_round})

func _sync_preparation_phase() -> void:
	if sim.phase == "preparation":
		phase = "benefit" if not (teams[0]["benefit_options"] as Array).is_empty() else "preparation"

func apply_command(team: int, command_id: String, operation: String, payload: Dictionary = {}) -> Dictionary:
	if team < 0 or team > 1 or command_id.is_empty() or command_id.length() > 128:
		return _fail("invalid_actor_or_id")
	if _commands[team].has(command_id):
		var cached: Dictionary = _commands[team][command_id]
		if cached["operation"] != operation or cached["payload"] != payload:
			return _fail("command_id_reused")
		return (cached["result"] as Dictionary).duplicate(true)
	var result: Dictionary = _dispatch(team, operation, payload) if _valid_payload(operation, payload) else _fail("invalid_payload")
	_commands[team][command_id] = {"operation": operation, "payload": payload.duplicate(true), "result": result.duplicate(true)}
	_collect_core_events()
	return result.duplicate(true)

func _valid_payload(operation: String, payload: Dictionary) -> bool:
	var string_field: String = ""
	if operation in ["buy_item", "recruit"]:
		string_field = "offer_id"
	elif operation == "choose_benefit":
		string_field = "option_id"
	if not string_field.is_empty() and not payload.get(string_field, null) is String:
		return false
	if operation in ["place", "bench", "deploy", "equip", "unequip", "dismiss"] and not _integer(payload.get("unit_id", null)):
		return false
	if operation == "swap" and (not _integer(payload.get("active_id", null)) or not _integer(payload.get("bench_id", null))):
		return false
	if operation in ["equip", "unequip"] and not payload.get("item_id", null) is String:
		return false
	if operation == "fuse":
		var ids: Variant = payload.get("item_ids", null)
		if not ids is Array or ids.size() != 2:
			return false
		for identifier: Variant in ids:
			if not identifier is String:
				return false
	return true

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and absf(float(value)) < 1000000.0

static func upgrade_cost_for(capacity: int) -> int:
	return 8 + (capacity - INITIAL_CAPACITY) * 4

static func income_for_round(round_number: int) -> int:
	return ROUND_INCOME + maxi(0, round_number - 1) * ROUND_INCOME_GROWTH

func _dispatch(team: int, operation: String, payload: Dictionary) -> Dictionary:
	if operation == "next_round":
		if (team != 0 and bot_enabled) or phase != "round_result" or sim.phase != "finished" or sim.match_winner >= 0:
			return _fail("wrong_phase")
		_settle_round_economy()
		if not sim.next_round():
			return _fail("wrong_phase")
		for side: int in range(2):
			var income: int = income_for_round(sim.round_index) + int(teams[side]["pending_win_bonus"])
			teams[side]["gold"] = int(teams[side]["gold"]) + income
			teams[side]["last_income_paid"] = income
			teams[side]["pending_win_bonus"] = 0
		_open_preparation()
		return _ok()
	if operation in ["equip", "buy_item"]:
		if not phase in ["benefit", "preparation", "combat"] or not sim.phase in ["preparation", "combat"]:
			return _fail("wrong_phase")
		if operation == "equip":
			return _equipment(team, operation, payload)
		else:
			return _buy_item(team, str(payload.get("offer_id", "")))
	if not phase in ["benefit", "preparation"] or sim.phase != "preparation":
		return _fail("wrong_phase")
	match operation:
		"choose_benefit": return _choose_benefit(team, str(payload.get("option_id", "")))
		"ready":
			if _active_count(team) == 0:
				return _fail("empty_formation")
			_auto_benefit(team)
			teams[team]["ready"] = true
			if bool(teams[0]["ready"]) and bool(teams[1]["ready"]):
				_begin_combat()
			return _ok()
		"reroll":
			if int(teams[team]["gold"]) < REROLL_COST:
				return _fail("not_enough_gold")
			teams[team]["gold"] = int(teams[team]["gold"]) - REROLL_COST
			teams[team]["shop_revision"] = int(teams[team]["shop_revision"]) + 1
			_refresh_shop(team)
			_emit("shop_refreshed", {"team": team, "cost": REROLL_COST})
			return _ok()
		"buy_item": return _buy_item(team, str(payload.get("offer_id", "")))
		"recruit": return _recruit(team, str(payload.get("offer_id", "")))
		"upgrade_capacity":
			var cur_cap: int = int(teams[team]["capacity"])
			if cur_cap >= MAX_CAPACITY:
				return _fail("capacity_maximum")
			var cost: int = upgrade_cost_for(cur_cap)
			if int(teams[team]["gold"]) < cost:
				return _fail("not_enough_gold")
			teams[team]["gold"] = int(teams[team]["gold"]) - cost
			teams[team]["capacity"] = cur_cap + 1
			_emit("capacity_upgraded", {"team": team, "capacity": cur_cap + 1})
			return _ok({"capacity": cur_cap + 1})
		"place", "deploy", "bench": return _position(team, operation, payload)
		"swap": return _swap(team, payload)
		"dismiss": return _dismiss(team, int(payload.get("unit_id", -1)))
		"equip", "unequip": return _equipment(team, operation, payload)
		"fuse": return _fuse(team, payload)
	return _fail("unknown_operation")

func _refresh_shop(team: int) -> void:
	var shop: Array[Dictionary] = []
	for slot: int in range(3):
		var key: String = Items.SHOP_KEYS[_rngs[team].randi_range(0, Items.SHOP_KEYS.size() - 1)]
		var definition: Dictionary = Items.definition(key)
		shop.append(_offer(team, slot, "item", key, str(definition["name"]), int(definition["price"])))
	var heroes: Array[String] = []
	## Cópias de heróis já possuídos também aparecem; quem está no nível máximo sai do sorteio.
	var pool: Array[String] = []
	for key: String in Catalog.KEYS:
		if int((teams[team]["copies"] as Dictionary).get(key, 0)) < _max_copies():
			pool.append(key)
	while heroes.size() < mini(4, pool.size()):
		var key: String = pool[_rngs[team].randi_range(0, pool.size() - 1)]
		if not heroes.has(key):
			heroes.append(key)
	for index: int in range(heroes.size()):
		shop.append(_offer(team, index + 3, "hero", heroes[index], sim.specs[heroes[index]].display_name, 0))
	teams[team]["shop"] = shop

func _offer(team: int, slot: int, kind: String, key: String, name: String, price: int) -> Dictionary:
	return {"offer_id": "%d:%d:%d:%d" % [team, sim.round_index, int(teams[team]["shop_revision"]), slot],
		"kind": kind, "key": key, "name": name, "price": price, "claimed": false}

func _find_offer(team: int, offer_id: String) -> Dictionary:
	for offer: Dictionary in teams[team]["shop"]:
		if str(offer["offer_id"]) == offer_id:
			return offer
	return {}

func _buy_item(team: int, offer_id: String) -> Dictionary:
	var offer: Dictionary = _find_offer(team, offer_id)
	if offer.is_empty() or offer["kind"] != "item" or bool(offer["claimed"]):
		return _fail("invalid_offer")
	if (teams[team]["bag"] as Array).size() >= BAG_CAPACITY:
		return _fail("bag_full")
	if int(teams[team]["gold"]) < int(offer["price"]):
		return _fail("not_enough_gold")
	var item: Dictionary = _new_item(team, str(offer["key"]))
	teams[team]["gold"] = int(teams[team]["gold"]) - int(offer["price"])
	(teams[team]["bag"] as Array).append(item)
	offer["claimed"] = true
	_emit("item_bought", {"team": team, "item_id": item["id"], "key": item["key"]})
	return _ok(item)

func _recruit(team: int, offer_id: String) -> Dictionary:
	var offer: Dictionary = _find_offer(team, offer_id)
	if offer.is_empty() or offer["kind"] != "hero" or bool(offer["claimed"]):
		return _fail("invalid_offer")
	var key: String = str(offer["key"])
	var unit = _unit_for_key(team, key)
	if unit == null:
		return _fail("unknown_hero")
	if (teams[team]["owned"] as Array).has(key):
		return _add_copy(team, offer, unit)
	if _active_count(team) >= int(teams[team]["capacity"]) and _bench_count(team) >= BENCH_CAPACITY:
		return _fail("bench_full")
	if _active_count(team) < int(teams[team]["capacity"]):
		var cell: Vector2i = _first_free_cell(team)
		if cell == Grid.INVALID or not sim.set_active(unit.id, true, cell):
			return _fail("invalid_placement")
	(teams[team]["owned"] as Array).append(key)
	teams[team]["copies"][key] = 1
	offer["claimed"] = true
	_emit("hero_recruited", {"team": team, "unit_id": unit.id})
	return _ok({"unit_id": unit.id, "active": unit.active, "level": 1, "copies": 1})

## Cópia gratuita junta imediatamente; nem toda cópia alcança um novo nível.
func _add_copy(team: int, offer: Dictionary, unit) -> Dictionary:
	var key: String = str(offer["key"])
	var copies: int = int((teams[team]["copies"] as Dictionary).get(key, 1))
	if copies >= _max_copies():
		return _fail("max_level")
	var previous_level: int = unit.level
	var level: int = Catalog.level_for_copies(copies + 1, sim.level_rules)
	var level_changed: bool = level != previous_level
	if not sim.set_unit_level(unit.id, level):
		return _fail("wrong_phase")
	teams[team]["copies"][key] = copies + 1
	offer["claimed"] = true
	_emit("hero_upgraded", {"team": team, "unit_id": unit.id, "level": level,
		"copies": copies + 1, "previous_level": previous_level, "level_changed": level_changed})
	return _ok({"unit_id": unit.id, "active": unit.active, "level": level,
		"copies": copies + 1, "previous_level": previous_level, "level_changed": level_changed})

func _position(team: int, operation: String, payload: Dictionary) -> Dictionary:
	var unit = _owned_unit(team, int(payload.get("unit_id", -1)))
	if unit == null:
		return _fail("not_owned")
	if operation == "bench":
		if not unit.active:
			return _fail("not_active")
		if _bench_count(team) >= BENCH_CAPACITY:
			return _fail("bench_full")
		if not sim.set_active(unit.id, false):
			return _fail("not_active")
		return _ok()
	var destination: Vector2i = _cell(payload.get("cell", null))
	if not Grid.belongs_to_team(destination, team):
		return _fail("invalid_placement")
	if operation == "place":
		return _ok() if unit.active and sim.place_unit(unit.id, destination) else _fail("invalid_placement")
	if unit.active:
		return _fail("already_active")
	if _active_count(team) >= int(teams[team]["capacity"]):
		return _fail("capacity_full")
	return _ok() if sim.set_active(unit.id, true, destination) else _fail("invalid_placement")

func _swap(team: int, payload: Dictionary) -> Dictionary:
	var active = _owned_unit(team, int(payload.get("active_id", -1)))
	var reserve = _owned_unit(team, int(payload.get("bench_id", -1)))
	if active == null or reserve == null or not active.active or reserve.active:
		return _fail("invalid_swap")
	var previous: Vector2i = active.cell
	if not sim.set_active(active.id, false):
		return _fail("invalid_swap")
	if not sim.set_active(reserve.id, true, previous):
		sim.set_active(active.id, true, previous)
		return _fail("invalid_swap")
	return _ok()

func _dismiss(team: int, unit_id: int) -> Dictionary:
	var unit = _owned_unit(team, unit_id)
	if unit == null or unit.summoned:
		return _fail("not_owned")
	var equipped: Array = (teams[team]["equipment"] as Dictionary).get(unit_id, []).duplicate(true)
	var bag: Array = (teams[team]["bag"] as Array).duplicate(true)
	# Check capacity before touching ownership, runtime stats, level or formation.
	if bag.size() + equipped.size() > BAG_CAPACITY:
		return _fail("bag_full")
	# All three core operations are valid for this existing unit in preparation.
	if not sim.apply_equipment(unit_id, {}, []):
		return _fail("equipment_rejected")
	sim.set_unit_level(unit_id, 1)
	sim.set_active(unit_id, false)
	bag.append_array(equipped)
	teams[team]["bag"] = bag
	(teams[team]["owned"] as Array).erase(unit.key)
	(teams[team]["copies"] as Dictionary).erase(unit.key)
	(teams[team]["equipment"] as Dictionary).erase(unit_id)
	_emit("hero_dismissed", {"team": team, "unit_id": unit_id, "returned_items": equipped.duplicate(true)})
	return _ok({"unit_id": unit_id, "returned_items": equipped, "gold": 0})

func _equipment(team: int, operation: String, payload: Dictionary) -> Dictionary:
	var unit = _owned_unit(team, int(payload.get("unit_id", -1)))
	if unit == null:
		return _fail("not_owned")
	var item_id: String = str(payload.get("item_id", ""))
	var equipped: Array = (teams[team]["equipment"] as Dictionary).get(unit.id, []).duplicate(true)
	var bag: Array = (teams[team]["bag"] as Array).duplicate(true)
	var index: int = _item_index(bag if operation == "equip" else equipped, item_id)
	if index < 0:
		return _fail("invalid_item")
	if operation == "equip":
		if phase == "combat" and (not unit.alive or not unit.active):
			return _fail("unit_not_in_combat")
		if equipped.size() >= EQUIPMENT_SLOTS:
			return _fail("equipment_full")
		equipped.append(bag[index])
		bag.remove_at(index)
	else:
		if phase == "combat":
			return _fail("cannot_unequip_during_combat")
		if bag.size() >= BAG_CAPACITY:
			return _fail("bag_full")
		bag.append(equipped[index])
		equipped.remove_at(index)
	if not sim.apply_equipment(unit.id, Items.modifiers(equipped), equipped):
		return _fail("equipment_rejected")
	teams[team]["equipment"][unit.id] = equipped
	teams[team]["bag"] = bag
	_emit("equipment_changed", {"team": team, "unit_id": unit.id})
	return _ok()

func _fuse(team: int, payload: Dictionary) -> Dictionary:
	var identifiers: Variant = payload.get("item_ids", [])
	if not identifiers is Array or identifiers.size() != 2 or identifiers[0] == identifiers[1]:
		return _fail("invalid_recipe")
	var bag: Array = (teams[team]["bag"] as Array).duplicate(true)
	var first: int = _item_index(bag, str(identifiers[0]))
	var second: int = _item_index(bag, str(identifiers[1]))
	if first < 0 or second < 0:
		return _fail("invalid_item")
	var output: String = Items.fused_key(str(bag[first]["key"]), str(bag[second]["key"]))
	if output.is_empty():
		return _fail("invalid_recipe")
	bag.remove_at(maxi(first, second))
	bag.remove_at(mini(first, second))
	var item: Dictionary = _new_item(team, output)
	bag.append(item)
	teams[team]["bag"] = bag
	_emit("items_fused", {"team": team, "key": output})
	return _ok(item)

func _offer_benefits(team: int) -> void:
	if (teams[team]["benefit_rounds"] as Array).has(sim.round_index):
		return
	var item_key: String = Items.SHOP_KEYS[_rngs[team].randi_range(0, Items.SHOP_KEYS.size() - 1)]
	var choices: Array[Dictionary] = [
		{"kind": "gold", "name": "Bolsa de moedas", "description": "+8 moedas · teste", "gold": 8},
		{"kind": "item", "name": "Presente", "description": "Um item grátis: " + str(Items.definition(item_key)["name"]), "item_keys": [item_key]}
	]
	if not bool(teams[team]["extra_life_used"]):
		choices.append({"kind": "life", "name": "Segunda chance", "description": "+1 coração; uma vez por partida · teste"})
	else:
		choices.append({"kind": "item_bundle", "name": "Kit de equipamento", "description": "Lâmina e colete grátis · teste", "item_keys": ["blade", "vest"]})
	# Fisher-Yates uses only the team's reproducible RNG.
	for index: int in range(choices.size() - 1, 0, -1):
		var other: int = _rngs[team].randi_range(0, index)
		var swap: Dictionary = choices[index]
		choices[index] = choices[other]
		choices[other] = swap
	for index: int in range(choices.size()):
		choices[index]["option_id"] = "%d:%d:benefit:%d" % [team, sim.round_index, index]
	teams[team]["benefit_options"] = choices

func _choose_benefit(team: int, option_id: String) -> Dictionary:
	var choice: Dictionary = {}
	for candidate: Dictionary in teams[team]["benefit_options"]:
		if str(candidate["option_id"]) == option_id:
			choice = candidate
	if choice.is_empty() or (teams[team]["benefit_rounds"] as Array).has(sim.round_index):
		return _fail("invalid_benefit")
	var keys: Array = choice.get("item_keys", [])
	if (teams[team]["bag"] as Array).size() + keys.size() > BAG_CAPACITY:
		return _fail("bag_full")
	if choice["kind"] == "life":
		if bool(teams[team]["extra_life_used"]) or sim.team_lives[team] >= MAX_LIVES:
			return _fail("extra_life_limit")
		sim.team_lives[team] += 1
		teams[team]["extra_life_used"] = true
	teams[team]["gold"] = int(teams[team]["gold"]) + int(choice.get("gold", 0))
	for key: String in keys:
		(teams[team]["bag"] as Array).append(_new_item(team, key))
	(teams[team]["benefit_rounds"] as Array).append(sim.round_index)
	teams[team]["benefit_options"] = []
	_sync_preparation_phase()
	_emit("benefit_selected", {"team": team, "kind": choice["kind"]})
	return _ok()

func _auto_benefit(team: int) -> void:
	var choices: Array = (teams[team]["benefit_options"] as Array).duplicate(true)
	for choice: Dictionary in choices:
		if choice["kind"] == "gold":
			_choose_benefit(team, str(choice["option_id"]))
			return

func _begin_combat() -> void:
	for team: int in range(2):
		_auto_benefit(team)
		if _active_count(team) == 0:
			for key: String in teams[team]["owned"]:
				var unit = _unit_for_key(team, key)
				if sim.set_active(unit.id, true, _first_free_cell(team)):
					break
			if _active_count(team) == 0:
				for offer: Dictionary in teams[team]["shop"]:
					if offer["kind"] == "hero" and not bool(offer["claimed"]):
						_recruit(team, str(offer["offer_id"]))
						break
		_apply_all_equipment(team)
	if not sim.start_combat():
		return
	_previous_round = sim.round_index
	for team: int in range(2):
		_previous_formations[team] = _formation_snapshot(team)
	phase = "combat"
	_collect_core_events()

func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var remaining: float = delta
	if phase in ["benefit", "preparation"]:
		var preparation_delta: float = minf(prep_remaining, remaining)
		prep_remaining = maxf(0.0, prep_remaining - preparation_delta)
		remaining -= preparation_delta
		if prep_remaining <= 0.000001:
			_begin_combat()
	if phase == "combat" and remaining > 0.0:
		sim.step(remaining)
		_collect_core_events()
		if sim.phase == "finished":
			_settle_round_economy()
			phase = "match_over" if sim.match_winner >= 0 else "round_result"
			if sim.is_boss_round and not bool((teams[0] as Dictionary).get("boss_resolved_r%d" % sim.round_index, false)):
				teams[0]["boss_resolved_r%d" % sim.round_index] = true
				_resolve_boss_rewards()

func _settle_round_economy() -> void:
	if sim.phase != "finished" or _settled_economy_rounds.has(sim.round_index):
		return
	_settled_economy_rounds[sim.round_index] = true
	var winner: int = int(sim.round_result.get("winner", -1))
	for team: int in range(2):
		teams[team]["pending_win_bonus"] = 0
		if not sim.is_boss_round:
			if winner == team:
				teams[team]["win_streak"] = int(teams[team]["win_streak"]) + 1
				if int(teams[team]["win_streak"]) >= 2:
					teams[team]["pending_win_bonus"] = WIN_STREAK_BONUS
			elif winner >= 0:
				teams[team]["win_streak"] = 0
		_emit("round_economy_resolved", {"team": team,
			"win_streak": teams[team]["win_streak"], "win_bonus": teams[team]["pending_win_bonus"]})

var _boss_sidelined_units: Array[int] = []

func _setup_boss_round() -> void:
	sim.is_boss_round = true
	_boss_sidelined_units.clear()
	for unit in sim.units:
		if unit.team == 1 and unit.active:
			_boss_sidelined_units.append(unit.id)
			unit.active = false
	var boss_unit = sim.get_unit(999)
	var boss_def = sim.summon_specs.get("boss_dev", null)
	if boss_def != null:
		if boss_unit == null:
			boss_unit = UnitState.new(boss_def, 999, 1, Vector2i(4, 1))
			sim.units.append(boss_unit)
		else:
			boss_unit.cell = Vector2i(4, 1)
			boss_unit.previous_cell = Vector2i(4, 1)
			boss_unit.hp = boss_unit.max_hp
			boss_unit.alive = true
			boss_unit.active = true
	teams[1]["ready"] = true

func _cleanup_boss_round() -> void:
	sim.is_boss_round = false
	var boss_unit = sim.get_unit(999)
	if boss_unit != null:
		boss_unit.active = false
	for u_id: int in _boss_sidelined_units:
		var u = sim.get_unit(u_id)
		if u != null:
			u.active = true
	_boss_sidelined_units.clear()

func _resolve_boss_rewards() -> void:
	var winner: int = int(sim.round_result.get("winner", -1))
	if winner == 0 and sim.is_boss_round and sim.boss_defeated():
		var rewards: Array[Dictionary] = []
		for drop_idx: int in range(3):
			var roll: float = _rngs[0].randf()
			if roll < 0.20 and sim.team_lives[0] < MAX_LIVES:
				sim.team_lives[0] += 1
				rewards.append({"kind": "life", "name": "Vida Extra", "description": "+1 Coração de Vida Extra!", "amount": 1})
			elif roll < 0.60:
				var gold_amt: int = 10
				teams[0]["gold"] = int(teams[0]["gold"]) + gold_amt
				rewards.append({"kind": "gold", "name": "Ouro do Criador", "description": "+%d Moedas de Ouro" % gold_amt, "amount": gold_amt})
			else:
				var item_key: String = Items.SHOP_KEYS[_rngs[0].randi_range(0, Items.SHOP_KEYS.size() - 1)]
				var def: Dictionary = Items.definition(item_key)
				if (teams[0]["bag"] as Array).size() < BAG_CAPACITY:
					var item_obj: Dictionary = _new_item(0, item_key)
					(teams[0]["bag"] as Array).append(item_obj)
					rewards.append({"kind": "item", "key": item_key, "name": str(def["name"]), "description": "+1 " + str(def["name"])})
				else:
					var fallback_gold: int = int(def.get("price", 5))
					teams[0]["gold"] = int(teams[0]["gold"]) + fallback_gold
					rewards.append({"kind": "gold", "name": "Moedas de Ouro", "description": "+%d Moedas de Ouro" % fallback_gold, "amount": fallback_gold})
		teams[0]["boss_rewards"] = rewards
		_emit("boss_rewards_awarded", {"rewards": rewards})
	else:
		teams[0]["boss_rewards"] = []
		_emit("boss_escaped", {"message": "O Boss escapou! Nenhum prêmio resgatado desta vez."})

func _bot_prepare() -> void:
	# Runs before player input; never inspects the player's current positions/items.
	_auto_benefit(1)
	_bot_command("upgrade_capacity")
	for offer: Dictionary in (teams[1]["shop"] as Array).duplicate(true):
		if offer["kind"] == "hero":
			_bot_command("recruit", {"offer_id": offer["offer_id"]})
	for offer: Dictionary in (teams[1]["shop"] as Array).duplicate(true):
		if offer["kind"] == "item":
			_bot_command("buy_item", {"offer_id": offer["offer_id"]})
	var bag: Array = (teams[1]["bag"] as Array).duplicate(true)
	for item: Dictionary in bag:
		var target_unit = null
		var candidates: Array = ["neymar", "elon", "snoop", "caramelo", "obama"] if item["key"] in ["blade", "boots", "charm"] else ["obama", "barbie", "lula", "michael"]
		for preferred_key: String in candidates:
			if (teams[1]["owned"] as Array).has(preferred_key):
				target_unit = _unit_for_key(1, preferred_key)
				break
		if target_unit == null and not (teams[1]["owned"] as Array).is_empty():
			target_unit = _unit_for_key(1, str(teams[1]["owned"][0]))
		if target_unit != null:
			_bot_command("equip", {"unit_id": target_unit.id, "item_id": item["id"]})
	teams[1]["ready"] = true

func _bot_command(operation: String, payload: Dictionary = {}) -> void:
	_bot_counter += 1
	apply_command(1, "bot_%d" % _bot_counter, operation, payload)

func _apply_all_equipment(team: int) -> void:
	for unit in sim.units:
		if unit.team == team:
			var equipped: Array = (teams[team]["equipment"] as Dictionary).get(unit.id, []).duplicate(true)
			sim.apply_equipment(unit.id, Items.modifiers(equipped), equipped)

func _active_count(team: int) -> int:
	var count: int = 0
	for unit in sim.units:
		if unit.team == team and unit.active and not unit.summoned:
			count += 1
	return count

func _bench_count(team: int) -> int:
	var count: int = 0
	for unit in sim.units:
		if unit.team == team and not unit.active and not unit.summoned and (teams[team]["owned"] as Array).has(unit.key):
			count += 1
	return count

func _first_free_cell(team: int) -> Vector2i:
	for row: int in range(4, 8) if team == 0 else range(0, 4):
		for column: int in range(8):
			var cell: Vector2i = Vector2i(column, row)
			var free: bool = true
			for unit in sim.units:
				if unit.active and unit.cell == cell:
					free = false
					break
			if free:
				return cell
	return Grid.INVALID

func _owned_unit(team: int, unit_id: int):
	var unit = sim.get_unit(unit_id)
	if unit != null and unit.team == team and (teams[team]["owned"] as Array).has(unit.key):
		return unit
	return null

func _unit_for_key(team: int, key: String):
	for unit in sim.units:
		if unit.team == team and unit.key == key:
			return unit
	return null

func _cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() == 2 and _integer(value[0]) and _integer(value[1]):
		return Vector2i(value[0], value[1])
	return Grid.INVALID

func _new_item(team: int, key: String) -> Dictionary:
	# Separate counters prevent own item IDs revealing the opponent's purchases.
	_item_counters[team] += 1
	return {"id": "%d:item:%d" % [team, _item_counters[team]], "key": key}

func _item_index(items: Array, item_id: String) -> int:
	for index: int in range(items.size()):
		if str(items[index]["id"]) == item_id:
			return index
	return -1

func _formation_snapshot(team: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit in sim.units:
		if unit.team == team and unit.active and not unit.summoned:
			result.append({"id": unit.id, "key": unit.key, "name": unit.display_name,
				"team": team, "cell": [unit.cell.x, unit.cell.y], "active": true, "alive": true, "level": unit.level,
				"equipment": (teams[team]["equipment"] as Dictionary).get(unit.id, []).duplicate(true)})
	return result

## Benefício pendente é individual: no PvP um jogador pode estar escolhendo enquanto o outro já prepara.
func _phase_for_team(team: int) -> String:
	if phase in ["benefit", "preparation"] and sim.phase == "preparation":
		return "benefit" if not (teams[team]["benefit_options"] as Array).is_empty() else "preparation"
	return phase

func snapshot_for_team(team: int) -> Dictionary:
	if team < 0 or team > 1:
		return {}
	var own: Dictionary = teams[team].duplicate(true)
	var own_units: Array[Dictionary] = []
	var bench: Array[int] = []
	for unit in sim.units:
		if unit.team == team and (own["owned"] as Array).has(unit.key):
			own_units.append(unit.as_dictionary())
			if not unit.active and not (sim.is_boss_round and team == 1):
				bench.append(unit.id)
	own["units"] = own_units
	own["bench"] = bench
	own["synergies"] = sim.preview_synergies(team)
	own["bag_capacity"] = BAG_CAPACITY
	own["equipment_slots"] = EQUIPMENT_SLOTS
	own["income"] = {"base": ROUND_INCOME, "growth": ROUND_INCOME_GROWTH,
		"current_round_base": income_for_round(sim.round_index), "next_round": sim.round_index + 1,
		"next_round_base": income_for_round(sim.round_index + 1), "win_bonus": int(own["pending_win_bonus"]),
		"next_round_total": income_for_round(sim.round_index + 1) + int(own["pending_win_bonus"]),
		"last_paid": int(own["last_income_paid"])}
	var combat: Dictionary = {}
	if phase in ["combat", "round_result", "match_over"]:
		var visible: Array[Dictionary] = []
		for unit in sim.units:
			if unit.active:
				visible.append(unit.as_dictionary())
		var projectiles: Array[Dictionary] = []
		for ball in sim.projectiles:
			projectiles.append(ball.as_dictionary())
		combat = {"units": visible, "projectiles": projectiles, "zones": sim.zones.duplicate(true), "result": sim.round_result.duplicate(true),
			"synergy_snapshot": sim.synergy_snapshot.duplicate(true)}
	var enemy_units_preview: Array = []
	if sim.is_boss_round or sim.round_index == 4:
		var boss_u = sim.get_unit(999)
		if boss_u != null:
			enemy_units_preview = [{
				"id": boss_u.id, "key": "boss_dev", "name": boss_u.display_name,
				"team": 1, "cell": [boss_u.cell.x, boss_u.cell.y], "active": true, "alive": true,
				"level": 1, "is_boss": true, "hp": boss_u.hp, "max_hp": boss_u.max_hp, "equipment": []
			}]
		else:
			enemy_units_preview = [{
				"id": 999, "key": "boss_dev", "name": "Desenvolvedor (Boss)",
				"team": 1, "cell": [4, 1], "active": true, "alive": true,
				"level": 1, "is_boss": true, "hp": 10000.0, "max_hp": 10000.0, "equipment": []
			}]
	else:
		enemy_units_preview = (_previous_formations[1 - team] as Array).duplicate(true)
	return {"phase": _phase_for_team(team), "prep_remaining": prep_remaining, "round": sim.round_index,
		"lives": sim.team_lives.duplicate(), "match_winner": sim.match_winner,
		"elapsed": sim.elapsed, "accelerated": sim.accelerated, "own": own,
		"is_boss_round": sim.is_boss_round, "boss_rewards": (teams[team] as Dictionary).get("boss_rewards", []),
		"enemy": {"units": enemy_units_preview, "previous_round": _previous_round},
		"combat": combat, "recipes": Items.RECIPES.duplicate(true), "item_catalog": Items.ITEMS.duplicate(true),
		"test_config": {"initial_gold": INITIAL_GOLD, "round_income": ROUND_INCOME,
			"round_income_growth": ROUND_INCOME_GROWTH, "win_streak_bonus": WIN_STREAK_BONUS, "reroll_cost": REROLL_COST,
			"upgrade_cost": upgrade_cost_for(int(teams[team]["capacity"])), "max_capacity": MAX_CAPACITY, "bag_capacity": BAG_CAPACITY,
			"equipment_slots": EQUIPMENT_SLOTS, "preparation_seconds": PREPARATION_SECONDS, "bench_capacity": BENCH_CAPACITY,
			"copies_for_level": (sim.level_rules.get("copies_for_level", [1, 2, 4]) as Array).duplicate(true),
			"power_multiplier": (sim.level_rules.get("power_multiplier", [1.0, 1.5, 2.25]) as Array).duplicate(true)}}

func _collect_core_events() -> void:
	for event: Dictionary in sim.drain_events():
		events.append(event)
	while events.size() > 2048:
		events.pop_front()

func _emit(kind: String, values: Dictionary = {}) -> void:
	var event: Dictionary = values.duplicate(true)
	event["type"] = kind
	event["round"] = sim.round_index
	events.append(event)

func drain_events(team: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in events:
		if not event.has("team") or int(event["team"]) == team:
			result.append(event.duplicate(true))
	events.clear()
	return result

func drain_events_by_team() -> Array[Array]:
	var per_team: Array[Array] = [[], []]
	for event: Dictionary in events:
		if not event.has("team") or int(event["team"]) == 0:
			per_team[0].append(event.duplicate(true))
		if not event.has("team") or int(event["team"]) == 1:
			per_team[1].append(event.duplicate(true))
	events.clear()
	return per_team

func _ok(data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "code": "ok", "data": data}

func _fail(code: String) -> Dictionary:
	return {"ok": false, "code": code, "data": {}}
