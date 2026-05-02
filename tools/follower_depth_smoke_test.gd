extends Node

const FollowerManagerScript := preload("res://src/followers/follower_manager.gd")
const SettlementManagerScript := preload("res://src/settlement/settlement_manager.gd")
const QuestManagerScript := preload("res://src/quests/quest_manager.gd")


func _ready() -> void:
	await get_tree().process_frame

	var followers := FollowerManagerScript.new()
	var settlement := SettlementManagerScript.new()
	var quests := QuestManagerScript.new()
	add_child(followers)
	add_child(settlement)
	add_child(quests)
	settlement.name = "SettlementManager"
	quests.name = "QuestManager"
	settlement.found("Spitehold")

	followers.recruit("follower.greenbarrow.first_scout")
	followers.set_role("follower.greenbarrow.first_scout", "scout")
	followers.change_loyalty("follower.greenbarrow.first_scout", 60)
	followers.equip_follower("follower.greenbarrow.first_scout", "weapon", "weapon.greenbarrow.fencepost_rifle")
	if not followers.assign_job("follower.greenbarrow.first_scout", "scout"):
		_fail("Follower job assignment failed.")
		return

	followers.recruit("follower.greenbarrow.sniper_mire")
	followers.set_role("follower.greenbarrow.sniper_mire", "sniper")
	followers.set_injury("follower.greenbarrow.sniper_mire", true, 2)
	var injured_modifiers: Dictionary = followers.get_support_modifiers()
	if float(injured_modifiers.get("damage_bonus", 0.0)) > 0.0:
		_fail("Injured follower should not add combat support.")
		return
	followers.rest_followers(2)
	var modifiers: Dictionary = followers.get_support_modifiers()
	if float(modifiers.get("damage_bonus", 0.0)) <= 0.0:
		_fail("Recovered sniper did not add combat support.")
		return
	if float(modifiers.get("ambush_reduction", 0.0)) <= 0.0:
		_fail("Scout did not add exploration support.")
		return
	if int(modifiers.get("morale_bonus", 0)) <= 0:
		_fail("Follower loyalty did not add morale support.")
		return

	var personal_quest := followers.start_personal_quest("follower.greenbarrow.first_scout")
	if personal_quest.is_empty():
		_fail("Follower personal quest id missing.")
		return
	var state: Dictionary = followers.get_follower_state("follower.greenbarrow.first_scout")
	if not bool(state.get("personal_quest_started", false)):
		_fail("Follower personal quest was not marked started.")
		return
	if not state.get("equipment", {}).has("weapon"):
		_fail("Follower equipment did not persist in state.")
		return

	var exported: Dictionary = followers.export_state()
	var restored := FollowerManagerScript.new()
	add_child(restored)
	restored.import_state(exported)
	if restored.get_follower_state("follower.greenbarrow.first_scout").is_empty():
		_fail("Follower state did not export/import.")
		return

	print("FOLLOWER_DEPTH_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("FOLLOWER_DEPTH: " + message)
	get_tree().quit(1)
