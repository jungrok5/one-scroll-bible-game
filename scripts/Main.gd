extends Node2D
#
# 한눈에 보는 성경 이야기 — 항해 (RPG 오버월드)
# 섬을 자유로이 돌아다니며(좌우는 바다라 막힘) NPC 근처에서 머리 위 말풍선.
# 씬마다 바이옴(배경) 다름. 위로 항해 → 예수님 항구 '해적선' 반전(모달) → 회복 영접 기도(모달).

const VW := 360.0
const VH := 640.0
const PATH_X := 132.0
const PATH_W := 96.0
const SPRITE_SCALE := 2.0
const PORT_GAP := 700.0
const FIRST := 460.0
const ISLAND_H := 190.0
const NPC_RADIUS := 86.0

var stops: Array = []
var ports: Array = []           # [{y, data, entered, completed}]
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
var vignette: TextureRect
var shard_box: Control
var shards: Array = []
var _dot_tex: Texture2D
var _shake: float = 0.0
var npc_entries: Array = []      # [{bubble, pos:Vector2}]


func _ready() -> void:
	randomize()
	_setup_input()
	_setup_font()
	_dot_tex = load("res://assets/sprites/dot.png")
	stops = GameData.stops()
	_build_world()
	_build_ui()
	_set_hud(0)
	if OS.has_environment("E2E"):
		var ap := Node.new()
		ap.set_script(load("res://tools/Autopilot.gd"))
		add_child(ap)


func _setup_input() -> void:
	for pair in [["move_up", [KEY_UP, KEY_W]], ["move_down", [KEY_DOWN, KEY_S]],
			["move_left", [KEY_LEFT, KEY_A]], ["move_right", [KEY_RIGHT, KEY_D]]]:
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
	if f != null:
		theme_res.default_font = f
	get_tree().root.theme = theme_res


# ---------- world ----------
func _build_world() -> void:
	world = Node2D.new()
	add_child(world)

	var n := stops.size()
	var top_port_y := 380.0
	for i in n:
		var py := top_port_y + float(n - 1 - i) * PORT_GAP
		ports.append({"y": py, "data": stops[i], "entered": false, "completed": false})
	var start_y: float = ports[0]["y"] + FIRST
	world_height = start_y + 240.0

	# 실제 항구/바다처럼 — NA 타일셋을 조합한 타일맵(바다 변주 + 섬+모래 해안 + 나무 부두)
	_build_tilemap()

	for i in n:
		_build_island(i)

	_spr(world, "ship_pirate.png", VW * 0.5, start_y + 46, 4)

	player = Player.new()
	player.position = Vector2(VW * 0.5, start_y)
	player.min_y = top_port_y - 60.0
	player.max_y = start_y
	player.z_index = 10
	player.bounds_provider = Callable(self, "x_bounds")
	world.add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
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
	var b: Dictionary = data["biome"]

	# 땅/바다/해안은 _build_tilemap()가 타일맵으로 한 번에 구성 → 여기선 소품·NPC만.

	# 소품
	for d in b["decor"]:
		_spr(world, d[0], float(d[1]), py + float(d[2]), 3)

	# NPC + 머리 위 말풍선
	for npc in data["npcs"]:
		var nx: float = float(npc["x"])
		var ny: float = py + float(npc["yo"])
		var ns := _spr(world, npc["spr"], nx, ny, 5)
		_bob(ns)
		if npc.get("guide", false):
			_spr(world, "lantern.png", nx + 22, ny - 8, 6)
		var bub := SpeechBubble.new()
		bub.position = Vector2(nx, ny - 18)
		world.add_child(bub)
		bub.set_text(npc["text"])
		npc_entries.append({"bubble": bub, "pos": Vector2(nx, ny)})


# ---------- tilemap (실제 항구/바다 배치) ----------
const CELL := 32.0   # 월드 px / 셀 (16px 타일 × SPRITE_SCALE)

# NA 타일셋(assets/sprites/tileset.png, 16px) 아틀라스 좌표(열,행). 변주는 가중 배열.
var _tiles := {
	"sea":   [Vector2i(23, 7), Vector2i(23, 7), Vector2i(22, 7), Vector2i(22, 9), Vector2i(23, 6), Vector2i(23, 9)],
	"sand":  [Vector2i(21, 13), Vector2i(20, 13), Vector2i(22, 13)],
	"grass": [Vector2i(22, 11), Vector2i(22, 11), Vector2i(23, 11), Vector2i(24, 11)],
	"stone": [Vector2i(26, 11), Vector2i(26, 11), Vector2i(27, 11)],
	"wood":  [Vector2i(25, 8), Vector2i(24, 8)],
	"dirt":  [Vector2i(21, 16)],
}


func _build_tilemap() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/tileset.png")
	src.texture_region_size = Vector2i(16, 16)
	var seen := {}
	for cat in _tiles:
		for c in _tiles[cat]:
			if not seen.has(c):
				seen[c] = true
				src.create_tile(c)
	ts.add_source(src, 0)

	var layer := TileMapLayer.new()
	layer.tile_set = ts
	layer.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	layer.z_index = -3
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(layer)

	var cols := int(ceil(VW / CELL)) + 1
	var rows := int(ceil(world_height / CELL)) + 1
	for cy in rows:
		for cx in cols:
			var wx := float(cx) * CELL + CELL * 0.5
			var wy := float(cy) * CELL + CELL * 0.5
			var cat: String = _terrain_at(wx, wy)
			var arr: Array = _tiles[cat]
			var ac: Vector2i = arr[randi() % arr.size()]
			layer.set_cell(Vector2i(cx, cy), 0, ac)


# 셀의 지형 분류 — 섬은 노이즈로 들쭉날쭉한 해안선(직선 X), 중앙은 부두/길.
func _terrain_at(wx: float, wy: float) -> String:
	var on_path: bool = wx >= PATH_X and wx <= PATH_X + PATH_W
	var best_d := 9999.0
	var best_stone := false
	for p in ports:
		var dy: float = wy - float(p["y"])
		if absf(dy) > ISLAND_H + CELL * 4.0:
			continue
		var dx: float = wx - VW * 0.5
		var hw: float = VW * 0.5 - 12.0
		var hh: float = ISLAND_H + 8.0
		var d: float = sqrt((dx / hw) * (dx / hw) + (dy / hh) * (dy / hh))
		if d < best_d:
			best_d = d
			best_stone = String(p["data"].get("key", "")) == "jesus"
	var n: float = _noise(wx, wy) * 0.12
	var is_interior: bool = best_d < 0.82 + n
	var is_beach: bool = best_d < 0.99 + n
	if on_path:
		return ("stone" if best_stone else "dirt") if is_interior else "wood"
	if is_interior:
		return "stone" if best_stone else "grass"
	if is_beach:
		return "sand"
	return "sea"


# 결정적 해시 노이즈 [-1,1] — 셀마다 안정적인 해안 흔들림.
func _noise(x: float, y: float) -> float:
	var s: float = sin(x * 12.9898 + y * 78.233) * 43758.5453
	return (s - floor(s)) * 2.0 - 1.0


func x_bounds(y: float) -> Vector2:
	for p in ports:
		if absf(y - p["y"]) <= ISLAND_H - 6.0:
			return Vector2(34.0, VW - 34.0)
	return Vector2(PATH_X + 14.0, PATH_X + PATH_W - 14.0)


# ---------- ui ----------
func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	vignette = TextureRect.new()
	vignette.texture = load("res://assets/sprites/vignette.png")
	vignette.position = Vector2.ZERO
	vignette.size = Vector2(VW, VH)
	vignette.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate = Color(1, 1, 1, 0.0)
	ui.add_child(vignette)

	shard_box = Control.new()
	shard_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shard_box)

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
	hint_label.text = "조이스틱으로 자유롭게 — 위로 항해하세요"
	hint_label.position = Vector2(0, 54)
	hint_label.size = Vector2(VW, 26)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hint_label.add_theme_font_size_override("font_size", 16)
	ui.add_child(hint_label)
	var ht := create_tween()
	ht.tween_interval(3.5)
	ht.tween_property(hint_label, "modulate:a", 0.0, 1.0)

	joystick = VirtualJoystick.new()
	ui.add_child(joystick)
	player.joystick = joystick

	dialogue = DialogueBox.new()
	ui.add_child(dialogue)


func _set_hud(done: int) -> void:
	for i in hud_dots.size():
		hud_dots[i].color = Color(1.0, 0.82, 0.35, 1.0) if i < done else Color(1, 1, 1, 0.25)


# ---------- loop ----------
func _process(delta: float) -> void:
	if camera != null:
		if _shake > 0.15:
			camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
			_shake *= 0.86
		elif camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO

	# NPC 근접 말풍선
	var can_talk := not in_dialogue and not ended
	for e in npc_entries:
		var near: bool = can_talk and player.position.distance_to(e["pos"]) < NPC_RADIUS
		if near:
			e["bubble"].appear()
		else:
			e["bubble"].vanish()

	if in_dialogue or cur >= ports.size():
		return
	var port: Dictionary = ports[cur]
	var py: float = port["y"]
	if not port["entered"] and player.position.y <= py + 170.0:
		_enter_port(cur)
	elif port["entered"] and not port["completed"]:
		var done_y: float = py if port["data"].get("ending", false) else py - 150.0
		if player.position.y <= done_y:
			_complete_port(cur)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _enter_port(idx: int) -> void:
	ports[idx]["entered"] = true
	var data: Dictionary = ports[idx]["data"]
	var py: float = ports[idx]["y"]
	_play_fx(data.get("fx", ""), py)
	_scene_title(data.get("title", ""), data.get("one", ""), data["biome"].get("title_color", Color(1, 1, 1)))
	if data.get("reveal", false):
		_start_reveal(idx)


func _complete_port(idx: int) -> void:
	ports[idx]["completed"] = true
	_set_hud(idx + 1)
	var data: Dictionary = ports[idx]["data"]
	var shard: String = data.get("shard", "")
	if shard != "":
		_add_shard(shard)
	if data.get("ending", false):
		_start_ending()
		return
	cur += 1


func _start_reveal(idx: int) -> void:
	in_dialogue = true
	player.locked = true
	var lines: Array = ports[idx]["data"].get("reveal_lines", [])
	await get_tree().create_timer(1.6).timeout
	shake(8.0)
	_flash(Color(1, 1, 1, 0.5))
	dialogue.start(lines, Callable(self, "_reveal_done"), "res://assets/face/guide.png")


func _reveal_done() -> void:
	in_dialogue = false
	player.locked = false


# ---------- scene title ----------
func _scene_title(title: String, sub: String, col: Color) -> void:
	var t := Label.new()
	t.text = title
	t.position = Vector2(0, VH * 0.32)
	t.size = Vector2(VW, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", col)
	t.add_theme_font_size_override("font_size", 34)
	ui.add_child(t)
	var s := Label.new()
	s.text = sub
	s.position = Vector2(24, VH * 0.32 + 44)
	s.size = Vector2(VW - 48, 60)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	s.add_theme_font_size_override("font_size", 15)
	ui.add_child(s)
	for lbl in [t, s]:
		lbl.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(lbl, "modulate:a", 1.0, 0.5)
		tw.tween_interval(2.0)
		tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
		tw.tween_callback(lbl.queue_free)


# ---------- fx ----------
func _play_fx(key: String, py: float) -> void:
	match key:
		"creation":
			canvas_mod.color = Color(0.18, 0.2, 0.34)
			_vig(0.5)
			_lightning(py)
			shake(9.0)
			await get_tree().create_timer(0.25).timeout
			_lightning(py)
			shake(7.0)
			_flash(Color(1, 1, 1, 0.8))
			_grade(Color(1, 1, 1), 1.4)
			_vig(0.08)
			_rays(py, Color(1.0, 0.95, 0.7, 0.5), 2.5)
			_weather("motes", py)
		"fall":
			_grade(Color(0.62, 0.56, 0.58), 1.2)
			_vig(0.5)
			_weather("petals", py)
		"jesus":
			_grade(Color(0.3, 0.32, 0.46), 0.6)
			_vig(0.62)
			await get_tree().create_timer(0.8).timeout
			_flash(Color(1, 1, 1, 0.9))
			shake(10.0)
			_grade(Color(1.0, 0.98, 0.92), 1.2)
			_vig(0.12)
			_rays(py, Color(1.0, 0.96, 0.78, 0.6), 3.0)
			_converge_shards(Vector2(VW * 0.5, VH * 0.42))
			_weather("motes", py)
		"restoration":
			_grade(Color(1.0, 0.95, 0.82), 1.4)
			_vig(0.04)
			_rays(py, Color(1.0, 0.9, 0.6, 0.55), 3.5)
			_weather("motes", py)


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


func _grade(target: Color, dur: float) -> void:
	var t := create_tween()
	t.tween_property(canvas_mod, "color", target, dur)


func _vig(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(vignette, "modulate:a", alpha, 1.0)


func _rays(py: float, color: Color, dur: float) -> void:
	var r := LightRays.new()
	r.position = Vector2(VW * 0.5, py - 210.0)
	r.z_index = 8
	r.setup(color)
	world.add_child(r)
	if dur > 0.0:
		var t := create_tween()
		t.tween_interval(dur)
		t.tween_property(r, "modulate:a", 0.0, 1.0)
		t.tween_callback(r.queue_free)


func _weather(kind: String, py: float) -> void:
	var p := Fx.particles(kind, _dot_tex, 180.0)
	p.position = Vector2(VW * 0.5, py - 200.0)
	p.z_index = 7
	world.add_child(p)


func _add_shard(label: String) -> void:
	var s := TextureRect.new()
	s.texture = _dot_tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.size = Vector2(14, 14)
	s.modulate = Color(1.0, 0.85, 0.4, 0.0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_box.add_child(s)
	shards.append(s)
	var n := shards.size()
	for i in n:
		shards[i].position = Vector2(VW * 0.5 - float(n - 1) * 11.0 + float(i) * 22.0 - 7.0, 40.0)
	var t := create_tween()
	t.tween_property(s, "modulate:a", 0.95, 0.4)


func _converge_shards(target: Vector2) -> void:
	for s in shards:
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", target - Vector2(7, 7), 1.0).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(s, "scale", Vector2(2.2, 2.2), 1.0)
		t.chain().tween_property(s, "modulate:a", 0.0, 0.3)
	if shards.size() > 0:
		var ft := create_tween()
		ft.tween_interval(1.0)
		ft.tween_callback(func() -> void: _flash(Color(1, 1, 1, 0.7)))


# ---------- ending ----------
func _start_ending() -> void:
	in_dialogue = true
	player.locked = true
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


func _make_label(parent: Node, txt: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", fs)
	parent.add_child(l)
	return l


func _show_prayer() -> void:
	var overlay := _panel_overlay(0.8)
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
	_vig(0.0)
	if rescue_ship != null:
		_rays(rescue_ship.position.y + 210.0, Color(1.0, 0.92, 0.62, 0.7), 3.0)
	shake(6.0)
	_flash(Color(1.0, 0.95, 0.8, 0.6))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(canvas_mod, "color", Color(1.05, 1.0, 0.85), 1.6)
	if rescue_ship != null:
		t.tween_property(player, "position", rescue_ship.position + Vector2(0, 24), 1.5).set_trans(Tween.TRANS_SINE)
	t.set_parallel(false)
	t.tween_interval(0.5)
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
	more.pressed.connect(func() -> void: OS.shell_open(GameData.SITE_URL))
	var again := Button.new()
	again.text = "처음부터 다시"
	again.custom_minimum_size = Vector2(0, 42)
	box.add_child(again)
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())


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


func _tile(parent: Node, x: float, y: float, w: float, h: float, texname: String, mod: Color, z: int = 0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/sprites/" + texname)
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.position = Vector2(x, y)
	t.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	t.size = Vector2(w / SPRITE_SCALE, h / SPRITE_SCALE)
	t.modulate = mod
	t.z_index = z
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _bob(s: Node2D) -> void:
	var base: float = s.position.y
	var t := create_tween().set_loops()
	t.tween_property(s, "position:y", base - 2.0, 0.7).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "position:y", base, 0.7).set_trans(Tween.TRANS_SINE)


func _spr(parent: Node, tex: String, x: float, y: float, z: int = 5) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/" + tex)
	s.position = Vector2(x, y)
	s.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	s.z_index = z
	parent.add_child(s)
	if tex == "ship_rescue.png":
		rescue_ship = s
	return s
