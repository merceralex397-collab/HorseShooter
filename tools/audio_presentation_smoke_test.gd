extends Node


func _ready() -> void:
	await get_tree().process_frame

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		_fail("AudioManager autoload missing.")
		return
	var validation: Dictionary = audio_manager.call("validate_audio_assets")
	if not bool(validation.get("ok", false)):
		_fail("Audio assets missing: " + str(validation.get("missing", [])))
		return
	if int(validation.get("music_count", 0)) < 10:
		_fail("Music library lacks region/combat/settlement coverage.")
		return
	if int(validation.get("sfx_count", 0)) < 12:
		_fail("SFX library lacks weapon/horse/UI coverage.")
		return

	var grass_track := String(audio_manager.call("play_region_music", "grassland"))
	var combat_track := String(audio_manager.call("set_combat_intensity", 0.8))
	var settlement_track := String(audio_manager.call("set_settlement_music_state", "city", true))
	if grass_track != "region_grassland" or combat_track != "combat_high" or settlement_track != "settlement_raid":
		_fail("Audio state selection returned wrong tracks.")
		return
	var plan: Dictionary = audio_manager.call("get_audio_plan")
	if String(plan.get("bark_strategy", "")).is_empty() or not bool(plan.get("subtitle_support", false)):
		_fail("Audio plan lacks bark/subtitle strategy.")
		return
	if not plan.get("android_mix_targets", {}).has("phone_speaker"):
		_fail("Audio plan lacks Android speaker mix target.")
		return

	print("AUDIO_PRESENTATION_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("AUDIO_PRESENTATION: " + message)
	get_tree().quit(1)
