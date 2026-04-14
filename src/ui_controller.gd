extends CanvasLayer

# UI Controller
# Displays score, high score, and other game information

@onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var high_score_label = $MarginContainer/VBoxContainer/HighScoreLabel

func _ready():
	# Connect to game manager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)
	
	# Initialize labels
	_on_score_changed(GameManager.score)
	_on_high_score_changed(GameManager.high_score)

func _on_score_changed(new_score):
	score_label.text = "Score: " + str(new_score)

func _on_high_score_changed(new_high_score):
	high_score_label.text = "High Score: " + str(new_high_score)
