class_name UI
## The design system: semantic colour tokens, a 4-pt spacing grid, one type scale (Inter),
## the app Theme, panels, and widget factories. Screens use these and nothing ad hoc.

# ---------- colour tokens ----------
static var TEXT := Color("#1A1D23")
static var MUTED := Color("#5F6672")          # secondary text, 5.9:1 on SURFACE
static var SUBTLE := Color("#868D99")         # captions, disabled
static var BG := Color("#F4F5F7")             # app background
static var SURFACE := Color("#FFFFFF")        # panels, cards, inputs
static var SUNKEN := Color("#ECEEF1")         # canvas wells, tracks
static var HOVER := Color("#F0F2F5")
static var BORDER := Color("#DFE2E7")
static var BORDER_STRONG := Color("#C7CCD4")
static var ACCENT := Color("#4F46E5")         # path, numbers, primary action, focus, selection
static var ACCENT_HOVER := Color("#4338CA")
static var ACCENT_TINT := Color("#EEF0FE")
static var SUCCESS := Color("#1F7A4D")
static var SUCCESS_TINT := Color("#E6F4EC")
static var DANGER := Color("#C8322B")
static var DANGER_TINT := Color("#FCEBEA")

static var dark := false
static var on_theme_changed := Callable()

const DARK := {"TEXT": "#E8EAED", "MUTED": "#A3A9B4", "SUBTLE": "#7B828E", "BG": "#111318", "SURFACE": "#1A1D24", "SUNKEN": "#0D0F13",
	"HOVER": "#242832", "BORDER": "#2B303A", "BORDER_STRONG": "#3A404C", "ACCENT": "#6366F1", "ACCENT_HOVER": "#5458E0", "ACCENT_TINT": "#262A52",
	"SUCCESS": "#2F9E69", "SUCCESS_TINT": "#16301F", "DANGER": "#E5564D", "DANGER_TINT": "#3A1A18"}
const LIGHT := {"TEXT": "#1A1D23", "MUTED": "#5F6672", "SUBTLE": "#868D99", "BG": "#F4F5F7", "SURFACE": "#FFFFFF", "SUNKEN": "#ECEEF1",
	"HOVER": "#F0F2F5", "BORDER": "#DFE2E7", "BORDER_STRONG": "#C7CCD4", "ACCENT": "#4F46E5", "ACCENT_HOVER": "#4338CA", "ACCENT_TINT": "#EEF0FE",
	"SUCCESS": "#1F7A4D", "SUCCESS_TINT": "#E6F4EC", "DANGER": "#C8322B", "DANGER_TINT": "#FCEBEA"}


## Switches every colour token between the light and dark palettes.
static func set_dark(d: bool) -> void:
	dark = d
	var p: Dictionary = DARK if d else LIGHT
	TEXT = Color(p.TEXT); MUTED = Color(p.MUTED); SUBTLE = Color(p.SUBTLE); BG = Color(p.BG)
	SURFACE = Color(p.SURFACE); SUNKEN = Color(p.SUNKEN); HOVER = Color(p.HOVER)
	BORDER = Color(p.BORDER); BORDER_STRONG = Color(p.BORDER_STRONG)
	ACCENT = Color(p.ACCENT); ACCENT_HOVER = Color(p.ACCENT_HOVER); ACCENT_TINT = Color(p.ACCENT_TINT)
	SUCCESS = Color(p.SUCCESS); SUCCESS_TINT = Color(p.SUCCESS_TINT); DANGER = Color(p.DANGER); DANGER_TINT = Color(p.DANGER_TINT)


## Flips the theme, remembers the choice and asks the app to rebuild the screen.
static func toggle_dark() -> void:
	Store.settings.dark = not dark
	Store.save_settings()
	if on_theme_changed.is_valid():
		on_theme_changed.call()


static func theme_button() -> Button:
	var b := icon_button("sun" if dark else "moon", "Switch to light mode" if dark else "Switch to dark mode")
	b.pressed.connect(toggle_dark)
	return b


# ---------- metrics ----------
const S1 := 4
const S2 := 8
const S3 := 12
const S4 := 16
const S6 := 24
const S8 := 32
const LINE := 1
const R_CONTROL := 6
const R_PANEL := 8
const R_POPUP := 10
const BAR_H := 52                        # toolbar height
const HEAD_H := 40                       # panel header height
const FAST := 0.12                       # motion: state changes
const BASE := 0.18                       # motion: surfaces appearing

static var _fonts := {}
static var _icons := {}
static var _icon_svg: Dictionary


## Inter at a named weight: regular 400, medium 500, semibold 600, bold 700.
static func font(name: String) -> Font:
	if not _fonts.has(name):
		var base: FontFile = load("res://fonts/Inter.ttf")
		var fb: Array[Font] = [SceneArt.font()]  # colour emoji inside any text
		base.fallbacks = fb
		var v := FontVariation.new()
		v.base_font = base
		var wght: int = {"regular": 400, "medium": 500, "semibold": 600, "bold": 700}.get(name, 400)
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
		_fonts[name] = v
	return _fonts[name]


## Lucide icon rendered white at 2x so it stays sharp; tint it with modulate or theme icon colours.
static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		if _icon_svg.is_empty():
			_icon_svg = load("res://data/icons.json").data
		var img := Image.new()
		img.load_svg_from_string(_icon_svg.get(name, _icon_svg["x"]), 2.0)
		_icons[name] = ImageTexture.create_from_image(img)
	return _icons[name]


## A pre-tinted icon at an exact pixel size, for places the theme cannot tint (input adornments).
static func icon_px(name: String, px: int, color: Color) -> Texture2D:
	var key := "%s@%d#%s" % [name, px, color.to_html(false)]
	if not _icons.has(key):
		icon(name)  # loads the SVG table
		var svg: String = _icon_svg.get(name, _icon_svg["x"])
		_icons[key] = _svg_tex_scaled(svg.replace("#ffffff", "#" + color.to_html(false)), px / 24.0)
	return _icons[key]


static func _svg_tex_scaled(svg: String, scale: float) -> Texture2D:
	var img := Image.new()
	img.load_svg_from_string(svg, scale)
	return ImageTexture.create_from_image(img)


static func _svg_tex(svg: String) -> Texture2D:
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	return ImageTexture.create_from_image(img)


static func box(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := R_CONTROL, pad := Vector4(12, 7, 12, 7)) -> StyleBoxFlat:
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


## Elevation is reserved for things that float: popups, menus, toasts.
static func elevated(s: StyleBoxFlat) -> StyleBoxFlat:
	s.shadow_color = Color(0, 0, 0, 0.45) if dark else Color(0.06, 0.08, 0.14, 0.14)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 6)
	return s


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("regular")
	t.default_font_size = 14

	# Buttons
	_button(t, "Button", SURFACE, HOVER, SUNKEN, BORDER_STRONG, TEXT)
	_button(t, "PrimaryButton", ACCENT, ACCENT_HOVER, ACCENT_HOVER, ACCENT, Color.WHITE)
	_button(t, "FlatButton", Color.TRANSPARENT, HOVER, SUNKEN, Color.TRANSPARENT, TEXT)
	_button(t, "DangerButton", Color.TRANSPARENT, DANGER_TINT, DANGER_TINT, Color.TRANSPARENT, DANGER)
	for ty in ["PrimaryButton", "FlatButton", "DangerButton"]:
		t.set_type_variation(ty, "Button")
	t.set_stylebox(&"hover", "PrimaryButton", box(ACCENT_HOVER, ACCENT_HOVER, LINE))
	for ty in ["Button", "PrimaryButton", "FlatButton", "DangerButton"]:
		t.set_font(&"font", ty, font("medium"))
		t.set_font_size(&"font_size", ty, 14)
		t.set_constant(&"h_separation", ty, 6)
		t.set_constant(&"icon_max_width", ty, 16)

	# Icon-only square button for toolbars and panel headers
	_button(t, "IconButton", Color.TRANSPARENT, HOVER, SUNKEN, Color.TRANSPARENT, MUTED)
	t.set_type_variation("IconButton", "Button")
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBoxFlat = t.get_stylebox(st, "IconButton").duplicate()
		sb.set_content_margin_all(6)
		t.set_stylebox(st, "IconButton", sb)
	t.set_color(&"icon_hover_color", "IconButton", TEXT)
	t.set_constant(&"icon_max_width", "IconButton", 16)

	# Segmented control: the group draws the track, the pressed segment is a raised chip
	t.set_type_variation("SegButton", "Button")
	var seg_pad := Vector4(12, 4, 12, 4)
	t.set_stylebox(&"normal", "SegButton", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 5, seg_pad))
	t.set_stylebox(&"hover", "SegButton", box(Color(SURFACE, 0.6), Color.TRANSPARENT, 0, 5, seg_pad))
	t.set_stylebox(&"pressed", "SegButton", box(SURFACE, BORDER_STRONG, LINE, 5, seg_pad))
	t.set_stylebox(&"hover_pressed", "SegButton", box(SURFACE, BORDER_STRONG, LINE, 5, seg_pad))
	t.set_stylebox(&"focus", "SegButton", _focus())
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(c, "SegButton", MUTED)
	for c in ["font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "SegButton", TEXT)
	for c in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		t.set_color(c, "SegButton", MUTED)
	for c in ["icon_pressed_color", "icon_hover_pressed_color"]:
		t.set_color(c, "SegButton", TEXT)
	t.set_font(&"font", "SegButton", font("medium"))
	t.set_font_size(&"font_size", "SegButton", 13)
	t.set_constant(&"icon_max_width", "SegButton", 14)
	t.set_constant(&"h_separation", "SegButton", 6)

	# Type scale: 11 / 13 / 14 / 16 / 20 / 24
	t.set_color(&"font_color", "Label", TEXT)
	for v in [["Display", "semibold", 24, TEXT], ["H1", "semibold", 20, TEXT], ["H2", "semibold", 16, TEXT], ["H3", "semibold", 14, TEXT],
			["Body", "regular", 14, TEXT], ["Muted", "regular", 13, MUTED], ["Caps", "semibold", 11, SUBTLE],
			["BarTitle", "semibold", 13, TEXT], ["Numeral", "semibold", 13, ACCENT]]:
		t.set_type_variation(v[0], "Label")
		t.set_font(&"font", v[0], font(v[1]))
		t.set_font_size(&"font_size", v[0], v[2])
		t.set_color(&"font_color", v[0], v[3])
	t.set_constant(&"line_spacing", "Body", 5)
	t.set_constant(&"line_spacing", "Muted", 4)

	# Inputs
	for ty in ["LineEdit", "TextEdit"]:
		t.set_stylebox(&"normal", ty, box(SURFACE, BORDER_STRONG, LINE, R_CONTROL, Vector4(10, 7, 10, 7)))
		t.set_stylebox(&"focus", ty, box(Color.TRANSPARENT, ACCENT, 2, R_CONTROL, Vector4(10, 7, 10, 7)))
		t.set_stylebox(&"read_only", ty, box(HOVER, BORDER, LINE, R_CONTROL, Vector4(10, 7, 10, 7)))
		t.set_color(&"font_color", ty, TEXT)
		t.set_color(&"font_placeholder_color", ty, SUBTLE)
		t.set_color(&"caret_color", ty, ACCENT)
		t.set_color(&"selection_color", ty, Color(ACCENT, 0.2))
		t.set_color(&"clear_button_color", ty, SUBTLE)
		t.set_font_size(&"font_size", ty, 14)
	t.set_constant(&"line_spacing", "TextEdit", 5)
	t.set_type_variation("TitleEdit", "LineEdit")
	t.set_stylebox(&"normal", "TitleEdit", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, R_CONTROL, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"focus", "TitleEdit", box(SURFACE, ACCENT, 2, R_CONTROL, Vector4(6, 4, 6, 4)))
	t.set_font(&"font", "TitleEdit", font("semibold"))
	t.set_font_size(&"font_size", "TitleEdit", 15)

	# Surfaces
	t.set_stylebox(&"panel", "Panel", box(SURFACE))
	t.set_stylebox(&"panel", "PanelContainer", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, Vector4.ZERO))
	t.set_type_variation("Pane", "PanelContainer")
	t.set_stylebox(&"panel", "Pane", box(SURFACE, BORDER, LINE, R_PANEL, Vector4(LINE, LINE, LINE, LINE)))
	t.set_type_variation("Frame", "PanelContainer")
	t.set_stylebox(&"panel", "Frame", box(SUNKEN, BORDER, LINE, R_CONTROL, Vector4(LINE, LINE, LINE, LINE)))
	t.set_stylebox(&"panel", "PopupPanel", elevated(box(SURFACE, BORDER, LINE, R_POPUP, Vector4(S4, S4, S4, S4))))
	t.set_stylebox(&"panel", "PopupMenu", elevated(box(SURFACE, BORDER, LINE, R_PANEL, Vector4(4, 4, 4, 4))))
	t.set_stylebox(&"hover", "PopupMenu", box(HOVER, Color.TRANSPARENT, 0, 4))
	t.set_stylebox(&"separator", "PopupMenu", _rule())
	t.set_color(&"font_color", "PopupMenu", TEXT)
	t.set_color(&"font_hover_color", "PopupMenu", TEXT)
	t.set_color(&"font_disabled_color", "PopupMenu", SUBTLE)
	t.set_font_size(&"font_size", "PopupMenu", 13)
	t.set_constant(&"v_separation", "PopupMenu", 8)
	t.set_constant(&"item_start_padding", "PopupMenu", 10)
	t.set_constant(&"item_end_padding", "PopupMenu", 16)
	t.set_stylebox(&"panel", "TooltipPanel", box(TEXT, Color.TRANSPARENT, 0, 5, Vector4(8, 5, 8, 5)))
	t.set_color(&"font_color", "TooltipLabel", SURFACE)
	t.set_font_size(&"font_size", "TooltipLabel", 12)

	# Dialog windows (rename, confirm)
	var frame := elevated(box(SURFACE, BORDER, LINE, R_POPUP, Vector4.ZERO))
	frame.expand_margin_left = 8
	frame.expand_margin_right = 8
	frame.expand_margin_bottom = 8
	frame.expand_margin_top = 38
	t.set_stylebox(&"embedded_border", "Window", frame)
	t.set_stylebox(&"embedded_unfocused_border", "Window", frame)
	t.set_font(&"title_font", "Window", font("semibold"))
	t.set_font_size(&"title_font_size", "Window", 13)
	t.set_color(&"title_color", "Window", TEXT)
	t.set_constant(&"title_height", "Window", 34)
	var x := '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><path d="M6 6l8 8M14 6l-8 8" stroke="#%s" stroke-width="1.6" stroke-linecap="round"/></svg>' % MUTED.to_html(false)
	t.set_icon(&"close", "Window", _svg_tex(x))
	t.set_icon(&"close_pressed", "Window", _svg_tex(x))
	t.set_stylebox(&"panel", "AcceptDialog", box(SURFACE, Color.TRANSPARENT, 0, 0, Vector4(S4, S3, S4, S4)))

	# Scrollbars
	for ty in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox(&"scroll", ty, box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber", ty, box(BORDER_STRONG, Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber_highlight", ty, box(SUBTLE, Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))
		t.set_stylebox(&"grabber_pressed", ty, box(MUTED, Color.TRANSPARENT, 0, 4, Vector4(3, 3, 3, 3)))

	# Check boxes
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "CheckBox", TEXT)
	for st in ["normal", "pressed", "hover", "hover_pressed"]:
		t.set_stylebox(st, "CheckBox", box(HOVER if st.begins_with("hover") else Color.TRANSPARENT, Color.TRANSPARENT, 0, R_CONTROL, Vector4(6, 4, 6, 4)))
	t.set_stylebox(&"focus", "CheckBox", _focus())
	var off := '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"><rect x="1.5" y="1.5" width="15" height="15" rx="4" fill="#%s" stroke="#%s" stroke-width="1"/></svg>' % [SURFACE.to_html(false), BORDER_STRONG.to_html(false)]
	var on := '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"><rect x="1" y="1" width="16" height="16" rx="4" fill="#%s"/><path d="M5 9.3l2.7 2.7 5.3-6" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>' % ACCENT.to_html(false)
	t.set_icon(&"unchecked", "CheckBox", _svg_tex(off))
	t.set_icon(&"checked", "CheckBox", _svg_tex(on))
	t.set_constant(&"h_separation", "CheckBox", 8)
	return t


static func _focus() -> StyleBoxFlat:
	var s := box(Color.TRANSPARENT, ACCENT, 2, R_CONTROL + 2)
	s.draw_center = false
	s.set_expand_margin_all(2)
	return s


static func _rule() -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = BORDER
	l.thickness = 1
	return l


static func _button(t: Theme, ty: String, bg: Color, hover: Color, press: Color, border: Color, fg: Color) -> void:
	t.set_stylebox(&"normal", ty, box(bg, border, LINE))
	t.set_stylebox(&"hover", ty, box(hover, border, LINE))
	t.set_stylebox(&"pressed", ty, box(press, border, LINE))
	t.set_stylebox(&"disabled", ty, box(HOVER if bg.a > 0 else Color.TRANSPARENT, BORDER if border.a > 0 else Color.TRANSPARENT, LINE))
	t.set_stylebox(&"focus", ty, _focus())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, ty, fg)
	t.set_color(&"font_disabled_color", ty, SUBTLE)
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		t.set_color(c, ty, fg)
	t.set_color(&"icon_disabled_color", ty, SUBTLE)


# ---------- structure ----------

## A panel: bordered surface with a 40 px header (title + actions) and a body.
## Returns {root, bar, body}. Add IconButtons to `bar`; put content in `body`.
static func panel(title: String, body_pad := 0) -> Dictionary:
	var w := PanelContainer.new()
	w.theme_type_variation = "Pane"
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 0)
	w.add_child(col)
	var head := PanelContainer.new()
	var sb := box(Color.TRANSPARENT, BORDER, 0, 0, Vector4(S3, 0, S1 + 2, 0))
	sb.border_width_bottom = LINE
	head.add_theme_stylebox_override(&"panel", sb)
	head.custom_minimum_size.y = HEAD_H
	var row := hbox(S1)
	var l := label(title, "BarTitle")
	l.name = "Title"
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	head.add_child(row)
	col.add_child(head)
	var body := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		body.add_theme_constant_override("margin_" + side, body_pad)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	return {"root": w, "bar": row, "body": body}


## A full-width bar (toolbar or status bar) with a hairline on one edge.
static func bar(height: int, line_top := false) -> Dictionary:
	var p := PanelContainer.new()
	var sb := box(SURFACE, BORDER, 0, 0, Vector4(S3, 0, S3, 0))
	if line_top:
		sb.border_width_top = LINE
	else:
		sb.border_width_bottom = LINE
	p.add_theme_stylebox_override(&"panel", sb)
	p.custom_minimum_size.y = height
	var row := hbox(S2)
	p.add_child(row)
	return {"root": p, "row": row}


static func backdrop() -> ColorRect:
	var c := ColorRect.new()
	c.color = BG
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## A small status pill: neutral, accent, success or danger.
static func badge(text: String, tone := "neutral") -> PanelContainer:
	var tones := {"neutral": [HOVER, MUTED], "accent": [ACCENT_TINT, ACCENT], "success": [SUCCESS_TINT, SUCCESS], "danger": [DANGER_TINT, DANGER]}
	var c: Array = tones.get(tone, tones.neutral)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", box(c[0], Color.TRANSPARENT, 0, 10, Vector4(8, 2, 8, 2)))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := label(text)
	l.add_theme_font_override(&"font", font("medium"))
	l.add_theme_font_size_override(&"font_size", 12)
	l.add_theme_color_override(&"font_color", c[1])
	p.add_child(l)
	return p


## The numbered tag every memory carries, in lists and on cards.
static func number_tag(num: int) -> Label:
	var l := label(str(num))
	l.add_theme_font_override(&"font", font("semibold"))
	l.add_theme_font_size_override(&"font_size", 12)
	l.add_theme_color_override(&"font_color", Color.WHITE)
	l.add_theme_stylebox_override(&"normal", box(ACCENT, Color.TRANSPARENT, 0, 11, Vector4(6, 1, 6, 1)))
	l.custom_minimum_size = Vector2(22, 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


static func logo(size: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load("res://icon.svg")
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


# ---------- motion ----------

## Surfaces arrive with a short fade and a 2% settle. No bounce.
static func appear(c: Control, delay := 0.0) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.985, 0.985)
	if not c.has_meta("pivot_hooked"):
		c.set_meta("pivot_hooked", true)
		c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, BASE).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, BASE).set_delay(delay)


static func fade_in(c: Control, delay := 0.0) -> void:
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, BASE).set_delay(delay)


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
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


static func icon_button(icon_name: String, tip: String, variation := "IconButton") -> Button:
	var b := button("", icon_name, variation, tip)
	b.custom_minimum_size = Vector2(32, 32)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


static func label(text: String, variation := "", wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func hbox(sep := S2) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override(&"separation", sep)
	return b


static func vbox(sep := S2) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override(&"separation", sep)
	return b


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func vrule() -> Control:
	var c := ColorRect.new()
	c.color = BORDER
	c.custom_minimum_size = Vector2(1, 20)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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


static func plural(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, one if n == 1 else many]


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
	d.dialog_autowrap = true
	d.ok_button_text = ok
	d.confirmed.connect(cb)
	d.visibility_changed.connect(func(): if not d.visible: d.queue_free())
	owner.add_child(d)
	d.get_ok_button().theme_type_variation = "PrimaryButton"
	d.popup_centered(Vector2i(420, 0))


## A transient message at the bottom centre. `action` adds a button: [label, Callable].
static func toast(owner: Control, text: String, action := [], seconds := 2.6) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", elevated(box(TEXT, Color.TRANSPARENT, 0, R_PANEL, Vector4(S4, S2, S2 if action else S4, S2))))
	var row := hbox(S3)
	var l := label(text)
	l.add_theme_color_override(&"font_color", SURFACE)
	row.add_child(l)
	if action:
		var b := button(action[0], "", "FlatButton")
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, ACCENT if dark else Color("#C7CBFF"))
		b.add_theme_stylebox_override(&"hover", box(Color(1, 1, 1, 0.12), Color.TRANSPARENT, 0))
		b.pressed.connect(func(): action[1].call(); p.queue_free())
		row.add_child(b)
	p.add_child(row)
	owner.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 44)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fade_in(p)
	var tw := p.create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(p, "modulate:a", 0.0, BASE)
	tw.tween_callback(p.queue_free)
