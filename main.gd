extends Control
## مدير الشاشات + إعدادات التشغيل (رجوع أندرويد، انتقالات، موسيقى).

const FONT := preload("res://DejaVuSans-Bold.ttf")

var current: Control = null
var sfx: Sfx
var fade: ColorRect
var busy := false
var select_mode := "arcade"
var match_cfg: Dictionary = {}
var ladder: Array = []


func _ready() -> void:
	SaveData.load_data()
	UIKit.font = FONT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	theme = UIKit.make_theme(FONT)
	sfx = Sfx.new()
	add_child(sfx)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	get_tree().quit_on_go_back = false
	DisplayServer.screen_set_keep_on(true)
	_swap(load("res://menu_screen.gd").new())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current != null and current.has_method("on_back"):
			current.call("on_back")
		else:
			goto_menu()


func _swap(scr: Control) -> void:
	if current != null:
		current.queue_free()
	current = scr
	scr.set("main", self)
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	move_child(fade, get_child_count() - 1)


func _go(path: String) -> void:
	if busy:
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.14)
	await tw.finished
	_swap(load(path).new())
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.2)
	await tw2.finished
	busy = false


func goto_menu() -> void:
	_go("res://menu_screen.gd")


func open_select(mode: String) -> void:
	select_mode = mode
	_go("res://select_screen.gd")


func open_settings() -> void:
	_go("res://settings_screen.gd")


func goto_fight() -> void:
	_go("res://fight_screen.gd")


func start_arcade(p1: String) -> void:
	ladder = GameData.arcade_ladder(p1)
	_set_arcade_match(p1, 0)
	goto_fight()


func arcade_next() -> void:
	var idx: int = int(match_cfg["idx"]) + 1
	_set_arcade_match(match_cfg["p1"], idx)
	goto_fight()


func _set_arcade_match(p1: String, idx: int) -> void:
	var step: Dictionary = ladder[idx]
	match_cfg = {
		"mode": "arcade", "p1": p1, "p2": step["opp"], "stage": step["stage"],
		"diff": SaveData.difficulty + int(step["diff_add"]), "boss": step["boss"],
		"idx": idx, "total": ladder.size(),
	}


func start_versus(p1: String, p2: String, stage: int) -> void:
	match_cfg = {
		"mode": "versus", "p1": p1, "p2": p2, "stage": stage,
		"diff": SaveData.difficulty, "boss": false, "idx": 0, "total": 1,
	}
	goto_fight()
