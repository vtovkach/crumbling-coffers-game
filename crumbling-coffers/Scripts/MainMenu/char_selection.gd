extends Node2D

func _ready() -> void:
	MusicManager.play_music("res://Assets/Music/little-bird.mp3")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
