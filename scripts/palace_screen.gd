class_name PalaceScreen
extends Control
## The palace editor: a Rooms window, the room window (2D map or 3D walk), and the Memories window.

signal back_requested
signal run_requested(mode: String)   # "run" or "test"

var palace: Dictionary
var room: Dictionary
var selected_id := ""

var _title: LineEdit
var _guide: Label
var _rooms_win: Control
var _rooms: VBoxContainer
var _room_win: Dictionary
var _mem_win: Dictionary
var _holder: Control
var _hint: Label
var _table: VBoxContainer
var _scroll: ScrollContainer
var _seg2: Button
var _seg3: Button
var _run: Button
var _test: Button
var _map: MapView
var _world: PalaceWorld
var _undo := {}
var _compact := false


func setup(p: Dictionary) -> void:
	palace = p
	room = p.rooms[0] if not p.rooms.is_empty() else {}


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var desk := UI.Desk.new()
	desk.sparkles = false
	desk.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(desk)
	var root := UI.vbox(0)
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UI.margin(_top_bar(), 20, 14, 20, 10))
	var body := UI.hbox(18)
	var bm := UI.margin(body, 20, 4, 20, 20)
	bm.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(bm)

	# Rooms
	var rw := UI.window("Rooms", UI.TEAL, 8)
	_rooms_win = rw.root
	var add := UI.bar_button("plus", "Add a room")
	add.pressed.connect(_add_room)
	rw.bar.add_child(add)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rooms = UI.vbox(6)
	_rooms.size_flags_horizontal = SIZE_EXPAND_FILL
	rs.add_child(_rooms)
	rw.body.add_child(rs)
	body.add_child(_rooms_win)

	# The room itself
	_room_win = UI.window("", UI.LAVENDER, 0)
	_room_win.root.size_flags_horizontal = SIZE_EXPAND_FILL
	var opts := UI.bar_button("ellipsis-vertical", "Room options")
	opts.pressed.connect(_room_menu)
	_room_win.bar.add_child(opts)
	_holder = Control.new()
	_holder.clip_contents = true
	_room_win.body.add_child(_holder)
	_holder.resized.connect(_place_overlays)
	body.add_child(_room_win.root)
	_holder.add_child(_view_switch())
	_hint = UI.label("", "Muted")
	var hint_pill := PanelContainer.new()
	hint_pill.name = "HintPill"
	hint_pill.add_theme_stylebox_override(&"panel", UI.box(Color(UI.PAPER, 0.92), UI.INK, UI.LINE, 12, Vector4(12, 6, 12, 6)))
	hint_pill.mouse_filter = MOUSE_FILTER_IGNORE
	hint_pill.add_child(_hint)
	_holder.add_child(hint_pill)

	# Memories
	_mem_win = UI.window("Memories", UI.BUTTER, 0)
	body.add_child(_mem_win.root)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_mem_win.body.add_child(_scroll)
	_table = UI.vbox(6)
	_table.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(UI.margin(_table, 10, 10, 12, 10))
	_table.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL

	for i in [0, 1, 2]:
		UI.pop_in(body.get_child(i), 0.04 * i)
	resized.connect(_fit)
	_fit()
	_set_view(Store.settings.get("view", "2d"))
	_refresh_all()


## Responsive layout: the rooms list folds into thumbnails and side windows narrow on smaller screens.
func _fit() -> void:
	var w := size.x
	var compact := w < 1280
	_rooms_win.custom_minimum_size.x = 112 if compact else 248
	_mem_win.root.custom_minimum_size.x = clampf(w * 0.28, 330, 430)
	_run.text = "" if w < 1120 else "Run the course"
	_test.text = "" if w < 1120 else "Punch test"
	if compact != _compact:
		_compact = compact
		if is_node_ready():
			_build_rooms()
	_place_overlays()


func _place_overlays() -> void:
	if not _holder:
		return
	var sw := _holder.get_node_or_null("Switch") as Control
	if sw:
		sw.reset_size()
		sw.position = Vector2(_holder.size.x - sw.size.x - 12, 12)
	var hp := _holder.get_node_or_null("HintPill") as Control
	if hp:
		hp.reset_size()
		hp.position = Vector2(12, _holder.size.y - hp.size.y - 12)
		hp.visible = hp.size.x < _holder.size.x - 24


func _view_switch() -> Control:
	var track := PanelContainer.new()
	track.name = "Switch"
	track.add_theme_stylebox_override(&"panel", UI.soft_shadow(UI.box(UI.LAVENDER_TINT, UI.INK, UI.LINE, 13, Vector4(4, 4, 4, 4)), 10, 3))
	var seg := UI.hbox(4)
	track.add_child(seg)
	var g := ButtonGroup.new()
	_seg2 = UI.button("2D map", "square", "SegButton", "Flat map of each room")
	_seg3 = UI.button("3D walk", "box", "SegButton", "Walk through your palace in 3D")
	for b in [_seg2, _seg3]:
		b.toggle_mode = true
		b.button_group = g
		seg.add_child(b)
	_seg2.pressed.connect(func(): _set_view("2d"))
	_seg3.pressed.connect(func(): _set_view("3d"))
	return track


func _top_bar() -> Control:
	var row := UI.hbox(14)
	var back := UI.icon_button("arrow-left", "All palaces", "Button")
	back.pressed.connect(func(): back_requested.emit())
	row.add_child(back)
	var logo := TextureRect.new()
	logo.texture = load("res://icon.svg")
	logo.custom_minimum_size = Vector2(44, 44)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	row.add_child(logo)
	var names := UI.vbox(0)
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	_title = LineEdit.new()
	_title.theme_type_variation = "TitleEdit"
	_title.text = palace.name
	_title.expand_to_text_length = true
	_title.custom_minimum_size.x = 120
	_title.size_flags_horizontal = SIZE_SHRINK_BEGIN
	_title.tooltip_text = "Rename this palace"
	_title.text_changed.connect(func(t): palace.name = t if t.strip_edges() != "" else "Untitled palace"; Store.mark_dirty(palace))
	_title.text_submitted.connect(func(_t): _title.release_focus())
	names.add_child(_title)
	_guide = UI.label("", "Muted")
	_guide.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(UI.margin(_guide, 7, 0, 0, 0))
	row.add_child(names)
	_run = UI.button("Run the course", "play", "PrimaryButton", "Walk the path memory by memory  (R)")
	_run.pressed.connect(func(): run_requested.emit("run"))
	row.add_child(_run)
	_test = UI.button("Punch test", "check", "ButterButton", "Test what you remember  (T)")
	_test.pressed.connect(func(): run_requested.emit("test"))
	row.add_child(_test)
	var more := UI.icon_button("ellipsis-vertical", "More", "Button")
	var menu := PopupMenu.new()
	menu.add_item("Export palace to a file…", 0)
	menu.add_item("Duplicate palace", 1)
	menu.add_separator()
	menu.add_item("Delete palace…", 2)
	menu.id_pressed.connect(_on_palace_menu)
	more.add_child(menu)
	more.pressed.connect(func(): menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO)))
	row.add_child(more)
	for b in [_run, _test, more, back]:
		b.size_flags_vertical = SIZE_SHRINK_CENTER
	return row


func _unhandled_key_input(e: InputEvent) -> void:
	if not e.pressed or get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	match e.keycode:
		KEY_R: run_requested.emit("run")
		KEY_T: run_requested.emit("test")
		KEY_Z when e.ctrl_pressed or e.meta_pressed: _do_undo()


# ---------- views ----------

func _set_view(v: String) -> void:
	Store.settings.view = v
	Store.save_settings()
	_seg2.set_pressed_no_signal(v == "2d")
	_seg3.set_pressed_no_signal(v == "3d")
	for c in [_map, _world]:
		if c:
			c.queue_free()
	_map = null
	_world = null
	if v == "3d":
		_world = PalaceWorld.new()
		_world.palace = palace
		_world.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_holder.add_child(_world)
		_holder.move_child(_world, 0)
		_world.selected.connect(_select)
		_world.added.connect(_on_added)
		_world.room_entered.connect(func(r): if r != room: _switch_room(r, false))
		_world.go_to_room(room)
		_hint.text = "Drag to look  ·  W A S D to walk  ·  click the floor or a wall to add a memory"
	else:
		_map = MapView.new()
		_map.palace = palace
		_map.room = room
		_map.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_holder.add_child(_map)
		_holder.move_child(_map, 0)
		_map.selected.connect(_select)
		_map.added.connect(_on_added)
		_map.moved.connect(func(_it): Store.mark_dirty(palace))
		_map.delete_requested.connect(_remove)
		_map.context.connect(_on_context)
		_hint.text = "Click to add a memory  ·  drag to move  ·  right-click for options"
	_sync_selection()
	_place_overlays.call_deferred()


func _redraw_view() -> void:
	if _map:
		_map.queue_redraw()
	if _world:
		_world.rebuild()


func _sync_selection() -> void:
	if _map:
		_map.room = room
		_map.selected_id = selected_id
	if _world:
		_world.selected_id = selected_id


# ---------- rooms ----------

func _switch_room(r: Dictionary, move_camera := true) -> void:
	room = r
	if not _item_in(room, selected_id):
		selected_id = ""
	_sync_selection()
	if _world and move_camera:
		_world.go_to_room(room)
	_refresh_all()


func _refresh_all() -> void:
	_build_rooms()
	_build_table()
	_update_guide()


func _update_guide() -> void:
	var first := 1
	for r in palace.rooms:
		if r == room:
			break
		first += r.items.size()
	var total := Store.count_items(palace)
	var n: int = room.get("items", []).size()
	_guide.text = "%d room%s  ·  %d memor%s on the path" % [palace.rooms.size(), "" if palace.rooms.size() == 1 else "s", total, "y" if total == 1 else "ies"]
	_room_win.bar.get_node("Title").text = "%s  ·  %s" % [room.get("name", ""), "empty, click to add a memory" if n == 0 else ("memory %d" % first if n == 1 else "memories %d–%d" % [first, first + n - 1])]
	_mem_win.bar.get_node("Title").text = "Memories  ·  %d" % total


func _build_rooms() -> void:
	for c in _rooms.get_children():
		_rooms.remove_child(c)
		c.queue_free()
	var n := 1
	for r in palace.rooms:
		_rooms.add_child(_room_row(r, n))
		n += r.items.size()
	var add := UI.button("" if _compact else "Add a room", "plus", "FlatButton", "Add another room to the path")
	add.alignment = HORIZONTAL_ALIGNMENT_CENTER if _compact else HORIZONTAL_ALIGNMENT_LEFT
	add.pressed.connect(_add_room)
	_rooms.add_child(add)


func _room_row(r: Dictionary, first: int) -> Control:
	var cur: bool = r == room
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.tooltip_text = "%s
Right-click for room options" % r.name
	var sel := UI.box(UI.LAVENDER_TINT, UI.INK, UI.LINE, 12, Vector4(6, 6, 6, 6))
	b.add_theme_stylebox_override(&"normal", sel if cur else UI.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 12, Vector4(6, 6, 6, 6)))
	b.add_theme_stylebox_override(&"hover", sel if cur else UI.box(Color(UI.LAVENDER_TINT, 0.6), Color.TRANSPARENT, 0, 12, Vector4(6, 6, 6, 6)))
	b.add_theme_stylebox_override(&"pressed", sel)
	var row := UI.hbox(10)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 6)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Frame"
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	var th := Thumb.new()
	th.room = r
	th.custom_minimum_size = Vector2(80, 50)
	frame.add_child(th)
	row.add_child(frame)
	if not _compact:
		var t := UI.vbox(0)
		t.mouse_filter = MOUSE_FILTER_IGNORE
		var name := UI.label(r.name, "H3")
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name.custom_minimum_size.x = 100
		t.add_child(name)
		var k: int = r.items.size()
		t.add_child(UI.label("no memories" if k == 0 else ("memory %d" % first if k == 1 else "memories %d–%d" % [first, first + k - 1]), "Muted"))
		for c in t.get_children():
			c.mouse_filter = MOUSE_FILTER_IGNORE
		row.add_child(t)
	b.add_child(row)
	b.custom_minimum_size = Vector2(0, 66)
	b.pressed.connect(func(): _switch_room(r))
	b.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT: _switch_room(r); _room_menu())
	return b


func _add_room() -> void:
	Pickers.room(self, "Add a room", func(choice):
		var t: String = choice.get("theme", "living")
		var name: String = choice.get("name", SceneArt.theme(t).name)
		var r := Store.new_room(_unique_room_name(name), t, choice.get("photo", ""))
		palace.rooms.append(r)
		Store.mark_dirty(palace)
		_switch_room(r))


func _unique_room_name(name: String) -> String:
	var names: Array = palace.rooms.map(func(r): return r.name)
	if name not in names:
		return name
	var i := 2
	while "%s %d" % [name, i] in names:
		i += 1
	return "%s %d" % [name, i]


func _room_menu() -> void:
	var menu := PopupMenu.new()
	var i: int = palace.rooms.find(room)
	menu.add_item("Rename room…", 0)
	menu.add_item("Change scene or photo…", 1)
	menu.add_separator()
	menu.add_item("Move earlier on the path", 2)
	menu.set_item_disabled(menu.item_count - 1, i <= 0)
	menu.add_item("Move later on the path", 3)
	menu.set_item_disabled(menu.item_count - 1, i >= palace.rooms.size() - 1)
	menu.add_separator()
	menu.add_item("Delete room…", 4)
	menu.set_item_disabled(menu.item_count - 1, palace.rooms.size() <= 1)
	menu.id_pressed.connect(func(id): _on_room_menu(id, i))
	menu.popup_hide.connect(menu.queue_free)
	add_child(menu)
	menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _on_room_menu(id: int, i: int) -> void:
	if id == 0:
		Pickers.ask_text(self, "Rename room", room.name, func(t):
			room.name = t
			Store.mark_dirty(palace)
			_refresh_all()
		)
	elif id == 1:
		Pickers.room(self, "Change the picture of “%s”" % room.name, func(c):
			room.theme = c.get("theme", room.theme)
			room.photo = c.get("photo", "")
			Store.mark_dirty(palace)
			_redraw_view()
		)
	elif id == 2 or id == 3:
		palace.rooms.remove_at(i)
		palace.rooms.insert(i + (-1 if id == 2 else 1), room)
		Store.mark_dirty(palace)
		_redraw_view()
		_refresh_all()
	elif id == 4:
		var n: int = room.items.size()
		var what := "" if n == 0 else " and its %d control%s" % [n, "" if n == 1 else "s"]
		UI.confirm(self, "Delete room", "Delete “%s”%s? This cannot be undone." % [room.name, what], "Delete room", func():
			palace.rooms.erase(room)
			Store.mark_dirty(palace)
			_redraw_view()
			_switch_room(palace.rooms[clampi(i - 1, 0, palace.rooms.size() - 1)])
		)


# ---------- controls ----------

func _item_in(r: Dictionary, id: String) -> bool:
	return id != "" and r.get("items", []).any(func(it): return it.id == id)


func _select(id: String) -> void:
	if id == selected_id:
		return
	selected_id = id
	if not _item_in(room, id):
		for r in palace.rooms:
			if _item_in(r, id):
				room = r
				if _world:
					_world.go_to_room(r)
				break
	_sync_selection()
	_refresh_all()
	_scroll_to_selected.call_deferred()


func _on_added(it: Dictionary) -> void:
	if not _item_in(room, it.id):
		for r in palace.rooms:
			if _item_in(r, it.id):
				room = r
	Store.mark_dirty(palace)
	selected_id = it.id
	_sync_selection()
	_redraw_view()
	_refresh_all()
	(func(): var f = _table.find_child("TitleField", true, false); if f: UI.focus_later(f)).call()


func _remove(id: String) -> void:
	for r in palace.rooms:
		for i in r.items.size():
			if r.items[i].id == id:
				_undo = {"room": r, "index": i, "item": r.items[i]}
				r.items.remove_at(i)
				Store.mark_dirty(palace)
				selected_id = ""
				_sync_selection()
				_redraw_view()
				_refresh_all()
				_undo_toast()
				return


func _undo_toast() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", UI.box(UI.INK, Color.TRANSPARENT, 0, 4, Vector4(16, 6, 8, 6)))
	var row := UI.hbox(12)
	var l := UI.label("Memory removed")
	l.add_theme_color_override(&"font_color", UI.PAPER)
	row.add_child(l)
	var b := UI.button("Undo", "rotate-ccw", "FlatButton", "Ctrl+Z")
	b.add_theme_color_override(&"font_color", UI.BUTTER)
	b.add_theme_color_override(&"icon_normal_color", UI.BUTTER)
	b.pressed.connect(func(): _do_undo(); p.queue_free())
	row.add_child(b)
	p.add_child(row)
	add_child(p)
	p.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM, PRESET_MODE_MINSIZE, 28)
	p.grow_horizontal = GROW_DIRECTION_BOTH
	p.grow_vertical = GROW_DIRECTION_BEGIN
	var tw := p.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)


func _do_undo() -> void:
	if _undo.is_empty() or _undo.room not in palace.rooms:
		return
	_undo.room.items.insert(mini(_undo.index, _undo.room.items.size()), _undo.item)
	var id: String = _undo.item.id
	_undo = {}
	Store.mark_dirty(palace)
	_redraw_view()
	_select(id)


func _move(id: String, step: int) -> void:
	var items: Array = room.items
	for i in items.size():
		if items[i].id == id and i + step >= 0 and i + step < items.size():
			var it = items[i]
			items.remove_at(i)
			items.insert(i + step, it)
			Store.mark_dirty(palace)
			_redraw_view()
			_refresh_all()
			return


func _on_context(it: Dictionary, _at: Vector2) -> void:
	var menu := PopupMenu.new()
	menu.add_item("Change picture…", 0)
	menu.add_item("Remove control", 1)
	menu.id_pressed.connect(func(id): if id == 0: _pick_picture(it) else: _remove(it.id))
	menu.popup_hide.connect(menu.queue_free)
	add_child(menu)
	menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _pick_picture(it: Dictionary) -> void:
	Pickers.picture(self, it.title, func(c):
		it.icon = c.get("icon", it.icon)
		it.image = c.get("image", "")
		it.erase("auto_icon")
		Store.mark_dirty(palace)
		_redraw_view()
		_build_table())


func _on_palace_menu(id: int) -> void:
	match id:
		0:
			UI.file_dialog(self, true, PackedStringArray(["*.palace ; StoryPalace file"]), func(path):
				if not path.ends_with(".palace"):
					path += ".palace"
				Store.flush()
				UI.toast(self, "Exported to %s" % path.get_file() if Store.export_palace(palace, path) else "Could not write that file. Try another folder."),
				palace.name.validate_filename() + ".palace")
		1:
			var c := Store.duplicate_palace(palace)
			UI.toast(self, "Made “%s”" % c.name)
		2:
			UI.confirm(self, "Delete palace", "Delete “%s” with all its rooms and memories? This cannot be undone. Export it first if you want a copy." % palace.name, "Delete palace", func():
				Store.delete_palace(palace)
				back_requested.emit())


# ---------- control descriptions table ----------

func _build_table() -> void:
	for c in _table.get_children():
		_table.remove_child(c)
		c.queue_free()
	var n := 1
	var total := Store.count_items(palace)
	for r in palace.rooms:
		_table.add_child(_room_header(r))
		if r.items.is_empty():
			var e := UI.label("Nothing here yet. Open this room and click anywhere to add a memory.", "Muted", true)
			_table.add_child(UI.margin(e, 8, 0, 8, 8))
		for it in r.items:
			_table.add_child(_row(r, it, n, n == total))
			n += 1


func _room_header(r: Dictionary) -> Control:
	var p := PanelContainer.new()
	var cur := r == room
	var sb := UI.box(UI.TEAL if cur else Color.TRANSPARENT, UI.INK if cur else Color.TRANSPARENT, UI.LINE if cur else 0, 10, Vector4(12, 5, 12, 5))
	p.add_theme_stylebox_override(&"panel", sb)
	var row := UI.hbox(8)
	var l := UI.label(r.name.to_upper(), "Caps")
	l.add_theme_color_override(&"font_color", UI.INK if cur else UI.MUTED)
	row.add_child(l)
	row.add_child(UI.spacer())
	var c := UI.label("%d" % r.items.size(), "Caps")
	c.add_theme_color_override(&"font_color", UI.INK if cur else UI.MUTED)
	row.add_child(c)
	p.add_child(row)
	p.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _switch_room(r))
	return p


func _row(r: Dictionary, it: Dictionary, num: int, is_finish: bool) -> Control:
	var sel: bool = it.id == selected_id
	var p := PanelContainer.new()
	var sb := UI.box(UI.PEACH.lerp(UI.PAPER, 0.55) if sel else UI.PAPER, UI.INK if sel else Color(UI.INK, 0.18), UI.LINE, 12, Vector4(10, 10, 12, 10))
	p.add_theme_stylebox_override(&"panel", sb)
	if not sel:
		var hov := sb.duplicate()
		hov.bg_color = UI.BUTTER_TINT
		hov.border_color = Color(UI.INK, 0.5)
		p.mouse_entered.connect(func(): p.add_theme_stylebox_override(&"panel", hov))
		p.mouse_exited.connect(func(): p.add_theme_stylebox_override(&"panel", sb))
	p.set_meta("item_id", it.id)
	var col := UI.vbox(10)
	p.add_child(col)
	var line := UI.hbox(10)
	col.add_child(line)
	var numl := UI.label(str(num))
	numl.add_theme_font_override(&"font", UI.font("black"))
	numl.add_theme_font_size_override(&"font_size", 15)
	numl.add_theme_color_override(&"font_color", Color.WHITE)
	numl.add_theme_stylebox_override(&"normal", UI.box(UI.PINK, UI.INK, UI.LINE, 13, Vector4(7, 1, 7, 1)))
	numl.custom_minimum_size = Vector2(32, 26)
	numl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numl.size_flags_vertical = SIZE_SHRINK_CENTER
	numl.tooltip_text = "The finish" if is_finish else "Memory %d on the path" % num
	line.add_child(numl)
	line.add_child(_picture_box(it, 44))
	var txt := UI.vbox(2)
	txt.size_flags_horizontal = SIZE_EXPAND_FILL
	var title := UI.label(it.title if it.title != "" else "What should this remind you of?", "H3")
	if it.title == "":
		title.add_theme_color_override(&"font_color", UI.MUTED)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	txt.add_child(title)
	if it.story != "" and not sel:
		var st := UI.label(it.story, "Muted")
		st.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		txt.add_child(st)
	line.add_child(txt)
	if it.recall != "":
		var mark := UI.label("✓ GOT IT" if it.recall == "ok" else "✗ MISSED", "Caps")
		mark.add_theme_color_override(&"font_color", UI.GREEN if it.recall == "ok" else UI.RED)
		mark.tooltip_text = "Result of your last punch test"
		line.add_child(mark)
	if sel:
		var ed := _editor(r, it)
		col.add_child(ed)
		UI.pop_in(ed, 0.0, 0.97)
	else:
		p.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _select(it.id))
	return p


func _picture_box(it: Dictionary, s: int) -> Control:
	var tex: Texture2D = Store.texture(it.image)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(s, s)
		return tr
	var l := UI.label(it.icon)
	l.add_theme_font_size_override(&"font_size", int(s * 0.7))
	l.custom_minimum_size = Vector2(s, s)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _editor(r: Dictionary, it: Dictionary) -> Control:
	var ed := UI.vbox(10)
	var top := UI.hbox(12)
	ed.add_child(top)
	var pic := Button.new()
	pic.theme_type_variation = "Button"
	pic.custom_minimum_size = Vector2(84, 84)
	pic.tooltip_text = "Change picture"
	pic.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	var pb := _picture_box(it, 64)
	pb.mouse_filter = MOUSE_FILTER_IGNORE
	var cc := CenterContainer.new()
	cc.mouse_filter = MOUSE_FILTER_IGNORE
	cc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cc.add_child(pb)
	pic.add_child(cc)
	pic.pressed.connect(func(): _pick_picture(it))
	top.add_child(pic)
	var f := UI.vbox(6)
	f.size_flags_horizontal = SIZE_EXPAND_FILL
	f.add_child(UI.label("What to remember", "Caps"))
	var title := LineEdit.new()
	title.name = "TitleField"
	title.text = it.title
	title.placeholder_text = "e.g. Mars, the 4th planet"
	f.add_child(title)
	var ideas := UI.hbox(2)
	f.add_child(ideas)
	top.add_child(f)
	var fill_ideas := func():
		for c in ideas.get_children():
			c.queue_free()
		for e in Emoji.suggest(title.text, 6):
			var b := Pickers._emoji_button(e, func():
				it.icon = e
				it.image = ""
				it.erase("auto_icon")
				Store.mark_dirty(palace)
				_redraw_view()
				_build_table())
			b.custom_minimum_size = Vector2(36, 36)
			b.add_theme_font_size_override(&"font_size", 20)
			b.tooltip_text = "Use this picture"
			ideas.add_child(b)
	title.text_changed.connect(func(t):
		it.title = t
		# a fresh control borrows the first idea until the user picks a picture themselves
		if it.image == "" and (it.icon == "⭐" or it.get("auto_icon", false)):
			var s := Emoji.suggest(t, 1)
			if not s.is_empty():
				it.icon = s[0]
				it.auto_icon = true
				if pb is Label:
					pb.text = s[0]
		Store.mark_dirty(palace)
		_redraw_view()
		fill_ideas.call())
	title.text_submitted.connect(func(_t): ed.get_node("Story").grab_focus())
	fill_ideas.call()

	ed.add_child(UI.label("The story: make it big, funny or strange", "Caps"))
	var story := TextEdit.new()
	story.name = "Story"
	story.text = it.story
	story.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	story.placeholder_text = "Picture it in this exact spot. What is it doing? What does it sound or smell like?"
	story.custom_minimum_size.y = 110
	story.text_changed.connect(func(): it.story = story.text; Store.mark_dirty(palace))
	ed.add_child(story)

	var actions := UI.hbox(8)
	var i: int = r.items.find(it)
	var up := UI.button("Earlier", "arrow-up", "Button", "Move earlier on the path")
	up.disabled = i == 0
	up.pressed.connect(func(): _move(it.id, -1))
	var down := UI.button("Later", "arrow-down", "Button", "Move later on the path")
	down.disabled = i == r.items.size() - 1
	down.pressed.connect(func(): _move(it.id, 1))
	actions.add_child(up)
	actions.add_child(down)
	actions.add_child(UI.spacer())
	var del := UI.button("Remove", "trash-2", "FlatButton", "Remove this control (Delete)")
	del.add_theme_color_override(&"font_color", UI.RED)
	del.add_theme_color_override(&"font_hover_color", UI.RED)
	del.add_theme_color_override(&"icon_normal_color", UI.RED)
	del.add_theme_color_override(&"icon_hover_color", UI.RED)
	del.pressed.connect(func(): _remove(it.id))
	actions.add_child(del)
	ed.add_child(actions)
	return ed


func _focus_title() -> void:
	var f := _table.find_child("TitleField", true, false)
	if f:
		f.grab_focus()


func _scroll_to_selected() -> void:
	for c in _table.get_children():
		if c.has_meta("item_id") and c.get_meta("item_id") == selected_id:
			_scroll.ensure_control_visible(c)
