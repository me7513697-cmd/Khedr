class_name TouchControls
extends Control
## أزرار لمس متعددة (multi-touch) + كيبورد للتجربة على الكمبيوتر.

var buttons := {}
var touches := {}
var held := {"left": 0, "right": 0, "block": 0}
var oneshot := {"punch": false, "kick": false, "special": false}
var show_buttons := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	show_buttons = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var w := size.x
	var h := size.y
	var r := clampf(h * 0.092, 50.0, 78.0)
	var m := 30.0
	buttons.clear()
	# منصة الحركة على الشمال (شكل كبسولة زي شادو فايت)
	buttons["left"] = {"c": Vector2(m + r * 1.05, h - m - r), "r": r, "icon": "left"}
	buttons["right"] = {"c": Vector2(m + r * 3.25, h - m - r), "r": r, "icon": "right"}
	# أزرار الهجوم على اليمين في قوس: لكمة (كبير تحت)، ركلة، خاص، صد
	var px := w - m - r * 1.3
	var py := h - m - r * 1.15
	buttons["punch"] = {"c": Vector2(px, py), "r": r * 1.2, "icon": "fist"}
	buttons["kick"] = {"c": Vector2(px - r * 2.45, py + r * 0.15), "r": r * 1.05, "icon": "boot"}
	buttons["special"] = {"c": Vector2(px - r * 0.2, py - r * 2.3), "r": r * 0.95, "icon": "bolt"}
	buttons["block"] = {"c": Vector2(px - r * 2.35, py - r * 1.75), "r": r * 0.88, "icon": "shield"}
	queue_redraw()


func _hit(p: Vector2) -> String:
	var best := ""
	var best_d := 1e9
	for id in buttons.keys():
		var b: Dictionary = buttons[id]
		var d := p.distance_to(b["c"])
		if d <= float(b["r"]) * 1.25 and d < best_d:
			best = id
			best_d = d
	return best


func _press(id: String) -> void:
	if held.has(id):
		held[id] += 1
	elif oneshot.has(id):
		oneshot[id] = true
	queue_redraw()


func _release(id: String) -> void:
	if held.has(id):
		held[id] = maxi(held[id] - 1, 0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var ev := make_input_local(event) as InputEventScreenTouch
		if ev.pressed:
			var id := _hit(ev.position)
			if id != "":
				touches[ev.index] = id
				_press(id)
		elif touches.has(ev.index):
			_release(touches[ev.index])
			touches.erase(ev.index)
	elif event is InputEventScreenDrag:
		var ev2 := make_input_local(event) as InputEventScreenDrag
		if touches.has(ev2.index):
			var old: String = touches[ev2.index]
			var nid := _hit(ev2.position)
			if (old == "left" or old == "right") and (nid == "left" or nid == "right") and nid != old:
				_release(old)
				touches[ev2.index] = nid
				_press(nid)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J, KEY_Z:
				oneshot["punch"] = true
			KEY_K, KEY_X:
				oneshot["kick"] = true
			KEY_L, KEY_C:
				oneshot["special"] = true


func get_cmd() -> Dictionary:
	var l: bool = held["left"] > 0 or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	var r: bool = held["right"] > 0 or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	var b: bool = held["block"] > 0 or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_SPACE)
	var cmd := {
		"move": int(r) - int(l),
		"block": b,
		"punch": oneshot["punch"],
		"kick": oneshot["kick"],
		"special": oneshot["special"],
	}
	for k in oneshot.keys():
		oneshot[k] = false
	return cmd


func clear_all() -> void:
	touches.clear()
	held = {"left": 0, "right": 0, "block": 0}
	for k in oneshot.keys():
		oneshot[k] = false
	queue_redraw()


var special_ready := false
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if show_buttons and special_ready:
		queue_redraw()


func _draw() -> void:
	if not show_buttons:
		return
	var pressed_ids := touches.values()
	if held["left"] > 0 and not pressed_ids.has("left"):
		pressed_ids.append("left")
	if held["right"] > 0 and not pressed_ids.has("right"):
		pressed_ids.append("right")
	# كبسولة منصة الحركة
	var lc: Vector2 = buttons["left"]["c"]
	var rc: Vector2 = buttons["right"]["c"]
	var pr: float = buttons["left"]["r"]
	draw_circle(lc, pr * 1.12, Color(0, 0, 0, 0.28))
	draw_circle(rc, pr * 1.12, Color(0, 0, 0, 0.28))
	draw_rect(Rect2(lc.x, lc.y - pr * 1.12, rc.x - lc.x, pr * 2.24), Color(0, 0, 0, 0.28))
	for id in buttons.keys():
		var b: Dictionary = buttons[id]
		var c: Vector2 = b["c"]
		var r: float = b["r"]
		var down := pressed_ids.has(id)
		var ring := Color(1, 1, 1, 0.85)
		var glow := false
		if id == "special":
			if special_ready:
				ring = Color(1.0, 0.82, 0.25, 0.7 + 0.3 * sin(_t * 7.0))
				glow = true
			else:
				ring = Color(1, 1, 1, 0.35)
		var rr := r * (0.93 if down else 1.0)
		draw_circle(c, rr, Color(0.04, 0.04, 0.06, 0.62 if not down else 0.82))
		if glow:
			draw_circle(c, rr, Color(1.0, 0.8, 0.2, 0.18))
		draw_arc(c, rr, 0.0, TAU, 48, ring, 3.5, true)
		draw_arc(c, rr * 0.86, 0.0, TAU, 48, Color(ring, ring.a * 0.35), 1.5, true)
		var ic := Color(1, 1, 1, 0.95 if down else 0.82)
		if id == "special" and not special_ready:
			ic = Color(1, 1, 1, 0.4)
		_icon(b["icon"], c, rr * 0.5, ic)


func _poly(c: Vector2, s: float, pts: Array, col: Color) -> void:
	var p := PackedVector2Array()
	for v in pts:
		p.append(c + (v as Vector2) * s)
	draw_colored_polygon(p, col)


func _icon(kind: String, c: Vector2, s: float, col: Color) -> void:
	match kind:
		"left":
			_poly(c, s, [Vector2(0.9, -0.9), Vector2(-0.9, 0.0), Vector2(0.9, 0.9)], col)
		"right":
			_poly(c, s, [Vector2(-0.9, -0.9), Vector2(0.9, 0.0), Vector2(-0.9, 0.9)], col)
		"fist":
			draw_rect(Rect2(c + Vector2(-0.8, -0.15) * s, Vector2(1.6, 1.05) * s), col)
			for i in 4:
				draw_circle(c + Vector2(-0.6 + 0.4 * i, -0.2) * s, 0.27 * s, col)
			draw_circle(c + Vector2(0.88, 0.4) * s, 0.3 * s, col)
			draw_rect(Rect2(c + Vector2(-0.6, 0.95) * s, Vector2(1.2, 0.3) * s), Color(col, col.a * 0.6))
		"boot":
			_poly(c, s, [Vector2(-0.55, -1.0), Vector2(0.25, -1.0), Vector2(0.3, 0.05), Vector2(1.0, 0.3), Vector2(1.0, 0.85), Vector2(-0.55, 0.85)], col)
		"shield":
			_poly(c, s, [Vector2(-0.85, -0.9), Vector2(0.85, -0.9), Vector2(0.85, 0.15), Vector2(0.0, 1.0), Vector2(-0.85, 0.15)], col)
			_poly(c, s * 0.55, [Vector2(-0.7, -0.7), Vector2(0.7, -0.7), Vector2(0.7, 0.1), Vector2(0.0, 0.85), Vector2(-0.7, 0.1)], Color(0.04, 0.04, 0.06, 0.8))
		"bolt":
			_poly(c, s, [Vector2(0.2, -1.05), Vector2(-0.6, 0.1), Vector2(-0.05, 0.1), Vector2(-0.25, 1.05), Vector2(0.65, -0.25), Vector2(0.05, -0.25)], col)
