class_name PalaceScreen
extends Control
## The palace editor: map sheet tabs (rooms), the map or 3D view, and the control descriptions.

signal back_requested
signal run_requested(mode: String)   # "run" or "test"

var palace: Dictionary
var room: Dictionary
var selected_id := ""

var _title: LineEdit
var _guide: Label
var _tabs: HBoxContainer
var _holder: Control
var _hint: Label
var _table: VBoxContainer
var _scroll: ScrollContainer
var _count: Label
var _seg2: Button
var _seg3: Button
var _map: MapView
var _world: PalaceWorld
var _undo := {}


func setup(p: Dictionary) -> void:
	palace = p
	room = p.rooms[0] if not p.rooms.is_empty() else {}


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := UI.vbox(0)
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_top_bar())
	var body := UI.hbox(20)
	body.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(UI.margin(body, 20, 16, 20, 16))
	body.get_parent().size_flags_vertical = SIZE_EXPAND_FILL

	var left := UI.vbox(0)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(left)
	_tabs = UI.hbox(4)
	left.add_child(_tabs)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Frame"
	frame.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_child(frame)
	_holder = Control.new()
	_holder.clip_contents = true
	frame.add_child(_holder)
	_hint = UI.label("", "Muted")
	left.add_child(UI.margin(_hint, 2, 10, 0, 0))

	var right := UI.vbox(10)
	right.custom_minimum_size.x = 400
	body.add_child(right)
	var head := UI.hbox()
	head.add_child(UI.label("Control descriptions", "H2"))
	head.add_child(UI.spacer())
	_count = UI.label("", "Muted")
	head.add_child(_count)
	right.add_child(head)
	var tframe := PanelContainer.new()
	tframe.theme_type_variation = "Frame"
	tframe.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(tframe)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tframe.add_child(_scroll)
	_table = UI.vbox(0)
	_table.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(_table)

	_set_view(Store.settings.get("view", "2d"))
	_refresh_all()


func _top_bar() -> Control:
	var bar := PanelContainer.new()
	var sb := UI.box(UI.PAPER, UI.INK, 0, 0, Vector4(12, 10, 20, 10))
	sb.border_width_bottom = UI.RULE
	bar.add_theme_stylebox_override(&"panel", sb)
	var row := UI.hbox(14)
	bar.add_child(row)
	var back := UI.icon_button("arrow-left", "All palaces")
	back.pressed.connect(func(): back_requested.emit())
	row.add_child(back)
	_title = LineEdit.new()
	_title.theme_type_variation = "TitleEdit"
	_title.text = palace.name
	_title.expand_to_text_length = true
	_title.custom_minimum_size.x = 120
	_title.tooltip_text = "Rename this palace"
	_title.text_changed.connect(func(t): palace.name = t if t.strip_edges() != "" else "Untitled palace"; Store.mark_dirty(palace))
	_title.text_submitted.connect(func(_t): _title.release_focus())
	row.add_child(_title)
	_guide = UI.label("", "Muted")
	row.add_child(_guide)
	row.add_child(UI.spacer())
	var seg := UI.hbox(0)
	var g := ButtonGroup.new()
	_seg2 = UI.button("2D map", "", "SegButton", "Flat map of each room")
	_seg3 = UI.button("3D walk", "", "SegButton", "Walk through your palace in 3D")
	for b in [_seg2, _seg3]:
		b.toggle_mode = true
		b.button_group = g
		seg.add_child(b)
	_seg2.pressed.connect(func(): _set_view("2d"))
	_seg3.pressed.connect(func(): _set_view("3d"))
	row.add_child(seg)
	var run := UI.button("Run the course", "play", "PrimaryButton", "Walk the path control by control  (R)")
	run.pressed.connect(func(): run_requested.emit("run"))
	row.add_child(run)
	var test := UI.button("Punch test", "check", "Button", "Test what you remember  (T)")
	test.pressed.connect(func(): run_requested.emit("test"))
	row.add_child(test)
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
	return bar


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
	for c in _holder.get_children():
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
		_hint.text = "Drag to look around  ·  W A S D or arrow keys to walk  ·  click the floor or a wall to add a control"
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
		_hint.text = "Click the map to add a control  ·  drag a control to move it  ·  right-click for options"
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
	_build_tabs()
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
	_guide.text = "%s  ·  %s" % [room.get("name", ""), "no controls yet" if n == 0 else ("control %d of %d" % [first, total] if n == 1 else "controls %d–%d of %d" % [first, first + n - 1, total])]
	_count.text = "%d control%s" % [total, "" if total == 1 else "s"]


func _build_tabs() -> void:
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	var g := ButtonGroup.new()
	for r in palace.rooms:
		var b := UI.button(r.name, "", "TabButton", "Right-click for room options")
		b.toggle_mode = true
		b.button_group = g
		b.button_pressed = r == room
		b.pressed.connect(func(): _switch_room(r))
		b.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT: _switch_room(r); _room_menu())
		_tabs.add_child(b)
	var add := UI.button("Add room", "plus", "FlatButton", "Add another room to the path")
	add.pressed.connect(_add_room)
	_tabs.add_child(add)
	_tabs.add_child(UI.spacer())
	if not room.is_empty():
		var opts := UI.button("Room options", "ellipsis-vertical", "FlatButton")
		opts.pressed.connect(_room_menu)
		_tabs.add_child(opts)


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
	var l := UI.label("Control removed")
	l.add_theme_color_override(&"font_color", UI.PAPER)
	row.add_child(l)
	var b := UI.button("Undo", "rotate-ccw", "FlatButton", "Ctrl+Z")
	b.add_theme_color_override(&"font_color", UI.YELLOW)
	b.add_theme_color_override(&"icon_normal_color", UI.YELLOW)
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
			UI.file_dialog(self, true, PackedStringArray(["*.palace ; Memory Palace file"]), func(path):
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
			var e := UI.label("No controls yet. Click the map to add one.", "Muted", true)
			_table.add_child(UI.margin(e, 16, 10, 16, 12))
		for it in r.items:
			_table.add_child(_row(r, it, n, n == total))
			n += 1


func _room_header(r: Dictionary) -> Control:
	var p := PanelContainer.new()
	var cur := r == room
	var sb := UI.box(UI.INK if cur else Color("#F3F2EE"), Color.TRANSPARENT, 0, 0, Vector4(16, 8, 16, 8))
	p.add_theme_stylebox_override(&"panel", sb)
	var row := UI.hbox(8)
	var l := UI.label(r.name.to_upper(), "Caps")
	l.add_theme_color_override(&"font_color", UI.PAPER if cur else UI.MUTED)
	row.add_child(l)
	row.add_child(UI.spacer())
	var c := UI.label("%d" % r.items.size(), "Caps")
	c.add_theme_color_override(&"font_color", UI.PAPER if cur else UI.MUTED)
	row.add_child(c)
	p.add_child(row)
	p.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _switch_room(r))
	return p


func _row(r: Dictionary, it: Dictionary, num: int, is_finish: bool) -> Control:
	var sel: bool = it.id == selected_id
	var p := PanelContainer.new()
	var sb := UI.box(UI.PURPLE_TINT if sel else UI.PAPER, UI.INK, 0, 0, Vector4(8, 10, 14, 10))
	sb.border_width_bottom = 1
	sb.border_color = Color(UI.INK, 0.35)
	p.add_theme_stylebox_override(&"panel", sb)
	p.set_meta("item_id", it.id)
	var col := UI.vbox(10)
	p.add_child(col)
	var line := UI.hbox(10)
	col.add_child(line)
	var numl := UI.label(str(num), "Numeral")
	numl.custom_minimum_size.x = 40
	numl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numl.tooltip_text = "Finish" if is_finish else ""
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
		var mark := UI.label("✓ Punched" if it.recall == "ok" else "✗ Missed", "Caps")
		mark.add_theme_color_override(&"font_color", UI.GREEN_TEXT if it.recall == "ok" else UI.RED)
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
