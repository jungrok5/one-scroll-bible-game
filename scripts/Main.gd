extends Node2D
#
# 한눈에 보는 성경 이야기 — 항해 (MVP 수직 슬라이스)
# 위로 항해(조이스틱) → 기항지마다 NPC 말풍선 + 연출 → 예수님 항구에서 '해적선' 반전
# → 회복 항구에서 영접 기도 → 구조선으로 갈아타고 일출 엔딩.
# 모바일 세로 360×640. 픽셀 스프라이트는 nearest + 2배 확대, UI는 캔버스 해상도라 또렷.

const VW := 360.0
const VH := 640.0
const PATH_X := 120.0
const PATH_W := 120.0
const SPRITE_SCALE := 2.0
const PORT_GAP := 640.0
const FIRST := 440.0

var stops: Array = []
var ports: Array = []           # [{ y, data, visited }]
var cur: int = 0
var in_dialogue: bool = false
var ended: bool = false

var world: Node2D
var player: Player
var camera: Camera2D
var canvas_mod: CanvasModulate
var world_height: float = 0.0

var ui: CanvasLayer
var dialogue: DialogueBox
var joystick: VirtualJoystick
var hud_dots: Array = []
var hint_label: Label

var rescue_ship: Sprite2D
var theme_res: Theme


func _ready() -> void:
	randomize()
	_setup_input()
	_setup_font()
	stops = GameData.stops()
	_build_world()
	_build_ui()
	_set_hud(0)
	if OS.has_environment("E2E"):
		var ap := Node.new()
		ap.set_script(load("res://tools/Autopilot.gd"))
		add_child(ap)


# ---------- setup ----------
func _setup_input() -> void:
	for pair in [["move_up", [KEY_UP, KEY_W]], ["move_down", [KEY_DOWN, KEY_S]]]:
		var a: String = pair[0]
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for kc in pair[1]:
			var ev := InputEventKey.new()
			ev.physical_keycode = kc
			InputMap.action_add_event(a, ev)


func _setup_font() -> void:
	theme_res = Theme.new()
	theme_res.default_font_size = 18
	var f: Font = null
	if ResourceLoader.exists("res://assets/fonts/NotoSansKR-Bold.woff2"):
		var r = load("res://assets/fonts/NotoSansKR-Bold.woff2")
		if r is Font:
			f = r
	if f == null:
		var ff := FontFile.new()
		if ff.load_dynamic_font("res://assets/fonts/NotoSansKR-Bold.woff2") == OK:
			f = ff
	if f != null:
		theme_res.default_font = f
	get_tree().root.theme = theme_res


# ---------- world ----------
func _build_world() -> void:
	world = Node2D.new()
	add_child(world)

	var n := stops.size()
	var top_port_y := 360.0
	for i in n:
		var py := top_port_y + float(n - 1 - i) * PORT_GAP
		ports.append({"y": py, "data": stops[i], "visited": false})
	var start_y: float = ports[0]["y"] + FIRST
	world_height = start_y + 220.0

	# 바다(전체) · 항로(중앙 띠)
	_rect(world, 0, 0, VW, world_height, Color8(40, 110, 150), 0)
	_rect(world, PATH_X, 0, PATH_W, world_height, Color8(150, 110, 70), 1)
	for y in range(0, int(world_height), 26):
		_rect(world, PATH_X, y, PATH_W, 4, Color8(120, 86, 52), 1)

	for i in n:
		_build_island(i)

	# 출발 지점의 해적선 + 플레이어
	_spr(world, "ship_pirate.png", VW * 0.5, start_y + 40, 4)

	player = Player.new()
	player.position = Vector2(VW * 0.5, start_y)
	player.min_y = top_port_y - 70.0
	player.max_y = start_y
	player.z_index = 10
	world.add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = int(VW)
	camera.limit_top = 0
	camera.limit_bottom = int(world_height)
	player.add_child(camera)
	camera.make_current()

	canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color(1, 1, 1)
	world.add_child(canvas_mod)


func _build_island(i: int) -> void:
	var data: Dictionary = ports[i]["data"]
	var py: float = ports[i]["y"]
	_rect(world, 0, py - 200, VW, 400, Color8(108, 150, 86), 2)
	_rect(world, 0, py - 200, VW, 14, Color8(214, 196, 138), 2)
	_rect(world, 0, py + 186, VW, 14, Color8(214, 196, 138), 2)
	_rect(world, PATH_X, py - 200, PATH_W, 400, Color8(150, 110, 70), 3)

	_spr(world, "sign.png", 86, py - 8, 5)
	_spr(world, data.get("npc", "npc_red.png"), 104, py + 16, 5)
	_spr(world, "guide.png", VW - 60, py + 12, 5)
	_spr(world, "lantern.png", VW - 38, py + 2, 6)

	match data.get("key", ""):
		"creation":
			_spr(world, "tree.png", 288, py - 96, 5)
			_spr(world, "bush.png", 56, py + 90, 5)
		"fall":
			_spr(world, "serpent.png", 268, py - 56, 6)
			_spr(world, "tree.png", 288, py - 92, 5)
		"jesus":
			_spr(world, "ship_pirate.png", 278, py + 96, 4)
			_spr(world, "cross.png", VW * 0.5, py - 86, 6)
		"restoration":
			rescue_ship = _spr(world, "ship_rescue.png", VW * 0.5, py - 110, 4)
			_spr(world, "tree.png", 292, py + 70, 5)


# ---------- ui ----------
func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	var n := stops.size()
	var total_w := float(n - 1) * 22.0
	for i in n:
		var d := ColorRect.new()
		d.size = Vector2(12, 12)
		d.position = Vector2(VW * 0.5 - total_w * 0.5 + float(i) * 22.0 - 6.0, 18.0)
		d.color = Color(1, 1, 1, 0.25)
		ui.add_child(d)
		hud_dots.append(d)

	hint_label = Label.new()
	hint_label.text = "위로 항해하세요"
	hint_label.position = Vector2(0, 54)
	hint_label.size = Vector2(VW, 26)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hint_label.add_theme_font_size_override("font_size", 19)
	ui.add_child(hint_label)
	var ht := create_tween()
	ht.tween_interval(3.0)
	ht.tween_property(hint_label, "modulate:a", 0.0, 1.0)

	joystick = VirtualJoystick.new()
	ui.add_child(joystick)
	player.joystick = joystick

	dialogue = DialogueBox.new()
	ui.add_child(dialogue)


func _set_hud(done: int) -> void:
	for i in hud_dots.size():
		hud_dots[i].color = Color(1.0, 0.82, 0.35, 1.0) if i < done else Color(1, 1, 1, 0.25)


# ---------- game loop ----------
func _process(_delta: float) -> void:
	if in_dialogue or cur >= ports.size():
		return
	var p: Dictionary = ports[cur]
	if not p["visited"] and player.position.y <= p["y"]:
		_trigger_port(cur)


func _trigger_port(idx: int) -> void:
	in_dialogue = true
	player.locked = true
	var data: Dictionary = ports[idx]["data"]
	_play_fx(data.get("fx", ""), ports[idx]["y"])
	dialogue.start(data["lines"], Callable(self, "_on_port_done"))


func _on_port_done() -> void:
	ports[cur]["visited"] = true
	_set_hud(cur + 1)
	var data: Dictionary = ports[cur]["data"]
	if data.get("ending", false):
		_start_ending()
		return
	in_dialogue = false
	player.locked = false
	cur += 1


# ---------- fx ----------
func _play_fx(key: String, py: float) -> void:
	match key:
		"creation":
			canvas_mod.color = Color(0.32, 0.36, 0.5)
			_lightning(py)
			await get_tree().create_timer(0.22).timeout
			_lightning(py)
			_flash(Color(1, 1, 1, 0.85))
			var t := create_tween()
			t.tween_property(canvas_mod, "color", Color(1, 1, 1), 1.2)
		"fall":
			var t2 := create_tween()
			t2.tween_property(canvas_mod, "color", Color(0.62, 0.58, 0.6), 1.0)
		"jesus":
			var t3 := create_tween()
			t3.tween_property(canvas_mod, "color", Color(0.5, 0.5, 0.62), 0.8)
		"restoration":
			var t4 := create_tween()
			t4.tween_property(canvas_mod, "color", Color(1.0, 0.97, 0.86), 1.2)


func _lightning(py: float) -> void:
	var fx := LightningFX.new()
	fx.z_index = 20
	world.add_child(fx)
	var x := VW * 0.5 + randf_range(-40, 40)
	fx.strike(Vector2(x, py - 340), Vector2(x + randf_range(-26, 26), py - 50), 2)


func _flash(col: Color) -> void:
	var f := ColorRect.new()
	f.color = col
	f.size = Vector2(VW, VH)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(f)
	var t := create_tween()
	t.tween_property(f, "modulate:a", 0.0, 0.5)
	t.tween_callback(f.queue_free)


# ---------- ending: prayer → ship swap → closing ----------
func _start_ending() -> void:
	_show_prayer()


func _panel_overlay(bg_alpha: float) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, bg_alpha)
	bg.size = Vector2(VW, VH)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(bg)
	ui.add_child(c)
	return c


func _make_label(parent: Node, txt: String, fs: int, col: Color, center: bool = true) -> Label:
	var l := Label.new()
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", fs)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


func _show_prayer() -> void:
	var overlay := _panel_overlay(0.80)
	var box := VBoxContainer.new()
	box.position = Vector2(24, 64)
	box.size = Vector2(VW - 48, VH - 130)
	box.add_theme_constant_override("separation", 10)
	overlay.add_child(box)

	_make_label(box, "그래서, 나는 어떻게?", 22, Color(1.0, 0.85, 0.45))
	_make_label(box, "천천히 한 문장씩 따라 읽어 보세요.", 14, Color(1, 1, 1, 0.72))
	_spacer(box, 8)
	for line in GameData.prayer_lines():
		_make_label(box, line, 18, Color(0.97, 0.97, 0.99))
	_spacer(box, 8)

	var btn := Button.new()
	btn.text = "함께 기도했어요"
	btn.custom_minimum_size = Vector2(0, 50)
	btn.add_theme_font_size_override("font_size", 18)
	box.add_child(btn)
	btn.pressed.connect(func() -> void:
		overlay.queue_free()
		_do_ship_swap()
	)


func _do_ship_swap() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(canvas_mod, "color", Color(1.0, 0.95, 0.8), 1.5)
	if rescue_ship != null:
		t.tween_property(player, "position", rescue_ship.position + Vector2(0, 22), 1.4)
	t.set_parallel(false)
	t.tween_interval(0.4)
	t.tween_callback(_show_closing)


func _show_closing() -> void:
	ended = true
	var overlay := _panel_overlay(0.45)
	var box := VBoxContainer.new()
	box.position = Vector2(24, 84)
	box.size = Vector2(VW - 48, VH - 150)
	box.add_theme_constant_override("separation", 12)
	overlay.add_child(box)

	_make_label(box, "새 배에 오르셨습니다", 22, Color(1.0, 0.88, 0.5))
	_make_label(box, GameData.after_text(), 17, Color(0.97, 0.97, 0.99))
	_make_label(box, GameData.after_verse(), 15, Color(0.85, 0.92, 1.0))
	_spacer(box, 10)

	var more := Button.new()
	more.text = "더 알아보기 · one-scroll-bible.com"
	more.custom_minimum_size = Vector2(0, 46)
	more.add_theme_font_size_override("font_size", 16)
	box.add_child(more)
	more.pressed.connect(func() -> void:
		OS.shell_open(GameData.SITE_URL)
	)

	var again := Button.new()
	again.text = "처음부터 다시"
	again.custom_minimum_size = Vector2(0, 42)
	box.add_child(again)
	again.pressed.connect(func() -> void:
		get_tree().reload_current_scene()
	)


# ---------- helpers ----------
func _spacer(parent: Node, h: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)


func _rect(parent: Node, x: float, y: float, w: float, h: float, col: Color, z: int = 0) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.z_index = z
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _spr(parent: Node, tex: String, x: float, y: float, z: int = 5) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/" + tex)
	s.position = Vector2(x, y)
	s.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	s.z_index = z
	parent.add_child(s)
	return s
