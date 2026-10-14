class_name Sfx
extends Node
## مؤثرات صوتية مولّدة بالكود (مفيش ملفات صوت).

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var music_player: AudioStreamPlayer


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)
	_streams["punch"] = _thump(0.10, 170.0, 0.55)
	_streams["kick"] = _thump(0.14, 120.0, 0.7)
	_streams["special"] = _sweep(0.40, 180.0, 700.0)
	_streams["block"] = _click(0.07, 900.0)
	_streams["whoosh"] = _whoosh(0.16)
	_streams["ko"] = _thump(0.55, 90.0, 0.9, 0.6)
	_streams["bell"] = _bell(0.5)
	_streams["select"] = _click(0.05, 1400.0)
	_streams["combo"] = _click(0.12, 1800.0)
	_streams["slipper"] = _sweep(0.25, 900.0, 300.0)
	_streams["shock"] = _thump(0.6, 60.0, 0.9, 0.5)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -13.0
	music_player.stream = _music()
	add_child(music_player)
	apply_settings()


func apply_settings() -> void:
	if music_player == null:
		return
	if SaveData.music:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()


func play(name: String) -> void:
	if not SaveData.sound or not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.play()


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


static func _thump(dur: float, freq: float, noise_amt: float, decay := 0.25) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t / (dur * decay))
		lp = lp * 0.7 + rng.randf_range(-1.0, 1.0) * 0.3
		s[i] = (sin(TAU * freq * t * (1.0 - 0.4 * t / dur)) * 0.8 + lp * noise_amt) * env
	return _wav(s)


static func _click(dur: float, freq: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = sin(TAU * freq * t) * exp(-t / (dur * 0.3)) * 0.6
	return _wav(s)


static func _whoosh(dur: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		var env := sin(PI * t)
		lp = lp * 0.55 + rng.randf_range(-1.0, 1.0) * 0.45
		s[i] = lp * env * 0.35
	return _wav(s)


static func _sweep(dur: float, f0: float, f1: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t * t)
		ph += TAU * f / RATE
		s[i] = (sin(ph) * 0.5 + sin(ph * 2.0) * 0.2) * sin(PI * minf(t * 1.6, 1.0)) * (1.0 - t) * 0.9
	return _wav(s)


static func _bell(dur: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 6.0)
		s[i] = (sin(TAU * 660.0 * t) * 0.5 + sin(TAU * 990.0 * t) * 0.3 + sin(TAU * 1320.0 * t) * 0.15) * env
	return _wav(s)


# ---------- موسيقى: إيقاع مقسوم + لحن حجاز (لوب ~18 ثانية) ----------
static func _add_dum(buf: PackedFloat32Array, t0: float) -> void:
	var start := int(t0 * RATE)
	var n := int(0.28 * RATE)
	var ph := 0.0
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		ph += TAU * (52.0 + 90.0 * exp(-t * 38.0)) / RATE
		buf[start + i] += sin(ph) * exp(-t * 13.0) * 0.95


static func _add_tak(buf: PackedFloat32Array, t0: float, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var start := int(t0 * RATE)
	var n := int(0.07 * RATE)
	var lp := 0.0
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		var nz := rng.randf_range(-1.0, 1.0)
		lp = nz - lp * 0.35
		buf[start + i] += lp * exp(-t * 75.0) * 0.32 + sin(TAU * 1900.0 * t) * exp(-t * 65.0) * 0.14


static func _add_pluck(buf: PackedFloat32Array, t0: float, freq: float, length: float, amp: float) -> void:
	var start := int(t0 * RATE)
	var n := int((length + 0.3) * RATE)
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		var env := exp(-t * 3.4) * minf(t * 220.0, 1.0)
		var ph := TAU * freq * t
		buf[start + i] += (sin(ph) + 0.5 * sin(2.0 * ph) + 0.28 * sin(3.0 * ph) + 0.12 * sin(5.0 * ph)) * env * amp


static func _music() -> AudioStreamWAV:
	var bpm := 108.0
	var slot := 60.0 / bpm / 2.0
	var bars := 8
	var total := int(slot * float(bars * 8) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var pat := ["D", "T", "", "T", "D", "", "T", ""]
	for bar in bars:
		for i in 8:
			var t0 := (float(bar * 8 + i)) * slot
			if pat[i] == "D":
				_add_dum(buf, t0)
			elif pat[i] == "T":
				_add_tak(buf, t0, bar * 8 + i + 1)
		# جيتار باص: دوّارة على ري
		var root := 73.42 if bar % 4 != 2 else 77.78
		_add_pluck(buf, float(bar * 8) * slot, root, slot * 3.0, 0.30)
		_add_pluck(buf, float(bar * 8 + 4) * slot, root, slot * 3.0, 0.26)
	# لحن (سلّم حجاز على ري): [بداية، طول، نصف-نغمة فوق D4]
	var phrases := [
		[[0, 2, 7], [2, 1, 5], [3, 1, 4], [4, 2, 1], [6, 2, 0]],
		[[0, 1, 0], [1, 1, 1], [2, 2, 4], [4, 2, 1], [6, 2, 0]],
		[[0, 2, 12], [2, 1, 10], [3, 1, 8], [4, 2, 7], [6, 2, 5]],
		[[0, 2, 4], [2, 2, 1], [4, 4, 0]],
	]
	for bar in bars:
		var ph: Array = phrases[bar % 4]
		for note in ph:
			var f := 293.66 * pow(2.0, float(note[2]) / 12.0)
			_add_pluck(buf, float(bar * 8 + int(note[0])) * slot, f, float(note[1]) * slot, 0.2)
	var peak := 0.001
	for v in buf:
		peak = maxf(peak, absf(v))
	var out := PackedFloat32Array()
	out.resize(total)
	for i in total:
		out[i] = buf[i] / peak * 0.85
	var w := _wav(out)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total
	return w
