extends RefCounted
## Editable laboratory data, separate from mutable combat state.

var key: String = ""
var display_name: String = ""
var max_hp: float = 100.0
## Curva própria opcional de HP base N1/N2/N3, antes de equipamentos/sinergias.
var max_hp_by_level: Array[float] = []
var attack_damage: float = 10.0
var armor: float = 0.0
var resist: float = 0.0
var damage_type: String = "physical"
var synergy_tags: Array[String] = []
var rarity: String = "common"
var attack_range: int = 1
var attacks_per_second: float = 1.0
var move_interval: float = 0.5
var crit_chance: float = 0.0
var crit_multiplier: float = 1.5
var projectile_seconds_per_hex: float = 0.12
var projectile_min_seconds: float = 0.12
var projectile_max_impacts: int = 3
var projectile_decay_multipliers: Array[float] = []
var bleed_damage_per_tick: float = 0.0
var bleed_duration: float = 0.0
var bleed_tick_interval: float = 1.0
var execute_threshold: float = 0.0
var initial_shield: float = 0.0
## Refinamentos TESTE: caça inicial limitada e renovação da própria mala.
var assassin_opening_duration: float = 0.0
var briefcase_guard_amount: float = 0.0
var briefcase_guard_interval: float = 5.0
var team_attack_speed_bonus: float = 0.0
var team_crit_bonus: float = 0.0
var crit_growth_per_hit: float = 0.0
var crit_growth_cap: float = 0.0
var heal_amount: float = 0.0
var heal_interval: float = 1.0
var heal_range: int = 2
var heal_teamwide: bool = false
var moonwalk_steps: int = 3
var moonwalk_step_duration: float = 0.55
var moonwalk_pause_duration: float = 1.2
var dance_shield_amount: float = 120.0
var dance_shield_duration: float = 4.0
## Kits do lote 03 (valores de teste; ver simulation/README.md).
var projectile_kind: String = ""
var splash_radius: int = 0
var splash_ratio: float = 0.0
var super_attack_interval: int = 0
var super_splash_depth: int = 0
var super_damage_multiplier: float = 1.0
var smoke_radius: int = 1
var smoke_duration: float = 0.0
var smoke_damage_per_tick: float = 0.0
var smoke_tick_interval: float = 0.5
var smoke_miss_chance: float = 0.0
var smoke_ally_speed_bonus: float = 0.0
var summon_key: String = ""
var guardian_damage_bonus: float = 0.0
var revive_ratio: float = 0.0
var extra_revive_ratio: float = 0.0
var extra_revive_min_level: int = 3
var aura_radius_by_level: Array[int] = []
var aura_ally_speed_bonus: float = 0.0
var aura_enemy_slow: float = 0.0
var lasso_first_delay: float = 0.0
var lasso_cooldown: float = 0.0
var lasso_stun: float = 0.0
var lasso_damage: float = 0.0
var max_mana: float = 0.0
var mana_per_attack: float = 0.0
## Boss Desenvolvedor e Invocações PvE (Round 4)
var is_boss: bool = false
var boss_red_fire_cooldown: float = 0.0
var boss_red_fire_damage: float = 0.0
var boss_tornado_cooldown: float = 0.0
var boss_tornado_damage: float = 0.0
var boss_purple_fire_cooldown: float = 0.0
var boss_purple_fire_damage: float = 0.0
var boss_summon_times: Array[float] = []
var boss_summon_keys: Array[String] = []

func load_values(character_key: String, values: Dictionary) -> void:
	key = character_key
	display_name = str(values.get("display_name", key))
	max_hp = maxf(1.0, float(values.get("max_hp", 100.0)))
	max_hp_by_level.clear()
	var health_curve: Variant = values.get("max_hp_by_level", [])
	if health_curve is Array and health_curve.size() == 3:
		for health: Variant in health_curve:
			max_hp_by_level.append(maxf(1.0, float(health)))
	attack_damage = maxf(0.0, float(values.get("attack_damage", 10.0)))
	armor = maxf(0.0, float(values.get("armor", 0.0)))
	resist = maxf(0.0, float(values.get("resist", 0.0)))
	damage_type = str(values.get("damage_type", "physical"))
	if damage_type not in ["physical", "magic"]:
		damage_type = "physical"
	synergy_tags.clear()
	for tag: Variant in values.get("synergy_tags", []):
		synergy_tags.append(str(tag))
	rarity = str(values.get("rarity", "common"))
	if rarity not in ["common", "rare", "epic", "legendary"]:
		rarity = "common"
	attack_range = clampi(int(values.get("attack_range", 1)), 1, 14)
	attacks_per_second = clampf(float(values.get("attacks_per_second", 1.0)), 0.01, 10.0)
	move_interval = maxf(0.1, float(values.get("move_interval", 0.5)))
	crit_chance = clampf(float(values.get("crit_chance", 0.0)), 0.0, 1.0)
	crit_multiplier = maxf(1.0, float(values.get("crit_multiplier", 1.5)))
	projectile_seconds_per_hex = maxf(0.05, float(values.get("projectile_seconds_per_hex", 0.12)))
	projectile_min_seconds = maxf(0.05, float(values.get("projectile_min_seconds", 0.12)))
	projectile_max_impacts = clampi(int(values.get("projectile_max_impacts", 3)), 1, 3)
	projectile_decay_multipliers.clear()
	for mult: Variant in values.get("projectile_decay_multipliers", []):
		projectile_decay_multipliers.append(clampf(float(mult), 0.0, 10.0))
	bleed_damage_per_tick = maxf(0.0, float(values.get("bleed_damage_per_tick", 0.0)))
	bleed_duration = maxf(0.0, float(values.get("bleed_duration", 0.0)))
	bleed_tick_interval = maxf(0.05, float(values.get("bleed_tick_interval", 1.0)))
	execute_threshold = clampf(float(values.get("execute_threshold", 0.0)), 0.0, 1.0)
	initial_shield = maxf(0.0, float(values.get("initial_shield", 0.0)))
	assassin_opening_duration = clampf(float(values.get("assassin_opening_duration", 0.0)), 0.0, 10.0)
	briefcase_guard_amount = maxf(0.0, float(values.get("briefcase_guard_amount", 0.0)))
	briefcase_guard_interval = maxf(0.1, float(values.get("briefcase_guard_interval", 5.0)))
	team_attack_speed_bonus = clampf(float(values.get("team_attack_speed_bonus", 0.0)), 0.0, 2.0)
	team_crit_bonus = clampf(float(values.get("team_crit_bonus", 0.0)), 0.0, 1.0)
	crit_growth_per_hit = maxf(0.0, float(values.get("crit_growth_per_hit", 0.0)))
	crit_growth_cap = maxf(0.0, float(values.get("crit_growth_cap", 0.0)))
	heal_amount = maxf(0.0, float(values.get("heal_amount", 0.0)))
	heal_interval = maxf(0.1, float(values.get("heal_interval", 1.0)))
	heal_range = clampi(int(values.get("heal_range", 2)), 1, 14)
	heal_teamwide = bool(values.get("heal_teamwide", false))
	## 0 disables the moonwalk (used by isolated healing fixtures).
	moonwalk_steps = clampi(int(values.get("moonwalk_steps", 3)), 0, 8)
	moonwalk_step_duration = maxf(0.1, float(values.get("moonwalk_step_duration", 0.55)))
	moonwalk_pause_duration = maxf(0.1, float(values.get("moonwalk_pause_duration", 1.2)))
	dance_shield_amount = maxf(0.0, float(values.get("dance_shield_amount", 120.0)))
	dance_shield_duration = maxf(0.1, float(values.get("dance_shield_duration", 4.0)))
	projectile_kind = str(values.get("projectile_kind", ""))
	if projectile_kind not in ["", "ball", "rocket", "mini_rocket", "smoke"]:
		projectile_kind = ""
	splash_radius = clampi(int(values.get("splash_radius", 0)), 0, 3)
	splash_ratio = clampf(float(values.get("splash_ratio", 0.0)), 0.0, 2.0)
	super_attack_interval = clampi(int(values.get("super_attack_interval", 0)), 0, 10)
	super_splash_depth = clampi(int(values.get("super_splash_depth", 0)), 0, 5)
	super_damage_multiplier = maxf(1.0, float(values.get("super_damage_multiplier", 1.0)))
	smoke_radius = clampi(int(values.get("smoke_radius", 1)), 0, 3)
	smoke_duration = maxf(0.0, float(values.get("smoke_duration", 0.0)))
	smoke_damage_per_tick = maxf(0.0, float(values.get("smoke_damage_per_tick", 0.0)))
	smoke_tick_interval = maxf(0.05, float(values.get("smoke_tick_interval", 0.5)))
	smoke_miss_chance = clampf(float(values.get("smoke_miss_chance", 0.0)), 0.0, 0.9)
	smoke_ally_speed_bonus = clampf(float(values.get("smoke_ally_speed_bonus", 0.0)), 0.0, 3.0)
	summon_key = str(values.get("summon_key", ""))
	guardian_damage_bonus = clampf(float(values.get("guardian_damage_bonus", 0.0)), 0.0, 5.0)
	revive_ratio = clampf(float(values.get("revive_ratio", 0.0)), 0.0, 1.0)
	extra_revive_ratio = clampf(float(values.get("extra_revive_ratio", 0.0)), 0.0, 1.0)
	extra_revive_min_level = clampi(int(values.get("extra_revive_min_level", 3)), 1, 3)
	aura_radius_by_level.clear()
	for radius: Variant in values.get("aura_radius_by_level", []):
		aura_radius_by_level.append(clampi(int(radius), 0, 14))
	aura_ally_speed_bonus = clampf(float(values.get("aura_ally_speed_bonus", 0.0)), 0.0, 3.0)
	aura_enemy_slow = clampf(float(values.get("aura_enemy_slow", 0.0)), 0.0, 0.9)
	lasso_first_delay = maxf(0.0, float(values.get("lasso_first_delay", 0.0)))
	lasso_cooldown = maxf(0.0, float(values.get("lasso_cooldown", 0.0)))
	lasso_stun = maxf(0.0, float(values.get("lasso_stun", 0.0)))
	lasso_damage = maxf(0.0, float(values.get("lasso_damage", 0.0)))
	max_mana = clampf(float(values.get("max_mana", 0.0)), 0.0, 1000.0)
	mana_per_attack = clampf(float(values.get("mana_per_attack", 0.0)), 0.0, max_mana)
	is_boss = bool(values.get("is_boss", false))
	boss_red_fire_cooldown = maxf(0.0, float(values.get("boss_red_fire_cooldown", 0.0)))
	boss_red_fire_damage = maxf(0.0, float(values.get("boss_red_fire_damage", 0.0)))
	boss_tornado_cooldown = maxf(0.0, float(values.get("boss_tornado_cooldown", 0.0)))
	boss_tornado_damage = maxf(0.0, float(values.get("boss_tornado_damage", 0.0)))
	boss_purple_fire_cooldown = maxf(0.0, float(values.get("boss_purple_fire_cooldown", 0.0)))
	boss_purple_fire_damage = maxf(0.0, float(values.get("boss_purple_fire_damage", 0.0)))
	boss_summon_times.clear()
	for time_val: Variant in values.get("boss_summon_times", []):
		boss_summon_times.append(maxf(0.1, float(time_val)))
	boss_summon_keys.clear()
	for key_val: Variant in values.get("boss_summon_keys", []):
		boss_summon_keys.append(str(key_val))
