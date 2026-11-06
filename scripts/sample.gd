class_name Sample
## The palace every new user starts with: the eight planets, walked through a house.


static func _m(icon: String, title: String, story: String, x: float, y: float) -> Dictionary:
	var it := Store.new_item(x, y)
	it.icon = icon
	it.title = title
	it.story = story
	return it


static func planets() -> Dictionary:
	var hall := Store.new_room("Front Door", "hallway")
	hall.items = [
		_m("🌡️", "Mercury — planet 1", "A giant thermometer lies on the doormat, its silver mercury boiling over because it sits closest to the sun.", 0.52, 0.86),
		_m("💄", "Venus — planet 2", "Venus, goddess of beauty, has scribbled bright lipstick all over the hall mirror.", 0.2, 0.32),
	]
	var living := Store.new_room("Living Room", "living")
	living.items = [
		_m("🌍", "Earth — planet 3", "A huge blue globe bounces on the sofa cushions. Home sweet home.", 0.47, 0.5),
		_m("🍫", "Mars — planet 4", "A Mars bar melts across the rug and the chocolate turns rusty red.", 0.3, 0.84),
		_m("⚡", "Jupiter — planet 5", "Jupiter, king of the gods, fires lightning out of the TV. It is the biggest planet, so the bolt is enormous.", 0.83, 0.42),
	]
	var kitchen := Store.new_room("Kitchen", "kitchen")
	kitchen.items = [
		_m("💍", "Saturn — planet 6", "A ring so large it circles the whole teapot, just like Saturn's rings.", 0.3, 0.4),
		_m("🧊", "Uranus — planet 7", "An ice giant: a block of ice tipped on its side, spinning in the pan.", 0.62, 0.42),
		_m("🔱", "Neptune — planet 8", "Neptune's trident is stuck in the laundry basket, dripping sea water.", 0.84, 0.8),
	]
	return {
		"id": Store.new_id("p"), "name": "The 8 Planets", "created": Time.get_unix_time_from_system(),
		"practiced": 0.0, "score": -1, "rooms": [hall, living, kitchen],
	}
