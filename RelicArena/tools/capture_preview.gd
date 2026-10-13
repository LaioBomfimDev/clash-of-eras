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
		if "--elon" in args:
			view.set("lobby_selected_hero_key", "elon")
			view.set("visual_time", 2.2)
			mode += "_elon_explosao"
		elif "--barbie" in args:
			view.set("lobby_selected_hero_key", "barbie")
			view.set("visual_time", 2.0)
			mode += "_barbie_ken"
		elif "--michael" in args:
			view.set("lobby_selected_hero_key", "michael")
			if "--shield" in args:
				view.set("visual_time", 2.7)
				mode += "_michael_escudo"
			else:
				view.set("visual_time", 1.8)
				mode += "_michael_moonwalk"
		elif "--zumbi" in args:
			view.set("lobby_selected_hero_key", "zumbi")
			if "--skill" in args:
				view.set("visual_time", 0.5)
				mode += "_zumbi_skill"
			elif "--walk" in args:
				view.set("visual_time", 1.5)
				mode += "_zumbi_walk"
			else:
				view.set("visual_time", 2.8)
				mode += "_zumbi_attack"
		if "--pose" in args:
			view.set("lobby_preview_mode", "pose")
			mode += "_pose"
		if "--level-3" in args:
			view.set("lobby_preview_level", 3)
			mode += "_lvl3"
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
				var recruit_offer: Dictionary = view.state["own"]["shop"][4]
				var recruit_res: Dictionary = view.call("_command", "recruit", {"offer_id": recruit_offer["offer_id"]})
				var u_id: int = int(recruit_res.get("data", {}).get("unit_id", 1))
				view.call("_command", "deploy", {"unit_id": u_id, "cell": Vector2i(3, 5)})
				view.call("_command", "buy_item", {"offer_id": view.state["own"]["shop"][0]["offer_id"]})
				view.call("_command", "buy_item", {"offer_id": view.state["own"]["shop"][1]["offer_id"]})
				view.call("_select_unit", u_id)
				var b0: String = str(view.state["own"]["bag"][0]["id"])
				view.call("_select_item", b0)
				view.call("_equip_selected")
				var b1: String = str(view.state["own"]["bag"][0]["id"])
				view.call("_select_item", b1)
				view.call("_equip_selected")
				view.call("_prepare_frame")
				var ground: Vector2 = Board.ground(Vector2i(3, 5))
				var feet: Vector2 = Board.project(ground)
				var tex: Texture2D = view.art.texture_for("michael", "south", 0.0)
				var h: float = (view.art.height_for(tex) if tex != null else 46.0)
				view.mouse_pointer = feet + Vector2(-18, -h + 3)
				view.queue_redraw()
				await process_frame
			elif "--zumbi-items" in args:
				mode = "itens_zumbi"
				var z_id: int = 4
				if not (view.session.teams[0]["owned"] as Array).has("zumbi"):
					view.session.teams[0]["owned"].append("zumbi")
				view.session.sim.set_active(z_id, true, Vector2i(3, 5))
				var items_to_give: Array = [
					{"id": "0:item:1", "key": "vest"},
					{"id": "0:item:2", "key": "ward"},
					{"id": "0:item:3", "key": "vest"},
					{"id": "0:item:4", "key": "blade"}
				]
				view.session.teams[0]["equipment"][z_id] = items_to_give
				view.session._apply_all_equipment(0)
				view.call("_select_unit", z_id)
				view.call("_refresh")
				view.call("_prepare_frame")
				view.queue_redraw()
				await process_frame
			elif "--synergies" in args or "--hover-synergy" in args:
				mode = "hover_sinergia"
				for offer: Dictionary in view.state["own"]["shop"]:
					if offer.get("kind", "") == "hero":
						view.call("_command", "recruit", {"offer_id": offer["offer_id"]})
				var displayed: Array = view._displayed_synergies(view._phase(), view.state.get("own", {}))
				var target_group: Dictionary = {}
				for g: Dictionary in displayed:
					if g.get("key", "") == "atiradores":
						target_group = g
						break
				if target_group.is_empty() and not displayed.is_empty():
					target_group = displayed[0]
				view.call("_show_synergy_hover", target_group, 112.0)
				view.queue_redraw()
				view.units_layer.queue_redraw()
				view.overlay_layer.queue_redraw()
				await process_frame
			elif "--hover-shop" in args:
				mode = "hover_loja"
				if not view.shop_buttons.is_empty():
					var keys: Array = view.shop_buttons.keys()
					var chosen_key: String = keys[mini(4, keys.size() - 1)]
					var target_btn: Button = view.shop_buttons[chosen_key]
					var center_pt: Vector2 = target_btn.get_global_rect().get_center()
					view.get_viewport().warp_mouse(center_pt)
					DisplayServer.warp_mouse(Vector2i(center_pt))
					var mm: InputEventMouseMotion = InputEventMouseMotion.new()
					mm.position = center_pt
					mm.global_position = center_pt
					view.get_viewport().push_input(mm)
			elif "--enemy-items" in args:
				mode = "itens_inimigo"
				for offer: Dictionary in view.state["own"]["shop"]:
					if offer.get("kind", "") == "hero":
						view.call("_command", "recruit", {"offer_id": offer["offer_id"]})
						break
				var bot_heroes: Array = []
				for u in view.session.sim.units:
					if u.team == 1 and u.active:
						bot_heroes.append(u)
				if not bot_heroes.is_empty():
					var bot_u = bot_heroes[0]
					var item_obj: Dictionary = {"id": "1:item:99", "key": "guard_vest"}
					view.session.teams[1]["equipment"][bot_u.id] = [item_obj]
				view.call("_fight")
				view.call("_process", 0.05)
				var enemy_id_with_item: int = -1
				for u: Dictionary in view.state.get("combat", {}).get("units", []):
					if int(u.get("team", 0)) == 1 and not (u.get("equipment", []) as Array).is_empty():
						enemy_id_with_item = int(u["id"])
						break
				if enemy_id_with_item >= 0:
					view.call("_select_unit", enemy_id_with_item)
				view.call("_prepare_frame")
				view.queue_redraw()
				view.units_layer.queue_redraw()
				await process_frame
				for hover_entry: Dictionary in view.world_item_hover_rects:
					if int(hover_entry.get("team", 0)) == 1:
						var r: Rect2 = hover_entry["rect"]
						view.mouse_pointer = r.get_center()
						break
				view.queue_redraw()
				view.units_layer.queue_redraw()
				await process_frame
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
					## Com --flight, para quando um foguete e um anel de fumaça estão no ar ao mesmo tempo.
					if "--flight" in args and index > 20:
						var flying: Array = view.state.get("combat", {}).get("projectiles", []).map(func(p: Dictionary) -> String: return str(p.get("kind", "")))
						if "rocket" in flying and "smoke" in flying:
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
								if (key == "explosao_02" and int(effect_data["frame_index"]) in [4, 5, 6, 7]) or (key == "explosao_03" and int(effect_data["frame_index"]) in [7, 8, 9]):
									rocket_peak = true
						var shield_count: int = 0
						for unit: Dictionary in view.state.get("combat", {}).get("units", []):
							if not view.call("_dance_vfx_data", unit).is_empty():
								shield_count += 1
						if keys.size() >= 2 and shield_count > 0 and ("--rocket" not in args or rocket_peak) and "--flight" not in args:
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
					if "--bot" in args:
						view.set("result_view_team", 1)
						mode += "_bot"
					view.set("overlay_signature", "")
					view.call("_refresh_overlay", view.call("_phase"))
				if "--levels" in args:
					mode = "niveis_combate"
				if "--kits" in args:
					mode = "lote03_" + ("resultado" if "--result" in args else "combate")
				if "--vfx" in args:
					mode = "vfx_" + ("resultado" if "--result" in args else "combate")
					if "--rocket" in args:
						mode += "_foguete"
					if "--flight" in args:
						mode += "_voo"
				if "--support-vfx" in args:
					mode = "support_" + ("resultado" if "--result" in args else "combate")
	view.call("_refresh")
	view.call("_prepare_frame")
	view.queue_redraw()
	view.units_layer.queue_redraw()
	view.overlay_layer.queue_redraw()
	if view.get("hero_preview_control") != null and is_instance_valid(view.get("hero_preview_control")):
		view.get("hero_preview_control").queue_redraw()
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
