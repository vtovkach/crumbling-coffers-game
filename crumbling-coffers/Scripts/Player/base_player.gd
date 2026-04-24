# Player's base clase. Will only contain information that is essential to being a displayable player in the game

extends CharacterBody2D
class_name Player

@onready var sprite: AnimatedSprite2D = get_node_or_null("PlayerSprite") 

# Position, velocity already given by GODOT parent classes. Position is especially important

# Player should also own some variables for rendering, i.e. direction and state.
# Technically this is better as interface, but ALL players will be renderable. So this is appropriate.
@onready var camera: Camera2D = get_node_or_null("Camera2D")	# All players have a camera, making it exist in code allows selecting specific camera (feature enabling) 
@export var direction: float = 0
var last_direction: float = 0

func _process(delta: float) -> void:
	update_facing()

func update_facing() -> void:
	if velocity.x != 0:
		last_direction = sign(velocity.x)
		if sprite:
			sprite.set_flip_h(last_direction < 0) 

func set_animation(anim: String) -> void:
	if sprite and sprite.animation != anim:
		sprite.play(anim) 

func is_animation(anim: String) -> bool:
	if sprite:
		return anim == sprite.animation
	return false
		
func is_animation_concluded(anim: String) -> bool:
	if sprite:
		return sprite.animation == anim and sprite.frame_progress == 1 and sprite.frame == sprite.sprite_frames.get_frame_count(anim) - 1 
	return false #  No sprite default
