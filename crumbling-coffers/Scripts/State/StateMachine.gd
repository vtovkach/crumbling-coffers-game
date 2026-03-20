extends Node

@export var initial_state : State

var active_state : State
var states : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transitioned.connect(on_child_transition)
	if initial_state:
		initial_state.enter()
		active_state = initial_state

func _process(delta: float) -> void:
	if active_state:
		active_state.update(delta)

func _physics_process(delta: float) -> void:
	if active_state:
		active_state.physics_update(delta)

func on_child_transition(state, new_state_name) -> void:
# Prep
	if state != active_state:
		return
	
	var new_state = states.get(new_state_name)
	if !new_state:
		return
	
# Change of state
	if active_state:
		active_state.exit()
	new_state.enter()
	active_state = new_state
