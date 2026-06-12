extends Node

## Procedural audio. Autoloaded as AudioManager.
##
## Every sound in the game is synthesized at startup into AudioStreamWAV
## buffers. No external or downloaded audio is used anywhere.
##
## Synth engine ("v2"): each sound is built from a detuned dual sine pair,
## optional extra partials (for bells/metal), a sub-oscillator for impact
## weight, lowpass-filtered noise (instead of raw white noise), soft
## tanh saturation (instead of chippy square waves), a shimmer band for
## magic, and a comb-echo tail that gives everything a stone-hall space.
##
## Usage:
##   AudioManager.play(&"xp_pickup")
##   AudioManager.play_weapon("soul_bolt")   # plays "w_soul_bolt"

const SAMPLE_RATE := 22050
const PLAYER_COUNT := 16

# Param reference (all optional except f0):
#   f0/f1     start/end pitch sweep (Hz)        dur      seconds (pre-tail)
#   decay     amp envelope power                vol      0..1 amplitude
#   detune    Hz offset of the 2nd oscillator   drive    >1 = soft saturation
#   partials  [[ratio, amp], ...] extra sines   sub      sub-osc amount (f*0.5)
#   noise     0..1 filtered-noise mix           nlp0/1   noise lowpass sweep Hz
#   shimmer   high sparkle amount               echo     0..1 stone-hall tail
#   attack    seconds (default 0.004)           lp       final polish lowpass Hz
const SFX: Dictionary = {
	# --- UI / run events -------------------------------------------------
	&"ui_click": {"f0": 740.0, "f1": 560.0, "dur": 0.12, "decay": 2.2, "vol": 0.3, "detune": 3.0, "echo": 0.2, "lp": 5200.0},
	&"ui_hover": {"f0": 520.0, "f1": 540.0, "dur": 0.06, "decay": 2.0, "vol": 0.16, "detune": 2.0, "lp": 4200.0},
	&"run_start": {"f0": 110.0, "f1": 220.0, "dur": 0.9, "decay": 1.5, "vol": 0.5, "detune": 2.5, "partials": [[2.0, 0.3], [3.0, 0.12]], "echo": 0.4},
	&"wave_start": {"f0": 98.0, "f1": 82.4, "dur": 1.1, "decay": 1.3, "vol": 0.46, "drive": 1.5, "partials": [[2.0, 0.25], [2.99, 0.1]], "sub": 0.3, "echo": 0.5},
	&"level_up": {"f0": 523.0, "f1": 1046.0, "dur": 0.9, "decay": 1.7, "vol": 0.5, "detune": 4.0, "shimmer": 0.3, "echo": 0.5},
	&"upgrade_pick": {"f0": 392.0, "f1": 523.0, "dur": 0.35, "decay": 1.8, "vol": 0.4, "detune": 3.0, "echo": 0.3},
	&"game_over": {"f0": 165.0, "f1": 41.0, "dur": 2.2, "decay": 1.2, "vol": 0.6, "sub": 0.5, "drive": 1.4, "echo": 0.6},
	&"victory": {"f0": 392.0, "f1": 784.0, "dur": 2.0, "decay": 1.2, "vol": 0.55, "partials": [[1.5, 0.2], [2.0, 0.25]], "shimmer": 0.25, "echo": 0.6},

	# --- Player ----------------------------------------------------------
	&"dash": {"f0": 300.0, "f1": 140.0, "dur": 0.28, "decay": 1.6, "vol": 0.3, "noise": 0.9, "nlp0": 1600.0, "nlp1": 320.0, "echo": 0.15},
	&"player_hurt": {"f0": 200.0, "f1": 90.0, "dur": 0.3, "decay": 1.6, "vol": 0.5, "sub": 0.6, "drive": 1.6, "noise": 0.25, "nlp0": 1100.0, "echo": 0.2},
	&"player_death": {"f0": 220.0, "f1": 36.0, "dur": 1.8, "decay": 1.2, "vol": 0.62, "sub": 0.7, "drive": 1.6, "noise": 0.3, "nlp0": 900.0, "echo": 0.55},
	&"heal": {"f0": 440.0, "f1": 660.0, "dur": 0.5, "decay": 1.7, "vol": 0.36, "detune": 3.0, "shimmer": 0.2, "echo": 0.35},
	&"xp_pickup": {"f0": 1175.0, "f1": 1568.0, "dur": 0.14, "decay": 2.4, "vol": 0.2, "detune": 5.0, "echo": 0.18, "lp": 7600.0},

	# --- Enemies ---------------------------------------------------------
	&"enemy_hit": {"f0": 240.0, "f1": 170.0, "dur": 0.09, "decay": 1.9, "vol": 0.3, "noise": 0.45, "nlp0": 2400.0, "drive": 1.3},
	&"enemy_death": {"f0": 200.0, "f1": 70.0, "dur": 0.35, "decay": 1.7, "vol": 0.34, "noise": 0.5, "nlp0": 1500.0, "sub": 0.25, "echo": 0.2},
	&"elite_death": {"f0": 165.0, "f1": 52.0, "dur": 0.7, "decay": 1.4, "vol": 0.46, "noise": 0.4, "nlp0": 1300.0, "sub": 0.4, "partials": [[2.76, 0.2]], "echo": 0.4},
	&"hexer_cast": {"f0": 420.0, "f1": 300.0, "dur": 0.4, "decay": 1.5, "vol": 0.32, "detune": 5.0, "shimmer": 0.15, "echo": 0.3},
	&"knight_charge": {"f0": 130.0, "f1": 320.0, "dur": 0.5, "decay": 1.3, "vol": 0.4, "noise": 0.55, "nlp0": 950.0, "drive": 1.5, "echo": 0.3},

	# --- Boss ------------------------------------------------------------
	&"boss_spawn": {"f0": 73.0, "f1": 36.5, "dur": 2.2, "decay": 1.1, "vol": 0.66, "sub": 0.6, "drive": 1.5, "partials": [[1.5, 0.2], [2.76, 0.12]], "echo": 0.6},
	&"boss_hurt": {"f0": 160.0, "f1": 120.0, "dur": 0.18, "decay": 1.7, "vol": 0.32, "noise": 0.3, "nlp0": 1400.0},
	&"boss_attack": {"f0": 110.0, "f1": 60.0, "dur": 0.6, "decay": 1.4, "vol": 0.48, "sub": 0.5, "drive": 1.6, "echo": 0.4},
	&"boss_death": {"f0": 196.0, "f1": 27.0, "dur": 2.6, "decay": 1.0, "vol": 0.7, "sub": 0.7, "noise": 0.35, "nlp0": 800.0, "partials": [[2.76, 0.2]], "echo": 0.65},

	# --- Weapons (distinct, fuller cues) ----------------------------------
	&"w_soul_bolt": {"f0": 660.0, "f1": 880.0, "dur": 0.16, "decay": 2.0, "vol": 0.22, "detune": 4.0, "shimmer": 0.12, "echo": 0.2, "lp": 7800.0},
	&"w_rune_knives": {"f0": 1320.0, "f1": 880.0, "dur": 0.22, "decay": 2.1, "vol": 0.2, "partials": [[2.31, 0.3], [3.7, 0.16]], "noise": 0.15, "nlp0": 5200.0, "echo": 0.25},
	&"w_orbiting_relics": {"f0": 165.0, "f1": 196.0, "dur": 0.25, "decay": 1.6, "vol": 0.15, "detune": 2.0, "partials": [[2.76, 0.15]], "echo": 0.2},
	&"w_cursed_flame": {"f0": 220.0, "f1": 90.0, "dur": 0.5, "decay": 1.4, "vol": 0.3, "noise": 0.85, "nlp0": 1800.0, "nlp1": 480.0, "echo": 0.25},
	&"w_bone_spikes": {"f0": 180.0, "f1": 60.0, "dur": 0.3, "decay": 1.7, "vol": 0.36, "noise": 0.6, "nlp0": 3000.0, "nlp1": 900.0, "sub": 0.35, "drive": 1.5, "echo": 0.25},
	&"w_chain_hex": {"f0": 1400.0, "f1": 320.0, "dur": 0.2, "decay": 1.8, "vol": 0.26, "detune": 8.0, "drive": 1.6, "noise": 0.2, "nlp0": 4200.0, "echo": 0.3},
	&"w_sanctified_nova": {"f0": 523.0, "f1": 519.0, "dur": 0.8, "decay": 1.5, "vol": 0.32, "partials": [[2.76, 0.35], [5.4, 0.1]], "shimmer": 0.2, "echo": 0.5},
	&"w_blood_scythe": {"f0": 420.0, "f1": 160.0, "dur": 0.3, "decay": 1.5, "vol": 0.3, "noise": 0.55, "nlp0": 2600.0, "nlp1": 850.0, "echo": 0.25},
	&"w_grave_bell": {"f0": 147.0, "f1": 146.0, "dur": 1.4, "decay": 1.1, "vol": 0.36, "partials": [[2.76, 0.4], [5.4, 0.14]], "echo": 0.6},
	&"w_thorn_sigil": {"f0": 280.0, "f1": 200.0, "dur": 0.25, "decay": 1.7, "vol": 0.22, "noise": 0.5, "nlp0": 1300.0, "echo": 0.2},
	&"w_phantom_bow": {"f0": 880.0, "f1": 392.0, "dur": 0.3, "decay": 1.8, "vol": 0.26, "detune": 5.0, "noise": 0.25, "nlp0": 2200.0, "echo": 0.3},
	&"w_plague_lantern": {"f0": 240.0, "f1": 180.0, "dur": 0.5, "decay": 1.3, "vol": 0.22, "noise": 0.6, "nlp0": 680.0, "shimmer": 0.08, "echo": 0.3},
	&"w_iron_maiden": {"f0": 220.0, "f1": 210.0, "dur": 0.5, "decay": 1.5, "vol": 0.34, "partials": [[1.51, 0.4], [2.62, 0.25]], "drive": 1.5, "sub": 0.3, "echo": 0.4},
	&"w_astral_tome": {"f0": 740.0, "f1": 988.0, "dur": 0.25, "decay": 1.8, "vol": 0.22, "shimmer": 0.25, "noise": 0.12, "nlp0": 3000.0, "echo": 0.35},
	&"w_moon_chakram": {"f0": 880.0, "f1": 1175.0, "dur": 0.3, "decay": 1.7, "vol": 0.22, "detune": 6.0, "noise": 0.15, "nlp0": 4600.0, "echo": 0.3},
	&"w_death_mark": {"f0": 392.0, "f1": 147.0, "dur": 0.4, "decay": 1.4, "vol": 0.26, "drive": 1.4, "sub": 0.3, "shimmer": 0.1, "echo": 0.4},
	&"w_storm_censer": {"f0": 1600.0, "f1": 90.0, "dur": 0.6, "decay": 1.5, "vol": 0.34, "noise": 0.7, "nlp0": 2600.0, "nlp1": 380.0, "sub": 0.45, "drive": 1.6, "echo": 0.5},
	&"w_saints_hammer": {"f0": 98.0, "f1": 40.0, "dur": 0.8, "decay": 1.3, "vol": 0.46, "sub": 0.8, "drive": 1.8, "noise": 0.4, "nlp0": 1100.0, "partials": [[1.5, 0.2]], "echo": 0.5},
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()

# Throttle very frequent sfx so 50 hits in one frame don't stack into noise.
var _last_played: Dictionary = {}
const MIN_REPEAT_MS := 45


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 0xC0FFEE

	for id in SFX.keys():
		_streams[id] = _synth(SFX[id])

	for i in range(PLAYER_COUNT):
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	add_child(_music_player)

	_music_player.stream = _build_music_loop()
	apply_volumes()
	_music_player.play()


func apply_volumes() -> void:
	if _music_player == null:
		return

	var music_vol := float(_save_data().get("music_volume", 1.0))
	if music_vol <= 0.001:
		_music_player.volume_db = -80.0
	else:
		_music_player.volume_db = linear_to_db(clampf(music_vol, 0.0001, 1.0)) - 11.0


func is_music_enabled() -> bool:
	return float(_save_data().get("music_volume", 1.0)) > 0.001


func set_music_enabled(enabled: bool) -> void:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.data["music_volume"] = 1.0 if enabled else 0.0
		save_system.save()
	apply_volumes()


func play(id: StringName, volume_db_offset := 0.0, pitch_jitter := 0.05) -> void:
	if not _streams.has(id):
		return

	var now := Time.get_ticks_msec()
	if _last_played.has(id) and now - int(_last_played[id]) < MIN_REPEAT_MS:
		return

	_last_played[id] = now

	var sfx_vol := float(_save_data().get("sfx_volume", 1.0))
	if sfx_vol <= 0.001:
		return

	if _players.is_empty():
		return

	var p := _players[_next_player]
	_next_player = (_next_player + 1) % PLAYER_COUNT

	p.stream = _streams[id]
	p.volume_db = linear_to_db(sfx_vol) + volume_db_offset
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func play_weapon(weapon_id: String) -> void:
	play(StringName("w_" + weapon_id), -4.0, 0.09)


func _save_data() -> Dictionary:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return {}

	var save_data: Variant = save_system.get("data")
	return save_data if save_data is Dictionary else {}


## Synthesizes one sound effect from its parameter dictionary (engine v2).
func _synth(p: Dictionary) -> AudioStreamWAV:
	var dur := float(p.get("dur", 0.2))
	var echo := float(p.get("echo", 0.0))
	var tail := 0.42 * echo + 0.03
	var note_n := int(dur * SAMPLE_RATE)
	var n := int((dur + tail) * SAMPLE_RATE)

	var mix := PackedFloat32Array()
	mix.resize(n)

	var f0 := float(p.get("f0", 440.0))
	var f1 := float(p.get("f1", f0))
	var detune := float(p.get("detune", 0.0))
	var partials: Array = p.get("partials", [])
	var sub_amt := float(p.get("sub", 0.0))
	var noise_mix := float(p.get("noise", 0.0))
	var nlp0 := float(p.get("nlp0", 2400.0))
	var nlp1 := float(p.get("nlp1", nlp0))
	var shimmer := float(p.get("shimmer", 0.0))
	var drive := float(p.get("drive", 0.0))
	var decay_pow := float(p.get("decay", 1.6))
	var vol := float(p.get("vol", 0.5))
	var attack_samples := maxi(1, int(float(p.get("attack", 0.004)) * SAMPLE_RATE))

	var phase := 0.0
	var phase_d := 0.0
	var phase_sub := 0.0
	var noise_state := 0.0
	var drive_norm := tanh(drive) if drive > 0.0 else 1.0

	for i in range(note_n):
		var t := float(i) / float(note_n)
		var freq := lerpf(f0, f1, t * t * (3.0 - 2.0 * t))

		phase += TAU * freq / float(SAMPLE_RATE)
		var s := sin(phase)

		if detune > 0.0:
			phase_d += TAU * (freq + detune) / float(SAMPLE_RATE)
			s = s * 0.6 + sin(phase_d) * 0.4

		for part in partials:
			s += float(part[1]) * sin(phase * float(part[0])) * (1.0 - t * 0.7)

		if sub_amt > 0.0:
			phase_sub += TAU * freq * 0.5 / float(SAMPLE_RATE)
			s += sub_amt * sin(phase_sub) * pow(1.0 - t, 1.4)

		if shimmer > 0.0:
			s += shimmer * sin(phase * 3.98) * (0.5 + 0.5 * sin(TAU * 9.0 * t)) * (1.0 - t)

		if noise_mix > 0.0:
			var cutoff := lerpf(nlp0, nlp1, t)
			var alpha := clampf(1.0 - exp(-TAU * cutoff / SAMPLE_RATE), 0.0, 1.0)
			noise_state += (_rng.randf() * 2.0 - 1.0 - noise_state) * alpha
			s = lerpf(s, noise_state * 2.4, noise_mix)

		if drive > 0.0:
			s = tanh(s * drive) / drive_norm

		var env := pow(1.0 - t, decay_pow)
		if i < attack_samples:
			env *= float(i) / float(attack_samples)

		mix[i] = s * env * vol

	# Stone-hall tail: two feedback combs smear the sound into the room.
	if echo > 0.0:
		var d1 := int(0.067 * SAMPLE_RATE)
		var d2 := int(0.103 * SAMPLE_RATE)
		var g1 := echo * 0.5
		var g2 := echo * 0.34
		for i in range(d1, n):
			mix[i] += mix[i - d1] * g1
		for i in range(d2, n):
			mix[i] += mix[i - d2] * g2

	# Final polish lowpass to round off any digital fizz.
	var lp := float(p.get("lp", 8800.0))
	var lp_a := clampf(1.0 - exp(-TAU * lp / SAMPLE_RATE), 0.0, 1.0)
	var lp_state := 0.0
	for i in range(n):
		lp_state += (mix[i] - lp_state) * lp_a
		mix[i] = lp_state

	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		bytes.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32000.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream


## Slow crypt ambience: a deep detuned drone breathing under a funeral bell
## that tolls twice per loop, sparse minor-key notes, cold air, and echoing
## water drips. Everything is washed through cavern combs. Original,
## synthesized, ~19 s, loops seamlessly on the drone.
func _build_music_loop() -> AudioStreamWAV:
	var dur := 19.2
	var n := int(dur * SAMPLE_RATE)

	var mix := PackedFloat32Array()
	mix.resize(n)

	# --- drone bed: A1 + detuned partner + low fifth, breathing slowly ----
	var p1 := 0.0
	var p2 := 0.0
	var p3 := 0.0
	var p4 := 0.0
	for i in range(n):
		var loop_t := float(i) / float(n)
		var t := float(i) / float(SAMPLE_RATE)
		p1 += TAU * 55.0 / SAMPLE_RATE
		p2 += TAU * 55.33 / SAMPLE_RATE
		p3 += TAU * 82.41 / SAMPLE_RATE
		p4 += TAU * 110.0 / SAMPLE_RATE
		var breath := 0.62 + 0.38 * sin(TAU * loop_t)            # loop-seamless swell
		var slow := 0.5 + 0.5 * sin(TAU * 0.11 * t + 1.7)
		var s := sin(p1) * 0.4 + sin(p2) * 0.34
		s += sin(p3) * 0.16 * slow
		s += sin(p4) * 0.07 * (1.0 - slow)
		s += (_rng.randf() * 2.0 - 1.0) * 0.012 * breath          # cold air
		mix[i] = s * 0.34 * breath

	# --- funeral bell: tolls at 0 s and half-loop ---------------------------
	for toll_at in [0.8, dur * 0.5 + 0.8]:
		_mix_bell(mix, int(toll_at * SAMPLE_RATE), 110.0, 0.30, 7.5)

	# --- sparse minor notes (A C E B-flat colour), long soft sines ----------
	var crypt_notes := [
		[2.6, -24], [5.4, -21], [7.8, -17], [9.0, -23],
		[12.2, -24], [14.6, -20], [16.4, -17], [17.8, -22],
	]
	for note in crypt_notes:
		var when := float(note[0])
		var semi := int(note[1])
		_synth_note(mix, int(when * SAMPLE_RATE), int(2.2 * SAMPLE_RATE),
			_mtof(semi), 0.085, 1.0, 0.3, 0.5, 0.004, 0.5)

	# --- water drips: tiny bright pings, seeded placement -------------------
	var drip_rng := RandomNumberGenerator.new()
	drip_rng.seed = 0x5EED
	for d in 6:
		var when := drip_rng.randf_range(1.0, dur - 1.5)
		var freq := drip_rng.randf_range(1200.0, 1900.0)
		var start := int(when * SAMPLE_RATE)
		var count := int(0.06 * SAMPLE_RATE)
		var ph := 0.0
		for i in range(count):
			var idx := start + i
			if idx >= n:
				break
			var t2 := float(i) / float(count)
			ph += TAU * lerpf(freq, freq * 0.82, t2) / SAMPLE_RATE
			mix[idx] += sin(ph) * pow(1.0 - t2, 2.6) * 0.05

	# --- cavern: long combs wash everything together -------------------------
	var d1 := int(0.31 * SAMPLE_RATE)
	var d2 := int(0.47 * SAMPLE_RATE)
	for i in range(d1, n):
		mix[i] += mix[i - d1] * 0.34
	for i in range(d2, n):
		mix[i] += mix[i - d2] * 0.26

	# normalize, encode, loop
	var peak := 0.0001
	for v in mix:
		peak = maxf(peak, absf(v))
	var gain := 0.85 / peak

	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		bytes.encode_s16(i * 2, int(clampf(mix[i] * gain, -1.0, 1.0) * 32000.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = n
	return stream


## A deep inharmonic bell with a very long decay, mixed into the buffer.
func _mix_bell(mix: PackedFloat32Array, start: int, freq: float, vol: float, decay_s: float) -> void:
	var n := mix.size()
	var count := mini(int(decay_s * SAMPLE_RATE), n - start)
	var ph1 := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	for i in range(count):
		var idx := start + i
		if idx < 0 or idx >= n:
			continue
		var t := float(i) / float(count)
		ph1 += TAU * freq / SAMPLE_RATE
		ph2 += TAU * freq * 2.76 / SAMPLE_RATE
		ph3 += TAU * freq * 5.4 / SAMPLE_RATE
		var s := sin(ph1) + sin(ph2) * 0.45 * (1.0 - t * 0.6) + sin(ph3) * 0.14 * (1.0 - t)
		var env := pow(1.0 - t, 2.6)
		if i < 90:
			env *= float(i) / 90.0
		mix[idx] += s * env * vol


## MIDI-style pitch: semitone offset from A4 (440 Hz) to frequency.
func _mtof(semi: int) -> float:
	return 440.0 * pow(2.0, float(semi) / 12.0)


## Adds one pitched note into the mix buffer with an attack/sustain/release
## envelope that returns to zero by the note's end, so loop seams stay click-free.
func _synth_note(
	mix: PackedFloat32Array,
	start: int,
	count: int,
	freq: float,
	vol: float,
	soft: float,
	atk_f: float,
	rel_f: float,
	vibrato: float,
	duty: float
) -> void:
	if count <= 0 or freq <= 0.0:
		return

	var n := mix.size()
	var atk := maxi(1, int(count * atk_f))
	var rel := maxi(1, int(count * rel_f))
	var phase := 0.0

	for i in range(count):
		var idx := start + i

		if idx < 0:
			continue

		if idx >= n:
			break

		var vib := 1.0 + sin(TAU * 5.2 * float(i) / SAMPLE_RATE) * vibrato

		phase += TAU * freq * vib / SAMPLE_RATE

		var sq := 1.0 if fmod(phase, TAU) < TAU * duty else -1.0
		var s := lerpf(sq, sin(phase), soft)
		var env := 1.0

		if i < atk:
			env = float(i) / float(atk)
		elif i > count - rel:
			env = float(count - i) / float(rel)

		mix[idx] += s * env * vol
