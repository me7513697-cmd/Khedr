class_name Rig
extends Node2D
## شخصية كرتونية متحركة بالكود: الراس من صورة حقيقية والجسم والأطراف مرسومة.
## بتبص يمين دايمًا (الـ Fighter هو اللي بيقلبها). الوحدات بالبكسل قبل التكبير.

const THIGH := 26.0
const SHIN := 26.0
const UARM := 20.0
const FARM := 19.0
const TORSO := 38.0
const OUTLINE := Color(0.08, 0.05, 0.05)
const OW := 2.6

const BASE := {
	"shift": 0.0, "lean": 6.0, "bob": 0.0, "rot": 0.0, "htilt": 0.0, "hx": 0.0, "hy": 0.0,
	"fa_u": 35.0, "fa_l": 125.0, "ba_u": 15.0, "ba_l": 105.0,
	"ff_u": 22.0, "ff_l": 8.0, "bf_u": -24.0, "bf_l": -10.0,
}

var char_id := ""
var animation := "idle"
var t := 0.0
var playing := true
var speed_scale := 1.0
var special_type := "rush"
var look: Dictionary = {}
var head_tex: Texture2D
var head_size := Vector2(40, 46)
var J: Dictionary = {}
var _pose_name := ""


static func _look(id: String) -> Dictionary:
	match id:
		"el_khawaga":
			return {
				"skin": Color("#d9a67d"), "torso": Color("#3b2d52"), "sleeve_u": Color("#3b2d52"), "sleeve_l": Color("#3b2d52"),
				"pants": Color("#d9a67d"), "shoe": Color("#8b5a2b"), "head_h": 49.0, "limb_w": 9.0, "leg_w": 10.5,
				"sw": 28.0, "hw": 30.0, "dress": true, "hem": 46.0, "hand_r": 6.5,
			}
		"el_behe":
			return {
				"skin": Color("#c68f68"), "torso": Color("#24384f"), "sleeve_u": Color("#c68f68"), "sleeve_l": Color("#c68f68"),
				"pants": Color("#6d5a47"), "shoe": Color("#2a2a2a"), "head_h": 52.0, "limb_w": 12.0, "leg_w": 14.0,
				"sw": 40.0, "hw": 38.0, "belly": true, "hand_r": 8.0,
			}
		_:
			return {
				"skin": Color("#d7a283"), "torso": Color("#1d2128"), "sleeve_u": Color("#1d2128"), "sleeve_l": Color("#d62828"),
				"pants": Color("#2f3550"), "shoe": Color("#f2f2f2"), "head_h": 47.0, "limb_w": 9.0, "leg_w": 11.5,
				"sw": 30.0, "hw": 26.0, "red_neck": true, "hand_r": 6.5,
			}


func setup(id: String) -> void:
	char_id = id
	look = _look(id)
	special_type = GameData.CHARACTERS[id]["special_type"]
	head_tex = GameData.head(id)
	var hh: float = look["head_h"]
	var asp := float(head_tex.get_width()) / float(head_tex.get_height())
	head_size = Vector2(hh * asp, hh)
	_update()


func play(anim: String) -> void:
	var cfg: Dictionary = GameData.ANIMS[anim]
	if animation == anim and playing and cfg["loop"] and _pose_name == "":
		return
	animation = anim
	t = 0.0
	playing = true
	_pose_name = ""
	_update()


func show_pose(pose_name: String) -> void:
	_pose_name = pose_name
	playing = false
	_update()


func pause() -> void:
	playing = false


func make_ghost() -> Rig:
	var g := Rig.new()
	g.setup(char_id)
	g.animation = animation
	g.t = t
	g._pose_name = _pose_name
	g.playing = false
	g._update()
	return g


func _process(delta: float) -> void:
	if playing:
		t += delta * speed_scale
	_update()


# ---------- الوضعيات ----------
static func _mk(d: Dictionary) -> Dictionary:
	return BASE.merged(d, true)


func _keys(keys: Array, p: float) -> Dictionary:
	p = clampf(p, 0.0, 1.0)
	for i in range(1, keys.size()):
		var k1: Array = keys[i]
		if p <= float(k1[0]) or i == keys.size() - 1:
			var k0: Array = keys[i - 1]
			var span := maxf(float(k1[0]) - float(k0[0]), 0.0001)
			var w := clampf((p - float(k0[0])) / span, 0.0, 1.0)
			w = w * w * (3.0 - 2.0 * w)
			var a := _mk(k0[1])
			var b := _mk(k1[1])
			var out := {}
			for key in a.keys():
				out[key] = lerpf(float(a[key]), float(b[key]), w)
			return out
	return _mk({})


func _pose() -> Dictionary:
	if _pose_name == "hurt":
		var j := sin(t * 38.0) * 1.2
		return _mk({"lean": -24.0, "shift": -5.0 + j, "htilt": -16.0, "hx": -3.0, "fa_u": 70.0, "fa_l": 25.0,
			"ba_u": 25.0, "ba_l": -15.0, "ff_u": 14.0, "ff_l": -12.0, "bf_u": -32.0, "bf_l": -4.0})
	var cfg: Dictionary = GameData.ANIMS[animation]
	var dur: float = float(cfg.get("dur", 1.0))
	var p := clampf(t / dur, 0.0, 1.0)
	match animation:
		"idle":
			var b := sin(t * TAU / 1.1)
			return _mk({"bob": -1.4 * b, "lean": 6.0 + 1.2 * b, "fa_u": 35.0 + 3.0 * b, "ba_u": 15.0 - 2.0 * b})
		"walk":
			var ph := t * TAU / 0.8
			var s := sin(ph)
			var c := cos(ph)
			return _mk({
				"bob": -2.0 * absf(c), "lean": 6.0,
				"ff_u": 14.0 + 26.0 * s, "ff_l": 14.0 + 26.0 * s - 38.0 * maxf(0.0, c),
				"bf_u": 14.0 - 26.0 * s, "bf_l": 14.0 - 26.0 * s + 38.0 * minf(0.0, c),
				"fa_u": 35.0 - 8.0 * s, "ba_u": 15.0 + 8.0 * s,
			})
		"run":
			var ph2 := t * TAU / 0.5
			var s2 := sin(ph2)
			var c2 := cos(ph2)
			return _mk({
				"bob": -4.0 * absf(c2), "lean": 17.0, "shift": 3.0,
				"ff_u": 10.0 + 44.0 * s2, "ff_l": 10.0 + 44.0 * s2 - 70.0 * maxf(0.0, c2),
				"bf_u": 10.0 - 44.0 * s2, "bf_l": 10.0 - 44.0 * s2 + 70.0 * minf(0.0, c2),
				"fa_u": 50.0 - 30.0 * s2, "fa_l": 120.0 - 20.0 * s2, "ba_u": 40.0 + 30.0 * s2, "ba_l": 120.0 + 20.0 * s2,
			})
		"block":
			var b2 := sin(t * TAU / 1.0)
			return _mk({
				"bob": -0.8 * b2, "lean": -3.0, "hy": 3.0, "htilt": 4.0,
				"fa_u": 55.0, "fa_l": 172.0, "ba_u": 45.0, "ba_l": 165.0,
				"ff_u": 46.0, "ff_l": -14.0, "bf_u": -36.0, "bf_l": 6.0,
			})
		"punch":
			return _keys([
				[0.0, {}],
				[0.18, {"shift": -5.0, "lean": -4.0, "fa_u": -25.0, "fa_l": 50.0, "ba_u": 50.0, "ba_l": 150.0}],
				[0.36, {"shift": 14.0, "lean": 20.0, "fa_u": 90.0, "fa_l": 90.0, "ba_u": -20.0, "ba_l": 30.0,
					"ff_u": 38.0, "ff_l": 12.0, "bf_u": -38.0, "bf_l": -22.0}],
				[0.6, {"shift": 14.0, "lean": 20.0, "fa_u": 90.0, "fa_l": 90.0, "ba_u": -20.0, "ba_l": 30.0,
					"ff_u": 38.0, "ff_l": 12.0, "bf_u": -38.0, "bf_l": -22.0}],
				[1.0, {}],
			], p)
		"kick":
			return _keys([
				[0.0, {}],
				[0.22, {"lean": -8.0, "shift": 4.0, "ff_u": 78.0, "ff_l": 14.0, "bf_u": -8.0, "bf_l": -6.0,
					"fa_u": 60.0, "fa_l": 120.0, "ba_u": 30.0, "ba_l": 90.0}],
				[0.42, {"lean": -16.0, "shift": 16.0, "ff_u": 88.0, "ff_l": 92.0, "bf_u": -4.0, "bf_l": -4.0,
					"fa_u": -35.0, "fa_l": 10.0, "ba_u": 70.0, "ba_l": 115.0}],
				[0.64, {"lean": -16.0, "shift": 16.0, "ff_u": 88.0, "ff_l": 92.0, "bf_u": -4.0, "bf_l": -4.0,
					"fa_u": -35.0, "fa_l": 10.0, "ba_u": 70.0, "ba_l": 115.0}],
				[1.0, {}],
			], p)
		"special":
			return _special(p)
		"fall":
			return _keys([
				[0.0, {"lean": -18.0, "htilt": -12.0, "shift": -3.0, "fa_u": 70.0, "fa_l": 40.0, "ba_u": -30.0, "ba_l": -50.0,
					"ff_u": 15.0, "ff_l": -15.0, "bf_u": -30.0, "bf_l": -5.0}],
				[0.3, {"rot": -40.0, "bob": -34.0, "lean": -10.0, "htilt": -25.0, "shift": -14.0, "fa_u": 120.0, "fa_l": 100.0,
					"ba_u": -100.0, "ba_l": -120.0, "ff_u": 40.0, "ff_l": 20.0, "bf_u": 10.0, "bf_l": 30.0}],
				[0.62, {"rot": -88.0, "bob": -2.0, "lean": 0.0, "htilt": -5.0, "shift": -30.0, "fa_u": 100.0, "fa_l": 130.0,
					"ba_u": -80.0, "ba_l": -100.0, "ff_u": 30.0, "ff_l": 20.0, "bf_u": 15.0, "bf_l": 5.0}],
				[1.0, {"rot": -90.0, "bob": 0.0, "lean": 0.0, "htilt": 0.0, "shift": -34.0, "fa_u": 160.0, "fa_l": 170.0,
					"ba_u": -150.0, "ba_l": -170.0, "ff_u": 5.0, "ff_l": 0.0, "bf_u": -5.0, "bf_l": 0.0}],
			], p)
	return _mk({})


func _special(p: float) -> Dictionary:
	match special_type:
		"slipper":
			return _keys([
				[0.0, {}],
				[0.28, {"lean": -12.0, "shift": -6.0, "fa_u": -140.0, "fa_l": -120.0, "ba_u": 50.0, "ba_l": 120.0,
					"ff_u": 30.0, "ff_l": 6.0, "bf_u": -34.0, "bf_l": -8.0}],
				[0.46, {"lean": 22.0, "shift": 10.0, "fa_u": 100.0, "fa_l": 92.0, "ba_u": -30.0, "ba_l": 20.0,
					"ff_u": 36.0, "ff_l": 10.0, "bf_u": -36.0, "bf_l": -20.0}],
				[0.72, {"lean": 22.0, "shift": 10.0, "fa_u": 100.0, "fa_l": 92.0, "ba_u": -30.0, "ba_l": 20.0,
					"ff_u": 36.0, "ff_l": 10.0, "bf_u": -36.0, "bf_l": -20.0}],
				[1.0, {}],
			], p)
		"slam":
			return _keys([
				[0.0, {}],
				[0.36, {"lean": -8.0, "bob": -9.0, "fa_u": 170.0, "fa_l": 176.0, "ba_u": 175.0, "ba_l": 178.0,
					"ff_u": 14.0, "ff_l": 4.0, "bf_u": -14.0, "bf_l": -4.0}],
				[0.48, {"lean": 40.0, "shift": 10.0, "fa_u": 42.0, "fa_l": 14.0, "ba_u": 36.0, "ba_l": 8.0,
					"ff_u": 56.0, "ff_l": -6.0, "bf_u": -46.0, "bf_l": -4.0}],
				[0.78, {"lean": 40.0, "shift": 10.0, "fa_u": 42.0, "fa_l": 14.0, "ba_u": 36.0, "ba_l": 8.0,
					"ff_u": 56.0, "ff_l": -6.0, "bf_u": -46.0, "bf_l": -4.0}],
				[1.0, {}],
			], p)
		_:
			return _keys([
				[0.0, {}],
				[0.16, {"lean": -10.0, "shift": -8.0, "fa_u": -30.0, "fa_l": 30.0, "ba_u": -10.0, "ba_l": 40.0,
					"ff_u": 40.0, "ff_l": -20.0, "bf_u": -45.0, "bf_l": 5.0}],
				[0.32, {"lean": 32.0, "shift": 18.0, "fa_u": 95.0, "fa_l": 95.0, "ba_u": 80.0, "ba_l": 85.0,
					"ff_u": 70.0, "ff_l": 10.0, "bf_u": -70.0, "bf_l": -60.0}],
				[0.82, {"lean": 32.0, "shift": 18.0, "fa_u": 95.0, "fa_l": 95.0, "ba_u": 80.0, "ba_l": 85.0,
					"ff_u": 70.0, "ff_l": 10.0, "bf_u": -70.0, "bf_l": -60.0}],
				[1.0, {}],
			], p)


# ---------- الهيكل (FK) ----------
static func _seg(deg: float, length: float) -> Vector2:
	var a := deg_to_rad(deg)
	return Vector2(sin(a), cos(a)) * length


func _update() -> void:
	if look.is_empty():
		return
	var P := _pose()
	var lean := deg_to_rad(float(P["lean"]))
	var hip := Vector2(float(P["shift"]), 0.0)
	var axis := Vector2(sin(lean), -cos(lean))
	var nrm := Vector2(cos(lean), sin(lean))
	var sh := hip + axis * TORSO
	var head_c := sh + axis * (head_size.y * 0.40 + 3.0) + Vector2(float(P["hx"]), float(P["hy"]))
	var sh_f := sh + nrm * 3.0
	var sh_b := sh - nrm * 3.0
	var ff_k := hip + nrm * 3.0 + _seg(P["ff_u"], THIGH)
	var ff_f := ff_k + _seg(P["ff_l"], SHIN)
	var bf_k := hip - nrm * 3.0 + _seg(P["bf_u"], THIGH)
	var bf_f := bf_k + _seg(P["bf_l"], SHIN)
	var fa_e := sh_f + _seg(P["fa_u"], UARM)
	var fa_h := fa_e + _seg(P["fa_l"], FARM)
	var ba_e := sh_b + _seg(P["ba_u"], UARM)
	var ba_h := ba_e + _seg(P["ba_l"], FARM)
	var pts := {
		"hip": hip, "sh": sh, "head": head_c, "sh_f": sh_f, "sh_b": sh_b,
		"ff_k": ff_k, "ff_f": ff_f, "bf_k": bf_k, "bf_f": bf_f,
		"fa_e": fa_e, "fa_h": fa_h, "ba_e": ba_e, "ba_h": ba_h,
	}
	var rot := deg_to_rad(float(P["rot"]))
	var ax := axis
	var nn := nrm
	if rot != 0.0:
		for k in pts.keys():
			pts[k] = hip + (pts[k] - hip).rotated(rot)
		ax = axis.rotated(rot)
		nn = nrm.rotated(rot)
	var hr: float = look["hand_r"]
	var maxy: float = -INF
	for k in ["ff_f", "bf_f"]:
		maxy = maxf(maxy, pts[k].y + 4.0)
	for k in ["fa_h", "ba_h"]:
		maxy = maxf(maxy, pts[k].y + hr)
	maxy = maxf(maxy, pts["head"].y + head_size.y * 0.5)
	maxy = maxf(maxy, pts["hip"].y + 6.0)
	var dy := -maxy + float(P["bob"])
	for k in pts.keys():
		pts[k] = pts[k] + Vector2(0.0, dy)
	pts["ax"] = ax
	pts["nn"] = nn
	pts["htilt"] = deg_to_rad(float(P["htilt"])) + lean * 0.5 + rot
	J = pts
	queue_redraw()


# ---------- الرسم ----------
func _limb(p0: Vector2, p1: Vector2, p2: Vector2, w: float, c1: Color, c2: Color) -> void:
	var ro := w * 0.5 + OW
	draw_line(p0, p1, OUTLINE, w + OW * 2.0)
	draw_line(p1, p2, OUTLINE, w + OW * 2.0)
	draw_circle(p0, ro, OUTLINE)
	draw_circle(p1, ro, OUTLINE)
	draw_circle(p2, ro, OUTLINE)
	draw_line(p0, p1, c1, w)
	draw_circle(p0, w * 0.5, c1)
	draw_circle(p1, w * 0.5, c1)
	draw_line(p1, p2, c2, w)
	draw_circle(p1, w * 0.5, c2)
	draw_circle(p2, w * 0.5, c2)


func _hand(p: Vector2) -> void:
	var r: float = look["hand_r"]
	draw_circle(p, r + OW, OUTLINE)
	draw_circle(p, r, look["skin"])


func _foot(ankle: Vector2, knee: Vector2) -> void:
	var dir := (ankle - knee).normalized().rotated(-PI / 2.0)
	var w: float = float(look["leg_w"]) * 0.8
	var tip := ankle + dir * (float(look["leg_w"]) + 3.0)
	draw_line(ankle, tip, OUTLINE, w + OW * 2.0)
	draw_circle(ankle, w * 0.5 + OW, OUTLINE)
	draw_circle(tip, w * 0.5 + OW, OUTLINE)
	draw_line(ankle, tip, look["shoe"], w)
	draw_circle(ankle, w * 0.5, look["shoe"])
	draw_circle(tip, w * 0.5, look["shoe"])


func _poly(points: PackedVector2Array, fill: Color) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, OW * 2.0)
	for p in points:
		draw_circle(p, OW, OUTLINE)
	draw_colored_polygon(points, fill)


func _draw() -> void:
	if J.is_empty():
		return
	var L := look
	var skin: Color = L["skin"]
	var hip: Vector2 = J["hip"]
	var sh: Vector2 = J["sh"]
	var ax: Vector2 = J["ax"]
	var nn: Vector2 = J["nn"]
	var lw: float = L["limb_w"]
	var gw: float = L["leg_w"]
	# الدراع الخلفي + الرجل الخلفية
	_limb(J["sh_b"], J["ba_e"], J["ba_h"], lw, L["sleeve_u"], L["sleeve_l"])
	_hand(J["ba_h"])
	_limb(J["hip"] - nn * 3.0, J["bf_k"], J["bf_f"], gw, L["pants"], L["pants"])
	_foot(J["bf_f"], J["bf_k"])
	# الجسم
	var sw: float = L["sw"]
	var hw: float = L["hw"]
	var body: PackedVector2Array
	var mid := (sh + hip) * 0.5
	if L.get("dress", false):
		var hem: float = L["hem"]
		body = PackedVector2Array([sh + nn * sw * 0.5, hip + nn * hw * 0.5, hip + Vector2(hem * 0.5, 27.0),
			hip + Vector2(-hem * 0.5, 27.0), hip - nn * hw * 0.5, sh - nn * sw * 0.5])
	elif L.get("belly", false):
		body = PackedVector2Array([sh + nn * sw * 0.5, mid + nn * (sw * 0.5 + 9.0), hip + nn * hw * 0.5,
			hip - nn * hw * 0.5, mid - nn * (sw * 0.5 - 2.0), sh - nn * sw * 0.5])
	else:
		body = PackedVector2Array([sh + nn * sw * 0.5, hip + nn * hw * 0.5, hip - nn * hw * 0.5, sh - nn * sw * 0.5])
	_poly(body, L["torso"])
	if L.get("dress", false):
		# حزام أبيض + سلاسل دهب + نقط على الفستان
		var a := hip - nn * (hw * 0.5)
		var b := hip + nn * (hw * 0.5)
		draw_line(a, b, OUTLINE, 7.0 + OW * 2.0)
		draw_line(a, b, Color("#efe9dc"), 7.0)
		var g := Color("#f2c14e")
		var n0 := sh - ax * 4.0
		draw_polyline(PackedVector2Array([n0 - nn * 7.0, sh - ax * 15.0, n0 + nn * 7.0]), g, 2.2)
		draw_polyline(PackedVector2Array([n0 - nn * 9.0, sh - ax * 22.0, n0 + nn * 9.0]), g, 2.2)
		draw_circle(sh - ax * 22.0, 2.6, g)
		var dot := Color("#8d76b8")
		for i in 6:
			var q := sh - ax * (7.0 + i * 3.4) + nn * sin(float(i) * 2.3) * 8.0
			draw_circle(q, 1.4, dot)
		for i in 4:
			draw_circle(hip + Vector2(sin(float(i) * 1.9) * 14.0, 9.0 + i * 4.5), 1.4, dot)
	elif L.get("red_neck", false):
		var vee := PackedVector2Array([sh + nn * 7.0, sh - nn * 7.0, sh - ax * 14.0])
		draw_colored_polygon(vee, Color("#d62828"))
	elif L.get("belly", false):
		draw_line(sh - nn * 3.0 - ax * 2.0, sh - nn * 3.0 - ax * 10.0, Color("#8aa0b8"), 2.0)
	# الرجل الأمامية
	_limb(J["hip"] + nn * 3.0, J["ff_k"], J["ff_f"], gw, L["pants"], L["pants"])
	_foot(J["ff_f"], J["ff_k"])
	# الرقبة + الراس
	var hc: Vector2 = J["head"]
	draw_line(sh, hc - ax * head_size.y * 0.25, OUTLINE, 7.0 + OW * 2.0)
	draw_line(sh, hc - ax * head_size.y * 0.25, skin, 7.0)
	draw_set_transform(hc, float(J["htilt"]), Vector2.ONE)
	draw_texture_rect(head_tex, Rect2(-head_size * 0.5, head_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# الدراع الأمامي
	_limb(J["sh_f"], J["fa_e"], J["fa_h"], lw, L["sleeve_u"], L["sleeve_l"])
	_hand(J["fa_h"])
