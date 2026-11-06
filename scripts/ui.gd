class_name UI
## Design tokens (orienteering map inks), the app Theme, and small widget factories.

const INK := Color("#1E1E1E")
const MUTED := Color("#5B5B5B")
const PAPER := Color("#FFFFFF")
const PURPLE := Color("#B4248C")       # course overprint: path, numerals, primary action
const PURPLE_DARK := Color("#951C74")
const PURPLE_TINT := Color("#FBE6F3")
const YELLOW := Color("#F7C04A")       # open land: selection
const YELLOW_TINT := Color("#FDF1D2")
const GREEN := Color("#7DB55E")        # thicket: remembered
const GREEN_TEXT := Color("#3F7A2A")
const BLUE := Color("#2A9FD8")         # water
const BROWN := Color("#B96A2C")        # contours
const RED := Color("#C8362D")          # missed
const RULE := 2                        # map-frame line weight

static var _fonts := {}
static var _icons := {}
static var _icon_svg: Dictionary


static func font(name: String) -> Font:
	if not _fonts.has(name):
		var f: FontFile = load("res://fonts/%s.ttf" % name)
		var fb: Array[Font] = [SceneArt.font()]
		f.fallbacks = fb  # colour emoji inside any text
		_fonts[name] = f
	return _fonts[name]


static func caps_font() -> Font:
	if not _fonts.has("caps"):
		var v := FontVariation.new()
		v.base_font = font("BarlowCondensed-SemiBold")
		v.spacing_glyph = 1
		_fonts["caps"] = v
	return _fonts["caps"]


## Lucide icon rendered white at 2x so it stays sharp; tint it with modulate or theme icon colours.
static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		if _icon_svg.is_empty():
			_icon_svg = load("res://data/icons.json").data
		var img := Image.new()
		img.load_svg_from_string(_icon_svg.get(name, _icon_svg["x"]), 2.0)
		_icons[name] = ImageTexture.create_from_image(img)
	return _icons[name]


static func box(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := 4, pad := Vector4(12, 8, 12, 8)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	s.anti_aliasing = true
	return s


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("Barlow-Regular")
	t.default_font_size = 16

	# Buttons: outlined map-print rectangles by default
	_button(t, "Button", PAPER, INK, INK, YELLOW_TINT, PAPER)
	_button(t, "PrimaryButton", PURPLE, PURPLE, PAPER, PURPLE_DARK, PAPER)
	_button(t, "FlatButton", Color.TRANSPARENT, Color.TRANSPARENT, INK, YELLOW_TINT, PAPER)
	t.set_type_variation("PrimaryButton", "Button")
	t.set_type_variation("FlatButton", "Button")
	for ty in ["Button", "PrimaryButton", "FlatButton"]:
		t.set_font(&"font", ty, font("BarlowCondensed-SemiBold"))
		t.set_font_size(&"font_size", ty, 18)
		t.set_constant(&"h_separation", ty, 8)
		t.set_constant(&"icon_max_width", ty, 20)
	t.set_stylebox(&"normal", "FlatButton", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, Vector4(8, 6, 8, 6)))
	t.set_stylebox(&"hover", "FlatButton", box(YELLOW_TINT, Color.TRANSPARENT, 0, 4, Vector4(8, 6, 8, 6)))
	t.set_stylebox(&"pressed", "FlatButton", box(YELLOW, Color.TRANSPARENT, 0, 4, Vector4(8, 6, 8, 6)))

	# Map sheet tabs and the 2D/3D segment use toggle buttons
	t.set_type_variation("TabButton", "Button")
	t.set_stylebox(&"normal", "TabButton", box(Color("#F3F2EE"), Color.TRANSPARENT, 0, 0, Vector4(16, 8, 16, 8)))
	t.set_stylebox(&"hover", "TabButton", box(YELLOW_TINT, Color.TRANSPARENT, 0, 0, Vector4(16, 8, 16, 8)))
	var tab_on := box(PAPER, INK, RULE, 0, Vector4(16, 8, 16, 10))
	tab_on.border_width_bottom = 0
	t.set_stylebox(&"pressed", "TabButton", tab_on)
	t.set_stylebox(&"hover_pressed", "TabButton", tab_on)
	t.set_stylebox(&"focus", "TabButton", _focus())
	t.set_color(&"font_color", "TabButton", MUTED)
	t.set_color(&"font_pressed_color", "TabButton", INK)
	t.set_color(&"font_hover_pressed_color", "TabButton", INK)
	t.set_color(&"font_hover_color", "TabButton", INK)
	t.set_font(&"font", "TabButton", font("BarlowCondensed-SemiBold"))
	t.set_font_size(&"font_size", "TabButton", 18)

	t.set_type_variation("SegButton", "Button")
	t.set_stylebox(&"normal", "SegButton", box(PAPER, INK, RULE, 0, Vector4(14, 6, 14, 6)))
	t.set_stylebox(&"hover", "SegButton", box(YELLOW_TINT, INK, RULE, 0, Vector4(14, 6, 14, 6)))
	t.set_stylebox(&"pressed", "SegButton", box(INK, INK, RULE, 0, Vector4(14, 6, 14, 6)))
	t.set_stylebox(&"hover_pressed", "SegButton", box(INK, INK, RULE, 0, Vector4(14, 6, 14, 6)))
	t.set_stylebox(&"focus", "SegButton", _focus())
	t.set_color(&"font_color", "SegButton", INK)
	t.set_color(&"font_hover_color", "SegButton", INK)
	t.set_color(&"font_pressed_color", "SegButton", PAPER)
	t.set_color(&"font_hover_pressed_color", "SegButton", PAPER)
	t.set_font(&"font", "SegButton", font("BarlowCondensed-Bold"))
	t.set_font_size(&"font_size", "SegButton", 17)

	# Text
	t.set_color(&"font_color", "Label", INK)
	for v in [["Display", "BarlowCondensed-Bold", 34, INK], ["H2", "BarlowCondensed-Bold", 24, INK], ["H3", "Barlow-SemiBold", 18, INK],
			["Muted", "Barlow-Regular", 15, MUTED], ["Numeral", "BarlowCondensed-Bold", 30, PURPLE], ["Body", "Barlow-Regular", 17, INK]]:
		t.set_type_variation(v[0], "Label")
		t.set_font(&"font", v[0], font(v[1]))
		t.set_font_size(&"font_size", v[0], v[2])
		t.set_color(&"font_color", v[0], v[3])
	t.set_type_variation("Caps", "Label")
	t.set_font(&"font", "Caps", caps_font())
	t.set_font_size(&"font_size", "Caps", 14)
	t.set_color(&"font_color", "Caps", MUTED)

	# Inputs
	for ty in ["LineEdit", "TextEdit"]:
		t.set_stylebox(&"normal", ty, box(PAPER, Color(INK, 0.55), 1, 4, Vector4(12, 8, 12, 8)))
		t.set_stylebox(&"focus", ty, box(Color.TRANSPARENT, PURPLE, 2, 4, Vector4(12, 8, 12, 8)))
		t.set_stylebox(&"read_only", ty, box(Color("#F3F2EE"), Color(INK, 0.3), 1, 4))
		t.set_color(&"font_color", ty, INK)
		t.set_color(&"font_placeholder_color", ty, Color("#767676"))
		t.set_color(&"caret_color", ty, PURPLE)
		t.set_color(&"selection_color", ty, Color(PURPLE, 0.25))
		t.set_font_size(&"font_size", ty, 17)
	t.set_type_variation("TitleEdit", "LineEdit")
	t.set_stylebox(&"normal", "TitleEdit", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, Vector4(6, 2, 6, 2)))
	t.set_stylebox(&"focus", "TitleEdit", box(Color.TRANSPARENT, PURPLE, 2, 4, Vector4(6, 2, 6, 2)))
	t.set_font(&"font", "TitleEdit", font("BarlowCondensed-Bold"))
	t.set_font_size(&"font_size", "TitleEdit", 30)

	# Panels, popups, dialogs
	t.set_stylebox(&"panel", "Panel", box(PAPER))
	t.set_stylebox(&"panel", "PanelContainer", box(PAPER, Color.TRANSPARENT, 0, 0, Vector4.ZERO))
	t.set_type_variation("Frame", "PanelContainer")
	t.set_stylebox(&"panel", "Frame", box(PAPER, INK, RULE, 4, Vector4(RULE, RULE, RULE, RULE)))
	var pop := box(PAPER, INK, RULE, 6, Vector4(20, 20, 20, 20))
	pop.shadow_color = Color(0, 0, 0, 0.18)
	pop.shadow_size = 18
	pop.shadow_offset = Vector2(0, 6)
	t.set_stylebox(&"panel", "PopupPanel", pop)
	t.set_stylebox(&"panel", "AcceptDialog", pop)
	t.set_stylebox(&"panel", "PopupMenu", box(PAPER, INK, RULE, 4, Vector4(6, 6, 6, 6)))
	t.set_stylebox(&"hover", "PopupMenu", box(YELLOW_TINT, Color.TRANSPARENT, 0, 2))
	t.set_color(&"font_color", "PopupMenu", INK)
	t.set_color(&"font_hover_color", "PopupMenu", INK)
	t.set_font_size(&"font_size", "PopupMenu", 16)
	t.set_constant(&"v_separation", "PopupMenu", 10)
	t.set_stylebox(&"panel", "TooltipPanel", box(INK, Color.TRANSPARENT, 0, 4, Vector4(10, 6, 10, 6)))
	t.set_color(&"font_color", "TooltipLabel", PAPER)
	t.set_font_size(&"font_size", "TooltipLabel", 14)

	# Scrollbars: thin ink
	for ty in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox(&"scroll", ty, box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber", ty, box(Color(INK, 0.25), Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber_highlight", ty, box(Color(INK, 0.45), Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber_pressed", ty, box(PURPLE, Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
	t.set_color(&"font_color", "CheckBox", INK)
	t.set_color(&"font_hover_color", "CheckBox", INK)
	t.set_color(&"font_pressed_color", "CheckBox", INK)
	t.set_color(&"font_hover_pressed_color", "CheckBox", INK)
	t.set_stylebox(&"hover", "CheckBox", box(YELLOW_TINT, Color.TRANSPARENT, 0, 4, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"focus", "CheckBox", _focus())
	return t


static func _focus() -> StyleBoxFlat:
	var s := box(Color.TRANSPARENT, PURPLE, 2, 4)
	s.draw_center = false
	s.set_expand_margin_all(2)
	return s


static func _button(t: Theme, ty: String, bg: Color, border: Color, fg: Color, hover_bg: Color, press_fg: Color) -> void:
	var pad := Vector4(16, 8, 16, 8)
	t.set_stylebox(&"normal", ty, box(bg, border, RULE, 4, pad))
	t.set_stylebox(&"hover", ty, box(hover_bg, border if ty != "PrimaryButton" else PURPLE_DARK, RULE, 4, pad))
	t.set_stylebox(&"pressed", ty, box(INK if ty != "PrimaryButton" else PURPLE_DARK, INK if ty != "PrimaryButton" else PURPLE_DARK, RULE, 4, pad))
	t.set_stylebox(&"disabled", ty, box(Color("#F3F2EE"), Color(INK, 0.25), RULE, 4, pad))
	t.set_stylebox(&"focus", ty, _focus())
	t.set_color(&"font_color", ty, fg)
	t.set_color(&"font_hover_color", ty, fg if ty != "Button" else INK)
	t.set_color(&"font_pressed_color", ty, press_fg)
	t.set_color(&"font_hover_pressed_color", ty, press_fg)
	t.set_color(&"font_focus_color", ty, fg)
	t.set_color(&"font_disabled_color", ty, Color(INK, 0.4))
	t.set_color(&"icon_normal_color", ty, fg)
	t.set_color(&"icon_hover_color", ty, fg)
	t.set_color(&"icon_pressed_color", ty, press_fg)
	t.set_color(&"icon_focus_color", ty, fg)
	t.set_color(&"icon_disabled_color", ty, Color(INK, 0.35))


# ---------- factories ----------

static func button(text: String, icon_name := "", variation := "Button", tip := "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	if icon_name != "":
		b.icon = icon(icon_name)
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func icon_button(icon_name: String, tip: String, variation := "FlatButton") -> Button:
	var b := button("", icon_name, variation, tip)
	b.custom_minimum_size = Vector2(40, 40)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


static func label(text: String, variation := "", wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func hbox(sep := 12) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override(&"separation", sep)
	return b


static func vbox(sep := 12) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override(&"separation", sep)
	return b


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func margin(child: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override(&"margin_left", l)
	m.add_theme_constant_override(&"margin_top", t)
	m.add_theme_constant_override(&"margin_right", r)
	m.add_theme_constant_override(&"margin_bottom", b)
	m.add_child(child)
	return m


## Focus after the current frame, skipping controls that were already replaced.
static func focus_later(c: Control) -> void:
	(func(): if is_instance_valid(c) and c.is_inside_tree(): c.grab_focus()).call_deferred()


static func ago(unix: float) -> String:
	if unix <= 0:
		return "Not tested yet"
	var d := int((Time.get_unix_time_from_system() - unix) / 86400.0)
	if d <= 0:
		return "Tested today"
	return "Tested yesterday" if d == 1 else "Tested %d days ago" % d


## Native open/save dialog. `cb` receives the chosen path.
static func file_dialog(owner: Node, save: bool, filters: PackedStringArray, cb: Callable, suggested := "") -> void:
	var fd := FileDialog.new()
	fd.use_native_dialog = true
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = filters
	fd.current_file = suggested
	fd.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS if save else OS.SYSTEM_DIR_PICTURES)
	fd.file_selected.connect(func(p): cb.call(p); fd.queue_free())
	fd.canceled.connect(fd.queue_free)
	owner.add_child(fd)
	fd.popup_centered(Vector2i(900, 600))


static func confirm(owner: Node, title: String, text: String, ok: String, cb: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.title = title
	d.dialog_text = text
	d.ok_button_text = ok
	d.confirmed.connect(cb)
	d.visibility_changed.connect(func(): if not d.visible: d.queue_free())
	owner.add_child(d)
	d.get_ok_button().theme_type_variation = "PrimaryButton"
	d.popup_centered(Vector2i(460, 0))


static func toast(owner: Control, text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", box(INK, Color.TRANSPARENT, 0, 4, Vector4(16, 10, 16, 10)))
	var l := label(text)
	l.add_theme_color_override(&"font_color", PAPER)
	p.add_child(l)
	owner.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 32)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var tw := p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)
