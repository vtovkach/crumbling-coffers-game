extends Control

var elapsed_time: int = 0
var searching: bool = false
var _loading_game: bool = false
var _pending_main_menu: bool = false
var _pending_quit: bool = false
var _pending_tcp_response: PacketizationManager.TCP_Response

@onready var hover_search_style = preload("res://Styles/lobby_menu/hover_search_style.tres")
@onready var hover_cancel_style = preload("res://Styles/lobby_menu/hover_cancel_style.tres")

@onready var pressed_search_style = preload("res://Styles/lobby_menu/pressed_search_style.tres")
@onready var pressed_cancel_style = preload("res://Styles/lobby_menu/pressed_cancel_style.tres")

@onready var search_cancel_button = $CenterContainer/MarginContainer2/VBoxContainer/find_match_button
@onready var main_menu_button = $CenterContainer/MarginContainer2/VBoxContainer/main_menu_button
@onready var search_panel = $MarginContainer1/SearchPanelContainer
@onready var timer_label = $MarginContainer1/SearchPanelContainer/SearchTimerLabel
@onready var search_timer = $SearchTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	# Playe music
	MusicManager.play_music("res://Assets/Music/little-bird.mp3")

	search_panel.visible = false
	timer_label.visible = false
	timer_label.text = "00:00"

	search_cancel_button.add_theme_stylebox_override("hover", hover_search_style)
	search_cancel_button.add_theme_stylebox_override("pressed", pressed_search_style)

	search_timer.timeout.connect(_on_search_timer_timeout)

func _exit_tree() -> void:
	get_tree().set_auto_accept_quit(true)

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if not searching:
		get_tree().quit()
		return
	stop_search()
	if not searching:
		# stop_search failed to send — quit immediately
		get_tree().quit()
		return
	_pending_quit = true
	main_menu_button.disabled = true
	# Fallback: quit after 3 seconds if server never responds
	get_tree().create_timer(3.0).timeout.connect(func(): get_tree().quit())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if searching:
		var raw: PackedByteArray = NetworkManager.receive_tcp()
		if not raw.is_empty():
			_handle_tcp_response(raw)
	if _loading_game:
		var raw: PackedByteArray = NetworkManager.receive_udp()
		if not raw.is_empty():
			_handle_udp_loading(raw)

func _handle_tcp_response(raw: PackedByteArray) -> void:
	var response: PacketizationManager.TCP_Response = PacketizationManager.interpret_tcp_packet(raw)
	if response.response_type == PacketizationManager.TYPE_GAME_NOT_FOUND:
		_on_game_not_found()
	elif response.response_type == PacketizationManager.TYPE_GAME_FOUND:
		_on_game_found(response)

func _handle_udp_loading(raw: PackedByteArray) -> void:
	var response: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw, _pending_tcp_response.game_id)
	if response == null or response.status == PacketizationManager.UDPStatus.ERROR:
		print("interpret_udp_packet failed")
		return
	if response.packet_type == PacketizationManager.UDPPacketType.SERVER_INIT:
		print("lobby: SERVER_INIT received, launching game")
		_launch_game(response)

func _on_game_not_found() -> void:
	print("lobby: game not found, stopping search")
	_reset_search_ui()
	if _pending_quit:
		get_tree().quit()
		return
	if _pending_main_menu:
		get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")

func _on_game_found(response: PacketizationManager.TCP_Response) -> void:
	print("lobby: game found!")
	_pending_main_menu = false
	searching = false
	search_timer.stop()
	elapsed_time = 0
	search_cancel_button.text = "Find Match"
	search_cancel_button.add_theme_stylebox_override("hover", hover_search_style)
	search_cancel_button.add_theme_stylebox_override("pressed", pressed_search_style)
	_start_loading_ui()

	print("lobby: sending UDP INIT to port %d" % response.port)
	var init_packet: Object = PacketizationManager.form_udp_init_packet(response.game_id, response.player_id, response.port)
	if NetworkManager.send_udp_reliable(init_packet) != 0:
		push_error("lobby: failed to send UDP INIT packet")
		_reset_search_ui()
		return
	print("lobby: UDP INIT packet sent")

	_pending_tcp_response = response
	_loading_game = true

func _launch_game(udp_response: PacketizationManager.UDP_Response) -> void:
	_loading_game = false
	var game_scene: PackedScene = load("res://Scenes/Game/game.tscn")
	var game: Game = game_scene.instantiate()
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	game.init(
		_pending_tcp_response.player_id,
		_pending_tcp_response.game_id,
		_pending_tcp_response.port,
		udp_response
	)
	queue_free()

# =========== BUTTON HANDLERS =============
func _on_find_match_button_pressed() -> void:
	if searching:
		stop_search()
	else:
		start_search()

func _on_back_button_pressed() -> void:
	if not searching:
		get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
		return
	stop_search()
	if not searching:
		# stop_search failed and already reset UI, navigate immediately
		get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
		return
	_pending_main_menu = true
	main_menu_button.disabled = true

# ========== SEARCH CONTROL ===========
func start_search() -> void:

	var search_packet: PackedByteArray = PacketizationManager.form_tcp_packet(PacketizationManager.TYPE_SEARCH_GAME, 0)
	if NetworkManager.send_tcp(search_packet) != 0:
		push_error("lobby: failed to send SEARCH_GAME request")
		return
	print("lobby: SEARCH_GAME request sent")

	_start_search_ui()

func stop_search() -> void:
	var stop_packet: PackedByteArray = PacketizationManager.form_tcp_packet(PacketizationManager.TYPE_STOP_SEARCH, 0)
	if NetworkManager.send_tcp(stop_packet) != 0:
		push_error("lobby: failed to send STOP_SEARCH request")
		_reset_search_ui()
		return
	print("lobby: STOP_SEARCH request sent")
	search_cancel_button.disabled = true

func _start_search_ui() -> void:
	searching = true
	elapsed_time = 0
	search_panel.visible = true
	timer_label.visible = true
	timer_label.text = "Searching... 00:00"
	search_cancel_button.text = "Cancel"
	search_cancel_button.add_theme_stylebox_override("hover", hover_cancel_style)
	search_cancel_button.add_theme_stylebox_override("pressed", pressed_cancel_style)
	search_timer.start()

func _start_loading_ui() -> void:
	search_panel.visible = true
	timer_label.visible = true
	timer_label.text = "Game is loading..."
	search_cancel_button.disabled = true
	main_menu_button.disabled = true

func _reset_search_ui() -> void:
	searching = false
	search_timer.stop()
	elapsed_time = 0
	search_panel.visible = false
	timer_label.visible = false
	timer_label.text = "00:00"
	search_cancel_button.disabled = false
	search_cancel_button.text = "Find Match"
	search_cancel_button.add_theme_stylebox_override("hover", hover_search_style)
	search_cancel_button.add_theme_stylebox_override("pressed", pressed_search_style)

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
