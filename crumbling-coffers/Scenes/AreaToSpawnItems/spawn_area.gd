extends Area2D

@export var spawn_padding: float = 8.0

func _ready():
	add_to_group("spawn_areas")

func get_random_point() -> Vector2:
	var collision_shape = $CollisionShape2D
	var shape = collision_shape.shape

	if shape is RectangleShape2D:
		var extents = shape.size * 0.5
		var local_center = collision_shape.position

		var x = randf_range(-extents.x + spawn_padding, extents.x - spawn_padding)
		var y = randf_range(-extents.y + spawn_padding, extents.y - spawn_padding)

		return to_global(local_center + Vector2(x, y))

	return global_position
