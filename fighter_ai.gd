class_name FighterAI
extends RefCounted
## ذكاء اصطناعي للخصم. difficulty: 0 سهل، 1 متوسط، 2 صعب (والزعيم +1).

var difficulty := 1
var plan := "idle"
var plan_t := 0.0
var block_hold := 0.0
var chain_decided := false

const THINK := [0.55, 0.36, 0.2]
const AGGRESSION := [0.45, 0.62, 0.8]
const BLOCK_CHANCE := [0.2, 0.45, 0.7]
const CHAIN_CHANCE := [0.15, 0.4, 0.7]


func get_cmd(me: Fighter, foe: Fighter, delta: float) -> Dictionary:
	var cmd := {"move": 0, "block": false, "punch": false, "kick": false, "special": false}
	if not foe.is_alive() or not me.is_alive():
		return cmd
	var d := clampi(difficulty, 0, 2)
	var dist := absf(foe.position.x - me.position.x)
	var dir := 1 if foe.position.x > me.position.x else -1
	# كومبو: بعد ما الضربة تصيب، ممكن يكمّل بركلة أو خاصة
	if me.is_attacking():
		if me.hit_done and not chain_decided and me.kind_now != "special":
			chain_decided = true
			if randf() < float(CHAIN_CHANCE[d]):
				if me.meter >= GameData.METER_COST and randf() < 0.5:
					cmd["special"] = true
				else:
					cmd["kick" if randf() < 0.6 else "punch"] = true
		return cmd
	chain_decided = false
	plan_t -= delta
	block_hold -= delta
	if block_hold > 0.0:
		cmd["block"] = true
		return cmd
	if plan_t <= 0.0:
		plan_t = float(THINK[d]) + randf() * 0.25
		plan = _decide(me, foe, dist, d)
	match plan:
		"approach":
			cmd["move"] = dir
		"retreat":
			cmd["move"] = -dir
		"punch", "kick", "special":
			cmd[plan] = true
			plan = "idle"
			plan_t = float(THINK[d]) * 0.8
		"block":
			block_hold = 0.35 + randf() * 0.25
			plan = "idle"
	return cmd


func _decide(me: Fighter, foe: Fighter, dist: float, d: int) -> String:
	if foe.is_attacking() and dist < 250.0 and randf() < float(BLOCK_CHANCE[d]):
		return "block"
	var can_special := me.meter >= GameData.METER_COST
	if can_special and me.special_type == "slipper" and dist > 230.0 and dist < 620.0 and randf() < 0.6:
		return "special"
	if dist > 175.0:
		return "approach" if randf() < 0.9 else "idle"
	if randf() < float(AGGRESSION[d]):
		if can_special and randf() < 0.55:
			return "special"
		if dist < 120.0 or randf() < 0.4:
			return "kick"
		return "punch"
	var r := randf()
	if r < 0.45:
		return "retreat"
	if r < 0.75:
		return "block"
	return "idle"
