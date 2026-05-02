extends Node

# Central contract node for gameplay, score, and session state.
# - Owns game state transitions.
# - Emits event bus signals that scenes/UI/audio consume.
# - Persists versioned run metadata and settings.
enum GameState { MENU, GET_READY, PLAYING, WAVE_CLEAR, WAVE_RETRY, PAUSED, GAME_OVER }

const SAVE_PATH := "user://horseshooter_save.json"
const SAVE_VERSION := 2

signal state_changed(new_state)
signal score_changed(new_score)
signal high_score_changed(new_high_score)
signal lives_changed(new_lives)
signal combo_changed(new_combo)
signal shot_missed(new_misses, misses_remaining)
signal horse_spawned
signal horse_killed
signal accuracy_updated(accuracy_percent, shots_fired, horses_hit)
signal round_started(round_id, profile)
signal round_cleared(round_id, summary)
signal round_failed(round_id, summary)
signal settings_changed()
signal request_score_popup(text, world_position, color_name)
signal request_vfx(vfx_name, world_position, payload)
signal request_audio(event_name, world_position, intensity)
signal hint_requested(text, duration)

@export var max_lives := 3
@export var combo_timeout := 2.1
@export var base_shoot_score := 100
@export var default_round_target := 10
@export var default_max_misses := 18
var state: GameState = GameState.MENU
var state_time := 0.0
var is_game_active := false
var transition_timer := 0.0
var transition_action: Callable

var score := 0
var high_score := 0
var best_round := 0
var total_accuracy := 0.0

var game_time := 0.0
var shots_fired := 0
var horses_hit := 0

var lives := 0
var combo := 0
var combo_timer := 0.0

var current_round := 0
var round_spawned := 0
var round_kills := 0
var round_target := 0
var round_missed := 0
var round_miss_limit := 0
var round_time_remaining := 0.0
var round_active := false
var round_profile: Dictionary = {}

var settings := {
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"auto_fire": false,
	"vibration": true,
	"tutorial_seen": false,
}

var _accuracy_samples: Array[float] = []


func _ready() -> void:
	load_state()
	reset_game()


func _process(delta: float) -> void:
	if is_game_active:
		game_time += delta
		state_time += delta

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(combo)
			combo_timer = 0.0

	if transition_timer > 0.0:
		transition_timer -= delta
		if transition_timer <= 0.0 and transition_action.is_valid():
			var action := transition_action
			transition_action = Callable()
			action.call()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()


func reset_game() -> void:
	score = 0
	shots_fired = 0
	horses_hit = 0
	_accuracy_samples = []
	game_time = 0.0
	lives = max(max_lives, 1)
	combo = 0
	combo_timer = 0.0
	current_round = 0
	round_spawned = 0
	round_kills = 0
	round_target = 0
	round_missed = 0
	round_miss_limit = 0
	round_time_remaining = 0.0
	round_active = false
	state = GameState.MENU
	is_game_active = false
	transition_timer = 0.0
	transition_action = Callable()
	emit_all_primary_signals()
	shot_missed.emit(round_missed, max(round_miss_limit - round_missed, 0))
	state_changed.emit(state)


func get_round_profile(round_id: int) -> Dictionary:
	return get_wave_profile(round_id)


func emit_all_primary_signals() -> void:
	score_changed.emit(score)
	high_score_changed.emit(high_score)
	lives_changed.emit(lives)
	combo_changed.emit(combo)
	notify_accuracy()


func start_game() -> void:
	reset_game()
	_set_state(GameState.GET_READY)
	transition_action = Callable(self, "_start_play")
	transition_timer = 0.75


func _start_play() -> void:
	_set_state(GameState.PLAYING)
	start_next_round()


func start_next_round() -> void:
	if lives <= 0:
		_set_state(GameState.GAME_OVER)
		return

	current_round += 1
	round_profile = get_wave_profile(current_round)
	round_spawned = 0
	round_kills = 0
	round_missed = 0
	round_miss_limit = int(round_profile.get("max_misses", default_max_misses))
	round_target = int(max(default_round_target, round_profile.get("target_horses", default_round_target)))
	round_time_remaining = float(round_profile.get("time_limit", 18.0))
	combo = 0
	combo_timer = 0.0
	combo_changed.emit(combo)
	round_active = true
	is_game_active = true
	_set_state(GameState.PLAYING)
	round_started.emit(current_round, round_profile)


func retry_round() -> void:
	if lives <= 0:
		_set_state(GameState.GAME_OVER)
		return
	_set_state(GameState.PLAYING)
	round_profile = get_wave_profile(current_round)
	round_spawned = 0
	round_kills = 0
	round_missed = 0
	round_miss_limit = int(round_profile.get("max_misses", default_max_misses))
	round_time_remaining = float(round_profile.get("time_limit", 18.0))
	combo = 0
	combo_timer = 0.0
	combo_changed.emit(combo)
	round_active = true
	is_game_active = true
	round_started.emit(current_round, round_profile)


func pause_game() -> void:
	if state != GameState.PLAYING and state != GameState.GET_READY:
		return
	_set_state(GameState.PAUSED)
	get_tree().paused = true


func resume_game() -> void:
	if state != GameState.PAUSED:
		return
	get_tree().paused = false
	_set_state(GameState.PLAYING)


func update_round_clock(delta: float) -> void:
	if state != GameState.PLAYING or not round_active:
		return
	round_time_remaining -= delta
	if round_time_remaining <= 0.0:
		round_time_remaining = 0.0
		fail_round("Time ran out")


func add_shot_fired() -> void:
	shots_fired += 1
	notify_accuracy()


func register_shot_missed() -> void:
	if not round_active or state != GameState.PLAYING:
		return
	round_missed += 1
	combo = max(combo - 1, 0)
	combo_changed.emit(combo)
	notify_accuracy()
	shot_missed.emit(round_missed, max(round_miss_limit - round_missed, 0))
	if round_miss_limit > 0 and round_missed >= round_miss_limit:
		fail_round("Too many misses")


func register_horse_spawned() -> void:
	round_spawned += 1
	horse_spawned.emit()


func register_horse_hit(points: int, world_position := Vector2.ZERO) -> void:
	if not round_active or state != GameState.PLAYING:
		return

	round_kills += 1
	horses_hit += 1
	combo += 1
	combo_timer = combo_timeout
	combo_changed.emit(combo)
	add_score(points)
	horse_killed.emit()

	var accuracy = get_accuracy()
	notify_accuracy()
	request_score_popup.emit("%d" % points, world_position, _combo_color_name(combo))
	request_audio.emit("hit", world_position, 1.0)
	request_vfx.emit("combo_text", world_position, {"combo": combo})

	if combo >= 10 and randf() < 0.4:
		request_audio.emit("combo", world_position, 1.3)

	if is_round_complete():
		complete_round()


func is_round_complete() -> bool:
	return round_active and round_kills >= round_target and round_spawned >= round_target


func complete_round() -> void:
	if not round_active or state != GameState.PLAYING:
		return
	round_active = false

	var accuracy = get_accuracy()
	var accuracy_bonus = int(round_time_remaining) * 2
	var clear_bonus = max(0, 120 - int(accuracy * 3.0))
	var final_points = max(40, accuracy_bonus + (100 - clear_bonus))
	add_score(final_points)

	var summary := {
		"round": current_round,
		"kills": round_kills,
		"target": round_target,
		"misses": round_missed,
		"misses_remaining": max(round_miss_limit - round_missed, 0),
		"accuracy": accuracy,
		"time_left": round_time_remaining,
		"bonus": final_points,
	}
	round_cleared.emit(current_round, summary)
	_set_state(GameState.WAVE_CLEAR)
	request_vfx.emit("round_clear", Vector2.ZERO, summary)
	request_audio.emit("round_clear", Vector2.ZERO, 1.0)

	if current_round > best_round:
		best_round = current_round

	save_state()
	transition_action = Callable(self, "_advance_after_clear")
	transition_timer = 1.7


func _advance_after_clear() -> void:
	_set_state(GameState.PLAYING)
	start_next_round()


func fail_round(reason := "Failed") -> void:
	if state != GameState.PLAYING or not round_active:
		return
	round_active = false

	lives -= 1
	lives = max(lives, 0)
	lives_changed.emit(lives)
	_accuracy_samples.push_front(get_accuracy())
	if _accuracy_samples.size() > 64:
		_accuracy_samples.resize(64)
	recalculate_total_accuracy()

	round_failed.emit(current_round, {"round": current_round, "reason": reason})
	request_vfx.emit("round_fail", Vector2.ZERO, {"reason": reason})
	request_audio.emit("round_fail", Vector2.ZERO, 1.0)

	if lives <= 0:
		_set_state(GameState.GAME_OVER)
		request_vfx.emit("game_over", Vector2.ZERO, {})
		request_audio.emit("game_over", Vector2.ZERO, 1.0)
		save_state()
		return

	_set_state(GameState.WAVE_RETRY)
	transition_action = Callable(self, "retry_round")
	transition_timer = 1.6
	save_state()


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
	if score > high_score:
		high_score = score
		high_score_changed.emit(high_score)


func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return float(horses_hit) / float(shots_fired) * 100.0


func notify_accuracy() -> void:
	accuracy_updated.emit(get_accuracy(), shots_fired, horses_hit)


func recalculate_total_accuracy() -> void:
	total_accuracy = 0.0
	for value in _accuracy_samples:
		total_accuracy += float(value)
	if _accuracy_samples.size() > 0:
		total_accuracy /= float(_accuracy_samples.size())
	else:
		total_accuracy = 0.0
	settings["total_accuracy"] = total_accuracy


func set_setting(key: String, value) -> void:
	if not settings.has(key):
		return
	match key:
		"master_volume", "music_volume", "sfx_volume":
			settings[key] = clamp(float(value), 0.0, 1.0)
		"auto_fire", "vibration", "tutorial_seen":
			settings[key] = bool(value)
		_:
			settings[key] = value
	settings_changed.emit()
	save_state()


func get_setting(key: String):
	return settings.get(key)


func get_wave_profile(round_id: int) -> Dictionary:
	var progress: float = clamp(float(round_id) / 24.0, 0.0, 1.0)
	var target_horses := int(clamp(8.0 + float(round_id) * 2.0, 10.0, 42.0))
	var spawn_interval: float = max(0.34, 0.88 - progress * 0.42)
	var spawn_variance: float = 0.08 + progress * 0.12
	var minimum_time: float = float(target_horses) * (spawn_interval + spawn_variance * 0.35) + 8.0
	var time_limit: float = max(20.0 + progress * 12.0, minimum_time)
	var advanced_progress: float = max(progress - 0.08, 0.0)
	return {
		"id": round_id,
		"target_horses": target_horses,
		"spawn_interval": spawn_interval,
		"spawn_interval_variance": spawn_variance,
		"time_limit": time_limit,
		"base_speed": 78.0 + progress * 38.0,
		"point_value": base_shoot_score + round_id * 5,
		"escape_ratio": min(0.24, advanced_progress * 0.16),
		"splitter_ratio": min(0.14, advanced_progress * 0.08),
		"zigzag_ratio": min(0.30, 0.08 + progress * 0.12),
		"powerup_chance": clamp(0.10 + progress * 0.08, 0.10, 0.28),
		"max_misses": int(clamp(18.0 - progress * 7.0, 9.0, 22.0)),
	}


func _combo_color_name(combo_value: int) -> String:
	if combo_value >= 10:
		return "Epic"
	if combo_value >= 6:
		return "Wild"
	if combo_value >= 3:
		return "Hot"
	return "Normal"


func _set_state(next_state: GameState) -> void:
	state = next_state
	state_time = 0.0
	is_game_active = next_state == GameState.PLAYING or next_state == GameState.GET_READY
	state_changed.emit(state)


func save_state() -> void:
	var save_data := {
		"version": SAVE_VERSION,
		"high_score": high_score,
		"best_round": best_round,
		"total_accuracy": total_accuracy,
		"settings": settings,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return
	var save_data := parsed as Dictionary
	if int(save_data.get("version", 1)) > SAVE_VERSION:
		return

	high_score = int(save_data.get("high_score", 0))
	best_round = int(save_data.get("best_round", 0))
	total_accuracy = float(save_data.get("total_accuracy", 0.0))
	var loaded_settings = save_data.get("settings", {})
	if loaded_settings is Dictionary:
		for key in settings.keys():
			if loaded_settings.has(key):
				settings[key] = loaded_settings[key]
	_normalize_settings()
	settings_changed.emit()


func _normalize_settings() -> void:
	settings["master_volume"] = clamp(float(settings.get("master_volume", 1.0)), 0.0, 1.0)
	settings["music_volume"] = clamp(float(settings.get("music_volume", 1.0)), 0.0, 1.0)
	settings["sfx_volume"] = clamp(float(settings.get("sfx_volume", 1.0)), 0.0, 1.0)
	settings["auto_fire"] = bool(settings.get("auto_fire", false))
	settings["vibration"] = bool(settings.get("vibration", true))
	settings["tutorial_seen"] = bool(settings.get("tutorial_seen", false))


func request_hint(text: String, duration: float = 2.4) -> void:
	if text.is_empty():
		return
	hint_requested.emit(text, duration)
