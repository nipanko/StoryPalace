extends Node
## Palaces on disk: one JSON file per palace in user://palaces, pictures in user://images.

signal changed(palace_id: String)

const PALACE_DIR := "user://palaces/"
const IMAGE_DIR := "user://images/"
const EXPORT_VERSION := 1

var palaces: Array = []          # Array of Dictionary, newest first
var settings := {"view": "2d", "seen_intro": false}
var _dirty := {}                 # palace id -> true, flushed by _save_timer
var _save_timer := Timer.new()
var _textures := {}              # image file -> Texture2D cache


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(PALACE_DIR)
	DirAccess.make_dir_recursive_absolute(IMAGE_DIR)
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.4
	_save_timer.timeout.connect(flush)
	add_child(_save_timer)
	_load_settings()
	_load_all()
	if palaces.is_empty():
		palaces.append(Sample.planets())
		mark_dirty(palaces[0])
		flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		flush()


# ---------- ids & lookup ----------

static func new_id(prefix: String) -> String:
	return "%s%x%04x" % [prefix, int(Time.get_unix_time_from_system() * 1000.0), randi() % 0xffff]


func get_palace(id: String) -> Dictionary:
	for p in palaces:
		if p.id == id:
			return p
	return {}


## Every memory in walking order: rooms in order, items in order inside each room.
static func stations(palace: Dictionary) -> Array:
	var out := []
	for r in palace.rooms:
		for it in r.items:
			out.append({"room": r, "item": it})
	return out


static func count_items(palace: Dictionary) -> int:
	var n := 0
	for r in palace.rooms:
		n += r.items.size()
	return n


# ---------- create ----------

func create_palace(name: String) -> Dictionary:
	var p := {
		"id": new_id("p"), "name": name, "created": Time.get_unix_time_from_system(),
		"practiced": 0.0, "score": -1, "rooms": [],
	}
	p.rooms.append(new_room("Living Room", "living"))
	palaces.push_front(p)
	mark_dirty(p)
	return p


static func new_room(name: String, theme: String, photo := "") -> Dictionary:
	return {"id": new_id("r"), "name": name, "theme": theme, "photo": photo, "items": []}


static func new_item(x: float, y: float) -> Dictionary:
	return {"id": new_id("m"), "x": x, "y": y, "icon": "⭐", "image": "", "title": "", "story": "", "recall": ""}


func delete_palace(p: Dictionary) -> void:
	palaces.erase(p)
	DirAccess.remove_absolute(PALACE_DIR + p.id + ".json")
	changed.emit(p.id)


func duplicate_palace(p: Dictionary) -> Dictionary:
	var c: Dictionary = p.duplicate(true)
	c.id = new_id("p")
	c.name = p.name + " (copy)"
	for r in c.rooms:
		r.id = new_id("r")
		for it in r.items:
			it.id = new_id("m")
	palaces.push_front(c)
	mark_dirty(c)
	return c


# ---------- saving ----------

func mark_dirty(p: Dictionary) -> void:
	_dirty[p.id] = true
	_save_timer.start()
	changed.emit(p.id)


func flush() -> void:
	for id in _dirty.keys():
		var p := get_palace(id)
		if not p.is_empty():
			_write_atomic(PALACE_DIR + id + ".json", JSON.stringify(p, "\t"))
	_dirty.clear()


## Write to a temp file first so a crash mid-write never destroys the old palace.
static func _write_atomic(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s: %s" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK


func _load_all() -> void:
	palaces.clear()
	for file in DirAccess.get_files_at(PALACE_DIR):
		if not file.ends_with(".json"):
			continue
		var p = _read_json(PALACE_DIR + file)
		if p is Dictionary and p.has("rooms"):
			palaces.append(_normalize(p))
	palaces.sort_custom(func(a, b): return a.created > b.created)


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Fill in keys older or hand-edited files may lack, so the UI never trips on them.
static func _normalize(p: Dictionary) -> Dictionary:
	for k in ["name", "created", "practiced", "score"]:
		if not p.has(k):
			p[k] = {"name": "Untitled palace", "created": 0.0, "practiced": 0.0, "score": -1}[k]
	if not p.has("id"):
		p.id = new_id("p")
	for k in ["created", "practiced", "score"]:
		if typeof(p[k]) not in [TYPE_FLOAT, TYPE_INT]:
			p[k] = 0.0 if k != "score" else -1
	p.rooms = p.rooms.filter(func(r): return r is Dictionary) if p.get("rooms") is Array else []
	if p.rooms.is_empty():
		p.rooms.append(new_room("Living Room", "living"))
	for r in p.rooms:
		if not r.get("items") is Array:
			r.items = []
		for k in ["name", "theme", "photo"]:
			if not r.has(k):
				r[k] = {"name": "Room", "theme": "living", "photo": ""}[k]
		if not r.has("id"):
			r.id = new_id("r")
		if not r.has("items"):
			r.items = []
		var clean := []
		for it in r.items:
			if not it is Dictionary:
				continue
			var d := new_item(0.5, 0.5)
			for k in d:
				if not it.has(k):
					it[k] = d[k]
			# files can come from anyone: force every field to the type the app draws
			it.x = clampf(float(it.x), 0.0, 1.0) if typeof(it.x) in [TYPE_FLOAT, TYPE_INT] else 0.5
			it.y = clampf(float(it.y), 0.0, 1.0) if typeof(it.y) in [TYPE_FLOAT, TYPE_INT] else 0.5
			for k in ["id", "icon", "image", "title", "story", "recall"]:
				it[k] = str(it[k])
			clean.append(it)
		r.items = clean
		for k in ["id", "name", "theme", "photo"]:
			r[k] = str(r[k])
	p.name = str(p.name)
	return p


func _load_settings() -> void:
	var s = _read_json("user://settings.json")
	if s is Dictionary:
		settings.merge(s, true)


func save_settings() -> void:
	_write_atomic("user://settings.json", JSON.stringify(settings))


# ---------- pictures ----------

## Copies a picture into the app, downscaled so palaces stay small. Returns the stored file name or "".
func import_image(path: String, max_side: int) -> String:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return ""
	var s := float(max_side) / maxf(img.get_width(), img.get_height())
	if s < 1.0:
		img.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
	var has_alpha := img.detect_alpha() != Image.ALPHA_NONE
	var name := new_id("i") + (".png" if has_alpha else ".jpg")
	var err := img.save_png(IMAGE_DIR + name) if has_alpha else img.save_jpg(IMAGE_DIR + name, 0.88)
	return name if err == OK else ""


func texture(name: String) -> Texture2D:
	if name == "":
		return null
	if not _textures.has(name):
		var img := Image.load_from_file(IMAGE_DIR + name)
		_textures[name] = ImageTexture.create_from_image(img) if img and not img.is_empty() else null
	return _textures[name]


# ---------- export / import ----------

func export_palace(p: Dictionary, path: String) -> bool:
	var images := {}
	for r in p.rooms:
		for name in [r.photo] + r.items.map(func(it): return it.image):
			if name != "" and FileAccess.file_exists(IMAGE_DIR + name):
				images[name] = Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(IMAGE_DIR + name))
	var doc := {"format": "memory-palace", "version": EXPORT_VERSION, "palace": p, "images": images}
	return _write_atomic(path, JSON.stringify(doc))


## Returns the imported palace, or {} when the file is not a palace export.
func import_palace(path: String) -> Dictionary:
	var doc = _read_json(path)
	if not (doc is Dictionary and doc.get("format") == "memory-palace" and doc.get("palace") is Dictionary):
		return {}
	var renamed := {}
	for name in doc.get("images", {}):
		var ext: String = name.get_extension().to_lower()
		if ext not in ["png", "jpg", "jpeg", "webp"]:
			continue  # only plain pictures leave an untrusted file
		var fresh := new_id("i") + "." + ext
		var f := FileAccess.open(IMAGE_DIR + fresh, FileAccess.WRITE)
		if f:
			f.store_buffer(Marshalls.base64_to_raw(str(doc.images[name])))
			renamed[name] = fresh
	var p := _normalize(doc.palace)
	p.id = new_id("p")
	p.created = Time.get_unix_time_from_system()
	for r in p.rooms:
		r.id = new_id("r")
		r.photo = renamed.get(r.photo, "")
		for it in r.items:
			it.id = new_id("m")
			it.image = renamed.get(it.image, "")
	palaces.push_front(p)
	mark_dirty(p)
	return p
