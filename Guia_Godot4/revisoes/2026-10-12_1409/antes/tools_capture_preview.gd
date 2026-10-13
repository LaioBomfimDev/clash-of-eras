extends SceneTree
## Captura somente o viewport deste jogo; não lê tela, navegador ou outros apps.
## Uso: Godot --path RelicArena --script res://tools/capture_preview.gd -- [--menu|--benefit|--items|--combat|--result] [--levels|--kits|--vfx|--support-vfx]

const Board = preload("res://client/board_projection.gd")
var finished: bool = false

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	create_timer(20).timeout.connect(func() -> void:
		if not finished:
			push_error("Captura do viewport excedeu 20 segundos.")
			quit(1))
	if DisplayServer.get_name() == "headless":
		push_error("A captura requer renderizador; testes de regras usam --headless.")
		quit(1)
		return
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		quit(1)
		return
	var view: Node = scene.instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.audio.set_enabled(false)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = "preparacao"
	if "--menu" in args:
		mode = "menu"
	elif "--heroes" in args:
		mode = "compendio_herois"
		view.set("lobby_subview", "heroes")
		view.set("lobby_signature", "")
		view.call("_refresh")
	elif "--settings" in args:
		mode = "configuracoes"
		view.set("lobby_subview", "settings")
		view.set("lobby_signature", "")
		view.call("_refresh")
	else:
		view.call("_start_match")
		if "--benefit" in args:
			mode = "beneficio"
		else:
			for option: Dictionary in view.state.get("own", {}).get("benefit_options", []):
				if option.get("kind", "") == "gold":
					view.call("_command", "choose_benefit", {"option_id": option["option_id"]})
					break
			view.call("_select_unit", 5)
			if "--kits" in args or "--vfx" in args or "--support-vfx" in args:
				if not _configure_kits(view, "--vfx" in args):
					view.queue_free()
					quit(1)
					return
				view.call("_select_unit", 10)
				mode = "lote03_preparacao"
				if "--support-vfx" in args:
					mode = "support_preparacao"
			if "--levels" in args:
				## Somente captura: injeta cópias grátis na loja local para mostrar níveis 2 e 3.
				for upgrade: Array in [["neymar", 1], ["obama", 1], ["obama", 2]]:
					view.session.teams[0]["shop"][3] = view.session._offer(0, 3, "hero", upgrade[0], view.specs[upgrade[0]].display_name, 0)
					view.session.teams[0]["shop"][3]["offer_id"] += ":captura%d" % int(upgrade[1])
					view.call("_command", "recruit", {"offer_id": view.session.teams[0]["shop"][3]["offer_id"]})
				view.call("_select_unit", 3)
				for index: int in range(16):
					view.call("_update_visuals", 0.05)
				mode = "niveis"
			if "--items" in args:
				mode = "itens"
				view.call("_command", "buy_item", {"offer_id": view.state["own"]["shop"][0]["offer_id"]})
				view.call("_command", "buy_item", {"offer_id": view.state["own"]["shop"][1]["offer_id"]})
				view.call("_select_unit", 1)
				view.call("_select_item", str(view.state["own"]["bag"][0]["id"]))
				view.call("_equip_selected")
				view.call("_select_item", str(view.state["own"]["bag"][0]["id"]))
			elif "--combat" in args or "--result" in args:
				mode = "combate"
				view.call("_fight")
				var frames: int = 700 if "--result" in args else (180 if "--vfx" in args or "--support-vfx" in args else 90)
				for index: int in range(frames):
					view.call("_process", 0.05)
					if view.call("_phase") in ["round_result", "match_over"]:
						break
					## Com --ball, para no primeiro quadro em que uma bola está no ar.
					if "--ball" in args and index > 20 and not view.state.get("combat", {}).get("projectiles", []).is_empty():
						break
					if "--vfx" in args and "--result" not in args:
						var keys: Dictionary = {}
						var rocket_peak: bool = false
						for effect: Dictionary in view.kit_effects:
							var key: String = str(effect.get("library_key", ""))
							var effect_data: Dictionary = view.call("_library_effect_data", effect)
							if not key.is_empty() and not effect_data.is_empty():
								keys[key] = true
								if key == "foguete_01" and int(effect_data["frame_index"]) in [5, 6, 7]:
									rocket_peak = true
						var shield_count: int = 0
						for unit: Dictionary in view.state.get("combat", {}).get("units", []):
							if not view.call("_dance_vfx_data", unit).is_empty():
								shield_count += 1
						if keys.size() >= 2 and shield_count > 0 and ("--rocket" not in args or rocket_peak):
							break
					if "--support-vfx" in args and "--result" not in args:
						var knot_visible: bool = false
						for effect: Dictionary in view.kit_effects:
							if effect.get("library_key", "") != "laco_01":
								continue
							var knot: Dictionary = view.call("_library_effect_data", effect)
							if not knot.is_empty() and int(knot["frame_index"]) in [2, 3, 4, 5, 6, 7, 8]:
								knot_visible = true
						if knot_visible and not view.call("_smoke_vfx_frames").is_empty():
							break
				if "--result" in args:
					mode = "resultado"
				if "--levels" in args:
					mode = "niveis_combate"
				if "--kits" in args:
					mode = "lote03_" + ("resultado" if "--result" in args else "combate")
				if "--vfx" in args:
					mode = "vfx_" + ("resultado" if "--result" in args else "combate")
					if "--rocket" in args:
						mode += "_foguete"
				if "--support-vfx" in args:
					mode = "support_" + ("resultado" if "--result" in args else "combate")
	view.call("_refresh")
	view.call("_prepare_frame")
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(folder)
	var path: String = folder.path_join("v1_4_" + mode + ".png")
	var frame: Image = root.get_texture().get_image()
	if frame == null or frame.is_empty():
		push_error("Viewport sem imagem.")
		quit(1)
		return
	var result: Error = frame.save_png(path)
	var prop_report: Array[Dictionary] = []
	for prop: Dictionary in view.arena_props:
		var ground_point: Vector2 = prop["ground"]
		var foot: Vector2 = Board.project(ground_point)
		prop_report.append({"path": prop["texture"].resource_path, "ground": [ground_point.x, ground_point.y], "foot": [foot.x, foot.y], "outside_grid": Board.pick_cell(foot) == Board.INVALID})
	var report: FileAccess = FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE)
	if report != null:
		var native_effects: Array[Dictionary] = []
		for effect: Dictionary in view.kit_effects:
			var data: Dictionary = view.call("_library_effect_data", effect)
			if not data.is_empty():
				native_effects.append({"key": effect["library_key"], "kind": effect["kind"], "frame": data["frame_index"], "position": [data["position"].x, data["position"].y], "target_id": effect["target_id"], "depth": effect["depth"]})
		var wire_report: Array[Dictionary] = []
		for effect: Dictionary in view.kit_effects:
			if effect.get("kind", "") != "lasso":
				continue
			var points: PackedVector2Array = view.call("_lasso_points", effect)
			var target: Dictionary = view.call("_unit_by_id", int(effect.get("target_id", -1)))
			var source: Dictionary = view.call("_unit_by_id", int(effect.get("source_id", -1)))
			var body_point: Vector2 = Board.project(view.call("_ground_of", target)) + Vector2(0, -21) if not target.is_empty() else points[-1]
			var source_point: Vector2 = Board.project(view.call("_ground_of", source)) + Vector2(0, -21) if not source.is_empty() else points[0]
			wire_report.append({"target_id": effect.get("target_id", -1), "source_id": effect.get("source_id", -1), "tip": [points[-1].x, points[-1].y], "body": [body_point.x, body_point.y], "tip_error_px": points[-1].distance_to(body_point), "source_error_px": points[0].distance_to(source_point)})
		var cloud_report: Array[Dictionary] = []
		for zone: Dictionary in view.state.get("combat", {}).get("zones", []):
			var cell: Vector2i = view.call("_cell", zone.get("cell", []))
			var data: Dictionary = view.call("_smoke_vfx_data", zone)
			cloud_report.append({"zone_id": zone.get("id", -1), "source_id": zone.get("source_id", -1), "cell": [cell.x, cell.y], "radius": zone.get("radius", 0), "remaining": zone.get("remaining", 0), "duration": zone.get("duration", 0), "native_drawn": not data.is_empty(), "frame": data.get("frame_index", -1), "scale": data.get("scale", 0)})
		var pull_report: Array[Dictionary] = []
		for target_id: int in view.visual_pulls:
			var pull: Dictionary = view.visual_pulls[target_id]
			pull_report.append({"target_id": target_id, "from": [pull["from"].x, pull["from"].y], "to": [pull["to"].x, pull["to"].y], "remaining": pull["remaining"], "duration": pull["duration"]})
		var shield_ids: Array[int] = []
		for unit: Dictionary in view.state.get("combat", {}).get("units", []):
			if not view.call("_dance_vfx_data", unit).is_empty():
				shield_ids.append(int(unit["id"]))
		report.store_string(JSON.stringify({"viewport": [frame.get_width(), frame.get_height()], "phase": view.call("_phase"), "elapsed": view.state.get("elapsed", 0), "props": prop_report, "effects": view.kit_effects.map(func(effect: Dictionary) -> String: return str(effect["kind"])), "native_vfx": native_effects, "native_clouds": cloud_report, "visual_pulls": pull_report, "lasso_wires": wire_report, "native_dance_shield_ids": shield_ids, "projectiles": view.state.get("combat", {}).get("projectiles", [])}, "\t"))
		report.close()
	print("VIEWPORT_CAPTURE: %s; result=%s" % [path, result])
	finished = true
	view.queue_free()
	await process_frame
	quit(0 if result == OK else 1)


## Somente diagnóstico: usa comandos válidos, sem modificar dano, vida ou resultado.
func _configure_kits(view: Node, include_vfx: bool = false) -> bool:
	var lineups: Array = [["barbie", "elon", "snoop", "lula", "bob_marley"], ["rapunzel", "neymar", "obama", "caramelo", "michael"]]
	if include_vfx:
		lineups = [["zumbi", "elon", "obama", "caramelo", "michael"], ["barbie", "neymar", "lula", "snoop", "michael"]]
	var command: int = 0
	for team: int in range(2):
		if int(view.session.teams[team]["capacity"]) < 5:
			command += 1
			if not bool(view.session.apply_command(team, "capture_kits_%d" % command, "upgrade_capacity").get("ok", false)):
				return false
		for unit in view.session.sim.units:
			if unit.team == team and unit.active and not lineups[team].has(unit.key):
				command += 1
				if not bool(view.session.apply_command(team, "capture_kits_%d" % command, "bench", {"unit_id": unit.id}).get("ok", false)):
					return false
		for key: String in lineups[team]:
			if (view.session.teams[team]["owned"] as Array).has(key):
				continue
			command += 1
			view.session.teams[team]["shop"][3] = view.session._offer(team, 3, "hero", key, view.specs[key].display_name, 0)
			view.session.teams[team]["shop"][3]["offer_id"] += ":capture%d" % command
			if not bool(view.session.apply_command(team, "capture_kits_%d" % command, "recruit", {"offer_id": view.session.teams[team]["shop"][3]["offer_id"]}).get("ok", false)):
				return false
	view.call("_consume_events")
	view.call("_refresh")
	view.call("_update_visuals", 1.0)
	return true
