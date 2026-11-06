extends Node
## Self-check: drives every screen and saves screenshots, then quits.
## Run: Godot --path . --resolution 1440x900 -- --windowed --scale=1 --shots=<dir>
## Add --headless before -- to run only the checks, without a window.

var dir := ""
var main: Node


func _ready() -> void:
	main = get_parent()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.trim_prefix("--shots=")
	_run.call_deferred()


func _shot(name: String, wait := 0.7) -> void:
	await get_tree().create_timer(wait).timeout
	await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		return  # logic checks only; nothing is drawn
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("shot ", name)


func _screen() -> Node:
	return main._screen


var failures := 0


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		failures += 1


func _click(at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	e.global_position = at
	get_viewport().push_input(e)


func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(e)


## Real input through the viewport: add a control by clicking, drag it, name it, export and re-import.
func _interaction_checks(ed: PalaceScreen, p: Dictionary) -> void:
	var map: MapView = ed._map
	var room: Dictionary = ed.room
	var before: int = room.items.size()
	var rect := map.scene_rect()
	var spot := map.get_global_rect().position + rect.position + rect.size * Vector2(0.6, 0.75)
	_move(spot)
	_click(spot, true)
	_click(spot, false)
	await get_tree().process_frame
	_check(room.items.size() == before + 1, "click on empty map adds a control")
	var it: Dictionary = room.items[-1]
	_check(ed.selected_id == it.id, "new control is selected")
	var to := spot + Vector2(-120, -40)
	_click(spot, true)
	for k in 6:
		_move(spot.lerp(to, (k + 1) / 6.0))
	_click(to, false)
	await get_tree().process_frame
	_check(absf(it.x - (0.6 - 120.0 / rect.size.x)) < 0.02, "dragging moves the control")
	await get_tree().process_frame
	var field: LineEdit = ed._table.find_child("TitleField", true, false)
	_check(field != null, "editor row opens for the new control")
	if field:
		field.text = "red apple"
		field.text_changed.emit("red apple")
		_check(it.title == "red apple" and it.icon == "🍎", "typing a title names it and suggests a picture (%s)" % it.icon)
	ed._remove(it.id)
	_check(room.items.size() == before, "remove deletes it")
	ed._do_undo()
	_check(room.items.size() == before + 1, "undo brings it back")
	ed._remove(it.id)
	var path := OS.get_user_data_dir().path_join("roundtrip.palace")
	_check(Store.export_palace(p, path), "export writes a file")
	var n := Store.palaces.size()
	var q := Store.import_palace(path)
	_check(Store.palaces.size() == n + 1 and Store.count_items(q) == Store.count_items(p) and q.id != p.id, "import restores every control under a new id")
	_check(Store.import_palace(OS.get_user_data_dir().path_join("settings.json")).is_empty(), "import rejects a file that is not a palace")
	Store.delete_palace(q)
	DirAccess.remove_absolute(path)


func _run() -> void:
	await _shot("01_home")
	var p: Dictionary = Store.palaces[0]
	main.open_palace(p)
	await _shot("02_editor")
	var ed: PalaceScreen = _screen()
	ed._select(p.rooms[1].items[1].id)
	await _shot("03_editor_selected")
	await _interaction_checks(ed, p)
	ed._set_view("3d")
	await _shot("04_editor_3d", 2.0)
	ed._set_view("2d")
	main._run(ed, p, "run")
	await _shot("05_run_first", 1.2)
	var t: Tour = main.get_child(main.get_child_count() - 1)
	t._go(3)
	await _shot("06_run_mid", 1.2)
	t._go(t._list.size())
	await _shot("07_run_done")
	t._begin("test", false)
	await _shot("08_test_intro")
	t._go(0)
	await _shot("09_test_hidden", 1.0)
	t._reveal()
	await _shot("10_test_revealed")
	for i in t._list.size():
		if t._k >= t._list.size():
			break
		t._reveal()
		t._grade(i % 3 != 1)
	await _shot("11_test_done")
	t._close()
	await get_tree().process_frame
	ed._set_view("3d")
	main._run(ed, p, "run")
	await _shot("12_run_3d", 2.5)
	t = main.get_child(main.get_child_count() - 1)
	t._go(4)
	await _shot("13_run_3d_next", 2.5)
	t._close()
	await get_tree().process_frame
	ed._set_view("2d")
	Pickers.room(ed, "Add a room", func(_c): pass)
	await _shot("14_room_picker")
	for c in ed.get_children():
		if c is PopupPanel:
			c.hide()
	Pickers.picture(ed, "Saturn — planet 6", func(_c): pass)
	await _shot("15_picture_picker")
	print("self-check: %s" % ("all passed" if failures == 0 else "%d failed" % failures))
	get_tree().quit(1 if failures else 0)
