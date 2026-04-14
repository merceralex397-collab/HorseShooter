extends Node

# Game Manager - Autoload singleton for game state
# Handles score, lives, wave management, etc.

var score: int = 0
var high_score: int = 0
var horses_spawned: int = 0
var horses_killed: int = 0
var game_time: float = 0.0
var is_game_active: bool = true

# Signals for UI updates
signal score_changed(new_score)
signal high_score_changed(new_high_score)
signal horse_spawned
signal horse_killed

func _ready():
	# Load high score from file if exists
	load_high_score()
	reset_game()

func _process(delta):
	if is_game_active:
		game_time += delta

func reset_game():
	score = 0
	horses_spawned = 0
	horses_killed = 0
	game_time = 0.0
	is_game_active = true
	emit_signal("score_changed", score)

func add_score(points: int):
	score += points
	emit_signal("score_changed", score)
	
	# Check for high score
	if score > high_score:
		high_score = score
		emit_signal("high_score_changed", high_score)
		save_high_score()

func register_horse_spawned():
	horses_spawned += 1
	emit_signal("horse_spawned")

func register_horse_killed():
	horses_killed += 1
	emit_signal("horse_killed")

func get_accuracy() -> float:
	if horses_spawned == 0:
		return 0.0
	return float(horses_killed) / float(horses_spawned) * 100.0

func save_high_score():
	# Save high score to user data
	var save_data = {"high_score": high_score}
	var file = FileAccess.open("user://horseshooter_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_high_score():
	# Load high score from user data
	if FileAccess.file_exists("user://horseshooter_save.json"):
		var file = FileAccess.open("user://horseshooter_save.json", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parse_result = JSON.parse_string(content)
			if parse_result and parse_result.has("high_score"):
				high_score = parse_result["high_score"]
