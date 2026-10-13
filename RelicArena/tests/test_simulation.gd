extends SceneTree
## Run with --headless --path RelicArena --script res://tests/test_simulation.gd.
## Assertions record failures and always reach quit; no bare assert().

const Simulation = preload("res://simulation/arena_simulation.gd")
const Grid = preload("res://simulation/hex_grid.gd")
const UnitState = preload("res://simulation/unit_state.gd")
const UnitSpec = preload("res://data/unit_spec.gd")
const Catalog = preload("res://data/character_catalog.gd")

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_test_grid()
	_test_preparation()
	_test_attack_cadence()
	_test_neymar()
	_test_caramelo()
	_test_bleed_kill_continues_tick()
	_test_obama()
	_test_zumbi()
	_test_clock_and_lives()
	_test_resolution_priorities()
	_test_replay_and_occupancy()
	_test_michael()
	_test_reserve_and_roster()
	_test_runtime_equipment()
	_test_functional_synergies()
	_test_match_levels()
	_test_assassin_opening()
	_test_briefcase_refresh()
	_test_kick_observation()
	_test_lote_03_kits()
	_test_revive_clears_bleeds()
	_test_summon_unique_ids()
	print("SIMULATION TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.0001, "%s (got %s; expected %s)" % [label, actual, expected])

func _sandbox() -> Simulation:
	var sim: Simulation = Simulation.new()
	sim.units.clear()
	return sim

func _fixture_unit(key: String, unit_id: int, team: int, cell: Vector2i, changes: Dictionary = {}) -> UnitState:
	var values: Dictionary = {
		"max_hp": 1000.0, "attack_damage": 10.0, "armor": 0.0,
		"attacks_per_second": 0.01, "crit_chance": 0.0, "attack_range": 1,
		"move_interval": 1000.0, "crit_multiplier": 1.5,
		"projectile_seconds_per_hex": 0.12, "projectile_min_seconds": 0.12,
		"projectile_max_impacts": 3
	}
	values.merge(changes, true)
	var spec: UnitSpec = UnitSpec.new()
	spec.load_values(key, values)
	var unit: UnitState = UnitState.new(spec, unit_id, team, cell)
	unit.attack_cooldown = 1000.0
	unit.move_cooldown = 1000.0
	return unit

func _events(sim: Simulation, event_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in sim.events:
		if event["type"] == event_type:
			result.append(event)
	return result

func _test_grid() -> void:
	var valid: bool = true
	for row: int in range(8):
		for column: int in range(8):
			var cell: Vector2i = Vector2i(column, row)
			valid = valid and Grid.axial_to_offset(Grid.offset_to_axial(cell)) == cell
			for neighbor: Vector2i in Grid.neighbors(cell):
				valid = valid and Grid.distance(cell, neighbor) == 1 and Grid.neighbors(neighbor).has(cell)
	_check(valid, "64 hexes: inverse conversion, adjacency and symmetry")
	_check(Grid.neighbors(Vector2i(3, 3)).size() == 6, "interior hex has six neighbors")
	_check(not Grid.contains(Vector2i(-1, 0)) and not Grid.contains(Vector2i(8, 7)), "board bounds")
	var occupied: Dictionary = {Vector2i(3, 3): 9, Vector2i(4, 3): 10}
	var origin: Vector2i = Vector2i(3, 4)
	var step_cell: Vector2i = Grid.next_step(origin, Vector2i(3, 1), 1, occupied)
	_check(Grid.distance(origin, step_cell) == 1 and not occupied.has(step_cell), "path detours around occupied cells")
	var blocked: Dictionary = {}
	for neighbor: Vector2i in Grid.neighbors(origin):
		blocked[neighbor] = true
	_check(Grid.next_step(origin, Vector2i(3, 0), 1, blocked) == origin, "blocked unit waits without teleporting")

func _test_preparation() -> void:
	var sim: Simulation = Simulation.new()
	_check(sim.units.size() == Catalog.KEYS.size() * 2 and sim.get_unit(1).active and not sim.get_unit(5).active and not sim.get_unit(6).active and sim.team_lives == [4, 4], "catalog roster per side, four active, four lives")
	_check(not sim.place_unit(1, Vector2i(2, 2)), "reject placement in opponent half")
	_check(not sim.place_unit(1, sim.get_unit(3).cell), "reject occupied preparation hex")
	_check(sim.place_unit(1, Vector2i(0, 7)), "accept empty own hex")
	_check(sim.start_combat(), "start valid formation")
	_check(not sim.start_combat() and not sim.place_unit(1, Vector2i(1, 7)), "combat cannot restart or accept placement")

func _test_neymar() -> void:
	var sim: Simulation = _sandbox()
	var source: UnitState = _fixture_unit("neymar", 1, 0, Vector2i(3, 4), {
		"attack_range": 3,
		"projectile_decay_multipliers": [1.0, 0.8, 0.5]
	})
	var first: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 2))
	var second: UnitState = _fixture_unit("target", 102, 1, Vector2i(4, 2))
	var third: UnitState = _fixture_unit("target", 103, 1, Vector2i(5, 2))
	sim.units = [source, first, second, third]
	source.attack_cooldown = 0.0
	sim.start_combat()
	sim.step(1.0)
	var impacts: Array[Dictionary] = _events(sim, "ball_impact")
	_check(impacts.size() == 3, "one kick has exactly three impacts with intact pair")
	if impacts.size() == 3:
		_check([impacts[0]["target_id"], impacts[1]["target_id"], impacts[2]["target_id"]] == [101, 102, 101], "ball follows A-B-A, never third target")
		_near(float(impacts[0]["damage"]), 10.0, "first impact applies 100% damage")
		_near(float(impacts[1]["damage"]), 8.0, "second impact applies 80% damage")
		_near(float(impacts[2]["damage"]), 5.0, "third impact applies 50% damage")
	_near(first.hp, 985.0, "primary receives two impacts with decay (10 + 5 = 15)")
	_near(second.hp, 992.0, "neighbor receives one impact with decay (8)")
	_near(third.hp, 1000.0, "third enemy untouched")
	_check(source.attack_count == 1 and sim.projectiles.is_empty(), "bounce never produces extra attacks or infinite projectiles")

	var separated: Simulation = _sandbox()
	var shooter: UnitState = _fixture_unit("neymar", 1, 0, Vector2i(3, 4), {"attack_range": 3})
	var a: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 2))
	var b: UnitState = _fixture_unit("target", 102, 1, Vector2i(4, 2))
	separated.units = [shooter, a, b]
	shooter.attack_cooldown = 0.0
	separated.start_combat()
	separated.step(0.3)
	b.cell = Vector2i(7, 0)
	separated.step(0.5)
	_check(_events(separated, "ball_impact").size() == 1 and separated.projectiles.is_empty(), "pair separation cancels bounce before next impact")
	_check(_events(separated, "ball_expired").size() == 1 and _events(separated, "ball_expired")[0]["reason"] == "pair_separated", "moving pair reports separation once")
	_near(b.hp, 1000.0, "ball cannot damage neighbor after pair separates")

	var dead_target_sim: Simulation = _sandbox()
	var kicker: UnitState = _fixture_unit("neymar", 1, 0, Vector2i(3, 4), {"attack_range": 3})
	var fragile: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 2), {"max_hp": 5.0})
	var neighbor: UnitState = _fixture_unit("target", 102, 1, Vector2i(4, 2))
	dead_target_sim.units = [kicker, fragile, neighbor]
	kicker.attack_cooldown = 0.0
	dead_target_sim.start_combat()
	dead_target_sim.step(1.0)
	_check(_events(dead_target_sim, "ball_impact").size() == 1, "death of primary ends ball instead of bouncing off corpse")
	_near(dead_target_sim.team_damage[0], 5.0, "projectile overkill only counts remaining HP")
	_check(_events(dead_target_sim, "death").size() == 1, "one projectile produces one death per target")
	_check(_events(dead_target_sim, "ball_expired").size() == 1 and _events(dead_target_sim, "ball_expired")[0]["reason"] == "pair_dead", "primary killed by impact reports dead pair explicitly")

func _test_attack_cadence() -> void:
	var sim: Simulation = _sandbox()
	var source: UnitState = _fixture_unit("attacker", 1, 0, Vector2i(3, 4), {"attacks_per_second": 1.0})
	var target: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3))
	sim.units = [source, target]
	source.attack_cooldown = -10.0 # Reproduces accumulated waiting while out of reach.
	sim.start_combat()
	sim.step(0.15)
	_check(source.attack_count == 1, "returning to range cannot catch up attacks for time spent walking")

func _test_caramelo() -> void:
	for hp_value: float in [11.0, 10.0, 9.0]:
		var sim: Simulation = _sandbox()
		var dog: UnitState = _fixture_unit("caramelo", 1, 0, Vector2i(3, 4), {
			"attack_damage": 1.0, "execute_threshold": 0.1,
			"bleed_damage_per_tick": 3.0, "bleed_duration": 3.0
		})
		var target: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3), {"max_hp": 100.0})
		target.hp = hp_value
		sim.units = [dog, target]
		dog.attack_cooldown = 0.0
		sim.start_combat()
		sim.step(0.05)
		_check(target.alive == (hp_value > 10.0), "execution boundary: starting HP %s / 100" % hp_value)
		_check(_events(sim, "execute").size() == (0 if hp_value > 10.0 else 1), "execution occurs before ordinary bite at %s HP" % hp_value)
		if hp_value <= 10.0:
			sim.step(2.0)
			_check(_events(sim, "death").size() == 1, "execution emits death only once")
			_check(dog.kills == 1 and dog.damage_dealt == hp_value, "execution credits exactly one kill and remaining HP damage")

	var bleed_sim: Simulation = _sandbox()
	var biter: UnitState = _fixture_unit("caramelo", 1, 0, Vector2i(3, 4), {
		"attack_damage": 0.0, "bleed_damage_per_tick": 4.0, "bleed_duration": 3.0,
		"bleed_tick_interval": 1.0, "attacks_per_second": 2.0
	})
	var victim: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3))
	bleed_sim.units = [biter, victim]
	biter.attack_cooldown = 0.0
	bleed_sim.start_combat()
	bleed_sim.step(1.1)
	_check(victim.bleeds.size() == 1, "repeated bites refresh one bleed without unlimited stacks")
	_near(victim.hp, 996.0, "repeated bites do not postpone bleed tick forever")
	biter.alive = false
	biter.hp = 0.0
	var ally: UnitState = _fixture_unit("ally", 2, 0, Vector2i(0, 7))
	bleed_sim.units.append(ally)
	bleed_sim.step(1.0)
	_near(victim.hp, 992.0, "existing bleed continues after source death")

func _test_obama() -> void:
	var sim: Simulation = _sandbox()
	var attacker: UnitState = _fixture_unit("attacker", 1, 0, Vector2i(3, 4), {"attack_damage": 40.0, "attacks_per_second": 2.0})
	var tank: UnitState = _fixture_unit("obama", 101, 1, Vector2i(3, 3), {"initial_shield": 50.0})
	sim.units = [attacker, tank]
	attacker.attack_cooldown = 0.0
	sim.start_combat()
	sim.step(0.05)
	_near(tank.hp, 1000.0, "briefcase absorbs first attack")
	_near(tank.shield, 10.0, "shield subtracts absorbed damage")
	_near(sim.team_damage[0], 0.0, "shield absorption does not inflate HP damage tiebreak")
	sim.step(0.5)
	_near(tank.hp, 970.0, "damage exceeding remaining shield reaches HP")
	_near(tank.shield, 0.0, "shield never becomes negative")
	_near(sim.team_damage[0], 30.0, "only actual HP loss counts toward damage")
	_near(tank.shield_absorbed, 50.0, "individual shield statistic counts actual absorption")
	_near(attacker.damage_dealt, 30.0, "attacker statistic excludes absorbed damage")

func _test_bleed_kill_continues_tick() -> void:
	var sim: Simulation = _sandbox()
	var dog: UnitState = _fixture_unit("caramelo", 1, 0, Vector2i(3, 4))
	var dying: UnitState = _fixture_unit("first", 101, 1, Vector2i(3, 3))
	var surviving: UnitState = _fixture_unit("second", 102, 1, Vector2i(4, 2))
	dying.hp = 3.0
	for target: UnitState in [dying, surviving]:
		target.bleeds.append({"source_id": 1, "damage": 4.0, "remaining": 1.0, "until_tick": 0.05, "interval": 1.0})
	sim.units = [dog, dying, surviving]
	sim.start_combat()
	sim.step(0.05)
	_check(not dying.alive and dying.bleeds.is_empty(), "bleed death clears typed effect array")
	_near(surviving.hp, 996.0, "bleed death cannot abort ticking remaining units in same step")
	_near(dog.damage_dealt, 7.0, "same-tick bleed damage counts killed and surviving targets")
	_check(dog.kills == 1 and _events(sim, "death").size() == 1, "bleed kill is credited exactly once")

func _test_zumbi() -> void:
	var sim: Simulation = _sandbox()
	var warrior: UnitState = _fixture_unit("zumbi", 1, 0, Vector2i(3, 4), {
		"crit_chance": 1.0, "crit_multiplier": 1.5, "attacks_per_second": 2.0,
		"team_attack_speed_bonus": 0.2, "team_crit_bonus": 0.1,
		"crit_growth_per_hit": 0.25, "crit_growth_cap": 0.5
	})
	var ally: UnitState = _fixture_unit("ally", 2, 0, Vector2i(0, 7))
	var target: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3))
	sim.units = [warrior, ally, target]
	warrior.attack_cooldown = 0.0
	sim.start_combat()
	_near(ally.attack_speed_multiplier, 1.2, "Zumbi buffs whole allied team attack speed")
	_near(ally.effective_crit_chance, 0.1, "Zumbi buffs whole allied team critical chance")
	sim.step(1.0)
	var hits: Array[Dictionary] = _events(sim, "hit")
	_check(hits.size() == 3, "controlled Zumbi fixture lands three attacks")
	if hits.size() == 3:
		_near(float(hits[0]["amount"]), 15.0, "first critical uses base multiplier")
		_near(float(hits[1]["amount"]), 17.5, "next personal critical grows")
		_near(float(hits[2]["amount"]), 20.0, "growth reaches configured cap")
	_near(warrior.crit_growth, 0.5, "critical growth never exceeds cap")
	_check(warrior.crit_growth_hits == 3, "growth counter records only personal critical attacks, including capped ones")
	_near(float(warrior.as_dictionary()["crit_damage_multiplier"]), 2.0, "snapshot exposes next critical multiplier")
	var growth_events: Array[Dictionary] = _events(sim, "crit_growth")
	_check(growth_events.size() == 3 and growth_events[2]["stacks"] == 3 and growth_events[2]["cap"] == 0.5 and growth_events[2]["multiplier"] == 2.0, "growth event exposes personal count, cap and next multiplier")
	_near(ally.crit_growth, 0.0, "Zumbi growth is not copied to allies")
	warrior.alive = false
	warrior.hp = 0.0
	sim.step(0.05)
	_near(ally.attack_speed_multiplier, 1.2, "round-snapshot buff persists after Zumbi death in experiment")

	var personal: Simulation = _sandbox()
	var leader: UnitState = _fixture_unit("zumbi", 1, 0, Vector2i(4, 4), {
		"crit_chance": 1.0, "crit_growth_per_hit": 0.25, "crit_growth_cap": 0.5
	})
	var critical_ally: UnitState = _fixture_unit("ally", 2, 0, Vector2i(3, 4), {"crit_chance": 1.0})
	var enemy: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3))
	personal.units = [leader, critical_ally, enemy]
	critical_ally.attack_cooldown = 0.0
	personal.start_combat()
	personal.step(0.05)
	_near(leader.crit_growth, 0.0, "allied critical does not feed Zumbi's counter")
	_check(leader.crit_growth_hits == 0, "allied critical never increments readable personal counter")
	leader.attack_cooldown = 0.0
	personal.step(0.05)
	_near(leader.crit_growth, 0.25, "own critical feeds Zumbi's counter")
	leader.effective_crit_chance = 0.0
	leader.attack_cooldown = 0.0
	personal.step(0.05)
	_near(leader.crit_growth, 0.25, "own noncritical attack does not feed counter")
	_check(leader.crit_growth_hits == 1, "noncritical hit leaves readable personal counter unchanged")

	# Validação da calibração do Zumbi (base 50 -> 1º crit 100 -> 120 -> 140 -> 160 -> 180):
	var zumbi_calib: Simulation = _sandbox()
	var zumbi_real: UnitState = _kit_unit("zumbi", 1, 0, Vector2i(3, 4))
	var zumbi_ally: UnitState = _fixture_unit("ally", 2, 0, Vector2i(0, 7))
	var dummy: UnitState = _fixture_unit("dummy", 101, 1, Vector2i(3, 3), {"armor": 0.0, "max_hp": 5000.0})
	dummy.hp = 5000.0
	zumbi_calib.units = [zumbi_real, zumbi_ally, dummy]
	zumbi_calib.start_combat()
	# Buff de crítico e velocidade para o aliado:
	_near(zumbi_ally.effective_crit_chance, 0.15, "Zumbi gives +15% crit chance to team allies")
	_near(zumbi_ally.attack_speed_multiplier, 1.15, "Zumbi gives +15% attack speed to team allies")
	# Ataque não-crítico causa dano base 50:
	zumbi_real.effective_crit_chance = 0.0
	zumbi_real.attack_cooldown = 0.0
	zumbi_calib.step(0.05)
	var non_crit_hits: Array[Dictionary] = _events(zumbi_calib, "hit")
	_check(non_crit_hits.size() == 1 and is_equal_approx(float(non_crit_hits[0]["amount"]), 50.0), "non-critical attack deals base 50 damage")
	_check(zumbi_real.crit_growth == 0.0 and zumbi_real.crit_growth_hits == 0, "non-critical hit does not start growth")
	# Agora acertos críticos sequenciais:
	zumbi_real.effective_crit_chance = 1.0
	var expected_crit_damages: Array[float] = [100.0, 120.0, 140.0, 160.0, 180.0]
	for idx: int in range(expected_crit_damages.size()):
		zumbi_real.attack_cooldown = 0.0
		zumbi_calib.step(0.05)
		var current_hits: Array[Dictionary] = _events(zumbi_calib, "hit")
		var last_hit: Dictionary = current_hits[current_hits.size() - 1]
		_near(float(last_hit["amount"]), expected_crit_damages[idx], "zumbi crit %d deals %f" % [idx + 1, expected_crit_damages[idx]])

func _test_clock_and_lives() -> void:
	var sim: Simulation = _sandbox()
	var a: UnitState = _fixture_unit("a", 1, 0, Vector2i(0, 7))
	var b: UnitState = _fixture_unit("b", 101, 1, Vector2i(7, 0))
	sim.units = [a, b]
	sim.start_combat()
	sim.step(14.95)
	_check(not sim.accelerated, "acceleration does not begin before 15 seconds")
	sim.step(0.05)
	_check(sim.accelerated and _events(sim, "acceleration").size() == 1, "acceleration begins exactly once at 15 seconds")
	sim.step(15.0)
	_check(sim.phase == "finished" and sim.tick == 600, "round ends after 30 real simulation seconds")
	_check(sim.round_result["winner"] == -1 and sim.team_lives == [4, 4], "complete draw preserves lives in current experiment")

	var match_sim: Simulation = Simulation.new()
	match_sim.place_unit(1, Vector2i(0, 7))
	for round_number: int in range(4):
		match_sim.start_combat()
		for unit: UnitState in match_sim.units:
			if unit.team == 1:
				unit.hp = 0.0
				unit.alive = false
		match_sim.step(0.05)
		_check(match_sim.team_lives[1] == 3 - round_number, "one life lost on resolution of round %d" % (round_number + 1))
		match_sim.step(10.0)
		_check(match_sim.team_lives[1] == 3 - round_number, "finished round cannot charge a second life")
		if round_number < 3:
			_check(match_sim.next_round(), "next round permitted before match ends")
			_check(match_sim.get_unit(1).cell == Vector2i(0, 7), "next round preserves preparation formation")
			_check(match_sim.get_unit(4).crit_growth == 0.0 and match_sim.get_unit(3).shield > 0.0 and match_sim.get_unit(1).hp == match_sim.get_unit(1).max_hp, "new round resets HP, shields and personal growth")
	_check(match_sim.match_winner == 0 and not match_sim.next_round(), "fourth lost life ends match")
	match_sim.reset(77)
	_check(match_sim.round_index == 1 and match_sim.team_lives == [4, 4] and match_sim.match_winner == -1, "reset starts a clean match")

func _test_resolution_priorities() -> void:
	var crowded: Simulation = _sandbox()
	crowded.round_duration = 0.05
	crowded.units = [
		_fixture_unit("a", 1, 0, Vector2i(0, 7)),
		_fixture_unit("b", 2, 0, Vector2i(1, 7)),
		_fixture_unit("c", 101, 1, Vector2i(7, 0))
	]
	crowded.team_damage = [0.0, 9000.0]
	crowded.start_combat()
	crowded.step(0.05)
	_check(crowded.round_result["winner"] == 0 and crowded.round_result["reason"] == "survivors", "surviving troop count takes priority over damage at timeout")

	var tied_troops: Simulation = _sandbox()
	tied_troops.round_duration = 0.05
	tied_troops.units = [
		_fixture_unit("a", 1, 0, Vector2i(0, 7)),
		_fixture_unit("b", 101, 1, Vector2i(7, 0))
	]
	tied_troops.team_damage = [10.0, 11.0]
	tied_troops.start_combat()
	tied_troops.step(0.05)
	_check(tied_troops.round_result["winner"] == 1 and tied_troops.round_result["reason"] == "damage", "damage breaks equal surviving troop count")

	var armored: Simulation = _sandbox()
	var hitter: UnitState = _fixture_unit("hitter", 1, 0, Vector2i(3, 4), {"attack_damage": 40.0})
	var defender: UnitState = _fixture_unit("defender", 101, 1, Vector2i(3, 3), {"armor": 100.0, "initial_shield": 10.0})
	armored.units = [hitter, defender]
	hitter.attack_cooldown = 0.0
	armored.start_combat()
	armored.step(0.05)
	_near(defender.hp, 990.0, "physical armor reduces damage before shield absorption")
	_near(armored.team_damage[0], 10.0, "damage score excludes armor mitigation and shield absorption")

func _test_replay_and_occupancy() -> void:
	var first: Simulation = Simulation.new()
	var second: Simulation = Simulation.new()
	first.reset(7129)
	second.reset(7129)
	first.start_combat()
	second.start_combat()
	var exclusive: bool = true
	for index: int in range(600):
		first.step(0.05)
		var occupied: Dictionary = {}
		for unit: UnitState in first.units:
			if unit.active and unit.alive:
				exclusive = exclusive and Grid.contains(unit.cell) and not occupied.has(unit.cell)
				occupied[unit.cell] = true
	second.step(30.0)
	_check(exclusive, "entire default fight stays inside board with exclusive living occupancy")
	_check(first.snapshot() == second.snapshot(), "same seed and formation reproduce state across delta partitioning")
	_check(first.phase == "finished", "default four-versus-four fight resolves")
	for unit: UnitState in first.units:
		_check(unit.hp >= 0.0 and unit.shield >= 0.0, "HP and shields stay nonnegative for unit %d" % unit.id)

func _test_michael() -> void:
	var sim: Simulation = _sandbox()
	var dancer: UnitState = _fixture_unit("michael", 5, 0, Vector2i(3, 4), {"max_hp": 100.0, "heal_amount": 75.0, "heal_interval": 4.0, "heal_range": 2, "moonwalk_steps": 0})
	var near_a: UnitState = _fixture_unit("a", 1, 0, Vector2i(4, 4), {"max_hp": 100.0})
	var near_b: UnitState = _fixture_unit("b", 2, 0, Vector2i(2, 4), {"max_hp": 100.0})
	var distant: UnitState = _fixture_unit("c", 3, 0, Vector2i(0, 7), {"max_hp": 100.0})
	var reserve: UnitState = _fixture_unit("reserve", 4, 0, Vector2i(3, 3), {"max_hp": 100.0})
	var corpse: UnitState = _fixture_unit("corpse", 6, 0, Vector2i(3, 5), {"max_hp": 100.0})
	var enemy: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(7, 0))
	dancer.hp = 90.0
	near_a.hp = 40.0
	near_b.hp = 80.0
	distant.hp = 10.0
	reserve.hp = 10.0
	reserve.active = false
	corpse.hp = 0.0
	corpse.alive = false
	sim.units = [near_a, near_b, distant, reserve, dancer, corpse, enemy]
	sim.start_combat()
	sim.step(3.95)
	_near(near_a.hp, 40.0, "dance healing waits its configured interval")
	sim.step(0.05)
	_near(near_a.hp, 100.0, "dance pulse heals a nearby injured ally without overheal")
	_near(near_b.hp, 100.0, "same pulse heals all nearby injured allies")
	_near(dancer.hp, 100.0, "test pulse permits explicit self-healing proposal")
	_near(distant.hp, 10.0, "dance does not heal outside configured hex radius")
	_near(reserve.hp, 10.0, "dance does not affect reserve")
	_check(not corpse.alive and corpse.hp == 0.0, "healing does not revive dead units")
	_near(dancer.healing_done, 90.0, "healing statistic counts only HP actually restored")
	_check(_events(sim, "heal_pulse").size() == 1 and _events(sim, "heal").size() == 3, "heal pulse and individual healing events emitted")
	_check(dancer.cell == Vector2i(3, 4) and _events(sim, "moonwalk_step").is_empty(), "moonwalk_steps 0 disables the walk")
	sim.step(4.0)
	_near(dancer.healing_done, 90.0, "full health does not inflate healing statistics")
	_test_michael_moonwalk()

	var magical: Simulation = _sandbox()
	var singer: UnitState = _fixture_unit("michael", 5, 0, Vector2i(3, 4), {"damage_type": "magic", "attack_damage": 40.0, "moonwalk_steps": 0})
	var tank: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3), {"armor": 900.0, "resist": 100.0})
	magical.units = [singer, tank]
	singer.attack_cooldown = 0.0
	magical.start_combat()
	magical.step(0.05)
	_near(tank.hp, 980.0, "magic attack uses resistance instead of physical armor")
	_near(singer.damage_dealt, 20.0, "individual damage includes only actual enemy HP loss")
	_check(_events(magical, "hit")[0]["damage_type"] == "magic", "damage event declares magic type")

func _moonwalk_fixture(changes: Dictionary = {}) -> Dictionary:
	var sim: Simulation = _sandbox()
	var values: Dictionary = {"attack_damage": 0.0, "heal_amount": 0.0, "moonwalk_steps": 3, "moonwalk_step_duration": 0.5, "moonwalk_pause_duration": 1.0, "dance_shield_amount": 100.0, "dance_shield_duration": 4.0}
	values.merge(changes, true)
	var dancer: UnitState = _fixture_unit("michael", 5, 0, Vector2i(3, 5), values)
	var ally: UnitState = _fixture_unit("ally", 1, 0, Vector2i(0, 7))
	var reserve: UnitState = _fixture_unit("reserve", 2, 0, Vector2i(7, 7))
	reserve.active = false
	var enemy: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(7, 0))
	sim.units = [ally, reserve, dancer, enemy]
	return {"sim": sim, "dancer": dancer, "ally": ally, "reserve": reserve, "enemy": enemy}

func _test_michael_moonwalk() -> void:
	var fixture: Dictionary = _moonwalk_fixture()
	var sim: Simulation = fixture["sim"]
	var dancer: UnitState = fixture["dancer"]
	var ally: UnitState = fixture["ally"]
	sim.start_combat()
	sim.step(0.05)
	var first: Array[Dictionary] = _events(sim, "moonwalk_step")
	_check(first.size() == 1 and dancer.moonwalk_stage == "walking", "first moonwalk step starts on the first tick")
	_check(Grid.distance(Vector2i(3, 5), dancer.cell) == 1, "each step reserves one adjacent hex")
	var step_axial: Vector2i = Grid.offset_to_axial(dancer.cell) - Grid.offset_to_axial(Vector2i(3, 5))
	_check(dancer.facing_axial == -step_axial, "Michael faces away from the step (walks backwards)")
	sim.step(1.45)
	_check(_events(sim, "moonwalk_step").size() == 3 and dancer.dance_shield == 0.0, "three steps happen before any shield")
	sim.step(0.05)
	var steps: Array[Dictionary] = _events(sim, "moonwalk_step")
	var chained: bool = steps.size() == 3
	var previous: Vector2i = Vector2i(3, 5)
	for event: Dictionary in steps:
		chained = chained and event["from"] == previous and Grid.distance(event["from"], event["to"]) == 1
		chained = chained and event["to"] != ally.cell and event["to"] != fixture["enemy"].cell
		previous = event["to"]
	_check(chained, "three chained single-hex steps avoid occupied hexes")
	_check(dancer.moonwalk_stage == "pause" and _events(sim, "dance_shield").size() == 1, "stopping after the third step grants one team shield")
	_near(dancer.dance_shield, 100.0, "dancer receives the dance shield")
	_near(ally.dance_shield, 100.0, "distant ally receives the team shield")
	_near(fixture["reserve"].dance_shield, 0.0, "reserve does not receive the shield")
	_near(fixture["enemy"].dance_shield, 0.0, "enemy does not receive the shield")
	sim._deal_damage(101, ally, 30.0, false, "hit")
	_near(ally.hp, 1000.0, "dance shield absorbs damage before HP")
	_near(ally.dance_shield, 70.0, "dance shield is consumed by absorbed damage")
	_check(_events(sim, "hit").back()["absorbed_dance"] == 30.0, "hit event reports dance absorption")
	sim.step(1.0)
	_check(dancer.moonwalk_stage == "walking" and dancer.moonwalk_steps_done == 0, "after the pause a new three-step cycle begins")
	sim.step(1.5)
	_check(_events(sim, "dance_shield").size() == 2, "second cycle grants a second shield")
	_near(ally.dance_shield, 100.0, "refresh keeps the larger value instead of stacking")
	_near(ally.dance_shield_remaining, 4.0, "refresh restarts duration")
	_check(_events(sim, "hit").filter(func(event: Dictionary) -> bool: return event["source_id"] == 5).is_empty(), "zero-damage dancer never emits hits")

	var lasting: Dictionary = _moonwalk_fixture({"moonwalk_pause_duration": 20.0, "dance_shield_duration": 2.0})
	var expiry: Simulation = lasting["sim"]
	expiry.start_combat()
	expiry.step(1.55)
	_near(lasting["ally"].dance_shield, 100.0, "shield active right after the third step")
	expiry.step(1.95)
	_near(lasting["ally"].dance_shield, 100.0, "shield lasts its configured duration")
	expiry.step(0.05)
	_near(lasting["ally"].dance_shield, 0.0, "shield expires after its duration")

	var boxed: Dictionary = _moonwalk_fixture()
	var crowded: Simulation = boxed["sim"]
	var walls: Array[UnitState] = []
	var wall_id: int = 10
	for neighbor: Vector2i in Grid.neighbors(Vector2i(3, 5)):
		walls.append(_fixture_unit("wall", wall_id, 0, neighbor))
		wall_id += 1
	crowded.units.append_array(walls)
	crowded.start_combat()
	crowded.step(1.55)
	_check(boxed["dancer"].cell == Vector2i(3, 5), "surrounded dancer stays in place")
	_check(_events(crowded, "moonwalk_step").all(func(event: Dictionary) -> bool: return event["blocked"]), "blocked steps are reported")
	_check(_events(crowded, "dance_shield").size() == 1, "blocked steps still complete the shield cycle")

	var first_run: Simulation = Simulation.new()
	var second_run: Simulation = Simulation.new()
	first_run.start_combat()
	second_run.start_combat()
	first_run.step(8.0)
	for index: int in range(160):
		second_run.step(0.05)
	var dancer_a: UnitState = first_run.get_unit(5)
	var dancer_b: UnitState = second_run.get_unit(5)
	_check(dancer_a.cell == dancer_b.cell and _events(first_run, "moonwalk_step").size() == _events(second_run, "moonwalk_step").size(), "seeded moonwalk path is reproducible")

func _test_reserve_and_roster() -> void:
	var sim: Simulation = Simulation.new()
	_check(sim.set_active(4, false), "active hero can move to reserve during preparation")
	_check(not sim.set_active(5, true, sim.get_unit(3).cell), "activation rejects occupied cell")
	_check(sim.set_active(5, true, Vector2i(3, 6)), "reserve can enter empty own hex")
	sim.start_combat()
	_near(sim.get_unit(1).attack_speed_multiplier, 1.0, "reserved Zumbi provides no aura")
	_check(not sim.set_active(4, true, Vector2i(2, 7)), "reserve changes rejected during combat")
	sim.step(30.0)
	_check(sim.get_unit(4).attack_count == 0 and sim.get_unit(4).damage_dealt == 0.0, "reserve never attacks or deals damage")
	_check(sim.get_unit(4).hp == sim.get_unit(4).max_hp, "reserve cannot be targeted by attacks")

	var dynamic: Simulation = Simulation.new()
	var roster: Array[Dictionary] = [
		{"id": 5, "key": "michael", "team": 0, "cell": Vector2i(3, 6), "active": true},
		{"id": 2, "key": "caramelo", "team": 0, "cell": Grid.INVALID, "active": false},
		{"id": 103, "key": "obama", "team": 1, "cell": Vector2i(3, 2), "active": true}
	]
	_check(dynamic.preparation_setup(roster) and dynamic.units.size() == 3, "dynamic roster does not assume every catalog character")
	_check(dynamic.get_unit(2).cell == Grid.INVALID and not dynamic.get_unit(2).active, "reserve accepts invalid board cell")
	var before: Dictionary = dynamic.snapshot()
	var malformed: Array[Dictionary] = [{"id": 1, "key": "neymar", "team": 0, "cell": "bad", "active": true}]
	_check(not dynamic.preparation_setup(malformed) and dynamic.snapshot() == before, "malformed cell is rejected without changing roster")
	var invalid: Array[Dictionary] = [roster[0], roster[0]]
	_check(not dynamic.preparation_setup(invalid) and dynamic.snapshot() == before, "roster validation is atomic for duplicate IDs")
	_check(dynamic.start_combat(), "dynamic roster with off-board reserve starts")
	dynamic.get_unit(103).alive = false
	dynamic.get_unit(103).hp = 0.0
	dynamic.step(0.05)
	_check(dynamic.round_result["survivors"] == [1, 0], "off-board reserve does not count as surviving troop")
	_check(dynamic.next_round() and dynamic.units.size() == 3 and not dynamic.get_unit(2).active, "new round preserves dynamic roster and active flags")
	_check(dynamic.get_unit(5).cell == Vector2i(3, 6), "new round restores dynamic preparation position")
	_check(dynamic.reset_round() and dynamic.team_lives == [4, 3], "reset_round preserves match lives")

func _test_runtime_equipment() -> void:
	var sim: Simulation = Simulation.new()
	var player: UnitState = sim.get_unit(1)
	var opponent: UnitState = sim.get_unit(101)
	var base_hp: float = player.spec.max_hp
	var base_attack: float = player.spec.attack_damage
	var modifiers: Dictionary = {"hp_mult": 1.2, "attack_mult": 1.5, "armor_mult": 2.0, "resist_mult": 3.0, "attack_speed_mult": 1.25, "crit_bonus": 0.2}
	_check(sim.apply_equipment(1, modifiers), "equipment applies supported runtime modifiers")
	_near(player.max_hp, base_hp * 1.2, "equipment increases runtime maximum HP")
	_near(player.attack_damage, base_attack * 1.5, "equipment increases runtime attack")
	_near(player.armor, player.spec.armor * 2.0, "equipment increases physical defense")
	_near(player.resist, player.spec.resist * 3.0, "equipment increases magical defense")
	_near(player.spec.max_hp, base_hp, "equipment never mutates shared specification")
	_near(opponent.max_hp, base_hp, "equipment never modifies opponent using same specification")
	sim.apply_equipment(1, modifiers)
	_near(player.max_hp, base_hp * 1.2, "reapplying same equipment is idempotent")
	_check(not sim.apply_equipment(1, {"hp_mult": NAN}), "nonfinite equipment modifier rejected")
	_check(not sim.apply_equipment(1, {"invented_field": 2.0}), "unknown equipment field rejected")
	sim.start_combat()
	_near(player.attack_speed_multiplier, 1.25 * 1.15, "equipment attack speed combines with Zumbi aura")
	_check(sim.apply_equipment(1, {"attack_mult": 1.8}), "equipment can be updated during combat for living units")
	player.alive = false
	_check(not sim.apply_equipment(1, {"attack_mult": 2.0}), "dead unit cannot be equipped during combat")
	player.alive = true
	for unit: UnitState in sim.units:
		if unit.team == 1:
			unit.alive = false
			unit.hp = 0.0
	sim.step(0.05)
	sim.next_round()
	_near(sim.get_unit(1).max_hp, base_hp, "new round clears runtime equipment until Session reapplies it")
	_check(sim.get_unit(1).damage_dealt == 0.0 and sim.get_unit(1).healing_done == 0.0 and sim.get_unit(1).kills == 0, "new round resets individual statistics")

func _test_functional_synergies() -> void:
	var sim: Simulation = Simulation.new()
	sim.synergy_enabled = true
	sim.set_active(5, true, Vector2i(3, 6))
	var preview: Array[Dictionary] = sim.preview_synergies(0)
	_near(sim.get_unit(1).attack_damage, sim.get_unit(1).spec.attack_damage, "synergy preview does not mutate combat attributes")
	_check(preview[0]["tier"] == 3 and preview[2]["tier"] == 2, "preparation preview reports selected formation tiers")
	sim.start_combat()
	_near(sim.get_unit(1).attack_damage, sim.get_unit(1).spec.attack_damage * 1.2, "three attackers use larger bonus only, not sum of tiers")
	_near(sim.get_unit(3).max_hp, sim.get_unit(3).spec.max_hp * 1.1, "two supports give temporary team HP test bonus")
	_near(sim.get_unit(1).attack_speed_multiplier, 1.3, "two ranged attackers add temporary member speed bonus")
	_near(sim.get_unit(2).attack_speed_multiplier, 1.15, "ranged synergy does not buff unrelated member")
	_check(str(sim.synergy_snapshot[0][0]["name"]).contains("TESTE"), "functional synergy metadata explicitly says test")
	sim.get_unit(4).alive = false
	sim.get_unit(4).hp = 0.0
	sim.step(0.05)
	_near(sim.get_unit(1).attack_damage, sim.get_unit(1).spec.attack_damage * 1.2, "formation synergy survives member death during round")
	_check(sim.synergy_snapshot[0][0]["tier"] == 3, "synergy tier remains frozen for round")

	var reserved: Simulation = Simulation.new()
	reserved.synergy_enabled = true
	reserved.set_active(4, false)
	reserved.set_active(5, true, Vector2i(3, 6))
	reserved.start_combat()
	_near(reserved.get_unit(1).attack_damage, reserved.get_unit(1).spec.attack_damage * 1.1, "reserve does not complete larger attacker tier")
	_near(reserved.get_unit(3).max_hp, reserved.get_unit(3).spec.max_hp, "reserve does not complete support synergy")

	var v_sim: Simulation = Simulation.new()
	v_sim.synergy_enabled = true
	var v_roster: Array[Dictionary] = [
		{"id": 1, "key": "obama", "team": 0, "cell": Vector2i(0, 4), "active": true},
		{"id": 2, "key": "barbie", "team": 0, "cell": Vector2i(1, 4), "active": true},
		{"id": 101, "key": "neymar", "team": 1, "cell": Vector2i(0, 3), "active": true}
	]
	v_sim.preparation_setup(v_roster)
	var v_preview: Array[Dictionary] = v_sim.preview_synergies(0)
	_check(v_preview[3]["tier"] == 2 and v_preview[3]["count"] == 2, "vanguard synergy activates tier 2 with 2 members")
	v_sim.start_combat()
	_near(v_sim.get_unit(1).armor, v_sim.get_unit(1).spec.armor + 25.0, "vanguard tier 2 grants +25 armor")
	_near(v_sim.get_unit(1).resist, v_sim.get_unit(1).spec.resist + 20.0, "vanguard tier 2 grants +20 resist")

func _test_match_levels() -> void:
	var sim: Simulation = Simulation.new()
	var neymar: UnitState = sim.get_unit(1)
	var base_hp: float = neymar.max_hp
	_check(sim.set_unit_level(1, 2) and neymar.level == 2 and is_equal_approx(neymar.max_hp, base_hp * 1.5), "set_unit_level applies the level multiplier")
	_check(not sim.set_unit_level(1, 4) and not sim.set_unit_level(1, 0) and neymar.level == 2, "levels outside 1..3 rejected")
	sim.start_combat()
	_check(not sim.set_unit_level(1, 3) and neymar.level == 2, "level cannot change during combat")
	sim.step(30.0)
	var summary: Array = sim.round_result.get("units_summary", []).filter(func(row: Dictionary) -> bool: return row["id"] == 1)
	_check(summary.size() == 1 and int(summary[0].get("level", 0)) == 2, "round summary reports match level for the result screen")
	var roster: Array[Dictionary] = [
		{"id": 5, "key": "michael", "team": 0, "cell": Vector2i(3, 6), "active": true, "level": 3},
		{"id": 103, "key": "obama", "team": 1, "cell": Vector2i(3, 2), "active": true}
	]
	var leveled: Simulation = Simulation.new()
	_check(leveled.preparation_setup(roster) and leveled.get_unit(5).level == 3 and leveled.get_unit(103).level == 1, "roster accepts optional level")
	var bad: Array[Dictionary] = [{"id": 5, "key": "michael", "team": 0, "cell": Vector2i(3, 6), "active": true, "level": 7}]
	_check(not leveled.preparation_setup(bad) and leveled.get_unit(5).level == 3, "invalid level rejected atomically")
	var healer: Simulation = _sandbox()
	var dancer: UnitState = _fixture_unit("michael", 5, 0, Vector2i(3, 5), {"attack_damage": 0.0, "heal_amount": 10.0, "heal_interval": 1.0, "dance_shield_amount": 100.0, "moonwalk_step_duration": 0.5, "moonwalk_pause_duration": 5.0})
	var hurt: UnitState = _fixture_unit("ally", 1, 0, Vector2i(0, 7))
	hurt.hp = 500.0
	var foe: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(7, 0))
	dancer.apply_level(3, healer.level_multiplier(3))
	healer.units = [dancer, hurt, foe]
	healer.start_combat()
	healer.step(1.55)
	_near(hurt.dance_shield, 225.0, "level 3 dance shield scales by 2.25")
	var mender: Simulation = _sandbox()
	var singer: UnitState = _fixture_unit("michael", 5, 0, Vector2i(3, 5), {"attack_damage": 0.0, "heal_amount": 10.0, "heal_interval": 1.0, "moonwalk_steps": 0})
	var near: UnitState = _fixture_unit("ally", 1, 0, Vector2i(3, 6))
	near.hp = 500.0
	singer.apply_level(3, mender.level_multiplier(3))
	mender.units = [singer, near, _fixture_unit("enemy", 101, 1, Vector2i(7, 0))]
	mender.start_combat()
	mender.step(1.0)
	_check(_events(mender, "heal").any(func(event: Dictionary) -> bool: return is_equal_approx(event["amount"], 22.5)), "level 3 heal pulse scales by 2.25")
	var biter: Simulation = _sandbox()
	var dog: UnitState = _fixture_unit("caramelo", 2, 0, Vector2i(3, 4), {"bleed_damage_per_tick": 10.0, "bleed_duration": 3.0, "bleed_tick_interval": 1.0})
	var prey: UnitState = _fixture_unit("target", 101, 1, Vector2i(3, 3))
	dog.apply_level(2, biter.level_multiplier(2))
	dog.attack_cooldown = 0.0
	biter.units = [dog, prey]
	biter.start_combat()
	biter.step(1.1) # mordida no 1º tique; sangramento a cada 1 s depois dela
	_check(_events(biter, "bleed").any(func(event: Dictionary) -> bool: return is_equal_approx(event["amount"], 15.0)), "level 2 bleed tick scales by 1.5")

## Kits do lote 03 (Barbie/Ken, Elon, Snoop, Lula, Bob Marley, Rapunzel). Números são fixtures.
func _kit_unit(key: String, unit_id: int, team: int, cell: Vector2i, changes: Dictionary = {}) -> UnitState:
	var base: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/debug_characters.json"))["characters"][key] as Dictionary).duplicate(true)
	base.merge(changes, true)
	var spec: UnitSpec = UnitSpec.new()
	spec.load_values(key, base)
	var unit: UnitState = UnitState.new(spec, unit_id, team, cell)
	unit.attack_cooldown = 1000.0
	unit.move_cooldown = 1000.0
	return unit

func _test_lote_03_kits() -> void:
	# Barbie invoca o Ken, que puxa o ataque de quem miraria a Barbie e dá +50% de dano a ela.
	var sim: Simulation = _sandbox()
	var barbie: UnitState = _kit_unit("barbie", 6, 0, Vector2i(3, 5), {"attack_damage": 100.0, "crit_chance": 0.0})
	var brute: UnitState = _fixture_unit("brute", 101, 1, Vector2i(3, 4), {"attack_damage": 50.0})
	barbie.attack_cooldown = 0.0
	brute.attack_cooldown = 0.0
	sim.units = [barbie, brute]
	sim.start_combat()
	var ken: UnitState = sim.get_unit(6 + Simulation.SUMMON_ID_OFFSET)
	_check(ken != null and ken.summoned and ken.team == 0 and ken.key == "ken" and Grid.distance(ken.cell, barbie.cell) == 1, "Barbie summons Ken on an adjacent free hex")
	_check(barbie.guardian_id == ken.id and _events(sim, "summon").size() == 1, "summon event and guardian link")
	sim.step(0.05)
	_check(brute.target_id == ken.id and ken.hp < ken.max_hp and barbie.hp == barbie.max_hp, "enemy that would hit Barbie hits Ken instead")
	_near(brute.damage_dealt, 50.0 * 100.0 / 130.0, "Ken takes the redirected hit (armor 30)")
	_near(_events(sim, "hit").filter(func(e: Dictionary) -> bool: return e["source_id"] == 6)[0]["amount"], 150.0, "Barbie deals +50% while Ken lives")
	ken.hp = 0.0
	ken.alive = false
	barbie.attack_cooldown = 0.0
	brute.hp = brute.max_hp
	sim.step(0.05)
	_check(brute.target_id == barbie.id, "with Ken dead the enemy targets Barbie again")
	_near(_events(sim, "hit").filter(func(e: Dictionary) -> bool: return e["source_id"] == 6).back()["amount"], 100.0, "bonus ends when Ken dies")
	var solo: Simulation = _sandbox()
	var lone: UnitState = _kit_unit("barbie", 6, 0, Vector2i(3, 5))
	var foe: UnitState = _fixture_unit("foe", 101, 1, Vector2i(7, 0))
	solo.units = [lone, foe]
	solo.start_combat()
	solo.get_unit(6).alive = false
	solo.get_unit(6).hp = 0.0
	solo.step(0.05)
	_check(solo.phase == "finished" and solo.round_result["survivors"] == [0, 1], "summons do not count as surviving troops")
	var leveled: Simulation = _sandbox()
	var star: UnitState = _kit_unit("barbie", 6, 0, Vector2i(3, 5))
	star.apply_level(3, leveled.level_multiplier(3))
	leveled.units = [star, _fixture_unit("foe", 101, 1, Vector2i(7, 0))]
	leveled.start_combat()
	_near(leveled.get_unit(86).max_hp, 2300.0, "Ken inherits Barbie's level with its own HP curve")

	# Elon: 3 ataques com minifoguete (alvo direto) + 4º Super Ataque com explosão penetrante (raio 1 + 2 quadros para trás).
	var rockets: Simulation = _sandbox()
	var elon: UnitState = _kit_unit("elon", 7, 0, Vector2i(3, 7), {"attack_damage": 100.0, "crit_chance": 0.0, "attacks_per_second": 0.05})
	var main: UnitState = _fixture_unit("main", 101, 1, Vector2i(3, 3))
	var near: UnitState = _fixture_unit("near", 102, 1, Vector2i(4, 3))
	var behind: UnitState = _fixture_unit("behind", 103, 1, Vector2i(3, 1))
	var far: UnitState = _fixture_unit("far", 104, 1, Vector2i(7, 0))
	elon.attack_cooldown = 0.0
	rockets.units = [elon, main, near, behind, far]
	rockets.start_combat()
	for shot: int in range(3):
		elon.attack_cooldown = 0.0
		rockets.step(0.05)
		_check(rockets.projectiles.size() == 1 and rockets.projectiles[0].kind == "mini_rocket", "Elon shot %d is a mini_rocket" % (shot + 1))
		rockets.step(0.8)
	_near(main.hp, 700.0, "3 mini-rockets deal full direct damage to main target (1000 - 300 = 700)")
	_near(near.hp, 1000.0, "mini-rockets deal zero splash damage to adjacent enemies")
	_near(behind.hp, 1000.0, "mini-rockets deal zero damage to backline enemies")
	elon.attack_cooldown = 0.0
	rockets.step(0.05)
	_check(rockets.projectiles.size() == 1 and rockets.projectiles[0].kind == "rocket" and rockets.projectiles[0].is_super, "Elon 4th attack is a SUPER rocket")
	rockets.step(0.8)
	_near(main.hp, 550.0, "super rocket deals 1.5x damage to main target (700 - 150 = 550)")
	_near(near.hp, 910.0, "super explosion deals 60% splash to adjacent neighbor (1000 - 90 = 910)")
	_near(behind.hp, 910.0, "super explosion penetrates 2 hexes behind target into backline (1000 - 90 = 910)")
	_near(far.hp, 1000.0, "super explosion does not reach distant enemies outside blast zone")
	_check(_events(rockets, "explosion").size() == 1, "one super explosion emitted on 4th shot")

	# Snoop: fumaça com dano contínuo, buff de velocidade a aliados e chance de errar para inimigos dentro.
	var smoke: Simulation = _sandbox()
	var snoop: UnitState = _kit_unit("snoop", 8, 0, Vector2i(3, 6), {"attack_damage": 20.0, "crit_chance": 0.0, "smoke_miss_chance": 0.9})
	var victim: UnitState = _fixture_unit("victim", 101, 1, Vector2i(3, 3), {"attack_damage": 10.0, "attacks_per_second": 10.0, "attack_range": 5})
	var ally_in_smoke: UnitState = _fixture_unit("ally_smoke", 2, 0, Vector2i(4, 3), {"attacks_per_second": 1.0})
	var outside: UnitState = _fixture_unit("outside", 102, 1, Vector2i(7, 0))
	snoop.attack_cooldown = 0.0
	smoke.units = [snoop, victim, ally_in_smoke, outside]
	smoke.start_combat()
	smoke.step(1.1) # impacto ~0,55 s; primeiro tique da nuvem 0,5 s depois
	_check(smoke.zones.size() == 1 and smoke.zones[0]["cell"] == Vector2i(3, 3) and int(smoke.zones[0]["radius"]) == 2, "smoke hit leaves a cloud of radius 2 on the target hex")
	_check(_events(smoke, "smoke").size() >= 1, "cloud deals continuous magic damage")
	_near(smoke._attack_speed(ally_in_smoke), 1.25, "ally inside friendly smoke cloud attacks 25% faster")
	_check(outside.hp == outside.max_hp, "cloud does not hurt enemies outside its radius")
	victim.attack_cooldown = 0.0
	smoke.step(1.0)
	_check(_events(smoke, "miss").size() >= 1, "enemies inside the cloud can miss")
	_check(smoke.zones.size() <= 1, "one cloud per Snoop, never stacking")
	smoke.step(5.0)
	_check(smoke.zones.size() <= 1, "clouds expire or are replaced")

	# Lula: volta por cima uma vez por rodada com 40% da vida.
	var comeback: Simulation = _sandbox()
	var lula: UnitState = _kit_unit("lula", 9, 0, Vector2i(3, 4))
	var killer: UnitState = _fixture_unit("killer", 101, 1, Vector2i(3, 3))
	comeback.units = [lula, killer]
	comeback.start_combat()
	comeback._deal_damage(101, lula, 100000.0, false, "hit")
	_check(lula.alive and lula.revived and is_equal_approx(lula.hp, lula.max_hp * 0.4), "first lethal hit: Lula rises with 40% HP")
	_check(_events(comeback, "revive").size() == 1 and _events(comeback, "death").is_empty(), "revive event, no death")
	comeback._deal_damage(101, lula, 100000.0, false, "hit")
	_check(not lula.alive and _events(comeback, "death").size() == 1, "second lethal hit in the same round kills")

	# Bob Marley: aliados no raio atacam mais rápido, inimigos mais devagar; raio cresce por nível.
	var music: Simulation = _sandbox()
	var bob: UnitState = _kit_unit("bob_marley", 10, 0, Vector2i(3, 5))
	var friend: UnitState = _fixture_unit("friend", 1, 0, Vector2i(3, 6), {"attacks_per_second": 1.0})
	var enemy_near: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(3, 4), {"attacks_per_second": 1.0})
	var enemy_far: UnitState = _fixture_unit("far", 102, 1, Vector2i(3, 0), {"attacks_per_second": 1.0}) # 5 hexágonos: fora de N1, dentro de N3
	music.units = [bob, friend, enemy_near, enemy_far]
	_near(music._attack_speed(friend), 1.3, "ally in the song radius attacks 30% faster")
	_near(music._attack_speed(enemy_near), 0.7, "enemy in the song radius attacks 30% slower")
	_near(music._attack_speed(enemy_far), 1.0, "enemy outside the level-1 radius is unaffected")
	bob.apply_level(3, music.level_multiplier(3))
	_near(music._attack_speed(enemy_far), 0.7, "level 3 song reaches a target outside the level-1 radius")

	# Rapunzel: laça o inimigo mais distante, puxa para perto e atordoa ~1 s.
	var rope: Simulation = _sandbox()
	var rapunzel: UnitState = _kit_unit("rapunzel", 11, 0, Vector2i(3, 6))
	var close: UnitState = _fixture_unit("close", 101, 1, Vector2i(3, 3))
	var carry: UnitState = _fixture_unit("carry", 102, 1, Vector2i(6, 0), {"attack_damage": 1.0, "attacks_per_second": 5.0, "attack_range": 14})
	carry.attack_cooldown = 0.0
	rope.units = [rapunzel, close, carry]
	rope.start_combat()
	rope.step(2.45)
	_check(_events(rope, "lasso").is_empty(), "time alone does not charge mana or cast the lasso")
	rapunzel.mana = rapunzel.spec.max_mana # Fixture de alvo/atordoamento; carga por ataques coberta no runner balance02.
	rope.step(0.05)
	var lasso: Array[Dictionary] = _events(rope, "lasso")
	_check(lasso.size() == 1 and lasso[0]["target_id"] == 102, "lasso picks the farthest enemy")
	_check(Grid.distance(carry.cell, rapunzel.cell) == 1 and carry.stun_remaining > 0.9, "target pulled next to Rapunzel and stunned")
	var attacks_before: int = carry.attack_count
	rope.step(0.9)
	_check(carry.attack_count == attacks_before, "stunned unit does not attack")
	rope.step(0.3)
	_check(carry.attack_count > attacks_before, "unit acts again after the stun")
	rope.step(6.5)
	_check(_events(rope, "lasso").size() == 1, "lasso does not repeat on the old timer without mana")
	rapunzel.mana = rapunzel.spec.max_mana
	rope.step(0.05)
	_check(_events(rope, "lasso").size() == 2, "a second full mana charge permits another lasso")

func _test_assassin_opening() -> void:
	var sim: Simulation = _sandbox()
	var dog: UnitState = _fixture_unit("caramelo", 2, 0, Vector2i(3, 4), {"assassin_opening_duration": 5.0, "move_interval": 0.1})
	var front: UnitState = _fixture_unit("front", 101, 1, Vector2i(3, 3))
	var carry: UnitState = _fixture_unit("carry", 102, 1, Vector2i(5, 1), {"attack_range": 3, "attack_damage": 50.0})
	var reserve: UnitState = _fixture_unit("reserve", 103, 1, Grid.INVALID, {"attack_range": 3, "attack_damage": 500.0})
	reserve.active = false
	sim.units = [dog, front, carry, reserve]
	dog.attack_cooldown = 0.0
	dog.move_cooldown = 0.0
	sim.start_combat()
	_check(dog.assassin_target_id == 102 and _events(sim, "assassin_hunt").size() == 1, "opening hunts active ranged carry instead of closer tank or reserve")
	var origin: Vector2i = dog.cell
	sim.step(0.05)
	_check(dog.target_id == 102 and Grid.distance(origin, dog.cell) == 1, "assassin pursues through one adjacent hex, without teleport")
	var occupied_valid: bool = true
	for tick_index: int in range(40):
		sim.step(0.05)
		var seen: Dictionary = {}
		for unit: UnitState in sim.units:
			if unit.active and unit.alive:
				occupied_valid = occupied_valid and not seen.has(unit.cell)
				seen[unit.cell] = true
	_check(occupied_valid, "opening path keeps exclusive occupied cells")
	var ended: Array[Dictionary] = _events(sim, "assassin_hunt_ended")
	_check(dog.assassin_opening_finished and ended.size() == 1 and ended[0]["reason"] == "first_bite", "first successful bite ends initial hunt once")
	for movement: Dictionary in _events(sim, "move"):
		if int(movement["source_id"]) == dog.id:
			_check(Grid.distance(movement["from"], movement["to"]) == 1, "every assassin path step is adjacent")
	_check(_events(sim, "assassin_hunt").size() == 1, "assassin cannot start a second hunt in the same round")
	_check(dog.as_dictionary()["assassin_opening_finished"] and dog.as_dictionary()["assassin_target_id"] == -1, "snapshot clears finished hunt target")

	var blocked: Simulation = _sandbox()
	var trapped: UnitState = _fixture_unit("caramelo", 2, 0, Vector2i(3, 4), {"assassin_opening_duration": 0.25, "move_interval": 0.1})
	var distant: UnitState = _fixture_unit("carry", 101, 1, Vector2i(6, 0), {"attack_range": 4})
	blocked.units = [trapped, distant]
	var next_id: int = 10
	for cell: Vector2i in Grid.neighbors(trapped.cell):
		blocked.units.append(_fixture_unit("blocker", next_id, 0, cell))
		next_id += 1
	trapped.move_cooldown = 0.0
	blocked.start_combat()
	blocked.step(0.25)
	_check(trapped.cell == Vector2i(3, 4) and trapped.assassin_opening_finished, "blocked hunt times out without inventing a move")
	_check(_events(blocked, "assassin_hunt_ended")[0]["reason"] == "timeout", "bounded opening reports timeout explicitly")

	var cancelled: Simulation = _sandbox()
	var hunter: UnitState = _fixture_unit("caramelo", 2, 0, Vector2i(3, 4), {"assassin_opening_duration": 5.0})
	var first_carry: UnitState = _fixture_unit("carry", 101, 1, Vector2i(5, 1), {"attack_range": 3, "attack_damage": 50.0})
	var replacement: UnitState = _fixture_unit("carry", 102, 1, Vector2i(0, 0), {"attack_range": 3, "attack_damage": 40.0})
	cancelled.units = [hunter, first_carry, replacement]
	cancelled.start_combat()
	first_carry.alive = false
	first_carry.hp = 0.0
	cancelled.step(0.05)
	_check(hunter.assassin_opening_finished and _events(cancelled, "assassin_hunt_ended")[0]["reason"] == "target_dead", "dead prey cancels locked opening")
	_check(_events(cancelled, "assassin_hunt").size() == 1 and hunter.assassin_target_id == -1, "cancelled hunt never reselects another carry")

	var reset_sim: Simulation = Simulation.new()
	reset_sim.round_duration = 0.1
	reset_sim.start_combat()
	reset_sim.step(0.1)
	_check(reset_sim.next_round() and not reset_sim.get_unit(2).assassin_opening_finished and reset_sim.get_unit(2).assassin_target_id == -1, "next round renews opening opportunity without keeping last prey")

func _test_briefcase_refresh() -> void:
	var sim: Simulation = _sandbox()
	var tank: UnitState = _fixture_unit("obama", 3, 0, Vector2i(2, 6), {"initial_shield": 230.0, "briefcase_guard_amount": 120.0, "briefcase_guard_interval": 5.0})
	var ally: UnitState = _fixture_unit("ally", 2, 0, Vector2i(1, 7))
	var enemy: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(6, 0))
	var reserve: UnitState = _fixture_unit("obama", 4, 0, Grid.INVALID, {"briefcase_guard_amount": 120.0, "briefcase_guard_interval": 5.0})
	reserve.active = false
	var dead: UnitState = _fixture_unit("obama", 5, 0, Vector2i(3, 7), {"briefcase_guard_amount": 120.0, "briefcase_guard_interval": 5.0})
	dead.alive = false
	dead.hp = 0.0
	sim.units = [tank, ally, enemy, reserve, dead]
	tank.shield = 0.0
	tank.hp = 700.0
	tank.dance_shield = 20.0
	tank.dance_shield_remaining = 30.0
	sim.start_combat()
	sim.step(4.95)
	_near(tank.shield, 0.0, "briefcase does not refresh before its five-second interval")
	sim.step(0.05)
	_near(tank.shield, 120.0, "briefcase restores its own depleted shield to configured floor")
	_near(tank.hp, 700.0, "briefcase refresh never heals HP")
	_near(tank.dance_shield, 20.0, "briefcase leaves independent dance shield unchanged")
	_near(ally.shield, 0.0, "briefcase never shields another ally")
	_near(reserve.shield, 0.0, "reserved Obama cannot refresh its shield")
	_near(dead.shield, 0.0, "dead Obama cannot refresh its shield")
	var first: Array[Dictionary] = _events(sim, "briefcase_guard")
	_check(first.size() == 1 and first[0]["source_id"] == 3 and first[0]["amount"] == 120.0 and first[0]["added"] == 120.0, "guard event exposes actual own shield gain")
	sim.step(5.0)
	_near(tank.shield, 120.0, "successive guards refresh without additive infinite stacking")
	_check(_events(sim, "briefcase_guard")[1]["added"] == 0.0, "full guard reports no fake added shield")
	tank.shield = 230.0
	sim.step(5.0)
	_near(tank.shield, 230.0, "guard never reduces larger remaining initial shield")
	_check(_events(sim, "briefcase_guard").size() == 3, "briefcase interval uses normal time through acceleration")
	tank.shield = 0.0
	tank.stun_remaining = 1.0
	tank.briefcase_cooldown = 0.05
	sim.step(0.5)
	_near(tank.shield, 0.0, "stun pauses briefcase activation")
	sim.step(0.5)
	_near(tank.shield, 120.0, "briefcase resumes after stun without stored extra guards")
	_near(float(tank.as_dictionary()["briefcase_cooldown"]), 5.0, "snapshot exposes next briefcase interval")

	var scaled: Simulation = _sandbox()
	var upgraded: UnitState = _fixture_unit("obama", 3, 0, Vector2i(2, 6), {"briefcase_guard_amount": 120.0, "briefcase_guard_interval": 0.1})
	upgraded.apply_level(3, 2.25)
	scaled.units = [upgraded, _fixture_unit("enemy", 101, 1, Vector2i(6, 0))]
	scaled.start_combat()
	scaled.step(0.1)
	_near(upgraded.shield, 270.0, "test kit scaling also applies to replenished briefcase shield")

func _test_kick_observation() -> void:
	for speed: float in [1.0, 2.0]:
		var sim: Simulation = _sandbox()
		var shooter: UnitState = _fixture_unit("neymar", 1, 0, Vector2i(3, 4), {"attack_range": 3, "attacks_per_second": speed})
		var a: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(3, 2))
		var b: UnitState = _fixture_unit("enemy", 102, 1, Vector2i(4, 2))
		sim.units = [shooter, a, b]
		shooter.attack_cooldown = 0.0
		sim.start_combat()
		sim.step(1.9)
		var kicks: Array[Dictionary] = _events(sim, "kick")
		_check(kicks.size() == int(speed * 2.0) and kicks.size() == shooter.attack_count, "one kick event per actual attack at APS %s" % speed)
		_check(kicks[0]["flight_duration"] == 0.24 and not kicks[0]["critical"], "kick records initial flight time and rolled critical")
		for expired: Dictionary in _events(sim, "ball_expired"):
			_check(expired["reason"] == "max_impacts" and expired["impacts"] == 3, "intact pair ends explicitly at three impacts")

	var alone: Simulation = _sandbox()
	var kicker: UnitState = _fixture_unit("neymar", 1, 0, Vector2i(3, 4), {"attack_range": 3})
	var target: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(3, 2))
	alone.units = [kicker, target]
	kicker.attack_cooldown = 0.0
	alone.start_combat()
	alone.step(0.5)
	var no_pair: Array[Dictionary] = _events(alone, "ball_expired")
	_check(no_pair.size() == 1 and no_pair[0]["reason"] == "no_pair" and no_pair[0]["impacts"] == 1, "single target reports one-impact no-pair finish")

	var cancelled: Simulation = _sandbox()
	var source: UnitState = _fixture_unit("neymar", 1, 0, Vector2i(3, 4), {"attack_range": 3})
	var doomed: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(3, 2))
	var neighbor: UnitState = _fixture_unit("enemy", 102, 1, Vector2i(4, 2))
	cancelled.units = [source, doomed, neighbor]
	source.attack_cooldown = 0.0
	cancelled.start_combat()
	cancelled.step(0.05)
	doomed.alive = false
	doomed.hp = 0.0
	cancelled.step(0.25)
	var ended: Array[Dictionary] = _events(cancelled, "ball_expired")
	_check(ended.size() == 1 and ended[0]["reason"] == "target_dead" and ended[0]["impacts"] == 0, "dead target in flight cancels with explicit zero-impact report")
	_check(_events(cancelled, "ball_impact").is_empty() and source.attack_count == 1, "cancelled projectile never creates hit or replacement attack")

func _test_revive_clears_bleeds() -> void:
	var sim: Simulation = _sandbox()
	var tank: UnitState = _fixture_unit("lula", 9, 0, Vector2i(1, 7), {"max_hp": 1000.0, "revive_ratio": 0.4})
	var ally: UnitState = _fixture_unit("ally", 2, 0, Vector2i(2, 7))
	var enemy: UnitState = _fixture_unit("enemy", 101, 1, Vector2i(7, 0))
	tank.hp = 5.0
	# The first bleed is kept locally before the second bleed triggers revival.
	for source_id: int in [101, 102]:
		tank.bleeds.append({"source_id": source_id, "damage": 4.0, "remaining": 3.0, "until_tick": 0.05, "interval": 1.0})
	ally.bleeds.append({"source_id": 101, "damage": 2.0, "remaining": 1.0, "until_tick": 0.05, "interval": 1.0})
	sim.units = [tank, ally, enemy]
	sim.start_combat()
	sim.step(0.05)
	_check(tank.alive and tank.revived and tank.bleeds.is_empty(), "revival during bleed ticking clears current and previously retained bleeds")
	_near(tank.hp, 400.0, "bleed lethal hit revives at configured HP ratio")
	_near(ally.hp, 998.0, "revival does not abort bleed ticks for later units")
	sim.step(1.0)
	_near(tank.hp, 400.0, "cleansed bleeds cannot damage the revived tank next second")
	_check(_events(sim, "revive").size() == 1 and _events(sim, "death").is_empty(), "bleed revival emits once without spurious death")
	sim._deal_damage(101, tank, 100000.0, false, "hit")
	_check(not tank.alive and _events(sim, "revive").size() == 1 and _events(sim, "death").size() == 1, "bleed-triggered revival cannot occur twice in one round")

func _test_summon_unique_ids() -> void:
	var sim: Simulation = Simulation.new()
	var roster: Array[Dictionary] = [
		{"id": 6, "key": "barbie", "team": 0, "cell": Vector2i(3, 5), "active": true},
		{"id": 86, "key": "neymar", "team": 0, "cell": Vector2i(0, 7), "active": true},
		{"id": 87, "key": "obama", "team": 0, "cell": Vector2i(1, 7), "active": true},
		{"id": 101, "key": "neymar", "team": 1, "cell": Vector2i(7, 0), "active": true}
	]
	_check(sim.preparation_setup(roster) and sim.start_combat(), "custom roster with occupied preferred summon IDs is valid")
	var guardian: UnitState = sim.get_unit(sim.get_unit(6).guardian_id)
	_check(guardian != null and guardian.summoned and guardian.key == "ken", "guardian link resolves Ken instead of preexisting hero")
	var ids: Dictionary = {}
	var unique: bool = true
	for unit: UnitState in sim.units:
		unique = unique and not ids.has(unit.id)
		ids[unit.id] = true
	_check(unique and sim.units.size() == 5, "summon allocation never duplicates any existing runtime ID")
	_check(sim.get_unit(86).key == "neymar" and sim.get_unit(87).key == "obama", "summoning preserves preexisting ID lookups")
	sim.round_duration = 0.05
	sim.step(0.05)
	_check(sim.round_result["survivors"] == [3, 1], "unique-ID summon remains excluded from survivor tiebreak")
	_check(sim.next_round() and sim.units.size() == 4 and sim.get_unit(6).guardian_id == -1, "new round discards old summon and guardian link")
	_check(sim.start_combat() and sim.get_unit(sim.get_unit(6).guardian_id).key == "ken", "next round allocates a fresh valid guardian link")
