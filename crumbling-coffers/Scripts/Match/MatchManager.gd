extends Node

# Match Manager will handle timer logic for SINGLEPLAYER ONLY (currently). For multiplayer logic, the server will 
# be keeping track of the timer globally. This is the first iteration of the MatchManager autoload.

# The timer logic that is in HUD will be moved out, so it only handles UI updates.
var time_left: int = 60
# Connect the signal "GameTimer" from HUD.tscn to script.
@onready var timer: Timer = $GameTimer

# Will need to have these signals in HUD for them to be caught by HUD to update UI.
signal time_updated(time: int) # Have it send out integer numbers, like initialized above.
signal match_ended() # Signal will be used to tell HUD that match is over and update accordingly.

# Declaring necessary functions. Will implement soon.
func _ready() -> void:
	pass

func start_match() -> void:
	pass

# Function that was being handled in HUD moved here:
func _on_game_timer_timeout() -> void:
	if time_left > 0:
		time_left -= 1
		# Update the timer by using signals instead of functions.
#		update_game_timer(time_left)
	else:
		# Stop the timer when we hit 0
		timer.stop()
		print("Game Over!")
