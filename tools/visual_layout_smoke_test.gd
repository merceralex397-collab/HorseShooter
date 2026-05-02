extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")
const EDGE_MARGIN := 32.0
const CAMERA_TOLERANCE := 2.0


func _ready() -> void:
	await get_tree().process_frame

	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	if not _check_camera_contract(main):
		await _cleanup_main(main)
		get_tree().quit(1)
		return
	if not _check_player_screen_position(main):
		await _cleanup_main(main)
		get_tree().quit(1)
		return

	await _cleanup_main(main)

	print("VISUAL_LAYOUT_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _check_camera_contract(main: Node2D) -> bool:
	var camera := main.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		push_error("VISUAL_LAYOUT: Camera2D node missing.")
		return false

	var viewport_size := main.get_viewport_rect().size
	var expected_center := viewport_size * 0.5
	var distance := camera.global_position.distance_to(expected_center)
	if distance > CAMERA_TOLERANCE:
		push_error("VISUAL_LAYOUT: Camera must be centered on playfield. camera=%s expected=%s" % [str(camera.global_position), str(expected_center)])
		return false

	return true


func _cleanup_main(main: Node) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("reset_game"):
		gm.reset_game()

	var pool := get_node_or_null("/root/ObjectPool")
	if pool and pool.has_method("clear_pool"):
		pool.clear_pool()

	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_all_audio"):
		audio.stop_all_audio()

	if main and is_instance_valid(main):
		main.queue_free()

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _check_player_screen_position(main: Node2D) -> bool:
	var player := main.get_node_or_null("Player") as Node2D
	if player == null:
		push_error("VISUAL_LAYOUT: Player node missing.")
		return false

	var viewport_size := main.get_viewport_rect().size
	var screen_position := player.get_global_transform_with_canvas().origin
	if screen_position.x < EDGE_MARGIN or screen_position.y < EDGE_MARGIN:
		push_error("VISUAL_LAYOUT: Player is clipped near top/left. screen=%s viewport=%s" % [str(screen_position), str(viewport_size)])
		return false
	if screen_position.x > viewport_size.x - EDGE_MARGIN or screen_position.y > viewport_size.y - EDGE_MARGIN:
		push_error("VISUAL_LAYOUT: Player is clipped near bottom/right. screen=%s viewport=%s" % [str(screen_position), str(viewport_size)])
		return false

	return true
