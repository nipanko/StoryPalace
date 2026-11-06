extends Control
## App root: theme, screen scale, and switching between home, editor and the course run.

var _screen: Control


func _ready() -> void:
	_fit_window()
	get_tree().root.theme = UI.build_theme()
	var bg := ColorRect.new()
	bg.color = UI.GROUND
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	show_home()
	if Array(OS.get_cmdline_user_args()).any(func(a): return a.begins_with("--shots=")):
		add_child(load("res://scripts/shots.gd").new())


## Godot does not scale UI with the OS display setting on Windows, so match it ourselves.
func _fit_window() -> void:
	var w := get_window()
	var screen := w.current_screen
	var scale := DisplayServer.screen_get_scale(screen) if OS.get_name() == "macOS" else DisplayServer.screen_get_dpi(screen) / 96.0
	scale = clampf(snappedf(scale, 0.25), 1.0, 3.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scale="):
			scale = a.trim_prefix("--scale=").to_float()
	w.content_scale_factor = scale
	w.min_size = Vector2i(Vector2(1024, 680) * scale)
	w.title = "StoryPalace"
	if "--windowed" not in OS.get_cmdline_user_args():
		w.mode = Window.MODE_MAXIMIZED


func _swap(s: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = s
	add_child(s)
	UI.pop_in(s, 0.0, 0.985)


func show_home() -> void:
	Store.flush()
	var h := Home.new()
	h.open_requested.connect(open_palace)
	_swap(h)


func open_palace(p: Dictionary) -> void:
	var s := PalaceScreen.new()
	s.setup(p)
	s.back_requested.connect(show_home)
	s.run_requested.connect(func(mode): _run(s, p, mode))
	_swap(s)


func _run(editor: PalaceScreen, p: Dictionary, mode: String) -> void:
	if Store.count_items(p) == 0:
		UI.toast(editor, "Add a control first: click anywhere on the map.")
		return
	var t := Tour.new()
	t.setup(p, mode, Store.settings.get("view", "2d"), editor.room)
	editor.visible = false   # its 3D view and shortcuts stay idle under the run
	t.closed.connect(func():
		t.queue_free()
		if is_instance_valid(editor):
			editor.visible = true
			editor._redraw_view()
			editor._refresh_all())
	add_child(t)
