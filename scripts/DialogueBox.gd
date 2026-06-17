class_name DialogueBox
extends Control
#
# 하단 대화창 — Ninja Adventure 크림 9-slice + 화자 초상(faceset). 타자기 효과.

signal finished

const VW := 360.0
const VH := 640.0

var _lines: Array = []
var _i: int = 0
var _on_done: Callable = Callable()
var _typing: bool = false
var _tw: Tween = null
var _face_path: String = ""

var _np: NinePatchRect
var _name: Label
var _text: Label
var _hint: Label
var _facebox: NinePatchRect
var _face: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_np = NinePatchRect.new()
	_np.texture = load("res://assets/ui/bubble.png")
	for m in ["left", "right", "top", "bottom"]:
		_np.set("patch_margin_" + m, 16)
	_np.position = Vector2(10, VH - 178)
	_np.size = Vector2(VW - 20, 162)
	add_child(_np)

	_facebox = NinePatchRect.new()
	_facebox.texture = load("res://assets/ui/faceset_box.png")
	for m in ["left", "right", "top", "bottom"]:
		_facebox.set("patch_margin_" + m, 6)
	_facebox.position = Vector2(14, 30)
	_facebox.size = Vector2(64, 64)
	_np.add_child(_facebox)
	_face = TextureRect.new()
	_face.position = Vector2(7, 7)
	_face.size = Vector2(50, 50)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_facebox.add_child(_face)

	_name = Label.new()
	_name.position = Vector2(90, 12)
	_name.add_theme_color_override("font_color", Color(0.55, 0.30, 0.12))
	_name.add_theme_font_size_override("font_size", 17)
	_np.add_child(_name)

	_text = Label.new()
	_text.position = Vector2(90, 40)
	_text.size = Vector2(VW - 20 - 104, 96)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_color_override("font_color", Color(0.20, 0.14, 0.10))
	_text.add_theme_font_size_override("font_size", 19)
	_text.add_theme_constant_override("line_spacing", 5)
	_np.add_child(_text)

	_hint = Label.new()
	_hint.text = "탭하여 계속"
	_hint.position = Vector2(VW - 20 - 116, 162 - 26)
	_hint.add_theme_color_override("font_color", Color(0.45, 0.32, 0.2))
	_hint.add_theme_font_size_override("font_size", 13)
	_np.add_child(_hint)


func start(lines: Array, on_done: Callable = Callable(), face_path: String = "") -> void:
	_lines = lines
	_i = 0
	_on_done = on_done
	_face_path = face_path
	if face_path != "" and ResourceLoader.exists(face_path):
		_face.texture = load(face_path)
		_facebox.visible = true
		_name.position.x = 90
		_text.position.x = 90
		_text.size.x = VW - 20 - 104
	else:
		_facebox.visible = false
		_name.position.x = 18
		_text.position.x = 18
		_text.size.x = VW - 20 - 32
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
