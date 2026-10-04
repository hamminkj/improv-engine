extends Control

signal navigate(screen: String)


func _ready() -> void:
	UI.background(self)
	var m := UI.margin(self, 80)
	var v := UI.vbox(24)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(v)

	var title := UI.label("CREDITS", 96, UI.ACCENT, false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var dev := UI.label(UI.credit_line(), 56, UI.TEXT, false)
	dev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dev)

	var engine := UI.label("Built with the Godot Engine.", 30, UI.MUTED, false)
	engine.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(engine)

	var thanks := UI.label("Thank you to every performer who said yes, and.", 30, UI.MUTED, false)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(thanks)

	v.add_child(UI.spacer(20))
	var back := UI.button("Back to Title", func(): navigate.emit("title"), 32)
	back.custom_minimum_size = Vector2(420, 0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			navigate.emit("title")
