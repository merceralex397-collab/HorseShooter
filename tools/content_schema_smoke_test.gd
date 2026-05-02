extends Node

const WeaponData := preload("res://src/content/weapon_data.gd")
const EquipmentData := preload("res://src/content/equipment_data.gd")
const AbilityData := preload("res://src/content/ability_data.gd")
const QuestData := preload("res://src/content/quest_data.gd")
const FollowerData := preload("res://src/content/follower_data.gd")
const EnemyData := preload("res://src/content/enemy_data.gd")
const SettlementBuildingData := preload("res://src/content/settlement_building_data.gd")
const ContentDatabaseScript := preload("res://src/content/content_database.gd")


func _ready() -> void:
	await get_tree().process_frame

	var records := [
		_make_weapon(),
		_make_equipment(),
		_make_ability(),
		_make_quest(),
		_make_follower(),
		_make_enemy(),
		_make_building(),
	]
	var database := ContentDatabaseScript.new()
	var report: Dictionary = database.load_resources(records)
	if not bool(report.get("valid", false)):
		push_error("CONTENT_SCHEMA: Resource records should validate: " + str(report))
		get_tree().quit(1)
		return
	if database.get_record("weapon.test.revolver").display_name != "Test Revolver":
		push_error("CONTENT_SCHEMA: ContentDatabase lookup failed.")
		database.free()
		get_tree().quit(1)
		return

	database.free()
	print("CONTENT_SCHEMA_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _make_weapon() -> Resource:
	var item := WeaponData.new()
	item.id = "weapon.test.revolver"
	item.display_name = "Test Revolver"
	item.family = "revolver"
	item.damage = 12
	return item


func _make_equipment() -> Resource:
	var item := EquipmentData.new()
	item.id = "equipment.test.coat"
	item.display_name = "Test Coat"
	item.slot = "coat"
	return item


func _make_ability() -> Resource:
	var item := AbilityData.new()
	item.id = "ability.test.profane_focus"
	item.display_name = "Profane Focus"
	item.tree = "profane_focus"
	return item


func _make_quest() -> Resource:
	var item := QuestData.new()
	item.id = "quest.test.start"
	item.display_name = "Test Quest"
	item.objectives = [{"type": "travel", "target": "location.test"}]
	return item


func _make_follower() -> Resource:
	var item := FollowerData.new()
	item.id = "follower.test.scout"
	item.display_name = "Test Scout"
	item.combat_role = "scout"
	return item


func _make_enemy() -> Resource:
	var item := EnemyData.new()
	item.id = "enemy.horse.test_runner"
	item.display_name = "Test Runner"
	item.enemy_role = "runner"
	return item


func _make_building() -> Resource:
	var item := SettlementBuildingData.new()
	item.id = "settlement.building.test_tower"
	item.display_name = "Test Tower"
	item.tier_required = "camp"
	return item
