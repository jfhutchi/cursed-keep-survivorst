class_name XpOrb
extends Node2D
## Pooled soul shard. Bobs in place, magnetizes to the player inside their
## pickup radius, and grants XP on contact.

var world: Node2D
var active := false

var value := 1.0
var _t := 0.0
var _magnet := false
var _vel := Vector2.ZERO
var _force_magnet := false # magnet pickup pulls everything


func setup(pos: Vector2, xp_value: float) -> void:
	global_position = pos + Vector2(randf_range(-12, 12), randf_range(-12, 12))
	value = xp_value
	_t = randf() * TAU
	_magnet = false
	_force_magnet = false
	_vel = Vector2(randf_range(-40, 40), randf_range(-40, 40))
	queue_redraw()


func force_magnet() -> void:
	_force_magnet = true


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
	_t += delta * 3.0
	var player: Node2D = world.player
	if player == null or not player.alive:
		queue_redraw()
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist_sq := to_player.length_squared()
	var pickup_r: float = player.stats["pickup_radius"]
	if _force_magnet or dist_sq < pickup_r * pickup_r:
		_magnet = true
	if _magnet:
		var speed := clampf(620.0 - sqrt(dist_sq), 260.0, 760.0)
		_vel = _vel.lerp(to_player.normalized() * speed, 10.0 * delta)
		global_position += _vel * delta
		if dist_sq < 560.0:
			_collect(player)
			return
	else:
		# settle drift
		_vel = _vel.lerp(Vector2.ZERO, 4.0 * delta)
		global_position += _vel * delta
	queue_redraw()


func _collect(player: Node2D) -> void:
	AudioManager.play(&"xp_pickup", -6.0, 0.12)
	world.spawn_fx({"kind": "soul_swirl", "pos": player.global_position, "color": Color(0.55, 0.85, 1.0)})
	player.gain_xp(value)
	world.release_orb(self)


func _draw() -> void:
	if not active:
		return
	var bob := sin(_t) * 2.0
	var pulse := 0.85 + 0.15 * sin(_t * 1.7)
	var c := Color(0.55, 0.85, 1.0)
	if value >= 5.0:
		c = Color(0.75, 0.6, 1.0) # bigger souls glow violet
	elif value >= 3.0:
		c = Color(0.5, 1.0, 0.9)
	var p := Vector2(0, bob)
	draw_circle(p, 8.0 * pulse, Color(c.r, c.g, c.b, 0.22))
	var pts := PackedVector2Array([p + Vector2(0, -6), p + Vector2(4, 0), p + Vector2(0, 6), p + Vector2(-4, 0)])
	draw_colored_polygon(pts, c)
	draw_circle(p + Vector2(-1, -2), 1.4, Color(1, 1, 1, 0.9))
