class_name Graffiti
extends RefCounted
## رسم نص بستايل جرافيتي: ظل + كنتور أسود سميك + حد ملون + تعبئة + نقط دهان نازلة.


static func measure(text: String, fsize: int) -> Vector2:
	var font: Font = UIKit.font
	if font == null:
		return Vector2(fsize * text.length() * 0.6, fsize * 1.2)
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)


static func draw_text(ci: CanvasItem, text: String, center: Vector2, fsize: int, fill: Color, tilt := 0.0, edge := Color("#ff2d78"), drips := false, max_w := 0.0) -> void:
	var font: Font = UIKit.font
	if font == null or text == "":
		return
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	if max_w > 0.0 and sz.x > max_w:
		fsize = maxi(int(float(fsize) * max_w / sz.x), 8)
		sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var h := font.get_height(fsize)
	var base := Vector2(-sz.x * 0.5, -h * 0.5 + font.get_ascent(fsize))
	var o := float(fsize)
	ci.draw_set_transform(center, tilt, Vector2.ONE)
	ci.draw_string_outline(font, base + Vector2(o * 0.06, o * 0.08), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, maxi(int(o * 0.2), 3), Color(0, 0, 0, 0.5))
	ci.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, maxi(int(o * 0.19), 3), Color(0.04, 0.02, 0.05))
	ci.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, maxi(int(o * 0.1), 2), edge)
	ci.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, fill)
	# لمعة خفيفة
	ci.draw_string(font, base + Vector2(-o * 0.012, -o * 0.02), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.16))
	if drips:
		var seed_v := absi(text.hash())
		var n := clampi(int(sz.x / (o * 0.55)), 3, 7)
		for i in n:
			var r1 := float((seed_v >> (i * 3)) & 7) / 7.0
			var r2 := float((seed_v >> (i * 3 + 1)) & 7) / 7.0
			var x := -sz.x * 0.42 + sz.x * 0.84 * (float(i) + r1 * 0.6) / float(n)
			var y0 := h * 0.5 - o * 0.1
			var ln := o * (0.1 + 0.26 * r2)
			var w := o * 0.05
			ci.draw_line(Vector2(x, y0), Vector2(x, y0 + ln), Color(0.04, 0.02, 0.05), w + o * 0.05)
			ci.draw_circle(Vector2(x, y0 + ln), w * 0.5 + o * 0.025, Color(0.04, 0.02, 0.05))
			ci.draw_line(Vector2(x, y0 - o * 0.06), Vector2(x, y0 + ln), edge, w)
			ci.draw_circle(Vector2(x, y0 + ln), w * 0.5, edge)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
