class_name Fx
extends RefCounted
#
# 날씨/분위기 파티클 팩토리(웹 안전한 CPUParticles2D). tex = dot.png.

static func particles(kind: String, tex: Texture2D, width: float = 180.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex
	p.amount = 24
	p.lifetime = 5.0
	p.preprocess = 3.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width, 12.0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	match kind:
		"motes":
			p.gravity = Vector2(0, -6)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 12.0
			p.color = Color(1.0, 0.95, 0.7, 0.8)
			p.material = add
		"stars":
			p.amount = 44
			p.lifetime = 3.0
			p.gravity = Vector2.ZERO
			p.initial_velocity_min = 0.0
			p.initial_velocity_max = 2.0
			p.scale_amount_min = 0.3
			p.scale_amount_max = 0.8
			p.color = Color(0.85, 0.92, 1.0, 0.9)
			p.material = add
		"petals":
			p.gravity = Vector2(0, 18)
			p.initial_velocity_min = 6.0
			p.initial_velocity_max = 16.0
			p.angular_velocity_min = -80.0
			p.angular_velocity_max = 80.0
			p.color = Color(0.62, 0.42, 0.32, 0.9)
		"rain":
			p.amount = 70
			p.lifetime = 1.3
			p.gravity = Vector2(0, 220)
			p.direction = Vector2(0.12, 1.0)
			p.initial_velocity_min = 120.0
			p.initial_velocity_max = 170.0
			p.scale_amount_min = 0.3
			p.scale_amount_max = 0.6
			p.color = Color(0.62, 0.72, 0.86, 0.5)
		"embers":
			p.gravity = Vector2(0, -22)
			p.initial_velocity_min = 8.0
			p.initial_velocity_max = 22.0
			p.color = Color(1.0, 0.62, 0.25, 0.9)
			p.material = add
	p.emitting = true
	return p
