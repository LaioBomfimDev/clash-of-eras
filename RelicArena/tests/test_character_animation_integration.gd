extends SceneTree
## Integração visual com quadros em memória, sem escrever PNG/manifesto ou alterar regras.

const MainView = preload("res://client/main.gd")
const Bank = preload("res://client/character_animation_bank.gd")
const Player = preload("res://client/character_animation_player.gd")
const Board = preload("res://client/board_projection.gd")

class FixtureBank extends Bank:
	var textures: Dictionary = {}

	func _load_texture(path: String) -> Texture2D:
		return textures.get(path, null) as Texture2D

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var view: MainView = MainView.new()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.menu_open = false
	var setup_ok: bool = view.session.sim.preparation_setup([
		{"id": 4, "key": "zumbi", "team": 0, "cell": Vector2i(2, 5), "active": true},
		{"id": 5, "key": "michael", "team": 0, "cell": Vector2i(1, 7), "active": true},
		{"id": 101, "key": "neymar", "team": 1, "cell": Vector2i(4, 2), "active": true},
		{"id": 102, "key": "elon", "team": 1, "cell": Vector2i(6, 2), "active": true}
	])
	_check(setup_ok, "fixture formation respects preparation halves")
	if not setup_ok:
		quit(1)
		return
	# Disposição de combate horizontal para exercitar os clips east/west exatos.
	view.session.sim.get_unit(101).cell = Vector2i(4, 5)
	_check(view.session.sim.start_combat(), "fixture uses authoritative round-start buffs")
	view.session.phase = "combat"
	view.session.events.clear()
	view.session.sim.events.clear()
	view.state = view.session.snapshot_for_team(0)
	var zumbi: Dictionary = view._unit_by_id(4)
	view.visual_directions[4] = "east"
	view.character_bank = FixtureBank.new()
	view.character_player = Player.new(view.character_bank)
	var idle_pose: Dictionary = view._visual_pose(zumbi)
	var fallback: Dictionary = view._body_frame(zumbi, idle_pose)
	_check(fallback["state"] == "idle", "absent optional clips preserve idle")
	_check(fallback["texture"] == view.art.texture_for("zumbi", "east", float(idle_pose["time"])), "fallback preserves current exact idle loader")
	_check(fallback["anchor"] == view.art.anchor_for(fallback["texture"], "zumbi"), "fallback preserves existing anchor")
	var bank: FixtureBank = _bank()
	view.character_bank = bank
	view.character_player = Player.new(bank)
	view.visual_moves[4] = true
	view.visual_attacks[4] = {"remaining": 0.1, "duration": 0.22, "direction": Vector2.RIGHT}
	view.visual_hits[4] = 0.1
	view._prepare_frame()
	var entry: Dictionary = _entry(view, 4)
	_check(entry["animation_state"] == "walk", "prepare frame resolves original walk clip")
	_check(entry["anchor"] == Vector2(6, 16), "prepare frame preserves declared clip anchor")
	_check(entry["pose"]["offset"] == Vector2.ZERO and entry["pose"]["angle"] == 0.0, "real clip removes fake bob/lunge")
	_check(entry["pose"]["tint"] == Color("ffb3a6"), "real clip preserves hit feedback")
	_check(is_equal_approx(float(entry["display_scale"]), view.art.board_scale_for("zumbi")), "clip preserves calibrated board scale")
	var stable_height: float = float(entry["height"])
	view.character_player.advance(0.25)
	view._prepare_frame()
	entry = _entry(view, 4)
	_check(is_equal_approx(float(entry["height"]), stable_height), "different animated bounds do not move bars")
	var local_center: Vector2 = view.art.bounds_for(entry["texture"], "zumbi", entry["anchor"]).get_center()
	var click: Vector2 = (entry["feet"] as Vector2).round() + local_center * float(entry["display_scale"])
	_check(int(view._unit_at_point(click).get("id", -1)) == 4, "pick uses the drawn animated bounds and anchor")
	view.visual_moves[4] = false
	view.character_player.clear()
	view.session.events.append({"type": "combat_started", "tick": 0, "round": 1})
	view._consume_events()
	_check(view._body_frame(view._unit_by_id(4), view._visual_pose(zumbi))["state"] == "skill", "passive skill visual begins at combat start")
	var inspiration: Array = view.kit_effects.filter(func(effect: Dictionary) -> bool: return effect.get("library_key", "") == "zumbi_inspiracao")
	_check(inspiration.size() == 2, "inspiration appears once on both active allies, including Zumbi")
	_check(inspiration.all(func(effect: Dictionary) -> bool: return int(effect.get("target_id", -1)) in [4, 5]), "inspiration never marks opponents")
	_check(view.session.sim.get_unit(5).round_attack_speed_bonus > 0.0, "marked ally actually has authoritative Zumbi attack-speed bonus")
	view.character_player.advance(0.25)
	view.session.events.append({"type": "combat_started", "tick": 0, "round": 1})
	view.session.events.append({"type": "crit_growth", "source_id": 4, "tick": 1, "amount": 0.1, "stacks": 1, "cap": 1.0})
	view._consume_events()
	_check(view.character_player.frame_for(view._unit_by_id(4), "east", false)["frame_index"] == 1, "duplicate start and critical VFX do not restart body skill")
	_check(view.kit_effects.filter(func(effect: Dictionary) -> bool: return effect.get("library_key", "") == "zumbi_inspiracao").size() == 2, "duplicate start does not duplicate inspiration")
	view._spawn_kit_feedback({"type": "hit", "critical": false, "amount": 10.0}, view._unit_by_id(4), view._unit_by_id(101))
	_check(view.kit_effects[-1]["library_key"] == "estocada_01", "normal spear hit preserves original thrust VFX")
	view._spawn_kit_feedback({"type": "hit", "critical": true, "amount": 15.0}, view._unit_by_id(4), view._unit_by_id(101))
	_check(view.kit_effects[-1]["library_key"] == "zumbi_estocada_critica", "critical spear hit uses dedicated original VFX")
	_check(is_equal_approx(float(view.kit_effects[-1]["angle"]), 0.0), "critical thrust preserves plus-x authored direction")
	view.visual_attacks.clear()
	view.session.events.append({"type": "kick", "source_id": 101, "target_id": 4, "tick": 2})
	view.session.events.append({"type": "projectile_launched", "source_id": 102, "target_id": 4, "kind": "rocket", "tick": 2})
	view._consume_events()
	_check(not view.visual_attacks.has(101) and not view.visual_attacks.has(102), "kick and projectile launch alone do not start body attack")
	_check(view.character_player.frame_for(view._unit_by_id(101), "west", false).is_empty(), "kick does not enqueue a second body clip")
	view.session.events.append({"type": "attack", "source_id": 101, "target_id": 4, "tick": 3})
	view._consume_events()
	_check(view.character_player.frame_for(view._unit_by_id(101), "east", false)["state"] == "attack", "normal attack selects original west-facing clip")
	view.character_player.advance(0.25)
	view.session.events.append({"type": "kick", "source_id": 101, "target_id": 4, "tick": 3})
	view.session.events.append({"type": "ball_impact", "source_id": 101, "target_id": 4, "tick": 4, "impact": 2})
	view._consume_events()
	_check(view.character_player.frame_for(view._unit_by_id(101), "east", false)["frame_index"] == 1, "kick and ricochet cannot reset an existing attack clip")
	view.visual_directions[5] = "east"
	view.visual_moves[5] = true
	var michael: Dictionary = view._unit_by_id(5)
	var michael_pose: Dictionary = view._visual_pose(michael)
	_check(view._body_frame(michael, michael_pose)["texture"] == view.art.texture_for("michael", "east", float(michael_pose["time"])), "Michael keeps existing 72-frame loader")
	view.session.sim.get_unit(101).cell = Vector2i(2, 2)
	view.state = view.session.snapshot_for_team(0)
	view.character_player.clear()
	view._start_passive_character_skills({"type": "combat_started", "tick": 99, "round": 1})
	var audience_frame: Dictionary = view.character_player.frame_for(view._unit_by_id(4), "north", false)
	_check(audience_frame.get("state", "") == "skill" and audience_frame.get("texture") == bank.frame_data("zumbi", "skill", "east", 0.0)["texture"], "non-aimed rally can face audience using actual east clip when north is unavailable")
	view.session.sim.get_unit(101).cell = Vector2i(4, 5)
	view.state = view.session.snapshot_for_team(0)
	var source = view.session.sim.get_unit(4)
	source.stun_remaining = 1.0
	view.state = view.session.snapshot_for_team(0)
	_check(view._body_frame(view._unit_by_id(4), view._visual_pose(view._unit_by_id(4)))["state"] == "idle", "authoritative stun interrupts body clip")
	source.stun_remaining = 0.0
	source.alive = false
	view.state = view.session.snapshot_for_team(0)
	var dead_pose: Dictionary = view._visual_pose(view._unit_by_id(4))
	view._body_frame(view._unit_by_id(4), dead_pose)
	_check(float(dead_pose["angle"]) > 0.0, "death pose is not zeroed by clip integration")
	view.character_player.play_action(101, "neymar", "attack", "west", "round-end")
	view.session.events.append({"type": "round_finished", "winner": 0})
	view._consume_events()
	_check(view.character_player.frame_for(view._unit_by_id(101), "west", false).is_empty(), "round result clears presentation actions")
	view._prepare_frame()
	view.queue_redraw()
	view.units_layer.queue_redraw()
	await process_frame
	print("CHARACTER ANIMATION INTEGRATION TESTS: %d passed, %d failed" % [passed, failed])
	view.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)


func _bank() -> FixtureBank:
	var bank: FixtureBank = FixtureBank.new()
	var paths: Array[String] = []
	for index: int in range(3):
		var path: String = "res://fixture/integration_%d.png" % index
		var image: Image = Image.create(12, 18, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		image.fill_rect(Rect2i(2, 2, 8, 8 + index * 2), Color.WHITE)
		bank.textures[path] = ImageTexture.create_from_image(image)
		paths.append(path)
	var characters: Dictionary = {}
	for key: String in ["zumbi", "neymar", "elon", "michael"]:
		var states: Dictionary = {}
		for state: String in ["walk", "attack", "skill"]:
			states[state] = {"fps": 4.0, "anchor": [6, 16], "directions": {
				"east": {"frames": paths}, "west": {"frames": paths}
			}}
		characters[key] = {"states": states}
	bank._load_definitions({"characters": characters})
	return bank


func _entry(view: MainView, unit_id: int) -> Dictionary:
	for entry: Dictionary in view.frame_entries:
		if int(entry["unit"]["id"]) == unit_id:
			return entry
	return {}


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
