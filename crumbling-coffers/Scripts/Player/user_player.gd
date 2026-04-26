# 	Does not have multiplayer support yet;
#	Need to differentiate between client player	
#	and other connected players in same room 

extends ControllablePlayer
class_name UserPlayer

# Inventory and hotbar variables for "collect" and "hotbar_collect" functions.
@export var inventory: Inventory
@export var itemRes: InventoryItem
@export var hotbar: Hotbar
@export var hotbar_itemRes: HotbarItem

#Daniel - adding a score to the character for when they pick up the items.

signal score_changed(new_score: int)
signal item_picked_up(item_instance_id: int)

var score: int = 0

var player_id: String	# This value should be populated by another class/function (Game class?) at this player's creation in online play


func _ready() -> void:
	# Connect signal to func reset_inv_hotbar so is called when the signal is emitted.
	MatchManager.match_ended.connect(reset_inv_hotbar)
	reset_inv_hotbar()
	if camera:
		camera.make_current()
	add_to_group("freezable")
	add_to_group("player")
	add_to_group("disorientable")
	add_to_group("slowable")

func add_score(amount: int) -> void:
	score += amount
	emit_signal("score_changed", score)
# Daniel - ending here

func _physics_process(delta: float) -> void:
	# Get inputs
	if not is_frozen:
		input_direction = Input.get_axis("left", "right")
		jump_pressed = Input.is_action_pressed("jump")
		down_pressed = Input.is_action_pressed("down")		# But, that is best saved for a refactor, and ONLY IF its needed.
		jump_tapped = Input.is_action_just_pressed("jump")	# this jump_tapped is technically unnecessary (only an intermediate for getting autojump_window)
		dash_pressed = Input.is_action_pressed("dash")		# in any case, i would like to keep it because this seems useful to track 
	
	super(delta)

###

func collect(itemRes):
	receive_inventory_item(itemRes)

func receive_inventory_item(item: InventoryItem) -> bool:
	if inventory == null or item == null:
		return false
	inventory.insert(item)
	return true

func consumable_collect(hotbar_itemRes):
	receive_hotbar_item(hotbar_itemRes)

func receive_hotbar_item(item: HotbarItem) -> bool:
	if hotbar == null or item == null:
		return false
	return hotbar.hotbar_insert(item)
	
func can_receive_inventory_item(item: InventoryItem) -> bool:
	if inventory == null or item == null:
		return false

	for slot in inventory.slots:
		if slot.item == item:
			return true
		if slot.item == null:
			return true

	return false

func can_receive_hotbar_item(item: HotbarItem) -> bool:
	if hotbar == null or item == null:
		return false

	for slot in hotbar.hotbar_slots:
		if slot.hotbar_item == item:
			return true
		if slot.hotbar_item == null:
			return true

	return false

func use_hotbar_item(index: int) -> bool:
	if hotbar == null:
		return false
	return hotbar.use_item(index, get_tree(), self)
	
func receive_pickup(pickup: ItemPickup) -> bool:
	if pickup.has_meta("item_instance_id"):
		emit_signal("item_picked_up", pickup.get_meta("item_instance_id"))
		return true
	return pickup.apply_to_player(self)
# Implementing call reset functions for inventory and hotbar when a match ends.
func reset_inv_hotbar():
	inventory.reset_inv()
	hotbar.reset_hotbar()
