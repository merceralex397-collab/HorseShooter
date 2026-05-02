extends Node

const MAX_MISS_PRESSURE := 40
const ROUND_CLEAR_TIMEOUT_MS := 2500
const POST_CLEAR_WAIT_MS := 2200

var gm: Node


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	gm = get_node_or_null("/root/GameManager")
	if gm == null:
		push_error("CI_SMOKE: GameManager autoload not found.")
		get_tree().quit(1)
		return

	if not await _check_wave_profile_timing():
		get_tree().quit(1)
		return
	if not _check_wave_profile_playability():
		get_tree().quit(1)
		return
	if not await _check_round_transitions():
		get_tree().quit(1)
		return
	if not await _check_failure_and_retry_flow():
		get_tree().quit(1)
		return
	if not await _check_miss_pressure_flow():
		get_tree().quit(1)
		return

	print("CI_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _wait_until_state(target_state: int, timeout_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if gm.state == target_state:
			return true
		await get_tree().process_frame
	return false


func _check_wave_profile_timing() -> bool:
	print("CI_SMOKE: wave profile timing")
	var observed_round_started := [false]
	var callback = func(_round_id: int, _profile: Dictionary) -> void:
		observed_round_started[0] = true
	gm.round_started.connect(callback, CONNECT_ONE_SHOT)

	gm.start_game()
	if not await _wait_until_state(gm.GameState.GET_READY, 800):
		push_error("CI_SMOKE: Expected GET_READY state after start_game.")
		return false

	if not await _wait_for_round_start(observed_round_started, 8000):
		push_error("CI_SMOKE: Did not receive round_started signal.")
		return false

	var profile: Dictionary = gm.get_round_profile(1) as Dictionary
	var target := int(profile.get("target_horses", 0))
	var time_limit := float(profile.get("time_limit", 0.0))
	if target <= 0 or time_limit <= 0.0:
		push_error("CI_SMOKE: Invalid round-1 profile target=%s time=%s" % [str(target), str(time_limit)])
		return false
	if target > 30:
		push_error("CI_SMOKE: Wave target too high for validation baseline: " + str(target))
		return false
	if time_limit > 60.0:
		push_error("CI_SMOKE: Wave time limit exceeded validation baseline: " + str(time_limit))
		return false
	return true


func _check_wave_profile_playability() -> bool:
	print("CI_SMOKE: wave profile playability")
	var profile: Dictionary = gm.get_round_profile(1) as Dictionary
	var target := int(profile.get("target_horses", 0))
	var spawn_interval := float(profile.get("spawn_interval", 0.0))
	var spawn_variance := float(profile.get("spawn_interval_variance", 0.0))
	var time_limit := float(profile.get("time_limit", 0.0))
	var expected_spawn_window := float(target) * (spawn_interval + spawn_variance * 0.35)
	var minimum_playable_time := expected_spawn_window + 8.0
	if time_limit < minimum_playable_time:
		push_error("CI_SMOKE: Round-1 timer is too strict for spawn cadence. target=%s spawn_window=%.2f time=%.2f required=%.2f" % [str(target), expected_spawn_window, time_limit, minimum_playable_time])
		return false
	return true


func _check_round_transitions() -> bool:
	print("CI_SMOKE: round transitions")
	var start_round = gm.current_round
	var profile := gm.get_round_profile(max(start_round, 1)) as Dictionary
	var target = int(profile.get("target_horses", 16))
	for _i in range(target):
		gm.register_horse_spawned()
		gm.register_horse_hit(100, Vector2.ZERO)

	if not await _wait_until_state(gm.GameState.WAVE_CLEAR, ROUND_CLEAR_TIMEOUT_MS):
		push_error("CI_SMOKE: Round clear state not reached after synthetic kills.")
		return false

	await get_tree().process_frame
	if not await _wait_until_state(gm.GameState.PLAYING, POST_CLEAR_WAIT_MS):
		push_error("CI_SMOKE: Round transition to next round did not happen.")
		return false

	if gm.current_round <= start_round:
		push_error("CI_SMOKE: Round did not advance after clear.")
		return false
	if gm.current_round != start_round + 1:
		push_error("CI_SMOKE: Expected to advance exactly one round. current=%s expected=%s" % [str(gm.current_round), str(start_round + 1)])
		return false
	return true


func _check_failure_and_retry_flow() -> bool:
	print("CI_SMOKE: failure and retry")
	var lives_before = gm.lives
	for _i in range(max(1, gm.round_miss_limit + 1)):
		gm.register_shot_missed()
		await get_tree().process_frame
		if gm.state == gm.GameState.WAVE_RETRY or gm.state == gm.GameState.GAME_OVER:
			break

	if gm.state != gm.GameState.WAVE_RETRY and gm.state != gm.GameState.GAME_OVER:
		push_error("CI_SMOKE: Miss pressure did not trigger retry/game over state.")
		return false

	if gm.state == gm.GameState.GAME_OVER:
		gm.start_game()
		if not await _wait_until_state(gm.GameState.PLAYING, 1200):
			push_error("CI_SMOKE: Game restart after game over did not return to PLAYING.")
			return false
		return true

	gm.retry_round()
	if not await _wait_until_state(gm.GameState.PLAYING, 1200):
		push_error("CI_SMOKE: Retry flow did not return to PLAYING.")
		return false
	if gm.lives != lives_before - 1:
		push_error("CI_SMOKE: Retry life bookkeeping changed unexpectedly: lives_before=%s lives_now=%s" % [str(lives_before), str(gm.lives)])
		return false
	return true


func _check_miss_pressure_flow() -> bool:
	print("CI_SMOKE: miss pressure")
	var profile: Dictionary = gm.get_round_profile(gm.current_round)
	var base_interval := float(profile.get("spawn_interval", 0.9))
	if base_interval > 2.5:
		push_error("CI_SMOKE: Spawn pacing degraded unexpectedly: " + str(base_interval))
		return false

	for _i in range(MAX_MISS_PRESSURE):
		gm.register_shot_missed()
		await get_tree().process_frame
		if gm.state != gm.GameState.PLAYING:
			break

	if gm.state == gm.GameState.GAME_OVER:
		gm.start_game()
		if not await _wait_until_state(gm.GameState.PLAYING, 1200):
			push_error("CI_SMOKE: Restart from miss pressure overrun did not return to PLAYING.")
			return false
	elif gm.state == gm.GameState.WAVE_RETRY:
		gm.retry_round()
		if not await _wait_until_state(gm.GameState.PLAYING, 1200):
			push_error("CI_SMOKE: Retry from miss pressure did not return to PLAYING.")
			return false

	return true


func _wait_for_round_start(observed: Array, timeout_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if bool(observed[0]):
			return true
		await get_tree().process_frame
	return false
