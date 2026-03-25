extends CharacterBody2D

const SPEED = 600.0
const GRAVITY = 900.0
const FRICTION = 300.0
var direction = 1

var is_frozen: bool = false
var freeze_time_left: float = 0.0

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCast2Left



func apply_freeze(duration: float) -> void:
	is_frozen = true
	freeze_time_left = duration

func clear_freeze() -> void:
	is_frozen = false
	freeze_time_left = 0.0

func _ready() -> void:
		add_to_group("freezable")
		
	
func _physics_process(delta):
	if is_frozen:
		freeze_time_left -= delta
		if freeze_time_left <= 0.0:
			clear_freeze()

	if not is_on_floor():
	
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0
			
	
	if  not is_frozen:
		if ray_cast_right.is_colliding():
			direction = -1
		elif ray_cast_left.is_colliding():
			direction = 1

		velocity.x = direction * SPEED
	else: 
		velocity.x = move_toward(velocity.x, 0, FRICTION*delta)
	move_and_slide()
