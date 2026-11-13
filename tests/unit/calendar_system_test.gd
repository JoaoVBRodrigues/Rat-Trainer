# GDD: Test Cases
class_name CalendarSystemTest
extends GdUnitTestSuite

# CalendarSystem Tests - Tests calendar progression through periods, months, and years

func test_initial_state_returns_defaults() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act & Assert
	assert_int(cal.completed_periods).is_equal(0)
	assert_int(cal.get_year()).is_equal(1)
	assert_int(cal.get_month()).is_equal(1)
	assert_int(cal.get_period()).is_equal(1)
	assert_int(cal.get_age()).is_equal(12)
	assert_bool(cal.is_campaign_complete()).is_false()

func test_advance_one_period_moves_to_period_2() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act
	cal.advance_period()

	# Assert
	assert_int(cal.completed_periods).is_equal(1)
	assert_int(cal.get_period()).is_equal(2)

func test_advance_periods_month_boundary_returns_first_of_next_month() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act - advance to end of month 1
	cal.advance_period()
	cal.advance_period()
	cal.advance_period()  # Period 3 -> new period

	# Assert
	assert_int(cal.get_month()).is_equal(2)
	assert_int(cal.get_period()).is_equal(1)

func test_advance_to_year_boundary_returns_first_day_of_year_2() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act - advance 36 periods (end of year 1)
	for i in range(36):
		cal.advance_period()

	# Assert
	assert_int(cal.get_year()).is_equal(2)

func test_campaign_completes_after_108_periods() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act - advance through all 108 periods
	for i in range(108):
		cal.advance_period()

	# Assert
	assert_bool(cal.is_campaign_complete()).is_true()
	assert_int(cal.get_age()).is_equal(15)

func test_final_period_is_also_month_end() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act
	for i in range(108):
		cal.advance_period()

	# Assert
	assert_bool(cal.is_month_end()).is_true()
	assert_bool(cal.is_year_end()).is_true()


func test_calendar_config_accepts_one_year_campaign() -> void:
	# Arrange
	var config_path: String = "user://calendar_short_test.json"
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	assert_bool(file != null).is_true()
	if file == null:
		return
	file.store_string('{"calendar":{"years":1,"months":12,"periods":3}}')
	file.close()
	var cal: CalendarSystem = CalendarSystem.new()

	# Act
	var initialized: bool = cal.initialize_from_config(config_path)

	# Assert
	assert_bool(initialized).is_true()
	assert_int(cal.total_periods).is_equal(36)
	assert_int(cal.get_remaining_periods()).is_equal(36)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))

func test_age_progresses_one_year_per_year() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Assert - Year 1
	assert_int(cal.get_age()).is_equal(12)

	# Act - advance through year 1
	for i in range(36):
		cal.advance_period()

	# Assert - Year 2
	assert_int(cal.get_age()).is_equal(13)

	# Act - advance through year 3
	for i in range(36):
		cal.advance_period()

	# Assert - Year 3
	assert_int(cal.get_age()).is_equal(14)

func test_is_new_year_period_returns_true_at_year_start() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Act & Assert
	assert_bool(cal.is_new_year_period()).is_true()

func test_weekday_label_cycles_monday_wednesday_friday() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Assert
	assert_str(cal.get_weekday_label()).is_equal("Monday")

	# Act
	cal.advance_period()

	# Assert
	assert_str(cal.get_weekday_label()).is_equal("Wednesday")

	# Act
	cal.advance_period()

	# Assert
	assert_str(cal.get_weekday_label()).is_equal("Friday")

func test_period_index_formulas_match_gdd_specification() -> void:
	# Arrange - Test case from GDD: 7 completed periods -> year 1, month 3, period 2
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")
	cal.completed_periods = 7
	cal._update_calculated_values()

	# Assert
	assert_int(cal.get_year()).is_equal(1)
	assert_int(cal.get_month()).is_equal(3)
	assert_int(cal.get_period()).is_equal(2)

func test_get_remaining_periods_returns_correct_count() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")

	# Assert
	assert_int(cal.get_remaining_periods()).is_equal(108)

	# Act
	cal.advance_period()

	# Assert
	assert_int(cal.get_remaining_periods()).is_equal(107)

func test_reset_returns_to_initial_state() -> void:
	# Arrange
	var cal = CalendarSystem.new()
	cal.initialize_from_config("res://assets/data/calendar.json")
	cal.advance_period()
	cal.advance_period()

	# Act
	cal.reset()

	# Assert
	assert_int(cal.completed_periods).is_equal(0)
	assert_int(cal.get_year()).is_equal(1)
	assert_int(cal.get_month()).is_equal(1)
	assert_int(cal.get_period()).is_equal(1)