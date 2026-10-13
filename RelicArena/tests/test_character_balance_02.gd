extends SceneTree
## Regras novas de combate, em fixtures descartáveis. Não demonstra balanceamento.
const Core = preload("res://simulation/arena_simulation.gd")
const State = preload("res://simulation/unit_state.gd")
const Catalog = preload("res://data/character_catalog.gd")
const Grid = preload("res://simulation/hex_grid.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_test_health_and_summon()
	_test_global_healing()
	_test_lula_returns()
	_test_mana_lasso()
	_test_round_reset()
	_test_boss_area()
	print("CHARACTER BALANCE02 TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)

func _near(actual: float, expected: float, label: String) -> void:
	_check(is_equal_approx(actual, expected), "%s (%s / %s)" % [label, actual, expected])

func _unit(sim: Core, key: String, id: int, team: int, cell: Vector2i) -> State:
	var spec = sim.specs.get(key, sim.summon_specs.get(key))
	var result: State = State.new(spec, id, team, cell)
	result.attack_cooldown = 1000.0
	result.move_cooldown = 1000.0
	return result

func _events(sim: Core, kind: String) -> Array:
	return sim.events.filter(func(event: Dictionary) -> bool: return event["type"] == kind)

func _test_health_and_summon() -> void:
	for level: int in [1, 2, 3]:
		var sim: Core = Core.new()
		_check(sim.preparation_setup([
			{"id": 6, "key": "barbie", "team": 0, "cell": Vector2i(3, 5), "active": true, "level": level},
			{"id": 101, "key": "obama", "team": 1, "cell": Vector2i(6, 1), "active": true}
		]), "level fixture accepted")
		var barbie: State = sim.get_unit(6)
		_near(barbie.max_hp, [600.0, 900.0, 1200.0][level - 1], "Barbie own HP curve")
		sim.start_combat()
		var ken: State = sim.get_unit(86)
		_check(ken != null and ken.summoned and ken.level == level, "Ken inherits summoner level without occupying roster")
		if ken != null:
			_near(ken.max_hp, [1200.0, 1600.0, 2300.0][level - 1], "Ken own HP curve")
			_check(ken.max_hp > barbie.max_hp, "Ken is healthier than Barbie at every level")
	var equipped: Core = Core.new()
	var doll: State = _unit(equipped, "barbie", 6, 0, Vector2i(3, 5))
	doll.apply_level(3, equipped.level_multiplier(3))
	doll.hp *= 0.5
	doll.equipment_modifiers = {"hp_mult": 1.2}
	doll.recalculate_combat_stats()
	_near(doll.max_hp, 1440.0, "equipment applies after custom base HP curve")
	_near(doll.hp, 720.0, "recalculation preserves current health fraction")
	var regular: State = _unit(equipped, "obama", 3, 0, Vector2i(2, 5))
	regular.apply_level(3, equipped.level_multiplier(3))
	_near(regular.max_hp, regular.spec.max_hp * 2.25, "other heroes retain their global HP scaling")

func _test_global_healing() -> void:
	var sim: Core = Core.new()
	var michael: State = _unit(sim, "michael", 5, 0, Vector2i(0, 7))
	var distant: State = _unit(sim, "obama", 3, 0, Vector2i(7, 0))
	var reserve: State = _unit(sim, "lula", 9, 0, Grid.INVALID)
	var corpse: State = _unit(sim, "zumbi", 4, 0, Vector2i(1, 7))
	var enemy: State = _unit(sim, "obama", 101, 1, Vector2i(7, 1))
	reserve.active = false
	reserve.hp = 10.0
	corpse.alive = false
	corpse.hp = 0.0
	enemy.hp = 10.0
	distant.hp = distant.max_hp - 3.0
	sim.units = [michael, distant, reserve, corpse, enemy]
	michael.support_cooldown = 0.0
	sim._update_support_skills(0.05)
	_check(Grid.distance(michael.cell, distant.cell) > michael.spec.heal_range, "healing fixture lies outside old radius")
	_near(distant.hp, distant.max_hp, "global heal reaches far ally and caps at missing HP")
	_near(michael.healing_done, 3.0, "healing statistics exclude excess")
	_near(reserve.hp, 10.0, "reserve excluded")
	_near(enemy.hp, 10.0, "enemy excluded")
	_check(not corpse.alive and corpse.hp == 0.0, "healing cannot revive")
	michael.alive = false
	distant.hp -= 10.0
	michael.support_cooldown = 0.0
	sim._update_support_skills(1.0)
	_near(distant.hp, distant.max_hp - 10.0, "dead Michael cannot maintain healing")

func _test_lula_returns() -> void:
	for level: int in [1, 2, 3]:
		var sim: Core = Core.new()
		var lula: State = _unit(sim, "lula", 9, 0, Vector2i(3, 5))
		lula.apply_level(level, sim.level_multiplier(level))
		sim.units = [lula, _unit(sim, "neymar", 101, 1, Vector2i(3, 2))]
		sim.start_combat()
		sim._deal_damage(101, lula, 100000.0, false, "execute", true)
		_check(lula.is_reviving and lula.revive_delay_remaining > 0.0, "first lethal hit starts 1.0s descent delay")
		sim.step(1.0)
		_check(lula.alive and lula.revive_count == 1, "first lethal hit revives at every level after 1.0s")
		_near(lula.hp, lula.max_hp * 0.4, "first return40percent")
		_check(lula.has_angel_wings, "Lula acquires angel wings")
		_check(lula.divine_frenzy_timer > 0.0, "divine frenzy 100% crit active")
		_check(lula.group_attack_buff_timer > 0.0, "group attack buff +25% active")
		if level == 3:
			lula.hp = 5.0
			lula.bleeds = [
				{"source_id": 101, "damage": 1.0, "remaining": 3.0, "until_tick": 1.0, "interval": 1.0},
				{"source_id": 101, "damage": 1000.0, "remaining": 3.0, "until_tick": 0.0, "interval": 1.0}
			]
			sim._update_bleeds(0.05)
			_check(lula.is_reviving and lula.bleeds.is_empty(), "second return also clears bleeds")
			sim.step(1.0)
			_check(lula.alive and lula.revive_count == 2, "second N3 return revives after 1.0s")
			_near(lula.hp, lula.max_hp * 0.3, "second N3 return30percent")
		sim._deal_damage(101, lula, 100000.0, false, "execute", true)
		_check(not lula.alive, "revivals are finite: next lethal hit kills")
		_check(_events(sim, "death").size() == 1, "one actual death after permitted returns")

func _test_mana_lasso() -> void:
	var sim: Core = Core.new()
	var rapunzel: State = _unit(sim, "rapunzel", 11, 0, Vector2i(3, 6))
	var close: State = _unit(sim, "obama", 101, 1, Vector2i(3, 5))
	var far: State = _unit(sim, "obama", 102, 1, Vector2i(7, 0))
	close.hp = 200.0 # Lowest HP is intentionally the close target.
	sim.units = [rapunzel, close, far]
	sim.start_combat()
	sim.step(3.0)
	_near(rapunzel.mana, 0.0, "waiting/walking/receiving damage cannot charge mana")
	_check(_events(sim, "lasso").is_empty(), "old delay does not cast")
	for hit: int in range(4):
		rapunzel.attack_cooldown = 0.0
		sim.step(0.05)
		_near(rapunzel.mana, 25.0 * (hit + 1), "each launched attack grants mana")
		_check(_events(sim, "lasso").is_empty(), "partial mana never casts; full cast follows on next step")
	rapunzel.stun_remaining = 1.0
	sim.step(0.05)
	_near(rapunzel.mana, 100.0, "stun retains a full charge")
	_check(_events(sim, "lasso").is_empty(), "stun prevents ultimate")
	rapunzel.stun_remaining = 0.0
	sim.step(0.05)
	_near(rapunzel.mana, 0.0, "ultimate consumes charge")
	var casts: Array = _events(sim, "lasso")
	_check(casts.size() == 1 and casts[0]["target_id"] == 102, "mana ultimate picks farthest, not lowest HP")
	_check(Grid.distance(rapunzel.cell, far.cell) == 1 and far.stun_remaining > 0.0, "ultimate pulls and stuns")
	var snap: Dictionary = rapunzel.as_dictionary()
	_check(snap["mana"] == 0.0 and snap["max_mana"] == 100.0, "UI receives authoritative mana")
	rapunzel.mana = 100.0
	close.active = false
	far.active = false
	sim._update_lassos(0.05)
	_near(rapunzel.mana, 100.0, "no valid target does not waste charge")

func _test_round_reset() -> void:
	var sim: Core = Core.new()
	_check(sim.preparation_setup([
		{"id": 9, "key": "lula", "team": 0, "cell": Vector2i(4, 4), "active": true, "level": 3},
		{"id": 11, "key": "rapunzel", "team": 0, "cell": Vector2i(3, 4), "active": true},
		{"id": 101, "key": "obama", "team": 1, "cell": Vector2i(3, 3), "active": true}
	]), "reset fixture uses real roster")
	for unit: State in sim.units:
		unit.attack_cooldown = 1000.0
		unit.move_cooldown = 1000.0
	sim.start_combat()
	var lula: State = sim.get_unit(9)
	sim.get_unit(11).attack_cooldown = 0.0
	sim.step(0.05)
	sim._deal_damage(101, lula, 100000.0, false, "execute", true)
	sim.step(1.0)
	sim._deal_damage(101, lula, 100000.0, false, "execute", true)
	sim.step(1.0)
	_check(sim.get_unit(11).mana > 0.0 and lula.revive_count == 2, "combat changes mana and consumes both returns")
	sim._deal_damage(11, sim.get_unit(101), 100000.0, false, "execute", true)
	sim.step(0.05)
	_check(sim.phase == "finished" and sim.next_round(), "normal round ends and next_round succeeds")
	_check(sim.get_unit(11).mana == 0.0 and sim.get_unit(9).revive_count == 0 and not sim.get_unit(9).revived,
		"next_round clears mana and both revival markers")

func _test_boss_area() -> void:
	var sim: Core = Core.new()
	var boss: State = _unit(sim, "boss_dev", 999, 1, Vector2i(4, 1))
	var a: State = _unit(sim, "obama", 3, 0, Vector2i(3, 5))
	var b: State = _unit(sim, "lula", 9, 0, Vector2i(4, 5))
	sim.units = [boss, a, b]
	_near(boss.max_hp, 10000.0, "Boss challenge HP (+2k)")
	boss.boss_tornado_timer = 0.0
	boss.boss_purple_fire_timer = 0.0
	sim.elapsed = 16.0
	sim._update_boss_spells(0.05)
	var summoned: Array = sim.units.filter(func(u: State) -> bool: return u.summoned)
	_check(summoned.size() == 2, "both timed minions are spawned")
	for minion: State in summoned:
		_near(minion.max_hp, 4000.0 if minion.key == "slime_lodo_olho" else 5000.0, "minion challenge HP (+2k)")
	_check(_events(sim, "fire_tornado_hit").size() == 2, "tornado damages multiple nearby troops")
	_check(a.cell != Vector2i(3, 5) or b.cell != Vector2i(4, 5), "tornado disrupts formation")
	var occupied: Dictionary = {}
	for unit: State in sim.units:
		_check(Grid.contains(unit.cell) and not occupied.has(unit.cell), "spell/summons preserve valid distinct occupied hexes")
		occupied[unit.cell] = true
