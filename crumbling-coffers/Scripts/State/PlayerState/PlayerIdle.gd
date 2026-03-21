extends State
class_name PlayerIdle

@export var player: Player

func physics_update(delta: float) -> void:
	player.move(0, delta)
	if not player.is_on_floor():
		transitioned.emit(self, "PlayerFall")
		return
	elif player.jump_pressed:
		transitioned.emit(self, "PlayerJump")
		return
	if player.direction != 0:
		transitioned.emit(self, "PlayerRun")
		return
