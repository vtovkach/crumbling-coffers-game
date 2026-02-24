extends Area2D

@export var points: int = 1

func _on_body_entered(body: Node) -> void:
	if body.has_method("add_score"):
		body.add_score(points)
		on_collected(body)
		collect()

func collect():
	queue_free()
		


func on_collected(body: Node) -> void:
	pass
