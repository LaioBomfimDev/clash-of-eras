extends RefCounted

const UnitSpec = preload("res://data/unit_spec.gd")

var spec: UnitSpec
var id: int
var key: String
var display_name: String
var team: int
var cell: Vector2i
var previous_cell: Vector2i
var hp: float
var max_hp: float
var shield: float
var dance_shield: float = 0.0
var dance_shield_remaining: float = 0.0
var dance_shield_source_id: int = -1
var moonwalk_stage: String = "none"
var moonwalk_steps_done: int = 0
var moonwalk_timer: float = 0.0
var moonwalk_from_cell: Vector2i
var moonwalk_to_cell: Vector2i
var moonwalk_previous_cell: Vector2i = Vector2i(-100, -100)
var facing_axial: Vector2i = Vector2i(0, 1)
var alive: bool = true
## Nível na partida (cópias). Multiplica vida, dano e poder do kit; não é o nível da carta.
var level: int = 1
var level_multiplier: float = 1.0
## Lote 03: atordoamento (Rapunzel), volta por cima (Lula), invocação (Ken) e laço.
var stun_remaining: float = 0.0
var revived: bool = false
var revive_count: int = 0
var is_reviving: bool = false
var revive_delay_remaining: float = 0.0
var pending_revival_ratio: float = 0.0
var has_angel_wings: bool = false
var divine_frenzy_timer: float = 0.0
var group_attack_buff_timer: float = 0.0
var mana: float = 0.0
var summoned: bool = false
var summoner_id: int = -1
var guardian_id: int = -1
var ability_cooldown: float = 0.0
var active: bool = true
var attack_damage: float = 0.0
var armor: float = 0.0
var resist: float = 0.0
var damage_type: String = "physical"
var equipment_modifiers: Dictionary = {}
var equipment: Array = []
var synergy_hp_multiplier: float = 1.0
var synergy_attack_multiplier: float = 1.0
var synergy_armor_bonus: float = 0.0
var synergy_resist_bonus: float = 0.0
var round_attack_speed_bonus: float = 0.0
var round_crit_bonus: float = 0.0
var support_cooldown: float = 4.0
var damage_dealt: float = 0.0
var healing_done: float = 0.0
var shield_absorbed: float = 0.0
var kills: int = 0
var attack_count: int = 0
var crit_growth: float = 0.0
var crit_growth_hits: int = 0
var assassin_target_id: int = -1
var assassin_opening_remaining: float = 0.0
var assassin_opening_finished: bool = true
var briefcase_cooldown: float = 0.0
var attack_cooldown: float = 0.25
var move_cooldown: float = 0.0
var attack_speed_multiplier: float = 1.0
var effective_crit_chance: float = 0.0
var last_action: String = "idle"
var target_id: int = -1
## One refreshable bleed per source, no unlimited stacks.
var bleeds: Array[Dictionary] = []
## Boss Desenvolvedor
var is_boss: bool = false
var boss_enraged: bool = false
var boss_red_fire_timer: float = 1.2
var boss_tornado_timer: float = 4.8
var boss_purple_fire_timer: float = 2.4
var boss_teleport_timer: float = 4.0
var boss_summons_spawned: Array[int] = []
var boss_tornado_telegraphed: bool = false
var boss_purple_telegraphed: bool = false
var boss_tornado_target: Vector2i = Vector2i(-1, -1)
var boss_purple_target: Vector2i = Vector2i(-1, -1)

func _init(definition: UnitSpec, unit_id: int, side: int, start_cell: Vector2i) -> void:
	spec = definition
	id = unit_id
	key = definition.key
	display_name = definition.display_name
	team = side
	cell = start_cell
	previous_cell = start_cell
	moonwalk_from_cell = start_cell
	moonwalk_to_cell = start_cell
	if key == "michael" and definition.moonwalk_steps > 0:
		moonwalk_stage = "ready"
	max_hp = definition.max_hp
	hp = max_hp
	shield = definition.initial_shield
	effective_crit_chance = definition.crit_chance
	support_cooldown = definition.heal_interval
	assassin_opening_remaining = definition.assassin_opening_duration
	assassin_opening_finished = definition.assassin_opening_duration <= 0.0
	briefcase_cooldown = definition.briefcase_guard_interval
	is_boss = definition.is_boss
	boss_red_fire_timer = 1.2
	boss_tornado_timer = 4.8
	boss_purple_fire_timer = 2.4
	boss_teleport_timer = definition.boss_teleport_interval if definition != null else 4.0
	boss_summons_spawned.clear()
	recalculate_combat_stats()

## Somente na preparação: o escudo inicial da mala volta ao valor do novo nível.
func apply_level(new_level: int, multiplier: float) -> void:
	level = new_level
	level_multiplier = multiplier
	shield = spec.initial_shield * level_multiplier
	recalculate_combat_stats()

func recalculate_combat_stats() -> void:
	var health_ratio: float = hp / max_hp if max_hp > 0.0 else 1.0
	var base_hp: float = spec.max_hp * level_multiplier
	if spec.max_hp_by_level.size() == 3:
		base_hp = spec.max_hp_by_level[clampi(level - 1, 0, 2)]
	max_hp = maxf(1.0, (base_hp * float(equipment_modifiers.get("hp_mult", 1.0)) + float(equipment_modifiers.get("hp_bonus", 0.0))) * synergy_hp_multiplier)
	hp = clampf(max_hp * health_ratio, 0.0, max_hp)
	attack_damage = maxf(0.0, (spec.attack_damage * level_multiplier * float(equipment_modifiers.get("attack_mult", 1.0)) + float(equipment_modifiers.get("attack_bonus", 0.0))) * synergy_attack_multiplier)
	armor = maxf(0.0, spec.armor * float(equipment_modifiers.get("armor_mult", 1.0)) + float(equipment_modifiers.get("armor_bonus", 0.0)) + synergy_armor_bonus)
	resist = maxf(0.0, spec.resist * float(equipment_modifiers.get("resist_mult", 1.0)) + float(equipment_modifiers.get("resist_bonus", 0.0)) + synergy_resist_bonus)
	damage_type = spec.damage_type
	attack_speed_multiplier = clampf(float(equipment_modifiers.get("attack_speed_mult", 1.0)) * (1.0 + round_attack_speed_bonus), 0.1, 10.0)
	effective_crit_chance = clampf(spec.crit_chance + float(equipment_modifiers.get("crit_bonus", 0.0)) + round_crit_bonus, 0.0, 1.0)

func as_dictionary() -> Dictionary:
	return {
		"id": id, "key": key, "name": display_name, "team": team,
		"cell": [cell.x, cell.y], "hp": hp, "max_hp": max_hp,
		"shield": shield, "dance_shield": dance_shield, "dance_shield_remaining": dance_shield_remaining,
		"dance_shield_source_id": dance_shield_source_id,
		"moonwalk_stage": moonwalk_stage, "moonwalk_steps_done": moonwalk_steps_done,
		"moonwalk_timer": moonwalk_timer,
		"moonwalk_step_duration": spec.moonwalk_step_duration,
		"moonwalk_pause_duration": spec.moonwalk_pause_duration,
		"moonwalk_from_cell": [moonwalk_from_cell.x, moonwalk_from_cell.y],
		"moonwalk_to_cell": [moonwalk_to_cell.x, moonwalk_to_cell.y],
		"facing_axial": [facing_axial.x, facing_axial.y],
		"alive": alive, "active": active, "crit_growth": crit_growth, "level": level, "stun_remaining": stun_remaining, "revived": revived, "summoned": summoned, "summoner_id": summoner_id, "guardian_id": guardian_id, "is_boss": is_boss, "boss_enraged": boss_enraged, "boss_teleport_timer": boss_teleport_timer,
		"is_reviving": is_reviving, "revive_delay_remaining": revive_delay_remaining, "has_angel_wings": has_angel_wings, "divine_frenzy_timer": divine_frenzy_timer, "group_attack_buff_timer": group_attack_buff_timer,
		"attack_damage": attack_damage, "armor": armor, "resist": resist,
		"damage_type": damage_type, "synergy_tags": spec.synergy_tags.duplicate(),
		"damage_dealt": damage_dealt, "healing_done": healing_done,
		"shield_absorbed": shield_absorbed, "kills": kills,
		"equipment_modifiers": equipment_modifiers.duplicate(true),
		"equipment": equipment.duplicate(true),
		"attack_count": attack_count, "target_id": target_id,
		"mana": mana, "max_mana": spec.max_mana, "revive_count": revive_count,
		"attack_speed_multiplier": attack_speed_multiplier,
		"effective_crit_chance": effective_crit_chance,
		"crit_growth_hits": crit_growth_hits, "crit_damage_multiplier": spec.crit_multiplier + crit_growth,
		"assassin_target_id": assassin_target_id, "assassin_opening_remaining": assassin_opening_remaining,
		"assassin_opening_finished": assassin_opening_finished, "briefcase_cooldown": briefcase_cooldown,
		"bleeds": bleeds.duplicate(true)
	}
