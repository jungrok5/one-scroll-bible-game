class_name Player
extends Node2D
#
# 상하좌우 자유 이동(RPG). 좌우 경계는 Main이 위치별로 알려줌(섬=넓게, 부두=좁게).

@export var speed: float = 120.0

var joystick: VirtualJoystick = null
var bounds_provider: Callable = Callable()   # func(y) -> Vector2(min_x, max_x)
var min_y: float = 0.0
var max_y: float = 0.0
var locked: bool = false
var auto_dir: Vector2 = Vector2.ZERO          # E2E 오토플레이용

var _sprite: Sprite2D
var _bob_t: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/player.png")
	_sprite.scale = Vector2(2, 2)
	add_child(_sprite)


func _process(delta: float) -> void:
	if locked:
		return
	var v := Vector2.ZERO
	if joystick != null:
		v += joystick.value
	v.x += Input.get_axis("move_left", "move_right")
	v.y += Input.get_axis("move_up", "move_down")
	v += auto_dir
	v.x = clampf(v.x, -1.0, 1.0)
	v.y = clampf(v.y, -1.0, 1.0)
	if v.length() > 1.0:
		v = v.normalized()

	position += v * speed * delta
	position.y = clampf(position.y, min_y, max_y)
	if bounds_provider.is_valid():
		var b: Vector2 = bounds_provider.call(position.y)
		position.x = clampf(position.x, b.x, b.y)

	# 걷는 바운스 + 좌우 방향
	if v.length() > 0.05:
		_bob_t += delta * 12.0
		_sprite.position.y = -absf(sin(_bob_t)) * 2.0
		if absf(v.x) > 0.05:
			_sprite.flip_h = v.x < 0.0
	else:
		_bob_t = 0.0
		_sprite.position.y = 0.0
