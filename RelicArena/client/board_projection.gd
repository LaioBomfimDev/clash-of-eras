extends RefCounted
## Câmera inclinada em perspectiva. Somente apresentação: a simulação continua em (coluna, fileira).
## "Chão" usa largura de hexágono = 1; profundidade 0 é a fileira mais próxima da câmera (7).

const CENTER_X: float = 648.0
const FRONT_Y: float = 448.0
const FRONT_HEX_WIDTH: float = 76.0
## Quanto o tabuleiro encolhe com a distância (fileira do fundo ≈ 79% da frente).
const DEPTH_FALLOFF: float = 0.0426
## Altura da câmera: controla a inclinação (achatamento vertical ≈ 0,62 na frente).
const CAMERA_HEIGHT: float = 14.5
const ROW_DEPTH: float = 0.8660254
const HEX_RADIUS: float = 0.5773503
const BENCH_DEPTH: float = -1.5
const BENCH_SLOTS: int = 5
const BENCH_SPACING: float = 1.15
const INVALID: Vector2i = Vector2i(-1, -1)


static func ground(cell: Vector2i) -> Vector2:
	return Vector2(cell.x + 0.5 * float(cell.y & 1) - 3.75, (7 - cell.y) * ROW_DEPTH)


static func scale_at(depth: float) -> float:
	return 1.0 / (1.0 + DEPTH_FALLOFF * depth)


static func project(point: Vector2) -> Vector2:
	var scale: float = scale_at(point.y)
	return Vector2(CENTER_X + point.x * FRONT_HEX_WIDTH * scale, FRONT_Y - CAMERA_HEIGHT * FRONT_HEX_WIDTH * (1.0 - scale))


static func cell_position(cell: Vector2i) -> Vector2:
	return project(ground(cell))


static func cell_scale(cell: Vector2i) -> float:
	return scale_at(ground(cell).y)


static func hex_polygon(cell: Vector2i, inset: float = 0.0) -> PackedVector2Array:
	return _hex_around(ground(cell), 1.0 - inset)


static func _hex_around(center: Vector2, size: float) -> PackedVector2Array:
	var radius: float = HEX_RADIUS * size
	var half: float = 0.5 * size
	var points: PackedVector2Array = PackedVector2Array()
	for offset: Vector2 in [Vector2(0, radius), Vector2(half, radius * 0.5), Vector2(half, -radius * 0.5),
			Vector2(0, -radius), Vector2(-half, -radius * 0.5), Vector2(-half, radius * 0.5)]:
		points.append(project(center + offset))
	return points


static func ellipse(center_ground: Vector2, radius_x: float, radius_depth: float, segments: int = 24) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(segments):
		var angle: float = TAU * index / segments
		points.append(project(center_ground + Vector2(cos(angle) * radius_x, sin(angle) * radius_depth)))
	return points


static func pick_cell(point: Vector2) -> Vector2i:
	for row: int in range(8):
		for column: int in range(8):
			var cell: Vector2i = Vector2i(column, row)
			if Geometry2D.is_point_in_polygon(point, hex_polygon(cell)):
				return cell
	return INVALID


static func bench_ground(slot: int) -> Vector2:
	return Vector2((slot - (BENCH_SLOTS - 1) * 0.5) * BENCH_SPACING, BENCH_DEPTH)


static func bench_position(slot: int) -> Vector2:
	return project(bench_ground(slot))


static func bench_polygon(slot: int) -> PackedVector2Array:
	return _hex_around(bench_ground(slot), 0.92)


static func pick_bench(point: Vector2) -> int:
	for slot: int in range(BENCH_SLOTS):
		if Geometry2D.is_point_in_polygon(point, bench_polygon(slot)):
			return slot
	return -1


## Vetor "de tela sem achatamento" para escolher uma das oito direções do sprite.
static func facing_vector(from_ground: Vector2, to_ground: Vector2) -> Vector2:
	var delta: Vector2 = to_ground - from_ground
	return Vector2(delta.x, -delta.y)


static func axial_facing_vector(axial: Vector2i) -> Vector2:
	## Eixo axial (q, r) de hexágonos pontudos: x = q + r/2, profundidade diminui com r.
	return Vector2(axial.x + axial.y * 0.5, axial.y * ROW_DEPTH)


## Arestas externas da grade, sem duplicar as compartilhadas. Não altera seleção ou combate.
static func perimeter_segments() -> Array[PackedVector2Array]:
	var counts: Dictionary = {}
	var segments: Dictionary = {}
	for row: int in range(8):
		for column: int in range(8):
			var polygon: PackedVector2Array = hex_polygon(Vector2i(column, row))
			for index: int in range(6):
				var a: Vector2 = polygon[index]
				var b: Vector2 = polygon[(index + 1) % 6]
				var hash_a: String = "%d:%d" % [roundi(a.x * 100), roundi(a.y * 100)]
				var hash_b: String = "%d:%d" % [roundi(b.x * 100), roundi(b.y * 100)]
				var key: String = hash_a + "/" + hash_b if hash_a < hash_b else hash_b + "/" + hash_a
				counts[key] = int(counts.get(key, 0)) + 1
				segments[key] = PackedVector2Array([a, b])
	var result: Array[PackedVector2Array] = []
	for key: String in counts:
		if int(counts[key]) == 1:
			result.append(segments[key])
	return result
