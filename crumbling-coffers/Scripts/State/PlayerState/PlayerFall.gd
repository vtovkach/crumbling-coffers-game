extends State
class_name PlayerFall

@export var player: Player

func physics_update(delta: float) -> void:
	player.move(player.direction, delta)	# could be slower but this refactor aims to to preserve behavior
	player.apply_gravity(delta)
	if player.is_on_floor():
		transitioned.emit(self, "PlayerRun" if player.direction == 0 else "PlayerIdle")
		return
