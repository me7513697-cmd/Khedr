class_name Fighter
extends Node2D
## مقاتل: حالات + ضرب + كومبو + صد + ضربة خاصة (3 أنواع). الـ sprites بتبص يمين افتراضيًا.

signal hit_landed(kind: String, blocked: bool, world_pos: Vector2, dmg: float)
signal attack_started(kind: String)
signal projectile_spawned(owner: Fighter, pos: Vector2, dir: int, dmg: float)
signal fx_requested(fx_name: String, pos: Vector2)

enum S { IDLE, WALK, RUN, BLOCK, PUNCH, KICK, SPECIAL, HURT, KO }

const SPRITE_SCALE := 2.5
const MIN_SEP := 86.0
const METER_MAX := 100.0
const MAX_CHAIN := 3

var char_id := ""
var stats: Dictionary = {}
var sprite: Rig
var state: int = S.IDLE
var state_t := 0.0
var facing := 1
var hp := 100.0
var max_hp := 100.0
var meter := 0.0
var push_v := 0.0
var bounds_l := 60.0
var bounds_r := 1220.0
var hit_done := false
var proj_done := false
var kind_now := "punch"
var atk: Dictionary = {}
var hurt_dur := 0.3
var flash_t := 0.0
var buf := ""
var buf_t := 0.0
var chain_n := 0
var combo_count := 0
var combo_t := 0.0
var ghost_t := 0.0
var base_tint := Color.WHITE
var special_type := "rush"

# إحصائيات المباراة
var hits_landed := 0
var dmg_dealt := 0.0
var max_combo := 0


func setup(id: String) -> void:
	char_id = id
	stats = GameData.CHARACTERS[id]
	special_type = stats["special_type"]
	max_hp = stats["hp"]
	hp = max_hp
	sprite = Rig.new()
	sprite.setup(id)
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(sprite)
	_set_state(S.IDLE)
	queue_redraw()


func reset(x: float, face: int) -> void:
	position.x = x
	facing = face
	hp = max_hp
	meter = 0.0
	push_v = 0.0
	buf = ""
	buf_t = 0.0
	flash_t = 0.0
	combo_count = 0
	combo_t = 0.0
	chain_n = 0
	sprite.modulate = base_tint
	sprite.speed_scale = 1.0
	_set_state(S.IDLE)
	sprite.scale.x = SPRITE_SCALE * facing


func set_frozen(b: bool) -> void:
	sprite.speed_scale = 0.0 if b else 1.0


func is_attacking() -> bool:
	return state == S.PUNCH or state == S.KICK or state == S.SPECIAL


func is_alive() -> bool:
	return state != S.KO


func _draw() -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		pts.append(Vector2(cos(a) * 74.0, sin(a) * 13.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.38))


func _play(anim: String) -> void:
	sprite.play(anim)


func _set_state(ns: int) -> void:
	state = ns
	state_t = 0.0
	match ns:
		S.IDLE:
			_play("idle")
		S.WALK:
			_play("walk")
		S.RUN:
			_play("run")
		S.BLOCK:
			_play("block")
		S.PUNCH:
			_play("punch")
		S.KICK:
			_play("kick")
		S.SPECIAL:
			_play("special")
		S.HURT:
			sprite.show_pose("hurt")
		S.KO:
			_play("fall")


func update(delta: float, cmd: Dictionary, foe: Fighter) -> void:
	state_t += delta
	if buf_t > 0.0:
		buf_t -= delta
	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			combo_count = 0
	for k in ["punch", "kick", "special"]:
		if cmd.get(k, false):
			buf = k
			buf_t = 0.25
	if flash_t > 0.0:
		flash_t -= delta
		sprite.modulate = Color(2.0, 0.75, 0.75)
	else:
		sprite.modulate = base_tint
	match state:
		S.IDLE, S.WALK, S.RUN, S.BLOCK:
			facing = 1 if foe.position.x >= position.x else -1
			_free(delta, cmd, foe)
		S.PUNCH, S.KICK, S.SPECIAL:
			_process_attack(delta, foe)
		S.HURT:
			if state_t >= hurt_dur:
				_set_state(S.IDLE)
	if absf(push_v) > 1.0:
		_move(push_v * delta, foe)
		push_v = move_toward(push_v, 0.0, 1100.0 * delta)
	sprite.scale.x = SPRITE_SCALE * facing


func _free(delta: float, cmd: Dictionary, foe: Fighter) -> void:
	if buf_t > 0.0 and buf != "":
		var k := buf
		buf = ""
		buf_t = 0.0
		if k == "special" and meter < GameData.METER_COST:
			k = "kick"
		chain_n = 0
		start_attack(k)
		return
	if cmd.get("block", false):
		if state != S.BLOCK:
			_set_state(S.BLOCK)
		return
	var mv: int = int(cmd.get("move", 0))
	if mv == 0:
		if state != S.IDLE:
			_set_state(S.IDLE)
		return
	var toward := (mv == facing)
	var spd: float = float(stats["speed"]) * (1.0 if toward else 0.72)
	_move(mv * spd * delta, foe)
	var want: int = S.RUN if toward else S.WALK
	if state != want:
		_set_state(want)


func start_attack(kind: String) -> void:
	kind_now = kind
	hit_done = false
	proj_done = false
	ghost_t = 0.0
	if kind == "special":
		atk = GameData.SPECIALS[special_type]
		meter -= GameData.METER_COST
		_set_state(S.SPECIAL)
	elif kind == "kick":
		atk = GameData.ATTACKS["kick"]
		_set_state(S.KICK)
	else:
		atk = GameData.ATTACKS["punch"]
		_set_state(S.PUNCH)
	attack_started.emit(kind)


func _info(kind: String) -> Dictionary:
	var n := combo_count if combo_t > 0.0 else 0
	var mult := maxf(pow(0.9, float(n)), 0.55)
	var base: float = float(stats[kind + "_dmg"])
	return {
		"kind": kind,
		"dmg": base * mult,
		"knock": float(atk["knock"]),
		"stun": float(atk["stun"]),
	}


func _process_attack(delta: float, foe: Fighter) -> void:
	var dur: float = atk["dur"]
	var hw: Array = atk["hit"]
	var t0: float = float(hw[0]) * dur
	var t1: float = float(hw[1]) * dur
	# أشباح خلف الضربة الخاصة
	if kind_now == "special":
		ghost_t -= delta
		if ghost_t <= 0.0:
			ghost_t = 0.045
			if special_type == "rush":
				_spawn_ghost()
	var lw: Array = atk["lunge_win"]
	var lunge: float = atk["lunge"]
	if lunge > 0.0 and state_t >= float(lw[0]) * dur and state_t <= float(lw[1]) * dur:
		_move(float(facing) * lunge * delta, foe)
	if kind_now == "special" and special_type == "slipper":
		if not proj_done and state_t >= t0:
			proj_done = true
			hit_done = true
			projectile_spawned.emit(self, global_position + Vector2(facing * 70.0, -SPRITE_SCALE * 74.0), facing, float(stats["special_dmg"]))
	elif kind_now == "special" and special_type == "slam":
		if not hit_done and state_t >= t0:
			hit_done = true
			fx_requested.emit("shockwave", global_position)
			if absf(foe.position.x - position.x) <= float(atk["reach"]) and foe.is_alive():
				foe.take_hit(self, _info("special"))
	else:
		if not hit_done and state_t >= t0 and state_t <= t1:
			var dx := foe.position.x - position.x
			if (signf(dx) == float(facing) or absf(dx) < 20.0) and absf(dx) <= float(atk["reach"]):
				if foe.take_hit(self, _info(kind_now)):
					hit_done = true
	# كانسل في كومبو بعد الإصابة: لكمة→لكمة→ركلة، أو ضربة خاصة
	if hit_done and kind_now != "special" and buf_t > 0.0 and buf != "" and state_t >= t0 + 0.05 and chain_n < MAX_CHAIN:
		var nk := buf
		if nk == "special" and meter < GameData.METER_COST:
			nk = ""
		elif nk == "kick" and kind_now == "kick":
			nk = ""
		if nk != "":
			buf = ""
			buf_t = 0.0
			chain_n += 1
			start_attack(nk)
			return
	if state_t >= dur:
		_set_state(S.IDLE)


func _spawn_ghost() -> void:
	var par := get_parent()
	if par == null:
		return
	var g := sprite.make_ghost()
	g.scale = sprite.scale
	g.position = position
	g.z_index = -1
	g.modulate = Color(1.0, 0.85, 0.4, 0.5)
	par.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.28)
	tw.tween_callback(g.queue_free)


func register_hit(dmg: float) -> void:
	combo_count = (combo_count + 1) if combo_t > 0.0 else 1
	combo_t = 1.25
	hits_landed += 1
	dmg_dealt += dmg
	max_combo = maxi(max_combo, combo_count)


func take_hit(attacker: Fighter, info: Dictionary) -> bool:
	if state == S.KO:
		return false
	if state == S.HURT and state_t < 0.12:
		return false
	var dmg: float = info["dmg"]
	var knock: float = info["knock"]
	var kind: String = info["kind"]
	var s := signf(attacker.position.x - position.x)
	if info.has("side"):
		s = float(info["side"])
	if s == 0.0:
		s = float(-facing)
	var chest := global_position + Vector2(s * 30.0, -SPRITE_SCALE * 72.0)
	if state == S.BLOCK and facing == int(s):
		var chip := dmg * 0.12
		hp = maxf(hp - chip, 1.0)
		push_v = -s * knock * 0.45
		meter = minf(meter + 2.5, METER_MAX)
		hit_landed.emit(kind, true, chest, chip)
		return true
	hp -= dmg
	meter = minf(meter + dmg * 0.7, METER_MAX)
	attacker.meter = minf(attacker.meter + dmg * 1.0, METER_MAX)
	attacker.register_hit(dmg)
	flash_t = 0.12
	buf = ""
	buf_t = 0.0
	if hp <= 0.0:
		hp = 0.0
		push_v = -s * knock * 1.3
		_set_state(S.KO)
	else:
		push_v = -s * knock
		hurt_dur = float(info["stun"])
		_set_state(S.HURT)
	hit_landed.emit(kind, false, chest, dmg)
	return true


func _move(dx: float, foe: Fighter) -> void:
	position.x = clampf(position.x + dx, bounds_l, bounds_r)
	var d := foe.position.x - position.x
	if absf(d) < MIN_SEP:
		var s := signf(d)
		if s == 0.0:
			s = float(facing)
		position.x = clampf(foe.position.x - s * MIN_SEP, bounds_l, bounds_r)
