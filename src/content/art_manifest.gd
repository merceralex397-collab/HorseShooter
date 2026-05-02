class_name ArtManifest
extends RefCounted

const PROTAGONIST_ASSETS := {
	"portrait": "res://assets/sprites/rpg_player_portrait.png",
}

const BIOME_ATLASES := {
	"grassland": "res://assets/sprites/biome_grassland.png",
	"forest": "res://assets/sprites/biome_forest.png",
	"snow": "res://assets/sprites/biome_snow.png",
	"coast": "res://assets/sprites/biome_coast.png",
	"mountain": "res://assets/sprites/biome_mountain.png",
	"volcano": "res://assets/sprites/biome_volcano.png",
	"badlands": "res://assets/sprites/biome_badlands.png",
	"corruption": "res://assets/sprites/biome_corruption.png",
}

const BOSS_ATLASES := {
	"enemy.boss.toll_mare": "res://assets/sprites/boss_toll_mare.png",
	"enemy.boss.whiteout_stallion": "res://assets/sprites/boss_whiteout_stallion.png",
	"enemy.boss.reef_kelpie": "res://assets/sprites/boss_reef_kelpie.png",
	"enemy.boss.glassback_colossus": "res://assets/sprites/boss_glassback_colossus.png",
	"enemy.boss.cinder_mare": "res://assets/sprites/boss_cinder_mare.png",
	"enemy.boss.pale_herd_king": "res://assets/sprites/boss_pale_herd_king.png",
	"enemy.boss.last_horse": "res://assets/sprites/boss_last_horse.png",
}

const VFX_ATLASES := {
	"bullet": "res://assets/sprites/bullet.png",
	"explosion_0": "res://assets/sprites/explosion_0.png",
	"explosion_1": "res://assets/sprites/explosion_1.png",
	"explosion_2": "res://assets/sprites/explosion_2.png",
	"explosion_3": "res://assets/sprites/explosion_3.png",
}

const UI_ATLASES := {
	"icon": "res://assets/sprites/icon.png",
}


static func get_release_asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for group in [PROTAGONIST_ASSETS, BIOME_ATLASES, BOSS_ATLASES, VFX_ATLASES, UI_ATLASES]:
		for path in group.values():
			paths.append(String(path))
	return paths


static func validate_release_assets(min_size := 32) -> Dictionary:
	var missing: Array[String] = []
	var invalid: Array[String] = []
	for asset_path in get_release_asset_paths():
		if not FileAccess.file_exists(asset_path):
			missing.append(asset_path)
			continue
		var texture := load(asset_path) as Texture2D
		if texture == null or texture.get_width() < min_size or texture.get_height() < min_size:
			invalid.append(asset_path)
	return {
		"ok": missing.is_empty() and invalid.is_empty(),
		"missing": missing,
		"invalid": invalid,
		"count": get_release_asset_paths().size(),
	}
