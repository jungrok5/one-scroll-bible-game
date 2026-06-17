class_name LightRays
extends Node2D
#
# 가산혼합 빛기둥 부채꼴 — 창조/예수님/회복의 빛내림 연출.

var _t: float = 0.0
var rays: int = 9
var length: float = 540.0
var col: Color = Color(1, 1, 1, 0.5)


func setup(c: Color, n: int = 9, l: float = 540.0) -> void:
	col = c
	rays = n
	length = l


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in rays:
		var ang: float = -PI / 2.0 + (float(i) - float(rays - 1) / 2.0) * 0.17 + sin(_t * 0.6 + i) * 0.015
		var dir := Vector2(cos(ang), sin(ang))
		var perp := Vector2(-dir.y, dir.x)
		var w: float = 9.0 + 5.0 * sin(_t * 1.3 + i * 1.7)
		var tip: Vector2 = dir * length
		var a: float = col.a * (0.45 + 0.55 * absf(sin(_t * 0.8 + i)))
		draw_colored_polygon(
			PackedVector2Array([perp * 3.0, -perp * 3.0, tip - perp * w, tip + perp * w]),
			Color(col.r, col.g, col.b, a * 0.5)
		)
