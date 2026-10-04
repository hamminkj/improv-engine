extends Node
## Holds the settings, the show-in-progress, and all of the simulation rules.
## Stats arrays everywhere use this order: [chaos, energy, heart, coherence].

const SETTINGS_PATH := "user://improv_settings.json"
const LENGTH_MULT := [0.6, 1.0, 1.5]
const LENGTH_NAMES := ["Short", "Standard", "Long"]
const INTENSITY_NAMES := ["Gentle", "Standard", "Wild"]
const CHAOS_LIMIT := [6, 10, 99]
const CONSTRAINT_CHANCE := [0.3, 0.55, 0.85]
const AUTO_TWIST_COUNT := [1, 2, 3]

var settings: Dictionary = {}
var players: Array = []
var rng := RandomNumberGenerator.new()
var stats: Dictionary = {}
var scenes: Array = []
var facts: Array = []
var theme_word: String = ""
var scene_index: int = 0
var total_scenes: int = 0
var beat_ends: Array = []
var current: Dictionary = {}
var cast_counts: Dictionary = {}
var fixed_pair: Array = []
var beat_rule: String = ""
var format: Dictionary = {}
var used: Dictionary = {}
var used_twists: Array = []


func _ready() -> void:
	settings = default_settings()
	load_settings()


func default_settings() -> Dictionary:
	return {
		"players": ["", "", "", ""],
		"format_id": "harold",
		"length": 1,
		"intensity": 1,
		"kinds": {"physical": true, "narrative": true, "time": true, "meta": true, "audience": true},
		"auto_twists": true,
		"show_timer": true,
		"seed": "",
	}


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		for k in data:
			settings[k] = data[k]
		settings["length"] = clampi(int(settings.get("length", 1)), 0, 2)
		settings["intensity"] = clampi(int(settings.get("intensity", 1)), 0, 2)
		var defaults := default_settings()
		for kind in Content.KINDS:
			if not settings["kinds"].has(kind):
				settings["kinds"][kind] = defaults["kinds"][kind]


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings))


func get_format(id: String) -> Dictionary:
	for f in Content.FORMATS:
		if f["id"] == id:
			return f
	return Content.FORMATS[0]


func length_mult() -> float:
	return LENGTH_MULT[clampi(int(settings.get("length", 1)), 0, 2)]


func scene_seconds(fmt: Dictionary) -> int:
	return int(round(float(fmt["scene_sec"]) * length_mult()))


func estimate_minutes(fmt: Dictionary) -> float:
	var scenes_n := 0
	for b in fmt["beats"]:
		scenes_n += int(b)
	var secs := 90.0
	secs += scenes_n * (scene_seconds(fmt) + 45)
	secs += (fmt["beats"].size() - 1) * 60
	if fmt["monologue"]:
		secs += fmt["beats"].size() * 75
	return secs / 60.0


func new_show() -> void:
	format = get_format(str(settings.get("format_id", "harold")))
	players = []
	for p in settings["players"]:
		var n := str(p).strip_edges()
		if n != "":
			players.append(n)
	var seed_text := str(settings.get("seed", "")).strip_edges()
	if seed_text != "":
		rng.seed = hash(seed_text)
	else:
		rng.randomize()
	stats = {"energy": 50.0, "chaos": 30.0, "heart": 40.0, "coherence": 70.0}
	scenes = []
	facts = []
	theme_word = ""
	scene_index = 0
	beat_rule = ""
	current = {}
	used = {}
	used_twists = []
	cast_counts = {}
	for p in players:
		cast_counts[p] = 0
	beat_ends = []
	var run := 0
	for b in format["beats"]:
		run += int(b)
		beat_ends.append(run)
	total_scenes = run
	fixed_pair = []
	if format["cast_rule"] == "fixed_pair" and players.size() >= 2:
		var first := rng.randi_range(0, players.size() - 1)
		var second := first
		while second == first:
			second = rng.randi_range(0, players.size() - 1)
		fixed_pair = [players[first], players[second]]


# ---------- drawing content ----------

func pick_from(list: Array, key: String) -> Variant:
	if not used.has(key):
		used[key] = []
	var u: Array = used[key]
	if u.size() >= list.size():
		u.clear()
	var idx := rng.randi_range(0, list.size() - 1)
	var tries := 0
	while u.has(idx) and tries < 200:
		idx = rng.randi_range(0, list.size() - 1)
		tries += 1
	u.append(idx)
	return list[idx]


func pick_constraint(force: bool = false) -> String:
	var intensity := int(settings.get("intensity", 1))
	if not force and rng.randf() > CONSTRAINT_CHANCE[intensity]:
		return ""
	var pool: Array = []
	for c in Content.CONSTRAINTS:
		if int(c[1]) <= intensity + 1:
			pool.append(c[0])
	if pool.is_empty():
		return ""
	return str(pick_from(pool, "constraint"))


func pick_cast(n: int = 0) -> Array:
	if format.get("cast_rule", "fair") == "fixed_pair" and fixed_pair.size() == 2:
		return fixed_pair.duplicate()
	var count := n
	if count <= 0:
		count = rng.randi_range(2, mini(4, players.size()))
	count = clampi(count, 1, players.size())
	var scored: Array = []
	for p in players:
		scored.append([float(cast_counts.get(p, 0)) + rng.randf() * 0.99, p])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	var out: Array = []
	for i in count:
		out.append(scored[i][1])
	return out


func reroll_element(key: String) -> String:
	match key:
		"location":
			current["location"] = str(pick_from(Content.LOCATIONS, "location"))
		"relationship":
			current["relationship"] = str(pick_from(Content.RELATIONSHIPS, "relationship"))
		"want":
			current["want"] = str(pick_from(Content.WANTS, "want"))
		"obstacle":
			current["obstacle"] = str(pick_from(Content.OBSTACLES, "obstacle"))
		"opener":
			current["opener"] = str(pick_from(Content.OPENERS, "opener"))
		"emotion":
			current["emotion"] = str(pick_from(Content.EMOTIONS, "emotion"))
		"constraint":
			current["constraint"] = pick_constraint(true)
	return str(current.get(key, ""))


func begin_scene(direction: Dictionary) -> Dictionary:
	var prev: Dictionary = current
	scene_index += 1
	var s := {
		"num": scene_index,
		"cast": pick_cast(),
		"location": str(pick_from(Content.LOCATIONS, "location")),
		"relationship": str(pick_from(Content.RELATIONSHIPS, "relationship")),
		"want": str(pick_from(Content.WANTS, "want")),
		"obstacle": str(pick_from(Content.OBSTACLES, "obstacle")),
		"opener": str(pick_from(Content.OPENERS, "opener")),
		"emotion": str(pick_from(Content.EMOTIONS, "emotion")),
		"constraint": pick_constraint(),
		"genre": "",
		"extra": "",
		"direction": str(direction.get("name", "New World")),
		"twists": [],
		"rolls": [],
		"rating": -1,
		"seconds": scene_seconds(format),
	}
	var has_prev := not prev.is_empty()
	match str(direction.get("id", "new_world")):
		"same_world":
			if has_prev:
				s["location"] = prev["location"]
				s["extra"] = "Same place as the last scene. Different people see it differently."
		"same_people":
			if has_prev and format.get("cast_rule", "fair") != "fixed_pair":
				s["cast"] = prev["cast"].duplicate()
		"time_jump":
			if has_prev:
				s["location"] = prev["location"]
				s["relationship"] = prev["relationship"]
				s["cast"] = prev["cast"].duplicate()
				s["extra"] = "Time jump: " + str(pick_from(Content.TIME_JUMPS, "time_jump"))
		"minor":
			if has_prev:
				s["location"] = prev["location"]
				s["extra"] = "Follow someone who was mentioned in the last scene but never seen."
		"callback":
			if not facts.is_empty():
				var f: Dictionary = facts[rng.randi_range(0, facts.size() - 1)]
				s["extra"] = "Callback: " + str(f["text"])
		"mirror":
			if has_prev:
				s["location"] = prev["location"]
				s["relationship"] = prev["relationship"]
				s["want"] = prev["want"]
				s["obstacle"] = prev["obstacle"]
				s["extra"] = "Flip the status. Whoever held power now does not."
		"genre":
			if has_prev:
				s["location"] = prev["location"]
				s["relationship"] = prev["relationship"]
			s["genre"] = str(pick_from(Content.GENRES, "genre"))
		"wildcard":
			s["constraint"] = pick_constraint(true)
			if rng.randf() < 0.5:
				s["genre"] = str(pick_from(Content.GENRES, "genre"))
			s["extra"] = "Wildcard: trust the dice and the moment."
	current = s
	apply_stats(0, -3, 0, 0)
	return s


func beat_of(n: int) -> int:
	for i in beat_ends.size():
		if n <= int(beat_ends[i]):
			return i + 1
	return beat_ends.size()


func is_beat_end() -> bool:
	return beat_ends.has(scene_index)


func is_last_scene() -> bool:
	return scene_index >= total_scenes


func finish_scene(rating_idx: int) -> void:
	var r: Dictionary = Content.RATINGS[clampi(rating_idx, 0, Content.RATINGS.size() - 1)]
	var d: Array = r["stats"]
	apply_stats(d[0], d[1], d[2], d[3])
	current["rating"] = int(r["value"])
	for p in current["cast"]:
		cast_counts[p] = int(cast_counts.get(p, 0)) + 1
	scenes.append(current.duplicate(true))


# ---------- stats ----------

func apply_stats(chaos: float, energy: float, heart: float, coherence: float) -> void:
	stats["chaos"] = clampf(float(stats["chaos"]) + chaos, 0.0, 100.0)
	stats["energy"] = clampf(float(stats["energy"]) + energy, 0.0, 100.0)
	stats["heart"] = clampf(float(stats["heart"]) + heart, 0.0, 100.0)
	stats["coherence"] = clampf(float(stats["coherence"]) + coherence, 0.0, 100.0)


func doctor() -> String:
	var e := float(stats["energy"])
	var c := float(stats["chaos"])
	var h := float(stats["heart"])
	var o := float(stats["coherence"])
	if e < 30.0:
		return "The room is flat. Reach for a physical or time twist."
	if c > 75.0:
		return "Things are wild. Call back to an earlier fact to ground the show."
	if o < 35.0:
		return "The story is scattered. Log facts and call them back."
	if h < 25.0:
		return "Not much heart yet. Look for a sincere moment."
	if e > 85.0:
		return "Big energy. A quiet moment would land now."
	if c < 15.0:
		return "A little too safe. Try a meta twist or a bigger choice."
	return "The show is in a good place. Keep listening."


# ---------- twists, dice, facts ----------

func draw_twists(n: int, kind_filter: String = "") -> Array:
	var intensity := int(settings.get("intensity", 1))
	var kinds: Dictionary = settings["kinds"]
	var pool: Array = []
	for row in Content.TWISTS:
		var kind := str(row[2])
		if kind_filter != "" and kind != kind_filter:
			continue
		if kind_filter == "" and not kinds.get(kind, true):
			continue
		if int(row[3]) > CHAOS_LIMIT[intensity]:
			continue
		pool.append(row)
	if pool.is_empty():
		pool = Content.TWISTS.duplicate()
	var fresh: Array = []
	for row in pool:
		if not used_twists.has(row[0]):
			fresh.append(row)
	if fresh.size() < n:
		used_twists.clear()
		fresh = pool.duplicate()
	var out: Array = []
	var guard := 0
	while out.size() < mini(n, fresh.size()) and guard < 500:
		var row = fresh[rng.randi_range(0, fresh.size() - 1)]
		var dup := false
		for o in out:
			if o["name"] == row[0]:
				dup = true
		if not dup:
			out.append(_twist_dict(row))
		guard += 1
	return out


func _twist_dict(row: Array) -> Dictionary:
	return {
		"name": row[0],
		"text": row[1],
		"kind": row[2],
		"chaos": row[3],
		"energy": row[4],
		"heart": row[5],
		"coherence": row[6],
	}


func apply_twist(tw: Dictionary) -> void:
	apply_stats(tw["chaos"], tw["energy"], tw["heart"], tw["coherence"])
	used_twists.append(tw["name"])
	if not current.is_empty():
		current["twists"].append(tw["name"])


func roll_d20() -> Dictionary:
	var roll := rng.randi_range(1, 20)
	var tier := "nudge"
	if roll == 1:
		tier = "disaster"
	elif roll <= 6:
		tier = "complication"
	elif roll <= 14:
		tier = "nudge"
	elif roll <= 19:
		tier = "gift"
	else:
		tier = "miracle"
	var t: Dictionary = Content.DICE_TIERS[tier]
	var text := str(pick_from(t["texts"], "dice_" + tier))
	var d: Array = t["stats"]
	apply_stats(d[0], d[1], d[2], d[3])
	if not current.is_empty():
		current["rolls"].append("%d: %s" % [roll, t["label"]])
	return {"roll": roll, "tier": tier, "label": t["label"], "color": Color(str(t["color"])), "text": text}


func add_fact(text: String) -> void:
	var clean := text.strip_edges()
	if clean == "":
		return
	facts.append({"text": clean, "scene": scene_index})
	apply_stats(0, 0, 0, 3)


func use_callback(fact: Dictionary) -> void:
	apply_stats(-2, 2, 4, 4)
	if not current.is_empty():
		current["twists"].append("Callback")


# ---------- the review ----------

func build_review() -> Dictionary:
	var total_rating := 0.0
	for s in scenes:
		total_rating += float(s["rating"])
	var rating_norm := 0.5
	if not scenes.is_empty():
		rating_norm = total_rating / (3.0 * scenes.size())
	var chaos_balance := 1.0 - absf(float(stats["chaos"]) - 50.0) / 50.0
	var score := 0.35 * rating_norm
	score += 0.20 * float(stats["energy"]) / 100.0
	score += 0.20 * float(stats["heart"]) / 100.0
	score += 0.15 * float(stats["coherence"]) / 100.0
	score += 0.10 * chaos_balance
	var stars := maxf(0.5, roundf(score * 5.0 * 2.0) / 2.0)

	var top_key := "flat"
	var top_val := 55.0
	for k in ["chaos", "heart", "energy", "coherence"]:
		if float(stats[k]) > top_val:
			top_val = float(stats[k])
			top_key = k
	var headline := str(pick_from(Content.HEADLINES[top_key], "headline_" + top_key))

	var theme := theme_word if theme_word != "" else "an open mind"
	var body := str(pick_from(Content.REVIEW_OPENERS, "review_open")) % theme
	match top_key:
		"chaos":
			body += " The twists came fast and the ensemble embraced every one."
		"heart":
			body += " Sincere moments gave the evening its center."
		"energy":
			body += " The pace never dipped, and the room rode it."
		"coherence":
			body += " Threads were planted early and paid off late."
		_:
			body += " The show took its time, and the performers trusted it."

	var best: Dictionary = {}
	var chaotic: Dictionary = {}
	for s in scenes:
		if best.is_empty() or int(s["rating"]) > int(best["rating"]):
			best = s
		if chaotic.is_empty() or s["twists"].size() + s["rolls"].size() > chaotic["twists"].size() + chaotic["rolls"].size():
			chaotic = s
	if not best.is_empty():
		body += " The high point was scene %d, which unfolded in %s." % [int(best["num"]), str(best["location"]).to_lower().rstrip(".")]
	if not facts.is_empty():
		var f: Dictionary = facts[rng.randi_range(0, facts.size() - 1)]
		body += " One detail will stay with the audience: \"%s\"." % str(f["text"])
	body += " " + str(pick_from(Content.REVIEW_CLOSERS, "review_close"))

	var awards: Array = []
	if not best.is_empty():
		awards.append("Best Scene: Scene %d, %s (%s)" % [int(best["num"]), ", ".join(best["cast"]), Content.RATINGS[int(best["rating"])]["name"]])
	if not chaotic.is_empty() and chaotic["twists"].size() + chaotic["rolls"].size() > 0:
		awards.append("Most Chaotic Scene: Scene %d, with %d twists and rolls" % [int(chaotic["num"]), chaotic["twists"].size() + chaotic["rolls"].size()])
	var top_player := ""
	var top_count := -1
	for p in cast_counts:
		if int(cast_counts[p]) > top_count:
			top_count = int(cast_counts[p])
			top_player = str(p)
	if top_player != "" and top_count > 0:
		awards.append("Most Stage Time: %s, %d scenes" % [top_player, top_count])
	if not facts.is_empty():
		awards.append("Facts Established: %d" % facts.size())

	return {
		"stars": stars,
		"headline": headline,
		"body": body,
		"awards": awards,
	}
