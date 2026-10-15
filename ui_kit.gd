class_name UIKit
extends RefCounted
## أدوات واجهة صغيرة بألوان مصرية (أحمر داكن + ذهبي).

const GOLD := Color("#f2c14e")
const RED := Color("#8e1b1b")
const DARK := Color("#14090a")

static var font: Font = null


static func box(bg: Color, border: Color, radius := 14, border_w := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func make_theme(font: Font) -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 28
	t.set_color("font_color", "Label", Color.WHITE)
	var clear := Color(0, 0, 0, 0)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", clear)
	t.set_stylebox("normal", "Button", box(Color(0.07, 0.03, 0.05, 0.86), GOLD))
	t.set_stylebox("hover", "Button", box(Color(0.16, 0.05, 0.08, 0.92), GOLD))
	t.set_stylebox("pressed", "Button", box(Color(0.3, 0.06, 0.1, 0.96), Color.WHITE))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return t


static func label(text: String, size := 28, color := Color.WHITE, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func button(text: String, min_size := Vector2(300, 74), font_size := 32) -> Button:
	var b := GButton.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	return b


static func bar(fill: Color, height := 26.0, reverse := false) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size = Vector2(0, height)
	p.show_percentage = false
	p.min_value = 0.0
	p.max_value = 100.0
	p.value = 100.0
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if reverse:
		p.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	var bg := box(Color(0, 0, 0, 0.65), Color.WHITE, 6, 2)
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	var fg := box(fill, fill.lightened(0.3), 5, 0)
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0
	p.add_theme_stylebox_override("background", bg)
	p.add_theme_stylebox_override("fill", fg)
	return p


## شريط صحة بذيل أبيض متأخر (تأثير الضرر).
static func hp_bar(reverse := false) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = Vector2(0, 30)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ghost := bar(Color("#ffffff"), 30.0, reverse)
	var fill := bar(Color("#e63946"), 30.0, reverse)
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(0, 0, 0, 0)
	fill.add_theme_stylebox_override("background", clear)
	for b in [ghost, fill]:
		b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(b)
	return {"root": root, "fill": fill, "ghost": ghost}
