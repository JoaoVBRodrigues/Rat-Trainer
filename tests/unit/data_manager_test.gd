extends GdUnitTestSuite

const DATA_MANAGER_SCRIPT: GDScript = preload("res://src/data/DataManager.gd")

var _test_save_dir: String


func after_test() -> void:
	for slot in range(DATA_MANAGER_SCRIPT.SAVE_SLOT_COUNT):
		var save_path: String = _test_save_dir.path_join(
			"slot_%d%s" % [slot, DATA_MANAGER_SCRIPT.SAVE_EXTENSION]
		)
		if FileAccess.file_exists(save_path):
			var remove_error: Error = DirAccess.remove_absolute(
				ProjectSettings.globalize_path(save_path)
			)
			assert_int(remove_error).is_equal(OK)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_test_save_dir)):
		var remove_dir_error: Error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(_test_save_dir)
		)
		assert_int(remove_dir_error).is_equal(OK)


func test_initialize_new_save_uses_mvp_character_values() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()

	# Act
	data_manager.initialize_new_save()
	var data: Dictionary = data_manager.get_current_data()

	# Assert
	assert_bool(data.has("character")).is_true()
	assert_bool(data.has("progress")).is_true()
	assert_bool(data.character.has("stats")).is_true()
	assert_int(data.character.age).is_equal(12)
	assert_int(data.character.credits).is_equal(200)
	assert_int(data.character.stats.STR).is_equal(15)
	assert_int(data.character.stats.INT).is_equal(15)
	assert_int(data.character.stats.CHA).is_equal(15)
	assert_int(data.character.stats.REF).is_equal(15)
	assert_int(data.character.stats.STA).is_equal(20)
	assert_int(data.character.stats.ETH).is_equal(50)


func test_save_and_load_roundtrip_preserves_updated_progress() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	data_manager.initialize_new_save()
	var data: Dictionary = data_manager.get_current_data()
	data["progress"]["turns_completed"] = 5
	data_manager.set_data(data)

	# Act
	var saved: bool = data_manager.save_current(0)
	var loaded: bool = data_manager.load_slot(0)
	var loaded_data: Dictionary = data_manager.get_current_data()

	# Assert
	assert_bool(saved).is_true()
	assert_bool(loaded).is_true()
	assert_float(float(loaded_data["progress"]["turns_completed"])).is_equal(5.0)


func test_save_slots_returns_only_occupied_slots() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	data_manager.initialize_new_save()
	var saved: bool = data_manager.save_current(0)
	assert_bool(saved).is_true()

	# Act
	var slots: Array[int] = data_manager.get_save_slots()

	# Assert
	assert_array(slots).contains_exactly(0)


func _create_data_manager() -> DataManager:
	_test_save_dir = "user://gdunit_data_manager_%d" % Time.get_ticks_usec()
	var data_manager: DataManager = auto_free(DATA_MANAGER_SCRIPT.new())
	data_manager.save_dir = _test_save_dir
	add_child(data_manager)
	return data_manager