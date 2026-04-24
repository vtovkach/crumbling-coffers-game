extends GutTest

# Setup
var player_scene = preload("res://Scenes/Player/controllable_player.tscn")
var player
var root
var platform: StaticBody2D

# All of this setup code is extremely delicate. It is intended to place the character (EXACTLY) on a platform.
func before_each() -> void:
	root = Node2D.new()
	add_child(root)
	
	# --- Platform ---
	platform = StaticBody2D.new()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Platform size
	shape.size = Vector2(1000, 200) # width, height
	collider.shape = shape
	platform.add_child(collider)
	platform.position = Vector2(0, 0)	
	root.add_child(platform)
	
	player = player_scene.instantiate()
	
	# Compute starting y-position: character height / 2 + character y
	var char_height =  player.find_child("CollisionShape2D").shape.height
	player.position = Vector2(0, - (char_height / 2))
	root.add_child(player)
	
	# Waiting period
	await get_tree().physics_frame
	await get_tree().physics_frame

func after_each():
	if root:
		root.queue_free()
		root = null
		player = null
		platform = null


func test_fall_in_air() -> void:
	player.position.y = 5000	# just put the character somewhere other than the ground. 
	player.velocity.y = 0
	var initialVelocityY = player.velocity.y
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
		
	# error due to gravity
	var error = 5
	
	# passes if the player's vertical velocity is more than error greater than initialVelocityY after gravity is applied
	assert_gt(player.velocity.y, initialVelocityY+error, "When in air, the player falls")
	
# "inputless"  -- no direction of movement intent
func test_inputless_stop() -> void:
	player.velocity.x = 300
	var initialVelocityX = player.velocity.x
	await get_tree().physics_frame

	assert_lt(player.velocity.x, initialVelocityX, "Not pressing left or right should slow down a horizontally-moving player")
	
# 2 simulations(ish) 1 test
func test_braking_stop() -> void:
	player.velocity.x = 1600
	player.move(0, 1, 1)	# technically calling this internal isnt ideal but we're testing here
	var speed_after_inputless_stop = player.velocity.x
	
	player.velocity.x = 1600
	player.move(-1, 1, 1)
	var speed_after_braking_stop = player.velocity.x
	
	assert_lt(speed_after_braking_stop, speed_after_inputless_stop, "Holding the opposite direction of movement should make the player turn around faster")
