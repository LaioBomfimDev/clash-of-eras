extends SceneTree
## Headless invariants for local V1 economy/commands/privacy; not a balance test.

const Session = preload("res://simulation/match_session.gd")
var passed: int = 0
var failed: int = 0
var command_number: int = 0

func _initialize() -> void:
	_test_initial_and_privacy()
	_test_commands_and_gold()
	_test_recruit_and_capacity()
	_test_copies_and_levels()
	_test_lote_03_session()
	_test_equipment_and_fusion()
	_test_benefits_and_rounds()
	_test_clock_and_replay()
	print("MATCH SESSION TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _command(session: Session, operation: String, payload: Dictionary = {}, team: int = 0) -> Dictionary:
	command_number += 1
	return session.apply_command(team, "test_%d" % command_number, operation, payload)

func _hero_offer(session: Session, team: int = 0) -> Dictionary:
	for offer: Dictionary in session.teams[team]["shop"]:
		if offer["kind"] == "hero":
			return offer
	return {}

func _fixture_bag(session: Session, keys: Array) -> void:
	var bag: Array = []
	for key: String in keys:
		bag.append(session._new_item(0, key))
	session.teams[0]["bag"] = bag

func _force_round_win(session: Session, team: int = 0) -> void:
	_command(session, "ready")
	for unit in session.sim.units:
		if unit.team != team and unit.active:
			unit.alive = false
			unit.hp = 0.0
	session.step(0.05)

func _test_initial_and_privacy() -> void:
	var session: Session = Session.new(100)
	var view: Dictionary = session.snapshot_for_team(0)
	_check(session.phase == "benefit" and view["own"]["gold"] == 25, "initial benefit and 25 player gold")
	_check(view["lives"] == [4, 4] and session._active_count(0) == 0, "four lives and clean field on game start")
	_check(not session.sim.get_unit(5).active and not session.sim.get_unit(4).active, "heroes start outside the field")
	_check(view["own"]["owned"].is_empty(), "clean start: player starts without pre-allocated heroes")
	var items: int = 0
	var heroes: int = 0
	for offer: Dictionary in view["own"]["shop"]:
		if offer["kind"] == "item": items += 1
		if offer["kind"] == "hero": heroes += 1
	_check(items == 3 and heroes == 4 and not _hero_offer(session).is_empty(), "expanded shop: three items and four heroes offered")
	_check(view["enemy"]["units"].is_empty() and view["combat"].is_empty(), "first preparation exposes no current enemy formation or combat state")
	_check(not view["enemy"].has("shop") and not view["enemy"].has("bag"), "enemy economy/inventory omitted")
	view["own"]["gold"] = 9999
	view["own"]["shop"].clear()
	_check(session.teams[0]["gold"] == 25 and session.teams[0]["shop"].size() == 7, "snapshot cannot mutate authority")
	_check(session.snapshot_for_team(5).is_empty(), "invalid spectator/actor cannot receive private snapshot")
	_check(not _command(session, "place", {"unit_id": 101, "cell": [0, 7]})["ok"], "player cannot command bot unit")
	_check(not _command(session, "place", {"unit_id": {}, "cell": [0, 7]})["ok"], "malformed unit identifier rejected without type conversion crash")
	_check(not _command(session, "place", {"unit_id": 1, "cell": [0.5, 7]})["ok"], "fractional grid coordinates rejected")
	_check(_command(session, "place", {"unit_id": 1.0, "cell": [0.0, 7.0]})["ok"] == false, "unit not owned cannot be placed")
	var first: Session = Session.new(100)
	var second: Session = Session.new(100)
	first.teams[1]["gold"] = 100 # Private opponent-only fixture action.
	_command(first, "reroll", {}, 1)
	_command(first, "buy_item", {"offer_id": first.teams[1]["shop"][0]["offer_id"]}, 1)
	var first_item: Dictionary = _command(first, "buy_item", {"offer_id": first.teams[0]["shop"][0]["offer_id"]})
	var second_item: Dictionary = _command(second, "buy_item", {"offer_id": second.teams[0]["shop"][0]["offer_id"]})
	_check(first_item["data"]["id"] == second_item["data"]["id"], "own item IDs do not disclose extra opponent purchases")
	var private_event: bool = false
	for event: Dictionary in first.drain_events(0):
		private_event = private_event or event.get("team", 0) == 1
	_check(not private_event, "UI event drain excludes opponent economy and inventory actions")

func _test_commands_and_gold() -> void:
	var session: Session = Session.new(101)
	var offer: Dictionary = session.teams[0]["shop"][0].duplicate(true)
	var payload: Dictionary = {"offer_id": offer["offer_id"]}
	var first: Dictionary = session.apply_command(0, "buy_once", "buy_item", payload)
	var gold: int = session.teams[0]["gold"]
	var repeated: Dictionary = session.apply_command(0, "buy_once", "buy_item", payload)
	_check(first == repeated and first["ok"], "duplicate command returns original success")
	_check(session.teams[0]["gold"] == gold and session.teams[0]["bag"].size() == 1, "duplicate purchase spends/grants once")
	_check(gold == 25 - int(offer["price"]), "only item cost debited")
	_check(not session.apply_command(0, "buy_once", "reroll")["ok"], "command ID reuse with different action rejected")
	_check(not _command(session, "buy_item", payload)["ok"], "claimed item cannot be bought with a new command ID")
	first["data"]["key"] = "hacked"
	_check(session.teams[0]["bag"][0]["key"] == offer["key"], "command response cannot mutate granted item")
	_check(not session.apply_command(2, "actor", "reroll")["ok"] and not session.apply_command(0, "", "reroll")["ok"], "invalid actor and empty command ID rejected")
	var before: int = session.teams[0]["gold"]
	_check(_command(session, "reroll")["ok"] and session.teams[0]["gold"] == before - 2, "reroll costs two test gold")
	_check(not _command(session, "buy_item", payload)["ok"], "old shop offer ID invalid after reroll")
	while int(session.teams[0]["gold"]) >= 2:
		_command(session, "reroll")
	var shop: Array = session.teams[0]["shop"].duplicate(true)
	_check(not _command(session, "reroll")["ok"] and session.teams[0]["shop"] == shop, "insufficient funds leaves shop and gold unchanged")
	_check(int(session.teams[0]["gold"]) >= 0, "economy never goes negative")

func _test_recruit_and_capacity() -> void:
	var session: Session = Session.new(102)
	for key: String in ["neymar", "caramelo", "obama", "michael"]:
		_check(_command(session, "recruit", {"offer_id": _copy_offer(session, key, 80 + session.teams[0]["owned"].size())["offer_id"]})["ok"], "fill field with %s" % key)
	_check(session._active_count(0) == 4, "initial capacity of four units reached")
	_check(_command(session, "recruit", {"offer_id": _copy_offer(session, "zumbi", 90)["offer_id"]})["ok"], "fifth hero with full field goes to reserve")
	_check(session.snapshot_for_team(0)["own"]["bench"] == [4], "fifth hero is on reserve bench")
	_check(not _command(session, "deploy", {"unit_id": 4, "cell": [0, 7]})["ok"], "field capacity enforced")
	_check(_command(session, "upgrade_capacity")["ok"] and session.teams[0]["gold"] == 17, "capacity four to five costs eight test gold")
	_check(_command(session, "deploy", {"unit_id": 4, "cell": [0, 7]})["ok"] and session._active_count(0) == 5, "fifth hero deploys after expansion")
	_check(_command(session, "upgrade_capacity")["ok"] and session.teams[0]["gold"] == 5 and int(session.teams[0]["capacity"]) == 6, "capacity five to six costs twelve test gold")
	_check(_command(session, "bench", {"unit_id": 2})["ok"], "free removal preserves owned hero")
	_check(_command(session, "swap", {"active_id": 3, "bench_id": 2})["ok"], "active/reserve swap succeeds atomically")
	_check(session.sim.get_unit(2).active and not session.sim.get_unit(3).active and session.teams[0]["gold"] == 5, "swap changes membership without refund or charge")
	var previous: Vector2i = session.sim.get_unit(2).cell
	_check(not _command(session, "swap", {"active_id": 2, "bench_id": 101})["ok"] and session.sim.get_unit(2).cell == previous, "foreign reserve cannot replace an owned unit")

func _copy_offer(session: Session, key: String, slot: int = 99) -> Dictionary:
	var offer: Dictionary = session._offer(0, slot, "hero", key, key, 0)
	(session.teams[0]["shop"] as Array).append(offer)
	return offer

func _test_copies_and_levels() -> void:
	var session: Session = Session.new(104)
	var recruit_obama: Dictionary = _command(session, "recruit", {"offer_id": _copy_offer(session, "obama", 80)["offer_id"]})
	_check(recruit_obama["ok"] and int(session.teams[0]["copies"]["obama"]) == 1, "Obama recruited: level 1 with one copy")
	var obama = session.sim.get_unit(3)
	var base_hp: float = obama.max_hp
	var base_attack: float = obama.attack_damage
	var base_shield: float = obama.shield
	_check(obama.level == 1 and int(session.teams[0]["copies"]["obama"]) == 1, "initial heroes start at match level 1 with one copy")
	var gold: int = int(session.teams[0]["gold"])
	var first: Dictionary = _command(session, "recruit", {"offer_id": _copy_offer(session, "obama", 81)["offer_id"]})
	_check(first["ok"] and int(first["data"]["level"]) == 2 and int(first["data"]["copies"]) == 2, "second copy joins immediately: level 2")
	_check(obama.level == 2 and is_equal_approx(obama.max_hp, base_hp * 1.5) and is_equal_approx(obama.attack_damage, base_attack * 1.5), "level 2 multiplies HP and attack by 1.5 test value")
	_check(is_equal_approx(obama.shield, base_shield * 1.5) and is_equal_approx(obama.hp, obama.max_hp), "level 2 scales suitcase shield and keeps full health")
	_check(int(session.teams[0]["gold"]) == gold and session.teams[0]["owned"].count("obama") == 1, "copy is free and does not create a second unit")
	_check(session.snapshot_for_team(0)["own"]["bench"].is_empty(), "joined copy does not occupy the reserve")
	var second: Dictionary = _command(session, "recruit", {"offer_id": _copy_offer(session, "obama", 82)["offer_id"]})
	_check(second["ok"] and obama.level == 3 and is_equal_approx(obama.max_hp, base_hp * 2.25), "third copy in total reaches level 3 (x2.25)")
	var copies_before: Dictionary = (session.teams[0]["copies"] as Dictionary).duplicate()
	var extra: Dictionary = _copy_offer(session, "obama", 83)
	_check(_command(session, "recruit", {"offer_id": extra["offer_id"]})["code"] == "max_level" and obama.level == 3, "fourth copy rejected at max level")
	_check(session.teams[0]["copies"] == copies_before and not extra["claimed"], "max-level rejection changes nothing")
	for attempt: int in range(4):
		_check(_command(session, "reroll")["ok"], "reroll after leveling")
		for offer: Dictionary in session.teams[0]["shop"]:
			_check(not (offer["kind"] == "hero" and offer["key"] == "obama"), "max-level hero leaves the shop pool")
	_fixture_bag(session, ["vest"])
	_check(_command(session, "equip", {"unit_id": 3, "item_id": session.teams[0]["bag"][0]["id"]})["ok"], "level 3 hero can equip")
	_check(is_equal_approx(obama.max_hp, base_hp * 2.25 * 1.2), "level and equipment multipliers combine")
	_force_round_win(session)
	_check(_command(session, "next_round")["ok"], "next round after leveling")
	obama = session.sim.get_unit(3)
	_check(obama.level == 3 and is_equal_approx(obama.max_hp, base_hp * 2.25 * 1.2) and is_equal_approx(obama.shield, base_shield * 2.25), "level persists into the next round")
	var formation: Array = session._formation_snapshot(0)
	_check(formation.any(func(entry: Dictionary) -> bool: return entry["id"] == 3 and entry["level"] == 3), "public formation snapshot carries level")
	var fresh: Session = Session.new(105)
	var zumbi_offer: Dictionary = _copy_offer(fresh, "zumbi", 85)
	_check(_command(fresh, "recruit", {"offer_id": zumbi_offer["offer_id"]})["ok"] and int(fresh.teams[0]["copies"]["zumbi"]) == 1, "new hero starts with one copy")
	_check(_command(fresh, "recruit", {"offer_id": _copy_offer(fresh, "zumbi", 86)["offer_id"]})["ok"] and fresh.sim.get_unit(4).level == 2, "reserve hero can level up too")

func _test_lote_03_session() -> void:
	var session: Session = Session.new(106)
	_check(session.sim.units.size() == 22 and not session.sim.get_unit(6).active, "new heroes exist but start outside the field")
	_check(not session.teams[0]["owned"].has("barbie"), "new heroes are not owned at the start")
	for key: String in ["neymar", "caramelo", "obama", "michael"]:
		_check(_command(session, "recruit", {"offer_id": _copy_offer(session, key, 70 + session.teams[0]["owned"].size())["offer_id"]})["ok"], "fill field with %s" % key)
	_check(session._active_count(0) == 4, "field has 4 active heroes")
	for key: String in ["barbie", "elon", "snoop", "lula", "bob_marley"]:
		_check(_command(session, "recruit", {"offer_id": _copy_offer(session, key, 80 + session.teams[0]["shop"].size())["offer_id"]})["ok"], "recruit %s into the reserve" % key)
	_check(session.snapshot_for_team(0)["own"]["bench"].size() == Session.BENCH_CAPACITY, "field full: five new heroes fill the five reserve slots")
	var before_bench: Dictionary = session.snapshot_for_team(0)["own"]
	var rejected_bench: Dictionary = _command(session, "bench", {"unit_id": 1})
	_check(rejected_bench["code"] == "bench_full", "full reserve rejects removing another active hero")
	_check(session.snapshot_for_team(0)["own"] == before_bench, "full-reserve removal rejection preserves formation and ownership atomically")
	var rejected: Dictionary = _command(session, "recruit", {"offer_id": _copy_offer(session, "rapunzel", 200)["offer_id"]})
	_check(rejected["code"] == "bench_full" and not session.teams[0]["owned"].has("rapunzel"), "sixth new hero rejected with full field and reserve")
	var copy: Dictionary = _command(session, "recruit", {"offer_id": _copy_offer(session, "barbie", 201)["offer_id"]})
	_check(copy["ok"] and int(copy["data"]["level"]) == 2, "copy of an owned hero still joins with a full reserve")
	var barbie_session: Session = Session.new(107)
	_check(_command(barbie_session, "recruit", {"offer_id": _copy_offer(barbie_session, "barbie", 202)["offer_id"]})["ok"], "Barbie recruited into empty field")
	_command(barbie_session, "ready")
	_check(barbie_session.phase == "combat", "combat starts with Barbie")
	var ken_ids: Array = barbie_session.snapshot_for_team(0)["combat"]["units"].filter(func(u: Dictionary) -> bool: return bool(u.get("summoned", false))).map(func(u: Dictionary) -> int: return int(u["id"]))
	_check(ken_ids == [86], "Ken appears in the revealed combat units")
	_check(barbie_session._formation_snapshot(0).all(func(u: Dictionary) -> bool: return int(u["id"]) != 86), "Ken is not part of the public formation")
	_check(barbie_session._active_count(0) == 1, "summons do not use field capacity")

func _test_equipment_and_fusion() -> void:
	var session: Session = Session.new(103)
	_check(_command(session, "recruit", {"offer_id": _copy_offer(session, "neymar", 88)["offer_id"]})["ok"], "recruit Neymar for equipment test")
	_fixture_bag(session, ["vest", "blade", "boots", "plate", "ward"])
	var identifiers: Array = session.teams[0]["bag"].duplicate(true)
	for index: int in range(4):
		_check(_command(session, "equip", {"unit_id": 1, "item_id": identifiers[index]["id"]})["ok"], "equip slot %d" % (index + 1))
	_check(session.sim.get_unit(1).max_hp > session.sim.get_unit(1).spec.max_hp and session.sim.get_unit(1).attack_damage > session.sim.get_unit(1).spec.attack_damage, "equipment reaches core runtime HP/attack stats")
	var before: Dictionary = session.snapshot_for_team(0)["own"]
	_check(not _command(session, "equip", {"unit_id": 1, "item_id": identifiers[4]["id"]})["ok"], "fifth item rejected under four-slot test rule")
	_check(session.snapshot_for_team(0)["own"] == before, "failed equipment operation preserves bag/equipment/stats")
	_fixture_bag(session, ["blade", "blade", "blade", "blade", "blade", "blade", "blade", "blade"])
	before = session.snapshot_for_team(0)["own"]
	_check(not _command(session, "unequip", {"unit_id": 1, "item_id": identifiers[0]["id"]})["ok"], "unequip rejects full bag")
	_check(session.snapshot_for_team(0)["own"] == before, "failed unequip neither loses nor duplicates item")
	var shop_item: Dictionary = session.teams[0]["shop"][0]
	var gold: int = session.teams[0]["gold"]
	_check(not _command(session, "buy_item", {"offer_id": shop_item["offer_id"]})["ok"] and session.teams[0]["gold"] == gold, "full bag cannot charge a purchase")
	_fixture_bag(session, ["blade", "blade", "ward"])
	var bag: Array = session.teams[0]["bag"].duplicate(true)
	_check(not _command(session, "fuse", {"item_ids": [bag[0]["id"], bag[0]["id"]]})["ok"], "same component cannot be consumed twice")
	_check(not _command(session, "fuse", {"item_ids": [bag[0]["id"], bag[2]["id"]]})["ok"] and session.teams[0]["bag"] == bag, "unknown recipe preserves components")
	_check(_command(session, "fuse", {"item_ids": [bag[0]["id"], bag[1]["id"]]})["ok"], "known two-blade recipe succeeds")
	_check(session.teams[0]["bag"].size() == 2 and session.teams[0]["bag"][1]["key"] == "great_blade" and session.teams[0]["gold"] == gold, "fusion consumes two distinct components and grants one result without gold/refunds")
	_fixture_bag(session, ["ward", "vest"])
	bag = session.teams[0]["bag"].duplicate(true)
	_check(_command(session, "fuse", {"item_ids": [bag[0]["id"], bag[1]["id"]]})["ok"] and session.teams[0]["bag"][0]["key"] == "guard_vest", "second known recipe accepts reversed component order")
	# Equipar durante combate em tempo real
	_fixture_bag(session, [])
	_check(_command(session, "unequip", {"unit_id": 1, "item_id": identifiers[3]["id"]})["ok"], "unequip opens a slot during preparation")
	_command(session, "ready")
	session.teams[1]["ready"] = true
	session.sim.start_combat()
	session.phase = "combat"
	_fixture_bag(session, ["blade"])
	var combat_item_id: String = session.teams[0]["bag"][0]["id"]
	var attack_before: float = session.sim.get_unit(1).attack_damage
	_check(_command(session, "equip", {"unit_id": 1, "item_id": combat_item_id})["ok"], "equip allowed during live combat")
	_check(session.sim.get_unit(1).attack_damage > attack_before, "equipment increases stats instantly during combat")
	_check(not _command(session, "unequip", {"unit_id": 1, "item_id": combat_item_id})["ok"], "unequip rejected during combat")
	# Comprar item da loja durante combate
	_fixture_bag(session, [])
	session.teams[0]["gold"] = 15
	var shop_item_combat: Dictionary = session.teams[0]["shop"][0]
	var gold_before_buy: int = session.teams[0]["gold"]
	var buy_combat_res: Dictionary = _command(session, "buy_item", {"offer_id": shop_item_combat["offer_id"]})
	_check(buy_combat_res["ok"], "buy_item allowed during live combat")
	_check(session.teams[0]["gold"] == gold_before_buy - int(shop_item_combat["price"]), "gold deducted for item bought during combat")
	_check(session.teams[0]["bag"].size() == 1 and session.teams[0]["bag"][0]["key"] == shop_item_combat["key"], "bought item deposited into bag during combat")
	var combat_snap: Dictionary = session.snapshot_for_team(0)
	var combat_units: Array = combat_snap["combat"]["units"]
	var player_unit_found: bool = false
	var enemy_unit_found: bool = false
	for u: Dictionary in combat_units:
		if int(u["id"]) == 1:
			player_unit_found = true
			_check(u.has("equipment") and not (u["equipment"] as Array).is_empty(), "player unit exports equipped items in combat snapshot")
		elif int(u["team"]) == 1:
			enemy_unit_found = true
			_check(u.has("equipment"), "enemy unit has equipment array exported in combat snapshot")
	_check(player_unit_found and enemy_unit_found, "combat snapshot contains both player and enemy units")

func _test_benefits_and_rounds() -> void:
	var session: Session = Session.new(104)
	var life_id: String = ""
	for choice: Dictionary in session.teams[0]["benefit_options"]:
		if choice["kind"] == "life": life_id = choice["option_id"]
	_check(not life_id.is_empty() and session.teams[0]["benefit_options"].size() == 3, "initial three options include one extra-life opportunity")
	_check(_command(session, "choose_benefit", {"option_id": life_id})["ok"] and session.sim.team_lives[0] == 5, "chosen benefit grants one extra life")
	_check(not _command(session, "choose_benefit", {"option_id": life_id})["ok"] and session.sim.team_lives[0] == 5, "benefit cannot be claimed twice with new command")
	_check(_command(session, "recruit", {"offer_id": _copy_offer(session, "neymar", 88)["offer_id"]})["ok"], "recruit Neymar for benefits test")
	_fixture_bag(session, ["blade"])
	var item_id: String = session.teams[0]["bag"][0]["id"]
	_command(session, "equip", {"unit_id": 1, "item_id": item_id})
	for index: int in range(3):
		_force_round_win(session)
		_check(session.phase == "round_result" and session.sim.team_lives[1] == 3 - index, "one life charged at resolution %d" % (index + 1))
		var before: int = session.teams[0]["gold"]
		_check(_command(session, "next_round")["ok"] and session.teams[0]["gold"] == before + 9, "next round grants income once (9 gold)")
	_check(session.sim.round_index == 4 and session.phase == "benefit", "second benefit opens before fourth combat")
	var life_found: bool = false
	for choice: Dictionary in session.teams[0]["benefit_options"]:
		life_found = life_found or choice["kind"] == "life"
	_check(not life_found and session.teams[0]["benefit_options"].size() == 3, "extra life limited to once per match, replacement third option exists")
	_check(session.teams[0]["equipment"][1][0]["id"] == item_id and session.sim.get_unit(1).attack_damage > session.sim.get_unit(1).spec.attack_damage, "equipment persists and reapplies across new rounds")
	_force_round_win(session)
	_check(session.phase == "match_over" and session.sim.match_winner == 0, "four lost bot lives ends full match")
	_check(not _command(session, "next_round")["ok"], "finished match cannot grant another round/income")
	session.reset(104)
	_check(session.sim.team_lives == [4, 4] and session.sim.round_index == 1 and session.teams[0]["gold"] == 25 and session.teams[0]["equipment"].is_empty(), "reset clears lives/economy/equipment/benefit history")

func _test_clock_and_replay() -> void:
	var session: Session = Session.new(105)
	_command(session, "recruit", {"offer_id": _copy_offer(session, "neymar", 88)["offer_id"]})
	session.step(29.95)
	_check(session.phase == "benefit" and session.sim.elapsed == 0.0, "preparation timer does not advance combat early")
	session.step(0.05)
	_check(session.phase == "combat" and session.sim.elapsed == 0.0, "thirty-second preparation automatically starts combat")
	_check(session.teams[0]["benefit_options"].is_empty(), "timeout selects safe gold benefit once")
	_check(not _command(session, "reroll")["ok"] and not _command(session, "bench", {"unit_id": 1})["ok"], "combat blocks economy and formation commands")
	var revealed: Dictionary = session.snapshot_for_team(0)
	_check(revealed["combat"]["units"].size() >= 1, "active combat units revealed after preparation")
	_force_to_next_preparation(session)
	var previous: Array = session.snapshot_for_team(0)["enemy"]["units"].duplicate(true)
	_check(session.snapshot_for_team(0)["enemy"]["previous_round"] == 1 and not previous.is_empty(), "next preparation supplies previous starting formation")
	var bot_unit = session.sim.get_unit(101)
	var original: Vector2i = bot_unit.cell
	var destination: Vector2i = Vector2i(7, 0) if original != Vector2i(7, 0) else Vector2i(6, 0)
	session.sim.place_unit(101, destination)
	_check(session.snapshot_for_team(0)["enemy"]["units"] == previous and session.snapshot_for_team(0)["combat"].is_empty(), "changing current bot formation does not change private preparation snapshot")
	_check(not previous[0].has("equipment_modifiers") and not previous[0].has("hp"), "previous formation excludes private equipment/current HP")
	var first: Session = Session.new(106)
	var second: Session = Session.new(106)
	_check(first.snapshot_for_team(0) == second.snapshot_for_team(0), "seed reproduces initial offers, benefits and bot economy")
	_command(first, "recruit", {"offer_id": _copy_offer(first, "neymar", 88)["offer_id"]})
	_command(second, "recruit", {"offer_id": _copy_offer(second, "neymar", 88)["offer_id"]})
	_command(first, "ready")
	_command(second, "ready")
	first.step(30.0)
	for index: int in range(600): second.step(0.05)
	_check(first.snapshot_for_team(0) == second.snapshot_for_team(0), "whole combat reproduced across frame-delta partitioning")
	_check(first.phase in ["round_result", "match_over"], "normal full roster combat resolves within thirty seconds")

func _force_to_next_preparation(session: Session) -> void:
	for unit in session.sim.units:
		if unit.team == 1 and unit.active:
			unit.alive = false
			unit.hp = 0.0
	session.step(0.05)
	_command(session, "next_round")
