class_name Player
extends Node2D
#
# 상하좌우 자유 이동 + 4방향 걷기 애니(Ninja Adventure 시트: 4열=방향, 행=프레임).
# 좌우 경계는 Main이 위치별로 알려줌(섬=넓게, 부두=좁게).

@export var speed: float = 120.0

var joystick: VirtualJoystick = null
var bounds_provider: Callable = Callable()
var min_y: float = 0.0
var max_y: float = 0.0
var locked: bool = false
var auto_dir: Vector2 = Vector2.ZERO

var _sprite: Sprite2D
var _facing_col: int = 0      # 0=down, 1=up, 2=side
var _anim_t: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/player_sheet.png")
	_sprite.hframes = 4
	_sprite.vframes = 7
	_sprite.frame = 0
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

	if v.length() > 0.06:
		if absf(v.x) >= absf(v.y):
			_facing_col = 2
			_sprite.flip_h = v.x < 0.0
		else:
			_facing_col = 0 if v.y > 0.0 else 1
			_sprite.flip_h = false
		_anim_t += delta * 8.0
		var row: int = (int(_anim_t) % 3) + 1     # 행 1~3 = 걷기 프레임
		_sprite.frame = row * 4 + _facing_col
	else:
		_sprite.frame = _facing_col                 # 행 0 = 정지
