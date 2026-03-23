extends MarginContainer

func _ready() -> void:
	MusicManager.play_music("res://Assets/Music/little-bird.mp3")

func _on_lobby_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu/lobby.tscn")


func _on_singleplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Maps/mossy_biome.tscn")


func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu/char_selection.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
