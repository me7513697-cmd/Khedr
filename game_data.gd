class_name GameData
extends RefCounted
## بيانات اللعبة: الشخصيات والمراحل والحركات.

const METER_COST := 60.0

const CHAR_ORDER: Array[String] = ["el_shahat", "el_khawaga", "el_behe"]

const CHARACTERS := {
	"el_shahat": {
		"name_ar": "اللمبي", "tag": "متوازن", "special_type": "rush", "special_name": "الهجمة المجنونة", "accent": "#e63946",
		"hp": 100.0, "speed": 300.0,
		"punch_dmg": 7.0, "kick_dmg": 11.0, "special_dmg": 22.0,
		"stars_power": 3, "stars_speed": 3, "stars_hp": 3,
	},
	"el_khawaga": {
		"name_ar": "اطاطا", "tag": "سريعة", "special_type": "slipper", "special_name": "ضربة القبقاب", "accent": "#c77dff",
		"hp": 92.0, "speed": 350.0,
		"punch_dmg": 6.0, "kick_dmg": 10.0, "special_dmg": 20.0,
		"stars_power": 2, "stars_speed": 5, "stars_hp": 2,
	},
	"el_behe": {
		"name_ar": "مليجي", "tag": "تقيل", "special_type": "slam", "special_name": "الدكّة", "accent": "#4cc9f0",
		"hp": 112.0, "speed": 245.0,
		"punch_dmg": 9.0, "kick_dmg": 13.0, "special_dmg": 26.0,
		"stars_power": 5, "stars_speed": 2, "stars_hp": 4,
	},
}

const STAGES := [
	{"id": "night", "name_ar": "كورنيش الليل", "file": "res://night.jpg"},
	{"id": "sunset", "name_ar": "كشك الغروب", "file": "res://sunset.jpg"},
	{"id": "day", "name_ar": "حارة الصبح", "file": "res://day.jpg"},
]

const DIFFICULTY_NAMES: Array[String] = ["سهل", "متوسط", "صعب"]

# حركات الأنيميشن: loop/fps للحلقات، dur (بالثواني) للضربات.
const ANIMS := {
	"idle": {"loop": true, "fps": 10.0},
	"walk": {"loop": true, "fps": 13.0},
	"run": {"loop": true, "fps": 16.0},
	"block": {"loop": true, "fps": 9.0},
	"punch": {"loop": false, "dur": 0.42},
	"kick": {"loop": false, "dur": 0.52},
	"special": {"loop": false, "dur": 0.85},
	"fall": {"loop": false, "dur": 0.9},
}

# نافذة الضرب كنسبة من مدة الحركة + المدى والدفع.
const ATTACKS := {
	"punch": {"dur": 0.42, "hit": [0.22, 0.58], "reach": 155.0, "knock": 170.0, "stun": 0.30, "lunge": 0.0, "lunge_win": [0.0, 0.0], "shake": 3.0},
	"kick": {"dur": 0.52, "hit": [0.28, 0.62], "reach": 190.0, "knock": 250.0, "stun": 0.38, "lunge": 0.0, "lunge_win": [0.0, 0.0], "shake": 6.0},
	"special": {"dur": 0.85, "hit": [0.30, 0.80], "reach": 235.0, "knock": 430.0, "stun": 0.60, "lunge": 330.0, "lunge_win": [0.12, 0.7], "shake": 12.0},
}

# أنواع الضربة الخاصة
const SPECIALS := {
	"rush": {"dur": 0.85, "hit": [0.30, 0.80], "reach": 235.0, "knock": 430.0, "stun": 0.60, "lunge": 360.0, "lunge_win": [0.12, 0.7], "shake": 12.0},
	"slipper": {"dur": 0.80, "hit": [0.40, 0.45], "reach": 0.0, "knock": 330.0, "stun": 0.50, "lunge": 0.0, "lunge_win": [0.0, 0.0], "shake": 9.0},
	"slam": {"dur": 0.95, "hit": [0.45, 0.50], "reach": 270.0, "knock": 520.0, "stun": 0.70, "lunge": 0.0, "lunge_win": [0.0, 0.0], "shake": 18.0},
}

static func head(id: String) -> Texture2D:
	return load("res://head_%s.png" % id)


static func portrait(id: String) -> Texture2D:
	return load("res://portrait_%s.png" % id)


## سلّم الأركيد: 3 مباريات، الأخيرة ضد زعيم أقوى.
static func arcade_ladder(p1: String) -> Array:
	var others: Array = []
	for id in CHAR_ORDER:
		if id != p1:
			others.append(id)
	var stages := [0, 1, 2]
	return [
		{"opp": others[0], "stage": stages[0], "boss": false, "diff_add": 0},
		{"opp": others[1], "stage": stages[1], "boss": false, "diff_add": 0},
		{"opp": others[0], "stage": stages[2], "boss": true, "diff_add": 1},
	]
