extends CharacterBody2D

const SPEED = 600.0
const GRAVITY = 900.0

var direction = 1

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCast2Left

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	if ray_cast_right.is_colliding():
		direction = -1
	elif ray_cast_left.is_colliding():
		direction = 1

	velocity.x = direction * SPEED
	move_and_slide()
