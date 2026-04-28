extends MarginContainer

@onready var sprite = $VBoxContainer/Sprite/AnimatedSprite2D
@onready var name_label = $VBoxContainer/TextContainer/NameLabel
@onready var score_label = $VBoxContainer/TextContainer/ScoreLabel

func setup(player_id: String, score: int, color_type: int = 0) -> void:
	# If called too early, wait
	if not is_node_ready():
		await ready
	
	# Requirement: Display only the first 6 characters of the hex string
	name_label.text = "ID: " + player_id.left(6)
	score_label.text = "Score: " + str(score)
	
	# Ensure the idle animation plays immediately
	if sprite:
		sprite.play("idle")
		
