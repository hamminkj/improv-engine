extends Control

signal navigate(screen: String)


func _ready() -> void:
	var review := GameState.build_review()
	UI.background(self)
	var m := UI.margin(self, 44)
	var outer := UI.vbox(14)
	m.add_child(outer)

	var title := UI.label("THE REVIEW", 56, UI.MUTED, false)
	outer.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var cols := UI.hbox(20)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cols)

	# Left: the critic's words
	var left := UI.panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cols.add_child(left)
	var lv := UI.vbox(14)
	left.add_child(lv)
	lv.add_child(UI.label(str(review["headline"]), 72, UI.ACCENT))
	var stars: float = review["stars"]
	lv.add_child(UI.label("%s out of 5 stars" % _fmt_stars(stars), 44, UI.ACCENT2, false))
	lv.add_child(UI.label(str(review["body"]), 32))
	lv.add_child(UI.label("AWARDS", 24, UI.ACCENT2, false))
	for a in review["awards"]:
		lv.add_child(UI.label("- " + str(a), 28))

	# Right: stats and scene list
	var right := UI.panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cols.add_child(right)
	var rv := UI.vbox(10)
	right.add_child(rv)
	rv.add_child(UI.label("THE ROOM AT CURTAIN", 24, UI.ACCENT2, false))
	for k in ["energy", "chaos", "heart", "coherence"]:
		var row := UI.vbox(2)
		row.add_child(UI.label(str(k).capitalize(), 22, UI.MUTED, false))
		var bar := UI.stat_bar(k)
		bar.value = float(GameState.stats[k])
		row.add_child(bar)
		rv.add_child(row)

	rv.add_child(UI.spacer(8))
	rv.add_child(UI.label("SCENES", 24, UI.ACCENT2, false))
	if GameState.scenes.is_empty():
		rv.add_child(UI.label("No scenes were completed.", 26, UI.MUTED))
	for s in GameState.scenes:
		var rating_name := "Unrated"
		if int(s["rating"]) >= 0:
			rating_name = str(Content.RATINGS[int(s["rating"])]["name"])
		var line := "%d. %s | %s | %s" % [int(s["num"]), ", ".join(s["cast"]), str(s["location"]), rating_name]
		rv.add_child(UI.label(line, 24))

	if not GameState.facts.is_empty():
		rv.add_child(UI.spacer(8))
		rv.add_child(UI.label("FACTS ESTABLISHED", 24, UI.ACCENT2, false))
		for f in GameState.facts:
			rv.add_child(UI.label("- " + str(f["text"]), 24))

	var credit := UI.label(UI.credit_line(), 26, UI.MUTED, false)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(credit)

	var bottom := UI.hbox(14)
	outer.add_child(bottom)
	bottom.add_child(UI.button("Run Another Show", func(): navigate.emit("show"), 30))
	bottom.add_child(UI.button("Change Setup", func(): navigate.emit("setup"), 30))
	bottom.add_child(UI.button("Credits", func(): navigate.emit("credits"), 30))
	bottom.add_child(UI.button("Title", func(): navigate.emit("title"), 30))


func _fmt_stars(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(v))
	return "%.1f" % v
