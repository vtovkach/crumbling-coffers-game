extends GutTest

# This file will run an integration test to detect if the player is falling and has met an edge.

var world
var player

# Initial Setup that will run before/after each test.
func before_each():
	var scene = preload("res://Tests/Scenes/player_falls_off_ledge.tscn")
	world = scene.instantiate()
	add_child(world)
	
	player = world.get_node("Player")

func after_each():
	world.queue_free()
	# Ensure that the physic frames frees the Player node.
	await wait_physics_frames(1)


# ###########################
# Integration Tetsing -- detecting player has reached/fell off an edge (2 tests)
# ###########################

func test_player_falls_off_ledge_right():	
	# Simulating moving player to the right
	Input.action_press("right")
	
	# Wait long enough to check player is not on the floor. 
	await wait_physics_frames(120)
	
	Input.action_release("right")
	
	# Check/assert that when the physics frames are finished, that the player is not on contact with 
	# the floor (should be in the air).
	assert_false(player.is_on_floor(), "Player should be off the edge and fallling.")
	assert_true(player.velocity.y > 0, "Player's vertical velocity should be increasing/accelerating.")


func test_player_falls_off_ledge_left():
	# Simulate user input is pressing in the left direction
	Input.action_press("left")
	 
	await wait_physics_frames(120)
	
	Input.action_release("left")
	
	assert_false(player.is_on_floor(), "Player should be off the edge and fallling.")
	assert_true(player.velocity.y > 0, "Player's vertical velocity should be increasing/accelerating.")
