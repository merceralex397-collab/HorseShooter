extends Node

const SettlementManagerScript := preload("res://src/settlement/settlement_manager.gd")
const FollowerManagerScript := preload("res://src/followers/follower_manager.gd")


func _ready() -> void:
	await get_tree().process_frame

	var settlement_manager := SettlementManagerScript.new()
	var follower_manager := FollowerManagerScript.new()
	add_child(settlement_manager)
	add_child(follower_manager)

	settlement_manager.found("Spitehold")
	settlement_manager.add_resource("timber", 250)
	settlement_manager.add_resource("food", 180)
	settlement_manager.add_resource("water", 160)
	settlement_manager.add_resource("ore", 100)
	settlement_manager.add_resource("medicine", 60)
	settlement_manager.add_resource("trade", 35)
	settlement_manager.add_resource("research", 40)
	settlement_manager.add_resource("defense", 60)

	for index in range(20):
		var building_id := "settlement.building.test.growth_%02d" % [index]
		if not settlement_manager.build(building_id, "camp"):
			_fail("Could not build " + building_id)
			return

	follower_manager.recruit("follower.greenbarrow.first_scout")
	follower_manager.assign_job("follower.greenbarrow.first_scout", "scout")
	if not settlement_manager.assign_follower("follower.greenbarrow.first_scout", "scout"):
		_fail("Could not assign settlement follower job.")
		return

	for tier in ["outpost", "hamlet", "village", "town", "city"]:
		if not settlement_manager.can_upgrade_to(tier):
			_fail("Expected upgrade availability for " + tier)
			return
		settlement_manager.upgrade_to(tier)

	var status: Dictionary = settlement_manager.get_city_status()
	if String(status.get("tier", "")) != "city":
		_fail("Settlement did not reach city tier.")
		return
	if int(status.get("population", 0)) < 900:
		_fail("City population floor was not applied.")
		return
	if not str(status.get("follower_jobs", {})).contains("first_scout"):
		_fail("Follower job missing from city status.")
		return

	print("SETTLEMENT_GROWTH_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("SETTLEMENT_GROWTH: " + message)
	get_tree().quit(1)
