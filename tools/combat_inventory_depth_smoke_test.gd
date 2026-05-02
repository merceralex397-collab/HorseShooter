extends Node

const InventoryManagerScript := preload("res://src/inventory/inventory_manager.gd")
const HorseEncounterScript := preload("res://src/combat/horse_encounter.gd")


func _ready() -> void:
	await get_tree().process_frame

	var inventory := InventoryManagerScript.new()
	add_child(inventory)
	inventory.add_item("weapon.test.rifle", 1)
	inventory.add_item("equipment.mod.bleed_rounds", 1)
	inventory.set_item_rarity("weapon.test.rifle", "rare")
	inventory.add_ammo("standard", 3)
	if not inventory.can_fire_weapon("weapon.test.rifle", "standard", 10, 20):
		_fail("Weapon should be able to fire before heat cap.")
		return
	if not inventory.register_weapon_fire("weapon.test.rifle", "standard", 10):
		_fail("Weapon fire did not consume ammo.")
		return
	if not inventory.install_weapon_mod("weapon.test.rifle", "equipment.mod.bleed_rounds", 2):
		_fail("Weapon mod install failed.")
		return
	inventory.add_material("material.ore", 3)
	if not inventory.craft_item("equipment.test.plate", {"material.ore": 2}):
		_fail("Crafting failed with enough material.")
		return
	if inventory.get_item_rarity("weapon.test.rifle") != "rare":
		_fail("Rarity lookup failed.")
		return

	var encounter := HorseEncounterScript.new()
	add_child(encounter)
	encounter.setup({
		"id": "enemy.horse.armored_test",
		"name": "Armored Test",
		"enemy_role": "armored",
		"health": 40,
		"armor": 4,
		"resistances": {"fire": 0.5},
		"phases": ["approach"],
	})
	var result: Dictionary = encounter.resolve_shot({
		"damage": 30,
		"damage_type": "fire",
		"direction": Vector2.LEFT,
		"status_effects": ["burning"],
	})
	if int(result.get("damage", 0)) >= 30:
		_fail("Armor/resistance did not reduce damage.")
		return
	if not result.get("status_effects", {}).has("burning"):
		_fail("Status effect was not applied.")
		return

	print("COMBAT_INVENTORY_DEPTH_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("COMBAT_INVENTORY_DEPTH: " + message)
	get_tree().quit(1)
