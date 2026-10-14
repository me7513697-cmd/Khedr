extends Control

var main
var btns := {}


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#150b0c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)
	v.add_child(UIKit.label("الإعدادات", 60, UIKit.GOLD, 8))
	for key in ["sound", "music", "vibrate", "difficulty"]:
		var b := UIKit.button("", Vector2(460, 70), 30)
		b.pressed.connect(_toggle.bind(key))
		v.add_child(b)
		btns[key] = b
	var reset := UIKit.button("مسح التقدم", Vector2(460, 60), 26)
	reset.pressed.connect(func():
		SaveData.reset_progress()
		reset.text = "تم المسح")
	v.add_child(reset)
	var back := UIKit.button("رجوع", Vector2(460, 66), 30)
	back.pressed.connect(func(): main.goto_menu())
	v.add_child(back)
	_refresh()


func _toggle(key: String) -> void:
	match key:
		"sound":
			SaveData.sound = not SaveData.sound
		"music":
			SaveData.music = not SaveData.music
			main.sfx.apply_settings()
		"vibrate":
			SaveData.vibrate = not SaveData.vibrate
			if SaveData.vibrate:
				Input.vibrate_handheld(60)
		"difficulty":
			SaveData.difficulty = (SaveData.difficulty + 1) % 3
	SaveData.save()
	main.sfx.play("select")
	_refresh()


func _refresh() -> void:
	btns["sound"].text = "المؤثرات: " + ("شغّالة" if SaveData.sound else "مقفولة")
	btns["music"].text = "الموسيقى: " + ("شغّالة" if SaveData.music else "مقفولة")
	btns["vibrate"].text = "الاهتزاز: " + ("شغّال" if SaveData.vibrate else "مقفول")
	btns["difficulty"].text = "الصعوبة: " + GameData.DIFFICULTY_NAMES[SaveData.difficulty]


func on_back() -> void:
	main.goto_menu()
