extends SceneTree
## Fixture de apresentação para BUG-017; não modifica regras nem dados da Session.

const Board = preload("res://client/board_projection.gd")
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> bool:
	if not ok:
		failures += 1
		push_error("LASSO_REPRO_FAIL: " + label)
	return ok

func _legacy_points(effect: Dictionary) -> PackedVector2Array:
	# Fórmula copiada literalmente do desenho anterior para preservar a evidência.
	var progress: float = 1.0 - float(effect["life"]) / float(effect["duration"])
	var from: Vector2 = effect["from"]
	var to: Vector2 = (effect["position"] as Vector2).lerp(effect["destination"], minf(1.0, progress * 1.83))
	var points: PackedVector2Array = PackedVector2Array()
	for seg: int in range(13):
		var t: float = float(seg) / 12.0
		var mid: Vector2 = from.lerp(to, t)
		var sway: float = sin(t * PI * 3.0 + progress * 8.0) * (6.0 * (1.0 - progress))
		var normal: Vector2 = (to - from).normalized().orthogonal()
		points.append(mid + normal * sway)
	return points

func _xy(point: Vector2) -> Array:
	return [point.x, point.y]

func _run() -> void:
	var after: bool = "--after" in OS.get_cmdline_user_args()
	var view: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.audio.set_enabled(false)
	view.call("_start_match")
	for option: Dictionary in view.state.get("own", {}).get("benefit_options", []):
		if option.get("kind", "") == "gold":
			view.call("_command", "choose_benefit", {"option_id": option["option_id"]})
			break
	var source: Dictionary = view.call("_unit_by_id", 1).duplicate(true)
	var target: Dictionary = view.call("_unit_by_id", 3).duplicate(true)
	if not _check(not source.is_empty() and not target.is_empty(), "unidades disponíveis"):
		view.queue_free()
		await process_frame
		quit(1)
		return
	var before_core: String = JSON.stringify(view.session.sim.snapshot())
	source["key"] = "rapunzel"
	source["cell"] = [1, 4]
	source["active"] = true
	source["alive"] = true
	target["cell"] = [2, 4]
	target["stun_remaining"] = 1.0
	target["active"] = true
	target["alive"] = true
	view.state["phase"] = "combat"
	view.state["combat"] = {"units": [source, target], "zones": []}
	view.visual_ground.clear()
	view.kit_effects.clear()
	view.call("_spawn_kit_feedback", {"type": "lasso", "from": [7, 0], "to": [2, 4]}, source, target)
	var wire: Dictionary = {}
	var knot: Dictionary = {}
	for effect: Dictionary in view.kit_effects:
		if effect.get("kind", "") == "lasso":
			wire = effect
		if effect.get("kind", "") == "lasso_knot":
			knot = effect
	if not _check(not wire.is_empty() and not knot.is_empty(), "fio e nó criados"):
		view.queue_free()
		await process_frame
		quit(1)
		return
	var samples: Array[Dictionary] = []
	var max_tip_error: float = 0.0
	var max_source_error: float = 0.0
	for frame: int in range(1, 7):
		view.call("_update_visuals", 0.05)
		var points: PackedVector2Array = view.call("_lasso_points", wire) if after and view.has_method("_lasso_points") else _legacy_points(wire)
		var body_point: Vector2 = Board.project(view.call("_ground_of", target)) + Vector2(0, -21)
		var source_point: Vector2 = Board.project(view.call("_ground_of", source)) + Vector2(0, -21)
		var native: Dictionary = view.call("_library_effect_data", knot)
		var tip_error: float = points[-1].distance_to(body_point)
		var source_error: float = points[0].distance_to(source_point)
		max_tip_error = maxf(max_tip_error, tip_error)
		max_source_error = maxf(max_source_error, source_error)
		samples.append({"seconds": frame * 0.05, "body": _xy(body_point), "knot": _xy(native.get("position", Vector2.ZERO)), "wire_tip": _xy(points[-1]), "wire_source": _xy(points[0]), "source": _xy(source_point), "tip_error_px": tip_error, "source_error_px": source_error})
		print("LASSO_SAMPLE t=%.2f tip_error=%.4f source_error=%.4f" % [frame * 0.05, tip_error, source_error])
	_check(JSON.stringify(view.session.sim.snapshot()) == before_core, "fixture não alterou núcleo")
	if after:
		_check(view.has_method("_lasso_points"), "usa pontos reais do desenho corrigido")
		_check(max_tip_error < 0.001 and max_source_error < 0.001, "extremidades ancoradas durante todo o puxão")
	else:
		_check(max_tip_error > 10.0, "defeito da ponta reproduzido")
		_check(max_source_error > 1.0, "ondulação deslocava também a origem")
	var report: Dictionary = {"mode": "after" if after else "before", "godot": Engine.get_version_info()["string"], "fixture": "visual-only lasso [7,0] -> [2,4], six steps of 0.05s", "samples": samples, "max_tip_error_px": max_tip_error, "max_source_error_px": max_source_error, "core_unchanged": JSON.stringify(view.session.sim.snapshot()) == before_core, "failures": failures}
	var suffix: String = "depois" if after else "antes"
	var output: FileAccess = FileAccess.open("res://captures/v1_4_bug017_repro_" + suffix + ".json", FileAccess.WRITE)
	if _check(output != null, "recibo JSON gravável"):
		output.store_string(JSON.stringify(report, "\t") + "\n")
		output.close()
	print("LASSO_REPRO_RESULT: mode=%s failures=%d max_tip=%.4f max_source=%.4f" % [suffix, failures, max_tip_error, max_source_error])
	view.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
