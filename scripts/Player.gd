class_name Player
extends Node2D
#
# 위/아래로만 움직이는 플레이어. 조이스틱 value.y + 키보드(move_up/move_down).

@export var speed: float = 130.0

var joystick: VirtualJoystick = null
var min_y: float = 0.0
var max_y: float = 0.0
var locked: bool = false
var auto_dir: float = 0.0   # E2E 오토플레이 전용(-1=위). 평상시 0.

var _sprite: Sprite2D
var _bob_t: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/player.png")
	_sprite.scale = Vector2(1, 1)
	add_child(_sprite)


func _process(delta: float) -> void:
	if locked:
		return
	var vy: float = auto_dir
	if joystick != null:
		vy += joystick.value.y
	vy += Input.get_axis("move_up", "move_down")
	vy = clampf(vy, -1.0, 1.0)

	position.y += vy * speed * delta
	position.y = clampf(position.y, min_y, max_y)

	# 걷는 느낌의 가벼운 바운스
	if absf(vy) > 0.05:
		_bob_t += delta * 12.0
		_sprite.position.y = -sin(_bob_t) * 1.5
	else:
		_bob_t = 0.0
		_sprite.position.y = 0.0
