class_name Projectile
extends Node2D
## Pooled projectile for all weapons and enemy/boss shots.
## No physics bodies: hits are resolved with squared-distance checks against
## the GameWorld enemy grid (or the player, for hostile shots).
##
## kinds (visual identity): bolt, knife, arrow, chakram, spark, orb, shard

var world: Node2D
var active := false

var kind := "bolt"
var color := Color.WHITE
var dir := Vector2.RIGHT
var speed := 600.0
var damage := 10.0
var pierce := 0
var hit_radius := 14.0
var source := ""
var hostile := false
var crit_bonus := 0.0
var bleed := 0.0
var soulburst := false
var split := false
var behavior := "straight" # straight | chakram (out then return)
var max_distance := 99999.0
var size := 1.0
var on_return_knives := false # moonlit_blades synergy
var burn_dps := 0.0           # soulfire_covenant synergy
var burn_dur := 0.0

var _travel := 0.0
var _returning := false
var _lifetime := 0.0
var _hit_ids: Dictionary = {}
var _trail: Array = []
var _spin := 0.0


func setup(params: Dictionary) -> void:
	kind = params.get("kind", "bolt")
	color = params.get("color", Color.WHITE)
	global_position = params.get("pos", Vector2.ZERO)
	dir = params.get("dir", Vector2.RIGHT).normalized()
	speed = params.get("speed", 600.0)
	damage = params.get("damage", 10.0)
	pierce = int(params.get("pierce", 0))
	hit_radius = params.get("hit_radius", 14.0) * params.get("size", 1.0)
	source = params.get("source", "")
	hostile = params.get("hostile", false)
	crit_bonus = params.get("crit_bonus", 0.0)
	bleed = params.get("bleed", 0.0)
	soulburst = params.get("soulburst", false)
	split = params.get("split", false)
	behavior = params.get("behavior", "straight")
	max_distance = params.get("max_distance", params.get("range", 99999.0))
	size = params.get("size", 1.0)
	on_return_knives = params.get("on_return_knives", false)
	burn_dps = params.get("burn_dps", 0.0)
	burn_dur = params.get("burn_dur", 0.0)
	_travel = 0.0
	_returning = false
	_lifetime = params.get("lifetime", 4.0)
	_hit_ids.clear()
	_trail.clear()
	_spin = 0.0
	rotation = dir.angle()
	queue_redraw()


func _pool_activate() -> void:
	active = true
	visible = true
	set_physics_process(true)


func _pool_deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_lifetime -= delta
	if _lifetime <= 0.0:
		_despawn()
		return

	var step := speed * delta
	match behavior:
		"chakram":
			if not _returning:
				_travel += step
				global_position += dir * step
				if _travel >= max_distance:
					_returning = true
					_hit_ids.clear() # can hit the same enemies on the way back
					if on_return_knives and world != null:
						world.weapon_manager.spawn_moonlit_knives(global_position)
			else:
				var to_player: Vector2 = world.player.global_position - global_position
				if to_player.length_squared() < 900.0:
					_despawn()
					return
				dir = dir.lerp(to_player.normalized(), 8.0 * delta).normalized()
				global_position += dir * step * 1.25
			_spin += delta * 14.0
			rotation = _spin
		_:
			_travel += step
			global_position += dir * step
			if _travel >= max_distance:
				_despawn()
				return
			if kind == "knife":
				_spin += delta * 10.0
				rotation = dir.angle() + 0.0
			else:
				rotation = dir.angle()

	# Trail ghost positions (drawn in _draw).
	_trail.push_front(global_position)
	if _trail.size() > 6:
		_trail.pop_back()

	# Out of arena? despawn (with margin).
	var half: Vector2 = GameData.ARENA_HALF + Vector2(160, 160)
	if absf(global_position.x) > half.x or absf(global_position.y) > half.y:
		_despawn()
		return

	if hostile:
		_check_player_hit()
	else:
		_check_enemy_hits()
	queue_redraw()


func _check_player_hit() -> void:
	var player: Node2D = world.player
	if player == null or not player.alive:
		return
	if global_position.distance_squared_to(player.global_position) < pow(hit_radius + 16.0, 2.0):
		player.take_damage(damage, global_position)
		_despawn()


func _check_enemy_hits() -> void:
	var hits: Array = world.query_enemies(global_position, hit_radius + 16.0)
	for enemy in hits:
		var eid: int = enemy.get_instance_id()
		if _hit_ids.has(eid):
			continue
		_hit_ids[eid] = true
		world.deal_damage(enemy, damage, source, {"crit_bonus": crit_bonus, "kb": dir * 90.0})
		if bleed > 0.0 and enemy.alive:
			enemy.apply_bleed(damage * bleed / 2.0, 2.0)
		if burn_dps > 0.0 and enemy.alive:
			enemy.apply_burn(burn_dps, burn_dur)
		if soulburst and not enemy.alive:
			world.area_damage(global_position, 70.0, damage * 0.5, source, Color(0.5, 0.85, 1.0))
		if split and not _returning:
			split = false
			var perp := dir.orthogonal()
			for s in [-1.0, 1.0]:
				world.spawn_projectile({"kind": kind, "color": color, "pos": global_position,
					"dir": (dir + perp * s * 0.5).normalized(), "speed": speed * 0.9,
					"damage": damage * 0.5, "pierce": 0, "source": source, "size": size * 0.8,
					"max_distance": 300.0})
		pierce -= 1
		if pierce < 0:
			_despawn()
			return


func _despawn() -> void:
	if active and world != null:
		world.release_projectile(self)


func _draw() -> void:
	if not active:
		return
	# Trail (positions are global; convert to local space).
	for i in _trail.size():
		var p: Vector2 = to_local(_trail[i])
		var a := (1.0 - float(i) / 6.0) * 0.35
		draw_circle(p, (4.0 + size * 2.0) * (1.0 - float(i) / 7.0), Color(color.r, color.g, color.b, a * color.a))
	var c := color
	var glow_c := Color(c.r, c.g, c.b, 0.28)
	# hostile shots get a pulsing red danger ring so threats read instantly
	if hostile:
		var danger_pulse := 0.45 + 0.25 * sin(Time.get_ticks_msec() * 0.018)
		draw_arc(Vector2.ZERO, 13.0 * size, 0, TAU, 18, Color(1.0, 0.28, 0.28, danger_pulse), 2.0)
	match kind:
		"bolt":
			draw_circle(Vector2.ZERO, 10.0 * size, glow_c)
			draw_circle(Vector2.ZERO, 5.0 * size, c)
			draw_circle(Vector2(-7.0 * size, 0), 3.0 * size, Color(c.r, c.g, c.b, 0.6))
		"knife":
			var pts := PackedVector2Array([Vector2(10, 0) * size, Vector2(-6, 4) * size, Vector2(-3, 0) * size, Vector2(-6, -4) * size])
			draw_colored_polygon(pts, c)
			draw_circle(Vector2.ZERO, 8.0 * size, glow_c)
		"arrow":
			draw_line(Vector2(-16, 0) * size, Vector2(10, 0) * size, c, 2.5 * size)
			var head := PackedVector2Array([Vector2(16, 0) * size, Vector2(8, 5) * size, Vector2(8, -5) * size])
			draw_colored_polygon(head, c)
			draw_circle(Vector2.ZERO, 9.0 * size, glow_c)
		"chakram":
			draw_arc(Vector2.ZERO, 10.0 * size, 0.6, TAU - 0.6, 14, c, 3.5 * size)
			draw_circle(Vector2.ZERO, 12.0 * size, glow_c)
		"spark":
			draw_circle(Vector2.ZERO, 7.0 * size, glow_c)
			draw_circle(Vector2.ZERO, 3.5 * size, c)
		"orb":
			var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.2
			draw_circle(Vector2.ZERO, 9.0 * size * pulse, glow_c)
			draw_circle(Vector2.ZERO, 6.0 * size, c)
			draw_circle(Vector2.ZERO, 2.5 * size, Color(1, 1, 1, 0.8))
		"shard":
			var pts := PackedVector2Array([Vector2(9, 0) * size, Vector2(-7, 6) * size, Vector2(-4, 0) * size, Vector2(-7, -6) * size])
			draw_colored_polygon(pts, c)
			draw_circle(Vector2.ZERO, 10.0 * size, glow_c)
