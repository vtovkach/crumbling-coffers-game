extends Node

# Match Manager will handle timer logic for SINGLEPLAYER ONLY (currently). For multiplayer logic, the server will 
# be keeping track of the timer globally. This is the first iteration of the MatchManager autoload.

enum MatchState {WAITING, COUNTDOWN, RUNNING, ENDED} # May add more states later on.
enum MatchMode {SINGLEPLAYER, MULTIPLAYER}
# Set the current state to waiting by default.
var current_state: MatchState = MatchState.WAITING
# Set the mode to singleplayer by default.
var mode: MatchMode = MatchMode.SINGLEPLAYER
# Variables for score page to hold results of last match
var final_score: int = 0
var time_left: int = 60

# Network identity data from server
var game_id: String = ""
var player_id: String = ""
var udp_port: int = 0
# Removed const map path; game.tscn contains map as child node

@onready var timer: Timer

# Signals that will be called out whenever emitted to notify other functions.
signal time_updated(time: int) 
signal match_ended() 
signal state_changed(new_state: MatchState)
signal match_ready
signal countdown_tick(number: int)
signal countdown_finished
signal prematch_updated(seconds: int)
signal prematch_ended
signal match_started

func show_prematch_countdown(seconds: int) -> void:
	prematch_updated.emit(seconds)

func hide_prematch_countdown() -> void:
	prematch_ended.emit()

func show_match_started() -> void:
	match_started.emit()

# Broadcasts end of match to all clients
@rpc("authority", "call_local", "reliable")
func end_match_rpc() -> void:
	end_match()

func _ready() -> void:
	# Connect handshake to start function
	# Later can be updated to wait for mulpitle match_ready signals before starting match
	match_ready.connect(func(): start_match(60))
	# Initializing MatchManager's timer when ran.
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false # Set to false in order to have timer reset and be used again.
	timer.autostart = false # Manually start the timer.
	add_child(timer)
	
	timer.timeout.connect(_on_game_timer_timeout)
	#print(current_state) # To check if current_state = 0 (which is WAITING)

# =============== Multiplayer Transition =============== #
# Called by Lobby to begin network search
# Lobby is responsible for scene transition
func load_multiplayer_level() -> void:
	# Set mode so scripts know to use server-synced logic
	mode = MatchMode.MULTIPLAYER
	# Form 200 byte 'Search Game' packet
	var search_packet = PacketizationManager.form_tcp_packet(PacketizationManager.TYPE_SEARCH_GAME, 0)
	# Send via TCP queue
	NetworkManager.send_tcp(search_packet)
	
# Looks for 'Game Found' from NetworkManager
func _process(delta: float) -> void:
	if mode == MatchMode.MULTIPLAYER:
		_check_for_game_start()

func _check_for_game_start() -> void:
	# Receive 200 byte packet
	var raw_packet := NetworkManager.receive_tcp()
	if raw_packet.is_empty():
		return
	# Parsing
	var response := PacketizationManager.interpret_tcp_packet(raw_packet)
	# If find match, move to dungeon
	if response.response_type == PacketizationManager.TYPE_GAME_FOUND:
		# Store session data for UDP
		game_id = response.game_id
		player_id = response.player_id
		udp_port = response.port
		# Removed forced scene tree change; Lobby controls this

# =============== State & Time =============== #
# set_state: Will assign/set the current state that is passed to the function and emit corresponding signal.
func set_state(new_state: MatchState) -> void:
	current_state = new_state
	state_changed.emit(current_state)
# Debugging code below to check if singleplayer mode is in proper state.
#	print("I am now this current state:")
#	print(current_state)

# set_time: When called, will assign the new time and emit signal to have HUD update UI.
func set_time(new_time: int) -> void:
	time_left = max(0, new_time) #Clamp to not show below 0 on HUD
	time_updated.emit(time_left)
	
	# Check if the time_left is 0, then switch match state to ENDED by calling end_match.
	if time_left <= 0 and current_state != MatchState.ENDED:
		# Stop timer variable node reference
		if timer:
			timer.stop()
		# In multiplayer must wait for server to send 'Match Over' packet
		if multiplayer.is_server():
			end_match_rpc.rpc()
		elif mode == MatchMode.SINGLEPLAYER:
			end_match()

func start_countdown() -> void:
	set_state(MatchState.COUNTDOWN)
	
	# Move loop so level script doesn't handle it
	var count = 3 
	while count > 0:
		countdown_tick.emit(count)
		await get_tree().create_timer(1.0).timeout
		count -= 1
	countdown_finished.emit()

func start_match(match_duration: int) -> void:
	set_time(match_duration)
	set_state(MatchState.RUNNING)
	
	# check mode to see if need to start timer or not when countdown ends.
	# Only server or single player should run timer logic
	if mode == MatchMode.SINGLEPLAYER or multiplayer.is_server():
		timer.start()

# New end_match function that will change the match state to ENDED wehen the timer runs out.
func end_match() -> void:
	timer.stop()
	set_state(MatchState.ENDED)
	match_ended.emit()


# _on_game_timer_timeout: Checks if the current state is not running. If false, then set timer to decrement current time (time_left).
func _on_game_timer_timeout() -> void:
	# Now will just check if the match state is anything else other than running.
	if current_state != MatchState.RUNNING:
		return
	
	# In multiplayer make only the server calculate time to prevent drift
	# Make clients ignore local clocks
	# game.gd will call set_time() directly using server data
	if mode == MatchMode.MULTIPLAYER and not multiplayer.is_server():
		return
		
	# decrement time by 1 second.
	set_time(time_left - 1)
	
# Make matchmanager responsible for transition
func go_to_score_page() -> void:
	# Ensure game isn't stuck in paused state
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu/score_page.tscn")
	
# Quit logic
func quit_to_main_menu() -> void:
	get_tree().paused = false
	set_state(MatchState.WAITING)
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
