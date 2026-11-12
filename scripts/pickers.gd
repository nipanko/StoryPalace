class_name Pickers
## The picture picker (emoji search + own picture) and the room picker (ready-made scenes + own photo).

const SHORT := {"Smileys & Emotion": "Faces", "People & Body": "People", "Animals & Nature": "Nature", "Food & Drink": "Food",
	"Travel & Places": "Places", "Activities": "Activities", "Objects": "Objects", "Symbols": "Symbols", "Flags": "Flags"}


## cb receives {"icon": "🍎"} or {"image": "file.png"}.
static func picture(owner: Control, hint: String, cb: Callable) -> void:
	var pop := PopupPanel.new()
	var root := UI.vbox(UI.S3)
	root.custom_minimum_size = Vector2(664, 540)
	pop.add_child(root)

	root.add_child(UI.label("Choose a picture", "H2"))
	var top := UI.hbox(UI.S2)
	var search := LineEdit.new()
	search.placeholder_text = "Search pictures: apple, rocket, crown, piano…"
	search.clear_button_enabled = true
	search.right_icon = UI.icon_px("search", 16, UI.SUBTLE)
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(search)
	var own := UI.button("Use your own…", "image", "Button", "Pick an image file from your computer")
	top.add_child(own)
	root.add_child(top)

	var ideas := Emoji.suggest(hint) if hint.strip_edges() != "" else []
	if not ideas.is_empty():
		var row := UI.hbox(2)
		var l := UI.label("Suggested", "Muted")
		l.custom_minimum_size.x = 84
		row.add_child(l)
		for e in ideas:
			row.add_child(_emoji_button(e, func(): pop.hide(); cb.call({"icon": e})))
		root.add_child(row)

	var cats := UI.hbox(2)
	var track := PanelContainer.new()
	track.add_theme_stylebox_override(&"panel", UI.box(UI.SUNKEN, Color.TRANSPARENT, 0, 7, Vector4(2, 2, 2, 2)))
	track.add_child(cats)
	root.add_child(track)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 14
	grid.add_theme_constant_override(&"h_separation", 2)
	grid.add_theme_constant_override(&"v_separation", 2)
	scroll.add_child(grid)
	root.add_child(scroll)

	var fill := func(list: Array) -> void:
		for c in grid.get_children():
			c.queue_free()
		for e in list:
			grid.add_child(_emoji_button(e, func(): pop.hide(); cb.call({"icon": e})))
		scroll.scroll_vertical = 0
	var group := ButtonGroup.new()
	for g in Emoji.data():
		var b := UI.button(SHORT.get(g[0], g[0]), "", "SegButton")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(func(): search.text = ""; fill.call(g[1].map(func(x): return x[0])))
		cats.add_child(b)
	search.text_changed.connect(func(t): fill.call(Emoji.search(t)) if t.strip_edges() != "" else (cats.get_child(0) as Button).emit_signal("pressed"))
	own.pressed.connect(func():
		UI.file_dialog(owner, false, PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Pictures"]), func(path):
			var name := Store.import_image(path, 512)
			if name == "":
				UI.toast(owner, "That file could not be opened as a picture.")
			else:
				pop.hide()
				cb.call({"image": name})))
	(cats.get_child(0) as Button).button_pressed = true
	fill.call(Emoji.data()[0][1].map(func(x): return x[0]))
	pop.popup_hide.connect(pop.queue_free)
	owner.add_child(pop)
	pop.popup_centered()
	search.grab_focus.call_deferred()


static func _emoji_button(e: String, on: Callable) -> Button:
	var b := UI.button(e, "", "FlatButton")
	b.custom_minimum_size = Vector2(44, 44)
	b.add_theme_font_size_override(&"font_size", 24)
	b.add_theme_stylebox_override(&"normal", UI.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, UI.R_CONTROL, Vector4(2, 2, 2, 2)))
	b.add_theme_stylebox_override(&"hover", UI.box(UI.HOVER, Color.TRANSPARENT, 0, UI.R_CONTROL, Vector4(2, 2, 2, 2)))
	b.add_theme_stylebox_override(&"pressed", UI.box(UI.ACCENT_TINT, Color.TRANSPARENT, 0, UI.R_CONTROL, Vector4(2, 2, 2, 2)))
	b.tooltip_text = ""
	b.pressed.connect(on)
	return b


## cb receives {"theme": id} or {"photo": file}. `title` names what the picker is for.
static func room(owner: Control, title: String, cb: Callable) -> void:
	var pop := PopupPanel.new()
	var root := UI.vbox(UI.S3)
	root.custom_minimum_size = Vector2(684, 0)
	pop.add_child(root)
	root.add_child(UI.label(title, "H2"))
	var intro := UI.label("Places you know by heart work best. Use a photo of your own home, school or street, or pick a ready-made room.", "Muted", true)
	intro.custom_minimum_size.x = 684  # a wrapping label needs a width, or it sizes the popup for one word per line
	root.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", UI.S2)
	grid.add_theme_constant_override(&"v_separation", UI.S2)
	root.add_child(grid)
	for id in SceneArt.ORDER:
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.custom_minimum_size = Vector2(222, 164)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = SceneArt.THEMES[id].name
		var col := UI.vbox(UI.S2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, UI.S2)
		var frame := PanelContainer.new()
		frame.theme_type_variation = "Frame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var th := Thumb.new()
		th.room = {"theme": id}
		th.custom_minimum_size = Vector2(204, 116)
		frame.add_child(th)
		col.add_child(frame)
		var l := UI.label(SceneArt.THEMES[id].name, "H3")
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(l)
		b.add_child(col)
		b.pressed.connect(func(): pop.hide(); cb.call({"theme": id}))
		grid.add_child(b)
	var own := UI.button("Use a photo of a real place…", "camera", "Button")
	own.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	own.pressed.connect(func():
		UI.file_dialog(owner, false, PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Photos"]), func(path):
			var name := Store.import_image(path, 2048)
			if name == "":
				UI.toast(owner, "That file could not be opened as a photo.")
			else:
				pop.hide()
				cb.call({"photo": name, "name": path.get_file().get_basename().capitalize()})))
	root.add_child(own)
	pop.popup_hide.connect(pop.queue_free)
	owner.add_child(pop)
	pop.popup_centered()


## Small one-field dialog (rename).
static func ask_text(owner: Control, title: String, value: String, cb: Callable) -> void:
	var d := AcceptDialog.new()
	d.title = title
	d.ok_button_text = "Save"
	var e := LineEdit.new()
	e.text = value
	e.custom_minimum_size.x = 340
	e.max_length = 60
	e.select_all_on_focus = true
	d.add_child(e)
	d.register_text_enter(e)
	d.confirmed.connect(func(): if e.text.strip_edges() != "": cb.call(e.text.strip_edges()))
	d.visibility_changed.connect(func(): if not d.visible: d.queue_free())
	owner.add_child(d)
	d.get_ok_button().theme_type_variation = "PrimaryButton"
	d.popup_centered()
	e.grab_focus.call_deferred()
