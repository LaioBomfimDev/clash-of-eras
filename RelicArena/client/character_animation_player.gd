extends RefCounted
## Relógios e prioridade somente de apresentação; nunca executa ataques ou dano.
## Injete um RefCounted compatível com has_animation/clip_duration/frame_data.
## Sem injeção, carrega o manifesto opcional do banco padrão.
## event_stamp deve ser único por unidade até clear(), incluindo rodada/tick/tipo.

const AnimationBank = preload("res://client/character_animation_bank.gd")
const ACTIONS: Array[String] = ["attack", "skill"]

var _bank: RefCounted
var _actions: Dictionary = {}
var _walks: Dictionary = {}
var _seen_stamps: Dictionary = {}


func _init(bank: RefCounted = null) -> void:
	_bank = bank
	if _bank == null:
		_bank = AnimationBank.new()
		_bank.call("load_assets")


## O cliente chama uma vez por quadro. Consultar frame_for não avança relógios.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	for records: Dictionary in [_actions, _walks]:
		for record: Dictionary in records.values():
			var next_elapsed: float = float(record["elapsed"]) + delta
			if is_finite(next_elapsed):
				record["elapsed"] = next_elapsed


## Chamar ao trocar rodada/partida ou recarregar assets, inclusive para limpar stamps.
func clear() -> void:
	_actions.clear()
	_walks.clear()
	_seen_stamps.clear()


## Aceita uma ação nova somente quando existe o clip exato. Não inventa direção.
## A direção aceita fica presa ao golpe, mesmo que a mira visual mude depois.
func play_action(unit_id: int, key: String, state: String, direction: String, event_stamp: String) -> bool:
	if unit_id < 0 or key.is_empty() or event_stamp.is_empty() or state not in ACTIONS:
		return false
	var seen: Dictionary = _seen_stamps.get(unit_id, {})
	if seen.has(event_stamp) or not _has_clip(key, state, direction):
		return false
	var duration: float = float(_bank.call("clip_duration", key, state, direction))
	if not is_finite(duration) or duration <= 0.0:
		return false
	_actions[unit_id] = {"key": key, "state": state, "direction": direction, "elapsed": 0.0, "duration": duration}
	_walks.erase(unit_id)
	seen[event_stamp] = true
	_seen_stamps[unit_id] = seen
	return true


## Snapshot mínimo: id/key; alive/active verdadeiros e stun_remaining zero.
## Retorna o frame do banco mais state, ou {} para o idle já existente do cliente.
func frame_for(unit: Dictionary, direction: String, walking: bool) -> Dictionary:
	var unit_id: int = int(unit.get("id", -1))
	var key: String = str(unit.get("key", ""))
	var stun: float = float(unit.get("stun_remaining", 0.0))
	if unit_id < 0 or key.is_empty() or not bool(unit.get("alive", true)) or not bool(unit.get("active", true)) or not is_finite(stun) or stun > 0.0:
		_actions.erase(unit_id)
		_walks.erase(unit_id)
		return {}
	var action: Dictionary = _actions.get(unit_id, {})
	if not action.is_empty():
		if str(action["key"]) == key and float(action["elapsed"]) < float(action["duration"]):
			var action_frame: Dictionary = _frame(key, str(action["state"]), str(action["direction"]), float(action["elapsed"]))
			if not action_frame.is_empty():
				return action_frame
		_actions.erase(unit_id)
	if not walking or not _has_clip(key, "walk", direction):
		_walks.erase(unit_id)
		# Pose opcional com os pés no chão: a pedra do retrato não reaparece
		# entre passos/golpes. Continua exigindo uma direção realmente exportada.
		if _has_clip(key, "stance", direction):
			return _frame(key, "stance", direction, 0.0)
		return {}
	var walk: Dictionary = _walks.get(unit_id, {})
	if walk.is_empty() or str(walk["key"]) != key or str(walk["direction"]) != direction:
		walk = {"key": key, "direction": direction, "elapsed": 0.0}
		_walks[unit_id] = walk
	return _frame(key, "walk", direction, float(walk["elapsed"]))


func _has_clip(key: String, state: String, direction: String) -> bool:
	if direction.is_empty() or _bank == null:
		return false
	for method: String in ["has_animation", "clip_duration", "frame_data"]:
		if not _bank.has_method(method):
			return false
	return bool(_bank.call("has_animation", key, state, direction))


func _frame(key: String, state: String, direction: String, elapsed: float) -> Dictionary:
	var raw: Variant = _bank.call("frame_data", key, state, direction, elapsed)
	if not raw is Dictionary or raw.is_empty():
		return {}
	var result: Dictionary = raw.duplicate()
	result["state"] = state
	return result
