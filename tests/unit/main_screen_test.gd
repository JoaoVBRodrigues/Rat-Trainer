extends GdUnitTestSuite


func test_main_screen_builds_six_focusable_destinations() -> void:
	# Arrange
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)

	# Assert
	assert_int(screen.get_menu_button_count()).is_equal(6)
	for button: Button in screen._menu_buttons:
		assert_int(button.focus_mode).is_equal(Control.FOCUS_ALL)


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
