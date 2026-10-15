extends Node
## Ferramenta local: nunca é registrada no protocolo de comandos do servidor.
const Session = preload("res://simulation/match_session.gd")
const Catalog = preload("res://data/character_catalog.gd")
const Items = preload("res://data/item_catalog.gd")
const PanelUI = preload("res://client/dev_panel.gd")
signal changed
signal notice(message: String)

var view: Node
var panel: CanvasLayer
var paused: bool = false
var speed: float = 1.0
var freeze_preparation: bool = false
var pending_step: float = 0.0
var _stepping_frame: bool = false
var storage_dir: String = "user://devtools"
var match_id: String = ""
var recent_events: Array[Dictionary] = []
var actions: Array[Dictionary] = []
var rounds: Array[Dictionary] = []
var modified: bool = false
var _file_counter: int = 0

func setup(main_view: Node) -> void:
	view = main_view
	panel = PanelUI.new()
	panel.lab = self
	add_child(panel)

func local_match() -> bool:
	return view != null and not view.is_online_match and not view.menu_open

func is_open() -> bool:
	return panel != null and panel.opened

func reset_clock() -> void:
	paused = false
	speed = 1.0
	pending_step = 0.0
	freeze_preparation = false
	_sync_audio()

func begin_match() -> void:
	reset_clock()
	match_id = "%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	recent_events.clear()
	actions.clear()
	rounds.clear()
	modified = false
	changed.emit()

func frame_delta(delta: float) -> float:
	_stepping_frame = false
	if not local_match():
		return delta
	_sync_audio()
	if pending_step > 0.0:
		_stepping_frame = true
		var result: float = pending_step
		pending_step = 0.0
		return result
	if paused:
		return 0.0
	return delta * speed

func simulation_delta(delta: float) -> float:
	if local_match() and freeze_preparation and not _stepping_frame and view.session.phase in ["benefit", "preparation"]:
		return 0.0
	return delta

func _sync_audio() -> void:
	if view == null or view.audio == null:
		return
	for child: Node in view.audio.get_children():
		if child is AudioStreamPlayer:
			child.stream_paused = paused and local_match()

func toggle_pause() -> void:
	if not _guard():
		return
	paused = not paused
	pending_step = 0.0
	_sync_audio()
	changed.emit()

func set_speed(value: float) -> bool:
	if not _guard() or not is_finite(value) or value < 0.1 or value > 8.0:
		return false
	speed = value
	_record("velocidade", {"valor": value})
	return true

func step_once(seconds: float) -> bool:
	if not _guard() or not is_finite(seconds) or seconds <= 0.0 or seconds > 1.0:
		return false
	paused = true
	pending_step = seconds
	changed.emit()
	return true

func _guard(preparation_only: bool = false) -> bool:
	if not local_match():
		notice.emit("Controles disponíveis somente em uma partida local contra bot.")
		return false
	if preparation_only and view.session.sim.phase != "preparation":
		notice.emit("Esta edição exige a fase de preparação.")
		return false
	return true

func new_scenario(seed_value: int, round_number: int = 1) -> bool:
	if view.is_online_match or view.lobby_subview == "matchmaking":
		notice.emit("Saia da partida/fila online antes de iniciar um teste local.")
		return false
	if seed_value == 0 or round_number < 1 or round_number > 100:
		return false
	if local_match():
		save_report("partida")
	view._start_match(seed_value)
	var s: Session = view.session
	if round_number != 1:
		s.sim.round_index = round_number
		s.sim.reset_round()
		s._open_preparation()
	paused = true
	_record("novo_cenario", {"seed": seed_value, "round": round_number})
	_refresh_view()
	notice.emit("Cenário R%d criado e pausado. Adicione heróis e inicie o combate." % round_number)
	return true

func fight() -> bool:
	if not _guard(true):
		return false
	if view.session._active_count(0) == 0:
		notice.emit("Adicione pelo menos um herói ao seu campo na aba Equipes.")
		return false
	view.session._begin_combat()
	_record("iniciar_combate")
	_refresh_view()
	return true

func next_round() -> bool:
	if not _guard() or view.session.phase != "round_result":
		notice.emit("Próximo round fica disponível após o resultado do combate.")
		return false
	view._next_round()
	_record("proximo_round")
	return true

func finish_combat() -> bool:
	if not _guard() or view.session.phase != "combat":
		return false
	# Executa as regras reais até o resultado, com duração limitada pelo editor.
	for index: int in range(6020):
		view.session.step(0.05)
		view._consume_events()
		if view.session.phase != "combat":
			break
	paused = true
	_record("simular_ate_resultado")
	_refresh_view()
	return true

func edit_team(team: int, gold: int, lives: int, capacity: int) -> bool:
	if not _guard(true) or team not in [0, 1]:
		return false
	var s: Session = view.session
	if gold < 0 or gold > 99999 or lives < 1 or lives > Session.MAX_LIVES or capacity < Session.INITIAL_CAPACITY or capacity > Session.MAX_CAPACITY or capacity < s._active_count(team):
		notice.emit("Valores inválidos: capacidade deve comportar todos os heróis ativos.")
		return false
	s.teams[team]["gold"] = gold
	s.teams[team]["capacity"] = capacity
	s.sim.team_lives[team] = lives
	_record("editar_equipe", {"team": team, "gold": gold, "lives": lives, "capacity": capacity})
	_refresh_view()
	return true

func grant_hero(team: int, key: String, level: int) -> bool:
	if not _guard(true) or team not in [0, 1] or key not in Catalog.KEYS or level < 1 or level > 3:
		return false
	var s: Session = view.session
	if s.sim.is_boss_round and team == 1:
		notice.emit("Na rodada do Boss, a equipe adversária é controlada pelo encontro.")
		return false
	var unit = s._unit_for_key(team, key)
	if unit == null:
		return false
	if not unit.active:
		if s._active_count(team) >= int(s.teams[team]["capacity"]):
			notice.emit("Campo cheio. Aumente a capacidade ou dispense um herói.")
			return false
		if not s.sim.set_active(unit.id, true, s._first_free_cell(team)):
			return false
	if key not in s.teams[team]["owned"]:
		s.teams[team]["owned"].append(key)
	s.teams[team]["copies"][key] = int(s.sim.level_rules["copies_for_level"][level - 1])
	s.sim.set_unit_level(unit.id, level)
	s._apply_all_equipment(team)
	_record("heroi", {"team": team, "key": key, "level": level})
	_refresh_view()
	return true

func grant_item(team: int, key: String) -> bool:
	if not _guard(true) or team not in [0, 1] or not Items.ITEMS.has(key):
		return false
	var s: Session = view.session
	if s.teams[team]["bag"].size() >= Session.BAG_CAPACITY:
		notice.emit("Bolsa cheia: máximo de oito itens.")
		return false
	s.teams[team]["bag"].append(s._new_item(team, key))
	_record("item_gratuito", {"team": team, "key": key})
	_refresh_view()
	return true

func dismiss_hero(unit_id: int) -> bool:
	if not _guard(true):
		return false
	var unit = view.session.sim.get_unit(unit_id)
	if unit == null:
		return false
	var result: Dictionary = view.session.apply_command(unit.team, "dev_%d" % Time.get_ticks_usec(), "dismiss", {"unit_id": unit_id})
	if not result.get("ok", false):
		notice.emit(view._error_text(str(result.get("code", ""))))
		return false
	_record("dispensar", {"unit_id": unit_id})
	_refresh_view()
	return true

func edit_unit(unit_id: int, hp: float, damage: float, armor: float, resist: float) -> bool:
	if not _guard() or view.session.phase != "combat":
		notice.emit("Atributos diretos são editáveis durante o combate e valem só nesta rodada.")
		return false
	var unit = view.session.sim.get_unit(unit_id)
	if unit == null or not unit.active or not unit.alive or unit.is_reviving:
		notice.emit("Selecione um combatente vivo.")
		return false
	for number: float in [hp, damage, armor, resist]:
		if not is_finite(number) or number < 0.0 or number > 100000.0:
			return false
	if hp < 1.0 or hp > unit.max_hp:
		notice.emit("Vida deve ficar entre 1 e a vida máxima atual do herói.")
		return false
	unit.hp = hp
	unit.attack_damage = damage
	unit.armor = armor
	unit.resist = resist
	_record("atributos_no_combate", {"unit_id": unit_id, "hp": hp, "damage": damage, "armor": armor, "resist": resist})
	_refresh_view()
	return true

func edit_timing(preparation: float, duration: float, acceleration: float) -> bool:
	if not _guard(true):
		return false
	if not is_finite(preparation) or not is_finite(duration) or not is_finite(acceleration) or preparation < 1 or preparation > 600 or duration < 1 or duration > 300 or acceleration < 0 or acceleration > duration:
		return false
	view.session.prep_remaining = preparation
	view.session.sim.round_duration = duration
	view.session.sim.acceleration_at = acceleration
	_record("tempos", {"preparation": preparation, "duration": duration, "acceleration": acceleration})
	_refresh_view()
	return true

func observe(event: Dictionary) -> void:
	if not local_match():
		return
	recent_events.append(event.duplicate(true))
	if recent_events.size() > 200:
		recent_events.pop_front()
	if event.get("type") == "round_finished":
		rounds.append({"round": view.session.sim.round_index, "result": event.duplicate(true)})
		if rounds.size() > 100:
			rounds.pop_front()
		save_report("round")
		changed.emit()

func _record(operation: String, values: Dictionary = {}) -> void:
	modified = true
	actions.append({"operation": operation, "values": values.duplicate(true), "round": view.session.sim.round_index, "tick": view.session.sim.tick})
	if actions.size() > 100:
		actions.pop_front()
	changed.emit()

func _refresh_view() -> void:
	view._consume_events()
	view.card_signature = ""
	view.overlay_signature = ""
	view._refresh()
	changed.emit()

func context() -> Dictionary:
	var result: Dictionary = {"schema": 1, "created_at": Time.get_datetime_string_from_system(true), "match_id": match_id,
		"mode": "online" if view.is_online_match else ("menu" if view.menu_open else "local"),
		"phase": view._phase(), "performance": view.get_performance_metrics()}
	if local_match():
		result.merge({"seed": str(view.session._seed), "round": view.session.sim.round_index,
			"modified": modified, "speed": speed, "paused": paused,
			"combat": view.session.sim.snapshot(), "teams": view.session.teams.duplicate(true),
			"rounds": rounds.duplicate(true), "actions": actions.duplicate(true), "events": recent_events.duplicate(true)})
	# Online: não exportar a sessão local antiga nem dados privados de outro jogador.
	return result

func save_feedback(category: String, rating: int, comment: String, subject: String = "") -> String:
	if comment.strip_edges().is_empty() or comment.length() > 10000 or rating < 1 or rating > 5:
		notice.emit("Escreva um comentário (até 10.000 caracteres) e uma nota de 1 a 5.")
		return ""
	var report: Dictionary = context()
	report["feedback"] = {"category": category, "rating": rating, "comment": comment.strip_edges(), "subject": subject}
	var path: String = _save("feedback", report)
	if not path.is_empty():
		notice.emit("Feedback salvo no computador. Disponível para revisão nesta pasta.")
		changed.emit()
	return path

func save_report(prefix: String = "relatorio") -> String:
	return _save(prefix, context())

func _save(prefix: String, data: Dictionary) -> String:
	var directory: String = ProjectSettings.globalize_path(storage_dir)
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		notice.emit("Não foi possível criar a pasta de registros.")
		return ""
	_file_counter += 1
	var path: String = directory.path_join("%s_%d_%d_%d.json" % [prefix, int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), _file_counter])
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		notice.emit("Falha ao salvar registro: %s" % FileAccess.get_open_error())
		return ""
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(path + ".tmp", path) != OK:
		notice.emit("Registro não concluído. O texto continua no editor.")
		return ""
	return path

func saved_feedbacks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(storage_dir):
		return result
	var names: PackedStringArray = DirAccess.get_files_at(storage_dir)
	names.sort()
	names.reverse()
	for filename: String in names:
		if not filename.begins_with("feedback_") or not filename.ends_with(".json"):
			continue
		var entry: Variant = JSON.parse_string(FileAccess.get_file_as_string(storage_dir.path_join(filename)))
		if entry is Dictionary and entry.has("feedback"):
			result.append(entry)
		if result.size() >= 30:
			break
	return result
