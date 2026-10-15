extends Control

var main
var bg: TextureRect
var t := 0.0


func _ready() -> void:
	bg = TextureRect.new()
	bg.texture = load(GameData.STAGES[1]["file"])
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.pivot_offset = Vector2(640, 360)
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	add_child(_deco(SaveData.last_char, false))
	var other := "el_behe" if SaveData.last_char != "el_behe" else "el_khawaga"
	add_child(_deco(other, true))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var title := GLabel.make("عاركة", 190, Color("#ffe03d"), Color("#ff2d78"), -0.05, true)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(title)
	var sub := GLabel.make("قتال الحواري", 50, Color.WHITE, Color("#17c3b2"), 0.03, false)
	sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	box.add_child(gap)
	var arc := UIKit.button("أركيد  (3 مباريات)", Vector2(400, 76), 34)
	arc.pressed.connect(func():
		main.sfx.play("select")
		main.open_select("arcade"))
	box.add_child(arc)
	var vs := UIKit.button("مواجهة سريعة", Vector2(400, 68), 30)
	vs.pressed.connect(func():
		main.sfx.play("select")
		main.open_select("versus"))
	box.add_child(vs)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var st := UIKit.button("الإعدادات", Vector2(194, 60), 26)
	st.pressed.connect(func():
		main.sfx.play("select")
		main.open_settings())
	row.add_child(st)
	var quit := UIKit.button("خروج", Vector2(194, 60), 26)
	quit.pressed.connect(func(): get_tree().quit())
	row.add_child(quit)
	if SaveData.wins + SaveData.losses > 0 or SaveData.arcade_clears > 0:
		box.add_child(UIKit.label("انتصارات: %d     بطولات: %d     أفضل كومبو: %d" % [SaveData.wins, SaveData.arcade_clears, SaveData.best_combo], 20, Color(1, 1, 1, 0.85)))


func _process(delta: float) -> void:
	t += delta
	var s := 1.04 + 0.025 * sin(t * 0.35)
	bg.scale = Vector2(s, s)


func on_back() -> void:
	get_tree().quit()


func _deco(id: String, flip: bool) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.anchor_top = 0.2
	c.anchor_bottom = 1.0
	if flip:
		c.anchor_left = 0.72
		c.anchor_right = 1.0
	else:
		c.anchor_left = 0.0
		c.anchor_right = 0.28
	var rig := Rig.new()
	rig.setup(id)
	c.add_child(rig)
	c.resized.connect(func():
		var sc: float = minf(c.size.y / 175.0, c.size.x / 150.0)
		rig.scale = Vector2(-sc if flip else sc, sc)
		rig.position = Vector2(c.size.x * 0.5, c.size.y - 8.0))
	return c
