class_name SceneArt
## Ready-made rooms, drawn from code so they stay crisp at any size (thumbnails included).
## Coordinates of memories and decor are normalised 0..1 across the scene rect.

const HORIZON := 0.56  # where back wall meets floor, as a fraction of height
const INSET := 0.12    # side-wall depth, as a fraction of width

const THEMES := {
	"hallway": {"name": "Hallway", "kind": "in", "wall": "#CFDCC8", "side": "#B9CCB1", "floor": "#A9764E", "floor2": "#9A6A44", "style": "planks", "rug": "#C4553F",
		"decor": [["🪞", 0.2, 0.3, 0.2], ["👟", 0.24, 0.9, 0.09], ["☂️", 0.84, 0.7, 0.16], ["🪴", 0.08, 0.66, 0.18]]},
	"living": {"name": "Living room", "kind": "in", "wall": "#F2D6B8", "side": "#E6C3A0", "floor": "#B88457", "floor2": "#A97750", "style": "planks", "rug": "#E07A5F",
		"decor": [["🛋️", 0.47, 0.58, 0.3], ["🪴", 0.1, 0.62, 0.2], ["🖼️", 0.5, 0.22, 0.16], ["📺", 0.83, 0.5, 0.18]]},
	"kitchen": {"name": "Kitchen", "kind": "in", "wall": "#CDE8EA", "side": "#B6DADD", "floor": "#ECE7DE", "floor2": "#C9C2B6", "style": "checker", "rug": "",
		"decor": [["🫖", 0.3, 0.45, 0.13], ["🍳", 0.62, 0.47, 0.12], ["🧺", 0.84, 0.82, 0.16], ["🪑", 0.14, 0.8, 0.18]]},
	"bedroom": {"name": "Bedroom", "kind": "in", "wall": "#DCD3F0", "side": "#CBBFE6", "floor": "#9A8FB8", "floor2": "#9A8FB8", "style": "carpet", "rug": "#F2B5C6",
		"decor": [["🛏️", 0.5, 0.62, 0.3], ["🪔", 0.16, 0.5, 0.12], ["🧸", 0.82, 0.78, 0.15], ["🕰️", 0.8, 0.24, 0.12]]},
	"classroom": {"name": "Classroom", "kind": "in", "wall": "#E4EAF2", "side": "#D0D9E6", "floor": "#D9CFC0", "floor2": "#CDC2B1", "style": "tiles", "rug": "",
		"decor": [["🪑", 0.3, 0.8, 0.17], ["🪑", 0.7, 0.8, 0.17], ["🌐", 0.88, 0.48, 0.12], ["📚", 0.1, 0.52, 0.12]]},
	"library": {"name": "Library", "kind": "in", "wall": "#8A5A3B", "side": "#76492F", "floor": "#7B4B2E", "floor2": "#6E4229", "style": "planks", "rug": "#A23B3B",
		"decor": [["🪑", 0.5, 0.78, 0.18], ["🕯️", 0.5, 0.45, 0.1], ["🌍", 0.86, 0.8, 0.13]]},
	"castle": {"name": "Castle hall", "kind": "in", "wall": "#A3A8AE", "side": "#8E949B", "floor": "#7D8288", "floor2": "#6F747A", "style": "slabs", "rug": "#B23A48",
		"decor": [["🛡️", 0.3, 0.26, 0.14], ["⚔️", 0.7, 0.26, 0.14], ["👑", 0.5, 0.62, 0.12], ["🕯️", 0.1, 0.5, 0.12], ["🕯️", 0.9, 0.5, 0.12]]},
	"garden": {"name": "Garden", "kind": "out", "sky": "#A9DBF5", "sky2": "#E9F7FF", "hill": "#8CC97A", "hill2": "#6FB45E", "ground": "#7CC36A", "path": "#E7D3A8",
		"decor": [["🌳", 0.12, 0.5, 0.3], ["🌳", 0.88, 0.48, 0.26], ["⛲", 0.5, 0.56, 0.2], ["🌷", 0.2, 0.86, 0.1], ["🌷", 0.8, 0.9, 0.1], ["🪑", 0.72, 0.68, 0.14]]},
	"beach": {"name": "Beach", "kind": "out", "sky": "#8FD3F4", "sky2": "#FDF1D8", "hill": "#3FA7D6", "hill2": "#7FD1E8", "ground": "#F2D49B", "path": "#E9C584",
		"decor": [["🌴", 0.12, 0.5, 0.32], ["⛱️", 0.7, 0.62, 0.22], ["🐚", 0.3, 0.88, 0.08], ["🦀", 0.86, 0.86, 0.1]]},
}

const ORDER := ["living", "kitchen", "bedroom", "hallway", "classroom", "library", "castle", "garden", "beach"]

static var emoji_font: SystemFont


static func font() -> Font:
	if emoji_font == null:
		emoji_font = SystemFont.new()
		emoji_font.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"])
	return emoji_font


static func theme(id: String) -> Dictionary:
	return THEMES.get(id, THEMES.living)


## Draws an emoji centred on `c` with height roughly `size` pixels.
static func draw_emoji(ci: CanvasItem, c: Vector2, text: String, size: float, alpha := 1.0) -> void:
	var fs := maxi(4, int(size * 0.8))
	var f := font()
	var s := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	ci.draw_string(f, Vector2(c.x - s.x * 0.5, c.y - s.y * 0.5 + f.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, alpha))


static func draw_room(ci: CanvasItem, r: Rect2, room: Dictionary, with_decor := true) -> void:
	var photo: Texture2D = Store.texture(room.get("photo", ""))
	if photo:
		_draw_cover(ci, r, photo)
		return
	var t := theme(room.get("theme", "living"))
	if t.kind == "in":
		_indoor(ci, r, t, room.get("theme", ""))
	else:
		_outdoor(ci, r, t, room.get("theme", ""))
	if with_decor:
		for d in t.decor:
			var p := r.position + Vector2(d[1], d[2]) * r.size
			_shadow(ci, p + Vector2(0, d[3] * r.size.y * 0.42), d[3] * r.size.y * 0.42)
			draw_emoji(ci, p, d[0], d[3] * r.size.y)


static func _draw_cover(ci: CanvasItem, r: Rect2, tex: Texture2D) -> void:
	var ts := tex.get_size()
	var s := maxf(r.size.x / ts.x, r.size.y / ts.y)
	var src_size := r.size / s
	ci.draw_texture_rect_region(tex, r, Rect2((ts - src_size) * 0.5, src_size))


static func _shadow(ci: CanvasItem, c: Vector2, w: float) -> void:
	ci.draw_colored_polygon(_ellipse(c, Vector2(w, w * 0.22), 20), Color(0, 0, 0, 0.13))


static func _ellipse(c: Vector2, rad: Vector2, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
	return pts


static func _quad(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([a, b, c, d]), col)


static func _indoor(ci: CanvasItem, r: Rect2, t: Dictionary, id: String) -> void:
	var o := r.position
	var w := r.size.x
	var h := r.size.y
	var ix := w * INSET
	var y0 := h * 0.07
	var y1 := h * HORIZON
	var wall := Color(t.wall)
	var side := Color(t.side)
	# ceiling, side walls, back wall
	_quad(ci, o, o + Vector2(w, 0), o + Vector2(w - ix, y0), o + Vector2(ix, y0), side.lightened(0.18))
	_quad(ci, o, o + Vector2(ix, y0), o + Vector2(ix, y1), o + Vector2(0, h), side)
	_quad(ci, o + Vector2(w, 0), o + Vector2(w, h), o + Vector2(w - ix, y1), o + Vector2(w - ix, y0), side.darkened(0.05))
	ci.draw_rect(Rect2(o + Vector2(ix, y0), Vector2(w - 2 * ix, y1 - y0)), wall)
	# floor
	var fl := [o + Vector2(ix, y1), o + Vector2(w - ix, y1), o + Vector2(w, h), o + Vector2(0, h)]
	_quad(ci, fl[0], fl[1], fl[2], fl[3], Color(t.floor))
	_floor_pattern(ci, o, w, h, ix, y1, t)
	# baseboard
	ci.draw_rect(Rect2(o + Vector2(ix, y1 - h * 0.018), Vector2(w - 2 * ix, h * 0.018)), wall.darkened(0.18))
	match id:
		"kitchen":
			for i in 14:
				for j in 3:
					var tile := Rect2(o + Vector2(ix + i * (w - 2 * ix) / 14.0, y1 - h * 0.25 + j * h * 0.05), Vector2((w - 2 * ix) / 14.0 - 2, h * 0.05 - 2))
					ci.draw_rect(tile, Color.WHITE.lerp(wall, 0.35))
			ci.draw_rect(Rect2(o + Vector2(ix, y1 - h * 0.1), Vector2(w - 2 * ix, h * 0.1)), Color("#8C6A4F"))
			ci.draw_rect(Rect2(o + Vector2(ix - 4, y1 - h * 0.115), Vector2(w - 2 * ix + 8, h * 0.02)), Color("#F3EFE8"))
		"classroom":
			var board := Rect2(o + Vector2(w * 0.3, h * 0.14), Vector2(w * 0.4, h * 0.26))
			ci.draw_rect(board.grow(h * 0.012), Color("#9C6B43"))
			ci.draw_rect(board, Color("#2F5D50"))
			ci.draw_line(board.position + Vector2(board.size.x * 0.1, board.size.y * 0.3), board.position + Vector2(board.size.x * 0.55, board.size.y * 0.3), Color(1, 1, 1, 0.6), maxf(1, h * 0.006))
			ci.draw_line(board.position + Vector2(board.size.x * 0.1, board.size.y * 0.55), board.position + Vector2(board.size.x * 0.4, board.size.y * 0.55), Color(1, 1, 1, 0.45), maxf(1, h * 0.006))
		"library":
			_shelves(ci, Rect2(o + Vector2(ix + w * 0.02, y0 + h * 0.04), Vector2(w * 0.26, y1 - y0 - h * 0.06)))
			_shelves(ci, Rect2(o + Vector2(w - ix - w * 0.28, y0 + h * 0.04), Vector2(w * 0.26, y1 - y0 - h * 0.06)))
		"castle":
			for row in 7:
				var yy := y0 + row * (y1 - y0) / 7.0
				ci.draw_line(o + Vector2(ix, yy), o + Vector2(w - ix, yy), wall.darkened(0.12), maxf(1, h * 0.003))
				for col in 9:
					var xx := ix + (col + (0.5 if row % 2 else 0.0)) * (w - 2 * ix) / 9.0
					ci.draw_line(o + Vector2(xx, yy), o + Vector2(xx, yy + (y1 - y0) / 7.0), wall.darkened(0.12), maxf(1, h * 0.003))
			for bx in [0.38, 0.62]:
				var b := o + Vector2(w * bx, y0)
				ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-w * 0.04, 0), b + Vector2(w * 0.04, 0), b + Vector2(w * 0.04, h * 0.3), b + Vector2(0, h * 0.26), b + Vector2(-w * 0.04, h * 0.3)]), Color(t.rug))
				ci.draw_rect(Rect2(b + Vector2(-w * 0.04, 0), Vector2(w * 0.08, h * 0.02)), Color("#E3B23C"))
		"hallway":
			var door := Rect2(o + Vector2(w * 0.44, h * 0.16), Vector2(w * 0.17, y1 - h * 0.16))
			ci.draw_rect(door.grow(h * 0.012), wall.darkened(0.25))
			ci.draw_rect(door, Color("#7A4E33"))
			ci.draw_rect(Rect2(door.position + door.size * Vector2(0.15, 0.08), door.size * Vector2(0.7, 0.36)), Color("#8B5B3D"))
			ci.draw_rect(Rect2(door.position + door.size * Vector2(0.15, 0.52), door.size * Vector2(0.7, 0.4)), Color("#8B5B3D"))
			ci.draw_circle(door.position + door.size * Vector2(0.84, 0.55), h * 0.012, Color("#E3B23C"))
	if id in ["living", "bedroom", "kitchen", "classroom"]:
		var wx := 0.2 if id != "classroom" else 0.15
		_window(ci, Rect2(o + Vector2(w * wx, h * 0.14), Vector2(w * 0.15, h * (0.24 if id == "kitchen" else 0.27))))
	if t.rug != "" and id != "castle":
		ci.draw_colored_polygon(_ellipse(o + Vector2(w * 0.5, h * 0.82), Vector2(w * 0.24, h * 0.08)), Color(t.rug, 0.85))
	elif id == "castle":
		_quad(ci, o + Vector2(w * 0.44, y1), o + Vector2(w * 0.56, y1), o + Vector2(w * 0.64, h), o + Vector2(w * 0.36, h), Color(t.rug))


static func _floor_pattern(ci: CanvasItem, o: Vector2, w: float, h: float, ix: float, y1: float, t: Dictionary) -> void:
	var line := Color(t.floor2)
	var lw := maxf(1.0, h * 0.003)
	var style: String = t.style
	if style == "carpet":
		return
	var cols: int = {"planks": 10, "tiles": 8, "checker": 8, "slabs": 6}[style]
	for i in cols + 1:
		var f := float(i) / cols
		ci.draw_line(o + Vector2(ix + f * (w - 2 * ix), y1), o + Vector2(f * w, h), line, lw, true)
	if style == "planks":
		return
	var rows := 6
	for j in rows + 1:
		# perspective: rows bunch up toward the back wall
		var f := pow(float(j) / rows, 1.6)
		var y := lerpf(y1, h, f)
		var x0 := lerpf(ix, 0, f)
		if style == "checker" and j < rows:
			var f2 := pow(float(j + 1) / rows, 1.6)
			var y2 := lerpf(y1, h, f2)
			var x2 := lerpf(ix, 0, f2)
			for i in cols:
				if (i + j) % 2 == 0:
					continue
				var a := float(i) / cols
				var b := float(i + 1) / cols
				_quad(ci, o + Vector2(x0 + a * (w - 2 * x0), y), o + Vector2(x0 + b * (w - 2 * x0), y),
					o + Vector2(x2 + b * (w - 2 * x2), y2), o + Vector2(x2 + a * (w - 2 * x2), y2), line)
		ci.draw_line(o + Vector2(x0, y), o + Vector2(w - x0, y), line, lw, true)


static func _window(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r.grow(r.size.y * 0.05), Color.WHITE)
	ci.draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]),
		PackedColorArray([Color("#8FCBF0"), Color("#8FCBF0"), Color("#DDF2FF"), Color("#DDF2FF")]))
	ci.draw_line(r.position + Vector2(r.size.x * 0.5, 0), r.position + Vector2(r.size.x * 0.5, r.size.y), Color.WHITE, maxf(1, r.size.y * 0.04))
	ci.draw_line(r.position + Vector2(0, r.size.y * 0.5), r.position + Vector2(r.size.x, r.size.y * 0.5), Color.WHITE, maxf(1, r.size.y * 0.04))


static func _shelves(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color("#5E3B26"))
	var spines := [Color("#C0392B"), Color("#2E86AB"), Color("#F2C14E"), Color("#3BB273"), Color("#8E5AA8"), Color("#E8E1D0"), Color("#1F4E79")]
	var rows := 4
	var rh := r.size.y / rows
	var seed := 7
	for j in rows:
		var x := r.position.x + rh * 0.08
		var y := r.position.y + j * rh
		while x < r.end.x - rh * 0.12:
			seed = (seed * 1103515245 + 12345) & 0x7fffffff
			var bw := rh * (0.1 + (seed % 7) * 0.02)
			var bh := rh * (0.62 + (seed % 5) * 0.06)
			ci.draw_rect(Rect2(x, y + rh * 0.92 - bh, minf(bw, r.end.x - rh * 0.1 - x), bh), spines[seed % spines.size()])
			x += bw + rh * 0.015
		ci.draw_rect(Rect2(r.position.x, y + rh * 0.92, r.size.x, rh * 0.08), Color("#4A2E1D"))


static func _outdoor(ci: CanvasItem, r: Rect2, t: Dictionary, id: String) -> void:
	var o := r.position
	var w := r.size.x
	var h := r.size.y
	var hy := h * 0.5
	ci.draw_polygon(PackedVector2Array([o, o + Vector2(w, 0), o + Vector2(w, hy), o + Vector2(0, hy)]),
		PackedColorArray([Color(t.sky), Color(t.sky), Color(t.sky2), Color(t.sky2)]))
	ci.draw_circle(o + Vector2(w * 0.8, h * 0.15), h * 0.06, Color("#FFE07A"), true, -1, true)
	for c in [Vector2(0.22, 0.14), Vector2(0.55, 0.1)]:
		var p: Vector2 = o + c * r.size
		for k in 3:
			ci.draw_circle(p + Vector2((k - 1) * h * 0.04, (k % 2) * -h * 0.015), h * 0.032, Color(1, 1, 1, 0.92), true, -1, true)
	# far band: hills for the garden, sea for the beach
	var far := PackedVector2Array([o + Vector2(0, hy)])
	for i in 25:
		var f := i / 24.0
		var bump := (sin(f * 9.0) * 0.03 + sin(f * 3.1 + 1.0) * 0.04) if id == "garden" else 0.0
		far.append(o + Vector2(f * w, h * (0.42 + bump)))
	far.append(o + Vector2(w, hy + h * 0.06))
	far.append(o + Vector2(0, hy + h * 0.06))
	ci.draw_colored_polygon(far, Color(t.hill))
	ci.draw_rect(Rect2(o + Vector2(0, hy), Vector2(w, h * 0.06)), Color(t.hill2))
	ci.draw_rect(Rect2(o + Vector2(0, hy + h * 0.06), Vector2(w, h - hy - h * 0.06)), Color(t.ground))
	if id == "beach":
		for i in 3:
			var y := hy + h * (0.015 + i * 0.018)
			ci.draw_line(o + Vector2(w * 0.1 * i, y), o + Vector2(w * (0.4 + 0.2 * i), y), Color(1, 1, 1, 0.5), maxf(1, h * 0.004))
	_quad(ci, o + Vector2(w * 0.46, hy + h * 0.06), o + Vector2(w * 0.54, hy + h * 0.06), o + Vector2(w * 0.68, h), o + Vector2(w * 0.32, h), Color(t.path))
