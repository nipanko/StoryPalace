class_name PalaceScreen
extends Control
## The palace editor: toolbar, Rooms panel, the room canvas (2D map or 3D walk),
## Memories panel, and a status bar.

signal back_requested
signal run_requested(mode: String)   # "run" or "test"

var palace: Dictionary
var room: Dictionary
var selected_id := ""

var _title: LineEdit
var _crumb: Button
var _rooms_panel: Control
var _rooms: VBoxContainer
var _room_panel: Dictionary
var _mem_panel: Dictionary
var _mem_count: PanelContainer
var _holder: Control
var _hint: Label
var _counts: Label
var _saved: Label
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
	add_child(UI.backdrop())
	var root := UI.vbox(0)
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_toolbar())
	var body := UI.hbox(UI.S3)
	var bm := UI.margin(body, UI.S3, UI.S3, UI.S3, UI.S3)
	bm.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(bm)
	root.add_child(_status_bar())

	# Rooms
	var rp := UI.panel("Rooms")
	_rooms_panel = rp.root
	var add := UI.icon_button("plus", "Add a room")
	add.pressed.connect(_add_room)
	rp.bar.add_child(add)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rooms = UI.vbox(2)
	_rooms.size_flags_horizontal = SIZE_EXPAND_FILL
	rs.add_child(UI.margin(_rooms, UI.S2, UI.S2, UI.S2, UI.S2))
	_rooms.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL
	rp.body.add_child(rs)
	body.add_child(_rooms_panel)

	# The room canvas
	_room_panel = UI.panel("")
	_room_panel.root.size_flags_horizontal = SIZE_EXPAND_FILL
	var opts := UI.icon_button("ellipsis-vertical", "Room options")
	opts.pressed.connect(_room_menu)
	_room_panel.bar.add_child(opts)
	_holder = Control.new()
	_holder.clip_contents = true
	_room_panel.body.add_child(_holder)
	body.add_child(_room_panel.root)

	# Memories
	_mem_panel = UI.panel("Memories")
	_mem_count = UI.badge("0")
	_mem_panel.bar.add_child(_mem_count)
	_mem_panel.bar.add_child(UI.margin(Control.new(), 0, 0, UI.S1, 0))
	body.add_child(_mem_panel.root)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_mem_panel.body.add_child(_scroll)
	_table = UI.vbox(2)
	_table.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(UI.margin(_table, UI.S2, UI.S2, UI.S2, UI.S2))
	_table.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL

	Store.changed.connect(_on_store_changed)
	Store.saved.connect(_on_store_saved)
	resized.connect(_fit)
	_fit()
	_set_view(Store.settings.get("view", "2d"))
	_refresh_all()


## Responsive layout: the Rooms panel folds to thumbnails and labels drop on narrow windows.
func _fit() -> void:
	var w := size.x
	var compact := w < 1200
	_rooms_panel.custom_minimum_size.x = 92 if compact else 232
	(_rooms_panel.find_child("Title", true, false) as Label).text = "" if compact else "Rooms"
	_mem_panel.root.custom_minimum_size.x = clampf(w * 0.27, 320, 400)
	var narrow := w < 1100
	_run.text = "" if narrow else "Run the course"
	_test.text = "" if narrow else "Punch test"
	_crumb.visible = not narrow
	if compact != _compact:
		_compact = compact
		if is_node_ready():
			_build_rooms()


func _toolbar() -> Control:
	var tb := UI.bar(UI.BAR_H)
	var row: HBoxContainer = tb.row
	var back := UI.icon_button("arrow-left", "All palaces")
	back.pressed.connect(func(): back_requested.emit())
	row.add_child(back)
	row.add_child(UI.logo(24))
	_crumb = UI.button("Palaces", "", "FlatButton", "All palaces")
	_crumb.add_theme_color_override(&"font_color", UI.MUTED)
	_crumb.pressed.connect(func(): back_requested.emit())
	row.add_child(_crumb)
	_title = LineEdit.new()
	_title.theme_type_variation = "TitleEdit"
	_title.text = palace.name
	_title.expand_to_text_length = true
	_title.custom_minimum_size.x = 80
	_title.max_length = 60
	_title.size_flags_vertical = SIZE_SHRINK_CENTER
	_title.tooltip_text = "Rename this palace"
	_title.text_changed.connect(func(t): palace.name = t if t.strip_edges() != "" else "Untitled palace"; Store.mark_dirty(palace))
	_title.text_submitted.connect(func(_t): _title.release_focus())
	row.add_child(_title)
	row.add_child(UI.spacer())

	var track := PanelContainer.new()
	track.add_theme_stylebox_override(&"panel", UI.box(UI.SUNKEN, Color.TRANSPARENT, 0, 7, Vector4(2, 2, 2, 2)))
	track.size_flags_vertical = SIZE_SHRINK_CENTER
	var seg := UI.hbox(2)
	track.add_child(seg)
	var g := ButtonGroup.new()
	_seg2 = UI.button("2D", "square", "SegButton", "Flat map of each room")
	_seg3 = UI.button("3D", "box", "SegButton", "Walk through your palace in 3D")
	for b in [_seg2, _seg3]:
		b.toggle_mode = true
		b.button_group = g
		seg.add_child(b)
	_seg2.pressed.connect(func(): _set_view("2d"))
	_seg3.pressed.connect(func(): _set_view("3d"))
	row.add_child(track)
	row.add_child(UI.theme_button())
	row.add_child(UI.vrule())
	_test = UI.button("Punch test", "check", "Button", "Test what you remember  (T)")
	_test.pressed.connect(func(): run_requested.emit("test"))
	row.add_child(_test)
	_run = UI.button("Run the course", "play", "PrimaryButton", "Walk the path memory by memory  (R)")
	_run.pressed.connect(func(): run_requested.emit("run"))
	row.add_child(_run)
	var more := UI.icon_button("ellipsis-vertical", "More")
	var menu := PopupMenu.new()
	menu.add_item("Export palace to a file…", 0)
	menu.add_item("Duplicate palace", 1)
	menu.add_separator()
	menu.add_item("Delete palace…", 2)
	menu.id_pressed.connect(_on_palace_menu)
	more.add_child(menu)
	more.pressed.connect(func(): menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO)))
	row.add_child(more)
	return tb.root


func _status_bar() -> Control:
	var sb := UI.bar(28, true)
	_hint = UI.label("", "Muted")
	_hint.add_theme_font_size_override(&"font_size", 12)
	_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hint.size_flags_horizontal = SIZE_EXPAND_FILL
	sb.row.add_child(_hint)
	_counts = UI.label("", "Muted")
	_counts.add_theme_font_size_override(&"font_size", 12)
	sb.row.add_child(_counts)
	sb.row.add_child(UI.vrule())
	_saved = UI.label("All changes saved", "Muted")
	_saved.add_theme_font_size_override(&"font_size", 12)
	_saved.custom_minimum_size.x = 112
	sb.row.add_child(_saved)
	return sb.root


func _on_store_changed(id: String) -> void:
	if id == palace.id:
		_saved.text = "Saving…"


func _on_store_saved() -> void:
	_saved.text = "All changes saved"


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
		_world.selected.connect(_select)
		_world.added.connect(_on_added)
		_world.room_entered.connect(func(r): if r != room: _switch_room(r, false))
		_world.go_to_room(room)
		_hint.text = "Drag to look around  ·  W A S D or arrow keys to walk  ·  Click the floor or a wall to add a memory"
	else:
		_map = MapView.new()
		_map.palace = palace
		_map.room = room
		_map.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_holder.add_child(_map)
		_map.selected.connect(_select)
		_map.added.connect(_on_added)
		_map.moved.connect(func(_it): Store.mark_dirty(palace))
		_map.delete_requested.connect(_remove)
		_map.context.connect(_on_context)
		_hint.text = "Click the room to add a memory  ·  Drag to move  ·  Right-click for options  ·  Delete removes"
	UI.fade_in(_holder.get_child(_holder.get_child_count() - 1))
	_sync_selection()


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


func _range_text(first: int, n: int) -> String:
	if n == 0:
		return "No memories"
	return "Memory %d" % first if n == 1 else "Memories %d–%d" % [first, first + n - 1]


func _update_guide() -> void:
	var first := 1
	for r in palace.rooms:
		if r == room:
			break
		first += r.items.size()
	var total := Store.count_items(palace)
	var n: int = room.get("items", []).size()
	_room_panel.bar.get_node("Title").text = "%s   ·   %s" % [room.get("name", ""), _range_text(first, n)]
	(_mem_count.get_child(0) as Label).text = str(total)
	_counts.text = "%s  ·  %s" % [UI.plural(palace.rooms.size(), "room", "rooms"), UI.plural(total, "memory", "memories")]


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
	add.add_theme_color_override(&"font_color", UI.MUTED)
	add.add_theme_color_override(&"icon_normal_color", UI.MUTED)
	add.size_flags_vertical = SIZE_FILL
	add.pressed.connect(_add_room)
	_rooms.add_child(add)


func _room_row(r: Dictionary, first: int) -> Control:
	var cur: bool = r == room
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.tooltip_text = "%s\nRight-click for room options" % r.name
	var pad := Vector4(UI.S2, 6, UI.S2, 6)
	var sel := UI.box(UI.ACCENT_TINT, Color.TRANSPARENT, 0, UI.R_CONTROL, pad)
	b.add_theme_stylebox_override(&"normal", sel if cur else UI.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, UI.R_CONTROL, pad))
	b.add_theme_stylebox_override(&"hover", sel if cur else UI.box(UI.HOVER, Color.TRANSPARENT, 0, UI.R_CONTROL, pad))
	b.add_theme_stylebox_override(&"pressed", sel)
	var row := UI.hbox(10)
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 6)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Frame"
	var th := Thumb.new()
	th.room = r
	th.custom_minimum_size = Vector2(64, 40)
	frame.add_child(th)
	frame.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(frame)
	if not _compact:
		var t := UI.vbox(0)
		t.size_flags_horizontal = SIZE_EXPAND_FILL
		t.alignment = BoxContainer.ALIGNMENT_CENTER
		var name := UI.label(r.name, "H3")
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if cur:
			name.add_theme_color_override(&"font_color", UI.ACCENT)
		t.add_child(name)
		var sub := UI.label(_range_text(first, r.items.size()), "Muted")
		sub.add_theme_font_size_override(&"font_size", 12)
		t.add_child(sub)
		row.add_child(t)
	b.add_child(row)
	for c in row.find_children("*", "Control", true, false) + [row]:
		c.mouse_filter = MOUSE_FILTER_IGNORE
	b.custom_minimum_size = Vector2(0, 54)
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
			_refresh_all()
		)
	elif id == 2 or id == 3:
		palace.rooms.remove_at(i)
		palace.rooms.insert(i + (-1 if id == 2 else 1), room)
		Store.mark_dirty(palace)
		_redraw_view()
		_refresh_all()
	elif id == 4:
		var n: int = room.items.size()
		var what := "" if n == 0 else " and its %s" % UI.plural(n, "memory", "memories")
		UI.confirm(self, "Delete room", "Delete “%s”%s? This cannot be undone." % [room.name, what], "Delete room", func():
			palace.rooms.erase(room)
			Store.mark_dirty(palace)
			_redraw_view()
			_switch_room(palace.rooms[clampi(i - 1, 0, palace.rooms.size() - 1)])
		)


# ---------- memories ----------

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
	var f := _table.find_child("TitleField", true, false)
	if f:
		UI.focus_later(f)
	_scroll_to_selected.call_deferred()


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
				UI.toast(self, "Memory removed", ["Undo", _do_undo], 6.0)
				return


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
			_scroll_to_selected.call_deferred()
			return


func _on_context(it: Dictionary, _at: Vector2) -> void:
	var menu := PopupMenu.new()
	menu.add_item("Change picture…", 0)
	menu.add_item("Remove memory", 1)
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
			UI.toast(self, "Made “%s”. Find it under Palaces." % c.name)
		2:
			UI.confirm(self, "Delete palace", "Delete “%s” with all its rooms and memories? This cannot be undone. Export it first if you want a copy." % palace.name, "Delete palace", func():
				Store.delete_palace(palace)
				back_requested.emit())


# ---------- memories list ----------

func _build_table() -> void:
	for c in _table.get_children():
		_table.remove_child(c)
		c.queue_free()
	var n := 1
	var total := Store.count_items(palace)
	for r in palace.rooms:
		_table.add_child(_room_header(r))
		if r.items.is_empty():
			var e := UI.label("No memories in this room yet. Open it and click anywhere to add one.", "Muted", true)
			_table.add_child(UI.margin(e, UI.S2, 0, UI.S2, UI.S2))
		for it in r.items:
			_table.add_child(_row(r, it, n, n == total))
			n += 1


func _room_header(r: Dictionary) -> Control:
	var cur: bool = r == room
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.custom_minimum_size.y = 28
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.tooltip_text = "Open %s" % r.name
	b.add_theme_stylebox_override(&"normal", UI.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, UI.R_CONTROL, Vector4(UI.S2, 2, UI.S2, 2)))
	var row := UI.hbox(UI.S2)
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, UI.S2)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	var l := UI.label(r.name.to_upper(), "Caps")
	l.add_theme_color_override(&"font_color", UI.ACCENT if cur else UI.SUBTLE)
	l.size_flags_horizontal = SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(l)
	var c := UI.label(str(r.items.size()), "Caps")
	c.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(c)
	b.add_child(row)
	b.pressed.connect(func(): _switch_room(r))
	return b


func _row(r: Dictionary, it: Dictionary, num: int, is_finish: bool) -> Control:
	var sel: bool = it.id == selected_id
	var p := PanelContainer.new()
	var pad := Vector4(UI.S2, UI.S2, UI.S2, UI.S2)
	var sb := UI.box(UI.ACCENT_TINT if sel else Color.TRANSPARENT, Color.TRANSPARENT, 0, UI.R_CONTROL, pad)
	p.add_theme_stylebox_override(&"panel", sb)
	if not sel:
		var hov := UI.box(UI.HOVER, Color.TRANSPARENT, 0, UI.R_CONTROL, pad)
		p.mouse_entered.connect(func(): p.add_theme_stylebox_override(&"panel", hov))
		p.mouse_exited.connect(func(): p.add_theme_stylebox_override(&"panel", sb))
	p.set_meta("item_id", it.id)
	var col := UI.vbox(UI.S3)
	p.add_child(col)
	var line := UI.hbox(10)
	col.add_child(line)
	var tag := UI.number_tag(num)
	tag.tooltip_text = "The finish" if is_finish else "Memory %d on the path" % num
	line.add_child(tag)
	line.add_child(_picture_box(it, 32))
	var txt := UI.vbox(0)
	txt.size_flags_horizontal = SIZE_EXPAND_FILL
	txt.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := UI.label(it.title if it.title != "" else "Untitled memory", "H3")
	if it.title == "":
		title.add_theme_color_override(&"font_color", UI.SUBTLE)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	txt.add_child(title)
	if it.story != "" and not sel:
		var st := UI.label(it.story.replace("\n", " "), "Muted")
		st.add_theme_font_size_override(&"font_size", 12)
		st.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		txt.add_child(st)
	line.add_child(txt)
	if it.recall != "":
		var mark := UI.badge("Got it" if it.recall == "ok" else "Missed", "success" if it.recall == "ok" else "danger")
		mark.tooltip_text = "Result of your last punch test"
		line.add_child(mark)
	if sel:
		col.add_child(_editor(r, it))
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
	l.add_theme_font_size_override(&"font_size", int(s * 0.72))
	l.custom_minimum_size = Vector2(s, s)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _field_label(text: String) -> Label:
	var l := UI.label(text, "Muted")
	l.add_theme_font_override(&"font", UI.font("medium"))
	l.add_theme_font_size_override(&"font_size", 12)
	return l


func _editor(r: Dictionary, it: Dictionary) -> Control:
	var ed := UI.vbox(UI.S3)
	var top := UI.hbox(UI.S3)
	ed.add_child(top)
	var pic := Button.new()
	pic.custom_minimum_size = Vector2(72, 72)
	pic.tooltip_text = "Change picture"
	pic.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	pic.size_flags_vertical = SIZE_SHRINK_BEGIN
	var pb := _picture_box(it, 48)
	pb.mouse_filter = MOUSE_FILTER_IGNORE
	var cc := CenterContainer.new()
	cc.mouse_filter = MOUSE_FILTER_IGNORE
	cc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cc.add_child(pb)
	pic.add_child(cc)
	pic.pressed.connect(func(): _pick_picture(it))
	top.add_child(pic)
	var f := UI.vbox(UI.S1)
	f.size_flags_horizontal = SIZE_EXPAND_FILL
	f.add_child(_field_label("What to remember"))
	var title := LineEdit.new()
	title.name = "TitleField"
	title.text = it.title
	title.placeholder_text = "e.g. Mars, the 4th planet"
	title.max_length = 120
	f.add_child(title)
	var ideas := UI.hbox(2)
	ideas.custom_minimum_size.y = 28
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
			b.custom_minimum_size = Vector2(28, 28)
			b.add_theme_font_size_override(&"font_size", 16)
			b.tooltip_text = "Use this picture"
			ideas.add_child(b)
	title.text_changed.connect(func(t):
		it.title = t
		# a fresh memory borrows the first idea until the user picks a picture themselves
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
	title.text_submitted.connect(func(_t): ed.get_node("StoryBox/Story").grab_focus())
	fill_ideas.call()

	var sbx := UI.vbox(UI.S1)
	sbx.name = "StoryBox"
	sbx.add_child(_field_label("The story"))
	var story := TextEdit.new()
	story.name = "Story"
	story.text = it.story
	story.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	story.placeholder_text = "Make it big, funny or strange. What is it doing in this exact spot?"
	story.custom_minimum_size.y = 96
	story.text_changed.connect(func(): it.story = story.text; Store.mark_dirty(palace))
	sbx.add_child(story)
	ed.add_child(sbx)

	var actions := UI.hbox(UI.S2)
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
	var del := UI.button("Remove", "trash-2", "DangerButton", "Remove this memory  (Delete)")
	del.pressed.connect(func(): _remove(it.id))
	actions.add_child(del)
	ed.add_child(actions)
	return ed


func _scroll_to_selected() -> void:
	for c in _table.get_children():
		if c.has_meta("item_id") and c.get_meta("item_id") == selected_id:
			_scroll.ensure_control_visible(c)
