extends GutTest

# Setup
var player_scene = preload("res://Scenes/Player/user_player.tscn")
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


# Tests
func test_input_jump() -> void:
	player.velocity.y = 0
	var initialVelocityY = player.velocity.y
		
	Input.action_press("jump")
	await get_tree().physics_frame
	Input.action_release("jump")
	
	# This test condition is admittedly not that great. It's assumed that player is on ground at this point.
	assert_eq(player.jump_pressed, true, "Pressing jump should set jump_pressed to true")


func test_input_left() -> void:
	player.velocity.x = 0
	var initialVelocityX = player.velocity.x
	
	Input.action_press("left")
	await get_tree().physics_frame
	Input.action_release("left")
	
	assert_lt(player.input_direction, 0, "Pressing left should make input direction negative")

func test_input_right() -> void:
	player.velocity.x = 0
	var initialVelocityX = player.velocity.x
	
	Input.action_press("right")
	await get_tree().physics_frame
	Input.action_release("right")
	
	assert_gt(player.input_direction, 0, "Pressing right should make input direction positive")

func test_input_leftandright() -> void:
	player.velocity.x = 0
	var initialVelocityX = player.velocity.x
	
	Input.action_press("right")
	Input.action_press("left")
	await get_tree().physics_frame
	Input.action_release("right")
	Input.action_release("left")
	
	assert_eq(player.input_direction, 0, "Pressing both left and right should have no effect on input direction")
	
