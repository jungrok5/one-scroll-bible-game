class_name LightningFX
extends Node2D
#
# 번개 한 줄기 — glow 3겹 Line2D로 그리고 짧게 명멸 후 자동 소멸.
# 천지창조("빛이 있으라") 연출에 사용.

func strike(from: Vector2, to: Vector2, branches: int = 2) -> void:
	var pts := _gen(from, to, 7)
	_line(pts, 7.0, Color(0.30, 0.45, 1.0, 0.22))
	_line(pts, 3.5, Color(0.55, 0.70, 1.0, 0.45))
	_line(pts, 1.4, Color(1, 1, 1, 1))
	for i in branches:
		var a: Vector2 = pts[clampi(pts.size() / 2 + i, 0, pts.size() - 1)]
		var b: Vector2 = a + Vector2(randf_range(-40, 40), randf_range(30, 70))
		var bp := _gen(a, b, 4)
		_line(bp, 2.5, Color(0.55, 0.70, 1.0, 0.4))
		_line(bp, 1.0, Color(1, 1, 1, 0.9))

	var t := create_tween()
	t.tween_interval(0.16)
	t.tween_callback(queue_free)


func _gen(from: Vector2, to: Vector2, segs: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var f: float = float(i) / float(segs)
		var p: Vector2 = from.lerp(to, f)
		if i != 0 and i != segs:
			p.x += randf_range(-14, 14)
		pts.append(p)
	return pts


func _line(pts: PackedVector2Array, w: float, c: Color) -> void:
	var l := Line2D.new()
	l.points = pts
	l.width = w
	l.default_color = c
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(l)
