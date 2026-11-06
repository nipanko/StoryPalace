class_name Home
extends Control
## All palaces as a library of map sheets, plus the legend that teaches the notation.

signal open_requested(palace: Dictionary)


class Contours extends Control:
	## Brown contour hairlines: the map's ground texture.
	var _lines: Array = []

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(func(): _lines.clear(); queue_redraw())

	func _draw() -> void:
		if _lines.is_empty():
			for hill in [[0.92, 0.08, 9, 1.0], [0.06, 0.9, 7, 2.3], [0.62, 1.05, 6, 4.1]]:
				var c := Vector2(hill[0], hill[1]) * size
				for k in range(1, int(hill[2]) + 1):
					var pts := PackedVector2Array()
					for i in 97:
						var a := TAU * i / 96.0
						var rr := k * 46.0 * (1.0 + 0.14 * sin(3.0 * a + hill[3] + k * 0.3) + 0.07 * sin(5.0 * a + k * 0.7))
						pts.append(c + Vector2(cos(a), sin(a)) * rr)
					_lines.append([pts, k % 5 == 0])
		for l in _lines:
			draw_polyline(l[0], Color(UI.BROWN, 0.26 if l[1] else 0.16), 2.0 if l[1] else 1.2, true)


class Symbol extends Control:
	## Legend symbols drawn with the course notation itself.
	var kind := "control"

	func _ready() -> void:
		custom_minimum_size = Vector2(56, 56)

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"start": Course.draw_start(self, c, 20, c + Vector2.UP)
			"control": Course.draw_control(self, c, 18, 1, {"icon": "🍎"})
			"finish": Course.draw_control(self, c, 15, 8, {"icon": "🏁"}, {"finish": true, "show_number": false})


var _grid: HFlowContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := Contours.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var col := UI.vbox(28)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(UI.margin(col, 48, 36, 48, 28))
	col.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL

	var head := UI.hbox(14)
	var mark := Symbol.new()
	mark.kind = "start"
	head.add_child(mark)
	var name := UI.label("Memory Palace", "Display")
	name.add_theme_font_size_override(&"font_size", 40)
	head.add_child(name)
	head.add_child(UI.spacer())
	var imp := UI.button("Import a palace…", "upload", "Button", "Open a .palace file someone shared with you")
	imp.pressed.connect(_import)
	head.add_child(imp)
	var new := UI.button("New palace", "plus", "PrimaryButton")
	new.pressed.connect(_new_palace)
	head.add_child(new)
	col.add_child(head)

	if not Store.settings.get("seen_intro", false):
		col.add_child(_legend())

	var sec := UI.hbox(12)
	sec.add_child(UI.label("Your palaces", "H2"))
	col.add_child(sec)
	_grid = HFlowContainer.new()
	_grid.add_theme_constant_override(&"h_separation", 24)
	_grid.add_theme_constant_override(&"v_separation", 24)
	col.add_child(_grid)
	_fill()

	var foot := UI.label("Built with 💖 by Storybook Interactive Private Limited", "Muted")
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(UI.margin(foot, 0, 24, 0, 0))
	Store.changed.connect(func(_id): if is_inside_tree(): _fill())


func _legend() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", UI.box(UI.PAPER, UI.INK, UI.RULE, 4, Vector4(24, 18, 12, 18)))
	var row := UI.hbox(28)
	p.add_child(row)
	var intro := UI.vbox(4)
	intro.custom_minimum_size.x = 220
	intro.add_child(UI.label("How it works", "H2"))
	intro.add_child(UI.label("A memory palace is a walk through a place you know, with a striking picture at every stop.", "Muted", true))
	row.add_child(intro)
	for e in [["start", "Start", "Pick a place you know well: your home, your school, your street."],
			["control", "Control", "Click a spot and put a vivid picture there for each thing to remember."],
			["finish", "Finish", "Run the course in order, then take the punch test to see what stuck."]]:
		var b := UI.hbox(10)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		var s := Symbol.new()
		s.kind = e[0]
		b.add_child(s)
		var t := UI.vbox(2)
		t.size_flags_horizontal = SIZE_EXPAND_FILL
		t.add_child(UI.label(e[1], "H3"))
		t.add_child(UI.label(e[2], "Muted", true))
		b.add_child(t)
		row.add_child(b)
	var close := UI.icon_button("x", "Hide this")
	close.size_flags_vertical = SIZE_SHRINK_BEGIN
	close.pressed.connect(func(): Store.settings.seen_intro = true; Store.save_settings(); p.queue_free())
	row.add_child(close)
	return p


func _fill() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for p in Store.palaces:
		_grid.add_child(_tile(p))
	var add := Button.new()
	add.theme_type_variation = "FlatButton"
	add.custom_minimum_size = Vector2(336, 290)
	add.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	add.tooltip_text = "Start a new palace"
	add.add_theme_stylebox_override(&"normal", UI.box(Color(1, 1, 1, 0.8), Color(UI.PURPLE, 0.55), 2, 4))
	add.add_theme_stylebox_override(&"hover", UI.box(UI.PURPLE_TINT, UI.PURPLE, 2, 4))
	var cc := CenterContainer.new()
	cc.mouse_filter = MOUSE_FILTER_IGNORE
	cc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var v := UI.vbox(10)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	var plus := TextureRect.new()
	plus.texture = UI.icon("plus")
	plus.modulate = UI.PURPLE
	plus.custom_minimum_size = Vector2(36, 36)
	plus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plus.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(plus)
	var l := UI.label("Start a new palace", "H2")
	l.add_theme_color_override(&"font_color", UI.PURPLE)
	v.add_child(l)
	var hint := UI.label("Your home, a walk to school,
any place you know by heart", "Muted")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	for c in v.get_children():
		c.mouse_filter = MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cc.add_child(v)
	add.add_child(cc)
	add.pressed.connect(_new_palace)
	_grid.add_child(add)


func _tile(p: Dictionary) -> Control:
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.custom_minimum_size = Vector2(336, 290)
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.add_theme_stylebox_override(&"normal", UI.box(Color(1, 1, 1, 0.85), Color.TRANSPARENT, 0, 4, Vector4(8, 8, 8, 8)))
	b.tooltip_text = "Open “%s”" % p.name
	var col := UI.vbox(6)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 8)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Frame"
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	var th := Thumb.new()
	th.custom_minimum_size = Vector2(316, 196)
	if not p.rooms.is_empty():
		th.room = p.rooms[0]
		th.palace = p
	frame.add_child(th)
	col.add_child(frame)
	var name := UI.label(p.name, "H2")
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(name)
	var n := Store.count_items(p)
	var meta := UI.label("%d room%s  ·  %d control%s" % [p.rooms.size(), "" if p.rooms.size() == 1 else "s", n, "" if n == 1 else "s"], "Muted")
	meta.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(meta)
	var res := UI.ago(p.practiced)
	if p.score >= 0:
		res += "  ·  %d%% punched" % p.score
	var r := UI.label(res.to_upper(), "Caps")
	r.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(r)
	b.add_child(col)
	b.pressed.connect(func(): open_requested.emit(p))
	b.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT: _tile_menu(p))
	return b


func _tile_menu(p: Dictionary) -> void:
	var menu := PopupMenu.new()
	menu.add_item("Open", 0)
	menu.add_item("Duplicate", 1)
	menu.add_item("Export to a file…", 2)
	menu.add_separator()
	menu.add_item("Delete…", 3)
	menu.id_pressed.connect(func(id): _on_tile_menu(id, p))
	menu.popup_hide.connect(menu.queue_free)
	add_child(menu)
	menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _on_tile_menu(id: int, p: Dictionary) -> void:
	if id == 0:
		open_requested.emit(p)
	elif id == 1:
		Store.duplicate_palace(p)
	elif id == 2:
		UI.file_dialog(self, true, PackedStringArray(["*.palace ; Memory Palace file"]), func(path): _export(p, path), p.name.validate_filename() + ".palace")
	elif id == 3:
		UI.confirm(self, "Delete palace", "Delete “%s” with all its rooms and memories? This cannot be undone." % p.name, "Delete palace", func(): Store.delete_palace(p))


func _export(p: Dictionary, path: String) -> void:
	if not path.ends_with(".palace"):
		path += ".palace"
	Store.flush()
	UI.toast(self, "Exported to %s" % path.get_file() if Store.export_palace(p, path) else "Could not write that file. Try another folder.")


func _new_palace() -> void:
	Pickers.ask_text(self, "Name your palace", "", func(name):
		Pickers.room(self, "Where does “%s” start?" % name, func(choice):
			var p := Store.create_palace(name)
			var t: String = choice.get("theme", "living")
			p.rooms[0] = Store.new_room(choice.get("name", SceneArt.theme(t).name), t, choice.get("photo", ""))
			Store.mark_dirty(p)
			open_requested.emit(p)))


func _import() -> void:
	UI.file_dialog(self, false, PackedStringArray(["*.palace ; Memory Palace file"]), func(path):
		var p := Store.import_palace(path)
		if p.is_empty():
			UI.toast(self, "That file is not a Memory Palace export.")
		else:
			open_requested.emit(p))
