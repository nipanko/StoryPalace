class_name MapView
extends Control
## One room as a map sheet with its course. Click empty ground to add a control, drag to move.

signal selected(item_id: String)
signal added(item: Dictionary)
signal moved(item: Dictionary)
signal context(item: Dictionary, at: Vector2)
signal delete_requested(item_id: String)

const ASPECT := 1.6

var palace: Dictionary
var room: Dictionary:
	set(v):
		room = v
		queue_redraw()
var editable := true
var selected_id := "":
	set(v):
		selected_id = v
		queue_redraw()
var tour := {}             # course drawing options while running or testing
var zoom := 1.0:
	set(v):
		zoom = v
		queue_redraw()
var focus := Vector2(0.5, 0.5):
	set(v):
		focus = v
		queue_redraw()

var _hover_id := ""
var _ghost := Vector2(-1, -1)
var _press_id := ""
var _press_at := Vector2.ZERO
var _press_empty := false
var _dragging := false
var _pops := {}            # item id -> landing scale while a new sticker presses down


## A new sticker lands with a small bounce.
func pop(id: String) -> void:
	_pops[id] = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float): _pops[id] = v; queue_redraw(), 0.0, 1.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _pops.erase(id))


func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	mouse_exited.connect(func(): _ghost = Vector2(-1, -1); _hover_id = ""; queue_redraw())
	resized.connect(queue_redraw)


func scene_rect() -> Rect2:
	var w := minf(size.x, size.y * ASPECT)
	var base := Rect2((size - Vector2(w, w / ASPECT)) * 0.5, Vector2(w, w / ASPECT))
	if is_equal_approx(zoom, 1.0):
		return base
	var zs := base.size * zoom
	var pos := size * 0.5 - focus * zs
	pos.x = clampf(pos.x, size.x - zs.x, 0.0) if zs.x > size.x else (size.x - zs.x) * 0.5
	pos.y = clampf(pos.y, size.y - zs.y, 0.0) if zs.y > size.y else (size.y - zs.y) * 0.5
	return Rect2(pos, zs)


func radius() -> float:
	var r := scene_rect()
	return clampf(r.size.y * 0.045, 16.0, 40.0 * zoom)


func first_number() -> int:
	var n := 1
	for r in palace.rooms:
		if r == room:
			break
		n += r.items.size()
	return n


func _draw() -> void:
	if room.is_empty():
		return
	var rect := scene_rect()
	# the space around the room reads as the desk, not as empty paper
	draw_rect(Rect2(Vector2.ZERO, size), UI.LAVENDER_TINT)
	var g := Color(UI.INK, 0.06)
	for x in range(24, int(size.x), 24):
		draw_line(Vector2(x, 0), Vector2(x, size.y), g, 1.0)
	for y in range(24, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), g, 1.0)
	SceneArt.draw_room(self, rect, room)
	var opts := tour.duplicate()
	opts.selected = selected_id
	opts.hover = _hover_id
	opts.pops = _pops
	Course.draw_room_course(self, rect, room, first_number(), Store.count_items(palace), radius(), opts)
	if editable and _ghost.x >= 0 and not _dragging:
		var c := rect.position + _ghost * rect.size
		var r := radius()
		draw_circle(c, r, Color(UI.PAPER, 0.75), true, -1, true)
		draw_arc(c, r, 0, TAU, 40, Color(UI.PINK, 0.8), Course.ring_width(r), true)
		draw_line(c - Vector2(r * 0.35, 0), c + Vector2(r * 0.35, 0), UI.PINK, 3, true)
		draw_line(c - Vector2(0, r * 0.35), c + Vector2(0, r * 0.35), UI.PINK, 3, true)
		_pill(c + Vector2(r + 10, -14), "Add memory %d here" % (first_number() + room.items.size()))
	elif editable and room.items.is_empty():
		_pill(rect.get_center() - Vector2(160, 18), "Click anywhere to place your first memory", true)


func _pill(at: Vector2, text: String, big := false) -> void:
	var f := UI.font("semibold")
	var fs := 17 if big else 15
	var s := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var box := Rect2(at, s + Vector2(20, 12))
	if big:
		box.position.x = scene_rect().get_center().x - box.size.x * 0.5
	box.position.x = minf(box.position.x, size.x - box.size.x - 6)
	draw_style_box(UI.box(UI.INK, Color.TRANSPARENT, 0, int(box.size.y * 0.5)), box)
	draw_string(f, box.position + Vector2(10, 6 + f.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.PAPER)


func item_at(p: Vector2) -> Dictionary:
	var rect := scene_rect()
	var r := radius() * 1.25
	for i in range(room.items.size() - 1, -1, -1):
		var it: Dictionary = room.items[i]
		if (rect.position + Vector2(it.x, it.y) * rect.size).distance_to(p) <= r:
			return it
	return {}


func _to_norm(p: Vector2) -> Vector2:
	var rect := scene_rect()
	return ((p - rect.position) / rect.size).clamp(Vector2(0.03, 0.04), Vector2(0.97, 0.96))


func _gui_input(e: InputEvent) -> void:
	if not editable:
		return
	if e is InputEventMouseMotion:
		if _press_id != "":
			if not _dragging and e.position.distance_to(_press_at) > 5:
				_dragging = true
			if _dragging:
				var it := _find(_press_id)
				var n := _to_norm(e.position)
				it.x = n.x
				it.y = n.y
				queue_redraw()
			return
		var hit := item_at(e.position)
		_hover_id = hit.get("id", "")
		_ghost = Vector2(-1, -1) if hit or not scene_rect().has_point(e.position) else _to_norm(e.position)
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if hit else CURSOR_CROSS
		queue_redraw()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			grab_focus()
			var hit := item_at(e.position)
			_press_at = e.position
			_press_id = hit.get("id", "")
			_press_empty = hit.is_empty() and scene_rect().has_point(e.position)
			if hit:
				selected_id = hit.id
				selected.emit(hit.id)
		else:
			if _dragging:
				moved.emit(_find(_press_id))
			elif _press_empty and e.position.distance_to(_press_at) < 6:
				var n := _to_norm(e.position)
				var it := Store.new_item(n.x, n.y)
				room.items.append(it)
				selected_id = it.id
				pop(it.id)
				added.emit(it)
			_press_id = ""
			_dragging = false
			_press_empty = false
			queue_redraw()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		var hit := item_at(e.position)
		if hit:
			selected_id = hit.id
			selected.emit(hit.id)
			context.emit(hit, get_screen_transform() * e.position)
	elif e is InputEventKey and e.pressed and e.keycode in [KEY_DELETE, KEY_BACKSPACE] and selected_id != "":
		delete_requested.emit(selected_id)
		accept_event()


func _find(id: String) -> Dictionary:
	for it in room.items:
		if it.id == id:
			return it
	return {}
