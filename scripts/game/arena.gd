class_name Arena
extends Node2D
## Builds the cursed keep interior procedurally from generated SVG decals:
## stone floor, cracks, sigils, border walls, pillars, flickering torches,
## drifting curse-fog and ambient dust. Pure visuals — gameplay bounds are
## enforced by position clamping (GameData.ARENA_HALF).

const FLOOR_TILES := [
	"res://assets/generated/environment/floor_a.svg",
	"res://assets/generated/environment/floor_b.svg",
]
const FLOOR_CRACK := "res://assets/generated/environment/floor_crack.svg"
const SIGIL := "res://assets/generated/environment/floor_sigil.svg"
const PILLAR := "res://assets/generated/environment/pillar.svg"
const TORCH := "res://assets/generated/environment/torch.svg"

var _torch_glows: Array = []
var _fog_sprites: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var half: Vector2 = GameData.ARENA_HALF

	# Base floor
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.075, 0.06, 0.10)
	floor_rect.position = -half - Vector2(40, 40)
	floor_rect.size = half * 2.0 + Vector2(80, 80)
	floor_rect.z_index = -30
	add_child(floor_rect)

	# Outer void beyond the walls
	var void_rect := ColorRect.new()
	void_rect.color = Color(0.025, 0.018, 0.04)
	void_rect.position = -half - Vector2(640, 640)
	void_rect.size = half * 2.0 + Vector2(1280, 1280)
	void_rect.z_index = -40
	add_child(void_rect)

	# Floor tiles (large worn stone slabs)
	var tile_textures: Array = []
	for path: String in FLOOR_TILES:
		tile_textures.append(load(path))
	var crack_tex: Texture2D = load(FLOOR_CRACK)
	for i in 150:
		var s := Sprite2D.new()
		s.texture = tile_textures[rng.randi() % tile_textures.size()]
		s.position = Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y))
		s.rotation = (rng.randi() % 4) * PI * 0.5
		s.modulate = Color(1, 1, 1, rng.randf_range(0.25, 0.7))
		s.z_index = -28
		add_child(s)
	for i in 46:
		var c := Sprite2D.new()
		c.texture = crack_tex
		c.position = Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y))
		c.rotation = rng.randf() * TAU
		c.modulate = Color(1, 1, 1, rng.randf_range(0.2, 0.55))
		c.z_index = -27
		add_child(c)

	# Broken sigils (faint green/purple glow)
	var sigil_tex: Texture2D = load(SIGIL)
	for i in 9:
		var sg := Sprite2D.new()
		sg.texture = sigil_tex
		sg.position = Vector2(rng.randf_range(-half.x * 0.85, half.x * 0.85), rng.randf_range(-half.y * 0.85, half.y * 0.85))
		sg.rotation = rng.randf() * TAU
		sg.modulate = Color(1, 1, 1, rng.randf_range(0.35, 0.6))
		sg.z_index = -26
		add_child(sg)

	_build_walls(half, rng)
	_build_banners(half, rng)
	_build_rubble(half, rng)
	_build_fog(half, rng)
	_build_dust(half)
	set_process(true)


func _build_walls(half: Vector2, rng: RandomNumberGenerator) -> void:
	# Wall band drawn as border rectangles + pillars with torches
	var wall_color := Color(0.045, 0.035, 0.07)
	var trim_color := Color(0.22, 0.16, 0.30)
	for side in 4:
		var wall := ColorRect.new()
		wall.color = wall_color
		wall.z_index = -24
		var trim := ColorRect.new()
		trim.color = trim_color
		trim.z_index = -23
		match side:
			0: # top
				wall.position = Vector2(-half.x - 40, -half.y - 200)
				wall.size = Vector2(half.x * 2 + 80, 200)
				trim.position = Vector2(-half.x - 40, -half.y - 6)
				trim.size = Vector2(half.x * 2 + 80, 6)
			1: # bottom
				wall.position = Vector2(-half.x - 40, half.y)
				wall.size = Vector2(half.x * 2 + 80, 200)
				trim.position = Vector2(-half.x - 40, half.y)
				trim.size = Vector2(half.x * 2 + 80, 6)
			2: # left
				wall.position = Vector2(-half.x - 200, -half.y - 40)
				wall.size = Vector2(200, half.y * 2 + 80)
				trim.position = Vector2(-half.x - 6, -half.y - 40)
				trim.size = Vector2(6, half.y * 2 + 80)
			3: # right
				wall.position = Vector2(half.x, -half.y - 40)
				wall.size = Vector2(200, half.y * 2 + 80)
				trim.position = Vector2(half.x, -half.y - 40)
				trim.size = Vector2(6, half.y * 2 + 80)
		add_child(wall)
		add_child(trim)

	var pillar_tex: Texture2D = load(PILLAR)
	var torch_tex: Texture2D = load(TORCH)
	var glow_tex := _radial_glow_texture(Color(1.0, 0.55, 0.25))
	# pillars along top and bottom walls; torches on every second pillar
	var idx := 0
	for x in range(int(-half.x) + 150, int(half.x) - 100, 300):
		for y_sign in [-1.0, 1.0]:
			var p := Sprite2D.new()
			p.texture = pillar_tex
			p.position = Vector2(x + rng.randf_range(-20, 20), y_sign * (half.y - 10))
			p.z_index = -22
			add_child(p)
			if idx % 2 == 0:
				var torch := Sprite2D.new()
				torch.texture = torch_tex
				torch.position = p.position + Vector2(0, -34)
				torch.z_index = -21
				add_child(torch)
				var glow := Sprite2D.new()
				glow.texture = glow_tex
				glow.position = torch.position + Vector2(0, -16)
				glow.z_index = -21
				glow.modulate = Color(1, 0.7, 0.35, 0.4)
				add_child(glow)
				_torch_glows.append({"node": glow, "phase": rng.randf() * TAU})
			idx += 1
	# side pillars
	for y in range(int(-half.y) + 180, int(half.y) - 120, 320):
		for x_sign in [-1.0, 1.0]:
			var p2 := Sprite2D.new()
			p2.texture = pillar_tex
			p2.position = Vector2(x_sign * (half.x - 16), y)
			p2.z_index = -22
			add_child(p2)


## Torn ceremonial banners hanging from the top wall between pillars.
func _build_banners(half: Vector2, rng: RandomNumberGenerator) -> void:
	for x in range(int(-half.x) + 300, int(half.x) - 200, 600):
		var banner := Polygon2D.new()
		var w := 26.0
		var drop := rng.randf_range(60.0, 86.0)
		# torn hem: jagged bottom edge
		banner.polygon = PackedVector2Array([
			Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0),
			Vector2(w * 0.5, drop * 0.8), Vector2(w * 0.2, drop),
			Vector2(0, drop * 0.85), Vector2(-w * 0.25, drop * 0.97),
			Vector2(-w * 0.5, drop * 0.78),
		])
		banner.color = Color(0.32, 0.12, 0.25) if rng.randf() < 0.5 else Color(0.18, 0.13, 0.34)
		banner.position = Vector2(x + rng.randf_range(-30, 30), -half.y + 4)
		banner.z_index = -20
		add_child(banner)
		var trim := Line2D.new()
		trim.points = PackedVector2Array([Vector2(-w * 0.5, 3), Vector2(w * 0.5, 3)])
		trim.width = 3.0
		trim.default_color = Color(0.72, 0.58, 0.32, 0.9)
		banner.add_child(trim)
		var glyph := Line2D.new()
		glyph.points = PackedVector2Array([Vector2(0, drop * 0.25), Vector2(6, drop * 0.42), Vector2(0, drop * 0.58), Vector2(-6, drop * 0.42), Vector2(0, drop * 0.25)])
		glyph.width = 2.0
		glyph.default_color = Color(0.85, 0.71, 0.42, 0.55)
		banner.add_child(glyph)


## Rubble stones and old bone piles scattered across the floor.
func _build_rubble(half: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 30:
		var rock := Polygon2D.new()
		var r := rng.randf_range(5.0, 14.0)
		var pts := PackedVector2Array()
		var sides := 5 + rng.randi() % 3
		for s in sides:
			var a := TAU * s / sides + rng.randf_range(-0.25, 0.25)
			pts.append(Vector2.from_angle(a) * r * rng.randf_range(0.7, 1.2))
		rock.polygon = pts
		var shade := rng.randf_range(0.10, 0.17)
		rock.color = Color(shade + 0.02, shade, shade + 0.05)
		rock.position = Vector2(rng.randf_range(-half.x * 0.95, half.x * 0.95), rng.randf_range(-half.y * 0.95, half.y * 0.95))
		rock.rotation = rng.randf() * TAU
		rock.z_index = -25
		add_child(rock)
	for i in 9:
		var pile := Node2D.new()
		pile.position = Vector2(rng.randf_range(-half.x * 0.9, half.x * 0.9), rng.randf_range(-half.y * 0.9, half.y * 0.9))
		pile.z_index = -25
		add_child(pile)
		for b in 3 + rng.randi() % 3:
			var bone := Polygon2D.new()
			var half_len := rng.randf_range(8.0, 16.0)
			bone.polygon = PackedVector2Array([Vector2(-half_len, -1.6), Vector2(half_len, -1.1), Vector2(half_len, 1.1), Vector2(-half_len, 1.6)])
			bone.color = Color(0.55, 0.52, 0.44, rng.randf_range(0.5, 0.8))
			bone.position = Vector2(rng.randf_range(-10, 10), rng.randf_range(-8, 8))
			bone.rotation = rng.randf() * TAU
			pile.add_child(bone)


func _build_fog(half: Vector2, rng: RandomNumberGenerator) -> void:
	var fog_tex := _radial_glow_texture(Color(0.5, 0.3, 0.8))
	for i in 7:
		var fog := Sprite2D.new()
		fog.texture = fog_tex
		fog.position = Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y))
		fog.scale = Vector2.ONE * rng.randf_range(3.0, 6.5)
		fog.modulate = Color(0.55, 0.35, 0.85, rng.randf_range(0.04, 0.09))
		fog.z_index = -19
		add_child(fog)
		_fog_sprites.append({"node": fog, "vel": Vector2(rng.randf_range(-9, 9), rng.randf_range(-6, 6)), "half": half})


func _build_dust(half: Vector2) -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 70
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = half
	dust.gravity = Vector2(2.0, -4.0)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 9.0
	dust.scale_amount_min = 0.7
	dust.scale_amount_max = 1.8
	dust.color = Color(0.75, 0.7, 0.95, 0.16)
	dust.z_index = -18
	add_child(dust)


static func _radial_glow_texture(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(color.r, color.g, color.b, 1.0), Color(color.r, color.g, color.b, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 128
	tex.height = 128
	return tex


func _process(delta: float) -> void:
	_t += delta
	for torch: Dictionary in _torch_glows:
		var glow: Sprite2D = torch["node"]
		var phase: float = torch["phase"]
		var flicker := 0.32 + 0.13 * sin(_t * 9.0 + phase) + 0.06 * sin(_t * 23.0 + phase * 2.0)
		glow.modulate.a = flicker
		glow.scale = Vector2.ONE * (1.0 + 0.1 * sin(_t * 7.0 + phase))
	for fog: Dictionary in _fog_sprites:
		var node: Sprite2D = fog["node"]
		node.position += fog["vel"] * delta
		var half: Vector2 = fog["half"]
		if absf(node.position.x) > half.x:
			fog["vel"].x *= -1.0
		if absf(node.position.y) > half.y:
			fog["vel"].y *= -1.0
