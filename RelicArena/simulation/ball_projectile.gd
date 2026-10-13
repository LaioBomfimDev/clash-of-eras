extends RefCounted
## One kick, one finite A -> B -> A projectile. No recursive attacks.
## kind: ball (Neymar, ricochete), rocket (Elon, explosão em área) ou smoke (Snoop, nuvem).

var id: int = 0
var source_id: int = -1
var target_id: int = -1
var primary_id: int = -1
var secondary_id: int = -1
var from_cell: Vector2i
var to_cell: Vector2i
var flight_left: float = 0.0
var flight_duration: float = 0.0
var impacts: int = 0
var total_impacts: int = 3
var raw_damage: float = 0.0
var critical: bool = false
var damage_type: String = "physical"
var kind: String = "ball"
var decay_multipliers: Array[float] = []

func as_dictionary() -> Dictionary:
	return {
		"id": id, "source_id": source_id, "target_id": target_id,
		"primary_id": primary_id, "secondary_id": secondary_id,
		"from_cell": [from_cell.x, from_cell.y], "to_cell": [to_cell.x, to_cell.y],
		"flight_left": flight_left, "flight_duration": flight_duration,
		"impacts": impacts, "total_impacts": total_impacts,
		"critical": critical, "raw_damage": raw_damage, "damage_type": damage_type, "kind": kind,
		"decay_multipliers": decay_multipliers.duplicate()
	}
