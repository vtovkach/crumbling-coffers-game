extends Node

# Match Manager will handle timer logic for SINGLEPLAYER ONLY (currently). For multiplayer logic, the server will 
# be keeping track of the timer globally. This is the first iteration of the MatchManager autoload.

# The timer logic that is in HUD will be moved out, so it only handles UI updates.
var time_left: int = 60
# Timer should be independent from any other scenes/scripts.
@onready var timer: Timer

# Will need to have these signals in HUD for them to be caught by HUD to update UI.
signal time_updated(time: int) # Have it send out integer numbers, like initialized above.
signal match_ended() # Signal will be used to tell HUD that match is over and update accordingly.

func _ready() -> void:
	# Initializing MatchManager's timer when ran.
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false # Set to false in order to have timer reset and be used again.
	timer.autostart = false # Manually start the timer.
	add_child(timer)
	# Connect to timeout from Timer class, which will be sent out 
	timer.timeout.connect(_on_game_timer_timeout)

func start_match(match_duration: int) -> void:
	time_left = match_duration
	timer.start()
	time_updated.emit(time_left)

# Function that was being handled in HUD moved here:
func _on_game_timer_timeout() -> void:
	if time_left > 0:
		time_left -= 1
		# Update the timer by using signals instead of functions.
		time_updated.emit(time_left)
	else:
		# Stop the timer when we hit 0
		timer.stop()
		match_ended.emit()
