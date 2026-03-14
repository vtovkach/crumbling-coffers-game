extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
# Mapped to countdown and game timer labels in scene
@onready var countdown_label: Label = $CenterContainer/CountdownLabel
@onready var game_timer_label: Label = $MarginContainer/GameTimerLabel

func _ready() -> void:
	# Hide the countdown by default
	hide_countdown()
	# Set initial text for game clock
	update_game_timer(60)

func _on_player_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score

func bind_to_player(player) -> void:
	player.score_changed.connect(_on_player_score_changed)
	_on_player_score_changed(player.score)

func hide_countdown() -> void:
	countdown_label.hide()
	
func update_game_timer(seconds: int) -> void:
	game_timer_label.text = str(seconds)
	
