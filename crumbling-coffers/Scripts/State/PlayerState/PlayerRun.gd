extends State
class_name PlayerRun

@export var player: Player

func physics_update(delta: float) -> void:
	player.move(player.direction, delta)
	if not player.is_on_floor():
		transitioned.emit(self, "PlayerFall")
		return
	elif player.jump_pressed:
		player.jump()
		transitioned.emit(self, "PlayerFall")
		return
