extends Node2D
## Arrastar e soltar na preparação (mouse ou toque emulado como mouse).
## Não substitui toques nem botões: um toque sem arrasto chega a main._unhandled_input como antes.
## Só envia comandos que a Session já valida; nenhuma regra, moeda ou dano é decidido aqui.
##
## Origens: herói em campo/reserva, item da bolsa, item equipado no cartão, oferta da loja.
## Destinos: hexágono da própria metade, espaço da reserva, herói, item da bolsa (fusão), bolsa.

const Board = preload("res://client/board_projection.gd")
const Kit = preload("res://client/ui_kit.gd")
## Distância mínima (px da tela base) para um toque virar arrasto.
const THRESHOLD: float = 10.0
const VALID: Color = Color(0.3, 0.95, 0.6, 0.45)
const INVALID: Color = Color(0.95, 0.35, 0.3, 0.4)

var view # main.gd; sem tipo para acessar campos e métodos próprios do visor.
var pressing: bool = false
var dragging: bool = false
var press_point: Vector2 = Vector2.ZERO
var pointer: Vector2 = Vector2.ZERO
var payload: Dictionary = {}
var replay_press: InputEventMouseButton = null


## Cria uma camada acima da interface para o objeto arrastado ficar visível sobre os painéis.
static func install(main_view: Node2D) -> Node2D:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 10
	main_view.add_child(layer)
	var controller: Node2D = load("res://client/drag_controller.gd").new()
	controller.view = main_view
	controller.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(controller)
	return controller


func dragged_unit_id() -> int:
	return int(payload.get("unit_id", -1)) if dragging and payload.get("kind", "") == "unit" else -1


func _input(event: InputEvent) -> void:
	if view == null:
		return
	var phase: String = view._phase()
	if (phase != "preparation" and phase != "combat") or not view.drawer_mode.is_empty():
		if pressing or dragging:
			_reset()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed:
			_on_press(mouse)
		else:
			_on_release(mouse)
	elif event is InputEventMouseMotion and pressing:
		pointer = (event as InputEventMouseMotion).position
		if not dragging and not payload.is_empty() and pointer.distance_to(press_point) >= THRESHOLD:
			dragging = true
			if payload.get("kind", "") == "unit":
				view._select_unit(int(payload["unit_id"]))
		if dragging:
			queue_redraw()


func _on_press(mouse: InputEventMouseButton) -> void:
	_reset()
	var phase: String = view._phase()
	pressing = true
	press_point = mouse.position
	pointer = mouse.position
	payload = _ui_source(mouse.position)
	if phase == "combat":
		# Durante o combate, itens da bolsa ou ofertas de item da loja podem ser arrastados
		var is_item_offer: bool = payload.get("kind", "") == "offer" and str(payload.get("offer", {}).get("kind", "")) == "item"
		if payload.get("kind", "") != "item" and not is_item_offer:
			_reset()
			return
		return
	if not payload.is_empty():
		return # O botão continua recebendo o toque; só vira arrasto se o dedo andar.
	if _ui_blocks(mouse.position):
		return
	var unit: Dictionary = _own_unit_under(mouse.position)
	if unit.is_empty():
		return # Toque no chão vazio segue direto para o fluxo de toque do visor.
	payload = {"kind": "unit", "unit_id": int(unit["id"]), "key": str(unit.get("key", "")), "level": int(unit.get("level", 1))}
	## O toque no herói fica guardado: se não houver arrasto, é reenviado ao soltar.
	replay_press = mouse.duplicate() as InputEventMouseButton
	get_viewport().set_input_as_handled()


func _on_release(mouse: InputEventMouseButton) -> void:
	if not pressing:
		return
	var from_world: bool = replay_press != null
	if dragging:
		pointer = mouse.position
		_drop(mouse.position)
		if from_world:
			get_viewport().set_input_as_handled()
	elif from_world:
		view._unhandled_input(replay_press)
		get_viewport().set_input_as_handled()
	_reset()


func _reset() -> void:
	pressing = false
	dragging = false
	payload = {}
	replay_press = null
	queue_redraw()


# --- Origens ------------------------------------------------------------------

func _ui_source(point: Vector2) -> Dictionary:
	var own: Dictionary = view.state.get("own", {})
	for item_id: Variant in view.bag_buttons:
		var slot: Button = view.bag_buttons[item_id]
		if is_instance_valid(slot) and slot.is_visible_in_tree() and not slot.disabled and slot.get_global_rect().has_point(point):
			var item: Dictionary = _item_in(own.get("bag", []), str(item_id))
			return {"kind": "item", "item_id": str(item_id), "key": str(item.get("key", ""))}
	var equipped: Array = (own.get("equipment", {}) as Dictionary).get(view.selected_id, [])
	for index: int in range(view.equipment_buttons.size()):
		var slot: Button = view.equipment_buttons[index]
		if index < equipped.size() and is_instance_valid(slot) and slot.is_visible_in_tree() and not slot.disabled and slot.get_global_rect().has_point(point):
			return {"kind": "equipped", "unit_id": view.selected_id, "item_id": str(equipped[index].get("id", "")), "key": str(equipped[index].get("key", ""))}
	for offer: Dictionary in own.get("shop", []):
		var card: Button = view.shop_buttons.get(str(offer.get("offer_id", "")), null)
		if card != null and is_instance_valid(card) and card.is_visible_in_tree() and not card.disabled and card.get_global_rect().has_point(point):
			return {"kind": "offer", "offer": offer.duplicate(true), "key": str(offer.get("key", ""))}
	return {}


## Algum painel/controle visível que bloqueia o mouse cobre o ponto? (cartão, loja, bolsa, topo).
func _ui_blocks(point: Vector2) -> bool:
	return _blocks_in(view.ui, point)


func _blocks_in(node: Node, point: Vector2) -> bool:
	for child: Node in node.get_children():
		if child is Control:
			var control: Control = child as Control
			if not control.is_visible_in_tree():
				continue
			if control.mouse_filter == Control.MOUSE_FILTER_STOP and control.get_global_rect().has_point(point):
				return true
			if _blocks_in(control, point):
				return true
	return false


func _own_unit_under(point: Vector2) -> Dictionary:
	var unit: Dictionary = view._unit_at_point(point)
	if unit.is_empty():
		var cell: Vector2i = Board.pick_cell(point)
		if cell != Board.INVALID:
			unit = view._own_unit_at(cell)
		else:
			var slot: int = Board.pick_bench(point)
			if slot >= 0:
				unit = view._bench_unit(slot)
	if unit.is_empty() or int(unit.get("team", 1)) != 0 or not unit.has("max_hp"):
		return {}
	return unit


func _item_in(items: Array, item_id: String) -> Dictionary:
	for item: Variant in items:
		if item is Dictionary and str(item.get("id", "")) == item_id:
			return item
	return {}


# --- Destinos ------------------------------------------------------------------

func _drop(point: Vector2) -> void:
	match str(payload.get("kind", "")):
		"unit":
			_drop_unit(point)
		"item":
			_drop_item(point)
		"equipped":
			_drop_equipped(point)
		"offer":
			_drop_offer(point)


func _drop_unit(point: Vector2) -> void:
	var unit_id: int = int(payload["unit_id"])
	var unit: Dictionary = view._unit_by_id(unit_id)
	if unit.is_empty():
		return
	var active: bool = bool(unit.get("active", false))
	var cell: Vector2i = Board.pick_cell(point)
	var slot: int = Board.pick_bench(point)
	if cell != Board.INVALID:
		if cell.y < 4:
			_toast("Solte o herói na sua metade (hexágonos azuis).")
			return
		var occupant: Dictionary = view._own_unit_at(cell)
		if occupant.is_empty():
			view._command("place" if active else "deploy", {"unit_id": unit_id, "cell": cell})
		elif int(occupant["id"]) == unit_id:
			pass
		elif not active:
			view._command("swap", {"active_id": int(occupant["id"]), "bench_id": unit_id})
		else:
			_swap_on_field(unit, occupant)
	elif slot >= 0:
		var resting: Dictionary = view._bench_unit(slot)
		if active and resting.is_empty():
			view._command("bench", {"unit_id": unit_id})
		elif active and int(resting["id"]) != unit_id:
			view._command("swap", {"active_id": unit_id, "bench_id": int(resting["id"])})
	view._select_unit(unit_id)


## Troca de lugar entre dois heróis em campo, só com comandos existentes (reserva → move → volta).
func _swap_on_field(moving: Dictionary, other: Dictionary) -> void:
	var from: Vector2i = view._cell(moving.get("cell", []))
	var to: Vector2i = view._cell(other.get("cell", []))
	var other_id: int = int(other["id"])
	if not bool(view._command("bench", {"unit_id": other_id}).get("ok", false)):
		return
	if not bool(view._command("place", {"unit_id": int(moving["id"]), "cell": to}).get("ok", false)):
		view._command("deploy", {"unit_id": other_id, "cell": to})
		return
	view._command("deploy", {"unit_id": other_id, "cell": from})


func _drop_item(point: Vector2) -> void:
	var item_id: String = str(payload["item_id"])
	var target: Dictionary = _own_unit_under(point)
	if not target.is_empty():
		view._select_unit(int(target["id"]))
		view._command("equip", {"unit_id": int(target["id"]), "item_id": item_id})
		view.selected_items.clear()
		return
	if view._phase() == "preparation":
		var other: String = _bag_item_at(point)
		if not other.is_empty() and other != item_id:
			view._command("fuse", {"item_ids": [item_id, other]})
			view.selected_items.clear()


func _drop_equipped(point: Vector2) -> void:
	var owner_id: int = int(payload["unit_id"])
	var item_id: String = str(payload["item_id"])
	if is_instance_valid(view.bag_panel) and view.bag_panel.get_global_rect().has_point(point):
		view._command("unequip", {"unit_id": owner_id, "item_id": item_id})
		return
	var target: Dictionary = _own_unit_under(point)
	if target.is_empty() or int(target["id"]) == owner_id:
		return
	if bool(view._command("unequip", {"unit_id": owner_id, "item_id": item_id}).get("ok", false)):
		if not bool(view._command("equip", {"unit_id": int(target["id"]), "item_id": item_id}).get("ok", false)):
			view._command("equip", {"unit_id": owner_id, "item_id": item_id})
		else:
			view._select_unit(int(target["id"]))


func _drop_offer(point: Vector2) -> void:
	var offer: Dictionary = payload["offer"]
	var offer_id: String = str(offer.get("offer_id", ""))
	if str(offer.get("kind", "item")) == "item":
		var target: Dictionary = _own_unit_under(point)
		var over_bag: bool = is_instance_valid(view.bag_panel) and view.bag_panel.get_global_rect().has_point(point)
		if target.is_empty() and not over_bag:
			return
		var bought: Dictionary = view._command("buy_item", {"offer_id": offer_id})
		if bool(bought.get("ok", false)) and not target.is_empty():
			view._select_unit(int(target["id"]))
			view._command("equip", {"unit_id": int(target["id"]), "item_id": str(bought.get("data", {}).get("id", ""))})
		return
	var cell: Vector2i = Board.pick_cell(point)
	var slot: int = Board.pick_bench(point)
	if cell == Board.INVALID and slot < 0:
		return
	var recruited: Dictionary = view._command("recruit", {"offer_id": offer_id})
	if not bool(recruited.get("ok", false)):
		return
	var data: Dictionary = recruited.get("data", {})
	var unit_id: int = int(data.get("unit_id", -1))
	if int(data.get("copies", 1)) > 1:
		view._select_unit(unit_id)
		return # Cópia: só sobe de nível; a posição atual do herói é mantida.
	if cell != Board.INVALID and cell.y >= 4 and view._own_unit_at(cell).is_empty():
		view._command("place" if bool(data.get("active", false)) else "deploy", {"unit_id": unit_id, "cell": cell})
	view._select_unit(unit_id)


func _bag_item_at(point: Vector2) -> String:
	for item_id: Variant in view.bag_buttons:
		var slot: Button = view.bag_buttons[item_id]
		if is_instance_valid(slot) and slot.is_visible_in_tree() and slot.get_global_rect().has_point(point):
			return str(item_id)
	return ""


func _toast(text: String) -> void:
	view.toast_text = text
	view.toast_remaining = 2.5


# --- Desenho do objeto arrastado ----------------------------------------------

func _process(_delta: float) -> void:
	if dragging:
		queue_redraw()


func _draw() -> void:
	if not dragging or view == null:
		return
	var kind: String = str(payload.get("kind", ""))
	var hint: String = ""
	var cell: Vector2i = Board.pick_cell(pointer)
	var slot: int = Board.pick_bench(pointer)
	var hero_drop: bool = kind == "unit" or (kind == "offer" and str(payload["offer"].get("kind", "")) == "hero")
	if hero_drop:
		if cell != Board.INVALID:
			var valid: bool = cell.y >= 4
			var outline: PackedVector2Array = Board.hex_polygon(cell, 0.05)
			draw_colored_polygon(outline, VALID if valid else INVALID)
			outline.append(outline[0])
			draw_polyline(outline, Color(1, 1, 1, 0.8), 2.0, true)
			hint = "Posicionar" if valid else "Só na sua metade"
			if valid and kind == "unit" and not view._own_unit_at(cell).is_empty() and int(view._own_unit_at(cell)["id"]) != int(payload["unit_id"]):
				hint = "Trocar de lugar"
		elif slot >= 0:
			var pad: PackedVector2Array = Board.bench_polygon(slot)
			draw_colored_polygon(pad, VALID)
			pad.append(pad[0])
			draw_polyline(pad, Color(1, 1, 1, 0.8), 2.0, true)
			hint = "Reserva" if kind == "unit" else "Recrutar para a reserva"
		if kind == "offer" and hint == "Posicionar":
			hint = "Recrutar aqui"
		_draw_hero(str(payload.get("key", "")), int(payload.get("level", 1)))
	else:
		var target: Dictionary = _own_unit_under(pointer)
		if not target.is_empty():
			var feet: Vector2 = Board.project(view._ground_of(target))
			var ring: PackedVector2Array = Board.ellipse(view._ground_of(target), 0.42, 0.25, 28)
			draw_colored_polygon(ring, VALID)
			ring.append(ring[0])
			draw_polyline(ring, Color(1, 1, 1, 0.85), 2.0, true)
			hint = "Equipar em %s" % str(target.get("name", "herói"))
			if feet.distance_to(pointer) > 90.0:
				hint = ""
		elif kind == "item" and not _bag_item_at(pointer).is_empty() and _bag_item_at(pointer) != str(payload["item_id"]):
			hint = "Fundir"
		elif kind != "item" and is_instance_valid(view.bag_panel) and view.bag_panel.get_global_rect().has_point(pointer):
			hint = "Devolver à bolsa" if kind == "equipped" else "Comprar para a bolsa"
		var icon: Texture2D = Kit.icon("item_" + str(payload.get("key", "")))
		if icon != null:
			draw_texture_rect(icon, Rect2(pointer - Vector2(20, 20), Vector2(40, 40)), false, Color(1, 1, 1, 0.92))
	if not hint.is_empty():
		var font: Font = ThemeDB.fallback_font
		var at: Vector2 = pointer + Vector2(18, -26)
		draw_string_outline(font, at, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color(0, 0, 0, 0.85))
		draw_string(font, at, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f4d58a"))


func _draw_hero(key: String, level: int) -> void:
	var texture: Texture2D = view.art.texture_for(key, "south", view.visual_time, "idle", level)
	if texture == null:
		draw_circle(pointer + Vector2(0, -14), 9, Color(1, 1, 1, 0.7))
		return
	var scale: float = view.art.board_scale_for(key) * [1.0, 1.2, 1.44][clampi(level, 1, 3) - 1]
	var anchor: Vector2 = view.art.anchor_for(texture, key)
	draw_set_transform(pointer.round(), 0.0, Vector2(scale, scale))
	draw_texture(texture, (-anchor).round(), Color(1, 1, 1, 0.88))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
