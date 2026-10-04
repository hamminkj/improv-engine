class_name UI
extends RefCounted
## Small helpers for building the interface in code, plus the shared theme.

const BG := Color("14101c")
const PANEL := Color("231b33")
const PANEL_HI := Color("33264d")
const ACCENT := Color("ffb347")
const ACCENT2 := Color("6ee7d8")
const TEXT := Color("f4efe6")
const MUTED := Color("a89fbd")
const DANGER := Color("ff6b6b")
const GOOD := Color("8be28b")

const STAT_COLORS := {
	"energy": Color("ffb347"),
	"chaos": Color("ff6b6b"),
	"heart": Color("f78fb3"),
	"coherence": Color("6ee7d8"),
}


static func _box(color: Color, radius: int = 12, margin: int = 16, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 28
	t.set_color("font_color", "Label", TEXT)

	t.set_stylebox("normal", "Button", _box(PANEL_HI, 12, 14))
	t.set_stylebox("hover", "Button", _box(PANEL_HI.lightened(0.15), 12, 14, ACCENT, 2))
	t.set_stylebox("pressed", "Button", _box(ACCENT.darkened(0.35), 12, 14, ACCENT, 2))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), 12, 14, ACCENT2, 3))
	t.set_stylebox("disabled", "Button", _box(PANEL, 12, 14))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", MUTED)

	t.set_stylebox("normal", "OptionButton", _box(PANEL_HI, 12, 12))
	t.set_stylebox("hover", "OptionButton", _box(PANEL_HI.lightened(0.15), 12, 12, ACCENT, 2))
	t.set_stylebox("pressed", "OptionButton", _box(PANEL_HI, 12, 12, ACCENT, 2))
	t.set_stylebox("focus", "OptionButton", _box(Color(0, 0, 0, 0), 12, 12, ACCENT2, 3))
	t.set_color("font_color", "OptionButton", TEXT)

	t.set_stylebox("normal", "LineEdit", _box(Color("0f0c17"), 10, 12, MUTED, 2))
	t.set_stylebox("focus", "LineEdit", _box(Color("0f0c17"), 10, 12, ACCENT, 3))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_color("caret_color", "LineEdit", ACCENT)

	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)
	t.set_color("font_pressed_color", "CheckButton", TEXT)

	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 16, 18))
	return t


static func label(text: String, size: int = 28, color: Color = TEXT, wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(text: String, callback: Callable, size: int = 28) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(callback)
	return b


static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func panel(color: Color = PANEL, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(color, 16, 18, border, border_w))
	return p


static func spacer(h: int = 0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	if expand:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func background(parent: Control) -> void:
	var r := ColorRect.new()
	r.color = BG
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


static func margin(parent: Control, amount: int = 40) -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", amount)
	m.add_theme_constant_override("margin_right", amount)
	m.add_theme_constant_override("margin_top", amount)
	m.add_theme_constant_override("margin_bottom", amount)
	parent.add_child(m)
	return m


static func stat_bar(stat: String) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 22)
	pb.add_theme_stylebox_override("background", _box(Color("0f0c17"), 8, 0))
	pb.add_theme_stylebox_override("fill", _box(STAT_COLORS.get(stat, ACCENT), 8, 0))
	return pb


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func credit_line() -> String:
	return "Developed by Julianne Hammink"
