class_name MonthlyScheduleFlowTest
extends GdUnitTestSuite

var _test_save_dir: String


func after_test() -> void:
	for save_suffix: String in ["", ".tmp", ".bak"]:
		var save_path: String = _test_save_dir.path_join(
			"slot_0.rat-save%s" % save_suffix
		)
		if not FileAccess.file_exists(save_path):
			continue
		var remove_error: Error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(save_path)
		)
		assert_int(remove_error).is_equal(OK)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_test_save_dir)):
		var remove_dir_error: Error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(_test_save_dir)
		)
		assert_int(remove_dir_error).is_equal(OK)


func test_finish_execution_at_campaign_end_shows_and_persists_ending() -> void:
	# Arrange
	var main_screen: Control = auto_free(Control.new())
	add_child(main_screen)
	var flow: MonthlyScheduleFlow = auto_free(MonthlyScheduleFlow.new())
	add_child(flow)
	var data_manager: DataManager = _create_data_manager()
	data_manager.initialize_new_save()
	flow.bind_main_screen(main_screen)
	flow.set_data_manager(data_manager)

	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	simulation.completed_events.append("e12")
	simulation.calendar.completed_periods = simulation.calendar.total_periods
	flow.update_simulation(simulation)
	flow._initial_state = simulation.get_state()
	flow._draft = MonthSchedule.new()

	# Act
	flow._finish_execution()

	# Assert
	assert_bool(simulation.is_campaign_complete()).is_true()
	assert_object(flow._ending_screen).is_not_null()
	assert_bool(flow._ending_screen.visible).is_true()
	assert_str(flow._ending_screen._ending_id).is_equal("caminho_equilibrado")
	assert_array(data_manager.get_unlocked_endings()).contains("caminho_equilibrado")
	var progress: Dictionary = data_manager.get_current_data().get("progress", {})
	assert_str(str(progress.get("ending_id", ""))).is_equal("caminho_equilibrado")
	assert_bool(data_manager.save_current(0)).is_true()
	var reloaded_manager: DataManager = auto_free(DataManager.new())
	reloaded_manager.save_dir = _test_save_dir
	add_child(reloaded_manager)
	assert_bool(reloaded_manager.load_slot(0)).is_true()
	assert_array(reloaded_manager.get_unlocked_endings()).contains("caminho_equilibrado")
	var saved_progress: Dictionary = reloaded_manager.get_current_data().get("progress", {})
	assert_str(str(saved_progress.get("ending_id", ""))).is_equal("caminho_equilibrado")


func _create_data_manager() -> DataManager:
	_test_save_dir = "user://gdunit_ending_flow_%d" % Time.get_ticks_usec()
	var data_manager: DataManager = auto_free(DataManager.new())
	data_manager.save_dir = _test_save_dir
	add_child(data_manager)
	return data_manager
