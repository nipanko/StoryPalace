class_name Emoji
## Unicode emoji list (groups of [char, "name | subgroup"]) with search and suggestions.

static var groups: Array = []


static func data() -> Array:
	if groups.is_empty():
		groups = load("res://data/emoji.json").data.duplicate(true)
		if OS.get_name() == "Windows":
			# Windows has no country or regional flag glyphs; they would show as letters
			for g in groups:
				g[1] = g[1].filter(func(e): var c: int = e[0].unicode_at(0); return not (c >= 0x1F1E6 and c <= 0x1F1FF) and e[0].unicode_at(1 if e[0].length() > 1 else 0) != 0xE0067)
			groups = groups.filter(func(g): return not g[1].is_empty())
	return groups


## Emoji whose names contain every word of the query, best (word-start) matches first.
static func search(query: String, limit := 120) -> Array:
	var words := query.to_lower().strip_edges().split(" ", false)
	if words.is_empty():
		return []
	var exact := []
	var best := []
	var rest := []
	for g in data():
		for e in g[1]:
			var name: String = e[1]
			var ok := true
			var starts := false
			var whole := false
			for w in words:
				var at := name.find(w)
				if at < 0:
					ok = false
					break
				if at == 0 or name[at - 1] == " ":
					starts = true
					var end := at + w.length()
					whole = whole or end >= name.length() or name[end] in [" ", ":", ","]
			if ok:
				(exact if whole else (best if starts else rest)).append(e[0])
	return (exact + best + rest).slice(0, limit)


## Picture ideas for a phrase like "Mars — planet 4": tries each word, longest first.
static func suggest(text: String, limit := 6) -> Array:
	var words := []
	for w in text.to_lower().replace("—", " ").replace("-", " ").replace(",", " ").split(" ", false):
		if w.length() >= 3 and not w.is_valid_int() and w not in ["the", "and", "for", "with"]:
			words.append(w)
	words.sort_custom(func(a, b): return a.length() > b.length())
	var out := []
	for w in words:
		for e in search(w, limit):
			if e not in out:
				out.append(e)
		if out.size() >= limit:
			break
	return out.slice(0, limit)
