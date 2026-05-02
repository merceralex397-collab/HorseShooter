extends Node

const StarterContent := preload("res://src/content/starter_content.gd")
const ContentDatabaseScript := preload("res://src/content/content_database.gd")


func _ready() -> void:
	await get_tree().process_frame

	var resources := StarterContent.make_greenbarrow_resources()
	var counts := {
		"weapon": 0,
		"equipment": 0,
		"ability": 0,
		"quest": 0,
		"follower": 0,
		"enemy": 0,
		"settlement": 0,
	}
	for resource in resources:
		var content_id := String(resource.get("id"))
		var prefix := content_id.split(".")[0]
		if counts.has(prefix):
			counts[prefix] += 1

	var minimums := {
		"weapon": 100,
		"equipment": 150,
		"ability": 60,
		"quest": 60,
		"follower": 12,
		"enemy": 45,
		"settlement": 40,
	}
	for key in minimums.keys():
		if int(counts.get(key, 0)) < int(minimums[key]):
			_fail("Expected at least %s %s records, got %s." % [str(minimums[key]), key, str(counts.get(key, 0))])
			return

	var database := ContentDatabaseScript.new()
	var report: Dictionary = database.load_resources(resources)
	if not bool(report.get("valid", false)):
		_fail("Starter resources failed validation: " + str(report))
		database.free()
		return
	if database.get_record("weapon.greenbarrow.roadwarden_pistol") == null:
		_fail("Starter pistol missing from content database.")
		database.free()
		return
	if database.get_record("enemy.boss.toll_mare") == null:
		_fail("Toll Mare missing from content database.")
		database.free()
		return

	database.free()
	print("STARTER_CONTENT_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("STARTER_CONTENT: " + message)
	get_tree().quit(1)
