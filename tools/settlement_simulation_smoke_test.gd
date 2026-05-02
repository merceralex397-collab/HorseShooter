extends Node

const SettlementManagerScript := preload("res://src/settlement/settlement_manager.gd")


func _ready() -> void:
	await get_tree().process_frame

	var settlement := SettlementManagerScript.new()
	add_child(settlement)
	settlement.found("Spitehold")
	settlement.add_resource("timber", 200)
	settlement.add_resource("food", 120)
	settlement.add_resource("water", 100)
	settlement.add_resource("defense", 60)
	settlement.add_resource("morale", 35)

	var placement: Dictionary = settlement.place_building("settlement.building.watchtower_wood", Vector2(20.0, 20.0), Vector2(80.0, 80.0))
	if not bool(placement.get("ok", false)):
		_fail("Valid building placement failed.")
		return
	var blocked: Dictionary = settlement.can_place_building("settlement.building.market", Vector2(40.0, 40.0), Vector2(80.0, 80.0))
	if bool(blocked.get("ok", false)):
		_fail("Overlapping building placement should be blocked.")
		return

	var route: Dictionary = settlement.create_trade_route("route.spitehold.gallowpine", "region.gallowpine", 4)
	if not bool(route.get("ok", false)):
		_fail("Trade route creation failed.")
		return
	var production: Dictionary = settlement.simulate_day()
	if not bool(production.get("ok", false)) or int(production.get("production", {}).get("trade", 0)) <= 0:
		_fail("Settlement production did not include trade output.")
		return

	settlement.assign_follower("follower.greenbarrow.first_scout", "guard")
	var raid: Dictionary = settlement.trigger_raid("raid.test.low_strength", 30)
	if not bool(raid.get("success", false)):
		_fail("Defended settlement should beat low-strength raid.")
		return
	var hard_raid: Dictionary = settlement.trigger_raid("raid.test.high_strength", 180)
	if int(hard_raid.get("damage", 0)) <= 0:
		_fail("High-strength raid should damage under-defended settlement.")
		return

	var ending: Dictionary = settlement.get_ending_projection()
	if String(ending.get("outcome", "")).is_empty() or ending.get("campaign_effects", []).is_empty():
		_fail("Settlement ending projection missing outcome/effects.")
		return

	var exported: Dictionary = settlement.export_state()
	var restored := SettlementManagerScript.new()
	add_child(restored)
	restored.import_state(exported)
	var restored_status: Dictionary = restored.get_city_status()
	if restored_status.get("trade_routes", {}).is_empty() or restored_status.get("event_log", []).is_empty():
		_fail("Settlement simulation state did not export/import.")
		return

	print("SETTLEMENT_SIMULATION_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("SETTLEMENT_SIMULATION: " + message)
	get_tree().quit(1)
