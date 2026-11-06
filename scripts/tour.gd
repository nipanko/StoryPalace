class_name Tour
extends Control
## Running the course (guided walk) and the punch test (recall, self-graded), in 2D or 3D.

signal closed

var palace: Dictionary
var mode := "run"            # "run" | "test"
var view := "2d"
var _start_room: Dictionary
var _list := []              # [{room, room_i, item, num}]
var _k := -1
var _states := {}            # item id -> "ok" | "miss"
var _revealed := false
var _hide := false
var _retest := false
var _t0 := 0.0

var _map: MapView
var _world: PalaceWorld
var _holder: Control
var _card: VBoxContainer
var _progress: Label
var _punch: HBoxContainer
var _title: Label


func setup(p: Dictionary, m: String, v: String, start_room: Dictionary) -> void:
	palace = p
	mode = m
	view = v
	_start_room = start_room


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = UI.PAPER
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var root := UI.vbox(0)
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(root)

	var bar := PanelContainer.new()
	var sb := UI.box(UI.PAPER, UI.INK, 0, 0, Vector4(12, 10, 20, 10))
	sb.border_width_bottom = UI.RULE
	bar.add_theme_stylebox_override(&"panel", sb)
	var row := UI.hbox(14)
	bar.add_child(row)
	var close := UI.icon_button("x", "Back to editing  (Esc)")
	close.pressed.connect(_close)
	row.add_child(close)
	_title = UI.label("", "Display")
	_title.add_theme_font_size_override(&"font_size", 30)
	row.add_child(_title)
	row.add_child(UI.label(palace.name, "Muted"))
	row.add_child(UI.spacer())
	_punch = UI.hbox(4)
	row.add_child(_punch)
	_progress = UI.label("", "H3")
	row.add_child(_progress)
	root.add_child(bar)

	var body := UI.hbox(24)
	body.size_flags_vertical = SIZE_EXPAND_FILL
	var m := UI.margin(body, 20, 16, 24, 20)
	m.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(m)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Frame"
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(frame)
	_holder = Control.new()
	_holder.clip_contents = true
	frame.add_child(_holder)
	_card = UI.vbox(16)
	_card.custom_minimum_size.x = 420
	body.add_child(_card)

	if view == "3d":
		_world = PalaceWorld.new()
		_world.palace = palace
		_world.editable = false
		_world.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_holder.add_child(_world)
	else:
		_map = MapView.new()
		_map.palace = palace
		_map.editable = false
		_map.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_holder.add_child(_map)
	_begin(mode, false)


func _begin(m: String, retest: bool) -> void:
	mode = m
	_retest = retest
	_title.text = "Run the course" if mode == "run" else "Punch test"
	var missed := _states.keys().filter(func(id): return _states[id] == "miss")
	_list.clear()
	var num := 1
	for i in palace.rooms.size():
		for it in palace.rooms[i].items:
			if not retest or it.id in missed:
				_list.append({"room": palace.rooms[i], "room_i": i, "item": it, "num": num})
			num += 1
	if not retest:
		_states.clear()
	else:
		for id in missed:
			_states.erase(id)
	_k = -1
	_revealed = false
	_build_punch_card()
	_apply_view_options(0)
	if _map:
		_map.room = palace.rooms[0] if _list.is_empty() else _list[0].room
		_map.zoom = 1.0
		_map.focus = Vector2(0.5, 0.5)
	if _world:
		_world.go_to_room(palace.rooms[0] if _list.is_empty() else _list[0].room)
		_world.set_tour({"reveal": 0})
	if mode == "test":
		_intro_card()
	else:
		_t0 = Time.get_ticks_msec()
		_go(0)


# ---------- moving along ----------

func _apply_view_options(reveal_upto: int) -> void:
	var opts := {"states": _states, "hide_pictures": _hide and mode == "test", "revealed": _cur().item.id if _revealed and _k >= 0 else ""}
	if _map and _k >= 0:
		var cur := _cur()
		var count := 0
		for e in _list.slice(0, _k + 1):
			if e.room == cur.room:
				count += 1
		var idx: int = cur.room.items.find(cur.item) + 1
		opts.reveal = idx if not _retest else cur.room.items.size()
		opts.show_all = _retest
		opts.leg_progress = 1.0
		_map.tour = opts
	if _world:
		opts.reveal = reveal_upto
		opts.show_all = _retest
		_world.set_tour(opts)


func _cur() -> Dictionary:
	return _list[clampi(_k, 0, _list.size() - 1)]


func _go(k: int) -> void:
	if k >= _list.size():
		_finish()
		return
	k = maxi(k, 0)
	var forward := k > _k
	_k = k
	_revealed = mode == "run"
	var cur := _cur()
	_progress.text = "Control %d of %d" % [k + 1, _list.size()] if not _retest else "Retest %d of %d" % [k + 1, _list.size()]
	var global_index: int = cur.num - 1
	_apply_view_options(global_index + 1)
	if _map:
		var room_changed: bool = _map.room != cur.room
		if room_changed:
			_map.room = cur.room
			_map.modulate.a = 0.0
			_map.create_tween().tween_property(_map, "modulate:a", 1.0, 0.25)
		var tw := _map.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_map, "zoom", 1.35, 0.45)
		tw.parallel().tween_property(_map, "focus", Vector2(cur.item.x, cur.item.y), 0.55)
		if forward and not _retest:
			# the signature move: the leg draws itself toward the control
			tw.parallel().tween_method(func(v: float): _map.tour.leg_progress = v; _map.queue_redraw(), 0.0, 1.0, 0.6)
	if _world:
		_world.tour_to(global_index)
	_control_card()


func _reveal() -> void:
	_revealed = true
	_apply_view_options(_cur().num)
	_control_card()


func _grade(ok: bool) -> void:
	_states[_cur().item.id] = "ok" if ok else "miss"
	_apply_view_options(_cur().num)
	_build_punch_card()
	_go(_k + 1)


# ---------- cards ----------

func _clear_card() -> void:
	for c in _card.get_children():
		_card.remove_child(c)
		c.queue_free()


func _intro_card() -> void:
	_clear_card()
	_progress.text = "%d controls" % _list.size()
	_card.add_child(UI.label("Punch test", "Display"))
	_card.add_child(UI.label("Walk your course and try to recall what waits at every control before you look. Be honest: it is only for you.", "Body", true))
	var hide := CheckBox.new()
	hide.text = "Hide the pictures too (harder: recall from the place alone)"
	hide.button_pressed = _hide
	hide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hide.toggled.connect(func(v): _hide = v)
	_card.add_child(hide)
	var start := UI.button("Start the test", "play", "PrimaryButton")
	start.size_flags_horizontal = SIZE_SHRINK_BEGIN
	start.pressed.connect(func(): _t0 = Time.get_ticks_msec(); _go(0))
	_card.add_child(start)
	_card.add_child(UI.label("Keys: Space shows the answer, 1 = missed it, 2 = got it, Esc leaves.", "Muted", true))
	UI.focus_later(start)


func _control_card() -> void:
	_clear_card()
	var cur := _cur()
	var it: Dictionary = cur.item
	var head := UI.hbox(16)
	var big := _Big.new()
	big.item = it
	big.num = cur.num
	big.finish = cur.num == Store.count_items(palace)
	big.hide_picture = _hide and mode == "test" and not _revealed
	head.add_child(big)
	var where := UI.vbox(2)
	where.size_flags_horizontal = SIZE_EXPAND_FILL
	where.add_child(UI.label(("Control %d" % cur.num).to_upper(), "Caps"))
	where.add_child(UI.label(cur.room.name, "H3"))
	head.add_child(where)
	_card.add_child(head)

	if _revealed:
		var t := UI.label(it.title if it.title != "" else "(nothing written here yet)", "Display", true)
		_card.add_child(t)
		if it.story != "":
			_card.add_child(UI.label(it.story, "Body", true))
	else:
		_card.add_child(UI.label("What is waiting here?", "Display", true))
		_card.add_child(UI.label("Picture the spot, then say it out loud or in your head.", "Muted", true))
	_card.add_child(UI.spacer())
	var row := UI.hbox(10)
	_card.add_child(row)
	if mode == "run":
		var back := UI.button("Back", "chevron-left", "Button", "Left arrow")
		back.disabled = _k == 0
		back.pressed.connect(func(): _go(_k - 1))
		row.add_child(back)
		var last := _k == _list.size() - 1
		var next := UI.button("Finish" if last else "Next control", "chevron-right", "PrimaryButton", "Right arrow or Space")
		next.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		next.size_flags_horizontal = SIZE_EXPAND_FILL
		next.pressed.connect(func(): _go(_k + 1))
		row.add_child(next)
		UI.focus_later(next)
		_card.add_child(UI.label("← →  or Space to move along  ·  Esc to stop", "Muted"))
	elif not _revealed:
		var show := UI.button("Show the answer", "eye", "PrimaryButton", "Space")
		show.size_flags_horizontal = SIZE_EXPAND_FILL
		show.pressed.connect(_reveal)
		row.add_child(show)
		UI.focus_later(show)
		_card.add_child(UI.label("Space to show the answer", "Muted"))
	else:
		var miss := UI.button("Missed it", "x", "Button", "Key 1")
		miss.size_flags_horizontal = SIZE_EXPAND_FILL
		miss.pressed.connect(func(): _grade(false))
		var ok := UI.button("Got it", "check", "PrimaryButton", "Key 2")
		ok.size_flags_horizontal = SIZE_EXPAND_FILL
		ok.pressed.connect(func(): _grade(true))
		row.add_child(miss)
		row.add_child(ok)
		UI.focus_later(ok)
		_card.add_child(UI.label("1 = missed it  ·  2 = got it", "Muted"))


func _finish() -> void:
	_clear_card()
	if _map:
		var tw := _map.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_map, "zoom", 1.0, 0.45)
		_map.tour.leg_progress = 1.0
	var secs := int((Time.get_ticks_msec() - _t0) / 1000.0)
	var took := "%d min %d s" % [secs / 60, secs % 60] if secs >= 60 else "%d s" % secs
	_progress.text = "Finished in %s" % took
	if mode == "run":
		_card.add_child(UI.label("Course complete", "Display"))
		_card.add_child(UI.label("You visited all %d controls. Run it again later today and tomorrow to make it stick, or test yourself now." % _list.size(), "Body", true))
		_card.add_child(_buttons([["Take the punch test", "check", "PrimaryButton", func(): _begin("test", false)],
			["Run it again", "rotate-ccw", "Button", func(): _begin("run", false)], ["Back to editing", "arrow-left", "FlatButton", _close]]))
		return
	var got := _states.values().count("ok")
	var total := _states.size()
	if not _retest:
		var all_ok := _list.size()
		palace.practiced = Time.get_unix_time_from_system()
		palace.score = int(round(100.0 * got / maxf(1, all_ok)))
	for e in _list:
		e.item.recall = _states.get(e.item.id, "")
	Store.mark_dirty(palace)
	_card.add_child(UI.label("%d of %d punched" % [got, total], "Display"))
	var missed := _list.filter(func(e): return _states.get(e.item.id) == "miss")
	if missed.is_empty():
		_card.add_child(UI.label("A clean run: every control remembered. Test again in a few days to keep it fresh.", "Body", true))
	else:
		_card.add_child(UI.label("Walk these again and make their pictures stranger or bigger:", "Body", true))
		for e in missed.slice(0, 6):
			var r := UI.hbox(10)
			var n := UI.label(str(e.num), "Numeral")
			n.add_theme_font_size_override(&"font_size", 24)
			n.custom_minimum_size.x = 32
			r.add_child(n)
			var t := UI.label("%s  %s" % [e.item.icon, e.item.title if e.item.title != "" else "(untitled)"], "H3")
			t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			t.size_flags_horizontal = SIZE_EXPAND_FILL
			r.add_child(t)
			_card.add_child(r)
	var btns := []
	if not missed.is_empty():
		btns.append(["Retest the %d missed" % missed.size(), "rotate-ccw", "PrimaryButton", func(): _begin("test", true)])
	btns.append(["Run the course", "play", "Button" if not missed.is_empty() else "PrimaryButton", func(): _begin("run", false)])
	btns.append(["Done", "check", "FlatButton", _close])
	_card.add_child(UI.spacer())
	_card.add_child(_buttons(btns))


func _buttons(list: Array) -> Control:
	var col := UI.vbox(8)
	for b in list:
		var btn := UI.button(b[0], b[1], b[2])
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(b[3])
		col.add_child(btn)
	UI.focus_later(col.get_child(0))
	return col


func _build_punch_card() -> void:
	for c in _punch.get_children():
		_punch.remove_child(c)
		c.queue_free()
	if mode != "test" or _list.size() > 30:
		return
	for e in _list:
		var s: String = _states.get(e.item.id, "")
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(28, 28)
		box.tooltip_text = "Control %d" % e.num
		var st := UI.box(UI.PAPER if s == "" else (UI.GREEN_TEXT if s == "ok" else UI.PAPER), UI.INK if s != "miss" else UI.RED, 1, 2, Vector4.ZERO)
		box.add_theme_stylebox_override(&"panel", st)
		var l := UI.label(str(e.num) if s == "" else ("✓" if s == "ok" else "✗"), "Caps")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override(&"font_color", UI.MUTED if s == "" else (UI.PAPER if s == "ok" else UI.RED))
		box.add_child(l)
		_punch.add_child(box)


func _close() -> void:
	closed.emit()


func _input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var done := _k < 0 or _k >= _list.size() or _list.is_empty() or _progress.text.begins_with("Finished")
	if done and e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		return  # the focused button on the intro or result card takes these
	accept_event()  # the editor underneath must not see keys while the course runs
	match e.keycode:
		KEY_ESCAPE:
			_close()
		KEY_RIGHT, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if done:
				return
			if mode == "run":
				_go(_k + 1)
			elif not _revealed:
				_reveal()
		KEY_LEFT:
			if mode == "run" and _k > 0:
				_go(_k - 1)
		KEY_1, KEY_KP_1:
			if mode == "test" and _revealed and _k >= 0:
				_grade(false)
		KEY_2, KEY_KP_2:
			if mode == "test" and _revealed and _k >= 0:
				_grade(true)


class _Big extends Control:
	## The current control drawn large on the card.
	var item: Dictionary
	var num := 1
	var finish := false
	var hide_picture := false

	func _ready() -> void:
		custom_minimum_size = Vector2(132, 132)

	func _draw() -> void:
		Course.draw_control(self, size * 0.5 + Vector2(-8, 6), 46, num, item, {"finish": finish, "hide_picture": hide_picture, "show_number": false})
