extends Control

var main
var mode := "arcade"
var p1 := "el_shahat"
var p2 := "el_behe"
var stage := 0
var char_cards := {}
var opp_cards := {}
var stage_cards: Array[PanelContainer] = []
var diff_buttons: Array[Button] = []


func _ready() -> void:
	mode = main.select_mode
	p1 = SaveData.last_char
	p2 = _first_other(p1)
	var bg := ColorRect.new()
	bg.color = Color("#150b0c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var back := UIKit.button("رجوع", Vector2(150, 54), 24)
	back.pressed.connect(func(): main.goto_menu())
	top.add_child(back)
	var title := UIKit.label("اختار مقاتلك" if mode == "arcade" else "مواجهة سريعة", 44, UIKit.GOLD, 6)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	top.add_child(spacer)

	var chars := HBoxContainer.new()
	chars.alignment = BoxContainer.ALIGNMENT_CENTER
	chars.add_theme_constant_override("separation", 16)
	chars.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(chars)
	for id in GameData.CHAR_ORDER:
		var card := _char_card(id)
		chars.add_child(card)
		char_cards[id] = card

	if mode == "versus":
		var orow := HBoxContainer.new()
		orow.alignment = BoxContainer.ALIGNMENT_CENTER
		orow.add_theme_constant_override("separation", 10)
		root.add_child(orow)
		orow.add_child(UIKit.label("الخصم:", 24, Color.WHITE))
		for id in GameData.CHAR_ORDER:
			var oc := _opp_card(id)
			orow.add_child(oc)
			opp_cards[id] = oc
		var stages := HBoxContainer.new()
		stages.alignment = BoxContainer.ALIGNMENT_CENTER
		stages.add_theme_constant_override("separation", 10)
		root.add_child(stages)
		stages.add_child(UIKit.label("المرحلة:", 24, Color.WHITE))
		for i in GameData.STAGES.size():
			var sc := _stage_card(i)
			stages.add_child(sc)
			stage_cards.append(sc)
	else:
		root.add_child(UIKit.label("3 مباريات ضد خصوم بالترتيب، والأخيرة ضد زعيم أقوى", 22, Color(1, 1, 1, 0.85)))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	bottom.add_child(UIKit.label("الصعوبة:", 24, Color.WHITE))
	for i in 3:
		var b := UIKit.button(GameData.DIFFICULTY_NAMES[i], Vector2(112, 54), 22)
		b.pressed.connect(_on_diff.bind(i))
		bottom.add_child(b)
		diff_buttons.append(b)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(30, 0)
	bottom.add_child(sp2)
	var go := UIKit.button("يلا نقاتل!", Vector2(260, 60), 30)
	go.pressed.connect(_start)
	bottom.add_child(go)
	_refresh()


func _first_other(id: String) -> String:
	for c in GameData.CHAR_ORDER:
		if c != id:
			return c
	return id


func _start() -> void:
	SaveData.last_char = p1
	SaveData.save()
	main.sfx.play("bell")
	if mode == "arcade":
		main.start_arcade(p1)
	else:
		main.start_versus(p1, p2, stage)


func _clickable(card: Control, cb: Callable) -> void:
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			main.sfx.play("select")
			cb.call())


func _char_card(id: String) -> PanelContainer:
	var d: Dictionary = GameData.CHARACTERS[id]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 0)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	var img := TextureRect.new()
	img.texture = GameData.portrait(id)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	img.custom_minimum_size = Vector2(0, 100)
	v.add_child(img)
	v.add_child(UIKit.label(d["name_ar"], 32, Color(d["accent"]), 4))
	v.add_child(UIKit.label("%s   قوة %s  سرعة %s" % [d["tag"], "★".repeat(d["stars_power"]), "★".repeat(d["stars_speed"])], 16, Color(1, 1, 1, 0.85)))
	v.add_child(UIKit.label("خاصة: " + String(d["special_name"]), 16, UIKit.GOLD))
	_clickable(card, func():
		p1 = id
		if p2 == p1:
			p2 = _first_other(p1)
		_refresh())
	return card


func _opp_card(id: String) -> PanelContainer:
	var card := PanelContainer.new()
	var h := HBoxContainer.new()
	card.add_child(h)
	var img := TextureRect.new()
	img.texture = GameData.portrait(id)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.custom_minimum_size = Vector2(46, 46)
	h.add_child(img)
	h.add_child(UIKit.label(GameData.CHARACTERS[id]["name_ar"], 22, Color.WHITE))
	_clickable(card, func():
		if id != p1:
			p2 = id
			_refresh())
	return card


func _stage_card(i: int) -> PanelContainer:
	var card := PanelContainer.new()
	var v := VBoxContainer.new()
	card.add_child(v)
	var img := TextureRect.new()
	img.texture = load(GameData.STAGES[i]["file"])
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.custom_minimum_size = Vector2(150, 56)
	v.add_child(img)
	v.add_child(UIKit.label(GameData.STAGES[i]["name_ar"], 16, Color.WHITE))
	_clickable(card, func():
		stage = i
		_refresh())
	return card


func _on_diff(i: int) -> void:
	SaveData.difficulty = i
	SaveData.save()
	main.sfx.play("select")
	_refresh()


func on_back() -> void:
	main.goto_menu()


func _refresh() -> void:
	for id in char_cards.keys():
		var sel: bool = p1 == id
		char_cards[id].add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.RED, 0.55) if sel else Color(1, 1, 1, 0.06), UIKit.GOLD if sel else Color(1, 1, 1, 0.25), 14, 5 if sel else 2))
	for id in opp_cards.keys():
		var sel1: bool = p2 == id
		opp_cards[id].add_theme_stylebox_override("panel", UIKit.box(Color(0, 0, 0, 0.3), UIKit.GOLD if sel1 else Color(1, 1, 1, 0.2), 10, 4 if sel1 else 2))
		opp_cards[id].modulate = Color(1, 1, 1, 0.35) if id == p1 else Color.WHITE
	for i in stage_cards.size():
		var sel2: bool = stage == i
		stage_cards[i].add_theme_stylebox_override("panel", UIKit.box(Color(0, 0, 0, 0.3), UIKit.GOLD if sel2 else Color(1, 1, 1, 0.25), 10, 4 if sel2 else 2))
	for i in diff_buttons.size():
		diff_buttons[i].modulate = Color.WHITE if SaveData.difficulty == i else Color(1, 1, 1, 0.5)
