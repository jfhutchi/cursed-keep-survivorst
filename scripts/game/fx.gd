class_name Fx
extends Node2D
## Pooled, draw-based visual effect. One node animates one short effect.
##
## kinds: sweep, nova, ring, flame_cone, lightning, burst, ghost, levelup,
##        warning_line, soul_swirl, hit, shockwave, boss_warning, mark_pop

var world: Node2D
var active := false

var kind := "burst"
var color := Color.WHITE
var duration := 0.4
var size := 1.0
var radius := 60.0
var angle := 0.0
var arc_deg := 180.0
var points: PackedVector2Array = PackedVector2Array()
var texture: Texture2D
var flip := false
var length := 200.0
var width := 40.0

var _t := 0.0
var _seed := 0


func setup(params: Dictionary) -> void:
	kind = params.get("kind", "burst")
	color = params.get("color", Color.WHITE)
	global_position = params.get("pos", Vector2.ZERO)
	duration = params.get("duration", _default_duration(kind))
	size = params.get("size", 1.0)
	radius = params.get("radius", 60.0)
	angle = params.get("angle", 0.0)
	arc_deg = params.get("arc_deg", 180.0)
	points = params.get("points", PackedVector2Array())
	texture = params.get("texture", null)
	flip = params.get("flip", false)
	length = params.get("length", 200.0)
	width = params.get("width", 40.0)
	_t = 0.0
	_seed = randi()
	rotation = 0.0
	queue_redraw()


static func _default_duration(k: String) -> float:
	match k:
		"sweep": return 0.32
		"nova": return 0.45
		"ring": return 0.6
		"flame_cone": return 0.4
		"lightning": return 0.22
		"ghost": return 0.3
		"levelup": return 0.8
		"warning_line": return 0.8
		"soul_swirl": return 0.35
		"hit": return 0.18
		"shockwave": return 0.4
		"boss_warning": return 2.0
		"mark_pop": return 0.5
	return 0.4


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
	if _t >= duration:
		world.release_fx(self)
		return
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var p := clampf(_t / duration, 0.0, 1.0)
	var fade := 1.0 - p
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	match kind:
		"sweep":
			# rotating arc fan (Blood Scythe and similar melee sweeps)
			var a0 := angle - deg_to_rad(arc_deg) * 0.5
			var swept := deg_to_rad(arc_deg) * minf(p * 1.6, 1.0)
			var pts := PackedVector2Array([Vector2.ZERO])
			for i in 13:
				var a := a0 + swept * float(i) / 12.0
				pts.append(Vector2.from_angle(a) * radius)
			draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.30 * fade))
			var edge := a0 + swept
			draw_line(Vector2.ZERO, Vector2.from_angle(edge) * radius, Color(color.r, color.g, color.b, 0.9 * fade), 4.0)
			draw_arc(Vector2.ZERO, radius * 0.97, a0, edge, 20, Color(color.r, color.g, color.b, 0.8 * fade), 3.0)
		"nova":
			var r := radius * (0.2 + 0.8 * p)
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(color.r, color.g, color.b, fade), 7.0 * fade + 2.0)
			draw_circle(Vector2.ZERO, r * 0.95, Color(color.r, color.g, color.b, 0.10 * fade))
		"ring":
			var r2 := radius * p
			draw_arc(Vector2.ZERO, r2, 0, TAU, 48, Color(color.r, color.g, color.b, fade * 0.85), 5.0)
			draw_arc(Vector2.ZERO, r2 * 0.85, 0, TAU, 40, Color(color.r, color.g, color.b, fade * 0.4), 2.0)
		"flame_cone":
			var half_rad := deg_to_rad(arc_deg) * 0.5
			for i in 14:
				var a := angle + rng.randf_range(-half_rad, half_rad)
				var dist := length * rng.randf_range(0.2, 1.0) * (0.4 + p)
				var fp := Vector2.from_angle(a) * dist
				var r3 := rng.randf_range(6.0, 16.0) * (1.0 - dist / (length * 1.4))
				var col := color.lerp(Color(0.7, 0.2, 0.9), rng.randf() * 0.6)
				draw_circle(fp, r3 * (1.0 + p), Color(col.r, col.g, col.b, 0.35 * fade))
		"lightning":
			if points.size() >= 2:
				var flick := 0.6 + 0.4 * sin(_t * 60.0)
				for i in points.size() - 1:
					var a4 := to_local(points[i])
					var b4 := to_local(points[i + 1])
					var mid := (a4 + b4) * 0.5 + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
					draw_line(a4, mid, Color(1, 1, 1, fade * flick), 2.0)
					draw_line(mid, b4, Color(1, 1, 1, fade * flick), 2.0)
					draw_line(a4, b4, Color(color.r, color.g, color.b, fade * 0.6 * flick), 5.0)
		"burst":
			for i in 10:
				var a5 := TAU * i / 10.0 + rng.randf() * 0.6
				var d5 := radius * 0.8 * p * size
				var pp := Vector2.from_angle(a5) * d5
				draw_circle(pp, (5.0 - 4.0 * p) * size, Color(color.r, color.g, color.b, fade))
			draw_circle(Vector2.ZERO, radius * 0.35 * p * size, Color(color.r, color.g, color.b, 0.25 * fade))
		"ghost":
			if texture != null:
				var tex_size := texture.get_size()
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1 if flip else 1, 1))
				draw_texture_rect(texture, Rect2(-tex_size * 0.5, tex_size), false, Color(color.r, color.g, color.b, 0.5 * fade))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"levelup":
			var r6 := 30.0 + 140.0 * p
			draw_arc(Vector2.ZERO, r6, 0, TAU, 40, Color(color.r, color.g, color.b, fade), 6.0)
			for i in 8:
				var a6 := TAU * i / 8.0
				var d6 := r6 * 0.8
				draw_line(Vector2.from_angle(a6) * d6 * 0.5, Vector2.from_angle(a6) * d6, Color(1.0, 0.95, 0.7, fade), 3.0)
		"warning_line":
			var blink := 0.4 + 0.6 * absf(sin(_t * 14.0))
			var dir6 := Vector2.from_angle(angle)
			var perp := dir6.orthogonal() * width * 0.5
			var quad := PackedVector2Array([perp, dir6 * length + perp, dir6 * length - perp, -perp])
			draw_colored_polygon(quad, Color(1.0, 0.25, 0.2, 0.16 * blink))
			draw_line(perp, dir6 * length + perp, Color(1.0, 0.3, 0.25, 0.7 * blink), 2.0)
			draw_line(-perp, dir6 * length - perp, Color(1.0, 0.3, 0.25, 0.7 * blink), 2.0)
		"soul_swirl":
			for i in 5:
				var a7 := TAU * i / 5.0 + p * 7.0
				var d7 := 14.0 * (1.0 - p)
				draw_circle(Vector2.from_angle(a7) * d7, 2.5 * fade + 0.5, Color(color.r, color.g, color.b, fade))
		"hit":
			for i in 4:
				var a8 := TAU * i / 4.0 + rng.randf() * 1.5
				draw_line(Vector2.from_angle(a8) * 3.0, Vector2.from_angle(a8) * (8.0 + 10.0 * p) * size, Color(1, 1, 1, fade), 2.0)
		"shockwave":
			var r8 := radius * p
			draw_arc(Vector2.ZERO, r8, 0, TAU, 36, Color(color.r, color.g, color.b, fade * 0.7), 8.0 * fade + 1.0)
		"boss_warning":
			var blink2 := 0.5 + 0.5 * sin(_t * 10.0)
			draw_arc(Vector2.ZERO, radius * (0.9 + 0.1 * sin(_t * 6.0)), 0, TAU, 48, Color(1.0, 0.2, 0.3, 0.5 * blink2), 6.0)
			draw_line(Vector2(0, -radius * 0.4), Vector2(0, radius * 0.15), Color(1.0, 0.3, 0.3, blink2), 8.0)
			draw_circle(Vector2(0, radius * 0.32), 5.0, Color(1.0, 0.3, 0.3, blink2))
		"mark_pop":
			draw_arc(Vector2.ZERO, 16.0 + 10.0 * p, 0, TAU, 20, Color(color.r, color.g, color.b, fade), 2.0)
			draw_line(Vector2(-6, -2), Vector2(0, 6), Color(color.r, color.g, color.b, fade), 2.0)
			draw_line(Vector2(0, 6), Vector2(8, -6), Color(color.r, color.g, color.b, fade), 2.0)
