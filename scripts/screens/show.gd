extends Control
## The live show. The operator drives it from the keyboard or mouse.

signal navigate(screen: String)

enum Phase { OPENING, MONOLOGUE, PITCH, LIVE, WRAP, INTERMISSION }

const ELEMENT_KEYS := ["location", "relationship", "want", "obstacle", "opener", "emotion", "constraint"]
const ELEMENT_TITLES := {
	"location": "WHERE",
	"relationship": "WHO",
	"want": "WANT",
	"obstacle": "IN THE WAY",
	"opener": "FIRST LINE",
	"emotion": "FEELING",
	"constraint": "RULE",
}

var phase: int = Phase.OPENING
var center: VBoxContainer
var top_label: Label
var help_label: Label
var stat_bars: Dictionary = {}
var doctor_label: Label
var facts_label: Label
var feed_label: Label
var flash: ColorRect

var overlay: Control = null
var overlay_kind: String = ""
var paused: bool = false

var time_left: float = 0.0
var time_total: float = 1.0
var timer_running: bool = false
var timer_label: Label
var auto_marks: Array = []

var banner: PanelContainer = null
var banner_title: Label
var banner_text: Label
var banner_time: float = 0.0

var pending_direction: Dictionary = {}
var direction_choices: Array = []
var warmup_choices: Array = []
var wrap_stage: int = 0
var mono_started: bool = false
var twist_feed: Array = []

var suggestion_edit: LineEdit
var menu_kind: String = ""
var menu_choices: Array = []
var menu_box: VBoxContainer
var dice_number: Label
var dice_text: Label
var dice_tier: Label
var fact_edit: LineEdit
var warmup_detail: Label


func _ready() -> void:
	UI.background(self)
	var m := UI.margin(self, 28)
	var root := UI.vbox(14)
	m.add_child(root)

	top_label = UI.label("", 30, UI.MUTED, false)
	root.add_child(top_label)

	var main_row := UI.hbox(20)
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main_row)

	center = UI.vbox(14)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.add_child(center)
	_build_side(main_row)

	help_label = UI.label("", 22, UI.MUTED, false)
	root.add_child(help_label)

	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	GameState.new_show()
	_refresh_side()
	_phase_opening()


# ---------- shared layout ----------

func _build_side(parent: Control) -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(470, 0)
	parent.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.label("THE ROOM", 26, UI.ACCENT, false))
	for k in ["energy", "chaos", "heart", "coherence"]:
		var row := UI.vbox(2)
		row.add_child(UI.label(str(k).capitalize(), 22, UI.MUTED, false))
		var bar := UI.stat_bar(k)
		row.add_child(bar)
		stat_bars[k] = bar
		v.add_child(row)
	v.add_child(UI.label("SHOW DOCTOR", 22, UI.ACCENT2, false))
	doctor_label = UI.label("", 24)
	v.add_child(doctor_label)
	v.add_child(UI.label("FACTS ESTABLISHED", 22, UI.ACCENT2, false))
	facts_label = UI.label("", 22)
	v.add_child(facts_label)
	v.add_child(UI.label("RECENT TWISTS", 22, UI.ACCENT2, false))
	feed_label = UI.label("", 22)
	v.add_child(feed_label)


func _refresh_side() -> void:
	for k in stat_bars:
		var bar: ProgressBar = stat_bars[k]
		var tw := create_tween()
		tw.tween_property(bar, "value", float(GameState.stats[k]), 0.4)
	doctor_label.text = GameState.doctor()
	if GameState.facts.is_empty():
		facts_label.text = "None yet. Press F to log one."
	else:
		var lines: Array = []
		var start := maxi(0, GameState.facts.size() - 5)
		for i in range(GameState.facts.size() - 1, start - 1, -1):
			lines.append("- " + str(GameState.facts[i]["text"]))
		facts_label.text = "\n".join(lines)
	if twist_feed.is_empty():
		feed_label.text = "Nothing yet."
	else:
		var tl: Array = []
		var tstart := maxi(0, twist_feed.size() - 4)
		for i in range(twist_feed.size() - 1, tstart - 1, -1):
			tl.append("- " + str(twist_feed[i]))
		feed_label.text = "\n".join(tl)


func _update_top() -> void:
	var parts: Array = ["IMPROV ENGINE"]
	if GameState.scene_index > 0:
		parts.append("Scene %d of %d" % [GameState.scene_index, GameState.total_scenes])
		parts.append("Beat %d" % GameState.beat_of(GameState.scene_index))
	if GameState.theme_word != "":
		parts.append("Theme: " + GameState.theme_word)
	if GameState.beat_rule != "":
		parts.append("Beat rule: " + GameState.beat_rule)
	top_label.text = "   |   ".join(parts)


func _set_help(text: String) -> void:
	help_label.text = text


func _center_label(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _card_button(text: String, callback: Callable, size: int = 28) -> Button:
	var b := UI.button(text, callback, size)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(300, 120)
	return b


func _flash(color: Color) -> void:
	flash.color = Color(color.r, color.g, color.b, 0.35)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.6)


func _fmt_time(t: float) -> String:
	var s := int(ceil(t))
	return "%d:%02d" % [s / 60, s % 60]


func _reset_phase_state() -> void:
	timer_running = false
	banner = null
	timer_label = null
	auto_marks = []
	banner_time = 0.0
	UI.clear(center)


# ---------- phase: opening suggestion ----------

func _phase_opening() -> void:
	phase = Phase.OPENING
	_reset_phase_state()
	_update_top()
	_set_help("Type what the audience shouts and press Enter.")
	center.add_child(UI.label("ASK THE AUDIENCE", 80, UI.ACCENT, false))
	center.add_child(UI.label("Pick a prompt, ask the room, and type what you hear.", 32, UI.MUTED))

	var cats: Array = Content.SUGGESTION_PROMPTS.keys()
	var row := UI.hbox(16)
	center.add_child(row)
	var shown := 0
	var start := GameState.rng.randi_range(0, cats.size() - 1)
	while shown < 3:
		var cat: String = cats[(start + shown) % cats.size()]
		var card := UI.panel(UI.PANEL_HI)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv := UI.vbox(8)
		card.add_child(cv)
		cv.add_child(UI.label(cat.to_upper(), 24, UI.ACCENT2, false))
		cv.add_child(UI.label(str(Content.SUGGESTION_PROMPTS[cat]), 34))
		var ex: Array = Content.SUGGESTION_EXAMPLES[cat]
		cv.add_child(UI.label("For example: " + str(ex[GameState.rng.randi_range(0, ex.size() - 1)]), 24, UI.MUTED))
		row.add_child(card)
		shown += 1

	center.add_child(UI.spacer(20))
	suggestion_edit = LineEdit.new()
	suggestion_edit.placeholder_text = "The audience says..."
	suggestion_edit.add_theme_font_size_override("font_size", 40)
	suggestion_edit.text_submitted.connect(func(t: String): _use_suggestion(t))
	center.add_child(suggestion_edit)

	var btns := UI.hbox(14)
	center.add_child(btns)
	btns.add_child(UI.button("Use it", func(): _use_suggestion(suggestion_edit.text), 32))
	btns.add_child(UI.button("Draw one for me", _draw_suggestion, 32))
	suggestion_edit.grab_focus.call_deferred()


func _draw_suggestion() -> void:
	var cats: Array = Content.SUGGESTION_EXAMPLES.keys()
	var cat: String = cats[GameState.rng.randi_range(0, cats.size() - 1)]
	var ex: Array = Content.SUGGESTION_EXAMPLES[cat]
	_use_suggestion(str(ex[GameState.rng.randi_range(0, ex.size() - 1)]))


func _use_suggestion(text: String) -> void:
	var t := text.strip_edges()
	if t == "":
		return
	GameState.theme_word = t
	GameState.add_fact("Audience suggestion: " + t)
	_refresh_side()
	_start_beat_or_scene(Content.DIRECTIONS[0])


func _start_beat_or_scene(direction: Dictionary) -> void:
	var n := GameState.scene_index + 1
	var first_of_beat := (n == 1) or GameState.beat_ends.has(n - 1)
	if GameState.format["monologue"] and first_of_beat:
		_phase_monologue(direction)
	else:
		_phase_pitch(direction)


# ---------- phase: monologue ----------

func _phase_monologue(direction: Dictionary) -> void:
	phase = Phase.MONOLOGUE
	_reset_phase_state()
	pending_direction = direction
	mono_started = false
	_update_top()
	_set_help("Space: start, then finish   F: log a fact   Esc: menu")
	var who: String = str(GameState.pick_cast(1)[0])
	var prompt := str(GameState.pick_from(Content.MONOLOGUE_PROMPTS, "monologue"))
	center.add_child(UI.label("MONOLOGUE", 80, UI.ACCENT, false))
	center.add_child(UI.label(who, 70, UI.TEXT, false))
	center.add_child(UI.label(prompt, 44, UI.ACCENT2))
	center.add_child(UI.label("Everyone else: listen for names, places, and details. The next scenes come from this story.", 28, UI.MUTED))
	timer_label = _center_label(UI.label(_fmt_time(60.0), 140, UI.TEXT, false))
	center.add_child(timer_label)
	time_total = 60.0
	time_left = 60.0
	center.add_child(UI.spacer(10, true))
	var btns := UI.hbox(14)
	center.add_child(btns)
	btns.add_child(UI.button("Start / Finish [Space]", _mono_advance, 30))
	btns.add_child(UI.button("Log a fact [F]", _open_fact, 30))


func _mono_advance() -> void:
	if not mono_started:
		mono_started = true
		timer_running = true
		_set_help("Space: finish the monologue   F: log a fact   P: pause")
	else:
		timer_running = false
		_phase_pitch(pending_direction)


# ---------- phase: pitch ----------

func _phase_pitch(direction: Dictionary) -> void:
	phase = Phase.PITCH
	_reset_phase_state()
	pending_direction = direction
	GameState.begin_scene(direction)
	_render_pitch()
	_refresh_side()


func _render_pitch() -> void:
	UI.clear(center)
	_update_top()
	_set_help("1 to 7: reroll a card   Click names to change the cast   Space: start the scene   Esc: menu")
	var s: Dictionary = GameState.current
	center.add_child(UI.label("SCENE %d" % int(s["num"]), 70, UI.ACCENT, false))
	center.add_child(UI.label("%s. %s" % [pending_direction.get("name", ""), pending_direction.get("text", "")], 28, UI.MUTED))

	var notes: Array = []
	if str(s["extra"]) != "":
		notes.append(str(s["extra"]))
	if str(s["genre"]) != "":
		notes.append("Genre: " + str(s["genre"]))
	if GameState.format["id"] == "chain" and int(s["num"]) > 1:
		notes.append("Open with the last line of the previous scene.")
	if not notes.is_empty():
		center.add_child(UI.label("  ".join(notes), 32, UI.ACCENT2))

	var cast_row := UI.hbox(10)
	center.add_child(cast_row)
	cast_row.add_child(UI.label("CAST:", 26, UI.ACCENT2, false))
	for p in GameState.players:
		var pname: String = str(p)
		var b := Button.new()
		b.text = pname
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 28)
		b.button_pressed = s["cast"].has(pname)
		b.toggled.connect(func(on: bool): _toggle_cast(pname, on))
		cast_row.add_child(b)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(grid)
	for i in ELEMENT_KEYS.size():
		var key: String = ELEMENT_KEYS[i]
		var value := str(s.get(key, ""))
		if value == "":
			value = "None this scene. Press %d to draw one." % (i + 1)
		var card := UI.panel(UI.PANEL_HI)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv := UI.vbox(6)
		card.add_child(cv)
		cv.add_child(UI.label("[%d] %s" % [i + 1, ELEMENT_TITLES[key]], 22, UI.ACCENT2, false))
		cv.add_child(UI.label(value, 32))
		var rr := UI.button("Reroll", func(): _reroll(key), 22)
		rr.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		cv.add_child(rr)
		grid.add_child(card)

	center.add_child(UI.spacer(6, true))
	var start_btn := UI.button("Start the Scene [Space]", _begin_live, 40)
	center.add_child(start_btn)


func _toggle_cast(pname: String, on: bool) -> void:
	var cast: Array = GameState.current["cast"]
	if on and not cast.has(pname):
		cast.append(pname)
	elif not on and cast.has(pname):
		cast.erase(pname)


func _reroll(key: String) -> void:
	GameState.reroll_element(key)
	_render_pitch()


# ---------- phase: live ----------

func _begin_live() -> void:
	var s: Dictionary = GameState.current
	if s["cast"].is_empty():
		s["cast"] = GameState.pick_cast()
	phase = Phase.LIVE
	UI.clear(center)
	banner = null
	_update_top()
	_set_help("T: random twist   Y: choose a twist   D: roll d20   F: log a fact   C: callback   P: pause   Space: end the scene")

	time_total = float(s["seconds"])
	time_left = time_total
	timer_running = true
	auto_marks = []
	if bool(GameState.settings.get("auto_twists", true)):
		var intensity := int(GameState.settings.get("intensity", 1))
		for i in GameState.AUTO_TWIST_COUNT[intensity]:
			auto_marks.append(GameState.rng.randf_range(0.2, 0.85) * time_total)
		auto_marks.sort()

	timer_label = _center_label(UI.label(_fmt_time(time_left), 130, UI.TEXT, false))
	timer_label.visible = bool(GameState.settings.get("show_timer", true))
	center.add_child(timer_label)
	center.add_child(_center_label(UI.label(" and ".join(s["cast"]) if s["cast"].size() == 2 else ", ".join(s["cast"]), 56, UI.ACCENT, false)))

	var recap := UI.panel(UI.PANEL)
	recap.add_child(UI.label(_recap_text(s), 28))
	center.add_child(recap)

	banner = UI.panel(UI.PANEL_HI, UI.ACCENT, 3)
	banner.custom_minimum_size = Vector2(0, 200)
	banner.modulate.a = 0.0
	var bv := UI.vbox(6)
	banner.add_child(bv)
	banner_title = UI.label("", 30, UI.ACCENT, false)
	banner_text = UI.label("", 40)
	bv.add_child(banner_title)
	bv.add_child(banner_text)
	center.add_child(banner)

	center.add_child(UI.spacer(4, true))
	var row := UI.hbox(10)
	center.add_child(row)
	row.add_child(UI.button("Twist [T]", _random_twist, 26))
	row.add_child(UI.button("Pick twist [Y]", _open_twist_menu, 26))
	row.add_child(UI.button("Roll d20 [D]", _roll_dice, 26))
	row.add_child(UI.button("Fact [F]", _open_fact, 26))
	row.add_child(UI.button("Callback [C]", _open_callback, 26))
	row.add_child(UI.button("Pause [P]", _open_pause, 26))
	row.add_child(UI.button("End scene [Space]", _end_scene, 26))
	_refresh_side()


func _recap_text(s: Dictionary) -> String:
	var lines: Array = []
	lines.append("WHERE: " + str(s["location"]))
	lines.append("WHO: " + str(s["relationship"]))
	lines.append("WANT: %s   |   IN THE WAY: %s" % [s["want"], s["obstacle"]])
	lines.append("FEELING: %s   |   FIRST LINE: \"%s\"" % [s["emotion"], s["opener"]])
	if str(s["constraint"]) != "":
		lines.append("RULE: " + str(s["constraint"]))
	if str(s["extra"]) != "":
		lines.append(str(s["extra"]))
	if str(s["genre"]) != "":
		lines.append("GENRE: " + str(s["genre"]))
	return "\n".join(lines)


func _process(delta: float) -> void:
	if banner_time > 0.0:
		banner_time -= delta
		if banner_time <= 0.0 and banner != null and is_instance_valid(banner):
			banner.modulate.a = 0.0
	if not timer_running or paused:
		return
	time_left -= delta
	if timer_label != null and is_instance_valid(timer_label):
		if time_left > 0.0:
			timer_label.text = _fmt_time(time_left)
			timer_label.add_theme_color_override("font_color", UI.DANGER if time_left <= 15.0 else UI.TEXT)
	var elapsed := time_total - time_left
	while not auto_marks.is_empty() and elapsed >= float(auto_marks[0]):
		auto_marks.pop_front()
		_auto_twist()
	if time_left <= 0.0:
		time_left = 0.0
		timer_running = false
		_time_up()


func _time_up() -> void:
	if timer_label != null and is_instance_valid(timer_label):
		timer_label.visible = true
		timer_label.text = "TIME"
		timer_label.add_theme_color_override("font_color", UI.DANGER)
	if phase == Phase.LIVE:
		_set_help("Time. Land the scene, then press Space.")
		_show_banner("TIME", "Find the button and end the scene.", UI.DANGER)
	else:
		_set_help("Time. Press Space to move on.")


func _show_banner(title: String, text: String, color: Color) -> void:
	_flash(color)
	if banner == null or not is_instance_valid(banner):
		return
	banner_title.text = title
	banner_title.add_theme_color_override("font_color", color)
	banner_text.text = text
	banner.modulate.a = 1.0
	banner_time = 25.0


func _end_scene() -> void:
	timer_running = false
	phase = Phase.WRAP
	wrap_stage = 0
	_render_wrap()


# ---------- twists ----------

func _random_twist() -> void:
	if phase != Phase.LIVE or overlay != null:
		return
	var picks := GameState.draw_twists(1)
	if not picks.is_empty():
		_present_twist(picks[0], "TWIST")


func _auto_twist() -> void:
	var picks := GameState.draw_twists(1)
	if not picks.is_empty():
		_present_twist(picks[0], "SURPRISE TWIST")


func _present_twist(tw: Dictionary, label: String) -> void:
	GameState.apply_twist(tw)
	twist_feed.append("%s (%s)" % [tw["name"], Content.KIND_LABELS[tw["kind"]]])
	_show_banner("%s: %s" % [label, str(tw["name"]).to_upper()], str(tw["text"]), UI.ACCENT)
	_refresh_side()


# ---------- overlays ----------

func _open_overlay(kind: String, content: Control) -> void:
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	var p := UI.panel(UI.PANEL, UI.ACCENT, 3)
	p.custom_minimum_size = Vector2(1100, 0)
	p.add_child(content)
	cc.add_child(p)
	add_child(overlay)
	overlay_kind = kind


func _close_overlay() -> void:
	if overlay != null:
		remove_child(overlay)
		overlay.queue_free()
		overlay = null
	overlay_kind = ""


func _can_use_live_tools() -> bool:
	return overlay == null and (phase == Phase.LIVE or phase == Phase.MONOLOGUE)


# Twist menu

func _open_twist_menu() -> void:
	if phase != Phase.LIVE or overlay != null:
		return
	menu_kind = ""
	menu_choices = GameState.draw_twists(4)
	menu_box = UI.vbox(10)
	_open_overlay("twist", menu_box)
	_fill_twist_menu()


func _fill_twist_menu() -> void:
	UI.clear(menu_box)
	menu_box.add_child(UI.label("CHOOSE A TWIST", 40, UI.ACCENT, false))
	var kinds_row := UI.hbox(8)
	menu_box.add_child(kinds_row)
	kinds_row.add_child(UI.button("Any", func(): _set_menu_kind(""), 24))
	var enabled: Dictionary = GameState.settings["kinds"]
	for kind in Content.KINDS:
		if bool(enabled.get(kind, true)):
			var k: String = kind
			kinds_row.add_child(UI.button(str(Content.KIND_LABELS[k]), func(): _set_menu_kind(k), 24))
	for i in menu_choices.size():
		var tw: Dictionary = menu_choices[i]
		var idx := i
		var b := _card_button("%d. %s (%s)\n%s" % [i + 1, tw["name"], Content.KIND_LABELS[tw["kind"]], tw["text"]], func(): _pick_menu_twist(idx), 26)
		menu_box.add_child(b)
	var foot := UI.hbox(10)
	menu_box.add_child(foot)
	foot.add_child(UI.button("Reshuffle [R]", _reshuffle_menu, 24))
	foot.add_child(UI.button("Close [Esc]", _close_overlay, 24))


func _set_menu_kind(kind: String) -> void:
	menu_kind = kind
	menu_choices = GameState.draw_twists(4, kind)
	_fill_twist_menu()


func _reshuffle_menu() -> void:
	menu_choices = GameState.draw_twists(4, menu_kind)
	_fill_twist_menu()


func _pick_menu_twist(idx: int) -> void:
	if idx < 0 or idx >= menu_choices.size():
		return
	var tw: Dictionary = menu_choices[idx]
	_close_overlay()
	_present_twist(tw, "TWIST")


# Dice

func _roll_dice() -> void:
	if phase != Phase.LIVE or overlay != null:
		return
	var result := GameState.roll_d20()
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(900, 0)
	v.add_child(_center_label(UI.label("THE DICE ARE ROLLING", 36, UI.ACCENT, false)))
	dice_number = _center_label(UI.label("?", 220, UI.TEXT, false))
	v.add_child(dice_number)
	dice_tier = _center_label(UI.label("", 56, UI.TEXT, false))
	v.add_child(dice_tier)
	dice_text = _center_label(UI.label("", 40, UI.TEXT))
	v.add_child(dice_text)
	var close := UI.button("Close [Space]", _close_overlay, 28)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(close)
	_open_overlay("dice", v)

	var number_label := dice_number
	var tween := create_tween()
	tween.tween_method(_dice_tick.bind(number_label), 0.0, 14.0, 1.0)
	tween.tween_callback(func(): _dice_done(result, number_label))


func _dice_tick(t: float, number_label: Label) -> void:
	if is_instance_valid(number_label):
		number_label.text = str((int(t) * 7 + 3) % 20 + 1)


func _dice_done(result: Dictionary, number_label: Label) -> void:
	if not is_instance_valid(number_label):
		return
	var color: Color = result["color"]
	number_label.text = str(result["roll"])
	number_label.add_theme_color_override("font_color", color)
	dice_tier.text = str(result["label"])
	dice_tier.add_theme_color_override("font_color", color)
	dice_text.text = str(result["text"])
	twist_feed.append("Rolled %d: %s" % [int(result["roll"]), str(result["label"])])
	_show_banner("d20: %d, %s" % [int(result["roll"]), str(result["label"]).to_upper()], str(result["text"]), color)
	_refresh_side()


# Facts

func _open_fact() -> void:
	if not _can_use_live_tools():
		return
	var v := UI.vbox(14)
	v.add_child(UI.label("LOG A FACT", 40, UI.ACCENT, false))
	v.add_child(UI.label("Type a detail the performers established: a name, a place, an object, a rule. You can call it back later.", 26, UI.MUTED))
	fact_edit = LineEdit.new()
	fact_edit.placeholder_text = "For example: Marge keeps bees in the attic"
	fact_edit.add_theme_font_size_override("font_size", 34)
	fact_edit.text_submitted.connect(func(t: String): _submit_fact(t))
	v.add_child(fact_edit)
	var row := UI.hbox(10)
	v.add_child(row)
	row.add_child(UI.button("Add fact", func(): _submit_fact(fact_edit.text), 28))
	row.add_child(UI.button("Cancel", _close_overlay, 28))
	_open_overlay("fact", v)
	fact_edit.grab_focus.call_deferred()


func _submit_fact(text: String) -> void:
	var t := text.strip_edges()
	if t == "":
		return
	GameState.add_fact(t)
	_close_overlay()
	_refresh_side()


# Callbacks

func _open_callback() -> void:
	if phase != Phase.LIVE or overlay != null:
		return
	var v := UI.vbox(10)
	v.add_child(UI.label("CALL BACK A FACT", 40, UI.ACCENT, false))
	if GameState.facts.is_empty():
		v.add_child(UI.label("No facts logged yet. Press F during a scene to log one.", 30, UI.MUTED))
	else:
		v.add_child(UI.label("Pick one and bring it into the scene right now.", 26, UI.MUTED))
		var shown := 0
		for i in range(GameState.facts.size() - 1, -1, -1):
			if shown >= 8:
				break
			var f: Dictionary = GameState.facts[i]
			var fact_copy := f
			v.add_child(_card_button("%d. %s" % [shown + 1, str(f["text"])], func(): _pick_callback(fact_copy), 28))
			shown += 1
	var close := UI.button("Close [Esc]", _close_overlay, 26)
	close.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(close)
	_open_overlay("callback", v)


func _pick_callback(fact: Dictionary) -> void:
	GameState.use_callback(fact)
	twist_feed.append("Callback: " + str(fact["text"]))
	_close_overlay()
	_show_banner("CALLBACK", str(fact["text"]), UI.ACCENT2)
	_refresh_side()


func _callback_by_number(n: int) -> void:
	var idx := GameState.facts.size() - 1 - n
	if idx >= 0 and idx < GameState.facts.size() and n < 8:
		_pick_callback(GameState.facts[idx])


# Pause

func _open_pause() -> void:
	if overlay != null:
		return
	paused = true
	var v := UI.vbox(14)
	v.add_child(_center_label(UI.label("PAUSED", 70, UI.ACCENT, false)))
	v.add_child(UI.button("Resume [Esc]", _resume, 32))
	v.add_child(UI.button("End the show now", _end_show_now, 32))
	v.add_child(UI.button("Quit to title", func(): navigate.emit("title"), 32))
	_open_overlay("pause", v)


func _resume() -> void:
	paused = false
	_close_overlay()


func _end_show_now() -> void:
	paused = false
	navigate.emit("review")


# ---------- phase: wrap ----------

func _render_wrap() -> void:
	UI.clear(center)
	banner = null
	timer_label = null
	_update_top()
	var s: Dictionary = GameState.current
	if wrap_stage == 0:
		_set_help("Press 1 to 4 to rate the scene.")
		center.add_child(UI.label("SCENE %d COMPLETE" % int(s["num"]), 72, UI.ACCENT, false))
		center.add_child(UI.label("How did that land?", 40, UI.TEXT, false))
		var summary: Array = []
		if not s["twists"].is_empty():
			summary.append("Twists: " + ", ".join(s["twists"]))
		if not s["rolls"].is_empty():
			summary.append("Rolls: " + ", ".join(s["rolls"]))
		if not summary.is_empty():
			center.add_child(UI.label("   ".join(summary), 26, UI.MUTED))
		var row := UI.hbox(14)
		center.add_child(row)
		for i in Content.RATINGS.size():
			var r: Dictionary = Content.RATINGS[i]
			var idx := i
			var b := _card_button("%d. %s\n%s" % [i + 1, r["name"], r["text"]], func(): _rate(idx), 32)
			b.custom_minimum_size = Vector2(200, 220)
			row.add_child(b)
	else:
		_set_help("Press 1 to %d to choose what happens next." % direction_choices.size())
		center.add_child(UI.label("WHAT HAPPENS NEXT?", 72, UI.ACCENT, false))
		center.add_child(UI.label("Choose a direction for the next scene.", 36, UI.TEXT, false))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center.add_child(grid)
		for i in direction_choices.size():
			var d: Dictionary = direction_choices[i]
			var idx := i
			grid.add_child(_card_button("%d. %s\n%s" % [i + 1, d["name"], d["text"]], func(): _choose_direction(idx), 30))
	_refresh_side()


func _rate(idx: int) -> void:
	if idx < 0 or idx >= Content.RATINGS.size():
		return
	GameState.finish_scene(idx)
	_refresh_side()
	if GameState.is_last_scene():
		navigate.emit("review")
	elif GameState.is_beat_end():
		_phase_intermission()
	else:
		direction_choices = _draw_directions()
		wrap_stage = 1
		_render_wrap()


func _draw_directions() -> Array:
	var pool: Array = []
	for d in Content.DIRECTIONS:
		var id: String = d["id"]
		if id == "callback" and GameState.facts.is_empty():
			continue
		if id == "same_people" and GameState.format.get("cast_rule", "fair") == "fixed_pair":
			continue
		pool.append(d)
	var out: Array = []
	var guard := 0
	while out.size() < mini(4, pool.size()) and guard < 200:
		var d: Dictionary = pool[GameState.rng.randi_range(0, pool.size() - 1)]
		if not out.has(d):
			out.append(d)
		guard += 1
	return out


func _choose_direction(idx: int) -> void:
	if idx < 0 or idx >= direction_choices.size():
		return
	_start_beat_or_scene(direction_choices[idx])


# ---------- phase: intermission ----------

func _phase_intermission() -> void:
	phase = Phase.INTERMISSION
	_reset_phase_state()
	GameState.apply_stats(-5, 6, 2, 0)
	GameState.beat_rule = str(GameState.pick_from(Content.BEAT_RULES, "beat_rule"))
	_update_top()
	_refresh_side()
	_set_help("1 to 3: pick a warm-up   Space: start the next beat")
	var done_beat := GameState.beat_of(GameState.scene_index)
	center.add_child(UI.label("BEAT %d COMPLETE" % done_beat, 80, UI.ACCENT, false))
	center.add_child(UI.label("Take a breath. Reset the room.", 36, UI.TEXT, false))

	var rule_panel := UI.panel(UI.PANEL_HI, UI.ACCENT2, 2)
	var rv := UI.vbox(6)
	rule_panel.add_child(rv)
	rv.add_child(UI.label("RULE FOR THE NEXT BEAT", 24, UI.ACCENT2, false))
	rv.add_child(UI.label(GameState.beat_rule, 40))
	if GameState.format["id"] == "harold" and done_beat + 1 == GameState.beat_ends.size():
		rv.add_child(UI.label("Final beat: bring back characters, places, and facts from the first beat.", 28, UI.MUTED))
	center.add_child(rule_panel)

	center.add_child(UI.label("OPTIONAL WARM-UP", 26, UI.ACCENT2, false))
	warmup_choices = []
	var guard := 0
	while warmup_choices.size() < 3 and guard < 100:
		var w: Dictionary = Content.WARMUPS[GameState.rng.randi_range(0, Content.WARMUPS.size() - 1)]
		if not warmup_choices.has(w):
			warmup_choices.append(w)
		guard += 1
	var row := UI.hbox(12)
	center.add_child(row)
	for i in warmup_choices.size():
		var idx := i
		row.add_child(_card_button("%d. %s" % [i + 1, warmup_choices[i]["name"]], func(): _pick_warmup(idx), 28))
	warmup_detail = UI.label("", 32, UI.TEXT)
	center.add_child(warmup_detail)
	center.add_child(UI.spacer(4, true))
	center.add_child(UI.button("Start the next beat [Space]", _finish_intermission, 36))


func _pick_warmup(idx: int) -> void:
	if idx < 0 or idx >= warmup_choices.size():
		return
	var w: Dictionary = warmup_choices[idx]
	warmup_detail.text = "%s: %s" % [w["name"], w["text"]]


func _finish_intermission() -> void:
	_start_beat_or_scene(Content.DIRECTIONS[0])


# ---------- input ----------

func _num_from_key(k: int) -> int:
	if k >= KEY_1 and k <= KEY_9:
		return k - KEY_1
	return -1


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.keycode
	if k == KEY_F11:
		return
	var n := _num_from_key(k)
	get_viewport().set_input_as_handled()

	if overlay != null:
		match overlay_kind:
			"pause":
				if k == KEY_ESCAPE or k == KEY_P:
					_resume()
			"twist":
				if k == KEY_ESCAPE:
					_close_overlay()
				elif k == KEY_R:
					_reshuffle_menu()
				elif n >= 0:
					_pick_menu_twist(n)
			"callback":
				if k == KEY_ESCAPE:
					_close_overlay()
				elif n >= 0:
					_callback_by_number(n)
			"dice":
				if k == KEY_ESCAPE or k == KEY_SPACE or k == KEY_ENTER:
					_close_overlay()
			"fact":
				if k == KEY_ESCAPE:
					_close_overlay()
		return

	if k == KEY_ESCAPE:
		_open_pause()
		return

	var go := k == KEY_SPACE or k == KEY_ENTER
	match phase:
		Phase.MONOLOGUE:
			if go:
				_mono_advance()
			elif k == KEY_F:
				_open_fact()
			elif k == KEY_P:
				_open_pause()
		Phase.PITCH:
			if go:
				_begin_live()
			elif n >= 0 and n < ELEMENT_KEYS.size():
				_reroll(ELEMENT_KEYS[n])
		Phase.LIVE:
			if go:
				_end_scene()
			elif k == KEY_T:
				_random_twist()
			elif k == KEY_Y:
				_open_twist_menu()
			elif k == KEY_D:
				_roll_dice()
			elif k == KEY_F:
				_open_fact()
			elif k == KEY_C:
				_open_callback()
			elif k == KEY_P:
				_open_pause()
		Phase.WRAP:
			if n >= 0:
				if wrap_stage == 0:
					_rate(n)
				else:
					_choose_direction(n)
		Phase.INTERMISSION:
			if go:
				_finish_intermission()
			elif n >= 0 and n < 3:
				_pick_warmup(n)
