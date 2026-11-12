class_name PalaceWorld
extends TextureRect
## The palace in 3D: rooms side by side joined by doorways, each memory at a control flag,
## the course as a purple line on the floor. Drag to look, W A S D / arrows to walk.

signal selected(item_id: String)
signal added(item: Dictionary)
signal room_entered(room: Dictionary)

const W := 10.0
const D := 8.0
const H := 3.2
const DOOR := 1.8
const DOOR_H := 2.5
const EYE := 1.6
const TOP := 0.07   # 2D y where the back wall starts
const ON_WALL := SceneArt.HORIZON - 0.1   # above this line a control hangs on the back wall

var palace: Dictionary
var selected_id := "":
	set(v):
		selected_id = v
		if is_inside_tree():
			_build_controls()
var tour := {}          # same options as the 2D course: reveal, states, hide_pictures, revealed
var editable := true

var _vp := SubViewport.new()
var _root: Node3D
var _course: Node3D
var _controls: Node3D
var _player := CharacterBody3D.new()
var _cam := Camera3D.new()
var _yaw := 0.0
var _pitch := -0.12
var _press := Vector2.ZERO
var _pressing := false
var _moved := false
var _room_i := -1
var _touring := false

static var _tex := {}


func _ready() -> void:
	expand_mode = EXPAND_IGNORE_SIZE
	stretch_mode = STRETCH_SCALE
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_STOP
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	add_child(_vp)
	texture = _vp.get_texture()

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#7FC2EE")
	sky_mat.sky_horizon_color = Color("#E2F3FF")
	sky_mat.ground_horizon_color = Color("#E2F3FF")
	sky_mat.ground_bottom_color = Color("#B9D7C0")
	env.sky = Sky.new()
	env.sky.sky_material = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.38
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	_player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.4
	shape.shape = cap
	shape.position.y = 0.9
	_player.add_child(shape)
	_cam.position.y = EYE
	_cam.fov = 68
	_cam.near = 0.05
	_player.add_child(_cam)
	_vp.add_child(_player)
	resized.connect(_fit)
	_fit()
	rebuild()


func _process(_d: float) -> void:
	if is_visible_in_tree():
		OS.low_processor_usage_mode = false   # 3D needs every frame while the camera moves


func _exit_tree() -> void:
	OS.low_processor_usage_mode = true


func _fit() -> void:
	var s := get_window().content_scale_factor if is_inside_tree() else 1.0
	_vp.size = Vector2i((size * s).max(Vector2(8, 8)))


# ---------- building ----------

func rebuild() -> void:
	if not is_inside_tree():
		return
	if _root:
		_root.queue_free()
	_root = Node3D.new()
	_vp.add_child(_root)
	for i in palace.rooms.size():
		_build_room(i, palace.rooms[i])
	_course = Node3D.new()
	_root.add_child(_course)
	_controls = Node3D.new()
	_root.add_child(_controls)
	_build_course()
	_build_controls()


## Rooms are flat-coloured like the 2D maps: unlit, so colours match exactly and old laptops stay fast.
func _mat(c: Color, _unshaded := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## A 2 m x 2 m floor patch drawn with native fills; the material tiles it across the room.
static func _floor_tex(style: String, base: Color, line: Color) -> Texture2D:
	var key := "floor%s%s%s" % [style, base.to_html(), line.to_html()]
	if _tex.has(key):
		return _tex[key]
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	img.fill(base)
	match style:
		"planks":
			for i in 4:
				img.fill_rect(Rect2i(i * 64, 0, 3, s), line)
				img.fill_rect(Rect2i(i * 64, (i * 97) % s, 64, 3), line)
		"tiles":
			for i in 4:
				img.fill_rect(Rect2i(i * 64, 0, 2, s), line)
				img.fill_rect(Rect2i(0, i * 64, s, 2), line)
		"checker":
			for i in 4:
				for j in 4:
					if (i + j) % 2:
						img.fill_rect(Rect2i(i * 64, j * 64, 64, 64), line)
		"slabs":
			for j in 2:
				img.fill_rect(Rect2i(0, j * 128, s, 4), line)
				img.fill_rect(Rect2i(((j * 64) % 128), j * 128, 4, 128), line)
				img.fill_rect(Rect2i(((j * 64) % 128) + 128, j * 128, 4, 128), line)
	img.generate_mipmaps()
	_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]


func _plane(size2: Vector2, pos: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size2
	pm.material = m
	mi.mesh = pm
	mi.position = pos
	_root.add_child(mi)


func _box(size3: Vector3, pos: Vector3, col: Color, solid := true, meta := {}) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size3
	bm.material = _mat(col)
	mi.mesh = bm
	mi.position = pos
	_root.add_child(mi)
	if solid:
		_body(size3, pos, meta)


func _body(size3: Vector3, pos: Vector3, meta := {}) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size3
	cs.shape = bs
	sb.add_child(cs)
	sb.position = pos
	for k in meta:
		sb.set_meta(k, meta[k])
	_root.add_child(sb)


func _build_room(i: int, room: Dictionary) -> void:
	var cx := i * W
	var t := SceneArt.theme(room.theme)
	var photo: Texture2D = Store.texture(room.photo)
	var indoor: bool = t.kind == "in" or photo != null
	var floor_col := Color(t.floor) if t.kind == "in" else Color(t.ground)
	if photo:
		floor_col = Color("#CFC6B8")
	_body(Vector3(W, 0.2, D), Vector3(cx, -0.1, 0), {"room": i, "kind": "floor"})
	var fm := _mat(floor_col)
	if t.kind == "in" and not photo:
		fm.albedo_color = Color.WHITE  # the texture already carries the floor colour
		fm.albedo_texture = _floor_tex(t.style, floor_col, Color(t.floor2).darkened(0.08))
		fm.uv1_scale = Vector3(W / 2.0, D / 2.0, 1)
		fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_plane(Vector2(W, D), Vector3(cx, 0, 0), fm)
	if t.kind == "out":
		_plane(Vector2(1.8, D), Vector3(cx, 0.005, 0), _mat(Color(t.path)))
	if t.get("rug", "") != "" and not photo:
		var rug := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = 0.02
		cm.material = _mat(Color(t.rug))
		rug.mesh = cm
		rug.scale = Vector3(2.4, 1, 1.1)
		rug.position = Vector3(cx, 0.01, D * 0.25)
		_root.add_child(rug)
	var has_prev := i > 0
	var has_next: bool = i < palace.rooms.size() - 1
	if indoor:
		var wall := Color(t.get("wall", "#E9E5DC")) if not photo else Color("#EDEAE3")
		var side := Color(t.get("side", "#DDD8CC")) if not photo else Color("#E2DED5")
		_box(Vector3(W, H, 0.2), Vector3(cx, H / 2, -D / 2 - 0.1), wall, true, {"room": i, "kind": "wall"})
		_box(Vector3(W, H, 0.2), Vector3(cx, H / 2, D / 2 + 0.1), side)
		_side_wall(cx - W / 2 + 0.05, has_prev, side)
		_side_wall(cx + W / 2 - 0.05, has_next, side)
		if photo:
			var ts := photo.get_size()
			var qh := H - 0.4
			var qw := minf(W - 0.6, qh * ts.x / ts.y)
			qh = qw * ts.y / ts.x
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(qw, qh)
			var m := _mat(Color.WHITE, true)
			m.albedo_texture = photo
			qm.material = m
			q.mesh = qm
			q.position = Vector3(cx, 0.2 + qh / 2, -D / 2 + 0.01)
			_root.add_child(q)
		elif room.theme in ["living", "bedroom", "kitchen", "classroom"]:
			var wx := 0.2 if room.theme != "classroom" else 0.15
			var a := wall_point(cx, wx, 0.14)
			var b := wall_point(cx, wx + 0.15, 0.41)
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(b.x - a.x, a.y - b.y)
			qm.material = _mat(Color("#BFE3FA"), true)
			q.mesh = qm
			q.position = Vector3((a.x + b.x) / 2, (a.y + b.y) / 2, -D / 2 + 0.02)
			_root.add_child(q)
	else:
		# open air: invisible fences keep the walker on the map
		_body(Vector3(W, 3, 0.2), Vector3(cx, 1.5, -D / 2 - 0.1), {"room": i, "kind": "wall"})
		_body(Vector3(W, 3, 0.2), Vector3(cx, 1.5, D / 2 + 0.1))
		if not has_prev:
			_body(Vector3(0.2, 3, D), Vector3(cx - W / 2, 1.5, 0))
		if not has_next:
			_body(Vector3(0.2, 3, D), Vector3(cx + W / 2, 1.5, 0))
		if room.theme == "beach":
			_plane(Vector2(W, 30), Vector3(cx, -0.05, -D / 2 - 15), _mat(Color(t.hill)))
		else:
			_box(Vector3(W, 0.9, 0.5), Vector3(cx, 0.45, -D / 2 - 0.4), Color(t.hill2), false)
	if not photo:
		for d in t.decor:
			_decor(cx, d)


func _side_wall(x: float, door: bool, col: Color) -> void:
	if not door:
		_box(Vector3(0.1, H, D), Vector3(x, H / 2, 0), col)
		return
	var seg := (D - DOOR) / 2
	_box(Vector3(0.1, H, seg), Vector3(x, H / 2, -D / 2 + seg / 2), col)
	_box(Vector3(0.1, H, seg), Vector3(x, H / 2, D / 2 - seg / 2), col)
	_box(Vector3(0.1, H - DOOR_H, DOOR), Vector3(x, DOOR_H + (H - DOOR_H) / 2, 0), col, false)


func _decor(cx: float, d: Array) -> void:
	var l := Label3D.new()
	l.text = d[0]
	l.font = SceneArt.font()
	l.font_size = 128
	var meters: float = d[3] * 4.0
	l.pixel_size = meters / 150.0
	l.outline_size = 0
	l.double_sided = true
	var y: float = d[2]
	if y < ON_WALL:
		l.position = wall_point(cx, d[1], y) + Vector3(0, 0, 0.06)
	else:
		l.position = floor_point(cx, d[1], y)
		l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		_contact(l.position, meters * 0.45)
	_root.add_child(l)


func _contact(at: Vector3, radius: float) -> void:
	var m := _mat(Color(0, 0, 0, 0.14))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.004
	cm.radial_segments = 24
	cm.material = m
	mi.mesh = cm
	mi.scale = Vector3(1, 1, 0.45)
	mi.position = Vector3(at.x, 0.012, at.z)
	_root.add_child(mi)


# ---------- 2D <-> 3D mapping ----------

static func floor_point(cx: float, x: float, y: float) -> Vector3:
	var f := clampf((y - SceneArt.HORIZON) / (1.0 - SceneArt.HORIZON), 0, 1)
	var inset := SceneArt.INSET * (1.0 - f)
	var u := (x - inset) / (1.0 - 2.0 * inset)
	return Vector3(cx + (u - 0.5) * (W - 1.0), 0.0, -D / 2 + 0.7 + f * (D - 1.4))


static func wall_point(cx: float, x: float, y: float) -> Vector3:
	var u := (x - SceneArt.INSET) / (1.0 - 2.0 * SceneArt.INSET)
	var h := H * (SceneArt.HORIZON - y) / (SceneArt.HORIZON - TOP)
	return Vector3(cx + (u - 0.5) * W, clampf(h, 0.5, H - 0.25), -D / 2 + 0.12)


func item_point(i: int, it: Dictionary) -> Vector3:
	if it.y < ON_WALL:
		return wall_point(i * W, it.x, it.y)
	return floor_point(i * W, it.x, it.y) + Vector3(0, 1.45, 0)


func _ground_of(p: Vector3) -> Vector3:
	return Vector3(p.x, 0.02, maxf(p.z, -D / 2 + 0.7))


func _floor_to_norm(cx: float, p: Vector3) -> Vector2:
	var f := clampf((p.z + D / 2 - 0.7) / (D - 1.4), 0, 1)
	var inset := SceneArt.INSET * (1.0 - f)
	var u := (p.x - cx) / (W - 1.0) + 0.5
	return Vector2(clampf(inset + u * (1.0 - 2.0 * inset), 0.03, 0.97), clampf(SceneArt.HORIZON + 0.02 + f * (1.0 - SceneArt.HORIZON - 0.06), 0.04, 0.96))


func _wall_to_norm(cx: float, p: Vector3) -> Vector2:
	var u := (p.x - cx) / W + 0.5
	var y := SceneArt.HORIZON - clampf(p.y, 0.5, H - 0.25) / H * (SceneArt.HORIZON - TOP)
	return Vector2(clampf(SceneArt.INSET + u * (1.0 - 2.0 * SceneArt.INSET), 0.03, 0.97), clampf(y, 0.08, SceneArt.HORIZON - 0.03))


# ---------- course and controls ----------

func _all() -> Array:
	var out := []
	for i in palace.rooms.size():
		for it in palace.rooms[i].items:
			out.append([i, it])
	return out


func _route(a: Vector3, ai: int, b: Vector3, bi: int) -> Array:
	var pts := [a]
	var step := 1 if bi > ai else -1
	var i := ai
	while i != bi:
		var door_x := (i + (0.5 if step > 0 else -0.5)) * W
		pts.append(Vector3(door_x - step * 0.8, 0.02, 0))
		pts.append(Vector3(door_x + step * 0.8, 0.02, 0))
		i += step
	pts.append(b)
	return pts


func _build_course() -> void:
	for c in _course.get_children():
		c.queue_free()
	var all := _all()
	if all.is_empty():
		return
	var limit: int = tour.get("reveal", all.size())
	var purple := _mat(UI.ACCENT, true)
	var start := Vector3(0, 0.02, D / 2 - 0.9)
	var tri := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.radial_segments = 3
	tm.top_radius = 0.45
	tm.bottom_radius = 0.45
	tm.height = 0.02
	tm.material = purple
	tri.mesh = tm
	tri.position = start
	_course.add_child(tri)
	var prev := start
	var prev_i := 0
	for k in mini(limit, all.size()):
		var g := _ground_of(item_point(all[k][0], all[k][1]))
		var pts := _route(prev, prev_i, g, all[k][0])
		for j in pts.size() - 1:
			_ribbon(pts[j], pts[j + 1], purple)
		prev = g
		prev_i = all[k][0]
	if limit >= all.size():
		var fin := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 0.55
		tor.outer_radius = 0.66
		tor.material = purple
		fin.mesh = tor
		fin.scale = Vector3(1, 0.05, 1)
		fin.position = prev
		_course.add_child(fin)


func _ribbon(a: Vector3, b: Vector3, m: Material) -> void:
	var d := b - a
	d.y = 0
	if d.length() < 0.05:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 0.012, d.length())
	bm.material = m
	mi.mesh = bm
	mi.position = (a + b) / 2
	mi.position.y = 0.02
	mi.rotation.y = atan2(d.x, d.z)
	_course.add_child(mi)


func _build_controls() -> void:
	if _controls == null:
		return
	for c in _controls.get_children():
		c.queue_free()
	var all := _all()
	var states: Dictionary = tour.get("states", {})
	var limit: int = tour.get("reveal", all.size())
	for k in all.size():
		if tour.has("reveal") and k >= limit and not tour.get("show_all", false):
			continue
		var i: int = all[k][0]
		var it: Dictionary = all[k][1]
		var p := item_point(i, it)
		var n := Node3D.new()
		n.position = p
		_controls.add_child(n)
		if it.y >= ON_WALL:
			_flag(n, p)
			_contact(Vector3(p.x, 0, p.z), 0.3)
		var sel: bool = it.id == selected_id
		_sprite(n, _disc_tex(Color(0.80, 0.82, 1.0, 1.0) if sel else Color(1, 1, 1, 0.9)), 0.95, 0)
		var hide: bool = tour.get("hide_pictures", false) and it.id != tour.get("revealed", "")
		if not hide:
			var tex: Texture2D = Store.texture(it.image)
			if tex:
				var s := Sprite3D.new()
				s.texture = tex
				s.pixel_size = 0.62 / maxf(tex.get_width(), tex.get_height())
				s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				s.render_priority = 1
				n.add_child(s)
			else:
				var l := Label3D.new()
				l.text = it.icon
				l.font = SceneArt.font()
				l.font_size = 128
				l.pixel_size = 0.0042
				l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				l.render_priority = 1
				l.outline_size = 0
				n.add_child(l)
		_sprite(n, _ring_tex(k == all.size() - 1), 1.0, 2)
		var num := Label3D.new()
		num.text = str(k + 1)
		num.font = UI.font("bold")
		num.font_size = 110
		num.outline_size = 26
		num.outline_modulate = Color.WHITE
		num.modulate = UI.ACCENT
		num.pixel_size = 0.0035
		num.offset = Vector2(150, 120)
		num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		num.render_priority = 3
		num.outline_render_priority = 2
		n.add_child(num)
		match states.get(it.id, ""):
			"ok": _sprite(n, _mark_tex(true), 0.42, 4, Vector2(0.32, -0.32))
			"miss": _sprite(n, _mark_tex(false), 1.05, 4)
		var area := StaticBody3D.new()
		area.collision_layer = 2
		area.set_meta("item", it.id)
		var cs := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 0.5
		cs.shape = sp
		area.add_child(cs)
		n.add_child(area)


func _flag(n: Node3D, p: Vector3) -> void:
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.025
	cm.bottom_radius = 0.025
	cm.height = p.y - 0.55
	cm.material = _mat(Color("#8A8F94"))
	post.mesh = cm
	post.position.y = -p.y + cm.height / 2.0
	n.add_child(post)
	var kite := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.3, 0.3)
	var m := _mat(Color.WHITE)
	m.albedo_texture = _kite_tex()
	bm.material = m
	kite.mesh = bm
	kite.position = Vector3(0, -0.72, 0)
	kite.rotation_degrees = Vector3(0, 45, 0)
	n.add_child(kite)


func _sprite(n: Node3D, tex: Texture2D, meters: float, prio: int, off := Vector2.ZERO) -> void:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = meters / tex.get_width()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.render_priority = prio
	s.offset = off / s.pixel_size
	n.add_child(s)


# ---------- generated textures (signed-distance painting) ----------

static func _paint(key: String, size: int, cover: Callable) -> Texture2D:
	if not _tex.has(key):
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				var c: Color = cover.call(Vector2(x + 0.5, y + 0.5) / size * 2.0 - Vector2.ONE)
				img.set_pixel(x, y, c)
		_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]


static func _aa(d: float, px: float) -> float:
	return clampf(0.5 - d / px, 0, 1)


static func _ring_tex(finish: bool) -> Texture2D:
	return _paint("ring%s" % finish, 192, func(p: Vector2) -> Color:
		var r := p.length()
		var a := _aa(absf(r - 0.86) - 0.09, 0.012)
		if finish:
			a = maxf(_aa(absf(r - 0.62) - 0.07, 0.012), _aa(absf(r - 0.9) - 0.07, 0.012))
		return Color(UI.ACCENT, a))


static func _disc_tex(c: Color) -> Texture2D:
	return _paint("disc" + c.to_html(), 96, func(p: Vector2) -> Color:
		return Color(c, c.a * _aa(p.length() - 0.84, 0.025)))


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0, 1)
	return p.distance_to(a + (b - a) * t)


static func _mark_tex(ok: bool) -> Texture2D:
	return _paint("mark%s" % ok, 128, func(p: Vector2) -> Color:
		if ok:
			var disc := _aa(p.length() - 0.95, 0.03)
			var tick := _aa(minf(_seg_dist(p, Vector2(-0.45, 0.02), Vector2(-0.1, 0.38)), _seg_dist(p, Vector2(-0.1, 0.38), Vector2(0.48, -0.32))) - 0.12, 0.03)
			return Color(UI.SUCCESS.lerp(Color.WHITE, tick), disc)
		var x := minf(_seg_dist(p, Vector2(-0.8, -0.8), Vector2(0.8, 0.8)), _seg_dist(p, Vector2(-0.8, 0.8), Vector2(0.8, -0.8)))
		return Color(UI.DANGER, _aa(x - 0.07, 0.02)))


## BoxMesh lays its six faces out as a 3x2 atlas: split every cell on the diagonal like a control kite.
static func _kite_tex() -> Texture2D:
	return _paint("kite", 96, func(p: Vector2) -> Color:
		var q := (p + Vector2.ONE) * 0.5
		var cell := Vector2(fposmod(q.x * 3.0, 1.0), fposmod(q.y * 2.0, 1.0))
		return Color.WHITE if cell.x + cell.y < 1.0 else UI.ACCENT)


# ---------- camera ----------

func go_to_room(room: Dictionary) -> void:
	var i: int = palace.rooms.find(room)
	if i < 0:
		return
	_player.position = Vector3(i * W, 0, D / 2 - 1.1)
	_yaw = 0.0
	_pitch = -0.12
	_room_i = i
	_apply_look()


func _apply_look() -> void:
	_player.rotation.y = _yaw
	_cam.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	if _touring or not is_visible_in_tree():
		return
	var typing := get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit
	var dir := Vector3.ZERO
	if not typing:
		var k := func(a: Key, b: Key) -> float: return 1.0 if Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b) else 0.0
		dir.z = k.call(KEY_S, KEY_DOWN) - k.call(KEY_W, KEY_UP)
		dir.x = k.call(KEY_D, KEY_NONE) - k.call(KEY_A, KEY_NONE)
		var turn: float = k.call(KEY_LEFT, KEY_Q) - k.call(KEY_RIGHT, KEY_E)
		if turn != 0.0:
			_yaw += turn * 1.9 * delta
			_apply_look()
	_player.velocity = (_player.transform.basis * dir).normalized() * 3.4 if dir != Vector3.ZERO else Vector3.ZERO
	_player.move_and_slide()
	_player.position.y = 0
	var ri := clampi(roundi(_player.position.x / W), 0, palace.rooms.size() - 1)
	if ri != _room_i and not palace.rooms.is_empty():
		_room_i = ri
		room_entered.emit(palace.rooms[ri])


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				grab_focus()
				_pressing = true
				_moved = false
				_press = e.position
			else:
				_pressing = false
				if not _moved and editable and not _touring:
					_click(e.position)
		elif e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and not _touring:
			var step := -0.5 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 0.5
			_player.velocity = _player.transform.basis * Vector3(0, 0, step) * 60.0
			_player.move_and_slide()
			_player.velocity = Vector3.ZERO
	elif e is InputEventMouseMotion and _pressing and not _touring:
		if e.position.distance_to(_press) > 4:
			_moved = true
		if _moved:
			_yaw -= e.relative.x * 0.005
			_pitch = clampf(_pitch - e.relative.y * 0.004, -1.2, 1.0)
			_apply_look()
			mouse_default_cursor_shape = CURSOR_DRAG
	elif e is InputEventMouseMotion:
		mouse_default_cursor_shape = CURSOR_ARROW


func _click(pos: Vector2) -> void:
	var s := get_window().content_scale_factor
	var from := _cam.project_ray_origin(pos * s)
	var to := from + _cam.project_ray_normal(pos * s) * 60.0
	var q := PhysicsRayQueryParameters3D.create(from, to, 0b11)
	var hit := _vp.find_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var body: Object = hit.collider
	if body.has_meta("item"):
		selected_id = body.get_meta("item")
		selected.emit(selected_id)
		return
	if not body.has_meta("room"):
		return
	var i: int = body.get_meta("room")
	var room: Dictionary = palace.rooms[i]
	var n := _wall_to_norm(i * W, hit.position) if body.get_meta("kind") == "wall" else _floor_to_norm(i * W, hit.position)
	var it := Store.new_item(n.x, n.y)
	room.items.append(it)
	selected_id = it.id
	_build_course()
	added.emit(it)


# ---------- tour ----------

## Glides the camera to look at control k (index in course order). Returns the tween.
func tour_to(k: int, fast := false) -> Tween:
	_touring = true
	var all := _all()
	var i: int = all[k][0]
	var target := item_point(i, all[k][1])
	var stand := Vector3(target.x * 0.8 + i * W * 0.2, 0, clampf(target.z + 3.4, -D / 2 + 1.0, D / 2 - 0.5))
	if absf(stand.z - target.z) < 2.2:
		stand.x += 1.8 if target.x <= i * W else -1.8
	var pts := _route(_player.position, clampi(roundi(_player.position.x / W), 0, palace.rooms.size() - 1), stand, i)
	var look := target - (stand + Vector3(0, EYE, 0))
	var yaw := atan2(-look.x, -look.z)
	var pitch := atan2(look.y, Vector2(look.x, look.z).length())
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for j in range(1, pts.size()):
		var seg: float = pts[j - 1].distance_to(pts[j])
		var p: Vector3 = pts[j]
		p.y = 0
		tw.tween_property(_player, "position", p, 0.05 if fast else clampf(seg / 4.5, 0.25, 1.4))
	tw.parallel().tween_method(func(v: float):
		_yaw = lerp_angle(_yaw, yaw, v)
		_pitch = lerpf(_pitch, pitch, v)
		_apply_look(), 0.0, 1.0, 0.05 if fast else 0.6)
	var ri := i
	tw.tween_callback(func():
		_yaw = yaw
		_pitch = pitch
		_apply_look()
		if ri != _room_i:
			_room_i = ri
			room_entered.emit(palace.rooms[ri]))
	return tw


func set_tour(opts: Dictionary) -> void:
	tour = opts
	_touring = true
	if _course:
		_build_course()
		_build_controls()
