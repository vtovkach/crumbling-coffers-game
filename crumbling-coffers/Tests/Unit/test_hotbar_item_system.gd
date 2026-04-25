extends GutTest

func test_hotbar_insert_adds_item_successfully():
	var hotbar := Hotbar.new()
	var slot := HotbarSlot.new()
	var item := HotbarItem.new()

	hotbar.hotbar_slots = [slot]

	var result := hotbar.hotbar_insert(item)

	assert_true(result)
	assert_eq(hotbar.hotbar_slots[0].hotbar_item, item)
	assert_eq(hotbar.hotbar_slots[0].amount, 1)


func test_hotbar_item_builds_use_request():
	var item := HotbarItem.new()
	item.name = "Test Freeze Staff"
	item.item_id = "test_freeze_staff"
	item.effect_method = &"apply_freeze"
	item.target_group = &"freezable"
	item.target_mode = HotbarItem.TargetMode.GROUP_EXCLUDING_USER
	item.duration = 5.0
	item.multiplier = 1.0
	item.consumed_on_use = true

	var request := item.build_use_request(null)

	assert_eq(request["item_id"], "test_freeze_staff")
	assert_eq(request["item_name"], "Test Freeze Staff")
	assert_eq(request["effect_method"], &"apply_freeze")
	assert_eq(request["target_group"], &"freezable")
	assert_eq(request["target_mode"], HotbarItem.TargetMode.GROUP_EXCLUDING_USER)
	assert_eq(request["duration"], 5.0)
	assert_eq(request["multiplier"], 1.0)
	assert_true(request["consumed_on_use"])


func test_hotbar_use_consumes_item():
	var hotbar := Hotbar.new()
	var slot := HotbarSlot.new()
	var item := HotbarItem.new()

	item.item_id = "test_freeze_staff"
	item.effect_method = &"apply_freeze"
	item.target_group = &"freezable"
	item.target_mode = HotbarItem.TargetMode.GROUP_EXCLUDING_USER
	item.duration = 5.0
	item.multiplier = 1.0
	item.consumed_on_use = true

	hotbar.hotbar_slots = [slot]
	hotbar.hotbar_insert(item)

	var result := hotbar.use_item(0, null, null, false)

	assert_true(result)
	assert_null(hotbar.hotbar_slots[0].hotbar_item)
	assert_eq(hotbar.hotbar_slots[0].amount, 0)
