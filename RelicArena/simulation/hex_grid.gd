extends RefCounted
## Pointy hexagons, odd rows shifted right. Public cells are (column, row).

const WIDTH: int = 8
const HEIGHT: int = 8
const INVALID: Vector2i = Vector2i(-100, -100)
const AXIAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

static func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and cell.y < HEIGHT

static func offset_to_axial(cell: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	var shift: int = (cell.y - (cell.y & 1)) / 2
	return Vector2i(cell.x - shift, cell.y)

static func axial_to_offset(axial: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	var shift: int = (axial.y - (axial.y & 1)) / 2
	return Vector2i(axial.x + shift, axial.y)

static func distance(a: Vector2i, b: Vector2i) -> int:
	var difference: Vector2i = offset_to_axial(a) - offset_to_axial(b)
	return maxi(absi(difference.x), maxi(absi(difference.y), absi(difference.x + difference.y)))

static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var axial: Vector2i = offset_to_axial(cell)
	for direction: Vector2i in AXIAL_DIRECTIONS:
		var candidate: Vector2i = axial_to_offset(axial + direction)
		if contains(candidate):
			result.append(candidate)
	return result

static func belongs_to_team(cell: Vector2i, team: int) -> bool:
	if not contains(cell):
		return false
	return cell.y >= 4 if team == 0 else cell.y < 4

static func next_step(origin: Vector2i, target: Vector2i, attack_range: int, occupied: Dictionary) -> Vector2i:
	if distance(origin, target) <= attack_range:
		return origin
	var queue: Array[Vector2i] = [origin]
	var came_from: Dictionary = {origin: origin}
	var cursor: int = 0
	var goal: Vector2i = INVALID
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		if distance(current, target) <= attack_range:
			goal = current
			break
		for candidate: Vector2i in neighbors(current):
			if came_from.has(candidate) or occupied.has(candidate):
				continue
			came_from[candidate] = current
			queue.append(candidate)
	if goal == INVALID:
		return origin
	while came_from[goal] != origin:
		goal = came_from[goal]
	return goal
