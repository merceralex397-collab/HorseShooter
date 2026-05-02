extends Node

const ArtManifest := preload("res://src/content/art_manifest.gd")

func _ready() -> void:
	await get_tree().process_frame

	var required_assets := [
		"res://assets/sprites/rpg_player_portrait.png",
		"res://assets/sprites/biome_grassland.png",
		"res://assets/sprites/biome_forest.png",
		"res://assets/sprites/biome_snow.png",
		"res://assets/sprites/biome_coast.png",
		"res://assets/sprites/biome_mountain.png",
		"res://assets/sprites/biome_volcano.png",
		"res://assets/sprites/biome_badlands.png",
		"res://assets/sprites/biome_corruption.png",
		"res://assets/sprites/boss_toll_mare.png",
		"res://assets/sprites/boss_last_horse.png",
	]
	for asset_path in required_assets:
		if not FileAccess.file_exists(asset_path):
			_fail("Missing generated graphics asset: " + asset_path)
			return
		var texture := load(asset_path) as Texture2D
		if texture == null:
			_fail("Generated graphics asset is not imported as a Texture2D: " + asset_path)
			return
		if texture.get_width() < 64 or texture.get_height() < 64:
			_fail("Invalid texture dimensions: " + asset_path)
			return
	var manifest_report: Dictionary = ArtManifest.validate_release_assets(8)
	if not bool(manifest_report.get("ok", false)):
		_fail("Release art manifest invalid: " + str(manifest_report))
		return
	if int(manifest_report.get("count", 0)) < 20:
		_fail("Release art manifest is too small.")
		return

	print("GRAPHICS_ASSETS_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("GRAPHICS_ASSETS: " + message)
	get_tree().quit(1)
