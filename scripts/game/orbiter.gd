class_name Orbiter
extends Node2D
## Persistent weapon companion node, created by WeaponManager (not pooled —
## there are at most a handful alive).
##
## kinds:
##   relics - ward-stones orbiting the player, contact damage with per-enemy
##            hit cooldown; optional arcane pulse; Iron Reliquary hardening
##   tome   - floating grimoire that drifts beside the player and auto-casts
##   maiden - temporary retaliation cage: spike ring with tick damage + DR

var world: Node2D
var weapon_manager: Node
var kind := "relics"

var _angle := 0.0
var _hit_times: Dictionary = {}    # enemy instance id -> last hit msec
var _pulse_cd := 0.0
var _zap_cd := 0.0
var _cast_cd := 0.0
var _maiden_t := 0.0
var _maiden_duration := 2.4
var _tome_index := 0
var _glyph_flash := 0.0


func setup_tome(index: int) -> void:
	_tome_index = index


func start_maiden(duration: float) -> void:
	_maiden_t = 0.0
	_maiden_duration = duration


func _process(delta: float) -> void:
	var player: Node2D = world.player
	if player == null or not player.alive:
		queue_redraw()
		return
	match kind:
		"relics":
			_tick_relics(delta, player)
		"tome":
			_tick_tome(delta, player)
		"maiden":
			_tick_maiden(delta, player)
	queue_redraw()


# --- Orbiting Relics ------------------------------------------------------

func _tick_relics(delta: float, player: Node2D) -> void:
	var wm := weapon_manager
	var orbit_speed: float = wm.wstat("orbiting_relics", "orbit_speed")
	var orbit_radius: float = wm.wstat("orbiting_relics", "radius")
	var count := int(wm.wstat("orbiting_relics", "count"))
	var damage: float = wm.wstat("orbiting_relics", "damage")
	var hit_interval: float = wm.wstat("orbiting_relics", "hit_interval")
	var stone_r: float = 14.0 * wm.wstat("orbiting_relics", "size")
	var hardened: bool = wm.relic_harden_t > 0.0
	if hardened:
		damage *= 2.0
	_angle += orbit_speed * delta
	global_position = player.global_position
	var now := Time.get_ticks_msec()
	for i in count:
		var a := _angle + TAU * i / count
		var stone_pos: Vector2 = global_position + Vector2.from_angle(a) * orbit_radius
		var hits: Array = world.query_enemies(stone_pos, stone_r + 14.0)
		for enemy in hits:
			var eid: int = enemy.get_instance_id()
			if _hit_times.has(eid) and now - int(_hit_times[eid]) < int(hit_interval * 1000.0):
				continue
			_hit_times[eid] = now
			world.deal_damage(enemy, damage, "orbiting_relics",
				{"kb": (enemy.global_position - global_position).normalized() * 120.0})
			AudioManager.play_weapon("orbiting_relics")
	# arcane pulse upgrade
	if wm.wstat("orbiting_relics", "pulse") > 0.0:
		_pulse_cd -= delta
		if _pulse_cd <= 0.0:
			_pulse_cd = 3.0 * player.stats["cooldown_mult"]
			for i in count:
				var a2 := _angle + TAU * i / count
				var sp: Vector2 = global_position + Vector2.from_angle(a2) * orbit_radius
				world.area_damage(sp, 65.0 * player.stats["area_mult"], damage * 0.7, "orbiting_relics", Color(1.0, 0.85, 0.45))
	# Relic Storm synergy: stones zap nearby enemies
	if world.synergies.has("relic_storm"):
		_zap_cd -= delta
		if _zap_cd <= 0.0:
			_zap_cd = 2.5 * player.stats["cooldown_mult"]
			var a3 := _angle
			var sp2: Vector2 = global_position + Vector2.from_angle(a3) * orbit_radius
			var target: Node2D = world.nearest_enemy(sp2, 220.0)
			if target != null:
				world.deal_damage(target, damage * 0.8, "orbiting_relics", {})
				world.spawn_fx({"kind": "lightning", "pos": sp2, "color": Color(0.5, 1.0, 0.7),
					"points": PackedVector2Array([sp2, target.global_position])})
	# cleanup stale hit entries occasionally
	if _hit_times.size() > 220:
		_hit_times.clear()


# --- Astral Tome ----------------------------------------------------------

func _tick_tome(delta: float, player: Node2D) -> void:
	var wm := weapon_manager
	var t := Time.get_ticks_msec() * 0.001 + _tome_index * 2.1
	var target_pos: Vector2 = player.global_position + Vector2(cos(t * 0.9) * 55.0, sin(t * 1.3) * 38.0 - 42.0)
	global_position = global_position.lerp(target_pos, 5.0 * delta)
	_glyph_flash = maxf(0.0, _glyph_flash - delta * 3.0)
	_cast_cd -= delta
	if _cast_cd > 0.0:
		return
	var cast_time: float = wm.wstat("astral_tome", "cast_cd")
	var range_v: float = wm.wstat("astral_tome", "range")
	var damage: float = wm.wstat("astral_tome", "damage")
	var empowered: bool = randf() < wm.wstat("astral_tome", "empowered")
	if empowered:
		damage *= 2.0
	# Astral Execution synergy: hunt marked enemies for bonus damage
	var target: Node2D = null
	if world.synergies.has("astral_execution"):
		target = world.find_marked_enemy(global_position, range_v)
		if target != null:
			damage *= 1.35
	if target == null:
		target = world.nearest_enemy(global_position, range_v)
	if target == null:
		return
	_cast_cd = cast_time
	_glyph_flash = 1.0
	AudioManager.play_weapon("astral_tome")
	var variety := int(wm.wstat("astral_tome", "variety"))
	var spell := randi() % (1 + mini(variety, 2))
	match spell:
		0: # arcane bolt
			world.spawn_projectile({"kind": "spark", "pos": global_position,
				"dir": (target.global_position - global_position).normalized(),
				"speed": 700.0, "damage": damage, "source": "astral_tome",
				"color": Color(0.72, 0.64, 1.0), "size": 1.4 if empowered else 1.0,
				"max_distance": range_v * 1.2})
		1: # mini nova at the target
			world.area_damage(target.global_position, 70.0 * player.stats["area_mult"] * (1.3 if empowered else 1.0),
				damage, "astral_tome", Color(0.72, 0.64, 1.0))
		2: # curse: damage + slow
			world.deal_damage(target, damage * 0.8, "astral_tome", {})
			if target.alive:
				target.apply_slow(0.4, 1.5)
			world.spawn_fx({"kind": "mark_pop", "pos": target.global_position, "color": Color(0.72, 0.64, 1.0)})


# --- Iron Maiden cage -------------------------------------------------------

func _tick_maiden(delta: float, player: Node2D) -> void:
	var wm := weapon_manager
	global_position = player.global_position
	_maiden_t += delta
	if _maiden_t >= _maiden_duration:
		wm.maiden_finished(self)
		return
	_angle += delta * 1.4
	# tick damage on contact with the cage ring
	_pulse_cd -= delta
	if _pulse_cd <= 0.0:
		_pulse_cd = 0.4
		var cage_r: float = wm.wstat("iron_maiden", "radius")
		var damage: float = wm.wstat("iron_maiden", "damage")
		var enemies: Array = world.query_enemies(global_position, cage_r + 16.0)
		for enemy in enemies:
			if enemy.global_position.distance_squared_to(global_position) > pow(cage_r - 26.0, 2.0):
				world.deal_damage(enemy, damage * 0.5, "iron_maiden",
					{"kb": (enemy.global_position - global_position).normalized() * 160.0, "no_crit": true})


func _draw() -> void:
	var wm := weapon_manager
	match kind:
		"relics":
			var orbit_radius: float = wm.wstat("orbiting_relics", "radius")
			var count := int(wm.wstat("orbiting_relics", "count"))
			var stone_r: float = 13.0 * wm.wstat("orbiting_relics", "size")
			var hardened: bool = wm.relic_harden_t > 0.0
			draw_arc(Vector2.ZERO, orbit_radius, 0, TAU, 48, Color(1.0, 0.85, 0.45, 0.10), 2.0)
			for i in count:
				var a := _angle + TAU * i / count
				var p := Vector2.from_angle(a) * orbit_radius
				var body := Color(0.55, 0.5, 0.62) if hardened else Color(0.78, 0.66, 0.4)
				draw_circle(p, stone_r + 5.0, Color(1.0, 0.85, 0.45, 0.22))
				draw_circle(p, stone_r, body)
				draw_circle(p, stone_r * 0.62, Color(0.32, 0.27, 0.2) if not hardened else Color(0.25, 0.22, 0.3))
				# rune line
				draw_line(p + Vector2(-stone_r * 0.4, 0), p + Vector2(stone_r * 0.4, 0), Color(1.0, 0.9, 0.6, 0.9), 2.0)
				draw_line(p + Vector2(0, -stone_r * 0.4), p + Vector2(0, stone_r * 0.2), Color(1.0, 0.9, 0.6, 0.9), 2.0)
		"tome":
			var flash := _glyph_flash
			# floating book: cover, pages, glow
			draw_circle(Vector2.ZERO, 18.0, Color(0.72, 0.64, 1.0, 0.14 + flash * 0.2))
			var tilt := sin(Time.get_ticks_msec() * 0.002 + _tome_index) * 0.15
			draw_set_transform(Vector2.ZERO, tilt, Vector2.ONE)
			draw_rect(Rect2(-11, -8, 22, 16), Color(0.36, 0.28, 0.55))
			draw_rect(Rect2(-9, -6.5, 18, 13), Color(0.92, 0.88, 0.8))
			draw_line(Vector2(0, -6.5), Vector2(0, 6.5), Color(0.5, 0.45, 0.4), 1.5)
			for i in 3:
				var y := -3.5 + i * 3.0
				draw_line(Vector2(-7, y), Vector2(-2, y), Color(0.6, 0.55, 0.7, 0.8), 1.0)
				draw_line(Vector2(2, y), Vector2(7, y), Color(0.6, 0.55, 0.7, 0.8), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if flash > 0.0:
				draw_arc(Vector2.ZERO, 20.0 + (1.0 - flash) * 14.0, 0, TAU, 20, Color(0.72, 0.64, 1.0, flash * 0.8), 2.0)
		"maiden":
			var cage_r: float = wm.wstat("iron_maiden", "radius")
			var fade := 1.0 - clampf((_maiden_t / _maiden_duration - 0.8) * 5.0, 0.0, 1.0)
			var grow := clampf(_maiden_t * 6.0, 0.0, 1.0)
			var r := cage_r * grow
			draw_arc(Vector2.ZERO, r, 0, TAU, 36, Color(0.85, 0.45, 0.35, 0.55 * fade), 3.0)
			for i in 12:
				var a2 := _angle + TAU * i / 12.0
				var inner := Vector2.from_angle(a2) * (r - 4.0)
				var outer := Vector2.from_angle(a2) * (r + 14.0)
				draw_line(inner, outer, Color(0.72, 0.42, 0.35, 0.9 * fade), 3.0)
				draw_line(inner, Vector2.from_angle(a2 + 0.06) * (r + 8.0), Color(0.55, 0.3, 0.28, 0.8 * fade), 2.0)
