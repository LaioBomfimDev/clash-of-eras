extends RefCounted
## Converte coordenadas e índices de time entre a sessão autoritativa do servidor
## e a perspectiva local do cliente (onde o próprio jogador é sempre time 0, linhas 4..7).

const Grid = preload("res://simulation/hex_grid.gd")


static func flip_team(team: int) -> int:
	if team == 0:
		return 1
	if team == 1:
		return 0
	return team


static func flip_cell_vec(cell: Vector2i) -> Vector2i:
	if not Grid.contains(cell):
		return cell
	return Vector2i(Grid.WIDTH - 1 - cell.x, Grid.HEIGHT - 1 - cell.y)


static func flip_cell_variant(value: Variant) -> Variant:
	if value is Vector2i:
		return flip_cell_vec(value)
	if value is Array and value.size() == 2:
		var cx: int = int(value[0])
		var cy: int = int(value[1])
		if Grid.contains(Vector2i(cx, cy)):
			return [Grid.WIDTH - 1 - cx, Grid.HEIGHT - 1 - cy]
		return [cx, cy]
	return value


static func from_client_payload(payload: Dictionary, team: int) -> Dictionary:
	if team == 0:
		return payload.duplicate(true)
	var mapped: Dictionary = payload.duplicate(true)
	if mapped.has("cell"):
		mapped["cell"] = flip_cell_variant(mapped["cell"])
	return mapped


static func to_client_snapshot(snapshot: Dictionary, team: int) -> Dictionary:
	if team == 0 or snapshot.is_empty():
		return snapshot.duplicate(true)
	var out: Dictionary = snapshot.duplicate(true)
	if out.has("lives") and out["lives"] is Array and (out["lives"] as Array).size() == 2:
		var lives_arr: Array = out["lives"]
		out["lives"] = [int(lives_arr[1]), int(lives_arr[0])]
	if out.has("match_winner"):
		out["match_winner"] = flip_team(int(out["match_winner"]))
	if out.has("own") and out["own"] is Dictionary:
		var own: Dictionary = out["own"]
		if own.has("units") and own["units"] is Array:
			var mapped_own: Array[Dictionary] = []
			for u: Variant in own["units"]:
				if u is Dictionary:
					mapped_own.append(_map_unit(u))
			own["units"] = mapped_own
	if out.has("enemy") and out["enemy"] is Dictionary:
		var enemy: Dictionary = out["enemy"]
		if enemy.has("units") and enemy["units"] is Array:
			var mapped_enemy: Array[Dictionary] = []
			for u: Variant in enemy["units"]:
				if u is Dictionary:
					mapped_enemy.append(_map_unit(u))
			enemy["units"] = mapped_enemy
	if out.has("combat") and out["combat"] is Dictionary:
		var combat: Dictionary = out["combat"]
		if not combat.is_empty():
			if combat.has("units") and combat["units"] is Array:
				var mapped_combat_units: Array[Dictionary] = []
				for u: Variant in combat["units"]:
					if u is Dictionary:
						mapped_combat_units.append(_map_unit(u))
				combat["units"] = mapped_combat_units
			if combat.has("projectiles") and combat["projectiles"] is Array:
				var mapped_proj: Array[Dictionary] = []
				for p: Variant in combat["projectiles"]:
					if p is Dictionary:
						var p_copy: Dictionary = (p as Dictionary).duplicate(true)
						if p_copy.has("from_cell"):
							p_copy["from_cell"] = flip_cell_variant(p_copy["from_cell"])
						if p_copy.has("to_cell"):
							p_copy["to_cell"] = flip_cell_variant(p_copy["to_cell"])
						mapped_proj.append(p_copy)
				combat["projectiles"] = mapped_proj
			if combat.has("zones") and combat["zones"] is Array:
				var mapped_zones: Array[Dictionary] = []
				for z: Variant in combat["zones"]:
					if z is Dictionary:
						var z_copy: Dictionary = (z as Dictionary).duplicate(true)
						if z_copy.has("team"):
							z_copy["team"] = flip_team(int(z_copy["team"]))
						if z_copy.has("cell"):
							z_copy["cell"] = flip_cell_variant(z_copy["cell"])
						mapped_zones.append(z_copy)
				combat["zones"] = mapped_zones
			if combat.has("synergy_snapshot") and combat["synergy_snapshot"] is Array:
				var syn: Array = combat["synergy_snapshot"]
				if syn.size() == 2:
					combat["synergy_snapshot"] = [syn[1], syn[0]]
			if combat.has("result") and combat["result"] is Dictionary and not (combat["result"] as Dictionary).is_empty():
				combat["result"] = _map_round_result(combat["result"])
	return out


static func to_client_events(events: Array, team: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw: Variant in events:
		if not raw is Dictionary:
			continue
		var ev: Dictionary = (raw as Dictionary).duplicate(true)
		if team == 1:
			if ev.has("team"):
				ev["team"] = flip_team(int(ev["team"]))
			for field: String in ["cell", "from", "to"]:
				if ev.has(field):
					ev[field] = flip_cell_variant(ev[field])
			if str(ev.get("type", "")) == "round_finished":
				ev = _map_round_result(ev)
		out.append(ev)
	return out


static func _map_unit(unit: Dictionary) -> Dictionary:
	var u: Dictionary = unit.duplicate(true)
	if u.has("team"):
		u["team"] = flip_team(int(u["team"]))
	for field: String in ["cell", "moonwalk_from_cell", "moonwalk_to_cell"]:
		if u.has(field):
			u[field] = flip_cell_variant(u[field])
	if u.has("facing_axial") and u["facing_axial"] is Array and (u["facing_axial"] as Array).size() == 2:
		var fa: Array = u["facing_axial"]
		u["facing_axial"] = [-int(fa[0]), -int(fa[1])]
	return u


static func _map_round_result(result: Dictionary) -> Dictionary:
	var r: Dictionary = result.duplicate(true)
	if r.has("winner"):
		r["winner"] = flip_team(int(r["winner"]))
	if r.has("survivors") and r["survivors"] is Array and (r["survivors"] as Array).size() == 2:
		var s: Array = r["survivors"]
		r["survivors"] = [int(s[1]), int(s[0])]
	if r.has("damage") and r["damage"] is Array and (r["damage"] as Array).size() == 2:
		var d: Array = r["damage"]
		r["damage"] = [float(d[1]), float(d[0])]
	if r.has("units_summary") and r["units_summary"] is Array:
		var summaries: Array[Dictionary] = []
		for item: Variant in r["units_summary"]:
			if item is Dictionary:
				var item_copy: Dictionary = (item as Dictionary).duplicate(true)
				if item_copy.has("team"):
					item_copy["team"] = flip_team(int(item_copy["team"]))
				summaries.append(item_copy)
		r["units_summary"] = summaries
	return r
