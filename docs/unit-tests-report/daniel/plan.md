# Unit Testing Plan - Daniel

## Feature Being Tested

The unit tests will focus on the item and hotbar systems, specifically the recently refactored logic that supports multiplayer-friendly item usage.

The tested code includes:

- `hotbar.gd`
- `hotbar_item.gd`
- `hotbar_slot.gd`

## Test Framework

The tests will be implemented using the GUT (Godot Unit Testing) framework.

---

## Test 1: Hotbar Insert Adds Item Successfully

### Code Tested
`Hotbar.hotbar_insert(item: HotbarItem) -> bool`

### Purpose
Verify that inserting an item into the hotbar works correctly and returns a success value.

### Fields Used
- `hotbar_slots`
- `hotbar_item`
- `amount`

### Expected Result
- Method returns `true`
- Slot contains the inserted item
- Slot amount is `1`

---

## Test 2: Hotbar Item Builds Correct Use Request

### Code Tested
`HotbarItem.build_use_request(user: Node = null) -> Dictionary`

### Purpose
Verify that item usage is correctly represented as a request object.

### Fields Used
- `item_id`
- `effect_method`
- `target_group`
- `target_mode`
- `duration`
- `multiplier`
- `consumed_on_use`

### Expected Result
The returned dictionary contains correct values for all fields.

---

## Test 3: Hotbar Use Consumes Item

### Code Tested
`Hotbar.use_item(...) -> bool`

### Purpose
Verify that using an item properly reduces or clears the hotbar slot.

### Fields Used
- `hotbar_slots`
- `hotbar_item`
- `amount`
- `consumed_on_use`

### Expected Result
- Method returns `true`
- Slot amount decreases
- Slot clears when amount reaches 0

---

## Justification

These tests validate core item system behavior:

1. Items can be added to the hotbar
2. Items correctly describe their behavior through a request object
3. Items are consumed correctly after use

These behaviors are critical for both current gameplay and future multiplayer support.