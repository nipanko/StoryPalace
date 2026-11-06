class_name UI
## Design tokens ("sticker desktop"), the app Theme, window panels, motion helpers and widget factories.

const INK := Color("#35294A")          # plum outlines and text
const MUTED := Color("#6B5F7D")
const GROUND := Color("#FFF5E6")       # the desk
const PAPER := Color("#FFFDF8")        # window bodies
const PINK := Color("#D02E6E")         # path, numerals, primary action, focus
const PINK_DARK := Color("#B0225B")
const PINK_TINT := Color("#FFE3EE")
const BUTTER := Color("#FFD166")
const BUTTER_TINT := Color("#FFF0C9")
const LAVENDER := Color("#CFC9F2")
const LAVENDER_TINT := Color("#EEEBFB")
const TEAL := Color("#9ED8CF")
const PEACH := Color("#FFC2A8")
const SKY := Color("#5C8DF6")
const GREEN := Color("#23805F")        # remembered
const RED := Color("#C93A2C")          # missed, destructive
const LINE := 2                        # outline weight
const RADIUS := 14

static var _fonts := {}
static var _icons := {}
static var _icon_svg: Dictionary


## Logical faces: display (Young Serif), regular, semibold, bold, black (Nunito weights).
static func font(name: String) -> Font:
	if not _fonts.has(name):
		var fb: Array[Font] = [SceneArt.font()]  # colour emoji inside any text
		if name == "display":
			var f: FontFile = load("res://fonts/YoungSerif-Regular.ttf")
			f.fallbacks = fb
			_fonts[name] = f
		else:
			var base: FontFile = load("res://fonts/Nunito.ttf")
			base.fallbacks = fb
			var v := FontVariation.new()
			v.base_font = base
			var wght: int = {"regular": 500, "semibold": 700, "bold": 800, "black": 900}.get(name, 500)
			v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
			_fonts[name] = v
	return _fonts[name]


static func caps_font() -> Font:
	if not _fonts.has("caps"):
		var v := FontVariation.new()
		v.base_font = font("black")
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


static func _svg_tex(svg: String) -> Texture2D:
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	return ImageTexture.create_from_image(img)


static func box(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := 12, pad := Vector4(12, 8, 12, 8)) -> StyleBoxFlat:
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


static func soft_shadow(s: StyleBoxFlat, size := 14, y := 5) -> StyleBoxFlat:
	s.shadow_color = Color(INK, 0.13)
	s.shadow_size = size
	s.shadow_offset = Vector2(0, y)
	return s


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("regular")
	t.default_font_size = 16

	# Buttons: outlined, rounded, sticker-like
	_button(t, "Button", PAPER, BUTTER_TINT, LAVENDER, INK, INK)
	_button(t, "PrimaryButton", PINK, PINK_DARK, PINK_DARK, PAPER, PAPER)
	_button(t, "ButterButton", BUTTER, Color("#FFC53D"), Color("#F5B829"), INK, INK)
	for ty in ["PrimaryButton", "ButterButton"]:
		t.set_type_variation(ty, "Button")
	t.set_type_variation("FlatButton", "Button")
	var pad := Vector4(10, 6, 10, 6)
	t.set_stylebox(&"normal", "FlatButton", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 10, pad))
	t.set_stylebox(&"hover", "FlatButton", box(LAVENDER_TINT, Color.TRANSPARENT, 0, 10, pad))
	t.set_stylebox(&"pressed", "FlatButton", box(LAVENDER, Color.TRANSPARENT, 0, 10, pad))
	t.set_stylebox(&"disabled", "FlatButton", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 10, pad))
	t.set_stylebox(&"focus", "FlatButton", _focus())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "FlatButton", INK)
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		t.set_color(c, "FlatButton", INK)
	t.set_color(&"font_disabled_color", "FlatButton", Color(INK, 0.35))
	for ty in ["Button", "PrimaryButton", "ButterButton", "FlatButton"]:
		t.set_font(&"font", ty, font("bold"))
		t.set_font_size(&"font_size", ty, 16)
		t.set_constant(&"h_separation", ty, 8)
		t.set_constant(&"icon_max_width", ty, 18)

	# Tiny square buttons that live in window title bars
	t.set_type_variation("BarButton", "Button")
	t.set_stylebox(&"normal", "BarButton", box(PAPER, INK, LINE, 7, Vector4(4, 4, 4, 4)))
	t.set_stylebox(&"hover", "BarButton", box(BUTTER, INK, LINE, 7, Vector4(4, 4, 4, 4)))
	t.set_stylebox(&"pressed", "BarButton", box(Color("#F5B829"), INK, LINE, 7, Vector4(4, 4, 4, 4)))
	t.set_stylebox(&"focus", "BarButton", _focus())
	t.set_constant(&"icon_max_width", "BarButton", 14)
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		t.set_color(c, "BarButton", INK)

	# Segmented switch (2D / 3D): the group draws the track, the pressed button is a paper chip
	t.set_type_variation("SegButton", "Button")
	var seg_pad := Vector4(14, 6, 14, 6)
	t.set_stylebox(&"normal", "SegButton", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 9, seg_pad))
	t.set_stylebox(&"hover", "SegButton", box(Color(PAPER, 0.6), Color.TRANSPARENT, 0, 9, seg_pad))
	t.set_stylebox(&"pressed", "SegButton", box(PAPER, INK, LINE, 9, seg_pad))
	t.set_stylebox(&"hover_pressed", "SegButton", box(PAPER, INK, LINE, 9, seg_pad))
	t.set_stylebox(&"focus", "SegButton", _focus())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "SegButton", INK)
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		t.set_color(c, "SegButton", INK)
	t.set_font(&"font", "SegButton", font("bold"))
	t.set_font_size(&"font_size", "SegButton", 15)
	t.set_constant(&"icon_max_width", "SegButton", 16)

	# Text
	t.set_color(&"font_color", "Label", INK)
	for v in [["Display", "display", 40, INK], ["H2", "display", 26, INK], ["H3", "bold", 17, INK],
			["Muted", "regular", 15, MUTED], ["Numeral", "black", 24, PINK], ["Body", "regular", 17, INK], ["BarTitle", "black", 14, INK]]:
		t.set_type_variation(v[0], "Label")
		t.set_font(&"font", v[0], font(v[1]))
		t.set_font_size(&"font_size", v[0], v[2])
		t.set_color(&"font_color", v[0], v[3])
	t.set_type_variation("Caps", "Label")
	t.set_font(&"font", "Caps", caps_font())
	t.set_font_size(&"font_size", "Caps", 12)
	t.set_color(&"font_color", "Caps", MUTED)

	# Inputs
	for ty in ["LineEdit", "TextEdit"]:
		t.set_stylebox(&"normal", ty, box(PAPER, Color(INK, 0.45), LINE, 10, Vector4(12, 8, 12, 8)))
		t.set_stylebox(&"focus", ty, box(Color.TRANSPARENT, PINK, LINE, 10, Vector4(12, 8, 12, 8)))
		t.set_stylebox(&"read_only", ty, box(LAVENDER_TINT, Color(INK, 0.25), LINE, 10))
		t.set_color(&"font_color", ty, INK)
		t.set_color(&"font_placeholder_color", ty, Color("#8A7F99"))
		t.set_color(&"caret_color", ty, PINK)
		t.set_color(&"selection_color", ty, Color(PINK, 0.22))
		t.set_font_size(&"font_size", ty, 16)
	t.set_type_variation("TitleEdit", "LineEdit")
	t.set_stylebox(&"normal", "TitleEdit", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 10, Vector4(6, 0, 6, 0)))
	t.set_stylebox(&"focus", "TitleEdit", box(Color(PAPER, 0.8), PINK, LINE, 10, Vector4(6, 0, 6, 0)))
	t.set_font(&"font", "TitleEdit", font("display"))
	t.set_font_size(&"font_size", "TitleEdit", 34)

	# Windows, popups, dialogs
	t.set_stylebox(&"panel", "Panel", box(PAPER))
	t.set_stylebox(&"panel", "PanelContainer", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, Vector4.ZERO))
	t.set_type_variation("Pane", "PanelContainer")
	t.set_stylebox(&"panel", "Pane", soft_shadow(box(PAPER, INK, LINE, RADIUS, Vector4(LINE, LINE, LINE, LINE))))
	t.set_type_variation("Frame", "PanelContainer")
	t.set_stylebox(&"panel", "Frame", box(PAPER, INK, LINE, 10, Vector4(LINE, LINE, LINE, LINE)))
	var pop := soft_shadow(box(PAPER, INK, LINE, 16, Vector4(20, 18, 20, 20)), 24, 10)
	t.set_stylebox(&"panel", "PopupPanel", pop)
	t.set_stylebox(&"panel", "PopupMenu", soft_shadow(box(PAPER, INK, LINE, 12, Vector4(6, 6, 6, 6))))
	t.set_stylebox(&"hover", "PopupMenu", box(LAVENDER_TINT, Color.TRANSPARENT, 0, 8))
	t.set_color(&"font_color", "PopupMenu", INK)
	t.set_color(&"font_hover_color", "PopupMenu", INK)
	t.set_color(&"font_disabled_color", "PopupMenu", Color(INK, 0.35))
	t.set_font(&"font", "PopupMenu", font("semibold"))
	t.set_font_size(&"font_size", "PopupMenu", 15)
	t.set_constant(&"v_separation", "PopupMenu", 10)
	t.set_stylebox(&"panel", "TooltipPanel", box(INK, Color.TRANSPARENT, 0, 8, Vector4(10, 6, 10, 6)))
	t.set_color(&"font_color", "TooltipLabel", PAPER)
	t.set_font_size(&"font_size", "TooltipLabel", 14)
	# Dialog windows (rename, confirm): lavender title bar like every other window
	var frame := soft_shadow(box(LAVENDER, INK, LINE, 16, Vector4.ZERO), 24, 10)
	frame.expand_margin_left = 10
	frame.expand_margin_right = 10
	frame.expand_margin_bottom = 10
	frame.expand_margin_top = 42
	t.set_stylebox(&"embedded_border", "Window", frame)
	t.set_stylebox(&"embedded_unfocused_border", "Window", frame)
	t.set_font(&"title_font", "Window", font("black"))
	t.set_font_size(&"title_font_size", "Window", 15)
	t.set_color(&"title_color", "Window", INK)
	t.set_constant(&"title_height", "Window", 36)
	var x := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect x="1" y="1" width="22" height="22" rx="6" fill="#FFFDF8" stroke="#35294A" stroke-width="2"/><path d="M8 8l8 8M16 8l-8 8" stroke="#35294A" stroke-width="2.2" stroke-linecap="round"/></svg>'
	t.set_icon(&"close", "Window", _svg_tex(x))
	t.set_icon(&"close_pressed", "Window", _svg_tex(x))
	t.set_stylebox(&"panel", "AcceptDialog", box(PAPER, Color.TRANSPARENT, 0, 0, Vector4(18, 16, 18, 16)))

	# Scrollbars: soft lavender
	for ty in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox(&"scroll", ty, box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 6, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber", ty, box(Color(INK, 0.22), Color.TRANSPARENT, 0, 6, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber_highlight", ty, box(Color(INK, 0.4), Color.TRANSPARENT, 0, 6, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber_pressed", ty, box(PINK, Color.TRANSPARENT, 0, 6, Vector4(3, 3, 3, 3)))

	# Check boxes drawn to match
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "CheckBox", INK)
	t.set_stylebox(&"normal", "CheckBox", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"hover", "CheckBox", box(LAVENDER_TINT, Color.TRANSPARENT, 0, 8, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"pressed", "CheckBox", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"hover_pressed", "CheckBox", box(LAVENDER_TINT, Color.TRANSPARENT, 0, 8, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"focus", "CheckBox", _focus())
	var off := '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22"><rect x="2" y="2" width="18" height="18" rx="5" fill="#FFFDF8" stroke="#35294A" stroke-width="2"/></svg>'
	var on := '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22"><rect x="2" y="2" width="18" height="18" rx="5" fill="#D02E6E" stroke="#35294A" stroke-width="2"/><path d="M6.5 11.5l3 3 6-7" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>'
	t.set_icon(&"unchecked", "CheckBox", _svg_tex(off))
	t.set_icon(&"checked", "CheckBox", _svg_tex(on))
	t.set_font(&"font", "CheckBox", font("semibold"))
	return t


static func _focus() -> StyleBoxFlat:
	var s := box(Color.TRANSPARENT, PINK, LINE, 12)
	s.draw_center = false
	s.set_expand_margin_all(3)
	return s


static func _button(t: Theme, ty: String, bg: Color, hover: Color, press: Color, fg: Color, press_fg: Color) -> void:
	var pad := Vector4(16, 8, 16, 8)
	t.set_stylebox(&"normal", ty, box(bg, INK, LINE, 12, pad))
	t.set_stylebox(&"hover", ty, box(hover, INK, LINE, 12, pad))
	t.set_stylebox(&"pressed", ty, box(press, INK, LINE, 12, pad))
	t.set_stylebox(&"disabled", ty, box(Color("#F2ECE2"), Color(INK, 0.25), LINE, 12, pad))
	t.set_stylebox(&"focus", ty, _focus())
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(c, ty, fg)
	t.set_color(&"font_pressed_color", ty, press_fg)
	t.set_color(&"font_hover_pressed_color", ty, press_fg)
	t.set_color(&"font_disabled_color", ty, Color(INK, 0.4))
	for c in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		t.set_color(c, ty, fg)
	t.set_color(&"icon_pressed_color", ty, press_fg)
	t.set_color(&"icon_disabled_color", ty, Color(INK, 0.35))


# ---------- windows ----------

## A pastel window: outlined title bar in `bar` colour, cream body. Returns {root, bar, body}.
## Add real actions to `bar` (BarButton icons); put content in `body`.
static func window(title: String, bar: Color, body_pad := 12) -> Dictionary:
	var w := PanelContainer.new()
	w.theme_type_variation = "Pane"
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 0)
	w.add_child(col)
	var tb := PanelContainer.new()
	var sb := box(bar, INK, 0, 0, Vector4(14, 6, 8, 6))
	sb.corner_radius_top_left = RADIUS - LINE
	sb.corner_radius_top_right = RADIUS - LINE
	sb.border_width_bottom = LINE
	tb.add_theme_stylebox_override(&"panel", sb)
	tb.custom_minimum_size.y = 40
	var row := hbox(6)
	var l := label(title, "BarTitle")
	l.name = "Title"
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	tb.add_child(row)
	col.add_child(tb)
	var body := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		body.add_theme_constant_override("margin_" + side, body_pad)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	return {"root": w, "bar": row, "body": body}


static func bar_button(icon_name: String, tip: String) -> Button:
	var b := button("", icon_name, "BarButton", tip)
	b.custom_minimum_size = Vector2(28, 28)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


# ---------- motion ----------

## Windows and stickers arrive with a small overshoot, like a sticker pressed down.
static func pop_in(c: Control, delay := 0.0, from := 0.94) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(from, from)
	if not c.has_meta("pivot_hooked"):
		c.set_meta("pivot_hooked", true)
		c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.34).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func slide_in(c: Control, from := Vector2(24, 0), delay := 0.0) -> void:
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, 0.22).set_delay(delay)
	if c.get_parent() is Container:
		return  # containers own position; fade only
	var end := c.position
	c.position += from
	tw.tween_property(c, "position", end, 0.3).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Hover lift and press squash, scale only so layout never jumps.
static func juice(c: Control, lift := 1.04) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	var to := func(s: float, d: float) -> void:
		if c.has_meta("juice"):
			(c.get_meta("juice") as Tween).kill()
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector2(s, s), d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		c.set_meta("juice", tw)
	c.mouse_entered.connect(func(): if not (c is BaseButton and c.disabled): to.call(lift, 0.2))
	c.mouse_exited.connect(func(): to.call(1.0, 0.2))
	if c is BaseButton:
		c.button_down.connect(func(): to.call(0.95, 0.08))
		c.button_up.connect(func(): to.call(lift if c.is_hovered() else 1.0, 0.24))


# ---------- decoration ----------

## A four-point sparkle sticker with an ink outline.
static func draw_sparkle(ci: CanvasItem, c: Vector2, r: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2
		var rr := r if i % 2 == 0 else r * 0.32
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, maxf(1.5, r * 0.09), true)


class Desk extends Control:
	## The cream desk: faint grid and a few sparkle stickers in the corners.
	var sparkles := true

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), GROUND)
		var g := Color(INK, 0.05)
		var step := 32.0
		var x := step
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), g, 1.0)
			x += step
		var y := step
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), g, 1.0)
			y += step
		if sparkles:
			UI.draw_sparkle(self, Vector2(size.x * 0.58, 58), 20, BUTTER)
			UI.draw_sparkle(self, Vector2(size.x * 0.58 + 34, 96), 10, TEAL)
			UI.draw_sparkle(self, Vector2(42, size.y - 60), 16, PEACH)
			UI.draw_sparkle(self, Vector2(size.x - 52, size.y - 48), 14, LAVENDER)


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
	juice(b, 1.03 if text != "" else 1.08)
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
	p.add_theme_stylebox_override(&"panel", soft_shadow(box(INK, Color.TRANSPARENT, 0, 12, Vector4(18, 10, 18, 10))))
	var l := label(text)
	l.add_theme_color_override(&"font_color", PAPER)
	p.add_child(l)
	owner.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 32)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slide_in(p, Vector2(0, 20))
	var tw := p.create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)
