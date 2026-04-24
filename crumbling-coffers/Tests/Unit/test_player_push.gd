extends GutTest

# Setup
var Player = preload("res://Scripts/Player/controllable_player.gd")
var player
var initialVelocity: Vector2

func before_each() -> void:
	initialVelocity = Vector2(0, 0)
	player = Player.new()
	add_child(player)
	await get_tree().process_frame

func after_each() -> void:
	player.queue_free()


# Tests
func test_push_angle() -> void:
	# Player movement
	initialVelocity.x = 200
	initialVelocity.y = 200
	
	player.velocity.x = initialVelocity.x 
	player.velocity.y = initialVelocity.y

	# Push
	var direction = Vector2(-1, -1)
	var angleRad = direction.angle()
	var pushStrength = 200
	
	# For floating point imprecision
	var error = 0.01

	player.push(direction, pushStrength)	
	assert_almost_eq(player.velocity.x, initialVelocity.x + pushStrength * cos(angleRad), error, "When pushed at angle, velocity.x is only the horizontal component of that push")
	assert_almost_eq(player.velocity.y, initialVelocity.y + pushStrength * sin(angleRad), error, "When pushed at angle, velocity.y is only the vertical component of that push")
	
	
func test_push_adds_velocity() -> void:
		# Player movement
	initialVelocity.x = 200
	
	player.velocity.x = initialVelocity.x
	player.velocity.y = initialVelocity.y

	# Push
	var direction = Vector2(-1, 0)
	var angleRad = direction.angle()
	var pushStrength = 5
	
	# For floating point imprecision
	var error = 0.01

	player.push(direction, pushStrength)	
	assert_almost_eq(player.velocity.x, initialVelocity.x + pushStrength * cos(angleRad), error, "When pushed, player velocity was added to (instead of set)")


func test_push_directionless() -> void:
		# Player movement
	initialVelocity.x = 1700
	initialVelocity.y = -1243
	
	player.velocity.x = initialVelocity.x
	player.velocity.y = initialVelocity.y

	# Push
	var direction = Vector2(0, 0)
	var pushStrength = 5214

	player.push(direction, pushStrength)	
	assert_eq(initialVelocity, player.velocity, "When pushed with no direction, nothing changes")
	

func test_push_respects_max_speed() -> void:
	initialVelocity.x = 1700
	initialVelocity.y = -1243
	
	player.velocity.x = initialVelocity.x
	player.velocity.y = initialVelocity.y

	# Push
	var direction = Vector2(90, 180)
	var pushStrength = 521433

	player.push(direction, pushStrength)	
	assert_lte(abs(player.velocity.x), player.max_speed, "After being pushed, player's horizontal speed does not exceed its maximum.")
	assert_lte(abs(player.velocity.y), player.max_speed, "After being pushed, player's vertical speed does not exceed its maximum.")
		

	
