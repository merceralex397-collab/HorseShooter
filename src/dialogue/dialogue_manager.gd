extends Node

const SAVE_MANAGER_PATH := "/root/SaveManager"

var bark_cooldowns := {}
var dialogue_flags := {}
var active_conversation := {}
var subtitles_enabled := true
var text_speed := 1.0


func render_line(line: String, context := {}) -> String:
	var rendered := line
	var player_name := _resolve_player_name(context)
	rendered = rendered.replace("{player_name}", player_name)
	return rendered


func render_exchange(lines: Array, context := {}) -> Array[String]:
	var rendered: Array[String] = []
	for line in lines:
		rendered.append(render_line(String(line), context))
	return rendered


func request_bark(trigger: String, now_seconds: float, minimum_gap := 8.0) -> String:
	var last_time := float(bark_cooldowns.get(trigger, -9999.0))
	if now_seconds - last_time < minimum_gap:
		return ""
	bark_cooldowns[trigger] = now_seconds
	match trigger:
		"horse_seen":
			return render_line("{player_name}: Damn horse. I hate every hoof on that bastard.")
		"horse_escape":
			return render_line("{player_name}: Shit. It ran. I hate horses even more now.")
		"settlement":
			return render_line("{player_name}: Fine, build the town. Keep the damn horses out.")
		_:
			return render_line("{player_name}: I hate horses. Continue.")


func start_conversation(conversation: Dictionary, context := {}) -> Dictionary:
	active_conversation = conversation.duplicate(true)
	active_conversation["line_index"] = 0
	active_conversation["context"] = context.duplicate(true) if context is Dictionary else {}
	active_conversation["closed"] = false
	return get_dialogue_state()


func advance() -> Dictionary:
	if active_conversation.is_empty() or bool(active_conversation.get("closed", false)):
		return get_dialogue_state()
	var lines: Array = active_conversation.get("lines", [])
	var next_index := int(active_conversation.get("line_index", 0)) + 1
	if next_index >= lines.size():
		active_conversation["closed"] = true
	else:
		active_conversation["line_index"] = next_index
	return get_dialogue_state()


func choose_response(choice_id: String) -> Dictionary:
	if active_conversation.is_empty():
		return get_dialogue_state()
	for choice in active_conversation.get("choices", []):
		if not (choice is Dictionary) or String(choice.get("id", "")) != choice_id:
			continue
		for flag_id in choice.get("set_flags", []):
			dialogue_flags[String(flag_id)] = true
		var quest_manager := get_node_or_null("/root/QuestManager")
		if quest_manager:
			var starts := String(choice.get("start_quest", ""))
			if not starts.is_empty():
				quest_manager.call("start_quest", starts)
			var completes := String(choice.get("complete_objective", ""))
			var quest_id := String(choice.get("quest_id", ""))
			if not completes.is_empty() and not quest_id.is_empty():
				quest_manager.call("advance_objective", quest_id, completes)
		active_conversation["selected_choice"] = choice_id
		if bool(choice.get("closes", true)):
			active_conversation["closed"] = true
		return get_dialogue_state()
	return get_dialogue_state()


func close_conversation() -> void:
	if not active_conversation.is_empty():
		active_conversation["closed"] = true


func get_dialogue_state() -> Dictionary:
	if active_conversation.is_empty():
		return {"active": false, "subtitles_enabled": subtitles_enabled, "text_speed": text_speed}
	var lines: Array = active_conversation.get("lines", [])
	var line_index := clampi(int(active_conversation.get("line_index", 0)), 0, maxi(lines.size() - 1, 0))
	var context: Dictionary = active_conversation.get("context", {})
	var line := ""
	if not lines.is_empty():
		line = render_line(String(lines[line_index]), context)
	return {
		"active": not bool(active_conversation.get("closed", false)),
		"conversation_id": String(active_conversation.get("id", "")),
		"speaker": render_line(String(active_conversation.get("speaker", "")), context),
		"portrait_id": String(active_conversation.get("portrait_id", "portrait.unknown")),
		"line": line,
		"line_index": line_index,
		"line_count": lines.size(),
		"choices": _visible_choices(active_conversation.get("choices", [])),
		"selected_choice": String(active_conversation.get("selected_choice", "")),
		"subtitles_enabled": subtitles_enabled,
		"text_speed": text_speed,
	}


func set_subtitle_settings(enabled: bool, speed: float) -> void:
	subtitles_enabled = enabled
	text_speed = clampf(speed, 0.5, 2.5)


func export_state() -> Dictionary:
	return {
		"bark_cooldowns": bark_cooldowns.duplicate(true),
		"dialogue_flags": dialogue_flags.duplicate(true),
		"active_conversation": active_conversation.duplicate(true),
		"subtitles_enabled": subtitles_enabled,
		"text_speed": text_speed,
	}


func import_state(state: Dictionary) -> void:
	if state.get("bark_cooldowns", {}) is Dictionary:
		bark_cooldowns = (state.get("bark_cooldowns", {}) as Dictionary).duplicate(true)
	else:
		bark_cooldowns = {}
	dialogue_flags = (state.get("dialogue_flags", {}) as Dictionary).duplicate(true) if state.get("dialogue_flags", {}) is Dictionary else {}
	active_conversation = (state.get("active_conversation", {}) as Dictionary).duplicate(true) if state.get("active_conversation", {}) is Dictionary else {}
	subtitles_enabled = bool(state.get("subtitles_enabled", true))
	text_speed = clampf(float(state.get("text_speed", 1.0)), 0.5, 2.5)


func _resolve_player_name(context) -> String:
	if context is Dictionary and context.has("player_name"):
		return String(context["player_name"])
	var save_manager := get_node_or_null(SAVE_MANAGER_PATH)
	if save_manager and save_manager.has_method("get_active_character_name"):
		return String(save_manager.get_active_character_name())
	return "Rider"


func _visible_choices(choices: Array) -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for choice in choices:
		if not (choice is Dictionary):
			continue
		var required_flag := String(choice.get("requires_flag", ""))
		if not required_flag.is_empty() and not bool(dialogue_flags.get(required_flag, false)):
			continue
		visible.append((choice as Dictionary).duplicate(true))
	return visible
