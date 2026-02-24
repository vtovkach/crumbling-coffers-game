extends "res://Scripts/pickup_base.gd"

func _ready() -> void:
	points = 5

func on_collected(body: Node) -> void:
	print("Common Item Collected.")
