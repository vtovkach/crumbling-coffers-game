extends Control

var elapsed_time: int = 0
var searching: bool = false

@onready var  timer_label = $MarginContainer1/SearchTimerLabel
@onready var search_timer = $SearchTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide timer initially
	timer_label.visible = false
	timer_label.text = "00:00"
	
	# Connect timer signal 
	search_timer.timeout.connect(_on_search_timer_timeout)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# =========== BUTTON HANDLERS =============
func _on_find_match_button_pressed() -> void:
	start_search()

func _on_cancel_button_pressed() -> void:
	stop_search()
	
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")

# ========== SEARCH CONTROL ===========
func start_search() -> void:
	searching = true
	elapsed_time = 0
	
	timer_label.visible = true
	timer_label.text = "Searching... 00:00"
	
	search_timer.start()
	
func stop_search() -> void:
	searching = false
	
	search_timer.stop()
	timer_label.visible = false

# TIMER UPDATE
func _on_search_timer_timeout() -> void:
	if not searching:
		return
	elapsed_time += 1
	timer_label.text = "Searching... " + format_time(elapsed_time)

# HELPERS 
func format_time(seconds: int) -> String:
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]
