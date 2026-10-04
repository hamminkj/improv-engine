extends Control
## Root node: owns the theme and swaps between screens.

const SCREENS := {
	"title": "res://scripts/screens/title.gd",
	"setup": "res://scripts/screens/setup.gd",
	"show": "res://scripts/screens/show.gd",
	"review": "res://scripts/screens/review.gd",
	"credits": "res://scripts/screens/credits.gd",
}

var _current: Control = null


func _ready() -> void:
	theme = UI.make_theme()
	go("title")


func go(screen_name: String) -> void:
	if screen_name == "quit":
		get_tree().quit()
		return
	if _current != null:
		remove_child(_current)
		_current.queue_free()
		_current = null
	var screen_script: GDScript = load(SCREENS[screen_name])
	var screen = screen_script.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.navigate.connect(go)
	add_child(screen)
	_current = screen


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
