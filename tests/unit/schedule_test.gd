extends GdUnitTestSuite


func test_month_schedule_requires_three_valid_selections() -> void:
	# Arrange
	var schedule: MonthSchedule = MonthSchedule.new()

	# Act
	schedule.set_selection(0, MonthSchedule.ActivityPeriod.WORK, "trabalho_reparo_leve", 1, 0, true, "", 15)
	schedule.set_selection(1, MonthSchedule.ActivityPeriod.LEISURE, "descanso", 1, 0, true)

	# Assert
	assert_bool(schedule.is_month_selected()).is_false()
	assert_bool(schedule.is_valid()).is_false()
	assert_int(schedule.get_total_cost()).is_equal(0)


func test_month_schedule_duplicate_is_independent() -> void:
	# Arrange
	var schedule: MonthSchedule = MonthSchedule.new()
	schedule.set_selection(0, MonthSchedule.ActivityPeriod.WORK, "trabalho_reparo_leve", 1, 0, true, "", 15)
	schedule.set_selection(1, MonthSchedule.ActivityPeriod.LEISURE, "descanso", 1, 0, true)
	schedule.set_selection(2, MonthSchedule.ActivityPeriod.STUDY, "curso_tecnologia", 1, 8, true)
	var duplicate: MonthSchedule = schedule.duplicate_schedule()

	# Act
	duplicate.clear_selection(0)

	# Assert
	assert_bool(schedule.is_month_selected()).is_true()
	assert_bool(duplicate.is_month_selected()).is_false()
	assert_str(schedule.get_selection(0).get("activity_id", "")).is_equal("trabalho_reparo_leve")


func test_month_flow_resolves_three_sequential_periods_and_net_summary() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	simulation.set_seed(12345)
	var credits_before: int = simulation.economy.get_credits()
	var flow: MonthlyScheduleFlow = auto_free(MonthlyScheduleFlow.new())
	add_child(flow)
	flow.update_simulation(simulation)
	var schedule: MonthSchedule = _make_valid_schedule()

	# Act
	var report: Dictionary = flow.run_month_for_test(schedule, 12345)

	# Assert
	assert_bool(report.get("completed", false)).is_true()
	var results: Array = report.get("results", [])
	assert_int(results.size()).is_equal(3)
	assert_int((results[0] as PeriodResult).period_num).is_equal(1)
	assert_int((results[1] as PeriodResult).period_num).is_equal(2)
	assert_int((results[2] as PeriodResult).period_num).is_equal(3)
	assert_int(simulation.calendar.completed_periods).is_equal(3)
	assert_int(int(report.get("credits_final", 0))).is_equal(simulation.economy.get_credits())
	assert_int(int(report.get("credits_delta", 0))).is_equal(
		simulation.economy.get_credits() - credits_before
	)
	assert_int(int(report.get("stress_final", -1))).is_equal(simulation.stats.get_stress())


func test_invalid_schedule_does_not_advance_simulation() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	simulation.economy.credits = 5
	var flow: MonthlyScheduleFlow = auto_free(MonthlyScheduleFlow.new())
	add_child(flow)
	flow.update_simulation(simulation)
	var schedule: MonthSchedule = MonthSchedule.new()
	schedule.set_selection(0, MonthSchedule.ActivityPeriod.STUDY, "curso_tecnologia", 1, 8, true)
	schedule.set_selection(1, MonthSchedule.ActivityPeriod.WORK, "trabalho_reparo_leve", 1, 0, true, "", 15)
	schedule.set_selection(2, MonthSchedule.ActivityPeriod.LEISURE, "descanso", 1, 0, true)
	var initial_state: Dictionary = simulation.get_state()

	# Act
	var report: Dictionary = flow.run_month_for_test(schedule, 77)

	# Assert
	assert_bool(report.get("completed", false)).is_false()
	assert_int(simulation.calendar.completed_periods).is_equal(0)
	assert_int(simulation.economy.get_credits()).is_equal(
		int(initial_state.get("economy", {}).get("credits", 0))
	)


func test_month_flow_rejects_non_month_boundary_without_mutation() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var first_result: PeriodResult = simulation.advance_period("leisure_descanso", 11)
	assert_bool(first_result.completed).is_true()
	var flow: MonthlyScheduleFlow = auto_free(MonthlyScheduleFlow.new())
	add_child(flow)
	flow.update_simulation(simulation)
	var schedule: MonthSchedule = _make_valid_schedule()

	# Act
	var report: Dictionary = flow.run_month_for_test(schedule, 22)

	# Assert
	assert_bool(report.get("completed", false)).is_false()
	assert_int(simulation.calendar.completed_periods).is_equal(1)


func _make_valid_schedule() -> MonthSchedule:
	var schedule: MonthSchedule = MonthSchedule.new()
	schedule.credits_at_start = 200
	schedule.set_selection(
		0, MonthSchedule.ActivityPeriod.WORK, "trabalho_reparo_leve", 1, 0, true, "", 15
	)
	schedule.set_selection(
		1, MonthSchedule.ActivityPeriod.WORK, "trabalho_reparo_leve", 1, 0, true, "", 15
	)
	schedule.set_selection(
		2, MonthSchedule.ActivityPeriod.LEISURE, "descanso", 1, 0, true
	)
	return schedule
