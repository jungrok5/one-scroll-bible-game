class_name DialogueBox
extends Control
#
# 말풍선 대화창(화면 하단 고정). start(lines, on_done) → 탭으로 한 줄씩 진행.
# 모바일 가독성: 큰 볼드 글씨 · 넉넉한 패딩 · 넓은 탭 영역.

signal finished

const VW := 360.0
const VH := 640.0

var _lines: Array = []
var _i: int = 0
var _on_done: Callable = Callable()
var _typing: bool = false
var _tw: Tween = null

var _panel: Panel
var _name: Label
var _text: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_panel = Panel.new()
	_panel.position = Vector2(12, VH - 212)
	_panel.size = Vector2(VW - 24, 188)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.17, 0.96)
	sb.border_color = Color(1, 1, 1, 0.16)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	_name = Label.new()
	_name.position = Vector2(16, 12)
	_name.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40))
	_name.add_theme_font_size_override("font_size", 19)
	_panel.add_child(_name)

	_text = Label.new()
	_text.position = Vector2(16, 44)
	_text.size = Vector2(VW - 24 - 32, 110)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_color_override("font_color", Color(0.97, 0.97, 0.99))
	_text.add_theme_font_size_override("font_size", 21)
	_text.add_theme_constant_override("line_spacing", 6)
	_panel.add_child(_text)

	_hint = Label.new()
	_hint.text = "탭하여 계속"
	_hint.position = Vector2(VW - 24 - 130, 188 - 30)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	_hint.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_hint)


func start(lines: Array, on_done: Callable = Callable()) -> void:
	_lines = lines
	_i = 0
	_on_done = on_done
	visible = true
	_show_current()


func _show_current() -> void:
	if _i >= _lines.size():
		visible = false
		finished.emit()
		if _on_done.is_valid():
			_on_done.call()
		return
	var e: Dictionary = _lines[_i]
	var spk: String = e.get("speaker", "")
	_name.text = spk
	_name.visible = spk != ""
	var body: String = e.get("text", "")
	_text.text = body
	# 타자기 효과
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_text.visible_ratio = 0.0
	_typing = true
	_hint.visible = false
	var dur: float = clampf(float(body.length()) * 0.035, 0.3, 2.6)
	_tw = create_tween()
	_tw.tween_property(_text, "visible_ratio", 1.0, dur)
	_tw.tween_callback(func() -> void:
		_typing = false
		_hint.visible = true
	)


# 한 줄 진행(탭/E2E). 타이핑 중이면 먼저 완성, 아니면 다음 줄.
func advance() -> void:
	if _typing:
		if _tw != null and _tw.is_valid():
			_tw.kill()
		_text.visible_ratio = 1.0
		_typing = false
		_hint.visible = true
		return
	_i += 1
	_show_current()


func _gui_input(event: InputEvent) -> void:
	var tap := false
	if event is InputEventScreenTouch and event.pressed:
		tap = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
	if tap:
		advance()
