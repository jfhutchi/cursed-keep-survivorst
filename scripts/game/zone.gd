class_name Zone
extends Node2D
## Pooled ground-effect node: telegraphed eruptions, persistent clouds,
## traps, lightning strikes, boss sigils and cracked ground.
##
## kinds:
##   erupt  - warning sigil, then bone spikes burst (damage once, optional 2nd)
##   hammer - large warning circle, then slam (damage + knockback + stun)
##   strike - quick warning flash, then a lightning bolt (damage)
##   sigil  - boss curse sigil: telegraph, then explodes (damages the PLAYER)
##   cloud  - drifting poison/flame cloud, ticks damage or applies DoT
##   trap   - thorn trap: ticks damage + slow on enemies inside
##   holy_flame - sanctified burning ground left by the Saint's Hammer

const HAMMER_TEX := preload("res://assets/generated/effects/saints_hammer_fx.svg")

var world: Node2D
var active := false

var kind := "erupt"
var color := Color.WHITE
var radius := 80.0
var delay := 0.7
var damage := 10.0
var duration := 0.0
var tick := 0.5
var slow := 0.0
var slow_dur := 1.0
var stun := 0.0
var knockback := 0.0
var source := ""
var opts: Dictionary = {}

var _t := 0.0
var _phase := 0       # 0 telegraph, 1 active/payload, 2 fade
var _phase_t := 0.0
var _tick_acc := 0.0
var _drift := Vector2.ZERO
var _erupted_twice := false
var _rng_seed := 0


func setup(params: Dictionary) -> void:
	kind = params.get("kind", "erupt")
	color = params.get("color", Color.WHITE)
	global_position = params.get("pos", Vector2.ZERO)
	radius = params.get("radius", 80.0)
	delay = params.get("delay", 0.7)
	damage = params.get("damage", 10.0)
	duration = params.get("duration", 0.0)
	tick = params.get("tick", 0.5)
	slow = params.get("slow", 0.0)
	slow_dur = params.get("slow_dur", 1.0)
	stun = params.get("stun", 0.0)
	knockback = params.get("knockback", 0.0)
	source = params.get("source", "")
	opts = params.get("opts", {})
	_t = 0.0
	_phase_t = 0.0
	_tick_acc = 0.0
	_erupted_twice = false
	_rng_seed = randi()
	_drift = Vector2(randf_range(-14, 14), randf_range(-14, 14))
	_phase = 1 if kind in ["cloud", "trap", "holy_flame"] else 0
	queue_redraw()


func _pool_activate() -> void:
	active = true
	visible = true
	set_process(true)


func _pool_deactivate() -> void:
	active = false
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	_phase_t += delta
	match _phase:
		0: # telegraph
			if _phase_t >= delay:
				_payload()
		1: # persistent area / post-payload burst frame
			match kind:
				"cloud", "trap", "holy_flame":
					_area_tick(delta)
					if kind == "cloud":
						global_position += _drift * delta
					if _phase_t >= duration:
						_on_expire()
						_phase = 2
						_phase_t = 0.0
				_:
					# burst visuals play for a short time, then fade out
					if _phase_t >= 0.35:
						if bool(opts.get("second", false)) and not _erupted_twice and kind == "erupt":
							_erupted_twice = true
							_damage_burst()
							_phase_t = 0.0
						else:
							_phase = 2
							_phase_t = 0.0
		2: # fade
			if _phase_t >= 0.25:
				world.release_zone(self)
				return
	queue_redraw()


func _payload() -> void:
	_phase = 1
	_phase_t = 0.0
	match kind:
		"erupt":
			AudioManager.play_weapon("bone_spikes")
			_damage_burst()
		"hammer":
			AudioManager.play_weapon("saints_hammer")
			GameEvents.screen_shake_requested.emit(9.0)
			GameEvents.hit_stop_requested.emit(0.05)
			_damage_burst()
			if bool(opts.get("crack", false)):
				# Sanctified Ground upgrade: the slam leaves holy flame
				world.spawn_zone({"kind": "holy_flame", "pos": global_position, "radius": radius * 0.8,
					"damage": damage * 0.12, "tick": 0.5, "duration": 3.0, "source": source,
					"color": Color(1.0, 0.85, 0.55)})
		"strike":
			AudioManager.play_weapon("storm_censer")
			_damage_burst()
		"sigil":
			AudioManager.play(&"boss_attack")
			# damages the player if inside
			var player: Node2D = world.player
			if player != null and player.alive:
				if global_position.distance_squared_to(player.global_position) < radius * radius:
					player.take_damage(damage, global_position)
			GameEvents.screen_shake_requested.emit(5.0)


func _damage_burst() -> void:
	var enemies: Array = world.query_enemies(global_position, radius)
	for enemy in enemies:
		world.deal_damage(enemy, damage, source, {"kb": (enemy.global_position - global_position).normalized() * knockback})
		if slow > 0.0 and enemy.alive:
			enemy.apply_slow(slow, slow_dur)
		if stun > 0.0 and enemy.alive:
			enemy.apply_stun(stun)


func _area_tick(delta: float) -> void:
	_tick_acc += delta
	if _tick_acc < tick:
		return
	_tick_acc -= tick
	var enemies: Array = world.query_enemies(global_position, radius)
	for enemy in enemies:
		match kind:
			"cloud":
				if opts.has("poison_dps"):
					enemy.apply_poison(opts["poison_dps"], opts.get("poison_dur", 2.0))
					if opts.has("vuln") and float(opts["vuln"]) > 0.0:
						enemy.poison_vuln = float(opts["vuln"])
				elif opts.has("burn_dps"):
					enemy.apply_burn(opts["burn_dps"], opts.get("burn_dur", 2.0))
				else:
					world.deal_damage(enemy, damage, source, {"no_crit": true})
			"trap":
				world.deal_damage(enemy, damage, source, {"no_crit": true})
				if slow > 0.0 and enemy.alive:
					enemy.apply_slow(slow, slow_dur)
				if bool(opts.get("poison", false)) and enemy.alive:
					enemy.apply_poison(damage * 0.8, 2.0)
			"holy_flame":
				world.deal_damage(enemy, damage, source, {"no_crit": true})


func _on_expire() -> void:
	if kind == "trap" and bool(opts.get("spread", false)):
		var offset := Vector2(randf_range(-90, 90), randf_range(-90, 90))
		world.weapon_manager.spawn_spread_trap(global_position + offset)
	# Grave Tithe synergy: dying thorn sigils erupt into bone spikes
	if kind == "trap" and world.synergies.has("grave_tithe"):
		world.weapon_manager.spawn_tithe_spike(global_position)


func _draw() -> void:
	if not active:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 9.0)
	match _phase:
		0:
			_draw_telegraph(pulse)
		1, 2:
			var fade := 1.0 - _phase_t / 0.25 if _phase == 2 else 1.0
			_draw_active(fade)


func _draw_telegraph(pulse: float) -> void:
	var progress := clampf(_phase_t / maxf(delay, 0.01), 0.0, 1.0)
	var warn := Color(1.0, 0.25, 0.2, 0.35 + pulse * 0.25) if kind in ["sigil", "hammer"] else Color(color.r, color.g, color.b, 0.3 + pulse * 0.25)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, warn, 3.0)
	draw_circle(Vector2.ZERO, radius * progress, Color(warn.r, warn.g, warn.b, 0.16))
	# inner warning sigil cross
	var a := warn.a * 0.9
	draw_line(Vector2(-radius * 0.4, 0), Vector2(radius * 0.4, 0), Color(warn.r, warn.g, warn.b, a), 2.0)
	draw_line(Vector2(0, -radius * 0.4), Vector2(0, radius * 0.4), Color(warn.r, warn.g, warn.b, a), 2.0)
	draw_arc(Vector2.ZERO, radius * 0.55, 0, TAU, 24, Color(warn.r, warn.g, warn.b, a * 0.7), 1.5)
	if kind == "hammer":
		_draw_falling_hammer(progress)


## The spectral hammer plunges head-first toward the warning circle,
## accelerating, with a faint motion ghost trailing above it.
func _draw_falling_hammer(progress: float) -> void:
	var drop := 1.0 - progress * progress              # 1 -> 0, accelerating
	var hammer_y := -470.0 * drop
	var sway := sin(_t * 5.0) * 0.06 * drop
	var hammer_scale := radius / 95.0
	var tex_size: Vector2 = HAMMER_TEX.get_size()
	# motion ghost while it is still moving fast
	if progress < 0.92:
		draw_set_transform(Vector2(0, hammer_y - 42.0 * hammer_scale), sway, Vector2.ONE * hammer_scale)
		draw_texture_rect(HAMMER_TEX, Rect2(-tex_size * 0.5 - Vector2(0, tex_size.y * 0.5 - 8), tex_size), false, Color(1, 1, 1, 0.22))
	draw_set_transform(Vector2(0, hammer_y), sway, Vector2.ONE * hammer_scale)
	draw_texture_rect(HAMMER_TEX, Rect2(-tex_size * 0.5 - Vector2(0, tex_size.y * 0.5 - 8), tex_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_active(fade: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng_seed
	match kind:
		"erupt":
			# bone spikes: pale triangles bursting outward
			for i in 9:
				var ang := rng.randf() * TAU
				var dist := rng.randf_range(radius * 0.15, radius * 0.8)
				var base := Vector2.from_angle(ang) * dist
				var h := rng.randf_range(18.0, 34.0)
				var pts := PackedVector2Array([base + Vector2(-6, 0), base + Vector2(6, 0), base + Vector2(0, -h)])
				draw_colored_polygon(pts, Color(0.92, 0.89, 0.8, fade))
			draw_circle(Vector2.ZERO, radius, Color(0.9, 0.86, 0.75, 0.12 * fade))
		"hammer":
			# the hammer rests on the ground for a beat, ringing with light
			var hammer_scale := radius / 95.0
			var tex_size: Vector2 = HAMMER_TEX.get_size()
			var settle := maxf(0.0, 1.0 - _phase_t * 4.0)
			var bounce := -absf(sin(_phase_t * 22.0)) * 5.0 * settle
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.85, 0.5, 0.25 * fade))
			draw_arc(Vector2.ZERO, radius * (0.4 + _phase_t * 2.0), 0, TAU, 40, Color(1.0, 0.9, 0.6, fade * 0.8), 5.0)
			# impact light rays
			for i in 8:
				var ray_a := TAU * i / 8.0 + 0.2
				draw_line(Vector2.from_angle(ray_a) * radius * 0.25,
					Vector2.from_angle(ray_a) * radius * (0.55 + _phase_t * 1.4),
					Color(1.0, 0.95, 0.75, fade * 0.7), 2.5)
			# dust puffs
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = _rng_seed
			for i in 7:
				var dust_a := rng2.randf() * TAU
				var dust_d := radius * rng2.randf_range(0.5, 0.95)
				draw_circle(Vector2.from_angle(dust_a) * dust_d + Vector2(0, -_phase_t * 26.0),
					rng2.randf_range(4.0, 9.0) * (1.0 + _phase_t), Color(0.75, 0.68, 0.55, 0.18 * fade))
			draw_set_transform(Vector2(0, bounce), 0.0, Vector2.ONE * hammer_scale)
			draw_texture_rect(HAMMER_TEX, Rect2(-tex_size * 0.5 - Vector2(0, tex_size.y * 0.5 - 8), tex_size), false, Color(1, 1, 1, minf(1.0, fade * 1.6)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"strike":
			# jagged lightning from above
			var top := Vector2(rng.randf_range(-20, 20), -340)
			var prev := top
			var segs := 7
			for i in segs:
				var y := -340.0 + 340.0 * float(i + 1) / segs
				var next := Vector2(rng.randf_range(-26, 26) * (1.0 - float(i) / segs), y)
				draw_line(prev, next, Color(0.85, 0.92, 1.0, fade), 3.5)
				draw_line(prev, next, Color(color.r, color.g, color.b, fade * 0.5), 7.0)
				prev = next
			draw_circle(Vector2.ZERO, radius * 0.8, Color(color.r, color.g, color.b, 0.3 * fade))
		"sigil":
			draw_circle(Vector2.ZERO, radius, Color(0.7, 0.3, 1.0, 0.3 * fade))
			draw_arc(Vector2.ZERO, radius * (0.3 + _phase_t * 2.5), 0, TAU, 36, Color(0.85, 0.5, 1.0, fade), 4.0)
		"cloud":
			for i in 6:
				var off := Vector2(rng.randf_range(-radius, radius) * 0.6, rng.randf_range(-radius, radius) * 0.6)
				var r := radius * rng.randf_range(0.35, 0.6) * (1.0 + sin(_t * 2.0 + i) * 0.1)
				draw_circle(off, r, Color(color.r, color.g, color.b, 0.10 * fade))
			draw_circle(Vector2.ZERO, radius * 0.4, Color(color.r, color.g, color.b, 0.16 * fade))
		"trap":
			# thorn sigil: dark green circle with thorn spokes
			draw_arc(Vector2.ZERO, radius, 0, TAU, 28, Color(color.r, color.g, color.b, 0.6 * fade), 2.0)
			for i in 7:
				var ang := TAU * i / 7.0 + _t * 0.4
				var p1 := Vector2.from_angle(ang) * radius * 0.3
				var p2 := Vector2.from_angle(ang + 0.18) * radius * 0.85
				draw_line(p1, p2, Color(color.r, color.g, color.b, 0.7 * fade), 2.5)
			draw_circle(Vector2.ZERO, radius * 0.2, Color(color.r, color.g, color.b, 0.5 * fade))
		"holy_flame":
			# ring of golden flame tongues with white-hot cores and rising motes
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.85, 0.5, 0.10 * fade))
			for i in 9:
				var flame_a := TAU * i / 9.0 + 0.3
				var base := Vector2.from_angle(flame_a) * radius * 0.72
				var h := (16.0 + 9.0 * sin(_t * 7.0 + i * 1.7)) * (radius / 120.0 + 0.5)
				var w := 7.0 + 2.0 * sin(_t * 5.0 + i)
				var outer := PackedVector2Array([base + Vector2(-w, 4), base + Vector2(w, 4),
					base + Vector2(w * 0.3, -h * 0.55), base + Vector2(0, -h), base + Vector2(-w * 0.3, -h * 0.55)])
				draw_colored_polygon(outer, Color(1.0, 0.78, 0.35, 0.6 * fade))
				var inner := PackedVector2Array([base + Vector2(-w * 0.45, 2), base + Vector2(w * 0.45, 2),
					base + Vector2(0, -h * 0.6)])
				draw_colored_polygon(inner, Color(1.0, 0.96, 0.82, 0.85 * fade))
			# rising holy motes
			for i in 6:
				var rise := fmod(_t * 0.45 + i * 0.167, 1.0)
				var mote_a := TAU * i / 6.0 + 0.8
				var mote := Vector2.from_angle(mote_a) * radius * 0.5 + Vector2(0, -rise * 34.0)
				draw_circle(mote, 2.2 * (1.0 - rise), Color(1.0, 0.95, 0.75, (1.0 - rise) * 0.8 * fade))
			draw_arc(Vector2.ZERO, radius * 0.78, 0, TAU, 32, Color(1.0, 0.9, 0.6, 0.25 * fade), 2.0)
