extends Node

const APP_ROOT_SCENE := preload("res://scenes/app/app_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var app_root := APP_ROOT_SCENE.instantiate()
	add_child(app_root)
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_size := get_viewport().get_visible_rect().size

	if not app_root.has_method("show_title_menu"):
		push_error("APP_ROOT_SMOKE: AppRoot.show_title_menu missing.")
		get_tree().quit(1)
		return
	if not app_root.has_method("show_name_entry"):
		push_error("APP_ROOT_SMOKE: AppRoot.show_name_entry missing.")
		get_tree().quit(1)
		return
	if not app_root.has_method("start_new_game"):
		push_error("APP_ROOT_SMOKE: AppRoot.start_new_game missing.")
		get_tree().quit(1)
		return
	if String(app_root.get("current_screen")) != "title":
		push_error("APP_ROOT_SMOKE: AppRoot must boot to title screen.")
		get_tree().quit(1)
		return
	if not _assert_panel_centered(app_root, viewport_size, "title"):
		return
	if not _assert_label_visible(app_root, "HorseShooter", "title"):
		return

	app_root.show_name_entry()
	await get_tree().process_frame
	await get_tree().process_frame
	if String(app_root.get("current_screen")) != "name_entry":
		push_error("APP_ROOT_SMOKE: AppRoot did not switch to name entry.")
		get_tree().quit(1)
		return
	viewport_size = get_viewport().get_visible_rect().size
	if not _assert_panel_centered(app_root, viewport_size, "name_entry"):
		return
	if not _assert_label_visible(app_root, "Name the horse-hating gunslinger", "name_entry"):
		return

	app_root.show_settings()
	await get_tree().process_frame
	await get_tree().process_frame
	if String(app_root.get("current_screen")) != "settings":
		push_error("APP_ROOT_SMOKE: AppRoot did not switch to settings.")
		get_tree().quit(1)
		return
	if not _assert_label_visible(app_root, "Settings", "settings"):
		return
	if _find_label_containing(app_root, "arrive in Phase") != null:
		push_error("APP_ROOT_SMOKE: Settings still contains placeholder planning copy.")
		get_tree().quit(1)
		return

	print("APP_ROOT_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _assert_panel_centered(root: Node, viewport_size: Vector2, screen_name: String) -> bool:
	var panel := _find_first_panel(root)
	if panel == null:
		push_error("APP_ROOT_SMOKE: Missing panel for " + screen_name)
		get_tree().quit(1)
		return false
	var rect := panel.get_global_rect()
	var center_error := rect.get_center().distance_to(viewport_size * 0.5)
	if center_error > 12.0:
		push_error("APP_ROOT_SMOKE: Panel not centered for %s. Rect=%s center_error=%s" % [screen_name, str(rect), str(center_error)])
		get_tree().quit(1)
		return false
	if rect.position.x < viewport_size.x * 0.2 or rect.position.y < viewport_size.y * 0.15:
		push_error("APP_ROOT_SMOKE: Panel is pinned near top-left for %s. Rect=%s" % [screen_name, str(rect)])
		get_tree().quit(1)
		return false
	return true


func _find_first_panel(node: Node) -> PanelContainer:
	if node is PanelContainer:
		return node
	for child in node.get_children():
		var found := _find_first_panel(child)
		if found:
			return found
	return null


func _assert_label_visible(root: Node, text: String, screen_name: String) -> bool:
	var label := _find_label(root, text)
	if label == null:
		push_error("APP_ROOT_SMOKE: Missing label '%s' for %s." % [text, screen_name])
		get_tree().quit(1)
		return false
	var rect := label.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		push_error("APP_ROOT_SMOKE: Label '%s' has invalid rect %s for %s." % [text, str(rect), screen_name])
		get_tree().quit(1)
		return false
	return true


func _find_label(node: Node, text: String) -> Label:
	if node is Label and node.text == text:
		return node
	for child in node.get_children():
		var found := _find_label(child, text)
		if found:
			return found
	return null


func _find_label_containing(node: Node, text: String) -> Label:
	if node is Label and node.text.contains(text):
		return node
	for child in node.get_children():
		var found := _find_label_containing(child, text)
		if found:
			return found
	return null
