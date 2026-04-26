extends Node
class_name MultiplayerItemManager

var game_id:   String = ""
var game_port: int    = 0

# All instantiated item nodes, keyed by server instance_id.
# Nodes here are not necessarily in the scene tree.
var spawned_items: Dictionary = {}

# Item nodes currently drawn on the map (subset of spawned_items).
# Keyed by server instance_id.
var active_items: Dictionary = {}

# Maps server item type ids to local pickup scenes.
# Configure these in the editor after adding this node to a scene.
@export var item_scenes: Dictionary = {}


func _ready() -> void:
	item_scenes = {
		1: preload("res://Scenes/items/Common Item.tscn"),
		2: preload("res://Scenes/items/Rare Item.tscn"),
		3: preload("res://Scenes/items/Legendary Item.tscn"),
	}

func has_item(item_instance_id: int) -> bool:
	return spawned_items.has(item_instance_id)


func get_item(item_instance_id: int) -> Node:
	return spawned_items.get(item_instance_id, null)

func spawn_item(x: float, y: float, item_type_id: int, item_instance_id: int) -> Node:
	if spawned_items.has(item_instance_id):
		push_warning("Multiplayer item already exists: %d" % item_instance_id)
		return spawned_items[item_instance_id]

	if not item_scenes.has(item_type_id):
		push_warning("No item scene registered for item_type_id: %d" % item_type_id)
		return null

	var scene: PackedScene = item_scenes[item_type_id]
	if scene == null:
		push_warning("Registered item scene is null for item_type_id: %d" % item_type_id)
		return null

	var item_instance := scene.instantiate()
	item_instance.global_position = Vector2(x, y)

	_register_spawned_item(item_instance_id, item_type_id, item_instance)
	_activate_item(item_instance_id, item_instance)

	return item_instance


# Reconciles active_items against the server's authoritative item list.
# packet_ids: Dictionary (instance_id -> anything) — only keys are used.
func update_active_items(packet_ids: Dictionary) -> void:
	for instance_id in active_items.keys():
		if not packet_ids.has(instance_id):
			_deactivate_item(instance_id)

	for instance_id in packet_ids.keys():
		if spawned_items.has(instance_id) and not active_items.has(instance_id):
			_activate_item(instance_id, spawned_items[instance_id])


func remove_item(item_instance_id: int) -> bool:
	if not spawned_items.has(item_instance_id):
		return false

	_deactivate_item(item_instance_id)

	var item_instance: Node = spawned_items[item_instance_id]
	spawned_items.erase(item_instance_id)

	if is_instance_valid(item_instance):
		item_instance.queue_free()

	return true


func clear_all_items() -> void:
	for item in spawned_items.values():
		if is_instance_valid(item):
			item.queue_free()

	spawned_items.clear()
	active_items.clear()

func _register_spawned_item(item_instance_id: int, item_type_id: int, item_instance: Node) -> void:
	spawned_items[item_instance_id] = item_instance

	item_instance.set_meta("item_instance_id", item_instance_id)
	item_instance.set_meta("item_type_id", item_type_id)


func _activate_item(item_instance_id: int, item_instance: Node) -> void:
	active_items[item_instance_id] = item_instance
	add_child(item_instance)


func _deactivate_item(item_instance_id: int) -> void:
	if not active_items.has(item_instance_id):
		return
	var item_instance: Node = active_items[item_instance_id]
	active_items.erase(item_instance_id)
	if is_instance_valid(item_instance) and item_instance.get_parent() == self:
		call_deferred("remove_child", item_instance)


# Multiplayer pickup flow:
# item collision -> PickupBase._on_body_entered -> UserPlayer.receive_pickup ->
# emits item_picked_up signal -> game.gd -> handle_player_pickup (here)
func handle_player_pickup(player: Node, item_instance_id: int) -> bool:
	if player == null:
		return false

	if not spawned_items.has(item_instance_id):
		return false

	var item_instance: Node = spawned_items[item_instance_id]
	if not is_instance_valid(item_instance):
		spawned_items.erase(item_instance_id)
		active_items.erase(item_instance_id)
		return false

	if not _can_player_receive_item(player, item_instance):
		return false

	if not _give_item_to_player(player, item_instance):
		return false

	_send_pickup_request_to_server(item_instance_id, player)

	# Local removal for responsiveness.
	# Server confirms this and broadcasts removal to all clients via ITEMS_AUTH.
	remove_item(item_instance_id)

	return true


func _can_player_receive_item(player: Node, item_instance: Node) -> bool:
	if item_instance.has_method("can_apply_to_player"):
		return item_instance.can_apply_to_player(player)

	return true


func _give_item_to_player(player: Node, item_instance: Node) -> bool:
	if item_instance.has_method("apply_to_player"):
		return item_instance.apply_to_player(player)

	return false


func _send_pickup_request_to_server(item_instance_id: int, player: Node) -> void:
	var item_node: Node = spawned_items.get(item_instance_id, null)
	var item_type: int  = item_node.get_meta("item_type_id") if item_node != null else 0
	var pkt = PacketizationManager.form_udp_pickup_packet(
		game_id,
		player.player_id,
		game_port,
		item_instance_id,
		item_type
	)
	NetworkManager.send_udp_reliable(pkt)
	print("Sent UDP Pickup Packet")
