extends SceneTree
## Economy02: progressive round income, fixed win bonus and atomic dismissal.
## Real Session commands with disposable setup; no UI or balancing claims.

const Session = preload("res://simulation/match_session.gd")
var passed: int = 0
var failed: int = 0
var command_id: int = 0
var offer_slot: int = 400


func _initialize() -> void:
	_test_income_and_streak()
	_test_boss_does_not_count()
	_test_copy_level_flags()
	_test_dismiss_and_recruit_again()
	_test_dismiss_atomic_and_actors()
	_test_dismiss_reserve()
	print("ECONOMIA02 TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)


func _command(session: Session, op: String, payload: Dictionary = {}, team: int = 0) -> Dictionary:
	command_id += 1
	return session.apply_command(team, "economia02_%d" % command_id, op, payload)


func _fresh() -> Session:
	var session: Session = Session.new(20261013)
	session.bot_enabled = false
	session.reset(20261013)
	return session


func _recruit(session: Session, key: String, team: int = 0) -> Dictionary:
	offer_slot += 1
	var offer: Dictionary = session._offer(team, offer_slot, "hero", key, key, 0)
	(session.teams[team]["shop"] as Array).append(offer)
	return _command(session, "recruit", {"offer_id": offer["offer_id"]}, team)


func _add_item(session: Session, key: String, team: int = 0) -> Dictionary:
	var item: Dictionary = session._new_item(team, key)
	(session.teams[team]["bag"] as Array).append(item)
	return item


func _start(session: Session) -> void:
	_command(session, "ready", {}, 0)
	_command(session, "ready", {}, 1)
	_check(session.phase == "combat", "fixture starts combat through Session commands")


func _finish(session: Session, winner: int) -> void:
	_start(session)
	if winner < 0:
		for unit in session.sim.units:
			unit.attack_cooldown = 1000.0
		session.sim.team_damage = [0.0, 0.0]
		session.sim.tick = 599
		session.sim.elapsed = 29.95
	else:
		for unit in session.sim.units:
			if unit.active and unit.team != winner:
				unit.hp = 0.0
				unit.alive = false
	session.step(0.05)
	_check(session.phase == "round_result", "fixture resolves a nonterminal round")


func _advance_and_check_income(session: Session, expected_zero: int, expected_one: int) -> void:
	var before_zero: int = int(session.teams[0]["gold"])
	var before_one: int = int(session.teams[1]["gold"])
	command_id += 1
	var id: String = "income_once_%d" % command_id
	var first: Dictionary = session.apply_command(0, id, "next_round")
	var after_zero: int = int(session.teams[0]["gold"])
	var after_one: int = int(session.teams[1]["gold"])
	var second: Dictionary = session.apply_command(0, id, "next_round")
	_check(bool(first.get("ok", false)) and first == second, "next-round command is idempotent")
	_check(after_zero == before_zero + expected_zero and after_one == before_one + expected_one,
		"both teams receive expected base income and fixed win bonus")
	_check(int(session.teams[0]["gold"]) == after_zero and int(session.teams[1]["gold"]) == after_one,
		"duplicate advance cannot pay income twice")
	_check(session.snapshot_for_team(0)["own"]["income"]["last_paid"] == expected_zero,
		"HUD reports authoritative amount actually paid")


func _test_income_and_streak() -> void:
	var session: Session = _fresh()
	_check(session.teams[0]["gold"] == 20 and session.teams[1]["gold"] == 20,
		"both teams start with20 coins before choosing a benefit")
	_check(Session.income_for_round(2) == 12 and Session.income_for_round(3) == 15
		and Session.income_for_round(4) == 18 and Session.income_for_round(100) == 306,
		"base9 grows3 per round index without an imposed cap")
	_recruit(session, "neymar")
	_recruit(session, "obama", 1)
	var before_clock: int = int(session.teams[0]["gold"])
	session.step(1.0)
	_check(session.teams[0]["gold"] == before_clock, "preparation time alone grants no income")
	_finish(session, 0)
	_check(session.teams[0]["win_streak"] == 1 and session.teams[0]["pending_win_bonus"] == 0,
		"first normal win starts sequence without bonus")
	_advance_and_check_income(session, 12, 12)
	_finish(session, 0)
	var income: Dictionary = session.snapshot_for_team(0)["own"]["income"]
	_check(session.teams[0]["win_streak"] == 2 and income["win_bonus"] == 1
		and income["next_round_base"] == 15 and income["next_round_total"] == 16,
		"second normal win reports fixed1 bonus for the next payment")
	var before_result_wait: int = int(session.teams[0]["gold"])
	session.step(10.0)
	_check(session.teams[0]["win_streak"] == 2 and session.teams[0]["gold"] == before_result_wait,
		"result waiting neither recounts victory nor pays income early")
	_advance_and_check_income(session, 16, 15)
	_finish(session, -1)
	_check(session.teams[0]["win_streak"] == 2 and session.teams[1]["win_streak"] == 0
		and session.teams[0]["pending_win_bonus"] == 0, "draw preserves sequence and grants no win bonus")
	_advance_and_check_income(session, 18, 18)
	_finish(session, 1) # Round4: the player fails PvE, without losing a heart.
	_check(session.sim.is_boss_round and session.teams[0]["win_streak"] == 2
		and session.teams[1]["win_streak"] == 0 and session.teams[1]["pending_win_bonus"] == 0,
		"failed Boss neither breaks player sequence nor starts opponent sequence")
	_advance_and_check_income(session, 21, 21)
	_finish(session, 0)
	_check(session.teams[0]["win_streak"] == 3 and session.teams[0]["pending_win_bonus"] == 1,
		"third normal win still grants only1, never growing sequence bonus")
	_advance_and_check_income(session, 25, 24)
	_finish(session, 1)
	_check(session.teams[0]["win_streak"] == 0 and session.teams[1]["win_streak"] == 1,
		"normal loss resets only losing side and starts opponent sequence")
	_advance_and_check_income(session, 27, 27)
	_finish(session, 1)
	_check(session.teams[1]["win_streak"] == 2 and session.teams[1]["pending_win_bonus"] == 1,
		"opponent receives the same fixed sequence rule")
	_advance_and_check_income(session, 30, 31)
	var snapshot: Dictionary = session.snapshot_for_team(0)
	snapshot["own"]["income"]["next_round_base"] = 99999
	snapshot["own"]["win_streak"] = 99999
	_check(session.snapshot_for_team(0)["own"]["income"]["next_round_base"] == 33
		and session.teams[0]["win_streak"] == 0, "income and sequence snapshot cannot mutate authority")
	_check(not snapshot["enemy"].has("income") and not snapshot["enemy"].has("shop"),
		"new economy fields do not expose private opponent economy")
	session.reset(20261013)
	_check(session.teams[0]["win_streak"] == 0 and session.teams[1]["win_streak"] == 0
		and session.teams[0]["pending_win_bonus"] == 0 and session.teams[0]["gold"] == 20,
		"new match resets sequences, pending bonus and initial gold")


func _test_boss_does_not_count() -> void:
	var session: Session = _fresh()
	_recruit(session, "neymar")
	_recruit(session, "obama", 1)
	session.teams[0]["win_streak"] = 2
	session.teams[1]["win_streak"] = 3
	session.sim.round_index = 4
	session.sim.reset_round()
	session._open_preparation()
	_finish(session, 0)
	_check(session.teams[0]["win_streak"] == 2 and session.teams[1]["win_streak"] == 3
		and session.teams[0]["pending_win_bonus"] == 0 and session.teams[1]["pending_win_bonus"] == 0,
		"Boss victory preserves both sequences without paying a sequence bonus")
	_advance_and_check_income(session, 21, 21)


func _test_dismiss_and_recruit_again() -> void:
	var session: Session = _fresh()
	for copy: int in range(4):
		_recruit(session, "neymar")
	var unit = session.sim.get_unit(1)
	_check(unit.level == 3 and session.teams[0]["copies"]["neymar"] == 4,
		"four total copies reach level3 before dismissal")
	var first: Dictionary = _add_item(session, "blade")
	var second: Dictionary = _add_item(session, "vest")
	_command(session, "equip", {"unit_id": 1, "item_id": first["id"]})
	_command(session, "equip", {"unit_id": 1, "item_id": second["id"]})
	var gold: int = int(session.teams[0]["gold"])
	var response: Dictionary = session.apply_command(0, "dismiss_once", "dismiss", {"unit_id": 1})
	var replay: Dictionary = session.apply_command(0, "dismiss_once", "dismiss", {"unit_id": 1})
	_check(response.get("ok", false) and response == replay, "dismiss succeeds in benefit preparation and replays idempotently")
	_check(not unit.active and unit.level == 1 and unit.equipment.is_empty(), "dismiss removes formation and resets runtime level/equipment")
	_check(not session.teams[0]["owned"].has("neymar") and not session.teams[0]["copies"].has("neymar")
		and not session.teams[0]["equipment"].has(1), "dismiss clears owned hero, copy count and equipment record")
	_check(session.teams[0]["gold"] == gold and response["data"]["gold"] == 0, "dismiss pays no gold")
	var bag: Array = session.teams[0]["bag"]
	_check(bag.size() == 2 and bag[0]["id"] == first["id"] and bag[1]["id"] == second["id"],
		"all original equipped item IDs return exactly once")
	response["data"]["returned_items"].clear()
	_check(session.apply_command(0, "dismiss_once", "dismiss", {"unit_id": 1})["data"]["returned_items"].size() == 2
		and bag.size() == 2, "dismiss return mutation cannot change cached reply or inventory")
	_check(_command(session, "dismiss", {"unit_id": 1})["code"] == "not_owned", "new command cannot dismiss an unowned hero again")
	var recruit_again: Dictionary = _recruit(session, "neymar")
	_check(recruit_again.get("ok", false) and unit.active and unit.level == 1
		and session.teams[0]["copies"]["neymar"] == 1 and unit.equipment.is_empty(),
		"future free recruit starts fresh with one copy at level1")

func _test_copy_level_flags() -> void:
	var session: Session = _fresh()
	_recruit(session, "neymar")
	session.drain_events(0)
	for total_copies: int in range(2, 5):
		var reply: Dictionary = _recruit(session, "neymar")
		var data: Dictionary = reply.get("data", {})
		var expected_previous: int = 1 if total_copies == 2 else 2
		var expected_level: int = 2 if total_copies < 4 else 3
		var expected_change: bool = total_copies != 3
		_check(bool(reply.get("ok", false)) and data.get("previous_level", -1) == expected_previous
			and data.get("level_changed", null) == expected_change,
			"copy%d reply identifies actual level change" % total_copies)
		var upgrade: Dictionary = {}
		for event: Dictionary in session.drain_events(0):
			if event.get("type", "") == "hero_upgraded":
				upgrade = event
		_check(upgrade.get("previous_level", -1) == expected_previous
			and upgrade.get("level_changed", null) == expected_change
			and upgrade.get("copies", -1) == total_copies,
			"copy%d event carries authoritative level-change flag" % total_copies)
		var own: Dictionary = session.snapshot_for_team(0)["own"]
		_check(own["copies"]["neymar"] == total_copies
			and own["units"][0]["level"] == expected_level,
			"copy%d snapshot preserves correct level, including N2 at third copy" % total_copies)


func _test_dismiss_atomic_and_actors() -> void:
	var session: Session = _fresh()
	_recruit(session, "obama")
	var item: Dictionary = _add_item(session, "vest")
	_command(session, "equip", {"unit_id": 3, "item_id": item["id"]})
	for index: int in range(Session.BAG_CAPACITY):
		_add_item(session, "charm")
	var before: Dictionary = session.snapshot_for_team(0)
	var refused: Dictionary = session.apply_command(0, "dismiss_full", "dismiss", {"unit_id": 3})
	_check(refused["code"] == "bag_full" and session.snapshot_for_team(0) == before,
		"insufficient return space rejects dismissal with no state changes")
	(session.teams[0]["bag"] as Array).pop_back()
	_check(session.apply_command(0, "dismiss_full", "dismiss", {"unit_id": 3}) == refused
		and session.teams[0]["owned"].has("obama"), "cached failed dismissal remains failed after freeing space")
	_check(_command(session, "dismiss", {"unit_id": 3}).get("ok", false)
		and session.teams[0]["bag"].size() == Session.BAG_CAPACITY, "new command can return equipment into the exact remaining slot")
	_recruit(session, "obama")
	_check(_command(session, "dismiss", {"unit_id": 3}).get("ok", false), "full bag permits dismissing a hero with no equipment")
	_recruit(session, "neymar")
	_recruit(session, "obama", 1)
	_check(_command(session, "dismiss", {"unit_id": 103})["code"] == "not_owned", "player cannot dismiss opponent hero")
	_check(_command(session, "dismiss", {"unit_id": 1.5})["code"] == "invalid_payload"
		and _command(session, "dismiss", {"unit_id": {}})["code"] == "invalid_payload", "malformed dismissal identifiers are rejected")
	_start(session)
	var combat_before: Dictionary = session.snapshot_for_team(0)
	_check(_command(session, "dismiss", {"unit_id": 1})["code"] == "wrong_phase"
		and session.snapshot_for_team(0) == combat_before, "combat dismissal is rejected atomically")


func _test_dismiss_reserve() -> void:
	var session: Session = _fresh()
	for key: String in ["neymar", "obama", "caramelo", "zumbi", "michael"]:
		_recruit(session, key)
	_check(session.snapshot_for_team(0)["own"]["bench"] == [5] and Session.BENCH_CAPACITY == 5,
		"reserve remains five slots and fifth recruit is benched")
	_check(_command(session, "dismiss", {"unit_id": 5}).get("ok", false)
		and session.snapshot_for_team(0)["own"]["bench"].is_empty()
		and session._active_count(0) == 4, "reserve dismissal leaves field formation intact")
