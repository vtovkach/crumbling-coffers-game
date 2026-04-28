extends Control

# Exporting ScoreBlock
@export var score_block_scene: PackedScene = preload("res://Scenes/Menu/ScoreBlock.tscn")
# Ref new VBoxContainer
@onready var player_list = $PlayersContainer/MarginContainer/PlayerList
@onready var slot1 = $PlayerSlots/Slot1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_display_players()
	#score_val.text = "Score: " + str(MatchManager.final_score)

func _display_players() -> void:
	# Clear any placeholders
	for child in slot1.get_children():
		child.queue_free()
		
	# Creating one block (singleplayer)
	var block = score_block_scene.instantiate()
	#player_list.add_child(block)
	
	# Add block to Slot1
	slot1.add_child(block)
	
	# Manually offsetting block from marker
	var horizontal_nudge = -100 # Move left
	var vertical_nudge = -200   # Move up
	block.position = Vector2(horizontal_nudge, vertical_nudge)
	
	# Set up data
	block.setup("WIZARD", MatchManager.final_score)

func _on_main_menu_button_pressed() -> void:
	# Go back to main menu
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
