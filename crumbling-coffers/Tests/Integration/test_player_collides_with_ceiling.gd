extends GutTest

func test_player_hits_ceiling():
	var scene = preload("res://Tests/Scenes/player_hits_wall.tscn")
	var world = scene.instantiate()
	add_child(world)
	
	var player = world.get_node("Player")
	
	# Simulate a user input pressing "jump" button
	Input.action_press("jump")
	
	# CHANGE: updating test to not rely on wait_physics_frames and check how many
	# frames pass before the player hits the ceiling (if any collision happens).
	var max_frames = 100
	var frames_passed = 0
	while not player.is_on_ceiling() and frames_passed < max_frames:
		await wait_physics_frames(1)
		frames_passed += 1
	
	
	# Let go of the "jump" input to avoid failing future test runs.
	Input.action_release("jump")
	
	# Print to terminal how much frames passed before a collision was detected.
	print("Player did not collide with the ceiling until %d physics frames have passed." % frames_passed)
	
	# Assert that the player has hit the ceiling and is in the air.
	assert_true(player.is_on_ceiling(), "Player should collide with the ceiling.")
	assert_true(player.velocity.y >= 0, "Player should stop moving up when colliding with the ceiling.")
	
	# Clean up and free the scene. 
	world.queue_free()
