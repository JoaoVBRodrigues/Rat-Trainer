extends GUTTestSuite

## Tests for DataManager.gd JSON persistence
## Verifies save/load functionality

func test_initialize_new_save_creates_valid_structure() -> void:
	# Arrange
	var data_manager: Object = preload("res://src/data/DataManager.gd").new()
	add_child(data_manager)

	# Act
	data_manager.initialize_new_save()
	var data: Dictionary = data_manager.get_current_data()

	# Assert
	assert_true(data.has("character"), "Save must have 'character' section")
	assert_true(data.has("progress"), "Save must have 'progress' section")
	assert_true(data.has("stats"), "Save should include stats in character")

	assert_int(data.character.age).is_equal(12, "Initial age should be 12")
	assert_int(data.character.credits).is_equal(200, "Initial credits should be stipend")

	data_manager.queue_free()

func test_save_and_load_roundtrip() -> void:
	# Arrange
	var data_manager: Object = preload("res://src/data/DataManager.gd").new()
	add_child(data_manager)

	data_manager.initialize_new_save()
	data_manager.get_current_data()["progress"]["turns_completed"] = 5

	# Act
	data_manager.save_current(0)

	var loaded: bool = data_manager.load_slot(0)
	assert_bool(loaded).is_true("Load should succeed")

	var data: Dictionary = data_manager.get_current_data()

	# Assert
	assert_int(data.progress.turns_completed).is_equal(5, "Saved progress must match")

	# Cleanup
	DirAccess.remove_absolute("user://saves/slot_0.rat-save")
	data_manager.queue_free()

func test_save_slots_returns_occupied_list() -> void:
	# Arrange
	var data_manager: Object = preload("res://src/data/DataManager.gd").new()
	add_child(data_manager)
	data_manager.save_current(0)

	# Act
	var slots: Array = data_manager.get_save_slots()

	# Assert
	assert_int(slots.size()).is_equal(1, "Should have 1 occupied slot")
	assert_int(slots[0]).is_equal(0, "Slot 0 should be occupied")

	# Cleanup
	DirAccess.remove_absolute("user://saves/slot_0.rat-save")
	data_manager.queue_free()