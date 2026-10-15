class_name GLabel
extends Control
## عنوان بخط جرافيتي.

var text := ""
var fsize := 64
var fill := Color("#ffe03d")
var edge := Color("#ff2d78")
var tilt := 0.0
var drips := false


static func make(t: String, size: int, fill_c := Color("#ffe03d"), edge_c := Color("#ff2d78"), tilt_r := 0.0, drip := false) -> GLabel:
	var g := GLabel.new()
	g.text = t
	g.fsize = size
	g.fill = fill_c
	g.edge = edge_c
	g.tilt = tilt_r
	g.drips = drip
	var m := Graffiti.measure(t, size)
	g.custom_minimum_size = Vector2(m.x + size * 0.5, m.y + size * (0.55 if drip else 0.3))
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


func _draw() -> void:
	Graffiti.draw_text(self, text, size * 0.5 - Vector2(0, fsize * (0.12 if drips else 0.0)), fsize, fill, tilt, edge, drips, size.x - 8.0)
