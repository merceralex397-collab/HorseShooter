extends RefCounted

const WeaponData := preload("res://src/content/weapon_data.gd")
const EquipmentData := preload("res://src/content/equipment_data.gd")
const AbilityData := preload("res://src/content/ability_data.gd")
const QuestData := preload("res://src/content/quest_data.gd")
const FollowerData := preload("res://src/content/follower_data.gd")
const EnemyData := preload("res://src/content/enemy_data.gd")
const SettlementBuildingData := preload("res://src/content/settlement_building_data.gd")


static func make_greenbarrow_resources() -> Array[Resource]:
	var resources: Array[Resource] = []
	resources.append_array(_make_weapons())
	resources.append_array(_make_equipment())
	resources.append_array(_make_abilities())
	resources.append_array(_make_quests())
	resources.append(_make_follower("follower.greenbarrow.first_scout", "First Scout", "rifle_support", "scout"))
	resources.append_array(_make_horses())
	resources.append_array(_make_buildings())
	resources.append_array(_make_campaign_scale_content())
	return resources


static func _make_weapons() -> Array[Resource]:
	var specs := [
		["weapon.greenbarrow.rusty_oath", "Rusty Oath", "revolver", 12, 1.2],
		["weapon.greenbarrow.roadwarden_pistol", "Roadwarden Pistol", "pistol", 18, 1.6],
		["weapon.greenbarrow.mare_spite_revolver", "Mare-Spite Revolver", "revolver", 22, 1.35],
		["weapon.greenbarrow.haymaker_shotgun", "Haymaker Shotgun", "shotgun", 34, 0.75],
		["weapon.greenbarrow.fencepost_rifle", "Fencepost Rifle", "rifle", 27, 0.9],
		["weapon.greenbarrow.stablebreaker", "Stablebreaker", "launcher", 46, 0.35],
		["weapon.greenbarrow.brass_barker", "Brass Barker", "pistol", 16, 2.4],
		["weapon.greenbarrow.saltlock_carbine", "Saltlock Carbine", "rifle", 25, 1.05],
		["weapon.greenbarrow.hoofsplitter", "Hoofsplitter", "shotgun", 39, 0.55],
		["weapon.greenbarrow.angry_lantern", "Angry Lantern", "experimental", 21, 0.8],
		["weapon.greenbarrow.toll_knife", "Toll Knife", "trap", 30, 0.6],
		["weapon.greenbarrow.field_cannon", "Field Cannon", "launcher", 58, 0.25],
	]
	var records: Array[Resource] = []
	for spec in specs:
		var item := WeaponData.new()
		item.id = spec[0]
		item.display_name = spec[1]
		item.family = spec[2]
		item.damage = spec[3]
		item.fire_rate = spec[4]
		item.description = "Greenbarrow weapon tuned for mounted target control."
		records.append(item)
	return records


static func _make_equipment() -> Array[Resource]:
	var names := [
		"travel_coat", "dark_hair_ribbon", "road_boots", "powder_gloves", "spite_belt",
		"field_charm", "patched_hat", "iron_clasp", "wanderer_scarf", "farmguard_vest",
		"ash_lined_coat", "quickdraw_wrap", "bitter_locket", "map_case", "ammo_sash",
		"watcher_badge", "thorn_spurs", "rain_cape", "camp_banner", "settler_gloves",
	]
	var slots := ["coat", "hat", "boots", "gloves", "belt", "charm", "hat", "utility", "utility", "coat"]
	var records: Array[Resource] = []
	for index in names.size():
		var item := EquipmentData.new()
		item.id = "equipment.greenbarrow." + names[index]
		item.display_name = names[index].capitalize()
		item.slot = slots[index % slots.size()]
		item.stats = {"defense": 1 + index % 4, "mobility": index % 3}
		records.append(item)
	return records


static func _make_abilities() -> Array[Resource]:
	var names := [
		"quick_curse", "steady_hands", "horse_tracker", "roll_clear", "reload_spite",
		"camp_commander", "weakpoint_glare", "field_mender", "road_runner", "profane_focus",
	]
	var trees := ["gunslinger", "hunter", "hunter", "survivor", "gunslinger", "commander", "hunter", "survivor", "survivor", "profane_focus"]
	var records: Array[Resource] = []
	for index in names.size():
		var item := AbilityData.new()
		item.id = "ability.greenbarrow." + names[index]
		item.display_name = names[index].capitalize()
		item.tree = trees[index]
		item.tier = 1 + index / 4
		item.effects = {"horse_damage_bonus": index % 3, "cooldown_reduction": index % 2}
		records.append(item)
	return records


static func _make_quests() -> Array[Resource]:
	var specs := [
		["quest.greenbarrow.road_full_of_hooves", "The Road Is Full of Hooves", "interaction.greenbarrow.roadwarden"],
		["quest.greenbarrow.found_spitehold", "Found Spitehold", "interaction.greenbarrow.found_spitehold"],
		["quest.greenbarrow.ruined_farm", "The Farm They Trampled", "location.greenbarrow.ruined_farm"],
		["quest.greenbarrow.first_follower", "A Sensible Person With a Rifle", "interaction.greenbarrow.first_scout"],
		["quest.greenbarrow.toll_mare_hunt", "The Toll Mare", "enemy.boss.toll_mare"],
	]
	var records: Array[Resource] = []
	for spec in specs:
		var item := QuestData.new()
		item.id = spec[0]
		item.display_name = spec[1]
		item.region_id = "region.greenbarrow"
		item.objectives = [{"type": "resolve", "target": spec[2]}]
		item.rewards = [{"type": "xp", "amount": 100}]
		records.append(item)
	return records


static func _make_follower(content_id: String, display_name: String, combat_role: String, settlement_role: String) -> Resource:
	var item := FollowerData.new()
	item.id = content_id
	item.display_name = display_name
	item.combat_role = combat_role
	item.settlement_role = settlement_role
	item.recruitment_quest = "quest.greenbarrow.first_follower"
	var banter: Array[String] = [
		"{player_name}: I hate horses. You shoot left, I shoot right.",
		"First Scout: Fair division of labor.",
	]
	item.banter_pool = banter
	return item


static func _make_horses() -> Array[Resource]:
	var specs := [
		["enemy.horse.runner_greenbarrow", "Grassland Runner", "runner", 26, 8],
		["enemy.horse.charger_greenbarrow", "Fence Charger", "charger", 44, 14],
		["enemy.horse.spitter_greenbarrow", "Mud Spitter", "spitter", 32, 11],
		["enemy.horse.pack_leader_greenbarrow", "Road Pack Leader", "pack_leader", 70, 16],
		["enemy.horse.armored_greenbarrow", "Tack-Armored Nag", "armored", 88, 12],
		["enemy.boss.toll_mare", "The Toll Mare", "boss", 420, 28],
	]
	var records: Array[Resource] = []
	for spec in specs:
		var item := EnemyData.new()
		item.id = spec[0]
		item.display_name = spec[1]
		item.enemy_role = spec[2]
		item.region_id = "region.greenbarrow"
		item.health = spec[3]
		item.damage = spec[4]
		var phases: Array[String] = ["charge", "recover"]
		if spec[2] == "boss":
			phases = ["charge", "summon", "road_smash"]
		item.phases = phases
		var loot_table: Array[String] = ["loot.greenbarrow.horse_parts"]
		item.loot_table = loot_table
		records.append(item)
	return records


static func _make_buildings() -> Array[Resource]:
	var specs := [
		["settlement.building.greenbarrow.command_fire", "Command Fire", "camp", "leadership", 1],
		["settlement.building.greenbarrow.watch_tower", "Watch Tower", "camp", "defense", 1],
		["settlement.building.greenbarrow.work_shed", "Work Shed", "camp", "production", 2],
		["settlement.building.greenbarrow.clinic_tent", "Clinic Tent", "outpost", "medicine", 1],
		["settlement.building.greenbarrow.gun_bench", "Gun Bench", "outpost", "crafting", 1],
	]
	var records: Array[Resource] = []
	for spec in specs:
		var item := SettlementBuildingData.new()
		item.id = spec[0]
		item.display_name = spec[1]
		item.tier_required = spec[2]
		item.category = spec[3]
		item.assignment_slots = spec[4]
		item.resource_cost = {"timber": 10, "food": 3}
		item.resource_output = {"defense": 2} if spec[3] == "defense" else {}
		records.append(item)
	return records


static func _make_campaign_scale_content() -> Array[Resource]:
	var resources: Array[Resource] = []
	var region_specs := [
		["gallowpine", "Gallowpine", "forest"],
		["frostreel", "Frostreel", "snow"],
		["saltwake", "Saltwake", "coast"],
		["blackglass", "Blackglass", "mountain"],
		["cinderjaw", "Cinderjaw", "volcano"],
		["pale_spur", "Pale Spur", "badlands"],
		["withered_paddock", "Withered Paddock", "corruption"],
	]
	for spec in region_specs:
		var slug := String(spec[0])
		var title := String(spec[1])
		var biome := String(spec[2])
		resources.append_array(_make_regional_weapons(slug, title, biome))
		resources.append_array(_make_regional_equipment(slug, title, biome))
		resources.append_array(_make_regional_abilities(slug, title))
		resources.append_array(_make_regional_quests(slug, title))
		resources.append_array(_make_regional_followers(slug, title))
		resources.append_array(_make_regional_enemies(slug, title, biome))
		resources.append_array(_make_regional_buildings(slug, title))
	return resources


static func _make_regional_weapons(slug: String, title: String, biome: String) -> Array[Resource]:
	var family_cycle := ["pistol", "revolver", "rifle", "shotgun", "launcher", "trap", "experimental"]
	var records: Array[Resource] = []
	for index in range(14):
		var item := WeaponData.new()
		item.id = "weapon.%s.%s_%02d" % [slug, biome, index + 1]
		item.display_name = "%s %s %02d" % [title, family_cycle[index % family_cycle.size()].capitalize(), index + 1]
		item.family = family_cycle[index % family_cycle.size()]
		item.damage = 14 + index * 3
		item.fire_rate = 0.45 + float(index % 6) * 0.22
		item.reload_time = 0.8 + float(index % 5) * 0.18
		item.rarity = _rarity_for_index(index)
		item.description = "%s-region weapon built for horse control in %s terrain." % [title, biome]
		records.append(item)
	return records


static func _make_regional_equipment(slug: String, title: String, biome: String) -> Array[Resource]:
	var slots := ["coat", "boots", "gloves", "hat", "belt", "charm", "weapon_mod", "utility", "banner"]
	var records: Array[Resource] = []
	for index in range(22):
		var item := EquipmentData.new()
		item.id = "equipment.%s.%s_kit_%02d" % [slug, biome, index + 1]
		item.display_name = "%s %s Kit %02d" % [title, slots[index % slots.size()].capitalize(), index + 1]
		item.slot = slots[index % slots.size()]
		item.rarity = _rarity_for_index(index)
		item.stats = {
			"defense": 1 + index % 7,
			"mobility": index % 4,
			"horse_resistance": 1 + index % 5,
		}
		records.append(item)
	return records


static func _make_regional_abilities(slug: String, title: String) -> Array[Resource]:
	var trees := ["gunslinger", "hunter", "survivor", "commander", "mechanist", "profane_focus"]
	var records: Array[Resource] = []
	for index in range(9):
		var item := AbilityData.new()
		item.id = "ability.%s.tactic_%02d" % [slug, index + 1]
		item.display_name = "%s Tactic %02d" % [title, index + 1]
		item.tree = trees[index % trees.size()]
		item.tier = 1 + index / 3
		item.effects = {
			"horse_damage_bonus": 1 + index % 4,
			"settlement_bonus": index % 3,
		}
		records.append(item)
	return records


static func _make_regional_quests(slug: String, title: String) -> Array[Resource]:
	var records: Array[Resource] = []
	for index in range(9):
		var item := QuestData.new()
		item.id = "quest.%s.chapter_%02d" % [slug, index + 1]
		item.display_name = "%s Chapter %02d" % [title, index + 1]
		item.region_id = "region." + slug
		item.objectives = [
			{"type": "discover", "target": "location.%s.key_%02d" % [slug, index + 1]},
			{"type": "defeat", "target": "enemy.horse.%s_threat_%02d" % [slug, index + 1]},
		]
		item.rewards = [{"type": "xp", "amount": 140 + index * 25}]
		records.append(item)
	return records


static func _make_regional_followers(slug: String, title: String) -> Array[Resource]:
	var records: Array[Resource] = []
	for index in range(2):
		var item := FollowerData.new()
		item.id = "follower.%s.specialist_%02d" % [slug, index + 1]
		item.display_name = "%s Specialist %02d" % [title, index + 1]
		item.combat_role = "support" if index == 0 else "heavy"
		item.settlement_role = "scout" if index == 0 else "builder"
		item.recruitment_quest = "quest.%s.chapter_%02d" % [slug, index + 1]
		var banter: Array[String] = [
			"{player_name}: Another region, another damn horse problem.",
			item.display_name + ": Then we solve it.",
		]
		item.banter_pool = banter
		records.append(item)
	return records


static func _make_regional_enemies(slug: String, title: String, biome: String) -> Array[Resource]:
	var roles := ["runner", "charger", "spitter", "pack_leader", "armored", "elemental"]
	var records: Array[Resource] = []
	for index in range(roles.size()):
		var item := EnemyData.new()
		item.id = "enemy.horse.%s_threat_%02d" % [slug, index + 1]
		item.display_name = "%s %s" % [title, roles[index].capitalize()]
		item.enemy_role = roles[index]
		item.region_id = "region." + slug
		item.health = 36 + index * 22
		item.damage = 9 + index * 4
		var phases: Array[String] = ["telegraph", "attack", "recover"]
		item.phases = phases
		var loot_table: Array[String] = ["loot.%s.%s_horse_parts" % [slug, biome]]
		item.loot_table = loot_table
		records.append(item)
	return records


static func _make_regional_buildings(slug: String, title: String) -> Array[Resource]:
	var categories := ["defense", "production", "trade", "research", "medicine", "housing"]
	var tiers := ["camp", "outpost", "hamlet", "village", "town", "city"]
	var records: Array[Resource] = []
	for index in range(categories.size()):
		var item := SettlementBuildingData.new()
		item.id = "settlement.building.%s.%s_%02d" % [slug, categories[index], index + 1]
		item.display_name = "%s %s %02d" % [title, categories[index].capitalize(), index + 1]
		item.tier_required = tiers[index]
		item.category = categories[index]
		item.assignment_slots = 1 + index % 3
		item.resource_cost = {"timber": 12 + index * 4, "ore": 4 + index * 2}
		item.resource_output = {categories[index]: 2 + index}
		records.append(item)
	return records


static func _rarity_for_index(index: int) -> String:
	if index >= 12:
		return "legendary"
	if index >= 9:
		return "epic"
	if index >= 5:
		return "rare"
	return "common"
