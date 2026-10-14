extends Control
## شاشة القتال: العالم + الكاميرا + الـ HUD + الجولات + الأركيد.

const FLOOR_RATIO := 0.855
const ROUND_TIME := 60.0
const ROUNDS_TO_WIN := 2

enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END }


class Spark extends Node2D:
	var life := 0.0
	var blocked := false
	var big := 1.0

	func _process(delta: float) -> void:
		life += delta
		queue_redraw()
		if life > 0.22:
			queue_free()

	func _draw() -> void:
		var t := life / 0.22
		var col := Color(1.0, 0.9, 0.4, 1.0 - t)
		if blocked:
			col = Color(0.6, 0.85, 1.0, 1.0 - t)
		for i in 9:
			var a := TAU * float(i) / 9.0 + 0.3
			var r0 := (10.0 + 42.0 * t) * big
			var r1 := r0 + (30.0 * (1.0 - t) + 8.0) * big
			draw_line(Vector2(cos(a), sin(a)) * r0, Vector2(cos(a), sin(a)) * r1, col, (5.0 * (1.0 - t) + 1.0) * big)


class Shockwave extends Node2D:
	var life := 0.0

	func _process(delta: float) -> void:
		life += delta
		queue_redraw()
		if life > 0.5:
			queue_free()

	func _draw() -> void:
		var t := life / 0.5
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.26))
		draw_arc(Vector2.ZERO, 40.0 + 300.0 * t, 0.0, TAU, 48, Color(1.0, 0.85, 0.5, 1.0 - t), 10.0 * (1.0 - t) + 2.0, true)
		draw_arc(Vector2.ZERO, 20.0 + 220.0 * t, 0.0, TAU, 48, Color(1, 1, 1, 0.7 * (1.0 - t)), 5.0, true)


class Slipper extends Node2D:
	var dir := 1
	var dmg := 20.0
	var owner_f: Fighter
	var life := 0.0

	func _process(delta: float) -> void:
		life += delta
		rotation += float(dir) * 15.0 * delta
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 22:
			var a := TAU * float(i) / 22.0
			pts.append(Vector2(cos(a) * 30.0, sin(a) * 13.0))
		draw_colored_polygon(pts, Color("#7a4a22"))
		var inner := PackedVector2Array()
		for i in 22:
			var a2 := TAU * float(i) / 22.0
			inner.append(Vector2(cos(a2) * 24.0, sin(a2) * 8.0))
		draw_colored_polygon(inner, Color("#d9a65f"))
		draw_line(Vector2(-6, -8), Vector2(8, 0), Color("#3b2410"), 5.0)
		draw_line(Vector2(-6, 8), Vector2(8, 0), Color("#3b2410"), 5.0)


var main
var cfg: Dictionary = {}
var auto_test := false

var world: Node2D
var bg_sprite: Sprite2D
var f1: Fighter
var f2: Fighter
var ai := FighterAI.new()
var ai1 := FighterAI.new()
var touch: TouchControls
var projectiles: Array = []

var phase: int = Phase.INTRO
var phase_t := 0.0
var round_no := 1
var wins := [0, 0]
var time_left := ROUND_TIME
var paused := false
var shake := 0.0
var hitstop := 0.0
var zoom := 1.0
var zoom_kick := 0.0
var match_time := 0.0
var frozen := false
var slowmo_active := false

var hud: Control
var hp1: Dictionary
var hp2: Dictionary
var ghost1 := 100.0
var ghost2 := 100.0
var ghost_delay1 := 0.0
var ghost_delay2 := 0.0
var last_hp1 := 100.0
var last_hp2 := 100.0
var mt1: ProgressBar
var mt2: ProgressBar
var pips1: Label
var pips2: Label
var timer_lbl: Label
var banner: Label
var sub_banner: Label
var combo1: Label
var combo2: Label
var combo_t1 := 0.0
var combo_t2 := 0.0
var flash_rect: ColorRect
var pause_btn: Button
var overlay: Control = null
var vs_splash: Control = null
var p1_won_match := false


func _ready() -> void:
	cfg = main.match_cfg if main != null and not main.match_cfg.is_empty() else {
		"mode": "versus", "p1": "el_shahat", "p2": "el_behe", "stage": 0, "diff": 1, "boss": false, "idx": 0, "total": 1,
	}
	ai.difficulty = clampi(int(cfg["diff"]), 0, 3)
	ai1.difficulty = 2

	world = Node2D.new()
	add_child(world)
	bg_sprite = Sprite2D.new()
	bg_sprite.texture = load(GameData.STAGES[int(cfg["stage"])]["file"])
	bg_sprite.z_index = -10
	world.add_child(bg_sprite)

	f1 = Fighter.new()
	f2 = Fighter.new()
	world.add_child(f1)
	world.add_child(f2)
	f1.setup(cfg["p1"])
	f2.setup(cfg["p2"])
	if cfg["boss"]:
		f2.max_hp *= 1.25
		f2.hp = f2.max_hp
		f2.base_tint = Color(1.0, 0.82, 0.82)
	for f in [f1, f2]:
		f.hit_landed.connect(_on_hit.bind(f))
		f.attack_started.connect(_on_attack.bind(f))
		f.projectile_spawned.connect(_on_projectile)
		f.fx_requested.connect(_on_fx)

	_build_hud()
	touch = TouchControls.new()
	add_child(touch)
	resized.connect(_layout)
	_layout()
	_start_round()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func on_back() -> void:
	_toggle_pause()


func _layout() -> void:
	if bg_sprite == null:
		return
	var tex := bg_sprite.texture
	var sc := maxf(size.x / tex.get_width(), size.y / tex.get_height()) * 1.0
	bg_sprite.scale = Vector2(sc, sc)
	bg_sprite.position = size / 2.0
	var floor_y := size.y * FLOOR_RATIO
	for f in [f1, f2]:
		f.position.y = floor_y
		f.bounds_l = 90.0
		f.bounds_r = size.x - 90.0


# ------------------------------------------------------------------ HUD
func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	hud.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var d1: Dictionary = GameData.CHARACTERS[cfg["p1"]]
	var d2: Dictionary = GameData.CHARACTERS[cfg["p2"]]
	var n2: String = d2["name_ar"]
	if cfg["boss"]:
		n2 = "الزعيم " + n2

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 3)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_name_lbl(d1["name_ar"], HORIZONTAL_ALIGNMENT_LEFT, Color(d1["accent"])))
	hp1 = UIKit.hp_bar(false)
	left.add_child(hp1["root"])
	mt1 = UIKit.bar(Color("#4cc9f0"), 10.0, false)
	left.add_child(mt1)
	pips1 = UIKit.label("○ ○", 24, UIKit.GOLD)
	pips1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(pips1)
	row.add_child(_face(cfg["p1"], Color(d1["accent"])))
	row.add_child(left)

	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(110, 0)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_lbl = UIKit.label("60", 54, Color.WHITE, 8)
	mid.add_child(timer_lbl)
	row.add_child(mid)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_name_lbl(n2, HORIZONTAL_ALIGNMENT_RIGHT, Color(d2["accent"])))
	hp2 = UIKit.hp_bar(true)
	right.add_child(hp2["root"])
	mt2 = UIKit.bar(Color("#4cc9f0"), 10.0, true)
	right.add_child(mt2)
	pips2 = UIKit.label("○ ○", 24, UIKit.GOLD)
	pips2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(pips2)
	row.add_child(right)
	row.add_child(_face(cfg["p2"], Color(d2["accent"])))

	banner = UIKit.label("", 120, UIKit.GOLD, 14)
	banner.anchor_left = 0.0
	banner.anchor_right = 1.0
	banner.anchor_top = 0.3
	banner.anchor_bottom = 0.3
	banner.offset_top = -90
	banner.offset_bottom = 90
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.pivot_offset = Vector2(640, 90)
	hud.add_child(banner)

	sub_banner = UIKit.label("", 46, Color.WHITE, 8)
	sub_banner.anchor_left = 0.0
	sub_banner.anchor_right = 1.0
	sub_banner.anchor_top = 0.27
	sub_banner.anchor_bottom = 0.27
	sub_banner.offset_top = -30
	sub_banner.offset_bottom = 30
	sub_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_banner.modulate.a = 0.0
	hud.add_child(sub_banner)

	combo1 = _combo_lbl(true)
	combo2 = _combo_lbl(false)

	flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash_rect)

	pause_btn = UIKit.button("II", Vector2(70, 52), 24)
	pause_btn.anchor_left = 0.5
	pause_btn.anchor_right = 0.5
	pause_btn.offset_left = -35
	pause_btn.offset_right = 35
	pause_btn.offset_top = 112
	pause_btn.offset_bottom = 164
	pause_btn.pressed.connect(_toggle_pause)
	hud.add_child(pause_btn)


func _combo_lbl(left_side: bool) -> Label:
	var l := UIKit.label("", 54, UIKit.GOLD, 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.anchor_top = 0.36
	l.anchor_bottom = 0.36
	l.offset_top = -40
	l.offset_bottom = 40
	if left_side:
		l.anchor_left = 0.0
		l.anchor_right = 0.0
		l.offset_left = 24
		l.offset_right = 300
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		l.anchor_left = 1.0
		l.anchor_right = 1.0
		l.offset_left = -300
		l.offset_right = -24
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.modulate.a = 0.0
	hud.add_child(l)
	return l


func _face(id: String, accent: Color) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(92, 92)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UIKit.box(Color(0, 0, 0, 0.6), accent, 8, 4)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	frame.add_theme_stylebox_override("panel", sb)
	var t := TextureRect.new()
	t.texture = GameData.portrait(id)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(t)
	return frame


func _name_lbl(t: String, align: int, col: Color) -> Label:
	var l := UIKit.label(t, 30, col, 6)
	l.horizontal_alignment = align as HorizontalAlignment
	return l


func _pips(n: int) -> String:
	var a := "●" if n >= 1 else "○"
	var b := "●" if n >= 2 else "○"
	return a + " " + b


func _pop_banner(text: String, col := UIKit.GOLD) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", col)
	banner.scale = Vector2(1.7, 1.7)
	banner.modulate.a = 0.0
	var tw := banner.create_tween().set_parallel(true)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner, "modulate:a", 1.0, 0.12)


func _flash_text(text: String, col: Color) -> void:
	sub_banner.text = text
	sub_banner.add_theme_color_override("font_color", col)
	sub_banner.modulate.a = 1.0
	var tw := sub_banner.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(sub_banner, "modulate:a", 0.0, 0.35)


# ------------------------------------------------------------------ الجولات
func _start_round() -> void:
	var cx := size.x / 2.0
	f1.reset(cx - 190.0, 1)
	f2.reset(cx + 190.0, -1)
	for p in projectiles:
		if is_instance_valid(p):
			p.queue_free()
	projectiles.clear()
	time_left = ROUND_TIME
	phase = Phase.INTRO
	phase_t = 0.0
	last_hp1 = 100.0
	last_hp2 = 100.0
	ghost1 = 100.0
	ghost2 = 100.0
	_pop_banner("الجولة %d" % round_no)
	if main != null:
		main.sfx.play("bell")
	touch.clear_all()
	if round_no == 1 and wins[0] == 0 and wins[1] == 0:
		_show_vs_splash()
	_update_hud(0.0)


func _show_vs_splash() -> void:
	vs_splash = Control.new()
	vs_splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vs_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(vs_splash)
	hud.move_child(vs_splash, 0)
	var d1: Dictionary = GameData.CHARACTERS[cfg["p1"]]
	var d2: Dictionary = GameData.CHARACTERS[cfg["p2"]]
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.anchor_right = 1.0
	strip.anchor_top = 0.42
	strip.anchor_bottom = 0.64
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vs_splash.add_child(strip)
	var l := UIKit.label(d1["name_ar"], 64, Color(d1["accent"]), 10)
	l.anchor_top = 0.42
	l.anchor_bottom = 0.64
	l.anchor_left = 0.05
	l.anchor_right = 0.4
	vs_splash.add_child(l)
	var r := UIKit.label(("الزعيم " if cfg["boss"] else "") + d2["name_ar"], 64, Color(d2["accent"]), 10)
	r.anchor_top = 0.42
	r.anchor_bottom = 0.64
	r.anchor_left = 0.6
	r.anchor_right = 0.95
	vs_splash.add_child(r)
	var vs := UIKit.label("VS", 80, Color.WHITE, 12)
	vs.anchor_top = 0.42
	vs.anchor_bottom = 0.64
	vs.anchor_left = 0.4
	vs.anchor_right = 0.6
	vs_splash.add_child(vs)
	if cfg["mode"] == "arcade":
		var m := UIKit.label("المباراة %d من %d" % [int(cfg["idx"]) + 1, int(cfg["total"])], 34, UIKit.GOLD, 6)
		m.anchor_left = 0.0
		m.anchor_right = 1.0
		m.anchor_top = 0.65
		m.anchor_bottom = 0.72
		vs_splash.add_child(m)
	vs_splash.modulate.a = 0.0
	var tw := vs_splash.create_tween()
	tw.tween_property(vs_splash, "modulate:a", 1.0, 0.25)


func _hide_vs_splash() -> void:
	if vs_splash != null:
		var s := vs_splash
		vs_splash = null
		var tw := s.create_tween()
		tw.tween_property(s, "modulate:a", 0.0, 0.2)
		tw.tween_callback(s.queue_free)


func _physics_process(delta: float) -> void:
	if paused:
		return
	var empty := {"move": 0, "block": false, "punch": false, "kick": false, "special": false}
	if hitstop > 0.0:
		hitstop -= delta
		_set_frozen(true)
		_update_camera(delta)
		_update_hud(delta)
		return
	_set_frozen(false)
	phase_t += delta
	match phase:
		Phase.INTRO:
			f1.update(delta, empty, f2)
			f2.update(delta, empty, f1)
			if phase_t > 1.3 and banner.text != "قاتل!":
				_pop_banner("قاتل!", Color("#ff5a3c"))
				_hide_vs_splash()
			if phase_t > 2.0:
				banner.text = ""
				phase = Phase.FIGHT
				phase_t = 0.0
		Phase.FIGHT:
			time_left -= delta
			match_time += delta
			var c1: Dictionary = touch.get_cmd()
			if auto_test:
				c1 = ai1.get_cmd(f1, f2, delta)
			var c2: Dictionary = ai.get_cmd(f2, f1, delta)
			f1.update(delta, c1, f2)
			f2.update(delta, c2, f1)
			_update_projectiles(delta)
			if f1.hp <= 0.0 or f2.hp <= 0.0 or time_left <= 0.0:
				_end_round()
		Phase.ROUND_END:
			f1.update(delta, empty, f2)
			f2.update(delta, empty, f1)
			_update_projectiles(delta)
			if phase_t > 2.8:
				if wins[0] >= ROUNDS_TO_WIN or wins[1] >= ROUNDS_TO_WIN:
					_end_match()
				else:
					round_no += 1
					_start_round()
		Phase.MATCH_END:
			f1.update(delta, empty, f2)
			f2.update(delta, empty, f1)
	_update_camera(delta)
	_update_hud(delta)


func _set_frozen(b: bool) -> void:
	if b == frozen:
		return
	frozen = b
	f1.set_frozen(b)
	f2.set_frozen(b)


func _update_camera(delta: float) -> void:
	var dist := absf(f1.position.x - f2.position.x)
	var target := lerpf(1.28, 1.0, clampf((dist - 220.0) / 520.0, 0.0, 1.0))
	if phase == Phase.INTRO:
		target = 1.0
	zoom = lerpf(zoom, target + zoom_kick, minf(delta * 6.0, 1.0))
	zoom_kick = move_toward(zoom_kick, 0.0, delta * 0.4)
	var mid := (f1.position.x + f2.position.x) / 2.0
	var pos := Vector2(size.x / 2.0 - mid * zoom, size.y / 2.0 * (1.0 - zoom))
	pos.x = clampf(pos.x, size.x * (1.0 - zoom), 0.0)
	pos.y = clampf(pos.y, size.y * (1.0 - zoom), 0.0)
	if shake > 0.1:
		pos += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
		shake = move_toward(shake, 0.0, 60.0 * delta)
	world.scale = Vector2(zoom, zoom)
	world.position = pos


func _end_round() -> void:
	phase = Phase.ROUND_END
	phase_t = 0.0
	var ko := f1.hp <= 0.0 or f2.hp <= 0.0
	var h1 := f1.hp / f1.max_hp
	var h2 := f2.hp / f2.max_hp
	var winner := -1
	if f1.hp <= 0.0 and f2.hp <= 0.0:
		winner = -1
	elif f2.hp <= 0.0:
		winner = 0
	elif f1.hp <= 0.0:
		winner = 1
	elif h1 > h2:
		winner = 0
	elif h2 > h1:
		winner = 1
	if winner >= 0:
		wins[winner] += 1
	var msg := ""
	if ko:
		msg = "KO!"
		if main != null:
			main.sfx.play("ko")
		shake = 16.0
		_start_slowmo()
	else:
		msg = "انتهى الوقت"
	if winner < 0:
		msg += "\nتعادل"
	elif winner == 0 and f1.hp >= f1.max_hp - 0.01:
		msg += "\nبدون خدش!"
	_pop_banner(msg, Color("#ff5a3c") if ko else UIKit.GOLD)


func _start_slowmo() -> void:
	if slowmo_active:
		return
	slowmo_active = true
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.9, true, false, true).timeout
	Engine.time_scale = 1.0
	slowmo_active = false


func _end_match() -> void:
	phase = Phase.MATCH_END
	p1_won_match = wins[0] > wins[1]
	_pop_banner("كسبت!" if p1_won_match else "خسرت!", Color("#7CFC7C") if p1_won_match else Color("#ff6b6b"))
	if auto_test:
		return
	# حفظ التقدم
	if p1_won_match:
		SaveData.wins += 1
	else:
		SaveData.losses += 1
	SaveData.best_combo = maxi(SaveData.best_combo, f1.max_combo)
	var finished_arcade := false
	if cfg["mode"] == "arcade" and p1_won_match and int(cfg["idx"]) + 1 >= int(cfg["total"]):
		SaveData.arcade_clears += 1
		finished_arcade = true
	SaveData.save()
	await get_tree().create_timer(1.2, true).timeout
	_show_end_panel(finished_arcade)


func _stats_text() -> String:
	return "ضربات: %d     أطول كومبو: %d     ضرر: %d     الوقت: %d ث" % [f1.hits_landed, f1.max_combo, int(f1.dmg_dealt), int(match_time)]


func _show_end_panel(finished_arcade: bool) -> void:
	var items: Array = []
	var title := ""
	if cfg["mode"] == "arcade":
		if p1_won_match and finished_arcade:
			title = "كسبت البطولة!"
			items = [["القائمة الرئيسية", func(): main.goto_menu()]]
		elif p1_won_match:
			title = "كسبت المباراة"
			items = [
				["المباراة اللي بعدها", func(): main.arcade_next()],
				["القائمة الرئيسية", func(): main.goto_menu()],
			]
		else:
			title = "اتهزمت"
			items = [
				["حاول تاني", func(): main.goto_fight()],
				["القائمة الرئيسية", func(): main.goto_menu()],
			]
	else:
		title = ("فاز " if p1_won_match else "فاز ") + GameData.CHARACTERS[f1.char_id if p1_won_match else f2.char_id]["name_ar"]
		items = [
			["إعادة المباراة", func(): main.goto_fight()],
			["اختيار المقاتل", func(): main.open_select("versus")],
			["القائمة الرئيسية", func(): main.goto_menu()],
		]
	overlay = _panel_overlay(title, items, _stats_text())


func _panel_overlay(title: String, items: Array, sub := "") -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)
	v.add_child(UIKit.label(title, 60, UIKit.GOLD, 8))
	if sub != "":
		v.add_child(UIKit.label(sub, 24, Color(1, 1, 1, 0.9)))
	for it in items:
		var b := UIKit.button(it[0], Vector2(400, 70), 30)
		b.pressed.connect(it[1])
		v.add_child(b)
	return dim


func _toggle_pause() -> void:
	if phase == Phase.MATCH_END or main == null:
		return
	paused = not paused
	if paused:
		touch.clear_all()
		overlay = _panel_overlay("إيقاف مؤقت", [
			["كمّل", func(): _toggle_pause()],
			["القائمة الرئيسية", func(): main.goto_menu()],
		])
	elif overlay != null:
		overlay.queue_free()
		overlay = null


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()


# ------------------------------------------------------------------ تأثيرات
func _on_hit(kind: String, blocked: bool, pos: Vector2, dmg: float, victim: Fighter) -> void:
	var sp := Spark.new()
	sp.blocked = blocked
	sp.big = 1.6 if kind == "special" else 1.0
	sp.position = world.to_local(pos)
	sp.z_index = 20
	world.add_child(sp)
	var a: Dictionary = GameData.ATTACKS.get(kind, GameData.ATTACKS["punch"])
	var sh: float = float(a["shake"])
	if kind == "special":
		sh = 14.0
	shake = maxf(shake, sh * (0.4 if blocked else 1.0))
	hitstop = maxf(hitstop, 0.03 if blocked else (0.05 if kind == "punch" else (0.08 if kind == "kick" else 0.16)))
	_popup("صد" if blocked else str(int(round(dmg))), sp.position + Vector2(0, -30), Color("#7fd8ff") if blocked else (Color("#ffd23f") if kind != "punch" else Color.WHITE), 38 if kind == "special" else 30)
	if main != null:
		main.sfx.play("block" if blocked else ("punch" if kind == "punch" else ("kick" if kind == "kick" else "shock")))
	if victim == f1 and not blocked and SaveData.vibrate and main != null:
		Input.vibrate_handheld(40 if kind != "special" else 120)
	var atk_f := f2 if victim == f1 else f1
	if not blocked and atk_f.combo_count >= 2:
		_show_combo(atk_f == f1, atk_f.combo_count)


func _show_combo(left_side: bool, n: int) -> void:
	var l := combo1 if left_side else combo2
	l.text = "%d كومبو!" % n
	l.pivot_offset = Vector2(0 if left_side else 276, 40)
	l.scale = Vector2(1.5, 1.5)
	l.modulate.a = 1.0
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.14)
	tw.tween_interval(0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	if main != null:
		main.sfx.play("combo")


func _popup(text: String, pos: Vector2, col: Color, size_px: int) -> void:
	var l := UIKit.label(text, size_px, col, 8)
	l.size = Vector2(160, 50)
	l.position = pos - Vector2(80, 25)
	l.z_index = 40
	world.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)


func _on_attack(kind: String, who: Fighter) -> void:
	if main != null:
		main.sfx.play("special" if kind == "special" else "whoosh")
	if kind == "special":
		hitstop = maxf(hitstop, 0.22)
		zoom_kick = 0.12
		var accent := Color(who.stats["accent"])
		flash_rect.color = Color(accent.r, accent.g, accent.b, 0.35)
		var tw := flash_rect.create_tween()
		tw.tween_property(flash_rect, "color:a", 0.0, 0.35)
		_flash_text(String(who.stats["special_name"]), accent)


func _on_projectile(owner_f: Fighter, pos: Vector2, dir: int, dmg: float) -> void:
	var s := Slipper.new()
	s.dir = dir
	s.dmg = dmg
	s.owner_f = owner_f
	s.position = world.to_local(pos)
	s.z_index = 15
	world.add_child(s)
	projectiles.append(s)
	if main != null:
		main.sfx.play("slipper")


func _on_fx(fx_name: String, pos: Vector2) -> void:
	if fx_name == "shockwave":
		var w := Shockwave.new()
		w.position = world.to_local(pos)
		w.z_index = -2
		world.add_child(w)
		shake = maxf(shake, 18.0)
		if main != null:
			main.sfx.play("shock")


func _update_projectiles(delta: float) -> void:
	for p in projectiles.duplicate():
		if not is_instance_valid(p):
			projectiles.erase(p)
			continue
		p.position.x += float(p.dir) * 760.0 * delta
		var foe: Fighter = f2 if p.owner_f == f1 else f1
		var done := false
		if foe.is_alive() and absf(p.position.x - foe.position.x) < 52.0:
			var info := {"kind": "special", "dmg": p.dmg, "knock": 330.0, "stun": 0.5, "side": -p.dir}
			if foe.take_hit(p.owner_f, info):
				done = true
		if p.position.x < -80.0 or p.position.x > size.x + 80.0 or p.life > 1.6:
			done = true
		if done:
			projectiles.erase(p)
			p.queue_free()


func _update_hud(delta: float) -> void:
	var v1 := f1.hp / f1.max_hp * 100.0
	var v2 := f2.hp / f2.max_hp * 100.0
	hp1["fill"].value = v1
	hp2["fill"].value = v2
	# ذيل الضرر: يستنى لحظة وبعدين يلحق
	if v1 < last_hp1 - 0.01:
		ghost_delay1 = 0.45
	if v2 < last_hp2 - 0.01:
		ghost_delay2 = 0.45
	last_hp1 = v1
	last_hp2 = v2
	ghost_delay1 -= delta
	ghost_delay2 -= delta
	if ghost_delay1 <= 0.0:
		ghost1 = move_toward(ghost1, v1, 45.0 * delta)
	if ghost_delay2 <= 0.0:
		ghost2 = move_toward(ghost2, v2, 45.0 * delta)
	ghost1 = maxf(ghost1, v1)
	ghost2 = maxf(ghost2, v2)
	hp1["ghost"].value = ghost1
	hp2["ghost"].value = ghost2
	mt1.value = f1.meter
	mt2.value = f2.meter
	mt1.modulate = Color(1.6, 1.6, 0.8) if f1.meter >= GameData.METER_COST else Color.WHITE
	mt2.modulate = Color(1.6, 1.6, 0.8) if f2.meter >= GameData.METER_COST else Color.WHITE
	pips1.text = _pips(wins[0])
	pips2.text = _pips(wins[1])
	timer_lbl.text = str(maxi(int(ceil(time_left)), 0))
	touch.special_ready = f1.meter >= GameData.METER_COST
