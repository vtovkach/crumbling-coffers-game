# 	Does not have multiplayer support yet;
#	Need to differentiate between client player	
#	and other connected players in same room 

extends CharacterBody2D

# Most of these values are placeholder.
@export var max_speed: float = 1000.0
@export var max_runspeed: float = 600.0

@export var accel: float = 1000.0
@export var decel: float = 500.0
@export var braking_decel: float = 2000.0

func _physics_process(delta: float) -> void:

	# Update velocity
#	move(direction)		Direction given by player input
		
	# Update position
	move_and_slide()


# Update velocity according to direction of movement
# direction: a float in [-1, 1]
# [-1, 0): 	To left.
# 0: 		Stop 
# (0, 1]:	To right.
func move(direction: float, delta: float) -> void:
	if direction:
		if (velocity.x > 0 and direction < 0) or (velocity.x < 0 and direction > 0):
			brake(direction, delta)
		else:
			velocity.x = move_toward(velocity.x, direction * max_runspeed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
	
	
	
# When acceleration direction is against current velocity
# May prefer a state to handle this, especially if custom animation
func brake(direction:float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * max_runspeed, braking_decel * delta)
	
		
# Push this character in a direction, may exceed their max runspeed (but not their max speed)
# Adds to initial velocity
# Consider for external force pushing character
func push(direction: float, pushStrength: float) -> void:
	velocity.x = move_toward(velocity.x, direction * max_speed, pushStrength);
