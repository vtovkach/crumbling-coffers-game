extends "res://Scripts/pickup_base.gd"

func _ready() -> void:
	super()
	points = 10

func on_collected(body: Node) -> void:
	if body.has_method("add_score"):
		body.add_score(points)
