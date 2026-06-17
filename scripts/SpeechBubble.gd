class_name SpeechBubble
extends Node2D
#
# NPC 머리 위 말풍선(월드 공간). 플레이어가 가까이 오면 appear(), 멀어지면 vanish().

const W := 192.0

var _panel: Panel
var _label: Label
var _bg := Color(0.09, 0.11, 0.17, 0.96)
var _shown := false
var _h := 56.0


func _ready() -> void:
	z_index = 40
	visible = false
	_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = _bg
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	add_child(_panel)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.97, 0.97, 0.99))
	_label.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_label)


func set_text(t: String) -> void:
	var lines: int = int(max(1, ceil(float(t.length()) / 15.0)))
	_h = float(lines) * 19.0 + 16.0
	_panel.position = Vector2(-W * 0.5, -_h - 30.0)
	_panel.size = Vector2(W, _h)
	_label.position = Vector2(8, 8)
	_label.size = Vector2(W - 16, _h - 16)
	_label.text = t
	queue_redraw()


func _draw() -> void:
	# 꼬리(아래 화살표)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-7, -30), Vector2(7, -30), Vector2(0, -18)]),
		_bg
	)


func appear() -> void:
	if _shown:
		return
	_shown = true
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.15)
	t.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func vanish() -> void:
	if not _shown:
		return
	_shown = false
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.tween_callback(func() -> void: visible = false)
