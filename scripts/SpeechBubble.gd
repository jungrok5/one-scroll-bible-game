class_name SpeechBubble
extends Node2D
#
# NPC 머리 위 말풍선(월드 공간). Ninja Adventure 크림색 9-slice 말풍선 사용.

const W := 188.0

var _np: NinePatchRect
var _label: Label
var _shown := false
var _h := 56.0


func _ready() -> void:
	z_index = 40
	visible = false
	_np = NinePatchRect.new()
	_np.texture = load("res://assets/ui/bubble.png")
	_np.patch_margin_left = 16
	_np.patch_margin_right = 16
	_np.patch_margin_top = 16
	_np.patch_margin_bottom = 16
	_np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_np)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.22, 0.15, 0.12))
	_label.add_theme_font_size_override("font_size", 13)
	_np.add_child(_label)


func set_text(t: String) -> void:
	var lines: int = int(max(1, ceil(float(t.length()) / 14.0)))
	_h = float(lines) * 18.0 + 24.0
	_np.position = Vector2(-W * 0.5, -_h - 26.0)
	_np.size = Vector2(W, _h)
	_label.position = Vector2(14, 8)
	_label.size = Vector2(W - 28, _h - 16)
	_label.text = t
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(
		PackedVector2Array([Vector2(-8, -26), Vector2(8, -26), Vector2(0, -14)]),
		Color(0.96, 0.90, 0.82)
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
