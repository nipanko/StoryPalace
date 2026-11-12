class_name Home
extends Control
## All palaces as a library of map sheets, plus the legend that teaches the notation.

signal open_requested(palace: Dictionary)


class Symbol extends Control:
	## Getting-started symbols drawn with the same markers the map uses.
	var kind := "control"

	func _ready() -> void:
		custom_minimum_size = Vector2(48, 48)

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"start": Course.draw_start(self, c, 15, c + Vector2.UP)
			"control": Course.draw_control(self, c + Vector2(-4, 3), 15, 1, {"icon": "🍎"})
			"finish": Course.draw_control(self, c, 13, 8, {"icon": "🏁"}, {"finish": true, "show_number": false})


const CARD_W := 288

var _grid: HFlowContainer
var _count: PanelContainer
var _query := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(UI.backdrop())
	var root := UI.vbox(0)
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(root)

	var tb := UI.bar(UI.BAR_H)
	tb.row.add_child(UI.margin(UI.logo(28), UI.S1, 0, 0, 0))
	tb.row.add_child(UI.label("StoryPalace", "H2"))
	tb.row.add_child(UI.spacer())
	var search := LineEdit.new()
	search.placeholder_text = "Search palaces"
	search.right_icon = UI.icon_px("search", 16, UI.SUBTLE)
	search.clear_button_enabled = true
	search.custom_minimum_size.x = 220
	search.size_flags_vertical = SIZE_SHRINK_CENTER
	search.text_changed.connect(func(t): _query = t.strip_edges(); _fill(false))
	tb.row.add_child(search)
	tb.row.add_child(UI.vrule())
	var imp := UI.button("Import", "upload", "Button", "Open a .palace file someone shared with you")
	imp.pressed.connect(_import)
	tb.row.add_child(imp)
	var new := UI.button("New palace", "plus", "PrimaryButton")
	new.pressed.connect(_new_palace)
	tb.row.add_child(new)
	root.add_child(tb.root)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := UI.vbox(UI.S6)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.size_flags_vertical = SIZE_EXPAND_FILL
	var m := UI.margin(col, UI.S8, UI.S6, UI.S8, UI.S4)
	m.size_flags_horizontal = SIZE_EXPAND_FILL
	m.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(m)

	var head := UI.vbox(UI.S1)
	var hrow := UI.hbox(UI.S2)
	hrow.add_child(UI.label("Palaces", "Display"))
	_count = UI.badge("0")
	hrow.add_child(_count)
	head.add_child(hrow)
	head.add_child(UI.label("Remember anything, one room at a time.", "Muted"))
	col.add_child(head)

	if not Store.settings.get("seen_intro", false):
		col.add_child(_getting_started())

	_grid = HFlowContainer.new()
	_grid.add_theme_constant_override(&"h_separation", UI.S4)
	_grid.add_theme_constant_override(&"v_separation", UI.S4)
	col.add_child(_grid)
	_fill(true)

	var push := Control.new()
	push.size_flags_vertical = SIZE_EXPAND_FILL
	col.add_child(push)
	var foot := UI.label("Built with 💖 by Storybook Interactive Private Limited", "Muted")
	foot.add_theme_font_size_override(&"font_size", 12)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(foot)
	Store.changed.connect(func(_id): if is_inside_tree(): _fill(false))


func _getting_started() -> Control:
	var w := UI.panel("Getting started", UI.S4)
	var close := UI.icon_button("x", "Hide this")
	close.pressed.connect(func(): Store.settings.seen_intro = true; Store.save_settings(); w.root.queue_free())
	w.bar.add_child(close)
	var row := UI.hbox(UI.S6)
	w.body.add_child(row)
	for e in [["start", "1. Pick a place", "Your home, your school, your street, or a ready-made room."],
			["control", "2. Place memories", "Click a spot and add a vivid picture for each thing to remember."],
			["finish", "3. Walk it, then test", "Run the course in order, then take the punch test to see what stuck."]]:
		var b := UI.hbox(UI.S3)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		var s := Symbol.new()
		s.kind = e[0]
		s.size_flags_vertical = SIZE_SHRINK_BEGIN
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
	var shown: Array = Store.palaces.filter(func(p): return _query == "" or p.name.containsn(_query))
	(_count.get_child(0) as Label).text = str(Store.palaces.size())
	var i := 0
	for p in shown:
		var t := _card(p)
		_grid.add_child(t)
		if animate:
			UI.appear(t, 0.03 * mini(i, 10))
		i += 1
	if _query != "":
		if shown.is_empty():
			_grid.add_child(UI.label("No palaces match “%s”." % _query, "Muted"))
		return
	var add := Button.new()
	add.custom_minimum_size = Vector2(CARD_W, 268)
	add.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	add.tooltip_text = "Start a new palace"
	add.add_theme_stylebox_override(&"normal", UI.box(Color.TRANSPARENT, UI.BORDER_STRONG, UI.LINE, UI.R_PANEL))
	add.add_theme_stylebox_override(&"hover", UI.box(UI.SURFACE, UI.ACCENT, UI.LINE, UI.R_PANEL))
	add.add_theme_stylebox_override(&"pressed", UI.box(UI.ACCENT_TINT, UI.ACCENT, UI.LINE, UI.R_PANEL))
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var v := UI.vbox(UI.S2)
	var plus := TextureRect.new()
	plus.texture = UI.icon("plus")
	plus.modulate = UI.ACCENT
	plus.custom_minimum_size = Vector2(24, 24)
	plus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(plus)
	var l := UI.label("New palace", "H3")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var hint := UI.label("Start from a ready-made room or a photo of a place you know", "Muted", true)
	hint.custom_minimum_size.x = 200
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	for c in [cc, v, plus, l, hint]:
		c.mouse_filter = MOUSE_FILTER_IGNORE
	cc.add_child(v)
	add.add_child(cc)
	add.pressed.connect(_new_palace)
	_grid.add_child(add)
	if animate:
		UI.appear(add, 0.03 * mini(i, 10))


## A palace card: its first room with the path, then name, counts and test status.
func _card(p: Dictionary) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARD_W, 268)
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.tooltip_text = "Open “%s”\nRight-click for more" % p.name
	b.add_theme_stylebox_override(&"normal", UI.box(UI.SURFACE, UI.BORDER, UI.LINE, UI.R_PANEL))
	b.add_theme_stylebox_override(&"hover", UI.box(UI.SURFACE, UI.ACCENT, UI.LINE, UI.R_PANEL))
	b.add_theme_stylebox_override(&"pressed", UI.box(UI.ACCENT_TINT, UI.ACCENT, UI.LINE, UI.R_PANEL))
	var col := UI.vbox(0)
	col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, UI.LINE)
	var th := Thumb.new()
	th.custom_minimum_size = Vector2(CARD_W - 2, 172)
	if not p.rooms.is_empty():
		th.room = p.rooms[0]
		th.palace = p
	col.add_child(th)
	var rule := ColorRect.new()
	rule.color = UI.BORDER
	rule.custom_minimum_size.y = 1
	col.add_child(rule)
	var info := UI.vbox(UI.S1)
	var name := UI.label(p.name, "H2")
	name.add_theme_font_size_override(&"font_size", 15)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(name)
	var n := Store.count_items(p)
	var meta := UI.hbox(UI.S2)
	var counts := UI.label("%s  ·  %s" % [UI.plural(p.rooms.size(), "room", "rooms"), UI.plural(n, "memory", "memories")], "Muted")
	counts.size_flags_horizontal = SIZE_EXPAND_FILL
	meta.add_child(counts)
	info.add_child(meta)
	var status := UI.ago(p.practiced)
	if p.score >= 0:
		status += "  ·  %d%%" % p.score
	info.add_child(UI.margin(UI.badge(status, "neutral" if p.practiced <= 0 else ("success" if p.score >= 80 else "accent")), 0, UI.S1, 0, 0))
	col.add_child(UI.margin(info, UI.S3, UI.S3, UI.S3, UI.S3))
	b.add_child(col)
	# the whole card is one button: children must not swallow the click
	col.mouse_filter = MOUSE_FILTER_IGNORE
	for c in col.find_children("*", "Control", true, false):
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
