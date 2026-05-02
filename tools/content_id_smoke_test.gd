extends Node

const ContentIds := preload("res://src/content/content_ids.gd")
const ContentValidator := preload("res://src/content/content_validator.gd")


func _ready() -> void:
	await get_tree().process_frame

	if not ContentIds.is_valid_id("weapon.revolver.rusty_oath"):
		push_error("CONTENT_ID: Valid dotted content ID rejected.")
		get_tree().quit(1)
		return
	if ContentIds.is_valid_id("Weapon Bad"):
		push_error("CONTENT_ID: Invalid content ID accepted.")
		get_tree().quit(1)
		return

	var report := ContentValidator.validate_records([
		{"id": "weapon.revolver.rusty_oath", "name": "Rusty Oath"},
		{"id": "weapon.revolver.rusty_oath", "name": "Duplicate"},
		{"id": "bad id", "name": "Bad ID"},
		{"id": "quest.greenbarrow.start", "name": ""},
	])
	if int(report.get("error_count", 0)) != 3:
		push_error("CONTENT_ID: Expected 3 validation errors, got " + str(report.get("error_count", 0)) + ": " + str(report))
		get_tree().quit(1)
		return

	print("CONTENT_ID_SMOKE_STATUS: PASS")
	get_tree().quit(0)
