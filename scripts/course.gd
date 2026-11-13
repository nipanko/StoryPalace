class_name Course
## The story path drawn over a scene: a start triangle, numbered memory markers,
## accent legs that stop at each marker's edge, and a double ring at the finish.


static func ring_width(r: float) -> float:
	return maxf(2.0, r * 0.1)


## A memory marker: white disc, accent ring, picture inside, numbered tag.
## state: "" | "ok" | "miss". opts.pop scales the marker while it lands.
static func draw_control(ci: CanvasItem, c: Vector2, r: float, num: int, item: Dictionary, opts := {}) -> void:
	r *= opts.get("pop", 1.0)
	if r < 1.0:
		return
	var w := ring_width(r)
	var sel: bool = opts.get("selected", false)
	ci.draw_circle(c + Vector2(0, r * 0.1), r + w * 0.5, Color(0.06, 0.08, 0.14, 0.18), true, -1, true)
	if sel:
		ci.draw_circle(c, r + w * 2.4, Color(UI.ACCENT, 0.22), true, -1, true)
	elif opts.get("hover", false):
		ci.draw_circle(c, r + w * 1.8, Color(UI.ACCENT, 0.12), true, -1, true)
	ci.draw_circle(c, r, Color.WHITE, true, -1, true)
	if not opts.get("hide_picture", false):
		draw_picture(ci, c, r * 1.2, item)
	else:
		draw_text_center(ci, c, "?", r * 1.0, Color("#868D99"))
	ci.draw_arc(c, r - w * 0.5, 0, TAU, 64, UI.ACCENT, w, true)
	if opts.get("finish", false):
		ci.draw_arc(c, r + w * 1.5, 0, TAU, 64, UI.ACCENT, w * 0.7, true)
	match opts.get("state", ""):
		"ok":
			var o := c + Vector2(r * 0.74, r * 0.74)
			var k := r * 0.4
			ci.draw_circle(o, k + 1.5, Color.WHITE, true, -1, true)
			ci.draw_circle(o, k, UI.SUCCESS, true, -1, true)
			ci.draw_polyline(PackedVector2Array([o + Vector2(-k * 0.5, 0), o + Vector2(-k * 0.1, k * 0.4), o + Vector2(k * 0.5, -k * 0.35)]), Color.WHITE, maxf(1.5, k * 0.22), true)
		"miss":
			var d := r * 0.72
			ci.draw_line(c + Vector2(-d, -d), c + Vector2(d, d), UI.DANGER, w * 1.2, true)
			ci.draw_line(c + Vector2(-d, d), c + Vector2(d, -d), UI.DANGER, w * 1.2, true)
	if opts.get("show_number", true):
		draw_number(ci, c + Vector2(r * 0.72, -r * 0.8), str(num), r * 0.66)


static func draw_text_center(ci: CanvasItem, c: Vector2, text: String, size: float, col: Color) -> void:
	var f := UI.font("semibold")
	var fs := maxi(8, int(size))
	var sz := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	ci.draw_string(f, Vector2(c.x - sz.x * 0.5, c.y - sz.y * 0.5 + f.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static func draw_picture(ci: CanvasItem, c: Vector2, size: float, item: Dictionary) -> void:
	var tex: Texture2D = Store.texture(item.get("image", ""))
	if tex:
		var s := size * 0.82
		var ts := tex.get_size()
		var k := minf(s / ts.x, s / ts.y)
		ci.draw_texture_rect(tex, Rect2(c - ts * k * 0.5, ts * k), false)
	else:
		SceneArt.draw_emoji(ci, c, item.get("icon", "⭐"), size)


## The accent number tag with a white keyline, anchored at its left-centre.
static func draw_number(ci: CanvasItem, pos: Vector2, text: String, size: float) -> void:
	var f := UI.font("semibold")
	var fs := maxi(9, int(size))
	var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var h := fs * 1.45
	var rect := Rect2(pos - Vector2(h * 0.3, h * 0.5), Vector2(maxf(h, ts.x + h * 0.6), h))
	ci.draw_style_box(UI.box(Color.WHITE, Color.TRANSPARENT, 0, int(h * 0.5) + 2, Vector4.ZERO), rect.grow(1.5))
	ci.draw_style_box(UI.box(UI.ACCENT, Color.TRANSPARENT, 0, int(h * 0.5), Vector4.ZERO), rect)
	ci.draw_string(f, Vector2(rect.get_center().x - ts.x * 0.5, rect.get_center().y - ts.y * 0.5 + f.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Start: a solid accent triangle pointing along the first leg.
static func draw_start(ci: CanvasItem, c: Vector2, r: float, toward: Vector2) -> void:
	var dir := (toward - c).normalized() if toward != c else Vector2.UP
	var pts := PackedVector2Array()
	for i in 3:
		pts.append(c + dir.rotated(TAU * i / 3.0) * r)
	var halo := PackedVector2Array()
	for i in 3:
		halo.append(c + dir.rotated(TAU * i / 3.0) * (r + 3.0))
	ci.draw_colored_polygon(halo, Color.WHITE)
	ci.draw_colored_polygon(pts, UI.ACCENT)


## A leg from circle edge to circle edge. progress 0..1 draws it partially (course being run).
static func draw_leg(ci: CanvasItem, a: Vector2, b: Vector2, ra: float, rb: float, progress := 1.0, dashed := false, width := 0.0) -> void:
	var d := b - a
	if d.length() <= ra + rb + 2:
		return
	var n := d.normalized()
	var s := a + n * (ra + 3)
	var e := b - n * (rb + 3)
	e = s.lerp(e, clampf(progress, 0, 1))
	var w := width if width > 0 else ring_width(rb)
	if dashed:
		ci.draw_dashed_line(s, e, UI.ACCENT, w, w * 3.0, true, true)
	else:
		ci.draw_line(s, e, UI.ACCENT, w, true)


## Everything for one room: entry mark, legs, controls. `numbers` are global course numbers.
static func draw_room_course(ci: CanvasItem, rect: Rect2, room: Dictionary, first_num: int, total: int, r: float, opts := {}) -> void:
	var items: Array = room.items
	var pts := []
	for it in items:
		pts.append(rect.position + Vector2(it.x, it.y) * rect.size)
	var entry := rect.position + Vector2(0.5, 0.94) * rect.size
	var limit: int = opts.get("reveal", items.size())   # tour: only legs already run
	var leg_progress: float = opts.get("leg_progress", 1.0)
	if not pts.is_empty() and limit > 0:
		if first_num == 1:
			draw_start(ci, entry, r * 0.9, pts[0])
			draw_leg(ci, entry, pts[0], r * 0.9, r, leg_progress if limit == 1 else 1.0)
		else:
			draw_leg(ci, entry, pts[0], 2, r, leg_progress if limit == 1 else 1.0, true)
	for i in range(1, mini(limit, pts.size())):
		draw_leg(ci, pts[i - 1], pts[i], r, r, leg_progress if i == limit - 1 else 1.0)
	var states: Dictionary = opts.get("states", {})
	for i in pts.size():
		if i >= limit and opts.has("reveal") and not opts.get("show_all", false):
			continue
		var it: Dictionary = items[i]
		draw_control(ci, pts[i], r, first_num + i, it, {
			"selected": it.id == opts.get("selected", ""), "hover": it.id == opts.get("hover", ""),
			"finish": first_num + i == total, "state": states.get(it.id, ""),
			"hide_picture": opts.get("hide_pictures", false) and it.id != opts.get("revealed", ""),
			"pop": opts.get("pops", {}).get(it.id, 1.0),
		})
