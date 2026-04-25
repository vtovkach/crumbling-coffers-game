extends GutTest

# Integration test for seeing if Player, when moving, will stop when hitting a wall in the Map.

# Both tests should pass. Messing/resizing GUT testing window may result in some failed tests.

# Testing if the player scene will stop when met with a wall.
# UPDATED: Now implementing a determined "input" action in order
# to run test "test_player_stops_at_wall()" properly (and does not fail upon running).

# Setup to decrease redundancy.
var world 
var player

func before_each():
	var scene = preload("res://Tests/Scenes/player_hits_wall.tscn")
	world = scene.instantiate()
	add_child(world)
	
	player = world.get_node("Player")

func after_each():
	world.queue_free()
	await wait_physics_frames(1)


# ######################
# Integration test -- Testing that player collides with a wall and stops moving (2 tests).
# ######################

func test_player_stops_at_wall_input_right():
	# Simulating an input action of the user pressing "right".
	Input.action_press("right")
	
	# Need to wait long enough due to 'slow' acceleration of velocity.x
	await wait_physics_frames(250)
	
	# Simulating user releases "right" to slow down velocity.
	Input.action_release("right")
	
	assert_true(player.is_on_wall(), "Player is supposed to be at wall.")


# Testing for player stopping at the wall in the opposite direction (to the left).
func test_player_stops_at_wall_input_left():
	
	Input.action_press("left")
	
	# Shorter waiting since the left wall is closer on the map.
	await wait_physics_frames(200)
	
	Input.action_release("left")
	
	assert_true(player.is_on_wall(), "Player should have collided with left wall.")
