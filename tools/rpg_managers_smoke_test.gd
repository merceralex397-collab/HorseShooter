extends Node

const QuestManagerScript := preload("res://src/quests/quest_manager.gd")
const InventoryManagerScript := preload("res://src/inventory/inventory_manager.gd")
const ProgressionManagerScript := preload("res://src/progression/progression_manager.gd")
const FollowerManagerScript := preload("res://src/followers/follower_manager.gd")
const SettlementManagerScript := preload("res://src/settlement/settlement_manager.gd")
const CombatDirectorScript := preload("res://src/combat/combat_director.gd")


func _ready() -> void:
	await get_tree().process_frame

	var quest_manager = QuestManagerScript.new()
	var inventory_manager = InventoryManagerScript.new()
	var progression_manager = ProgressionManagerScript.new()
	var follower_manager = FollowerManagerScript.new()
	var settlement_manager = SettlementManagerScript.new()
	var combat_director = CombatDirectorScript.new()

	add_child(quest_manager)
	add_child(inventory_manager)
	add_child(progression_manager)
	add_child(follower_manager)
	add_child(settlement_manager)
	add_child(combat_director)

	quest_manager.start_quest("quest.greenbarrow.road_full_of_hooves")
	quest_manager.advance_objective("quest.greenbarrow.road_full_of_hooves", "reach_road")
	if not quest_manager.is_objective_complete("quest.greenbarrow.road_full_of_hooves", "reach_road"):
		_fail("Quest objective did not complete.")
		return

	inventory_manager.add_item("weapon.greenbarrow.rusty_oath", 1)
	inventory_manager.equip_item("weapon", "weapon.greenbarrow.rusty_oath")
	if inventory_manager.get_equipped("weapon") != "weapon.greenbarrow.rusty_oath":
		_fail("Inventory equip failed.")
		return

	progression_manager.grant_xp(150)
	progression_manager.unlock_ability("ability.greenbarrow.profane_focus")
	if not progression_manager.has_ability("ability.greenbarrow.profane_focus"):
		_fail("Ability unlock failed.")
		return

	follower_manager.recruit("follower.greenbarrow.first_scout")
	follower_manager.assign_to_settlement("follower.greenbarrow.first_scout", "watch")
	if follower_manager.get_assignment("follower.greenbarrow.first_scout") != "watch":
		_fail("Follower assignment failed.")
		return

	settlement_manager.found("Spitehold")
	settlement_manager.add_resource("timber", 30)
	settlement_manager.build("settlement.building.watchtower_wood", "camp")
	if not settlement_manager.has_building("settlement.building.watchtower_wood"):
		_fail("Settlement building failed.")
		return

	var consequence: Dictionary = combat_director.register_enemy_escape("enemy.horse.runner_greenbarrow", "region.greenbarrow")
	if int(consequence.get("regional_threat_delta", 0)) <= 0:
		_fail("Combat escape consequence did not raise regional threat.")
		return

	print("RPG_MANAGERS_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("RPG_MANAGERS: " + message)
	get_tree().quit(1)
