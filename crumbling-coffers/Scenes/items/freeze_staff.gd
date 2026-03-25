extends "res://Scripts/pickup_base.gd"


@export var freeze_duration: float = 5.0

func _on_body_entered(body: Node) -> void:
	for target in get_tree().get_nodes_in_group("freezable"):
# For Testing against yourself - commment out chunk below.
		if target == body:
			continue

	

		if target.has_method("apply_freeze"):
			target.apply_freeze(freeze_duration)

	queue_free()
