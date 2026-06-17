extends Node
#
# E2E 오토플레이 — 환경변수 E2E(스크린샷 출력 디렉터리)가 있을 때 Main이 스폰.
# 게임을 자동 진행(위로 이동·대화 자동 넘김·기도 버튼 클릭)하며 스크린샷을 저장하고 종료.
# 평상시(일반 플레이)에는 스폰되지 않음.

var main: Node
var dir: String
var idx: int = 0
var t_total: float = 0.0
var dlg_timer: float = 10.0
var walk_timer: float = 10.0
var busy: bool = false
var quitting: bool = false


func _ready() -> void:
	main = get_parent()
	dir = OS.get_environment("E2E")
	if dir == "":
		dir = "res://docs/screenshots"
	if not dir.begins_with("res://") and not dir.begins_with("user://"):
		DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.5).timeout
	await _shot("start")


func _process(delta: float) -> void:
	if quitting or busy:
		return
	busy = true
	await _tick(delta)
	busy = false


func _tick(delta: float) -> void:
	t_total += delta
	if t_total > 130.0:
		await _finish()
		return

	# 1) 엔딩(클로징) 도달
	if main.ended:
		main.player.auto_dir = 0.0
		await get_tree().create_timer(0.3).timeout
		await _shot("closing")
		await _finish()
		return

	# 2) 대화 진행 중 → 캡처 후 한 줄 넘김
	var dlg = main.dialogue
	if dlg != null and dlg.visible:
		main.player.auto_dir = 0.0
		dlg_timer += delta
		if dlg_timer >= 0.65:
			dlg_timer = 0.0
			await _shot("dialogue")
			if is_instance_valid(dlg) and dlg.visible:
				dlg.advance()
		return

	# 3) 기도 오버레이 버튼 → 캡처 후 클릭
	var btn = _find_button(main.ui)
	if btn != null and not main.ended:
		main.player.auto_dir = 0.0
		await _shot("prayer")
		btn.pressed.emit()
		await get_tree().create_timer(0.25).timeout
		return

	# 4) 위로 항해
	main.player.auto_dir = -1.0
	walk_timer += delta
	if walk_timer >= 1.6:
		walk_timer = 0.0
		await _shot("voyage")


func _find_button(node: Node) -> Button:
	for c in node.get_children():
		if c is Button and (c as Button).is_visible_in_tree():
			return c
		var r := _find_button(c)
		if r != null:
			return r
	return null


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path := "%s/%02d_%s.png" % [dir, idx, tag]
	var err := img.save_png(path)
	idx += 1
	print("[E2E] shot %s (err=%d)" % [path, err])


func _finish() -> void:
	quitting = true
	await _shot("final")
	await get_tree().process_frame
	get_tree().quit()
