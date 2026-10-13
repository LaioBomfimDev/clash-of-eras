extends RefCounted
## V1 laboratory items. Numbers, bag size and slots are experiments, not final rules.

const ITEMS: Dictionary = {
	"blade": {"name": "Lâmina", "price": 5, "description": "+20% de ataque", "modifiers": {"attack_mult": 1.20}, "rarity": "rare"},
	"vest": {"name": "Colete", "price": 5, "description": "+20% de vida", "modifiers": {"hp_mult": 1.20}, "rarity": "rare"},
	"boots": {"name": "Botas", "price": 4, "description": "+15% de velocidade de ataque", "modifiers": {"attack_speed_mult": 1.15}, "rarity": "common"},
	"plate": {"name": "Placa", "price": 4, "description": "+12 de armadura", "modifiers": {"armor_bonus": 12.0}, "rarity": "common"},
	"ward": {"name": "Amuleto", "price": 4, "description": "+12 de resistência mágica", "modifiers": {"resist_bonus": 12.0}, "rarity": "common"},
	"charm": {"name": "Trevo", "price": 3, "description": "+8 pontos percentuais de crítico", "modifiers": {"crit_bonus": 0.08}, "rarity": "common"},
	"great_blade": {"name": "Lâmina dupla", "price": 0, "description": "+45% de ataque · fusão de duas lâminas", "modifiers": {"attack_mult": 1.45}, "rarity": "epic"},
	"guard_vest": {"name": "Colete protegido", "price": 0, "description": "+25% de vida e +16 resistência · colete + amuleto", "modifiers": {"hp_mult": 1.25, "resist_bonus": 16.0}, "rarity": "epic"}
}
const SHOP_KEYS: Array[String] = ["blade", "vest", "boots", "plate", "ward", "charm"]
const RECIPES: Array[Dictionary] = [
	{"id": "double_blade", "name": "Duas lâminas", "ingredients": ["blade", "blade"], "result": "great_blade"},
	{"id": "guard_vest", "name": "Colete + amuleto", "ingredients": ["vest", "ward"], "result": "guard_vest"}
]

static func definition(key: String) -> Dictionary:
	return (ITEMS.get(key, {}) as Dictionary).duplicate(true)

static func fused_key(first: String, second: String) -> String:
	var input: Array[String] = [first, second]
	input.sort()
	for recipe: Dictionary in RECIPES:
		var ingredients: Array = recipe["ingredients"].duplicate()
		ingredients.sort()
		if ingredients[0] == input[0] and ingredients[1] == input[1]:
			return str(recipe["result"])
	return ""

static func modifiers(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item: Dictionary in items:
		var values: Dictionary = definition(str(item["key"])).get("modifiers", {})
		for key: String in values:
			var baseline: float = 1.0 if key.ends_with("_mult") else 0.0
			result[key] = float(result.get(key, baseline)) + float(values[key]) - baseline
	return result
