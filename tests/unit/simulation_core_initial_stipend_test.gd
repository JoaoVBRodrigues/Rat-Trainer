extends GdUnitTestSuite


func test_initialize_credits_first_year_stipend_before_first_choice() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()

	# Act
	var initialized: bool = simulation.initialize()

	# Assert
	assert_bool(initialized).is_true()
	assert_int(simulation.calendar.completed_periods).is_equal(0)
	assert_int(simulation.economy.get_credits()).is_equal(200)
