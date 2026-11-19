extends GdUnitTestSuite

var _save_dir: String
var _data: Dictionary
var _test_save_dir: String

func before_test() -> void:
	_save_dir = Data.save_dir
	_data = Data.get_current_data()
	_test_save_dir = "res://reports/playable_ui_%d" % Time.get_ticks_usec()
	Data.save_dir = _test_save_dir
	Data.initialize_new_save()

func after_test() -> void:
	Data.save_dir = _save_dir
	Data.set_data(_data)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_test_save_dir)):
		for filename: String in DirAccess.get_files_at(_test_save_dir):
			assert_int(DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_save_dir.path_join(filename)))).is_equal(OK)
		assert_int(DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_save_dir))).is_equal(OK)

func campaign() -> MainScreen:
	var host: Control = auto_free(Control.new())
	host.size = Vector2(1024, 768)
	add_child(host)
	var screen: MainScreen = MainScreen.new()
	host.add_child(screen)
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()
	sim.set_seed(456)
	screen.update_simulation(sim, {"name": "Nyx Volt", "guardian_name": "ORAC"})
	return screen

func settle() -> void:
	for frame: int in range(5):
		await get_tree().process_frame

func test_profile_and_talk_buttons_open_closable_screens() -> void:
	var screen: MainScreen = campaign()
	for destination: String in ["perfil", "falar"]:
		var button: Button = screen.find_child("Menu_" + destination, true, false) as Button
		button.pressed.emit()
		await settle()
		var modal: Control = screen.find_child("ProfileScreen" if destination == "perfil" else "TalkScreen", true, false) as Control
		assert_object(modal).is_not_null()
		if modal == null:
			continue
		assert_bool(modal.visible).is_true()
		var close: Button = modal.find_child("CloseButton", true, false) as Button
		assert_object(close).is_not_null()
		if close != null:
			close.pressed.emit()
			assert_bool(modal.visible).is_false()

func test_second_month_starts_at_first_editable_period() -> void:
	var screen: MainScreen = campaign()
	var flow: MonthlyScheduleFlow = screen._schedule_flow
	flow.on_schedule_requested("agenda")
	var choices: Dictionary = flow._build_activity_choices()
	var draft: MonthSchedule = MonthSchedule.new()
	# Use an actual catalog leisure ID, independently of localized names.
	var rest_id: String = str(choices["leisure"][0]["id"])
	for index: int in range(3):
		draft.set_selection(index, MonthSchedule.ActivityPeriod.LEISURE, rest_id, 1, 0, true)
	flow._on_schedule_confirmed(draft)
	for index: int in range(3):
		flow._result_screen._continue_button.pressed.emit()
	flow._on_summary_finished()
	assert_int(screen.simulation.calendar.completed_periods).is_equal(3)
	flow.on_schedule_requested("agenda")
	assert_int(flow._next_period_index).is_equal(0)
	for index: int in range(3):
		assert_bool(flow._schedule_screen._period_buttons[index].disabled).is_false()
	flow._on_schedule_confirmed(draft)
	assert_bool(flow._result_screen.visible).is_true()
	assert_bool(flow._schedule_screen.visible).is_false()
	assert_int(screen.simulation.calendar.completed_periods).is_equal(4)

func test_result_contains_art_and_keeps_continue_inside_viewport() -> void:
	var screen: MainScreen = campaign()
	var result: PeriodResult = screen.simulation.advance_period("work_trabalho_reparo_leve_l1")
	var presentation: ActivityResultScreen = ActivityResultScreen.new()
	screen.add_child(presentation)
	presentation.show_result(result, screen.simulation)
	await settle()
	var art: TextureRect = presentation.find_child("ActivityArtwork", true, false) as TextureRect
	assert_object(art).is_not_null()
	if art != null:
		assert_object(art.texture).is_not_null()
		assert_bool(art.size.x > 300).is_true()
	assert_bool(presentation._continue_button.get_global_rect().end.y <= 768).is_true()
	assert_bool(presentation._continue_button.get_global_rect().end.x <= 1024).is_true()

func test_title_panel_is_centered_inside_viewport() -> void:
	var host: Control = auto_free(Control.new())
	host.size = Vector2(1024, 768)
	add_child(host)
	var title: TitleScreen = TitleScreen.new()
	host.add_child(title)
	await settle()
	var panel: Control = title.find_child("TitlePanel", true, false) as Control
	assert_bool(panel.get_global_rect().end.x <= 1024).is_true()
	assert_bool(panel.get_global_rect().end.y <= 768).is_true()

func test_compact_stat_labels_have_readable_width() -> void:
	var screen: MainScreen = campaign()
	await settle()
	var body: VBoxContainer = screen._status_panel._body
	var row: HBoxContainer = body.get_child(1) as HBoxContainer
	assert_object(row).is_not_null()
	if row != null:
		var label: Label = row.get_child(0) as Label
		assert_bool(label.size.x >= 90).is_true()
		assert_bool(label.size.y >= 14).is_true()

func test_loading_pending_encounter_opens_choices_instead_of_planning() -> void:
	var screen: MainScreen = campaign()
	var pending: PeriodResult = screen.simulation.advance_period("mission_missao_fisica_ruinas")
	assert_bool(screen.simulation.has_pending_encounter()).is_true()
	screen._schedule_flow.resume_saved_flow({})
	var encounter: EncounterScreen = screen.find_child("EncounterScreen", true, false) as EncounterScreen
	assert_object(encounter).is_not_null()
	if encounter != null:
		assert_bool(encounter.visible).is_true()
	if screen._schedule_flow._schedule_screen != null:
		assert_bool(screen._schedule_flow._schedule_screen.visible).is_false()

func test_failed_autosave_can_retry_without_replaying_completed_period() -> void:
	var screen: MainScreen = campaign()
	var flow: MonthlyScheduleFlow = screen._schedule_flow
	flow.on_schedule_requested("agenda")
	var rest: String = str(flow._build_activity_choices()["leisure"][0]["id"])
	var draft: MonthSchedule = MonthSchedule.new()
	for index: int in range(3):
		draft.set_selection(index, MonthSchedule.ActivityPeriod.LEISURE, rest, 1, 0, true)
	var valid_dir: String = Data.save_dir
	# An existing file cannot be used as a save directory; no source file is altered.
	Data.save_dir = "res://project.godot/invalid_save_directory"
	flow._on_schedule_confirmed(draft)
	assert_int(screen.simulation.calendar.completed_periods).is_equal(1)
	assert_bool(flow._result_screen.visible).is_true()
	Data.save_dir = valid_dir
	if flow._result_screen.visible:
		flow._result_screen._continue_button.pressed.emit()
		assert_int(screen.simulation.calendar.completed_periods).is_equal(2)
		assert_bool(flow._result_screen.visible).is_true()

func test_month_summary_displays_actual_attribute_values_and_deltas() -> void:
	var screen: MainScreen = campaign()
	var before: Dictionary = screen.simulation.get_state()
	var result: PeriodResult = screen.simulation.advance_period("study_curso_tecnologia_l1")
	assert_bool(result.completed).is_true()
	var after: Dictionary = screen.simulation.get_state()
	var report: Dictionary = screen._schedule_flow._build_report(before, after)
	assert_int(report["stat_deltas"]["int"]).is_equal(12)
	var summary: MonthSummaryScreen = MonthSummaryScreen.new()
	screen.add_child(summary)
	summary.display_month_summary(before, after)
	var intelligence_row: HBoxContainer = summary._attributes_container.get_child(1) as HBoxContainer
	assert_str((intelligence_row.get_child(1) as Label).text).is_equal("+12")
	assert_str((intelligence_row.get_child(2) as Label).text).is_equal("27")

func test_recovery_item_refreshes_mission_availability_and_character_art() -> void:
	var screen: MainScreen = campaign()
	screen.simulation.stats.add_stress(70)
	screen.simulation.stats.check_and_update_disease()
	assert_bool(screen.simulation.buy_item("adesivo_recuperacao")["success"]).is_true()
	screen.update_simulation(screen.simulation)
	assert_bool(screen._menu_buttons[5].disabled).is_true()
	screen._on_menu_pressed("equipamento")
	screen._item_management_screen._on_item_action("adesivo_recuperacao", "use", "")
	screen._item_management_screen._on_close_pressed()
	assert_bool(screen.simulation.stats.is_diseased).is_false()
	assert_bool(screen._menu_buttons[5].disabled).is_false()
	var character: TextureRect = screen.get_node("CharacterVisual") as TextureRect
	assert_bool(character.texture.resource_path.ends_with("_sick.png")).is_false()

func test_legacy_status_script_remains_loadable_by_the_editor() -> void:
	var script: GDScript = load("res://src/ui/widgets/StatusScreen.gd") as GDScript
	assert_bool(script.can_instantiate()).is_true()

func test_event_remains_answerable_when_its_checkpoint_cannot_be_saved() -> void:
	var screen: MainScreen = campaign()
	screen.simulation.calendar.completed_periods = 8
	screen.simulation.calendar.month = 3
	screen.simulation.calendar.period = 3
	screen.simulation.calendar.turn_number = 9
	var flow: MonthlyScheduleFlow = screen._schedule_flow
	flow._draft = MonthSchedule.new()
	flow._draft.set_selection(2, MonthSchedule.ActivityPeriod.LEISURE, "descanso", 1, 0, true)
	flow._next_period_index = 2
	flow._ensure_screens()
	var valid_dir: String = Data.save_dir
	Data.save_dir = "res://project.godot/invalid_save_directory"
	flow._resolve_next_period()
	assert_bool(screen.simulation.has_pending_event()).is_true()
	assert_bool(flow._event_choice_screen.visible).is_true()
	Data.save_dir = valid_dir
	if flow._event_choice_screen.visible:
		(flow._event_choice_screen._options_container.get_child(0) as Button).pressed.emit()
		assert_int(screen.simulation.calendar.completed_periods).is_equal(9)
		assert_bool(flow._result_screen.visible).is_true()
