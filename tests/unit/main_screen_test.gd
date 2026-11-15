extends GdUnitTestSuite

var _previous_save_dir: String
var _test_save_dir: String
var _previous_simulation: SimulationCore
var _previous_game_state: GameManager.GameState
var _previous_data: Dictionary


func before_test() -> void:
	var game_manager: GameManager = get_node("/root/Game") as GameManager
	_previous_save_dir = Data.save_dir
	_previous_simulation = game_manager.simulation
	_previous_game_state = game_manager.current_state
	_previous_data = Data.get_current_data()
	_test_save_dir = "user://gdunit_main_screen_%d" % Time.get_ticks_usec()
	Data.save_dir = _test_save_dir


func after_test() -> void:
	var game_manager: GameManager = get_node("/root/Game") as GameManager
	Data.save_dir = _previous_save_dir
	Data.set_data(_previous_data)
	game_manager.simulation = _previous_simulation
	game_manager.transition_to(_previous_game_state)
	for save_name: String in [
		"slot_0.rat-save", "slot_1.rat-save", "slot_2.rat-save",
		"autosave.rat-save", "monthly_snapshot.rat-save"
	]:
		for suffix: String in ["", ".tmp", ".bak"]:
			var save_path: String = _test_save_dir.path_join(save_name + suffix)
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


func test_main_screen_builds_six_focusable_destinations() -> void:
	# Arrange
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)

	# Assert
	assert_int(screen.get_menu_button_count()).is_equal(6)
	for button: Button in screen._menu_buttons:
		assert_int(button.focus_mode).is_equal(Control.FOCUS_ALL)


func test_new_campaign_button_is_visible_without_active_campaign() -> void:
	# Arrange
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)

	# Assert
	var new_campaign_button: Button = screen.find_child(
		"NewCampaignButton", true, false
	) as Button
	assert_object(new_campaign_button).is_not_null()
	assert_bool(new_campaign_button.visible).is_true()
	assert_bool(screen._menu_buttons[5].disabled).is_true()
	assert_bool(screen._schedule_button.disabled).is_true()


func test_mission_menu_opens_schedule_with_missions_visible() -> void:
	# Arrange
	var game_manager: GameManager = get_node("/root/Game") as GameManager
	var previous_simulation: SimulationCore = game_manager.simulation
	var previous_state: GameManager.GameState = game_manager.current_state
	var previous_data: Dictionary = Data.get_current_data()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	var new_campaign_button: Button = screen.find_child(
		"NewCampaignButton", true, false
	) as Button

	# Act
	new_campaign_button.pressed.emit()
	screen._on_menu_pressed("missao")

	# Assert
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	assert_object(schedule_screen).is_not_null()
	assert_bool(schedule_screen.visible).is_true()
	assert_str(schedule_screen._active_category).is_equal("mission")
	var mission_cards: VBoxContainer = schedule_screen._selection_host._cards
	assert_int(mission_cards.get_child_count()).is_equal(5)
	var ruins_card: Button = mission_cards.get_node_or_null(
		"Card_missao_fisica_ruinas"
	) as Button
	var drones_card: Button = mission_cards.get_node_or_null(
		"Card_missao_fisica_drones"
	) as Button
	var infiltration_card: Button = mission_cards.get_node_or_null(
		"Card_missao_fisica_infiltracao"
	) as Button
	assert_object(ruins_card).is_not_null()
	assert_object(drones_card).is_not_null()
	assert_object(infiltration_card).is_not_null()
	assert_bool(ruins_card.disabled).is_false()
	assert_bool(drones_card.disabled).is_true()
	assert_bool(infiltration_card.disabled).is_true()
	assert_str(ruins_card.text).contains("Ruínas Industriais")

	game_manager.simulation = previous_simulation
	game_manager.transition_to(previous_state)
	Data.set_data(previous_data)


func test_physical_mission_opens_encounter_screen_with_four_choices() -> void:
	# Arrange
	var game_manager: GameManager = get_node("/root/Game") as GameManager
	var previous_simulation: SimulationCore = game_manager.simulation
	var previous_state: GameManager.GameState = game_manager.current_state
	var previous_data: Dictionary = Data.get_current_data()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	var new_campaign_button: Button = screen.find_child(
		"NewCampaignButton", true, false
	) as Button
	new_campaign_button.pressed.emit()
	var simulation: SimulationCore = game_manager.simulation
	var encounter_seed: int = 0
	for seed_value: int in range(1, 1001):
		simulation.start_new_game()
		simulation.set_seed(seed_value)
		var result: PeriodResult = simulation.advance_period(
			"mission_missao_fisica_ruinas", seed_value
		)
		if result.is_encounter_pending:
			encounter_seed = seed_value
			break
	assert_int(encounter_seed).is_greater(0)
	simulation.start_new_game()
	simulation.set_seed(encounter_seed)
	screen.update_simulation(simulation)

	# Act
	screen._on_menu_pressed("missao")
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	var choices_by_category: Dictionary = screen._schedule_flow._build_activity_choices()
	var mission_choice: Dictionary = (
		choices_by_category["mission"][0].duplicate(true)
	)
	mission_choice["period_index"] = 0
	schedule_screen._on_activity_selected(mission_choice)
	var leisure_choice: Dictionary = choices_by_category["leisure"][0].duplicate(true)
	leisure_choice["period_index"] = 1
	schedule_screen._on_activity_selected(leisure_choice)
	leisure_choice["period_index"] = 2
	schedule_screen._on_activity_selected(leisure_choice)
	schedule_screen._on_confirm_pressed()

	# Assert
	var encounter_screen: EncounterScreen = screen.find_child(
		"EncounterScreen", true, false
	) as EncounterScreen
	assert_object(encounter_screen).is_not_null()
	assert_bool(encounter_screen.visible).is_true()
	assert_str(encounter_screen._monster_label.text).is_not_empty()
	assert_int(encounter_screen._options_container.get_child_count()).is_equal(4)
	assert_str(
		(encounter_screen._options_container.get_child(0) as Button).text
	).is_equal("Lutar")
	assert_str(
		(encounter_screen._options_container.get_child(1) as Button).text
	).is_equal("Conversar")
	assert_str(
		(encounter_screen._options_container.get_child(2) as Button).text
	).is_equal("Fugir")
	assert_str(
		(encounter_screen._options_container.get_child(3) as Button).text
	).is_equal("Esconder")

	game_manager.simulation = previous_simulation
	game_manager.transition_to(previous_state)
	Data.set_data(previous_data)


func test_schedule_request_does_not_advance_simulation() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	var requested_sources: Array[String] = []
	screen.schedule_requested.connect(
		func(source: String) -> void: requested_sources.append(source)
	)
	var completed_periods: int = simulation.calendar.completed_periods

	# Act
	screen._on_schedule_pressed()

	# Assert
	assert_array(requested_sources).contains_exactly(["primary"])
	assert_int(simulation.calendar.completed_periods).is_equal(completed_periods)
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	assert_bool(schedule_screen != null).is_true()
	assert_bool(schedule_screen._repeat_button.visible).is_false()
	assert_bool(schedule_screen.visible).is_true()


func test_agenda_and_primary_schedule_request_share_the_same_flow() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	var completed_periods: int = simulation.calendar.completed_periods

	# Act
	screen._on_menu_pressed("agenda")
	var agenda_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	screen._schedule_flow._close_flow()
	screen._on_schedule_pressed()
	var primary_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen

	# Assert
	assert_object(agenda_screen).is_same(primary_screen)
	assert_bool(primary_screen.visible).is_true()
	assert_int(simulation.calendar.completed_periods).is_equal(completed_periods)


func test_schedule_ui_resolves_three_results_then_returns_to_main_screen() -> void:
	# Arrange
	Data.initialize_new_save()
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	simulation.set_seed(456)
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	screen._on_schedule_pressed()
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	var flow: MonthlyScheduleFlow = screen.get_node("MonthlyScheduleFlow") as MonthlyScheduleFlow
	var choices_by_category: Dictionary = flow._build_activity_choices()

	# Act — choose two work periods and one leisure period through the screen draft.
	var work_choice: Dictionary = choices_by_category.get("work", [])[0].duplicate(true)
	work_choice["period_index"] = 0
	schedule_screen._on_activity_selected(work_choice)
	work_choice["period_index"] = 1
	schedule_screen._on_activity_selected(work_choice)
	var leisure_choice: Dictionary = choices_by_category.get("leisure", [])[0].duplicate(true)
	leisure_choice["period_index"] = 2
	schedule_screen._on_activity_selected(leisure_choice)
	schedule_screen._on_confirm_pressed()

	# Assert — every state update precedes its result, and summary returns to the hub.
	var result_screen: ActivityResultScreen = screen.find_child(
		"ActivityResultScreen", true, false
	) as ActivityResultScreen
	assert_bool(result_screen.visible).is_true()
	var activity_placeholder: Label = result_screen.find_child(
		"ActivityPlaceholderLabel", true, false
	) as Label
	assert_str(activity_placeholder.text).is_equal(result_screen._title_label.text)
	assert_int(simulation.calendar.completed_periods).is_equal(1)
	result_screen._on_continue_pressed()
	assert_int(simulation.calendar.completed_periods).is_equal(2)
	result_screen._on_continue_pressed()
	assert_int(simulation.calendar.completed_periods).is_equal(3)
	result_screen._on_continue_pressed()
	var summary_screen: MonthSummaryScreen = screen.find_child(
		"MonthSummaryScreen", true, false
	) as MonthSummaryScreen
	assert_bool(summary_screen.visible).is_true()
	summary_screen._on_finish_pressed()
	assert_bool(summary_screen.visible).is_false()
	assert_int(simulation.calendar.completed_periods).is_equal(3)

	# Repeat appears only after this in-memory campaign has completed its first month.
	screen._on_schedule_pressed()
	assert_bool(schedule_screen._repeat_button.visible).is_true()
	var state_before_repeat: Dictionary = simulation.get_state()
	var periods_before_repeat: int = simulation.calendar.completed_periods
	schedule_screen._on_repeat_pressed()
	assert_str(schedule_screen.get_draft().get_selection(0).get("activity_id", "")).is_equal(
		str(choices_by_category.get("work", [])[0].get("id", ""))
	)
	assert_bool(schedule_screen.get_draft().is_month_selected()).is_true()
	assert_int(simulation.calendar.completed_periods).is_equal(periods_before_repeat)
	assert_bool(simulation.get_state() == state_before_repeat).is_true()


func test_selecting_activity_restores_focus_to_same_card_after_refresh() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	screen._on_schedule_pressed()
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	var selection: ActivitySelection = schedule_screen._selection_host
	var first_card: Button = selection._cards.get_child(0) as Button
	var selected_card_name: String = first_card.name

	# Act
	first_card.grab_focus()
	first_card.pressed.emit()
	await get_tree().process_frame

	# Assert
	var refreshed_card: Button = selection._cards.get_node(selected_card_name) as Button
	assert_bool(refreshed_card.has_focus()).is_true()


func test_recovery_focuses_first_editable_period() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	screen._on_schedule_pressed()
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	var flow: MonthlyScheduleFlow = screen.get_node("MonthlyScheduleFlow") as MonthlyScheduleFlow
	var choices_by_category: Dictionary = flow._build_activity_choices()

	# Act
	schedule_screen.open_schedule(
		simulation,
		MonthSchedule.new(),
		null,
		choices_by_category,
		"error",
		1,
		true,
		1
	)
	await get_tree().process_frame

	# Assert
	assert_bool(schedule_screen._period_buttons[0].disabled).is_true()
	assert_bool(schedule_screen._period_buttons[1].has_focus()).is_true()


func test_blocked_recovery_disables_unsafe_controls() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	screen._on_schedule_pressed()
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	var flow: MonthlyScheduleFlow = screen.get_node("MonthlyScheduleFlow") as MonthlyScheduleFlow

	# Act
	schedule_screen.open_schedule(
		simulation,
		MonthSchedule.new(),
		null,
		flow._build_activity_choices(),
		"blocked_recovery",
		0,
		false,
		0,
		true
	)

	# Assert
	assert_str(schedule_screen._status_label.text).is_equal(
		Localization.text("ui.indisponivel")
	)
	assert_bool(schedule_screen._confirm_button.disabled).is_true()
	assert_bool(schedule_screen._cancel_button.disabled).is_true()
	assert_bool(schedule_screen._repeat_button.disabled).is_true()
	for period_button: Button in schedule_screen._period_buttons:
		assert_bool(period_button.disabled).is_true()
	for category_button: Button in schedule_screen._category_buttons.values():
		assert_bool((category_button as Button).disabled).is_true()


func test_cancelled_planning_leaves_campaign_state_unchanged() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	var state_before: Dictionary = simulation.get_state()

	# Act
	screen._on_schedule_pressed()
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	schedule_screen._on_cancel_pressed()

	# Assert
	assert_bool(schedule_screen.visible).is_false()
	assert_int(simulation.calendar.completed_periods).is_equal(0)
	assert_int(simulation.economy.get_credits()).is_equal(
		int(state_before.get("economy", {}).get("credits", 0))
	)


func test_disease_invalidating_pending_mission_preserves_resolved_periods() -> void:
	# Arrange
	Data.initialize_new_save()
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	simulation.set_seed(456)
	simulation.stats.set_stress(64)
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	screen._on_schedule_pressed()
	var schedule_screen: ScheduleScreen = screen.find_child(
		"MonthlyScheduleScreen", true, false
	) as ScheduleScreen
	var flow: MonthlyScheduleFlow = screen.get_node("MonthlyScheduleFlow") as MonthlyScheduleFlow
	var choices_by_category: Dictionary = flow._build_activity_choices()

	# Act — two work periods raise Stress enough to invalidate the planned mission.
	var work_choice: Dictionary = choices_by_category.get("work", [])[0].duplicate(true)
	work_choice["period_index"] = 0
	schedule_screen._on_activity_selected(work_choice)
	work_choice["period_index"] = 1
	schedule_screen._on_activity_selected(work_choice)
	var mission_choice: Dictionary = choices_by_category.get("mission", [])[0].duplicate(true)
	mission_choice["period_index"] = 2
	schedule_screen._on_activity_selected(mission_choice)
	schedule_screen._on_confirm_pressed()
	var result_screen: ActivityResultScreen = screen.find_child(
		"ActivityResultScreen", true, false
	) as ActivityResultScreen
	result_screen._on_continue_pressed()
	result_screen._on_continue_pressed()

	# Assert — the unresolved slot can be replaced without replaying either prior period.
	assert_int(simulation.calendar.completed_periods).is_equal(2)
	assert_int(flow._results.size()).is_equal(2)
	assert_bool(schedule_screen.visible).is_true()
	var leisure_choice: Dictionary = choices_by_category.get("leisure", [])[0].duplicate(true)
	leisure_choice["period_index"] = 2
	schedule_screen._on_activity_selected(leisure_choice)
	schedule_screen._on_confirm_pressed()
	assert_int(simulation.calendar.completed_periods).is_equal(3)
	assert_int(flow._results.size()).is_equal(3)
	assert_int(flow._next_period_index).is_equal(3)


func test_update_simulation_displays_profile_and_initial_campaign_values() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)

	# Act
	screen.update_simulation(simulation, {"name": "Nyx"})

	# Assert
	var name_label: Label = screen.find_child("CharacterName", true, false) as Label
	var credits_label: Label = screen.find_child("CharacterCredits", true, false) as Label
	var progress_label: Label = screen.find_child("CalendarProgress", true, false) as Label
	assert_str(name_label.text).is_equal("Nyx")
	assert_str(credits_label.text).is_equal("200 Cr")
	assert_str(progress_label.text).contains("0/108")


func test_status_panel_uses_stat_names_from_json() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	var status_panel: StatusPanel = screen.get_node("StatusPanel") as StatusPanel

	# Act
	status_panel.set_expanded(true)
	var labels: Array[Node] = status_panel.find_children("*", "Label", true, false)
	var visible_text: Array[String] = []
	for node: Node in labels:
		var label: Label = node as Label
		if label != null:
			visible_text.append(label.text)

	# Assert
	assert_bool(visible_text.has("Força")).is_true()
	assert_bool(visible_text.has("Inteligência")).is_true()
	assert_bool(visible_text.has("Ética")).is_true()


func test_status_expands_inline_and_uses_shared_theme() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)
	var status_panel: StatusPanel = screen.get_node("StatusPanel") as StatusPanel
	var status_button: Button = screen.find_child("StatusToggle", true, false) as Button

	# Act
	status_button.pressed.emit()

	# Assert
	assert_bool(status_panel.expanded).is_true()
	assert_str(status_button.text).is_equal("Fechar")
	var shared_panel_style: StyleBox = screen.theme.get_stylebox("panel", "PanelContainer")
	var status_panel_style: StyleBox = status_panel.get_theme_stylebox(
		"panel", "PanelContainer"
	)
	assert_object(status_panel_style).is_same(shared_panel_style)
