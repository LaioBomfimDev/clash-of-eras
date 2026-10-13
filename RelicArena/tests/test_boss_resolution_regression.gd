extends SceneTree
## BUG-023: PvE resolution, protected hearts and exactly-once loot.
## Disposable fixtures use real Session/core; no presentation or balance claims.

const Session = preload("res://simulation/match_session.gd")
const Core = preload("res://simulation/arena_simulation.gd")
const UnitState = preload("res://simulation/unit_state.gd")

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	_test_live_boss_timeout(false)
	_test_live_boss_timeout(true)
	_test_player_eliminated()
	_test_boss_defeated_once()
	_test_life_reward_is_legitimate()
	_test_missing_boss_and_reward_guard()
	_test_normal_rounds()
	print("BOSS RESOLUTION REGRESSION: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)


func _boss_session(hero_count: int = 2) -> Session:
	var session: Session = Session.new(20261013)
	session.bot_enabled = false
	session.reset(20261013)
	var recruited: int = 0
	for offer: Dictionary in (session.teams[0]["shop"] as Array).duplicate(true):
		if offer["kind"] != "hero":
			continue
		var reply: Dictionary = session.apply_command(0, "boss_recruit_%d" % recruited,
			"recruit", {"offer_id": offer["offer_id"]})
		if bool(reply.get("ok", false)):
			recruited += 1
		if recruited == hero_count:
			break
	# Jump only this disposable fixture to the round-four preparation boundary.
	session.sim.round_index = 4
	session.sim.reset_round()
	session._open_preparation()
	session.apply_command(0, "boss_ready", "ready")
	_check(recruited == hero_count and session.phase == "combat"
		and session.sim.is_boss_round and session.sim.get_unit(999) != null,
		"fixture starts real round-four Boss combat")
	session.drain_events(0)
	return session


func _timeout(session: Session) -> void:
	session.sim.tick = 599
	session.sim.elapsed = 29.95
	session.step(0.05)


func _rewards(session: Session) -> Array:
	return (session.teams[0] as Dictionary).get("boss_rewards", [])


func _event_count(events: Array[Dictionary], kind: String) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if event.get("type", "") == kind:
			count += 1
	return count


func _test_live_boss_timeout(damage_advantage: bool) -> void:
	var session: Session = _boss_session(1 if damage_advantage else 2)
	var boss = session.sim.get_unit(999)
	var lives: Array = session.sim.team_lives.duplicate()
	var gold: int = int(session.teams[0]["gold"])
	if damage_advantage:
		session.sim.team_damage = [1000.0, 0.0]
	_timeout(session)
	var label: String = "damage advantage" if damage_advantage else "survivor advantage"
	_check(boss.alive and boss.hp > 0.0 and is_equal_approx(session.sim.elapsed, 30.0),
		"Boss remains alive at timeout with " + label)
	_check(int(session.sim.round_result.get("winner", -1)) != 0,
		"live Boss cannot lose on normal " + label)
	_check(_rewards(session).is_empty() and int(session.teams[0]["gold"]) == gold,
		"live Boss timeout grants no loot with " + label)
	_check(session.sim.team_lives == lives,
		"Boss timeout changes neither side's hearts with " + label)
	_check(session.phase == "round_result" and session.sim.match_winner == -1,
		"Boss timeout ends only the PvE round with " + label)


func _test_player_eliminated() -> void:
	var session: Session = _boss_session()
	session.sim.team_lives = [1, 1]
	for unit in session.sim.units:
		if unit.team == 0 and unit.active:
			unit.hp = 0.0
			unit.alive = false
	session.step(0.05)
	_check(int(session.sim.round_result.get("winner", -1)) != 0,
		"player elimination does not defeat live Boss")
	_check(session.sim.team_lives == [1, 1], "PvE elimination protects both final hearts")
	_check(session.phase == "round_result" and session.sim.match_winner == -1,
		"PvE elimination cannot end the overall match")
	_check(_rewards(session).is_empty(), "PvE elimination grants no loot")


func _test_boss_defeated_once() -> void:
	var session: Session = _boss_session()
	# At the life cap no life drop can obscure an erroneous heart deduction.
	session.sim.team_lives = [Session.MAX_LIVES, 1]
	var boss = session.sim.get_unit(999)
	var minion: UnitState = UnitState.new(session.sim.summon_specs["slime_lodo_olho"],
		1089, 1, Vector2i(3, 1))
	minion.summoned = true
	minion.active = true
	session.sim.units.append(minion)
	boss.hp = 0.0
	boss.alive = false
	session.step(0.05)
	var first_rewards: Array = _rewards(session).duplicate(true)
	var first_gold: int = int(session.teams[0]["gold"])
	var first_bag: Array = (session.teams[0]["bag"] as Array).duplicate(true)
	var first_lives: Array = session.sim.team_lives.duplicate()
	_check(minion.alive and int(session.sim.round_result.get("winner", -1)) == 0,
		"Boss death before deadline wins even with a living summoned minion")
	_check(first_rewards.size() == 3, "Boss death grants three drops")
	_check(first_lives == [Session.MAX_LIVES, 1], "PvE victory changes neither side's hearts")
	_check(session.phase == "round_result" and session.sim.match_winner == -1,
		"PvE victory cannot consume the opponent's final heart or end match")
	_check(_event_count(session.drain_events(0), "boss_rewards_awarded") == 1,
		"Boss victory announces one reward grant")
	session.step(5.0)
	session.step(5.0)
	_check(_rewards(session) == first_rewards and int(session.teams[0]["gold"]) == first_gold
		and session.teams[0]["bag"] == first_bag and session.sim.team_lives == first_lives,
		"later result ticks do not duplicate drops, gold, items or hearts")
	_check(_event_count(session.drain_events(0), "boss_rewards_awarded") == 0,
		"later result ticks do not reannounce loot")
	var next: Dictionary = session.apply_command(0, "boss_next_once", "next_round")
	var after_income: int = int(session.teams[0]["gold"])
	var repeated: Dictionary = session.apply_command(0, "boss_next_once", "next_round")
	_check(bool(next.get("ok", false)) and next == repeated and session.sim.round_index == 5,
		"duplicate next-round command advances exactly once after PvE")
	_check(int(session.teams[0]["gold"]) == first_gold + Session.income_for_round(5)
		and after_income == int(session.teams[0]["gold"]),
		"continuing after PvE grants only one normal round income")


func _test_life_reward_is_legitimate() -> void:
	var session: Session = _boss_session()
	session.sim.team_lives = [2, 1]
	# Godot 4.7.2 seed13 starts at0.0621177: deliberately exercise a life drop.
	session._rngs[0].seed = 13
	var boss = session.sim.get_unit(999)
	boss.hp = 0.0
	boss.alive = false
	session.step(0.05)
	var awarded_lives: int = 0
	for reward: Dictionary in _rewards(session):
		if reward.get("kind", "") == "life":
			awarded_lives += int(reward.get("amount", 1))
	_check(awarded_lives > 0, "deterministic fixture exercises a legitimate life reward")
	_check(session.sim.team_lives[0] == 2 + awarded_lives
		and session.sim.team_lives[0] <= Session.MAX_LIVES,
		"player hearts increase only by actual life drops within the cap")
	_check(session.sim.team_lives[1] == 1 and session.sim.match_winner == -1,
		"legitimate life reward cannot consume opponent heart or end match")


func _test_missing_boss_and_reward_guard() -> void:
	var session: Session = _boss_session()
	var boss = session.sim.get_unit(999)
	var gold: int = int(session.teams[0]["gold"])
	# Defensive Session boundary: a reported winner alone is insufficient.
	session.sim.round_result = {"winner": 0}
	session._resolve_boss_rewards()
	_check(_rewards(session).is_empty() and int(session.teams[0]["gold"]) == gold,
		"Session refuses loot for a reported victory with live Boss")
	session.sim.units.erase(boss)
	session._resolve_boss_rewards()
	_check(_rewards(session).is_empty() and int(session.teams[0]["gold"]) == gold,
		"Session refuses loot when no Boss exists")
	session.sim.round_result = {}
	var lives: Array = session.sim.team_lives.duplicate()
	_timeout(session)
	_check(int(session.sim.round_result.get("winner", -1)) != 0 and _rewards(session).is_empty(),
		"missing Boss cannot be mistaken for a defeated Boss at timeout")
	_check(session.sim.team_lives == lives and session.sim.match_winner == -1,
		"missing-Boss PvE resolution changes neither side's hearts")


func _normal_fixture(round_number: int, own_count: int = 1) -> Core:
	var sim: Core = Core.new()
	sim.round_index = round_number
	var roster: Array[Dictionary] = [
		{"id": 1, "key": "obama", "team": 0, "cell": Vector2i(0, 7), "active": true},
		{"id": 101, "key": "obama", "team": 1, "cell": Vector2i(7, 0), "active": true}
	]
	if own_count == 2:
		roster.append({"id": 2, "key": "neymar", "team": 0,
			"cell": Vector2i(1, 7), "active": true})
	_check(sim.preparation_setup(roster) and sim.start_combat(), "normal-round fixture starts")
	return sim


func _test_normal_rounds() -> void:
	var elimination: Core = _normal_fixture(2)
	elimination.team_lives = [2, 1]
	elimination.get_unit(101).hp = 0.0
	elimination.get_unit(101).alive = false
	elimination.step(0.05)
	_check(elimination.round_result.get("winner", -1) == 0
		and elimination.round_result.get("reason", "") == "elimination",
		"normal elimination still resolves the winning side")
	_check(elimination.team_lives == [2, 0] and elimination.match_winner == 0,
		"normal elimination still removes final heart and ends match")
	var survivors: Core = _normal_fixture(2, 2)
	survivors.tick = 599
	survivors.elapsed = 29.95
	survivors.step(0.05)
	_check(survivors.round_result.get("winner", -1) == 0
		and survivors.round_result.get("reason", "") == "survivors"
		and survivors.team_lives == [4, 3], "normal timeout still prioritizes survivors")
	# A bare core round4 is normal until Session explicitly enables PvE.
	var damage: Core = _normal_fixture(4)
	_check(not damage.is_boss_round, "round number4 alone does not enable PvE in bare core")
	damage.team_damage = [10.0, 20.0]
	damage.tick = 599
	damage.elapsed = 29.95
	damage.step(0.05)
	_check(damage.round_result.get("winner", -1) == 1
		and damage.round_result.get("reason", "") == "damage"
		and damage.team_lives == [3, 4], "normal round4 damage tiebreak still removes losing heart")
	var draw: Core = _normal_fixture(2)
	draw.team_damage = [20.0, 20.0]
	draw.tick = 599
	draw.elapsed = 29.95
	draw.step(0.05)
	_check(draw.round_result.get("winner", -2) == -1
		and draw.round_result.get("reason", "") == "draw"
		and draw.team_lives == [4, 4] and draw.match_winner == -1,
		"normal complete draw preserves both sides' hearts")
