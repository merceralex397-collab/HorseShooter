extends CanvasLayer

const GAME_MANAGER_PATH := "/root/GameManager"

# UI Controller
# Displays score, high score, and other game information

@onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var high_score_label = $MarginContainer/VBoxContainer/HighScoreLabel

func _get_game_manager() -> Node:
	return get_node_or_null(GAME_MANAGER_PATH)

func _ready():
	# Connect to game manager signals
	var gm := _get_game_manager()
	if gm:
		gm.score_changed.connect(_on_score_changed)
		gm.high_score_changed.connect(_on_high_score_changed)
		_on_score_changed(gm.score)
		_on_high_score_changed(gm.high_score)
	else:
		_on_score_changed(0)
		_on_high_score_changed(0)
	
func _on_score_changed(new_score):
	score_label.text = "Score: " + str(new_score)

func _on_high_score_changed(new_high_score):
	high_score_label.text = "High Score: " + str(new_high_score)
