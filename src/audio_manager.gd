extends Node

# Centralized music/SFX routing and playback.

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

const MASTER_BUS := "Master"

@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _music_alt_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _sfx_root: Node
var _active_buses_ready := false
var _current_music_player: AudioStreamPlayer
var _current_music_track := ""
var _current_region_music := ""
var _combat_intensity := 0.0
var _settlement_music_state := "none"
var _master_volume := 1.0
var _music_volume := 1.0
var _sfx_volume := 1.0
var _duck_timer: Timer

var _music_library := {
	"wave_ambient": ["res://assets/sounds/music_loop.wav", "res://assets/sounds/shoot.wav"],
	"region_grassland": ["res://assets/sounds/music_loop.wav"],
	"region_forest": ["res://assets/sounds/music_loop.wav"],
	"region_snow": ["res://assets/sounds/music_loop.wav"],
	"region_coast": ["res://assets/sounds/music_loop.wav"],
	"region_mountain": ["res://assets/sounds/music_loop.wav"],
	"region_volcano": ["res://assets/sounds/music_loop.wav"],
	"region_badlands": ["res://assets/sounds/music_loop.wav"],
	"region_corruption": ["res://assets/sounds/music_loop.wav"],
	"combat_low": ["res://assets/sounds/music_loop.wav"],
	"combat_high": ["res://assets/sounds/music_loop.wav"],
	"settlement_camp": ["res://assets/sounds/music_loop.wav"],
	"settlement_city": ["res://assets/sounds/music_loop.wav"],
	"settlement_raid": ["res://assets/sounds/music_loop.wav"],
}

var _sfx_library := {
	"shoot": [
		"res://assets/sounds/shoot.wav",
		"res://assets/sounds/shoot.wav",
	],
	"hit": [
		"res://assets/sounds/hit.wav",
	],
	"explosion": [
		"res://assets/sounds/explosion.wav",
		"res://assets/sounds/boing.wav",
	],
	"boing": [
		"res://assets/sounds/boing.wav",
	],
	"combo": [
		"res://assets/sounds/hit.wav",
	],
	"round_clear": [
		"res://assets/sounds/explosion.wav",
	],
	"round_fail": [
		"res://assets/sounds/boing.wav",
	],
	"game_over": [
		"res://assets/sounds/explosion.wav",
	],
	"ui": [
		"res://assets/sounds/shoot.wav",
	],
	"powerup": [
		"res://assets/sounds/boing.wav",
	],
	"shield_block": [
		"res://assets/sounds/boing.wav",
	],
	"weapon_pistol": ["res://assets/sounds/shoot.wav"],
	"weapon_shotgun": ["res://assets/sounds/explosion.wav"],
	"weapon_rifle": ["res://assets/sounds/shoot.wav"],
	"horse_runner": ["res://assets/sounds/boing.wav"],
	"horse_charger": ["res://assets/sounds/explosion.wav"],
	"horse_spitter": ["res://assets/sounds/hit.wav"],
	"horse_boss": ["res://assets/sounds/explosion.wav"],
	"dialogue_advance": ["res://assets/sounds/hit.wav"],
	"map_open": ["res://assets/sounds/boing.wav"],
}


func _ready() -> void:
	ensure_buses()
	_setup_players()
	_sfx_root = Node.new()
	_sfx_root.name = "SFXPlayers"
	add_child(_sfx_root)
	_duck_timer = Timer.new()
	_duck_timer.one_shot = true
	add_child(_duck_timer)
	_duck_timer.timeout.connect(_restore_sfx_volume)

	var gm := get_node_or_null("/root/GameManager")
	if gm:
		if not gm.settings_changed.is_connected(_on_settings_changed):
			gm.connect("settings_changed", _on_settings_changed)
		if not gm.request_audio.is_connected(_on_request_audio):
			gm.connect("request_audio", _on_request_audio)
		_on_settings_changed()


func _setup_players() -> void:
	_music_player.bus = BUS_MUSIC
	_music_alt_player.bus = BUS_MUSIC
	_music_player.finished.connect(_on_music_finished.bind(_music_player))
	_music_alt_player.finished.connect(_on_music_finished.bind(_music_alt_player))
	add_child(_music_player)
	add_child(_music_alt_player)
	_current_music_player = _music_player


func _exit_tree() -> void:
	stop_all_audio()
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		if gm.settings_changed.is_connected(_on_settings_changed):
			gm.disconnect("settings_changed", _on_settings_changed)
		if gm.request_audio.is_connected(_on_request_audio):
			gm.disconnect("request_audio", _on_request_audio)


func ensure_buses() -> void:
	if _active_buses_ready:
		return

	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_UI)
	_active_buses_ready = true


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var bus_index = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, MASTER_BUS)

	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index <= 0:
		return
	# Optional clean routing for music and UI.
	if bus_name == BUS_MUSIC or bus_name == BUS_SFX or bus_name == BUS_UI:
		AudioServer.set_bus_send(bus_index, MASTER_BUS)


func _on_settings_changed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return

	_master_volume = float(gm.get_setting("master_volume"))
	_music_volume = float(gm.get_setting("music_volume"))
	_sfx_volume = float(gm.get_setting("sfx_volume"))
	update_bus_levels()


func _on_request_audio(event_name: String, world_position: Vector2, intensity: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	play_sfx(event_name, world_position, float(intensity))


func update_bus_levels() -> void:
	if not _active_buses_ready:
		return
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), _to_db(_master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), _to_db(_music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), _to_db(_sfx_volume))


func _to_db(value: float) -> float:
	value = clamp(value, 0.0, 1.0)
	if value <= 0.0:
		return -80.0
	return linear_to_db(value)


func play_sfx(event_name: StringName, world_position: Vector2 = Vector2.ZERO, intensity: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _sfx_library.has(String(event_name)):
		return

	var candidates: Array = _sfx_library[String(event_name)]
	if candidates.is_empty():
		return

	var picked_path = candidates[randi() % candidates.size()]
	if not ResourceLoader.exists(picked_path):
		return

	var stream := load(picked_path) as AudioStream
	if stream == null:
		return

	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = _to_db(_sfx_volume * clamp(intensity, 0.0, 2.0))
	player.pitch_scale = randf_range(0.92, 1.14)
	player.position = world_position
	_sfx_root.add_child(player)
	player.play()
	player.finished.connect(_on_one_shot_finished.bind(player))

	if String(event_name) in ["explosion", "round_fail", "game_over", "round_clear"]:
		_pulse_duck_sfx()

	if event_name in ["explosion", "game_over", "round_clear", "hit", "shield_block"] and OS.has_feature("mobile"):
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.get_setting("vibration") == true and Input.has_method("vibrate_handheld"):
			var amplitude = int(clamp(20.0 * intensity, 12.0, 40.0))
			Input.vibrate_handheld(amplitude)


func _on_one_shot_finished(player: AudioStreamPlayer2D) -> void:
	player.queue_free()


func play_music(track_name: StringName, immediate: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _music_library.has(String(track_name)):
		return

	var candidates = _music_library[String(track_name)]
	var path = candidates[randi() % candidates.size()]
	if not ResourceLoader.exists(path):
		return

	var stream = load(path) as AudioStream
	if stream == null:
		return

	if _current_music_track == String(track_name) and _current_music_player.playing:
		return

	if immediate or not _current_music_player.playing:
		_current_music_player.stream = stream
		_current_music_player.volume_db = _to_db(_music_volume)
		_current_music_player.play()
		_current_music_track = String(track_name)
		return

	var next_player = _music_alt_player if _current_music_player == _music_player else _music_player
	next_player.stream = stream
	next_player.volume_db = -80.0
	_next_fade_to_track(next_player, _current_music_player)
	_current_music_track = String(track_name)
	_current_music_player = next_player


func play_region_music(biome: String) -> String:
	var track := "region_" + biome
	if not _music_library.has(track):
		track = "wave_ambient"
	_current_region_music = track
	play_music(track, false)
	return track


func set_combat_intensity(intensity: float) -> String:
	_combat_intensity = clampf(intensity, 0.0, 1.0)
	var track := "combat_high" if _combat_intensity >= 0.55 else "combat_low"
	play_music(track, false)
	return track


func set_settlement_music_state(tier: String, under_raid := false) -> String:
	if under_raid:
		_settlement_music_state = "settlement_raid"
	elif tier == "city" or tier == "town":
		_settlement_music_state = "settlement_city"
	else:
		_settlement_music_state = "settlement_camp"
	play_music(_settlement_music_state, false)
	return _settlement_music_state


func get_audio_plan() -> Dictionary:
	return {
		"music_tracks": _music_library.keys(),
		"sfx_events": _sfx_library.keys(),
		"current_track": _current_music_track,
		"current_region_music": _current_region_music,
		"combat_intensity": _combat_intensity,
		"settlement_music_state": _settlement_music_state,
		"bark_strategy": "text_first_subtitled_barks_with_optional_future_voice_assets",
		"subtitle_support": true,
		"android_mix_targets": {
			"phone_speaker": "dialogue/UI legible over music",
			"headphones": "combat transients below clipping, music ducked by large SFX",
		},
	}


func validate_audio_assets() -> Dictionary:
	var missing: Array[String] = []
	for library in [_music_library, _sfx_library]:
		for event_name in library.keys():
			for asset_path in library[event_name]:
				if not ResourceLoader.exists(String(asset_path)):
					missing.append(String(event_name) + ":" + String(asset_path))
	return {"ok": missing.is_empty(), "missing": missing, "music_count": _music_library.size(), "sfx_count": _sfx_library.size()}


func _next_fade_to_track(new_player: AudioStreamPlayer, old_player: AudioStreamPlayer) -> void:
	new_player.play()
	var fade_duration := 0.5
	var music_tween = get_tree().create_tween()
	music_tween.parallel().tween_property(new_player, "volume_db", _to_db(_music_volume), fade_duration)
	music_tween.parallel().tween_property(old_player, "volume_db", -35.0, fade_duration)
	music_tween.tween_callback(func():
		old_player.stop()
		old_player.volume_db = _to_db(_music_volume)
	)


func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music_player and player == _current_music_player:
		player.play()
	if player == _music_alt_player and player == _current_music_player:
		player.play()


func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()
	if _music_alt_player.playing:
		_music_alt_player.stop()
	_current_music_track = ""


func stop_all_audio() -> void:
	stop_music()
	if _music_player:
		_music_player.stream = null
	if _music_alt_player:
		_music_alt_player.stream = null
	if _sfx_root:
		for child in _sfx_root.get_children():
			if child is AudioStreamPlayer2D:
				child.stop()
			child.queue_free()


func play_menu_music() -> void:
	play_music("wave_ambient", true)


func _pulse_duck_sfx() -> void:
	if _duck_timer == null:
		return
	var sfx_bus = AudioServer.get_bus_index(BUS_SFX)
	if sfx_bus == -1:
		return
	var duck_db = _to_db(max(_sfx_volume * 0.45, 0.0))
	AudioServer.set_bus_volume_db(sfx_bus, duck_db)
	_duck_timer.stop()
	_duck_timer.start(0.16)


func _restore_sfx_volume() -> void:
	var sfx_bus = AudioServer.get_bus_index(BUS_SFX)
	if sfx_bus == -1:
		return
	AudioServer.set_bus_volume_db(sfx_bus, _to_db(_sfx_volume))
