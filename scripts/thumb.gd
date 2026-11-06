class_name Thumb
extends Control
## A small drawn room (optionally with its course) for tiles and pickers.

var room: Dictionary
var palace: Dictionary   # set to draw the course of `room`


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)


func _draw() -> void:
	if room.is_empty():
		return
	var rect := Rect2(Vector2.ZERO, size)
	SceneArt.draw_room(self, rect, room)
	if not palace.is_empty():
		var n := 1
		for r in palace.rooms:
			if r == room:
				break
			n += r.items.size()
		Course.draw_room_course(self, rect, room, n, Store.count_items(palace), clampf(size.y * 0.06, 8, 18))
