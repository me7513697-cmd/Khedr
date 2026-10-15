class_name GButton
extends Button
## زرار نصه مكتوب بخط جرافيتي.

var fill := Color("#ffe03d")
var edge := Color("#ff2d78")


func _draw() -> void:
	var col := fill
	if disabled:
		col = col.darkened(0.5)
	elif is_pressed() or is_hovered():
		col = Color.WHITE
	var fs := int(get_theme_font_size("font_size") * 1.2)
	Graffiti.draw_text(self, text, size * 0.5, fs, col, 0.0, edge, false, size.x - 30.0)
