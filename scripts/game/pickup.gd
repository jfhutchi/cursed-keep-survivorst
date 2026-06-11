class_name Pickup
extends Node2D
## Pooled rare pickup dropped by elites: health vial or soul magnet.

var world: Node2D
var active := false

var kind := "health" # health | magnet
var _t := 0.0


func setup(pos: Vector2, pickup_kind: String) -> void:
	global_position = pos
	kind = pickup_kind
	_t = 0.0
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
	var player: Node2D = world.player
	if player == null or not player.alive:
		return
	var pickup_r: float = maxf(40.0, player.stats["pickup_radius"] * 0.6)
	if global_position.distance_squared_to(player.global_position) < pickup_r * pickup_r:
		_collect(player)
		return
	queue_redraw()


func _collect(player: Node2D) -> void:
	match kind:
		"health":
			player.heal(25.0)
			world.spawn_text(global_position, "+25", Color(0.5, 1.0, 0.6), 14)
		"magnet":
			AudioManager.play(&"heal", 0.0, 0.2)
			world.magnetize_all_orbs()
			world.spawn_fx({"kind": "nova", "pos": global_position, "color": Color(0.6, 0.8, 1.0), "radius": 120.0})
	world.release_pickup(self)


func _draw() -> void:
	if not active:
		return
	var bob := sin(_t * 3.0) * 3.0
	var p := Vector2(0, bob)
	match kind:
		"health":
			draw_circle(p, 11.0, Color(0.9, 0.2, 0.3, 0.2))
			draw_rect(Rect2(p + Vector2(-7, -2.5), Vector2(14, 5)), Color(0.95, 0.3, 0.4))
			draw_rect(Rect2(p + Vector2(-2.5, -7), Vector2(5, 14)), Color(0.95, 0.3, 0.4))
		"magnet":
			draw_circle(p, 11.0, Color(0.4, 0.7, 1.0, 0.2))
			draw_arc(p, 8.0, PI * 0.15, PI * 0.85, 12, Color(0.55, 0.8, 1.0), 4.0)
			draw_line(p + Vector2(-6, 2), p + Vector2(-6, 8), Color(0.9, 0.95, 1.0), 4.0)
			draw_line(p + Vector2(6, 2), p + Vector2(6, 8), Color(0.9, 0.95, 1.0), 4.0)
