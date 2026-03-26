# There could be generalized indicators / inheritance, 
# but typing concerns and me not yet willing to add "Indicatable" interface to everything that exists
# makes me less willing to add the generalization at this moment.

# So for now, this 2-point item indicator will just extend Node2D.
# even though 1-point indicators, 2-point non-item indicators, etc [may] be desired

extends Node2D
class_name TwoPointItemIndicator

@export var source: Player
@export var target: PickupBase

var dir: Vector2

var camera_node: Camera2D
var bounds: Vector2
var margin: float = 4


func _ready() -> void:
	camera_node = get_viewport().get_camera_2d()
	bounds = get_viewport_rect().size

func _process(delta: float) -> void:
	if not target or not source:	# safety
		return

	dir = target.global_position - source.global_position
	_update_rotation()
	_update_position()


func spawn(player: Player, item: PickupBase) -> void:
	source = player
	target = item
	# Add this to a group of indicators

func destroy() -> void:
	source = null
	target = null
	# Remove this from the group of indicators
	
func _update_rotation() -> void:
	# Rotate to face target
	rotation = atan2(dir.y, dir.x)
	
func _update_position() -> void:
	# Place at screen edge between source and target
	pass
