extends Control

signal navigate(screen: String)

var names: Array = []
var names_box: VBoxContainer
var add_btn: Button
var format_opt: OptionButton
var length_opt: OptionButton
var intensity_slider: HSlider
var intensity_label: Label
var format_desc: Label
var estimate_label: Label
var kind_checks: Dictionary = {}
var auto_check: CheckButton
var timer_check: CheckButton
var seed_edit: LineEdit
var warn: Label


func _ready() -> void:
	var s: Dictionary = GameState.settings
	for p in s["players"]:
		names.append(str(p))
	while names.size() < 2:
		names.append("")

	UI.background(self)
	var m := UI.margin(self, 44)
	var outer := UI.vbox(14)
	m.add_child(outer)
	outer.add_child(UI.label("SET UP THE SHOW", 64, UI.ACCENT, false))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var cols := UI.hbox(20)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cols)

	# Left column: performers
	var left := UI.panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cols.add_child(left)
	var lv := UI.vbox(10)
	left.add_child(lv)
	lv.add_child(UI.label("PERFORMERS (2 to 10)", 26, UI.ACCENT2, false))
	names_box = UI.vbox(8)
	lv.add_child(names_box)
	add_btn = UI.button("Add performer", _add_name, 26)
	lv.add_child(add_btn)
	_rebuild_names()

	# Right column: options
	var right := UI.panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cols.add_child(right)
	var rv := UI.vbox(10)
	right.add_child(rv)

	rv.add_child(UI.label("FORMAT", 26, UI.ACCENT2, false))
	format_opt = OptionButton.new()
	format_opt.add_theme_font_size_override("font_size", 28)
	format_opt.get_popup().add_theme_font_size_override("font_size", 28)
	var sel := 0
	for i in Content.FORMATS.size():
		format_opt.add_item(Content.FORMATS[i]["name"])
		if Content.FORMATS[i]["id"] == str(s["format_id"]):
			sel = i
	format_opt.select(sel)
	format_opt.item_selected.connect(func(_i: int): _update_labels())
	rv.add_child(format_opt)
	format_desc = UI.label("", 24, UI.MUTED)
	rv.add_child(format_desc)

	rv.add_child(UI.label("LENGTH", 26, UI.ACCENT2, false))
	length_opt = OptionButton.new()
	length_opt.add_theme_font_size_override("font_size", 28)
	length_opt.get_popup().add_theme_font_size_override("font_size", 28)
	for n in GameState.LENGTH_NAMES:
		length_opt.add_item(n)
	length_opt.select(clampi(int(s["length"]), 0, 2))
	length_opt.item_selected.connect(func(_i: int): _update_labels())
	rv.add_child(length_opt)
	estimate_label = UI.label("", 24, UI.TEXT)
	rv.add_child(estimate_label)

	rv.add_child(UI.label("INTENSITY", 26, UI.ACCENT2, false))
	intensity_slider = HSlider.new()
	intensity_slider.min_value = 0
	intensity_slider.max_value = 2
	intensity_slider.step = 1
	intensity_slider.value = clampi(int(s["intensity"]), 0, 2)
	intensity_slider.custom_minimum_size = Vector2(0, 36)
	intensity_slider.value_changed.connect(func(_v: float): _update_labels())
	rv.add_child(intensity_slider)
	intensity_label = UI.label("", 24, UI.MUTED)
	rv.add_child(intensity_label)

	rv.add_child(UI.label("TWIST TYPES", 26, UI.ACCENT2, false))
	var kinds: Dictionary = s["kinds"]
	for kind in Content.KINDS:
		var cb := CheckButton.new()
		cb.text = Content.KIND_LABELS[kind]
		cb.add_theme_font_size_override("font_size", 26)
		cb.button_pressed = bool(kinds.get(kind, true))
		kind_checks[kind] = cb
		rv.add_child(cb)

	auto_check = CheckButton.new()
	auto_check.text = "The screen fires surprise twists on its own"
	auto_check.add_theme_font_size_override("font_size", 26)
	auto_check.button_pressed = bool(s["auto_twists"])
	rv.add_child(auto_check)

	timer_check = CheckButton.new()
	timer_check.text = "Show the scene timer"
	timer_check.add_theme_font_size_override("font_size", 26)
	timer_check.button_pressed = bool(s["show_timer"])
	rv.add_child(timer_check)

	rv.add_child(UI.label("SEED (optional, repeats the same draw order)", 24, UI.ACCENT2, false))
	seed_edit = LineEdit.new()
	seed_edit.text = str(s["seed"])
	seed_edit.placeholder_text = "Leave blank for a fresh show"
	seed_edit.add_theme_font_size_override("font_size", 26)
	rv.add_child(seed_edit)

	_update_labels()

	warn = UI.label("", 26, UI.DANGER, false)
	outer.add_child(warn)

	var bottom := UI.hbox(16)
	outer.add_child(bottom)
	bottom.add_child(UI.button("Back", func(): navigate.emit("title"), 30))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	bottom.add_child(UI.button("Start the Show", _start, 36))


func _rebuild_names() -> void:
	UI.clear(names_box)
	for i in names.size():
		var idx := i
		var row := UI.hbox(8)
		var e := LineEdit.new()
		e.placeholder_text = "Performer %d" % (i + 1)
		e.text = str(names[i])
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.add_theme_font_size_override("font_size", 28)
		e.text_changed.connect(func(t: String): names[idx] = t)
		row.add_child(e)
		var rm := UI.button("X", func(): _remove_name(idx), 24)
		rm.disabled = names.size() <= 2
		row.add_child(rm)
		names_box.add_child(row)
	if add_btn != null:
		add_btn.disabled = names.size() >= 10


func _add_name() -> void:
	if names.size() < 10:
		names.append("")
		_rebuild_names()


func _remove_name(idx: int) -> void:
	if names.size() > 2 and idx >= 0 and idx < names.size():
		names.remove_at(idx)
		_rebuild_names()


func _update_labels() -> void:
	var fmt: Dictionary = Content.FORMATS[format_opt.selected]
	GameState.settings["length"] = length_opt.selected
	format_desc.text = fmt["desc"]
	var scene_total := 0
	for b in fmt["beats"]:
		scene_total += int(b)
	var mins := GameState.estimate_minutes(fmt)
	estimate_label.text = "About %d minutes, %d scenes, %d seconds each." % [int(round(mins)), scene_total, GameState.scene_seconds(fmt)]
	var lvl := int(intensity_slider.value)
	var blurbs := [
		"Gentle: fewer surprises, softer twists, and fewer rules.",
		"Standard: a healthy mix of surprises and rules.",
		"Wild: frequent surprises, big twists, and tough rules.",
	]
	intensity_label.text = "%s. %s" % [GameState.INTENSITY_NAMES[lvl], blurbs[lvl]]


func _start() -> void:
	var cleaned: Array = []
	var seen: Dictionary = {}
	for n in names:
		var t := str(n).strip_edges()
		if t == "":
			continue
		var base := t
		var k := 2
		while seen.has(t):
			t = "%s %d" % [base, k]
			k += 1
		seen[t] = true
		cleaned.append(t)
	if cleaned.size() < 2:
		warn.text = "Add at least two performer names to begin."
		return
	var any_kind := false
	for kind in kind_checks:
		if kind_checks[kind].button_pressed:
			any_kind = true
	if not any_kind:
		warn.text = "Turn on at least one twist type."
		return

	var s: Dictionary = GameState.settings
	s["players"] = cleaned
	s["format_id"] = Content.FORMATS[format_opt.selected]["id"]
	s["length"] = length_opt.selected
	s["intensity"] = int(intensity_slider.value)
	var kinds: Dictionary = {}
	for kind in kind_checks:
		kinds[kind] = kind_checks[kind].button_pressed
	s["kinds"] = kinds
	s["auto_twists"] = auto_check.button_pressed
	s["show_timer"] = timer_check.button_pressed
	s["seed"] = seed_edit.text.strip_edges()
	GameState.save_settings()
	navigate.emit("show")
