extends Control

@onready var score_val = $PlayersContainer/MarginContainer/Player1Block/ScoreValue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score_val.text = "Score: " + str(MatchManager.final_score)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_main_menu_button_pressed() -> void:
	# Go back to main menu
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
