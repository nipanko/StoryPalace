class_name Course
## Orienteering course notation drawn over a scene: start triangle, numbered control circles,
## legs that stop at circle edges, and a double circle for the finish.


static func ring_width(r: float) -> float:
	return maxf(2.0, r * 0.13)


## A control: circle, picture inside, purple number beside it. state: "" | "ok" | "miss".
static func draw_control(ci: CanvasItem, c: Vector2, r: float, num: int, item: Dictionary, opts := {}) -> void:
	var w := ring_width(r)
	var sel: bool = opts.get("selected", false)
	if sel:
		ci.draw_circle(c, r + w, Color(UI.YELLOW, 0.95), true, -1, true)
	else:
		ci.draw_circle(c, r, Color(1, 1, 1, 0.72), true, -1, true)
	if opts.get("hover", false) and not sel:
		ci.draw_circle(c, r + w * 1.6, Color(UI.PURPLE, 0.18), false, w, true)
	if not opts.get("hide_picture", false):
		draw_picture(ci, c, r * 1.25, item)
	ci.draw_arc(c, r, 0, TAU, 48, UI.PURPLE, w * (1.4 if sel else 1.0), true)
	if opts.get("finish", false):
		ci.draw_arc(c, r + w * 2.4, 0, TAU, 56, UI.PURPLE, w, true)
	match opts.get("state", ""):
		"ok":
			ci.draw_circle(c + Vector2(r * 0.72, r * 0.72), r * 0.42, UI.GREEN_TEXT, true, -1, true)
			var k := r * 0.42
			var o := c + Vector2(r * 0.72, r * 0.72)
			ci.draw_polyline(PackedVector2Array([o + Vector2(-k * 0.5, 0), o + Vector2(-k * 0.1, k * 0.4), o + Vector2(k * 0.5, -k * 0.35)]), Color.WHITE, maxf(2, k * 0.25), true)
		"miss":
			var d := r * 0.95
			ci.draw_line(c + Vector2(-d, -d), c + Vector2(d, d), UI.RED, w * 1.2, true)
			ci.draw_line(c + Vector2(-d, d), c + Vector2(d, -d), UI.RED, w * 1.2, true)
	if opts.get("show_number", true):
		draw_number(ci, c + Vector2(r * 0.9, -r * 0.95), str(num), r * 1.05)


static func draw_picture(ci: CanvasItem, c: Vector2, size: float, item: Dictionary) -> void:
	var tex: Texture2D = Store.texture(item.get("image", ""))
	if tex:
		var s := size * 0.82
		var ts := tex.get_size()
		var k := minf(s / ts.x, s / ts.y)
		ci.draw_texture_rect(tex, Rect2(c - ts * k * 0.5, ts * k), false)
	else:
		SceneArt.draw_emoji(ci, c, item.get("icon", "⭐"), size)


static func draw_number(ci: CanvasItem, pos: Vector2, text: String, size: float) -> void:
	var f := UI.font("BarlowCondensed-Bold")
	var fs := maxi(8, int(size))
	var at := pos + Vector2(0, f.get_ascent(fs) * 0.5)
	ci.draw_string_outline(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(3, int(size * 0.22)), Color.WHITE)
	ci.draw_string(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.PURPLE)


## Start: an equilateral triangle pointing along the first leg.
static func draw_start(ci: CanvasItem, c: Vector2, r: float, toward: Vector2) -> void:
	var dir := (toward - c).normalized() if toward != c else Vector2.UP
	var pts := PackedVector2Array()
	for i in 3:
		pts.append(c + dir.rotated(TAU * i / 3.0) * r)
	pts.append(pts[0])
	ci.draw_polyline(pts, UI.PURPLE, ring_width(r) * 1.1, true)


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
		ci.draw_dashed_line(s, e, UI.PURPLE, w, w * 3.0, true, true)
	else:
		ci.draw_line(s, e, UI.PURPLE, w, true)


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
		})
