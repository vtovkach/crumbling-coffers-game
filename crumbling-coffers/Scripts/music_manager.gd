extends Node

@onready var player: AudioStreamPlayer = $AudioStreamPlayer 

var current_track_path: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func play_music(track_path: String) -> void:
	if current_track_path == track_path and player.playing:
		return

	var stream := load(track_path) as AudioStream
	if stream == null:
		push_error("Failed to load music: " + track_path)
		return

	player.stream = stream
	player.play()
	current_track_path = track_path

func stop_music() -> void:
	player.stop()
	current_track_path = ""
