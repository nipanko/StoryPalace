class_name Home
extends Control
## All palaces as a library of map sheets, plus the legend that teaches the notation.

signal open_requested(palace: Dictionary)


class Symbol extends Control:
	## Legend symbols drawn with the same stickers the map uses.
	var kind := "control"

	func _ready() -> void:
		custom_minimum_size = Vector2(58, 58)

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"start": Course.draw_start(self, c, 20, c + Vector2.UP)
			"control": Course.draw_control(self, c, 19, 1, {"icon": "🍎"})
			"finish": Course.draw_control(self, c, 15, 8, {"icon": "🏁"}, {"finish": true, "show_number": false})


const TILE_BARS := [UI.LAVENDER, UI.TEAL, UI.PEACH, UI.BUTTER]

var _grid: HFlowContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var desk := UI.Desk.new()
	desk.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(desk)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var col := UI.vbox(28)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(UI.margin(col, 48, 36, 48, 28))
	col.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL

	var head := UI.hbox(16)
	var mark := TextureRect.new()
	mark.texture = load("res://icon.svg")
	mark.custom_minimum_size = Vector2(64, 64)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	head.add_child(mark)
	var names := UI.vbox(0)
	var name := UI.label("StoryPalace", "Display")
	name.add_theme_font_size_override(&"font_size", 46)
	names.add_child(name)
	names.add_child(UI.label("Remember anything, one room at a time.", "Muted"))
	head.add_child(names)
	head.add_child(UI.spacer())
	var imp := UI.button("Import a palace", "upload", "Button", "Open a .palace file someone shared with you")
	imp.pressed.connect(_import)
	imp.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(imp)
	var new := UI.button("New palace", "plus", "PrimaryButton")
	new.pressed.connect(_new_palace)
	new.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(new)
	col.add_child(head)

	if not Store.settings.get("seen_intro", false):
		var lg := _legend()
		col.add_child(lg)
		UI.pop_in(lg, 0.05, 0.97)

	col.add_child(UI.label("Your palaces", "H2"))
	_grid = HFlowContainer.new()
	_grid.add_theme_constant_override(&"h_separation", 24)
	_grid.add_theme_constant_override(&"v_separation", 24)
	col.add_child(_grid)
	_fill(true)

	var foot := UI.label("Built with 💖 by Storybook Interactive Private Limited", "Muted")
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(UI.margin(foot, 0, 24, 0, 0))
	Store.changed.connect(func(_id): if is_inside_tree(): _fill(false))


func _legend() -> Control:
	var w := UI.window("How it works", UI.BUTTER, 18)
	var close := UI.bar_button("x", "Hide this")
	close.pressed.connect(func(): Store.settings.seen_intro = true; Store.save_settings(); w.root.queue_free())
	w.bar.add_child(close)
	var row := UI.hbox(28)
	w.body.add_child(row)
	var intro := UI.vbox(4)
	intro.custom_minimum_size.x = 230
	intro.add_child(UI.label("Build a palace", "H2"))
	intro.add_child(UI.label("A memory palace is a walk through a place you know, with a striking picture at every stop.", "Muted", true))
	row.add_child(intro)
	for e in [["start", "1. Pick a place", "Your home, your school, your street, or a ready-made room."],
			["control", "2. Stick memories on it", "Click a spot and add a vivid picture for each thing to remember."],
			["finish", "3. Walk it, then test", "Run the course in order, then take the punch test to see what stuck."]]:
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
	return w.root


func _fill(animate: bool) -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var i := 0
	for p in Store.palaces:
		var t := _tile(p, TILE_BARS[i % TILE_BARS.size()])
		_grid.add_child(t)
		if animate:
			UI.pop_in(t, 0.06 + 0.04 * mini(i, 8))
		i += 1
	var add := Button.new()
	add.theme_type_variation = "FlatButton"
	add.custom_minimum_size = Vector2(320, 300)
	add.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	add.tooltip_text = "Start a new palace"
	add.add_theme_stylebox_override(&"normal", UI.box(Color(UI.PAPER, 0.6), Color(UI.INK, 0.4), UI.LINE, UI.RADIUS))
	add.add_theme_stylebox_override(&"hover", UI.box(UI.PINK_TINT, UI.INK, UI.LINE, UI.RADIUS))
	add.add_theme_stylebox_override(&"pressed", UI.box(UI.PINK_TINT, UI.INK, UI.LINE, UI.RADIUS))
	UI.juice(add, 1.02)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var v := UI.vbox(10)
	var plus := PanelContainer.new()
	plus.add_theme_stylebox_override(&"panel", UI.box(UI.PINK, UI.INK, UI.LINE, 26, Vector4(12, 12, 12, 12)))
	plus.size_flags_horizontal = SIZE_SHRINK_CENTER
	var pi := TextureRect.new()
	pi.texture = UI.icon("plus")
	pi.custom_minimum_size = Vector2(26, 26)
	pi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plus.add_child(pi)
	v.add_child(plus)
	var l := UI.label("Start a new palace", "H2")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var hint := UI.label("Your home, a walk to school, any place you know by heart", "Muted", true)
	hint.custom_minimum_size.x = 240
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	for c in [cc, v, plus, pi, l, hint]:
		c.mouse_filter = MOUSE_FILTER_IGNORE
	cc.add_child(v)
	add.add_child(cc)
	add.pressed.connect(_new_palace)
	_grid.add_child(add)
	if animate:
		UI.pop_in(add, 0.06 + 0.04 * mini(i, 8))


## A palace as a little window: its name in the title bar, its first room below.
func _tile(p: Dictionary, bar: Color) -> Control:
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.custom_minimum_size = Vector2(320, 300)
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, UI.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, UI.RADIUS, Vector4.ZERO))
	b.tooltip_text = "Open “%s”" % p.name
	UI.juice(b, 1.025)
	var w := UI.window(p.name, bar, 10)
	w.root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var col := UI.vbox(8)
	w.body.add_child(col)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Frame"
	var th := Thumb.new()
	th.custom_minimum_size = Vector2(292, 168)
	if not p.rooms.is_empty():
		th.room = p.rooms[0]
		th.palace = p
	frame.add_child(th)
	col.add_child(frame)
	var n := Store.count_items(p)
	col.add_child(UI.label("%d room%s  ·  %d memor%s" % [p.rooms.size(), "" if p.rooms.size() == 1 else "s", n, "y" if n == 1 else "ies"], "H3"))
	var chip := PanelContainer.new()
	var tested: bool = p.practiced > 0
	chip.add_theme_stylebox_override(&"panel", UI.box(UI.TEAL if tested else UI.LAVENDER_TINT, UI.INK, UI.LINE, 11, Vector4(10, 2, 10, 2)))
	chip.size_flags_horizontal = SIZE_SHRINK_BEGIN
	var res := UI.ago(p.practiced)
	if p.score >= 0:
		res += "  ·  %d%% remembered" % p.score
	chip.add_child(UI.label(res, "Caps"))
	col.add_child(chip)
	b.add_child(w.root)
	# the whole window is one button: children must not swallow the click
	w.root.mouse_filter = MOUSE_FILTER_IGNORE
	for c in w.root.find_children("*", "Control", true, false):
		c.mouse_filter = MOUSE_FILTER_IGNORE
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
		UI.file_dialog(self, true, PackedStringArray(["*.palace ; StoryPalace file"]), func(path): _export(p, path), p.name.validate_filename() + ".palace")
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
	UI.file_dialog(self, false, PackedStringArray(["*.palace ; StoryPalace file"]), func(path):
		var p := Store.import_palace(path)
		if p.is_empty():
			UI.toast(self, "That file is not a StoryPalace export.")
		else:
			open_requested.emit(p))
