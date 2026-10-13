extends SceneTree
## Four automated local matches through public commands, not human playtests.
## Checks termination, state invariants and isolation; does not prove balancing.
## Run: Godot --headless --path RelicArena --script res://tests/test_full_matches.gd
const Session = preload("res://simulation/match_session.gd")
var command_counter: int = 0
var failures: int = 0
var passed: int = 0
func _initialize() -> void:
	for seed_value: int in [1, 2, 77, 20261011]:
		var session: Session = Session.new(seed_value)
		var rounds: int = 0
		while session.phase != "match_over" and rounds < 16:
			_prepare(session)
			_command(session, "ready")
			session.step(30.0)
			_check(session.phase in ["round_result", "match_over"], "combat terminates within 30 s")
			_check_invariants(session)
			rounds += 1
			if session.phase == "round_result":
				_command(session, "next_round")
		_check(session.phase == "match_over", "match reaches zero lives without hanging")
		print("INTEGRATION seed=%d rounds=%d lives=%s winner=%d" % [seed_value, rounds, session.sim.team_lives, session.sim.match_winner])
	print("FULL MATCH TESTS: 4 automated matches, %d passed, %d failed" % [passed, failures])
	quit(1 if failures > 0 else 0)

func _command(session: Session, operation: String, payload: Dictionary = {}) -> Dictionary:
	command_counter += 1
	return session.apply_command(0, "review_%d" % command_counter, operation, payload)

func _prepare(session: Session) -> void:
	var own: Dictionary = session.snapshot_for_team(0)["own"]
	for option: Dictionary in own["benefit_options"]:
		if option["kind"] == "life":
			_command(session, "choose_benefit", {"option_id": option["option_id"]})
			break
	if session.phase == "benefit":
		for option: Dictionary in session.snapshot_for_team(0)["own"]["benefit_options"]:
			if option["kind"] == "gold":
				_command(session, "choose_benefit", {"option_id": option["option_id"]})
	_command(session, "upgrade_capacity")
	own = session.snapshot_for_team(0)["own"]
	for offer: Dictionary in own["shop"]:
		if offer["kind"] == "hero":
			_command(session, "recruit", {"offer_id": offer["offer_id"]})
	for offer: Dictionary in own["shop"]:
		if offer["kind"] == "item":
			_command(session, "buy_item", {"offer_id": offer["offer_id"]})
	for item: Dictionary in session.snapshot_for_team(0)["own"]["bag"]:
		var preferred: int = 1 if item["key"] in ["blade", "boots", "charm"] else 3
		var result: Dictionary = _command(session, "equip", {"unit_id": preferred, "item_id": item["id"]})
		if not result["ok"]:
			_command(session, "equip", {"unit_id": 5, "item_id": item["id"]})
	var public_before: Dictionary = session.snapshot_for_team(0)["enemy"]
	var enemy_item: float = session.sim.get_unit(101).attack_damage
	_command(session, "reroll")
	_check(session.snapshot_for_team(0)["enemy"] == public_before, "player's shop action cannot reveal enemy current preparation")
	_check(session.sim.get_unit(101).attack_damage == enemy_item, "player's shop does not modify bot runtime")

func _check_invariants(session: Session) -> void:
	for team: int in range(2):
		var own: Dictionary = session.snapshot_for_team(team)["own"]
		_check(int(own["gold"]) >= 0, "gold remains nonnegative")
		_check((own["bag"] as Array).size() <= int(own["bag_capacity"]), "bag respects limit")
		_check((own["bench"] as Array).size() <= Session.BENCH_CAPACITY, "reserve respects limit")
		var ids: Dictionary = {}
		for item: Dictionary in own["bag"]:
			_check(not ids.has(item["id"]), "bag item identity remains unique")
			ids[item["id"]] = true
		for unit_id: Variant in own["equipment"]:
			var equipped: Array = own["equipment"][unit_id]
			_check(equipped.size() <= int(own["equipment_slots"]), "equipment slots respect limit")
			for item: Dictionary in equipped:
				_check(not ids.has(item["id"]), "equipment and bag conserve unique ownership")
				ids[item["id"]] = true
		var active_count: int = 0
		for unit: Dictionary in own["units"]:
			if unit["active"]:
				active_count += 1
		_check(active_count <= int(own["capacity"]), "formation respects capacity")
		_check(session.sim.team_lives[team] >= 0 and session.sim.team_lives[team] <= 5, "extra life respects match limits")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failures += 1
		push_error("REVIEW FAIL " + label)
