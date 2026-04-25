extends Resource
class_name Hotbar

# Signal will be used to be sent out and then the changes to update the UI will be made and visible.
signal update
# Signal used to send out when an item is used.
signal item_used(index)

signal item_use_requested(index: int, request: Dictionary)

# Same insertion functionality as inventory.gd. Using different name conventions.
@export var hotbar_slots: Array[HotbarSlot]


func hotbar_insert(item: HotbarItem) -> bool:
	if item == null:
		return false

	var itemSlots = hotbar_slots.filter(func(slot): return slot.hotbar_item == item) 
	if !itemSlots.is_empty():
		itemSlots[0].amount += 1
	else:
		var emptySlots = hotbar_slots.filter(func(slot): return slot.hotbar_item == null)
		if !emptySlots.is_empty():
			emptySlots[0].hotbar_item = item
			emptySlots[0].amount = 1
	# Emit hotbar's update signal.
	update.emit()
	return true
# Reset the hotbar to have no items when a new match is started. Similar behavior to inventory's reset_inv().
func reset_hotbar() -> void:
	for hotbar_slot in hotbar_slots:
		hotbar_slot.hotbar_item = null
		hotbar_slot.amount = 0
	update.emit()
	
	
func use_item(index: int, scene_tree: SceneTree = null, user: Node = null, apply_locally: bool = true) -> bool:
	if index < 0 or index >= hotbar_slots.size():
		return false

	var slot = hotbar_slots[index]
	if slot == null or slot.hotbar_item == null:
		return false

	var item: HotbarItem = slot.hotbar_item
	if not item.can_use():
		return false

	var request := item.build_use_request(user)
	item_use_requested.emit(index, request)

	# Current single-player/local behavior. In multiplayer this can be disabled and the
	# server can validate/broadcast the request instead.
	if apply_locally and scene_tree != null:
		_apply_use_request_locally(request, scene_tree, user)

	if item.consumed_on_use:
		_consume_slot(index)
		item_used.emit(index)
	else:
		update.emit()

	return true


func _consume_slot(index: int) -> void:
	if index < 0 or index >= hotbar_slots.size():
		return

	var slot = hotbar_slots[index]
	if slot == null or slot.hotbar_item == null:
		return

	slot.amount -= 1

	if slot.amount <= 0:
		slot.hotbar_item = null
		slot.amount = 0

	update.emit()


func _apply_use_request_locally(request: Dictionary, scene_tree: SceneTree, user: Node = null) -> void:
	var method: StringName = request.get("effect_method", &"")
	if method == &"":
		return

	var targets := _get_local_targets(request, scene_tree, user)
	for target in targets:
		_apply_effect_to_target(target, request)


func _get_local_targets(request: Dictionary, scene_tree: SceneTree, user: Node = null) -> Array[Node]:
	var mode: int = request.get("target_mode", HotbarItem.TargetMode.NONE)
	var group_name: StringName = request.get("target_group", &"")

	match mode:
		HotbarItem.TargetMode.USER_ONLY:
			return [user] if user != null else []
		HotbarItem.TargetMode.GROUP_EXCLUDING_USER, HotbarItem.TargetMode.GROUP_INCLUDING_USER:
			if group_name == &"":
				return []
			var targets: Array[Node] = []
			for target in scene_tree.get_nodes_in_group(String(group_name)):
				if mode == HotbarItem.TargetMode.GROUP_EXCLUDING_USER and target == user:
					continue
				targets.append(target)
			return targets
		_:
			return []


func _apply_effect_to_target(target: Node, request: Dictionary) -> void:
	if target == null:
		return

	var method: StringName = request.get("effect_method", &"")
	if not target.has_method(method):
		return

	var duration: float = request.get("duration", 0.0)
	var multiplier: float = request.get("multiplier", 1.0)

	if method == &"apply_slow":
		target.call(method, duration, multiplier)
	else:
		target.call(method, duration)
