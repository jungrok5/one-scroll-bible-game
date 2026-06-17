extends Node
#
# E2E 오토플레이 — 환경변수 E2E(스크린샷 디렉터리)가 있을 때 Main이 스폰.
# 위로 항해하며 좌우로 살짝 흔들어(NPC 말풍선 트리거) 자동 진행, 모달은 자동 처리. 스크린샷 저장 후 종료.

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
	await get_tree().create_timer(0.6).timeout
	await _shot("start")


func _process(delta: float) -> void:
	if quitting or busy:
		return
	busy = true
	await _tick(delta)
	busy = false


func _tick(delta: float) -> void:
	t_total += delta
	if t_total > 150.0:
		await _finish()
		return

	if main.ended:
		main.player.auto_dir = Vector2.ZERO
		await get_tree().create_timer(0.3).timeout
		await _shot("closing")
		await _finish()
		return

	var dlg = main.dialogue
	if dlg != null and dlg.visible:
		main.player.auto_dir = Vector2.ZERO
		dlg_timer += delta
		if dlg_timer >= 0.7:
			dlg_timer = 0.0
			await _shot("reveal")
			if is_instance_valid(dlg) and dlg.visible:
				dlg.advance()
		return

	var btn = _find_button(main.ui)
	if btn != null:
		main.player.auto_dir = Vector2.ZERO
		await _shot("prayer")
		btn.pressed.emit()
		await get_tree().create_timer(0.25).timeout
		return

	# 위로 항해 + 좌우 흔들어 NPC 말풍선 트리거
	main.player.auto_dir = Vector2(sin(t_total * 1.4) * 0.75, -1.0)
	walk_timer += delta
	if walk_timer >= 1.3:
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
	img.save_png(path)
	idx += 1


func _finish() -> void:
	quitting = true
	await _shot("final")
	await get_tree().process_frame
	get_tree().quit()
