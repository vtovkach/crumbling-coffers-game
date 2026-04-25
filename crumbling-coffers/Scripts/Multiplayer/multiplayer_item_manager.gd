extends Node
class_name MultiplayerItemManager

# Tracks active multiplayer-spawned items by their server-provided instance id.
# item_instance_id -> item pickup node
var spawned_items: Dictionary = {}

# Maps server item type ids to local pickup scenes.
# Configure these in the editor after adding this node to a scene.
@export var item_scenes: Dictionary = {}


func has_item(item_instance_id: String) -> bool:
	return spawned_items.has(item_instance_id)


func get_item(item_instance_id: String) -> Node:
	return spawned_items.get(item_instance_id, null)

func spawn_item(x: float, y: float, item_type_id: String, item_instance_id: String) -> Node:
	if item_instance_id.is_empty():
		push_warning("Cannot spawn multiplayer item with empty item_instance_id.")
		return null

	if spawned_items.has(item_instance_id):
		push_warning("Multiplayer item already exists: %s" % item_instance_id)
		return spawned_items[item_instance_id]

	if not item_scenes.has(item_type_id):
		push_warning("No item scene registered for item_type_id: %s" % item_type_id)
		return null

	var scene: PackedScene = item_scenes[item_type_id]
	if scene == null:
		push_warning("Registered item scene is null for item_type_id: %s" % item_type_id)
		return null

	var item_instance := scene.instantiate()
	item_instance.global_position = Vector2(x, y)

	_register_spawned_item(item_instance_id, item_type_id, item_instance)

	add_child(item_instance)
	return item_instance


func remove_item(item_instance_id: String) -> bool:
	if not spawned_items.has(item_instance_id):
		return false

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
	
func _register_spawned_item(item_instance_id: String, item_type_id: String, item_instance: Node) -> void:
	spawned_items[item_instance_id] = item_instance

	item_instance.set_meta("item_instance_id", item_instance_id)
	item_instance.set_meta("item_type_id", item_type_id)
	
	
func handle_player_pickup(player: Node, item_instance_id: String) -> bool:
	if player == null:
		return false

	if not spawned_items.has(item_instance_id):
		return false

	var item_instance: Node = spawned_items[item_instance_id]
	if not is_instance_valid(item_instance):
		spawned_items.erase(item_instance_id)
		return false

	if not _can_player_receive_item(player, item_instance):
		return false

	if not _give_item_to_player(player, item_instance):
		return false

	_send_pickup_request_to_server(item_instance_id, player)

	# Local removal for responsiveness.
	# Server can later confirm this and broadcast removal to all clients.
	remove_item(item_instance_id)

	return true


func _can_player_receive_item(player: Node, item_instance: Node) -> bool:
	# If the item has its own pickup logic, use that as the compatibility layer.
	# Current item_pickup.gd already handles inventory/hotbar insertion.
	if item_instance.has_method("can_apply_to_player"):
		return item_instance.can_apply_to_player(player)

	# Fallback: if no checker exists, allow the pickup attempt.
	return true


func _give_item_to_player(player: Node, item_instance: Node) -> bool:
	if item_instance.has_method("apply_to_player"):
		return item_instance.apply_to_player(player)

	return false


func _send_pickup_request_to_server(item_instance_id: String, player: Node) -> void:
	# TODO: Vadym/server-side networking will implement UDP request here.
	# This should eventually notify the server that this client picked up:
	# - item_instance_id
	# - player id / client id
	pass	
