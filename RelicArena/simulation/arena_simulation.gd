extends RefCounted
class_name ArenaSimulation
## Local laboratory authority. No scene, animation, network or wall-clock dependency.

const Grid = preload("res://simulation/hex_grid.gd")
const UnitState = preload("res://simulation/unit_state.gd")
const BallProjectile = preload("res://simulation/ball_projectile.gd")
const Catalog = preload("res://data/character_catalog.gd")
const UnitSpec = preload("res://data/unit_spec.gd")
const FIXED_STEP: float = 0.05
const MAX_BUFFERED_EVENTS: int = 2048
## IDs de invocação: invocador + 80 (fica dentro do bloco de 100 IDs do time).
const SUMMON_ID_OFFSET: int = 80

var units: Array[UnitState] = []
var projectiles: Array[BallProjectile] = []
var events: Array[Dictionary] = []
var specs: Dictionary = {}
## Nível na partida por cópias (dados de teste em debug_characters.json).
var level_rules: Dictionary = {}
var summon_specs: Dictionary = {}
## Nuvens de fumaça do Snoop: {id, source_id, team, cell, radius, remaining, until_tick, interval, damage, miss_chance}.
var zones: Array[Dictionary] = []
var _next_zone_id: int = 1
var phase: String = "preparation"
var elapsed: float = 0.0
var tick: int = 0
var round_result: Dictionary = {}
var team_lives: Array[int] = [4, 4]
var round_index: int = 1
var match_winner: int = -1
var is_boss_round: bool = false
var team_damage: Array[float] = [0.0, 0.0]
var round_duration: float = 30.0
var acceleration_at: float = 15.0
var acceleration_multiplier: float = 2.0 # LAB hypothesis; only attacks, movement, ball flight.
var accelerated: bool = false
## Functional test groups; not the final everyday identity synergies.
var synergy_enabled: bool = false
var synergy_snapshot: Array[Array] = [[], []]
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = 20261011
var _accumulator: float = 0.0
var _next_projectile_id: int = 1
var _formation: Dictionary = {}
var _roster: Array[Dictionary] = []

func _init() -> void:
	specs = Catalog.load_specs()
	level_rules = Catalog.load_level_rules()
	summon_specs = Catalog.load_summon_specs()
	reset()

func reset(seed_value: int = 20261011) -> void:
	_seed = seed_value
	team_lives = [4, 4]
	round_index = 1
	match_winner = -1
	_formation = {
		1: Vector2i(2, 6), 2: Vector2i(5, 5), 3: Vector2i(3, 4), 4: Vector2i(4, 4),
		5: Vector2i(1, 7),
		101: Vector2i(5, 1), 102: Vector2i(2, 2), 103: Vector2i(4, 3), 104: Vector2i(3, 3),
		105: Vector2i(6, 0)
	}
	_roster.clear()
	for team: int in range(2):
		for index: int in range(Catalog.KEYS.size()):
			var unit_id: int = team * 100 + index + 1
			_roster.append({"id": unit_id, "key": Catalog.KEYS[index], "team": team, "cell": _formation.get(unit_id, Grid.INVALID), "active": index < 4, "level": 1})
	_setup_round()

func _setup_round() -> void:
	units.clear()
	projectiles.clear()
	zones.clear()
	_next_zone_id = 1
	events.clear()
	team_damage = [0.0, 0.0]
	phase = "preparation"
	elapsed = 0.0
	tick = 0
	_accumulator = 0.0
	_next_projectile_id = 1
	accelerated = false
	round_result = {}
	synergy_snapshot = [[], []]
	_rng.seed = _seed + (round_index - 1) * 997
	# A Session seleciona PvE explicitamente; o núcleo também pode rodar PvP no round4.
	is_boss_round = false
	for entry: Dictionary in _roster:
		var unit_id: int = int(entry["id"])
		var key_str: String = str(entry["key"])
		var definition: UnitSpec = specs.get(key_str, null)
		if definition == null:
			definition = summon_specs.get(key_str, null)
		if definition == null:
			continue
		var unit: UnitState = UnitState.new(definition, unit_id, int(entry["team"]), _formation.get(unit_id, entry["cell"]))
		unit.active = bool(entry["active"])
		var level: int = clampi(int(entry.get("level", 1)), 1, Catalog.MAX_MATCH_LEVEL)
		unit.apply_level(level, level_multiplier(level))
		units.append(unit)

func preparation_setup(roster: Array[Dictionary]) -> bool:
	if phase != "preparation":
		return false
	var normalized: Array[Dictionary] = []
	var occupied: Dictionary = {}
	var seen_ids: Dictionary = {}
	var seen_characters: Dictionary = {}
	for entry: Dictionary in roster:
		var unit_id: int = int(entry.get("id", -1))
		var character_key: String = str(entry.get("key", ""))
		var team: int = int(entry.get("team", -1))
		var raw_cell: Variant = entry.get("cell", Grid.INVALID)
		if not raw_cell is Vector2i:
			return false
		var cell: Vector2i = raw_cell
		var enabled: bool = bool(entry.get("active", false))
		var raw_level: Variant = entry.get("level", 1)
		if not raw_level is int or int(raw_level) < 1 or int(raw_level) > Catalog.MAX_MATCH_LEVEL:
			return false
		var unique_character: String = "%d:%s" % [team, character_key]
		if unit_id < 1 or seen_ids.has(unit_id) or (not specs.has(character_key) and not summon_specs.has(character_key)) or team not in [0, 1] or seen_characters.has(unique_character):
			return false
		if enabled and (not Grid.belongs_to_team(cell, team) or occupied.has(cell)):
			return false
		seen_ids[unit_id] = true
		seen_characters[unique_character] = true
		if enabled:
			occupied[cell] = unit_id
		normalized.append({"id": unit_id, "key": character_key, "team": team, "cell": cell, "active": enabled, "level": int(raw_level)})
	if normalized.is_empty():
		return false
	normalized.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	_roster = normalized
	_formation.clear()
	for entry: Dictionary in normalized:
		_formation[int(entry["id"])] = entry["cell"]
	_setup_round()
	return true

func reset_round(roster: Array[Dictionary] = []) -> bool:
	if phase != "preparation":
		return false
	if not roster.is_empty():
		return preparation_setup(roster)
	_setup_round()
	return true

func set_active(unit_id: int, enabled: bool, destination: Vector2i = Grid.INVALID) -> bool:
	if phase != "preparation":
		return false
	var unit: UnitState = get_unit(unit_id)
	if unit == null:
		return false
	var cell: Vector2i = unit.cell if destination == Grid.INVALID else destination
	if enabled:
		if not Grid.belongs_to_team(cell, unit.team):
			return false
		for other: UnitState in units:
			if other.id != unit_id and other.active and other.alive and other.cell == cell:
				return false
		unit.cell = cell
		unit.previous_cell = cell
		_formation[unit_id] = cell
	unit.active = enabled
	for entry: Dictionary in _roster:
		if int(entry["id"]) == unit_id:
			entry["active"] = enabled
	return true

func level_multiplier(level: int) -> float:
	var table: Array = level_rules.get("power_multiplier", [1.0, 1.5, 2.25])
	return float(table[clampi(level, 1, table.size()) - 1])

## Preparação somente. Persiste no elenco para as próximas rodadas.
func set_unit_level(unit_id: int, level: int) -> bool:
	if phase != "preparation" or level < 1 or level > Catalog.MAX_MATCH_LEVEL:
		return false
	var unit: UnitState = get_unit(unit_id)
	if unit == null:
		return false
	unit.apply_level(level, level_multiplier(level))
	for entry: Dictionary in _roster:
		if int(entry["id"]) == unit_id:
			entry["level"] = level
	return true

func apply_equipment(unit_id: int, modifiers: Dictionary, items: Variant = null) -> bool:
	if phase != "preparation" and phase != "combat":
		return false
	var unit: UnitState = get_unit(unit_id)
	if unit == null or (phase == "combat" and not unit.alive):
		return false
	var multiplier_keys: Array[String] = ["hp_mult", "attack_mult", "armor_mult", "resist_mult", "attack_speed_mult"]
	var bonus_keys: Array[String] = ["hp_bonus", "attack_bonus", "armor_bonus", "resist_bonus", "crit_bonus"]
	for field: Variant in modifiers:
		if str(field) not in multiplier_keys and str(field) not in bonus_keys:
			return false
		var value: Variant = modifiers[field]
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
		if str(field) in multiplier_keys and (float(value) < 0.1 or float(value) > 10.0):
			return false
		if str(field) in bonus_keys and (float(value) < 0.0 or float(value) > (1.0 if str(field) == "crit_bonus" else 10000.0)):
			return false
	unit.equipment_modifiers = modifiers.duplicate(true)
	if items is Array:
		unit.equipment = (items as Array).duplicate(true)
	unit.recalculate_combat_stats()
	return true

func get_unit(unit_id: int) -> UnitState:
	for unit: UnitState in units:
		if unit.id == unit_id:
			return unit
	return null

func place_unit(unit_id: int, destination: Vector2i) -> bool:
	if phase != "preparation":
		return false
	var unit: UnitState = get_unit(unit_id)
	if unit == null or not unit.active or not Grid.belongs_to_team(destination, unit.team):
		return false
	for other: UnitState in units:
		if other.id != unit_id and other.active and other.alive and other.cell == destination:
			return false
	unit.cell = destination
	unit.previous_cell = destination
	_formation[unit_id] = destination
	return true

func start_combat() -> bool:
	if phase != "preparation" or match_winner >= 0:
		return false
	var occupied: Dictionary = {}
	var active_counts: Array[int] = [0, 0]
	for unit: UnitState in units:
		if not unit.active or not unit.alive:
			continue
		if not Grid.contains(unit.cell) or occupied.has(unit.cell):
			return false
		occupied[unit.cell] = unit.id
		active_counts[unit.team] += 1
	if active_counts[0] == 0 or active_counts[1] == 0:
		return false
	_snapshot_auras()
	phase = "combat"
	_emit("combat_started", {"round": round_index, "seed": _seed})
	for unit: UnitState in units:
		if unit.active and unit.alive and unit.spec.lasso_cooldown > 0.0:
			unit.ability_cooldown = unit.spec.lasso_first_delay
	_spawn_summons()
	_start_assassin_hunts()
	return true

## Barbie: Ken aparece num hexágono livre vizinho (de preferência à frente) e herda o nível dela.
func _spawn_summons() -> void:
	for summoner: UnitState in units.duplicate():
		if not summoner.active or not summoner.alive or summoner.summoned or summoner.spec.summon_key.is_empty():
			continue
		var definition: UnitSpec = summon_specs.get(summoner.spec.summon_key, null)
		if definition == null:
			continue
		var cell: Vector2i = _free_cell_near(summoner.cell, summoner.team)
		if cell == Grid.INVALID:
			continue
		## Rosters may use custom IDs; skip all occupied IDs before linking the guardian.
		var summon_id: int = maxi(1, summoner.id + SUMMON_ID_OFFSET)
		while get_unit(summon_id) != null:
			summon_id += 1
		var summon: UnitState = UnitState.new(definition, summon_id, summoner.team, cell)
		summon.summoned = true
		summon.summoner_id = summoner.id
		summon.apply_level(summoner.level, summoner.level_multiplier)
		units.append(summon)
		summoner.guardian_id = summon.id
		_emit("summon", {"source_id": summoner.id, "target_id": summon.id, "cell": cell, "key": definition.key})

## Hexágono livre mais próximo; empate prefere avançar em direção ao inimigo.
func _free_cell_near(origin: Vector2i, team: int) -> Vector2i:
	var occupied: Dictionary = _occupied_cells()
	var best: Vector2i = Grid.INVALID
	var best_score: int = 100000
	for row: int in range(Grid.HEIGHT):
		for column: int in range(Grid.WIDTH):
			var cell: Vector2i = Vector2i(column, row)
			if occupied.has(cell) or cell == origin:
				continue
			var forward: int = (origin.y - row) if team == 0 else (row - origin.y)
			var score: int = Grid.distance(origin, cell) * 100 - forward * 10 + column
			if score < best_score:
				best_score = score
				best = cell
	return best

func _snapshot_auras() -> void:
	var attack_bonuses: Array[float] = [0.0, 0.0]
	var crit_bonuses: Array[float] = [0.0, 0.0]
	for unit: UnitState in units:
		if unit.active and unit.alive:
			attack_bonuses[unit.team] += unit.spec.team_attack_speed_bonus
			crit_bonuses[unit.team] += unit.spec.team_crit_bonus
	for unit: UnitState in units:
		unit.round_attack_speed_bonus = attack_bonuses[unit.team] if unit.active else 0.0
		unit.round_crit_bonus = crit_bonuses[unit.team] if unit.active else 0.0
		unit.synergy_hp_multiplier = 1.0
		unit.synergy_attack_multiplier = 1.0
		unit.synergy_armor_bonus = 0.0
		unit.synergy_resist_bonus = 0.0
	_snapshot_test_synergies()
	for unit: UnitState in units:
		unit.recalculate_combat_stats()

func _snapshot_test_synergies() -> void:
	synergy_snapshot = [[], []]
	if not synergy_enabled:
		return
	for team: int in range(2):
		synergy_snapshot[team] = preview_synergies(team)
		var attack_tier: int = int(synergy_snapshot[team][0]["tier"])
		var shooter_tier: int = int(synergy_snapshot[team][1]["tier"])
		var support_tier: int = int(synergy_snapshot[team][2]["tier"])
		var vanguard_tier: int = int(synergy_snapshot[team][3]["tier"])
		for unit: UnitState in units:
			if unit.team != team or not unit.active:
				continue
			if support_tier > 0:
				unit.synergy_hp_multiplier = 1.25 if support_tier == 4 else 1.1
			if attack_tier > 0 and "atacantes" in unit.spec.synergy_tags:
				unit.synergy_attack_multiplier = 1.2 if attack_tier == 3 else 1.1
			if shooter_tier > 0 and "atiradores" in unit.spec.synergy_tags:
				unit.round_attack_speed_bonus += 0.35 if shooter_tier == 4 else 0.15
			if vanguard_tier > 0 and "vanguarda" in unit.spec.synergy_tags:
				unit.synergy_armor_bonus = 50.0 if vanguard_tier == 3 else 25.0
				unit.synergy_resist_bonus = 40.0 if vanguard_tier == 3 else 20.0

func preview_synergies(team: int) -> Array[Dictionary]:
	if team not in [0, 1]:
		return []
	var counts: Dictionary = {"atacantes": 0, "atiradores": 0, "apoio": 0, "vanguarda": 0}
	for unit: UnitState in units:
		if unit.team == team and unit.active and unit.alive and not unit.summoned:
			for tag: String in unit.spec.synergy_tags:
				counts[tag] = int(counts.get(tag, 0)) + 1
	var attack_tier: int = 3 if int(counts["atacantes"]) >= 3 else (2 if int(counts["atacantes"]) >= 2 else 0)
	var shooter_tier: int = 4 if int(counts["atiradores"]) >= 4 else (2 if int(counts["atiradores"]) >= 2 else 0)
	var support_tier: int = 4 if int(counts["apoio"]) >= 4 else (2 if int(counts["apoio"]) >= 2 else 0)
	var vanguard_tier: int = 3 if int(counts["vanguarda"]) >= 3 else (2 if int(counts["vanguarda"]) >= 2 else 0)
	return [
		{"key": "atacantes", "name": "Atacantes · TESTE", "count": counts["atacantes"], "tier": attack_tier, "breakpoints": [2, 3], "description": "+10%/20% ataque dos membros em 2/3"},
		{"key": "atiradores", "name": "Atiradores · TESTE", "count": counts["atiradores"], "tier": shooter_tier, "breakpoints": [2, 4], "description": "+15%/35% velocidade de ataque dos membros em 2/4"},
		{"key": "apoio", "name": "Apoio · TESTE", "count": counts["apoio"], "tier": support_tier, "breakpoints": [2, 4], "description": "+10%/25% vida da equipe em 2/4"},
		{"key": "vanguarda", "name": "Vanguarda · TESTE", "count": counts["vanguarda"], "tier": vanguard_tier, "breakpoints": [2, 3], "description": "+25/+50 armadura e +20/+40 resistência dos membros em 2/3"}
	]

func next_round() -> bool:
	if phase != "finished" or match_winner >= 0:
		return false
	round_index += 1
	_setup_round()
	return true

func step(delta: float) -> void:
	if phase != "combat" or not is_finite(delta) or delta <= 0.0:
		return
	_accumulator += delta
	while _accumulator + 0.0000001 >= FIXED_STEP and phase == "combat":
		_accumulator -= FIXED_STEP
		_tick()

func _tick() -> void:
	tick += 1
	elapsed = tick * FIXED_STEP
	if not accelerated and elapsed >= acceleration_at:
		accelerated = true
		_emit("acceleration", {"multiplier": acceleration_multiplier})
	var action_delta: float = FIXED_STEP * (acceleration_multiplier if accelerated else 1.0)
	_update_bleeds(FIXED_STEP)
	_update_dance_shields(FIXED_STEP)
	_update_zones(FIXED_STEP)
	_update_stuns(FIXED_STEP)
	_update_projectiles(action_delta)
	_update_support_skills(FIXED_STEP)
	_update_lassos(FIXED_STEP)
	_update_assassin_hunts(FIXED_STEP)
	_update_briefcase_guards(FIXED_STEP)
	_update_boss_spells(action_delta)
	## Stable IDs determine ties in this prototype; not a claim of PvP fairness.
	for unit: UnitState in units:
		if not unit.active or not unit.alive or unit.stun_remaining > 0.0:
			continue
		## O Boss Desenvolvedor não dá socos nem persegue; conjura poderes à distância.
		if unit.is_boss:
			continue
		## Waiting out of reach never banks attacks to be repaid as a burst.
		unit.attack_cooldown = maxf(0.0, unit.attack_cooldown - action_delta)
		unit.move_cooldown = maxf(0.0, unit.move_cooldown - action_delta)
		var target: UnitState = _find_target(unit)
		if target == null:
			unit.target_id = -1
			continue
		unit.target_id = target.id
		var in_range: bool = Grid.distance(unit.cell, target.cell) <= unit.spec.attack_range
		if _is_moonwalker(unit):
			## The moonwalk replaces chasing; a zero-damage dancer never emits empty hits.
			if in_range and unit.attack_damage > 0.0 and unit.attack_cooldown <= 0.000001:
				_attack(unit, target)
				unit.attack_cooldown = 1.0 / _attack_speed(unit)
			continue
		if in_range:
			if unit.attack_cooldown <= 0.000001:
				_attack(unit, target)
				unit.attack_cooldown = 1.0 / _attack_speed(unit)
		else:
			_move_toward(unit, target)
	_update_moonwalks(action_delta)
	_check_resolution()

func _find_target(source: UnitState) -> UnitState:
	if not source.assassin_opening_finished:
		var hunted: UnitState = get_unit(source.assassin_target_id)
		if hunted != null and hunted.active and hunted.alive and hunted.team != source.team:
			return hunted

	# Taunt / Trava de mira: se já ataca um tank ou alvo em alcance, mantém a mira fixa
	if source.target_id >= 0:
		var current: UnitState = get_unit(source.target_id)
		if current != null and current.active and current.alive and current.team != source.team:
			if current.guardian_id >= 0:
				var guardian: UnitState = get_unit(current.guardian_id)
				if guardian != null and guardian.active and guardian.alive:
					return guardian
			var is_tank: bool = current.summoned or "vanguarda" in current.spec.synergy_tags or current.guardian_id >= 0 or current.key in ["obama", "barbie", "lula", "ken"]
			var dist: int = Grid.distance(source.cell, current.cell)
			if is_tank or dist <= source.spec.attack_range:
				return current

	var best: UnitState = null
	var best_distance: int = 1000
	var best_is_tank: bool = false
	for candidate: UnitState in units:
		if not candidate.active or not candidate.alive or candidate.team == source.team:
			continue
		var candidate_distance: int = Grid.distance(source.cell, candidate.cell)
		var candidate_is_tank: bool = candidate.summoned or "vanguarda" in candidate.spec.synergy_tags or candidate.guardian_id >= 0 or candidate.key in ["obama", "barbie", "lula", "ken"]
		var is_closer: bool = candidate_distance < best_distance
		var same_dist: bool = candidate_distance == best_distance
		var takes_taunt_priority: bool = same_dist and candidate_is_tank and not best_is_tank
		var takes_id_tiebreak: bool = same_dist and candidate_is_tank == best_is_tank and (best == null or candidate.id < best.id)
		if is_closer or takes_taunt_priority or takes_id_tiebreak:
			best = candidate
			best_distance = candidate_distance
			best_is_tank = candidate_is_tank

	## Ken "puxa o aggro": quem miraria a Barbie passa a mirar o Ken enquanto ele estiver vivo.
	if best != null and best.guardian_id >= 0:
		var guardian: UnitState = get_unit(best.guardian_id)
		if guardian != null and guardian.active and guardian.alive:
			return guardian

	## Mobs sumonados do Boss puxam o aggro de quem atacaria o Boss enquanto estiverem vivos.
	if best != null and best.is_boss:
		var summon_taunter: UnitState = null
		var min_summon_dist: int = 1000
		for cand: UnitState in units:
			if cand.team == best.team and cand.active and cand.alive and cand.summoned:
				var s_dist: int = Grid.distance(source.cell, cand.cell)
				if s_dist < min_summon_dist or (s_dist == min_summon_dist and (summon_taunter == null or cand.id < summon_taunter.id)):
					min_summon_dist = s_dist
					summon_taunter = cand
		if summon_taunter != null:
			return summon_taunter

	return best

## TESTE: uma caça inicial ao maior dano à distância, sem salto e sem trocar de presa.
func _start_assassin_hunts() -> void:
	for source: UnitState in units:
		if not source.active or not source.alive or source.key != "caramelo" or source.assassin_opening_finished:
			continue
		var best: UnitState = null
		for candidate: UnitState in units:
			if not candidate.active or not candidate.alive or candidate.team == source.team or candidate.spec.attack_range < 2 or candidate.attack_damage <= 0.0:
				continue
			var closer: bool = best != null and Grid.distance(source.cell, candidate.cell) < Grid.distance(source.cell, best.cell)
			var same_distance: bool = best != null and Grid.distance(source.cell, candidate.cell) == Grid.distance(source.cell, best.cell)
			if best == null or candidate.attack_damage > best.attack_damage or (is_equal_approx(candidate.attack_damage, best.attack_damage) and (closer or (same_distance and candidate.id < best.id))):
				best = candidate
		if best == null:
			_end_assassin_hunt(source, "no_carry")
			continue
		source.assassin_target_id = best.id
		_emit("assassin_hunt", {"source_id": source.id, "target_id": best.id, "duration": source.assassin_opening_remaining})

func _end_assassin_hunt(source: UnitState, reason: String) -> void:
	if source.assassin_opening_finished:
		return
	source.assassin_opening_finished = true
	source.assassin_opening_remaining = 0.0
	_emit("assassin_hunt_ended", {"source_id": source.id, "target_id": source.assassin_target_id, "reason": reason})
	source.assassin_target_id = -1

func _update_assassin_hunts(delta: float) -> void:
	for source: UnitState in units:
		if not source.active or not source.alive or source.assassin_opening_finished:
			continue
		var target: UnitState = get_unit(source.assassin_target_id)
		if target == null or not target.active or not target.alive:
			_end_assassin_hunt(source, "target_dead")
			continue
		source.assassin_opening_remaining = maxf(0.0, source.assassin_opening_remaining - delta)
		if source.assassin_opening_remaining <= 0.000001:
			_end_assassin_hunt(source, "timeout")

## TESTE: renova somente o escudo próprio até um piso, sem somar e sem curar HP.
func _update_briefcase_guards(delta: float) -> void:
	for source: UnitState in units:
		if not source.active or not source.alive or source.key != "obama" or source.spec.briefcase_guard_amount <= 0.0 or source.stun_remaining > 0.0:
			continue
		source.briefcase_cooldown = maxf(0.0, source.briefcase_cooldown - delta)
		if source.briefcase_cooldown > 0.000001:
			continue
		source.briefcase_cooldown = source.spec.briefcase_guard_interval
		var before: float = source.shield
		source.shield = maxf(source.shield, source.spec.briefcase_guard_amount * source.level_multiplier)
		source.last_action = "briefcase_guard"
		_emit("briefcase_guard", {"source_id": source.id, "amount": source.shield, "added": source.shield - before, "interval": source.spec.briefcase_guard_interval})

func _occupied_cells() -> Dictionary:
	var result: Dictionary = {}
	for unit: UnitState in units:
		if unit.active and unit.alive:
			result[unit.cell] = unit.id
	return result

func _move_toward(unit: UnitState, target: UnitState) -> void:
	if unit.move_cooldown > 0.000001:
		return
	var destination: Vector2i = Grid.next_step(unit.cell, target.cell, unit.spec.attack_range, _occupied_cells())
	if destination == unit.cell:
		return
	unit.previous_cell = unit.cell
	unit.cell = destination
	unit.move_cooldown = unit.spec.move_interval
	unit.last_action = "move"
	_emit("move", {"source_id": unit.id, "from": unit.previous_cell, "to": destination})

func _attack(source: UnitState, target: UnitState) -> void:
	source.attack_count += 1
	source.last_action = "attack"
	_emit("attack", {"source_id": source.id, "target_id": target.id})
	if source.spec.max_mana > 0.0 and source.spec.mana_per_attack > 0.0:
		source.mana = minf(source.spec.max_mana, source.mana + source.spec.mana_per_attack)
		_emit("mana_gained", {"source_id": source.id, "amount": source.mana, "max_mana": source.spec.max_mana})
	var miss_chance: float = _smoke_miss_chance(source)
	if miss_chance > 0.0 and _rng.randf() < miss_chance:
		_emit("miss", {"source_id": source.id, "target_id": target.id})
		return
	if source.key == "caramelo" and not source.assassin_opening_finished and source.assassin_target_id == target.id:
		_end_assassin_hunt(source, "first_bite")
	if source.key == "caramelo" and target.hp <= target.max_hp * source.spec.execute_threshold + 0.000001:
		_deal_damage(source.id, target, target.hp, false, "execute", true)
		return
	var critical: bool = _rng.randf() < source.effective_crit_chance
	var damage: float = source.attack_damage
	if _guardian_alive(source):
		damage *= 1.0 + source.spec.guardian_damage_bonus
	if critical:
		damage *= source.spec.crit_multiplier + source.crit_growth
		if source.key == "zumbi":
			source.crit_growth_hits += 1
			source.crit_growth = minf(source.spec.crit_growth_cap, source.crit_growth + source.spec.crit_growth_per_hit)
			_emit("crit_growth", {"source_id": source.id, "amount": source.crit_growth, "stacks": source.crit_growth_hits, "cap": source.spec.crit_growth_cap, "multiplier": source.spec.crit_multiplier + source.crit_growth})
	var kind: String = source.spec.projectile_kind
	if kind.is_empty() and source.key == "neymar":
		kind = "ball"
	var is_super: bool = false
	if source.spec.super_attack_interval > 0:
		if source.attack_count % source.spec.super_attack_interval == 0:
			is_super = true
			damage *= source.spec.super_damage_multiplier
		else:
			if kind == "rocket":
				kind = "mini_rocket"
	if kind == "ball":
		_launch_ball(source, target, damage, critical)
	elif kind in ["rocket", "mini_rocket", "smoke"]:
		_launch_projectile(source, target, damage, critical, kind, is_super)
	else:
		_deal_damage(source.id, target, damage, critical, "hit", false, source.damage_type)
		if source.key == "caramelo" and target.alive:
			_apply_bleed(source, target)

func _launch_ball(source: UnitState, target: UnitState, damage: float, critical: bool) -> void:
	var ball: BallProjectile = BallProjectile.new()
	ball.id = _next_projectile_id
	_next_projectile_id += 1
	ball.source_id = source.id
	ball.primary_id = target.id
	ball.target_id = target.id
	ball.total_impacts = source.spec.projectile_max_impacts
	ball.raw_damage = damage
	ball.critical = critical
	ball.damage_type = source.damage_type
	ball.decay_multipliers = source.spec.projectile_decay_multipliers.duplicate()
	for other: UnitState in units:
		if other.active and other.alive and other.team != source.team and other.id != target.id and Grid.distance(other.cell, target.cell) == 1:
			if ball.secondary_id < 0 or other.id < ball.secondary_id:
				ball.secondary_id = other.id
	_set_ball_leg(ball, source.cell, target, source.spec)
	projectiles.append(ball)
	_emit("ball_launched", {"projectile_id": ball.id, "source_id": source.id, "target_id": target.id, "secondary_id": ball.secondary_id})
	_emit("kick", {"projectile_id": ball.id, "source_id": source.id, "target_id": target.id, "flight_duration": ball.flight_duration, "critical": critical})

## Foguete (Elon) e fumaça (Snoop): um trecho só, sem ricochete.
func _launch_projectile(source: UnitState, target: UnitState, damage: float, critical: bool, kind: String, is_super: bool = false) -> void:
	var projectile: BallProjectile = BallProjectile.new()
	projectile.id = _next_projectile_id
	_next_projectile_id += 1
	projectile.kind = kind
	projectile.source_id = source.id
	projectile.primary_id = target.id
	projectile.target_id = target.id
	projectile.total_impacts = 1
	projectile.raw_damage = damage
	projectile.critical = critical
	projectile.damage_type = source.damage_type
	projectile.is_super = is_super
	_set_ball_leg(projectile, source.cell, target, source.spec)
	projectiles.append(projectile)
	_emit("projectile_launched", {"projectile_id": projectile.id, "source_id": source.id, "target_id": target.id, "kind": kind, "is_super": is_super})
	if is_super:
		_emit("super_attack", {"source_id": source.id, "target_id": target.id, "kind": kind})

func _resolve_projectile(projectile: BallProjectile, target: UnitState) -> void:
	var source: UnitState = get_unit(projectile.source_id)
	if projectile.kind == "mini_rocket":
		_deal_damage(projectile.source_id, target, projectile.raw_damage, projectile.critical, "mini_rocket_hit", false, projectile.damage_type)
		_emit("mini_rocket_impact", {"source_id": projectile.source_id, "target_id": target.id, "cell": target.cell})
	elif projectile.kind == "rocket":
		var center: Vector2i = target.cell
		_deal_damage(projectile.source_id, target, projectile.raw_damage, projectile.critical, "rocket_hit", false, projectile.damage_type)
		var radius: int = source.spec.splash_radius if source != null else 0
		var ratio: float = source.spec.splash_ratio if source != null else 0.0
		var depth: int = source.spec.super_splash_depth if (source != null and projectile.is_super) else 0
		var affected_cells: Array[Vector2i] = [center]
		if radius > 0:
			for candidate: Vector2i in Grid.neighbors(center):
				if not affected_cells.has(candidate):
					affected_cells.append(candidate)
		if depth > 0 and source != null:
			# Retaguarda do alvo na direção do avanço do time atacante:
			for x: int in range(Grid.WIDTH):
				for y: int in range(Grid.HEIGHT):
					var c: Vector2i = Vector2i(x, y)
					var dist: int = Grid.distance(c, center)
					if dist > 0 and dist <= radius + depth:
						var is_behind: bool = (c.y < center.y) if source.team == 0 else (c.y > center.y)
						if is_behind and not affected_cells.has(c):
							affected_cells.append(c)
		_emit("explosion", {"source_id": projectile.source_id, "cell": center, "radius": radius, "depth": depth, "is_super": projectile.is_super, "cells": affected_cells})
		if ratio > 0.0 and source != null:
			for other: UnitState in units.duplicate():
				if other.id != target.id and other.active and other.alive and other.team != source.team and affected_cells.has(other.cell):
					_deal_damage(projectile.source_id, other, projectile.raw_damage * ratio, false, "splash", false, projectile.damage_type)
	elif projectile.kind == "smoke":
		var cloud_cell: Vector2i = target.cell
		_deal_damage(projectile.source_id, target, projectile.raw_damage, projectile.critical, "smoke_hit", false, projectile.damage_type)
		if source != null and source.spec.smoke_duration > 0.0:
			_spawn_smoke(source, cloud_cell)

## Uma nuvem por Snoop: a nova substitui a anterior (sem acumular dano de várias nuvens).
func _spawn_smoke(source: UnitState, cell: Vector2i) -> void:
	var kept: Array[Dictionary] = []
	for zone: Dictionary in zones:
		if int(zone["source_id"]) != source.id:
			kept.append(zone)
	zones = kept
	var zone: Dictionary = {"id": _next_zone_id, "source_id": source.id, "team": source.team, "cell": cell,
		"radius": source.spec.smoke_radius, "remaining": source.spec.smoke_duration, "duration": source.spec.smoke_duration,
		"until_tick": source.spec.smoke_tick_interval, "interval": source.spec.smoke_tick_interval,
		"damage": source.spec.smoke_damage_per_tick * source.level_multiplier, "miss_chance": source.spec.smoke_miss_chance,
		"ally_speed_bonus": source.spec.smoke_ally_speed_bonus}
	_next_zone_id += 1
	zones.append(zone)
	_emit("smoke_cloud", {"source_id": source.id, "zone_id": zone["id"], "cell": cell, "radius": zone["radius"]})

## Dano contínuo mágico a inimigos dentro da nuvem; usa o relógio normal (não acelera).
func _update_zones(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for zone: Dictionary in zones:
		zone["remaining"] = float(zone["remaining"]) - delta
		zone["until_tick"] = float(zone["until_tick"]) - delta
		if float(zone["until_tick"]) <= 0.000001 and float(zone["remaining"]) >= -0.000001:
			for unit: UnitState in units.duplicate():
				if unit.active and unit.alive and unit.team != int(zone["team"]) and Grid.distance(unit.cell, zone["cell"]) <= int(zone["radius"]):
					_deal_damage(int(zone["source_id"]), unit, float(zone["damage"]), false, "smoke", false, "magic")
			zone["until_tick"] = float(zone["until_tick"]) + float(zone["interval"])
		if float(zone["remaining"]) > 0.000001:
			remaining.append(zone)
	zones = remaining

func _smoke_miss_chance(unit: UnitState) -> float:
	var chance: float = 0.0
	for zone: Dictionary in zones:
		if int(zone["team"]) != unit.team and Grid.distance(unit.cell, zone["cell"]) <= int(zone["radius"]):
			chance = maxf(chance, float(zone["miss_chance"]))
	return chance

func _guardian_alive(unit: UnitState) -> bool:
	if unit.guardian_id < 0:
		return false
	var guardian: UnitState = get_unit(unit.guardian_id)
	return guardian != null and guardian.active and guardian.alive

## Bob Marley "paz e amor": aliados no raio atacam mais rápido; inimigos no raio, mais devagar.
## O raio cresce com o nível na partida. Só a velocidade muda; o dano não é reduzido.
## Snoop Dogg "fumaça": aliados dentro da fumaça amiga recebem bônus de velocidade.
func _attack_speed(unit: UnitState) -> float:
	var multiplier: float = unit.attack_speed_multiplier
	for singer: UnitState in units:
		if not singer.active or not singer.alive or singer.spec.aura_radius_by_level.is_empty():
			continue
		var radius: int = singer.spec.aura_radius_by_level[clampi(singer.level, 1, singer.spec.aura_radius_by_level.size()) - 1]
		if Grid.distance(singer.cell, unit.cell) > radius:
			continue
		if singer.team == unit.team:
			multiplier *= 1.0 + singer.spec.aura_ally_speed_bonus
		else:
			multiplier *= 1.0 - singer.spec.aura_enemy_slow
	for zone: Dictionary in zones:
		if int(zone.get("team", -1)) == unit.team and Grid.distance(unit.cell, zone.get("cell", Grid.INVALID)) <= int(zone.get("radius", 0)):
			var ally_buff: float = float(zone.get("ally_speed_bonus", 0.0))
			if ally_buff > 0.0:
				multiplier *= 1.0 + ally_buff
				break
	return clampf(unit.spec.attacks_per_second * multiplier, 0.05, 10.0)

func _update_stuns(delta: float) -> void:
	for unit: UnitState in units:
		if unit.stun_remaining > 0.0:
			unit.stun_remaining = maxf(0.0, unit.stun_remaining - delta)

## Rapunzel: laça o inimigo mais distante, puxa para o hexágono livre mais perto dela e atordoa.
func _update_lassos(delta: float) -> void:
	for source: UnitState in units:
		if not source.active or not source.alive or source.spec.lasso_cooldown <= 0.0 or source.stun_remaining > 0.0:
			continue
		if source.spec.max_mana > 0.0:
			if source.mana + 0.000001 < source.spec.max_mana:
				continue
		else:
			source.ability_cooldown = maxf(0.0, source.ability_cooldown - delta)
			if source.ability_cooldown > 0.000001:
				continue
		var target: UnitState = null
		var best_distance: int = -1
		for candidate: UnitState in units:
			if not candidate.active or not candidate.alive or candidate.team == source.team or candidate.summoned:
				continue
			var distance: int = Grid.distance(source.cell, candidate.cell)
			if distance > best_distance or (distance == best_distance and candidate.id < target.id):
				target = candidate
				best_distance = distance
		if target == null:
			continue
		if source.spec.max_mana > 0.0:
			source.mana = 0.0
		source.ability_cooldown = source.spec.lasso_cooldown
		var from: Vector2i = target.cell
		if best_distance > 1:
			var destination: Vector2i = _free_cell_near(source.cell, source.team)
			if destination != Grid.INVALID and Grid.distance(destination, source.cell) < best_distance:
				target.previous_cell = target.cell
				target.cell = destination
				target.moonwalk_from_cell = destination
				target.moonwalk_to_cell = destination
		target.stun_remaining = maxf(target.stun_remaining, source.spec.lasso_stun)
		source.last_action = "lasso"
		_emit("lasso", {"source_id": source.id, "target_id": target.id, "from": from, "to": target.cell, "stun": source.spec.lasso_stun})
		_deal_damage(source.id, target, source.spec.lasso_damage * source.level_multiplier, false, "lasso_hit", false, "physical")

## Boss Desenvolvedor (Round 4): Fogo vermelho ardente, fogo roxo explosivo, furacão de chamas com empurrão e invocações escalonadas
func _update_boss_spells(delta: float) -> void:
	for unit: UnitState in units:
		if not unit.active or not unit.alive or not unit.is_boss or unit.stun_remaining > 0.0:
			continue
		
		# 1. Invocação de monstros em tempos específicos
		for s_idx: int in range(unit.spec.boss_summon_times.size()):
			var spawn_time: float = unit.spec.boss_summon_times[s_idx]
			if elapsed >= spawn_time and not unit.boss_summons_spawned.has(s_idx):
				unit.boss_summons_spawned.append(s_idx)
				var summon_key: String = unit.spec.boss_summon_keys[s_idx]
				var def: UnitSpec = summon_specs.get(summon_key, null)
				if def != null:
					var cell: Vector2i = _free_cell_near(unit.cell, unit.team)
					if cell != Grid.INVALID:
						var summon_id: int = maxi(1, unit.id + SUMMON_ID_OFFSET + (s_idx + 1) * 10)
						while get_unit(summon_id) != null:
							summon_id += 1
						var summon: UnitState = UnitState.new(def, summon_id, unit.team, cell)
						summon.summoned = true
						summon.summoner_id = unit.id
						units.append(summon)
						unit.last_action = "cast"
						_emit("summon", {"source_id": unit.id, "target_id": summon.id, "cell": cell, "key": summon_key})
						_emit("boss_summon", {"boss_id": unit.id, "target_id": summon.id, "cell": cell, "key": summon_key})
						for enemy: UnitState in units:
							if enemy.team != summon.team and enemy.active and enemy.alive:
								enemy.target_id = summon.id
		
		# 2. Fogo Vermelho (Disparo incandescente de dano concentrado e labaredas em área)
		unit.boss_red_fire_timer = maxf(0.0, unit.boss_red_fire_timer - delta)
		if unit.boss_red_fire_timer <= 0.000001:
			unit.boss_red_fire_timer = unit.spec.boss_red_fire_cooldown
			var target: UnitState = _find_threat_target(1 - unit.team)
			if target != null:
				var target_cell: Vector2i = target.cell
				var impact_damage: float = unit.spec.boss_red_fire_damage
				unit.last_action = "cast"
				_emit("boss_cast", {"source_id": unit.id, "spell": "red_fire", "from": unit.cell, "to": target_cell})
				for victim: UnitState in units:
					if victim.active and victim.alive and victim.team != unit.team:
						if Grid.distance(target_cell, victim.cell) <= 1:
							_deal_damage(unit.id, victim, impact_damage, false, "red_fire_hit", false, "magic")
				_emit("red_fire_explosion", {"source_id": unit.id, "center": target_cell, "radius": 1, "damage": impact_damage})

		# 3. Fogo Roxo (Projétil em área com explosão mágica)
		unit.boss_purple_fire_timer = maxf(0.0, unit.boss_purple_fire_timer - delta)
		if unit.boss_purple_fire_timer <= 0.000001:
			unit.boss_purple_fire_timer = unit.spec.boss_purple_fire_cooldown
			var target: UnitState = _find_cluster_target(1 - unit.team)
			if target != null:
				var target_cell: Vector2i = target.cell
				var impact_damage: float = unit.spec.boss_purple_fire_damage
				unit.last_action = "cast"
				_emit("boss_cast", {"source_id": unit.id, "spell": "purple_fire", "from": unit.cell, "to": target_cell})
				for victim: UnitState in units:
					if victim.active and victim.alive and victim.team != unit.team:
						if Grid.distance(target_cell, victim.cell) <= 1:
							_deal_damage(unit.id, victim, impact_damage, false, "purple_fire_hit", false, "magic")
				_emit("purple_fire_explosion", {"source_id": unit.id, "center": target_cell, "radius": 1, "damage": impact_damage})
		
		# 4. Furacão de Fogo (Dano em área + Deslocamento / Embaralhamento da formação)
		unit.boss_tornado_timer = maxf(0.0, unit.boss_tornado_timer - delta)
		if unit.boss_tornado_timer <= 0.000001:
			unit.boss_tornado_timer = unit.spec.boss_tornado_cooldown
			var target: UnitState = _find_cluster_target(1 - unit.team)
			if target != null:
				var center_cell: Vector2i = target.cell
				var tornado_damage: float = unit.spec.boss_tornado_damage
				unit.last_action = "cast"
				_emit("boss_cast", {"source_id": unit.id, "spell": "fire_tornado", "center": center_cell, "radius": 1})
				var victims_to_displace: Array[UnitState] = []
				for victim: UnitState in units:
					if victim.active and victim.alive and victim.team != unit.team:
						if Grid.distance(center_cell, victim.cell) <= 1:
							_deal_damage(unit.id, victim, tornado_damage, false, "fire_tornado_hit", false, "magic")
							victims_to_displace.append(victim)
				for victim: UnitState in victims_to_displace:
					if victim.alive:
						var free_cell: Vector2i = _find_free_adjacent_cell(victim.cell)
						if free_cell != Grid.INVALID:
							var old_pos: Vector2i = victim.cell
							victim.previous_cell = old_pos
							victim.cell = free_cell
							_emit("unit_displaced", {"unit_id": victim.id, "from": old_pos, "to": free_cell, "reason": "fire_tornado"})
				_emit("fire_tornado", {"source_id": unit.id, "center": center_cell, "radius": 1, "damage": tornado_damage})

func _find_threat_target(enemy_team: int) -> UnitState:
	var best_unit: UnitState = null
	var highest_threat: float = -1.0
	for candidate: UnitState in units:
		if not candidate.active or not candidate.alive or candidate.team != enemy_team:
			continue
		var threat: float = candidate.attack_damage * candidate.attack_speed_multiplier
		if threat > highest_threat or (threat == highest_threat and (best_unit == null or candidate.id < best_unit.id)):
			highest_threat = threat
			best_unit = candidate
	if best_unit == null:
		return _find_cluster_target(enemy_team)
	return best_unit

func _find_cluster_target(enemy_team: int) -> UnitState:
	var best_unit: UnitState = null
	var best_neighbors: int = -1
	for candidate: UnitState in units:
		if not candidate.active or not candidate.alive or candidate.team != enemy_team:
			continue
		var neighbors: int = 0
		for other: UnitState in units:
			if other.active and other.alive and other.team == enemy_team:
				if Grid.distance(candidate.cell, other.cell) <= 1:
					neighbors += 1
		if neighbors > best_neighbors or (neighbors == best_neighbors and (best_unit == null or candidate.id < best_unit.id)):
			best_neighbors = neighbors
			best_unit = candidate
	return best_unit

func _find_free_adjacent_cell(origin: Vector2i) -> Vector2i:
	var occupied: Dictionary = _occupied_cells()
	var candidates: Array[Vector2i] = Grid.neighbors(origin)
	for cell: Vector2i in candidates:
		if not occupied.has(cell) and Grid.contains(cell):
			return cell
	return Grid.INVALID

func _set_ball_leg(ball: BallProjectile, origin: Vector2i, target: UnitState, definition: UnitSpec) -> void:
	ball.from_cell = origin
	ball.to_cell = target.cell
	ball.flight_duration = maxf(definition.projectile_min_seconds, Grid.distance(origin, target.cell) * definition.projectile_seconds_per_hex)
	ball.flight_left = ball.flight_duration

func _update_projectiles(delta: float) -> void:
	var remaining: Array[BallProjectile] = []
	for ball: BallProjectile in projectiles:
		var target: UnitState = get_unit(ball.target_id)
		if target == null or not target.active or not target.alive:
			_expire_ball(ball, "target_dead")
			continue
		ball.to_cell = target.cell
		ball.flight_left -= delta
		if ball.flight_left > 0.000001:
			remaining.append(ball)
			continue
		if ball.kind != "ball":
			ball.impacts = 1
			_resolve_projectile(ball, target)
			continue
		## A moving pair is checked before every bounce impact as well as departure.
		if ball.impacts > 0 and not _pair_is_adjacent(ball):
			_expire_ball(ball, _pair_end_reason(ball))
			continue
		ball.impacts += 1
		var impact_damage: float = ball.raw_damage
		if not ball.decay_multipliers.is_empty():
			var decay_index: int = clampi(ball.impacts - 1, 0, ball.decay_multipliers.size() - 1)
			impact_damage *= ball.decay_multipliers[decay_index]
		_deal_damage(ball.source_id, target, impact_damage, ball.critical, "ball_hit", false, ball.damage_type)
		_emit("ball_impact", {"projectile_id": ball.id, "source_id": ball.source_id, "target_id": target.id, "impact": ball.impacts, "damage": impact_damage})
		if ball.impacts >= ball.total_impacts:
			_expire_ball(ball, "max_impacts")
			continue
		var end_reason: String = _pair_end_reason(ball)
		if not end_reason.is_empty():
			_expire_ball(ball, end_reason)
			continue
		var next_id: int = ball.secondary_id if ball.target_id == ball.primary_id else ball.primary_id
		var next_target: UnitState = get_unit(next_id)
		var source: UnitState = get_unit(ball.source_id)
		if next_target == null or source == null:
			_expire_ball(ball, "target_missing" if next_target == null else "source_missing")
			continue
		ball.target_id = next_id
		_set_ball_leg(ball, target.cell, next_target, source.spec)
		remaining.append(ball)
	projectiles = remaining

func _expire_ball(ball: BallProjectile, reason: String) -> void:
	_emit("ball_expired", {"projectile_id": ball.id, "source_id": ball.source_id, "reason": reason, "impacts": ball.impacts, "kind": ball.kind})

func _pair_end_reason(ball: BallProjectile) -> String:
	if ball.secondary_id < 0:
		return "no_pair"
	var primary: UnitState = get_unit(ball.primary_id)
	var secondary: UnitState = get_unit(ball.secondary_id)
	if primary == null or secondary == null or not primary.active or not secondary.active or not primary.alive or not secondary.alive:
		return "pair_dead"
	return "" if Grid.distance(primary.cell, secondary.cell) == 1 else "pair_separated"

func _pair_is_adjacent(ball: BallProjectile) -> bool:
	var primary: UnitState = get_unit(ball.primary_id)
	var secondary: UnitState = get_unit(ball.secondary_id)
	return primary != null and secondary != null and primary.active and secondary.active and primary.alive and secondary.alive and Grid.distance(primary.cell, secondary.cell) == 1

func _update_support_skills(delta: float) -> void:
	for source: UnitState in units:
		if not source.active or not source.alive or source.spec.heal_amount <= 0.0:
			continue
		source.support_cooldown = maxf(0.0, source.support_cooldown - delta)
		if source.support_cooldown > 0.000001:
			continue
		source.support_cooldown = source.spec.heal_interval
		_emit("heal_pulse", {"source_id": source.id})
		for target: UnitState in units:
			if not target.active or not target.alive or target.team != source.team:
				continue
			if not source.spec.heal_teamwide and Grid.distance(source.cell, target.cell) > source.spec.heal_range:
				continue
			var effective: float = minf(source.spec.heal_amount * source.level_multiplier, target.max_hp - target.hp)
			if effective <= 0.000001:
				continue
			target.hp += effective
			source.healing_done += effective
			_emit("heal", {"source_id": source.id, "target_id": target.id, "amount": effective})

func _is_moonwalker(unit: UnitState) -> bool:
	return unit.key == "michael" and unit.spec.moonwalk_steps > 0

## Michael: N random free hexes walking backwards, then a team shield and a pause.
## A step with no free neighbour is danced in place so the cycle never stalls.
func _update_moonwalks(delta: float) -> void:
	for unit: UnitState in units:
		if not unit.active or not unit.alive or not _is_moonwalker(unit) or unit.stun_remaining > 0.0:
			continue
		if unit.moonwalk_stage == "ready":
			_start_moonwalk_step(unit)
			continue
		unit.moonwalk_timer -= delta
		if unit.moonwalk_timer > 0.000001:
			continue
		if unit.moonwalk_stage == "pause":
			unit.moonwalk_steps_done = 0
			_start_moonwalk_step(unit)
			continue
		unit.moonwalk_steps_done += 1
		if unit.moonwalk_steps_done < unit.spec.moonwalk_steps:
			_start_moonwalk_step(unit)
			continue
		unit.moonwalk_stage = "pause"
		unit.moonwalk_from_cell = unit.cell
		unit.moonwalk_to_cell = unit.cell
		unit.moonwalk_timer += unit.spec.moonwalk_pause_duration
		_grant_dance_shield(unit)

func _start_moonwalk_step(unit: UnitState) -> void:
	var occupied: Dictionary = _occupied_cells()
	var options: Array[Vector2i] = []
	for candidate: Vector2i in Grid.neighbors(unit.cell):
		if not occupied.has(candidate) and candidate != unit.moonwalk_previous_cell:
			options.append(candidate)
	if options.is_empty():
		for candidate: Vector2i in Grid.neighbors(unit.cell):
			if not occupied.has(candidate):
				options.append(candidate)
	unit.moonwalk_from_cell = unit.cell
	## Adding to the leftover (≤0) keeps the cadence exact across fixed ticks.
	unit.moonwalk_timer += unit.spec.moonwalk_step_duration
	if options.is_empty():
		unit.moonwalk_stage = "blocked"
		unit.moonwalk_to_cell = unit.cell
		_emit("moonwalk_step", {"source_id": unit.id, "from": unit.cell, "to": unit.cell, "step": unit.moonwalk_steps_done + 1, "blocked": true})
		return
	var destination: Vector2i = options[_rng.randi_range(0, options.size() - 1)]
	unit.moonwalk_stage = "walking"
	unit.moonwalk_previous_cell = unit.cell
	unit.previous_cell = unit.cell
	unit.cell = destination
	unit.moonwalk_to_cell = destination
	## Facing is the opposite of the step: he slides backwards.
	unit.facing_axial = Grid.offset_to_axial(unit.moonwalk_from_cell) - Grid.offset_to_axial(destination)
	unit.last_action = "moonwalk"
	_emit("moonwalk_step", {"source_id": unit.id, "from": unit.moonwalk_from_cell, "to": destination, "step": unit.moonwalk_steps_done + 1, "blocked": false})

## Refresh, never stack: each ally keeps the larger of current/new value and a new duration.
func _grant_dance_shield(source: UnitState) -> void:
	var targets: Array[int] = []
	for ally: UnitState in units:
		if ally.team != source.team or not ally.active or not ally.alive:
			continue
		ally.dance_shield = maxf(ally.dance_shield, source.spec.dance_shield_amount * source.level_multiplier)
		ally.dance_shield_remaining = source.spec.dance_shield_duration
		targets.append(ally.id)
	source.last_action = "dance"
	_emit("dance_shield", {"source_id": source.id, "amount": source.spec.dance_shield_amount * source.level_multiplier, "duration": source.spec.dance_shield_duration, "targets": targets})

func _update_dance_shields(delta: float) -> void:
	for unit: UnitState in units:
		if unit.dance_shield_remaining <= 0.0:
			continue
		unit.dance_shield_remaining = maxf(0.0, unit.dance_shield_remaining - delta)
		if unit.dance_shield_remaining <= 0.000001:
			unit.dance_shield = 0.0

func _apply_bleed(source: UnitState, target: UnitState) -> void:
	for bleed: Dictionary in target.bleeds:
		if int(bleed["source_id"]) == source.id:
			bleed["remaining"] = source.spec.bleed_duration
			return # Refresh duration without resetting tick cadence or adding stacks.
	target.bleeds.append({
		"source_id": source.id, "damage": source.spec.bleed_damage_per_tick * source.level_multiplier,
		"remaining": source.spec.bleed_duration,
		"until_tick": source.spec.bleed_tick_interval,
		"interval": source.spec.bleed_tick_interval
	})
	_emit("bleed_applied", {"source_id": source.id, "target_id": target.id})

func _update_bleeds(delta: float) -> void:
	for target: UnitState in units:
		if not target.active or not target.alive:
			continue
		var remaining: Array[Dictionary] = []
		for bleed: Dictionary in target.bleeds:
			bleed["remaining"] = float(bleed["remaining"]) - delta
			bleed["until_tick"] = float(bleed["until_tick"]) - delta
			if float(bleed["until_tick"]) <= 0.000001 and float(bleed["remaining"]) >= -0.000001:
				var revives_before: int = target.revive_count
				_deal_damage(int(bleed["source_id"]), target, float(bleed["damage"]), false, "bleed")
				if target.revive_count > revives_before:
					## Revival cleanses all bleeds, including effects already retained locally.
					remaining.clear()
					break
				bleed["until_tick"] = float(bleed["until_tick"]) + float(bleed["interval"])
			if target.alive and float(bleed["remaining"]) > 0.000001:
				remaining.append(bleed)
			if not target.alive:
				break
		if target.alive:
			target.bleeds = remaining
		else:
			## [] here would be an untyped Array at runtime, not Array[Dictionary].
			target.bleeds.clear()

func _deal_damage(source_id: int, target: UnitState, raw_damage: float, critical: bool, kind: String, execution: bool = false, damage_type: String = "physical") -> void:
	if not target.active or not target.alive:
		return
	var defense: float = target.resist if damage_type == "magic" else target.armor
	var reduced: float = maxf(0.0, raw_damage) if execution else maxf(0.0, raw_damage) * 100.0 / (100.0 + defense)
	var absorbed: float = 0.0
	var absorbed_dance: float = 0.0
	var absorbed_base: float = 0.0
	if not execution:
		absorbed_dance = minf(target.dance_shield, reduced)
		target.dance_shield -= absorbed_dance
		reduced -= absorbed_dance
		absorbed_base = minf(target.shield, reduced)
		target.shield -= absorbed_base
		absorbed = absorbed_dance + absorbed_base
		target.shield_absorbed += absorbed
		reduced -= absorbed_base
	var effective: float = minf(target.hp, reduced)
	target.hp = maxf(0.0, target.hp - effective)
	var source: UnitState = get_unit(source_id)
	if source != null:
		team_damage[source.team] += effective
		source.damage_dealt += effective
	_emit(kind, {"source_id": source_id, "target_id": target.id, "amount": effective, "absorbed": absorbed, "absorbed_dance": absorbed_dance, "absorbed_base": absorbed_base, "critical": critical, "damage_type": "execution" if execution else damage_type})
	var revival_ratio: float = 0.0
	if target.revive_count == 0:
		revival_ratio = target.spec.revive_ratio
	elif target.revive_count == 1 and target.level >= target.spec.extra_revive_min_level:
		revival_ratio = target.spec.extra_revive_ratio
	if target.hp <= 0.000001 and revival_ratio > 0.0:
		## Primeiro retorno40%; no N3 Lula tem mais um retorno configurado30%.
		target.revived = true
		target.revive_count += 1
		target.hp = target.max_hp * revival_ratio
		target.bleeds.clear()
		target.stun_remaining = 0.0
		_emit("revive", {"source_id": source_id, "target_id": target.id, "amount": target.hp, "count": target.revive_count})
		return
	if target.hp <= 0.000001:
		target.hp = 0.0
		target.alive = false
		target.bleeds.clear()
		target.last_action = "dead"
		target.dance_shield = 0.0
		target.dance_shield_remaining = 0.0
		if source != null:
			source.kills += 1
		_emit("death", {"source_id": source_id, "target_id": target.id})

## Sem chefe ativo existente não há vitória/recompensa PvE, mesmo com mais tropas.
func boss_defeated() -> bool:
	if not is_boss_round:
		return false
	var found_boss: bool = false
	for unit: UnitState in units:
		if not unit.active or not unit.is_boss or unit.team != 1:
			continue
		found_boss = true
		if unit.alive:
			return false
	return found_boss

func _check_resolution() -> void:
	var survivors: Array[int] = [0, 0]
	for unit: UnitState in units:
		if unit.active and unit.alive and not unit.summoned:
			survivors[unit.team] += 1
	var winner: int = -1
	var reason: String = ""
	if is_boss_round:
		if boss_defeated():
			winner = 0
			reason = "elimination"
		elif survivors[0] == 0:
			winner = 1
			reason = "elimination"
		elif elapsed + 0.000001 >= round_duration:
			winner = 1
			reason = "timeout"
	elif survivors[0] == 0 or survivors[1] == 0:
		reason = "elimination"
		if survivors[0] != survivors[1]:
			winner = 0 if survivors[0] > survivors[1] else 1
	elif elapsed + 0.000001 >= round_duration:
		if survivors[0] != survivors[1]:
			winner = 0 if survivors[0] > survivors[1] else 1
			reason = "survivors"
		elif not is_equal_approx(team_damage[0], team_damage[1]):
			winner = 0 if team_damage[0] > team_damage[1] else 1
			reason = "damage"
		else:
			reason = "draw"
	if reason.is_empty():
		return
	phase = "finished"
	if winner >= 0 and not is_boss_round:
		var loser: int = 1 - winner
		team_lives[loser] = maxi(0, team_lives[loser] - 1)
		if team_lives[loser] == 0:
			match_winner = winner
	round_result = {"winner": winner, "reason": reason, "survivors": survivors, "damage": team_damage.duplicate(), "elapsed": elapsed, "units_summary": unit_summaries(), "is_boss_round": is_boss_round}
	projectiles.clear()
	zones.clear()
	_emit("round_finished", round_result.duplicate(true))

func _emit(kind: String, fields: Dictionary = {}) -> void:
	var event: Dictionary = fields.duplicate(true)
	event["type"] = kind
	event["tick"] = tick
	event["time"] = elapsed
	events.append(event)
	if events.size() > MAX_BUFFERED_EVENTS:
		events.pop_front()

func drain_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = events.duplicate(true)
	events.clear()
	return result

func snapshot() -> Dictionary:
	var unit_snapshots: Array[Dictionary] = []
	var projectile_snapshots: Array[Dictionary] = []
	for unit: UnitState in units:
		unit_snapshots.append(unit.as_dictionary())
	for ball: BallProjectile in projectiles:
		projectile_snapshots.append(ball.as_dictionary())
	return {
		"phase": phase, "tick": tick, "elapsed": elapsed, "round": round_index,
		"lives": team_lives.duplicate(), "match_winner": match_winner,
		"is_boss_round": is_boss_round,
		"units": unit_snapshots, "projectiles": projectile_snapshots,
		"damage": team_damage.duplicate(), "result": round_result.duplicate(true),
		"accelerated": accelerated, "synergies": synergy_snapshot.duplicate(true), "zones": zones.duplicate(true)
	}

func unit_summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit: UnitState in units:
		result.append({
			"id": unit.id, "key": unit.key, "name": unit.display_name, "team": unit.team,
			"active": unit.active, "alive": unit.alive, "hp": unit.hp, "max_hp": unit.max_hp,
			"damage_dealt": unit.damage_dealt, "healing_done": unit.healing_done,
			"shield_absorbed": unit.shield_absorbed, "kills": unit.kills, "level": unit.level, "summoned": unit.summoned
		})
	return result
