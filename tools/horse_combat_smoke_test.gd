extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	world.call("interact_with", "interaction.greenbarrow.supply_cache")
	var start_result: Dictionary = world.call("start_horse_encounter", "enemy.horse.runner_greenbarrow")
	if not bool(start_result.get("ok", false)):
		_fail("Could not start runner encounter.")
		return

	var shot_result: Dictionary = world.call("fire_at_active_encounter", Vector2.DOWN)
	if not bool(shot_result.get("ok", false)):
		_fail("Shot resolution failed.")
		return
	if String(shot_result.get("quality", "")) == "miss":
		_fail("Combat produced a miss result; replacement mechanic should use glancing/solid/weakpoint.")
		return
	if int(shot_result.get("damage", 0)) <= 0:
		_fail("Shot did no damage.")
		return

	var escape_result: Dictionary = world.call("force_active_encounter_escape")
	if not bool(escape_result.get("escaped", false)):
		_fail("Escape consequence did not register.")
		return
	if int(world.call("get_region_threat", "region.greenbarrow")) <= 0:
		_fail("Escape did not raise regional threat.")
		return

	var boss_start: Dictionary = world.call("start_horse_encounter", "enemy.boss.toll_mare")
	if not bool(boss_start.get("ok", false)):
		_fail("Could not start Toll Mare encounter.")
		return
	var telegraph: Dictionary = boss_start.get("telegraph", {})
	if not str(telegraph.get("tell", "")).contains("rush"):
		_fail("Boss telegraph did not expose readable tell text.")
		return

	print("HORSE_COMBAT_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("HORSE_COMBAT: " + message)
	get_tree().quit(1)
