extends State
class_name PlayerJump

@export var player: Player

func enter() -> void:
	player.jump()

func physics_update(delta: float) -> void:
	player.move(player.direction, delta)	# could be slower but this refactor aims to to preserve behavior
	player.apply_gravity(delta)
	if player.velocity.y >= 0:
		transitioned.emit(self, "PlayerFall")
		return
