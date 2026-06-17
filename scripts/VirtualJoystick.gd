class_name VirtualJoystick
extends Control
#
# 화면 가상 조이스틱(좌하단). 위/아래로 밀면 value.y 출력. 모바일 터치 크게.

@export var radius: float = 56.0
@export var knob_radius: float = 26.0

var value: Vector2 = Vector2.ZERO
var _active: bool = false
var _base: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _home: Vector2 = Vector2.ZERO


func _ready() -> void:
	size = Vector2(200, 230)
	position = Vector2(0, get_viewport_rect().size.y - size.y)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_home = Vector2(92, 150)
	_base = _home
	_knob = _home


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_active = true
			_base = event.position
			_knob = event.position
		else:
			_active = false
			value = Vector2.ZERO
			_knob = _home
			_base = _home
		queue_redraw()
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _active:
		var d: Vector2 = event.position - _base
		if d.length() > radius:
			d = d.normalized() * radius
		_knob = _base + d
		value = d / radius
		queue_redraw()


func _draw() -> void:
	var ring_col: Color = Color(1, 1, 1, 0.55)
	var faint: Color = Color(1, 1, 1, 0.12)
	var center: Vector2 = _base if _active else _home
	draw_circle(center, radius, faint)
	draw_arc(center, radius, 0.0, TAU, 48, ring_col, 3.0)
	draw_circle(_knob if _active else _home, knob_radius, Color(1, 1, 1, 0.68))
	# 위/아래 힌트 화살표
	var a: Color = Color(1, 1, 1, 0.35)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius - 14), center + Vector2(-8, -radius - 4), center + Vector2(8, -radius - 4)]), a)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, radius + 14), center + Vector2(-8, radius + 4), center + Vector2(8, radius + 4)]), a)
