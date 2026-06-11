extends Node
## Procedural audio. Autoloaded as AudioManager.
##
## Every sound in the game is synthesized at startup into AudioStreamWAV
## buffers (sine/square/noise/bell partials with pitch sweeps and decay
## envelopes). No external or downloaded audio is used anywhere.
##
## Usage:
##   AudioManager.play(&"xp_pickup")
##   AudioManager.play_weapon("soul_bolt")   # plays "w_soul_bolt"

const SAMPLE_RATE := 22050
const PLAYER_COUNT := 16

# kind: "tone" (sine), "bell" (sine + inharmonic partial), "noise", "chord"
# f0/f1: start/end frequency sweep, dur: seconds, decay: envelope power,
# square/noise: 0..1 mix amounts, vol: 0..1 amplitude.
const SFX: Dictionary = {
	# --- UI / run events -------------------------------------------------
	&"ui_click": {"f0": 660.0, "f1": 880.0, "dur": 0.07, "decay": 1.5, "vol": 0.5},
	&"ui_hover": {"f0": 440.0, "f1": 470.0, "dur": 0.04, "decay": 1.5, "vol": 0.25},
	&"run_start": {"f0": 220.0, "f1": 440.0, "dur": 0.5, "decay": 1.6, "vol": 0.6, "harmonic": 0.4},
	&"wave_start": {"f0": 196.0, "f1": 165.0, "dur": 0.65, "decay": 1.3, "vol": 0.55, "harmonic": 0.5},
	&"level_up": {"f0": 523.0, "f1": 1046.0, "dur": 0.55, "decay": 1.8, "vol": 0.65, "harmonic": 0.3},
	&"upgrade_pick": {"f0": 784.0, "f1": 988.0, "dur": 0.22, "decay": 1.8, "vol": 0.5},
	&"game_over": {"f0": 220.0, "f1": 55.0, "dur": 1.4, "decay": 1.2, "vol": 0.7, "square": 0.2},
	&"victory": {"f0": 392.0, "f1": 784.0, "dur": 1.2, "decay": 1.1, "vol": 0.7, "harmonic": 0.6},

	# --- Player ----------------------------------------------------------
	&"dash": {"f0": 900.0, "f1": 300.0, "dur": 0.16, "decay": 1.6, "vol": 0.4, "noise": 0.45},
	&"player_hurt": {"f0": 240.0, "f1": 110.0, "dur": 0.25, "decay": 1.6, "vol": 0.6, "square": 0.4},
	&"player_death": {"f0": 330.0, "f1": 40.0, "dur": 1.3, "decay": 1.1, "vol": 0.75, "square": 0.3, "noise": 0.2},
	&"heal": {"f0": 520.0, "f1": 780.0, "dur": 0.3, "decay": 1.7, "vol": 0.45},
	&"xp_pickup": {"f0": 980.0, "f1": 1320.0, "dur": 0.08, "decay": 2.2, "vol": 0.32},

	# --- Enemies ---------------------------------------------------------
	&"enemy_hit": {"f0": 320.0, "f1": 240.0, "dur": 0.06, "decay": 1.8, "vol": 0.34, "noise": 0.5},
	&"enemy_death": {"f0": 260.0, "f1": 90.0, "dur": 0.22, "decay": 1.7, "vol": 0.4, "noise": 0.55},
	&"elite_death": {"f0": 200.0, "f1": 60.0, "dur": 0.5, "decay": 1.4, "vol": 0.55, "noise": 0.4, "harmonic": 0.5},
	&"hexer_cast": {"f0": 500.0, "f1": 340.0, "dur": 0.3, "decay": 1.5, "vol": 0.4, "square": 0.5},
	&"knight_charge": {"f0": 150.0, "f1": 420.0, "dur": 0.45, "decay": 1.2, "vol": 0.5, "noise": 0.3},

	# --- Boss ------------------------------------------------------------
	&"boss_spawn": {"f0": 98.0, "f1": 49.0, "dur": 1.6, "decay": 1.0, "vol": 0.8, "square": 0.35, "harmonic": 0.6},
	&"boss_hurt": {"f0": 180.0, "f1": 130.0, "dur": 0.12, "decay": 1.6, "vol": 0.4, "noise": 0.35},
	&"boss_attack": {"f0": 130.0, "f1": 70.0, "dur": 0.5, "decay": 1.3, "vol": 0.6, "square": 0.5},
	&"boss_death": {"f0": 220.0, "f1": 30.0, "dur": 2.0, "decay": 0.9, "vol": 0.85, "noise": 0.35, "harmonic": 0.7},

	# --- Weapons (one cue per weapon, distinct character) ----------------
	&"w_soul_bolt": {"f0": 720.0, "f1": 980.0, "dur": 0.09, "decay": 2.0, "vol": 0.3},
	&"w_rune_knives": {"f0": 1400.0, "f1": 900.0, "dur": 0.08, "decay": 2.2, "vol": 0.28, "noise": 0.4},
	&"w_orbiting_relics": {"f0": 180.0, "f1": 220.0, "dur": 0.18, "decay": 1.6, "vol": 0.22, "harmonic": 0.5},
	&"w_cursed_flame": {"f0": 300.0, "f1": 120.0, "dur": 0.35, "decay": 1.3, "vol": 0.4, "noise": 0.75},
	&"w_bone_spikes": {"f0": 220.0, "f1": 80.0, "dur": 0.2, "decay": 1.7, "vol": 0.45, "noise": 0.6, "square": 0.3},
	&"w_chain_hex": {"f0": 1600.0, "f1": 400.0, "dur": 0.13, "decay": 1.9, "vol": 0.34, "square": 0.6},
	&"w_sanctified_nova": {"f0": 660.0, "f1": 660.0, "dur": 0.5, "decay": 1.5, "vol": 0.45, "harmonic": 0.8},
	&"w_blood_scythe": {"f0": 500.0, "f1": 180.0, "dur": 0.22, "decay": 1.5, "vol": 0.42, "noise": 0.55},
	&"w_grave_bell": {"f0": 196.0, "f1": 194.0, "dur": 0.9, "decay": 1.2, "vol": 0.5, "harmonic": 0.9},
	&"w_thorn_sigil": {"f0": 350.0, "f1": 240.0, "dur": 0.16, "decay": 1.7, "vol": 0.3, "noise": 0.5},
	&"w_phantom_bow": {"f0": 1100.0, "f1": 500.0, "dur": 0.18, "decay": 1.8, "vol": 0.36, "noise": 0.25},
	&"w_plague_lantern": {"f0": 260.0, "f1": 200.0, "dur": 0.4, "decay": 1.2, "vol": 0.3, "noise": 0.65},
	&"w_iron_maiden": {"f0": 140.0, "f1": 90.0, "dur": 0.3, "decay": 1.5, "vol": 0.5, "square": 0.6, "noise": 0.3},
	&"w_astral_tome": {"f0": 840.0, "f1": 1100.0, "dur": 0.14, "decay": 1.8, "vol": 0.3, "harmonic": 0.4},
	&"w_moon_chakram": {"f0": 950.0, "f1": 1250.0, "dur": 0.2, "decay": 1.6, "vol": 0.3, "noise": 0.2},
	&"w_death_mark": {"f0": 480.0, "f1": 160.0, "dur": 0.3, "decay": 1.4, "vol": 0.38, "square": 0.45},
	&"w_storm_censer": {"f0": 2000.0, "f1": 200.0, "dur": 0.25, "decay": 1.6, "vol": 0.42, "noise": 0.7},
	&"w_saints_hammer": {"f0": 110.0, "f1": 45.0, "dur": 0.55, "decay": 1.2, "vol": 0.6, "square": 0.4, "noise": 0.35},
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
	_rng.seed = 0xC0FFEE # deterministic synthesis
	for id: StringName in SFX.keys():
		_streams[id] = _synth(SFX[id])
	for i in PLAYER_COUNT:
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
	var music_vol := float(_save_data().get("music_volume", 1.0))
	_music_player.volume_db = linear_to_db(clampf(music_vol, 0.0001, 1.0)) - 13.0


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


## Synthesizes one sound effect from its parameter dictionary.
func _synth(p: Dictionary) -> AudioStreamWAV:
	var dur: float = p.get("dur", 0.2)
	var n := int(dur * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var f0: float = p.get("f0", 440.0)
	var f1: float = p.get("f1", f0)
	var noise_mix: float = p.get("noise", 0.0)
	var square_mix: float = p.get("square", 0.0)
	var harmonic: float = p.get("harmonic", 0.0)
	var decay_pow: float = p.get("decay", 1.6)
	var vol: float = p.get("vol", 0.6)
	var attack_samples := maxi(1, int(0.004 * SAMPLE_RATE))
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var freq := lerpf(f0, f1, t * t * (3.0 - 2.0 * t)) # smoothstep sweep
		phase += TAU * freq / float(SAMPLE_RATE)
		var s := sin(phase)
		if square_mix > 0.0:
			s = lerpf(s, signf(s), square_mix)
		if harmonic > 0.0:
			s += harmonic * sin(phase * 2.76) * (1.0 - t)
		if noise_mix > 0.0:
			s = lerpf(s, _rng.randf() * 2.0 - 1.0, noise_mix)
		var env := pow(1.0 - t, decay_pow)
		if i < attack_samples:
			env *= float(i) / float(attack_samples)
		bytes.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream


## A quiet, ominous drone loop: detuned low sines breathing against each
## other with a slow shimmer. Original, synthesized, ~9.6 seconds, loops.
func _build_music_loop() -> AudioStreamWAV:
	var dur := 9.6
	var n := int(dur * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var p1 := 0.0
	var p2 := 0.0
	var p3 := 0.0
	var p4 := 0.0
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var loop_t := float(i) / float(n)
		p1 += TAU * 55.0 / SAMPLE_RATE          # A1 root
		p2 += TAU * 55.4 / SAMPLE_RATE          # detuned root (beating)
		p3 += TAU * 82.41 / SAMPLE_RATE         # E2 fifth
		p4 += TAU * 130.81 / SAMPLE_RATE        # C3 minor third
		var breath := 0.6 + 0.4 * sin(TAU * loop_t)            # whole-loop swell
		var slow := 0.5 + 0.5 * sin(TAU * 0.21 * t)
		var s := sin(p1) * 0.40 + sin(p2) * 0.34
		s += sin(p3) * 0.22 * slow
		s += sin(p4) * 0.12 * (1.0 - slow)
		s += (_rng.randf() * 2.0 - 1.0) * 0.015 * breath        # faint air
		bytes.encode_s16(i * 2, int(clampf(s * 0.5 * breath, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = n
	return stream
