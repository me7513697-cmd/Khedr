class_name SaveData
extends RefCounted
## حفظ الإعدادات والتقدم في user://save.cfg

const PATH := "user://save.cfg"

static var sound := true
static var music := true
static var vibrate := true
static var difficulty := 1
static var last_char := "el_shahat"
static var arcade_clears := 0
static var wins := 0
static var losses := 0
static var best_combo := 0
static var _loaded := false


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	sound = cf.get_value("settings", "sound", true)
	music = cf.get_value("settings", "music", true)
	vibrate = cf.get_value("settings", "vibrate", true)
	difficulty = clampi(int(cf.get_value("settings", "difficulty", 1)), 0, 2)
	last_char = cf.get_value("settings", "last_char", "el_shahat")
	if not GameData.CHARACTERS.has(last_char):
		last_char = "el_shahat"
	arcade_clears = int(cf.get_value("progress", "arcade_clears", 0))
	wins = int(cf.get_value("progress", "wins", 0))
	losses = int(cf.get_value("progress", "losses", 0))
	best_combo = int(cf.get_value("progress", "best_combo", 0))


static func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("settings", "sound", sound)
	cf.set_value("settings", "music", music)
	cf.set_value("settings", "vibrate", vibrate)
	cf.set_value("settings", "difficulty", difficulty)
	cf.set_value("settings", "last_char", last_char)
	cf.set_value("progress", "arcade_clears", arcade_clears)
	cf.set_value("progress", "wins", wins)
	cf.set_value("progress", "losses", losses)
	cf.set_value("progress", "best_combo", best_combo)
	cf.save(PATH)


static func reset_progress() -> void:
	arcade_clears = 0
	wins = 0
	losses = 0
	best_combo = 0
	save()
