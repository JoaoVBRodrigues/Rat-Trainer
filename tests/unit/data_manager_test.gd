extends GdUnitTestSuite

const DATA_MANAGER_SCRIPT: GDScript = preload("res://src/data/DataManager.gd")

var _test_save_dir: String


func after_test() -> void:
	for filename: String in [
		"slot_0.rat-save", "slot_1.rat-save", "slot_2.rat-save",
		"autosave.rat-save", "monthly_snapshot.rat-save",
		"settings.json", "settings.json.tmp", "settings.json.bak"
	]:
		var save_path: String = _test_save_dir.path_join(filename)
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
	assert_int(data.schema_version).is_equal(DATA_MANAGER_SCRIPT.CURRENT_SCHEMA_VERSION)
	assert_str(data.character.guardian_name).is_equal("ORAC")


func test_unversioned_save_migrates_and_keeps_source_file() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	var save_path: String = _test_save_dir.path_join("slot_1.rat-save")
	var legacy_data: Dictionary = {
		"character": {
			"name": "Nyx",
			"age": 12,
			"credits": 175,
			"stats": {"STR": 20, "INT": 15, "CHA": 15, "REF": 15, "STA": 20, "ETH": 50}
		},
		"progress": {"year": 1, "month": 2, "period": 2}
	}
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(JSON.stringify(legacy_data))
	file.close()

	# Act
	var loaded: bool = data_manager.load_slot(1)
	var migrated_data: Dictionary = data_manager.get_current_data()
	var original: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	var original_text: String = original.get_as_text()
	original.close()
	var original_json: JSON = JSON.new()
	assert_int(original_json.parse(original_text)).is_equal(OK)

	# Assert
	assert_bool(loaded).is_true()
	assert_int(migrated_data.schema_version).is_equal(DATA_MANAGER_SCRIPT.CURRENT_SCHEMA_VERSION)
	assert_str(migrated_data.character.guardian_name).is_equal("ORAC")
	assert_int(migrated_data.progress.turns_completed).is_equal(4)
	assert_bool(original_json.data.has("schema_version")).is_false()


func test_unversioned_simulation_calendar_migrates_completed_periods() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var calendar_state: Dictionary = simulation.calendar.get_calendar_state().to_dict()
	calendar_state["completed_periods"] = 7
	assert_bool(simulation.calendar.load_state(calendar_state)).is_true()
	var legacy_data: Dictionary = {
		"character": {"name": "Nyx"},
		"progress": {"year": 1, "month": 1, "period": 1},
		"simulation": simulation.get_state()
	}
	var save_path: String = _test_save_dir.path_join("slot_2.rat-save")
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(JSON.stringify(legacy_data))
	file.close()

	# Act
	var loaded: bool = data_manager.load_slot(2)
	var migrated_data: Dictionary = data_manager.get_current_data()

	# Assert
	assert_bool(loaded).is_true()
	assert_int(migrated_data.progress.turns_completed).is_equal(7)
	assert_bool(migrated_data.simulation.calendar.has("completed_periods")).is_false()
	assert_int(migrated_data.rng_state).is_equal(simulation.rng.state)


func test_settings_roundtrip_preserves_all_supported_values() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	data_manager.settings_path = _test_save_dir.path_join("settings.json")
	var settings: Dictionary = {
		"music_volume": 35,
		"sfx_volume": 80,
		"animation_speed": 150,
		"text_scale": 120
	}

	# Act
	var saved: bool = data_manager.save_settings(settings)
	var loaded_settings: Dictionary = data_manager.get_settings()

	# Assert
	assert_bool(saved).is_true()
	assert_bool(loaded_settings == settings).is_true()


func test_save_and_load_roundtrip_preserves_updated_progress() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	data_manager.initialize_new_save()
	var data: Dictionary = data_manager.get_current_data()
	data["progress"]["turns_completed"] = 5
	data["rng_state"] = -9007199254740993
	data_manager.set_data(data)

	# Act
	var saved: bool = data_manager.save_current(0)
	var loaded: bool = data_manager.load_slot(0)
	var loaded_data: Dictionary = data_manager.get_current_data()

	# Assert
	assert_bool(saved).is_true()
	assert_bool(loaded).is_true()
	assert_float(float(loaded_data["progress"]["turns_completed"])).is_equal(5.0)
	assert_int(loaded_data.rng_state).is_equal(-9007199254740993)


func test_save_load_restores_pending_event_and_exact_rng_state() -> void:
	# Arrange
	var data_manager: DataManager = _create_data_manager()
	data_manager.initialize_new_save()
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var calendar_state: Dictionary = simulation.calendar.get_calendar_state().to_dict()
	calendar_state["completed_periods"] = 8
	assert_bool(simulation.calendar.load_state(calendar_state)).is_true()
	simulation.rng.state = -9007199254740993
	var pending_result: PeriodResult = simulation.advance_period("leisure_descanso")
	assert_bool(pending_result.is_event_pending).is_true()
	assert_bool(data_manager.set_simulation_state(simulation.get_state())).is_true()
	assert_bool(data_manager.save_current(0)).is_true()

	# Act
	var loaded: bool = data_manager.load_slot(0)
	var saved_data: Dictionary = data_manager.get_current_data()
	var restored: SimulationCore = SimulationCore.new()
	assert_bool(restored.initialize()).is_true()
	var restored_state: Dictionary = saved_data.get("simulation", {}).duplicate(true)
	restored_state["calendar"]["completed_periods"] = saved_data.progress.turns_completed
	restored_state["rng_state"] = saved_data.rng_state
	var restored_successfully: bool = restored.load_state(restored_state)
	var event_option: String = "%s_a" % pending_result.event_id
	var original_result: PeriodResult = simulation.advance_period(event_option)
	var restored_result: PeriodResult = restored.advance_period(event_option)

	# Assert
	assert_bool(loaded).is_true()
	assert_int(saved_data.rng_state).is_equal(-9007199254740993)
	assert_bool(restored_successfully).is_true()
	assert_bool(original_result.completed).is_true()
	assert_bool(restored_result.completed).is_true()
	assert_bool(simulation.get_state() == restored.get_state()).is_true()


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