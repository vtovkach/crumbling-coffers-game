extends GutTest

# Path to the player scene
var PlayerScene = load("res://Scenes/Player/player.tscn")

# Test verifies player exists physically i.e. has collision shape
func test_player_has_collision():
	# Instantiate player into the test runner's tree
	var player = PlayerScene.instantiate()
	add_child_autofree(player)
	
	# Search for collision shape or polygon
	var collider = player.find_child("*Collision*", true, false)
	
	# Verify that a collider was found & ensure active
	assert_not_null(collider, "Player must have a CollisionShape2D to interact with boundaries.")
	assert_true(collider.disabled == false, "Player collision shape should not be disabled.")
