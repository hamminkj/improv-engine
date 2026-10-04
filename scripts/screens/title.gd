extends Control

signal navigate(screen: String)

const HOW_TO := """The screen runs the show. One person (the operator) works the keyboard or a clicker; everyone else performs.

1. Set up your performers, format, length, and intensity.
2. Ask the audience for a suggestion. It becomes the theme.
3. Each scene, the screen deals a cast, place, relationship, want, obstacle, and first line. Reroll anything you do not like.
4. During a scene, fire twists, roll the d20, log facts, and call them back later. The room meter reacts.
5. After each scene, rate it and choose where the story goes next. Between beats, take a warm-up and get a new beat rule.
6. At the end, a critic reviews your show.

F11 toggles fullscreen."""

var _how_panel: PanelContainer


func _ready() -> void:
	UI.background(self)
	var m := UI.margin(self, 80)
	var v := UI.vbox(18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(v)

	var title := UI.label("IMPROV ENGINE", 130, UI.ACCENT, false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := UI.label("The screen runs the show. You bring it to life.", 38, UI.TEXT, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	v.add_child(UI.spacer(20))

	var buttons := UI.vbox(14)
	buttons.custom_minimum_size = Vector2(560, 0)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(buttons)
	buttons.add_child(UI.button("Start a Show", func(): navigate.emit("setup"), 36))
	buttons.add_child(UI.button("How It Works", _toggle_how, 30))
	buttons.add_child(UI.button("Credits", func(): navigate.emit("credits"), 30))
	buttons.add_child(UI.button("Quit", func(): navigate.emit("quit"), 30))

	_how_panel = UI.panel(UI.PANEL, UI.ACCENT2, 2)
	_how_panel.visible = false
	_how_panel.custom_minimum_size = Vector2(1100, 0)
	_how_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_how_panel.add_child(UI.label(HOW_TO, 26))
	v.add_child(_how_panel)

	v.add_child(UI.spacer(10, true))
	var credit := UI.label(UI.credit_line(), 28, UI.MUTED, false)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(credit)


func _toggle_how() -> void:
	_how_panel.visible = not _how_panel.visible
