extends RefCounted

const UnitSpec = preload("res://data/unit_spec.gd")
const DATA_PATH: String = "res://data/debug_characters.json"
## Ordem estável: os IDs de unidade derivam do índice (time * 100 + índice + 1).
const KEYS: Array[String] = ["neymar", "caramelo", "obama", "zumbi", "michael", "barbie", "elon", "snoop", "lula", "bob_marley", "rapunzel"]
const MAX_MATCH_LEVEL: int = 3

static func _raw() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return raw if raw is Dictionary else {}

static func load_specs() -> Dictionary:
	var definitions: Dictionary = _raw().get("characters", {})
	var result: Dictionary = {}
	for character_key: String in KEYS:
		var spec: UnitSpec = UnitSpec.new()
		var values: Dictionary = definitions.get(character_key, {})
		spec.load_values(character_key, values)
		result[character_key] = spec
	return result

## Invocações (ex.: Ken da Barbie): não entram no deck nem na loja.
static func load_summon_specs() -> Dictionary:
	var definitions: Dictionary = _raw().get("summons", {})
	var result: Dictionary = {}
	for summon_key: Variant in definitions:
		if definitions[summon_key] is Dictionary:
			var spec: UnitSpec = UnitSpec.new()
			spec.load_values(str(summon_key), definitions[summon_key])
			result[str(summon_key)] = spec
	return result

## Regras do nível na partida: cópias mínimas e multiplicador de poder por nível (índice 0 = nível 1).
static func load_level_rules() -> Dictionary:
	var rules: Dictionary = _raw().get("match_levels", {})
	var copies: Array[int] = [1, 2, 3]
	var power: Array[float] = [1.0, 1.5, 2.25]
	var raw_copies: Variant = rules.get("copies_for_level", [])
	var raw_power: Variant = rules.get("power_multiplier", [])
	if raw_copies is Array and raw_copies.size() == MAX_MATCH_LEVEL and raw_power is Array and raw_power.size() == MAX_MATCH_LEVEL:
		for index: int in range(MAX_MATCH_LEVEL):
			copies[index] = maxi(1, int(raw_copies[index]))
			power[index] = clampf(float(raw_power[index]), 0.1, 10.0)
	return {"copies_for_level": copies, "power_multiplier": power}

static func level_for_copies(copies: int, rules: Dictionary) -> int:
	var level: int = 1
	var thresholds: Array = rules.get("copies_for_level", [1, 2, 3])
	for index: int in range(thresholds.size()):
		if copies >= int(thresholds[index]):
			level = index + 1
	return clampi(level, 1, MAX_MATCH_LEVEL)
