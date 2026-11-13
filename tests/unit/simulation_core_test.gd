# GDD: Test Cases
class_name SimulationCoreTest
extends GdUnitTestSuite

# SimulationCore Tests - Tests the main simulation facade and integration

func test_initialize_creates_all_systems() -> void:
	# Arrange
	var sim = SimulationCore.new()

	# Act
	var success = sim.initialize()

	# Assert
	assert_bool(success).is_true()

func test_start_new_game_resets_all_state() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.advance_period("leisure_descanso")

	# Act
	sim.start_new_game()

	# Assert
	assert_int(sim.calendar.completed_periods).is_equal(0)
	assert_int(sim.stats.get_stress()).is_equal(0)
	assert_int(sim.economy.get_credits()).is_equal(200)
	assert_int(sim.get_age()).is_equal(12)

func test_initial_stipend_is_available_before_first_choice() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)
	assert_int(sim.economy.get_credits()).is_equal(200)

	# Act - First period should give stipend
	var result = sim.advance_period("leisure_descanso")

	# Assert - The stipend was already credited before the first choice
	assert_bool(result.year_stipend_given).is_false()
	assert_int(result.credits_change).is_equal(0)
	assert_int(sim.economy.get_credits()).is_equal(200)

func test_advance_period_applies_study_activity() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)

	# Act
	var result = sim.advance_period("study_curso_tecnologia_l1")

	# Assert
	assert_int(result.stat_changes.get("int", 0)).is_equal(12)
	assert_int(sim.economy.get_credits()).is_equal(192)  # 200 - 8 cost

func test_advance_period_applies_work_activity() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)

	# Act
	var result = sim.advance_period("work_trabalho_reparo_leve_l1")

	# Assert
	assert_int(result.credits_change).is_equal(15)
	assert_int(sim.economy.get_credits()).is_equal(215)
	assert_int(result.activity_type).is_equal(PeriodResult.ActivityType.WORK)

func test_advance_period_applies_mission_technical_on_success() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.stats.set_stat("int", 80)
	sim.stats.set_stat("sta", 50)  # Higher STA = higher disease threshold
	sim.set_seed(42)

	# Act
	var result = sim.advance_period("mission_missao_tecnica_l1")

	# Assert
	assert_int(result.activity_type).is_equal(PeriodResult.ActivityType.MISSION)


func test_successful_technical_mission_credits_its_reward() -> void:
	# Arrange / Act
	for seed_value: int in range(1, 101):
		var sim: SimulationCore = SimulationCore.new()
		assert_bool(sim.initialize()).is_true()
		sim.stats.set_stat("int", 100)
		sim.stats.set_stat("eth", 100)
		sim.set_seed(seed_value)
		var result: PeriodResult = sim.advance_period("mission_missao_tecnica")
		if not result.mission_success:
			continue

		# Assert
		assert_int(result.credits_change).is_equal(30)
		assert_int(sim.economy.get_credits()).is_equal(230)
		assert_int(result.mission_count).is_equal(1)
		assert_int(result.rep_gained.get("hacker", 0)).is_equal(5)
		return
	assert_bool(false).is_true()


func test_advance_period_applies_leisure() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.stats.set_stress(50)
	sim.set_seed(42)

	# Act
	var result = sim.advance_period("leisure_descanso")

	# Assert
	assert_int(result.activity_type).is_equal(PeriodResult.ActivityType.LEISURE)


func test_balanced_strategy_first_three_months_match_gdd_values() -> void:
	# Arrange
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()
	sim.set_seed(12345)
	var choices: Array[String] = [
		"study_curso_tecnologia_l1",
		"work_trabalho_reparo_leve",
		"leisure_descanso",
		"study_curso_comunicacao_l1",
		"work_trabalho_reparo_leve",
		"leisure_descanso",
		"study_curso_artes_l1",
		"work_trabalho_reparo_leve",
		"leisure_descanso"
	]

	# Act
	for choice: String in choices:
		var result: PeriodResult = sim.advance_period(choice)
		assert_bool(result.completed).is_true()

	# Assert
	assert_int(sim.stats.get_stat("int")).is_equal(33)
	assert_int(sim.stats.get_stat("cha")).is_equal(23)
	assert_int(sim.stats.get_stat("ref")).is_equal(28)
	assert_int(sim.stats.get_stress()).is_equal(0)
	assert_int(sim.economy.get_credits()).is_equal(226)
	assert_int(sim.calendar.completed_periods).is_equal(9)

func test_campaign_completes_after_108_periods_deterministic() -> void:
	# Arrange - Using a fixed seed for determinism
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(12345)

	# Act - Run full campaign with leisure (always succeeds)
	for i in range(108):
		var result = sim.advance_period("leisure_descanso", 12345 + i)

	# Assert
	assert_bool(sim.is_campaign_complete()).is_true()
	assert_int(sim.get_age()).is_equal(15)


func test_one_year_configuration_completes_after_36_periods() -> void:
	# Arrange
	var config_path: String = "user://simulation_short_calendar_test.json"
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	assert_bool(file != null).is_true()
	if file == null:
		return
	file.store_string('{"calendar":{"years":1,"months":12,"periods":3}}')
	file.close()
	var sim: SimulationCore = SimulationCore.new()
	var initialized: bool = sim.initialize(config_path)
	assert_bool(initialized).is_true()
	if not initialized:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))
		return

	# Act
	for period_index: int in range(36):
		var result: PeriodResult = sim.advance_period("leisure_descanso")
		assert_bool(result.completed).is_true()

	# Assert
	assert_bool(sim.is_campaign_complete()).is_true()
	assert_int(sim.get_age()).is_equal(13)
	assert_int(sim.calendar.total_periods).is_equal(36)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))


func test_disease_blocks_missions() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.stats.set_stress(80)  # High stress
	sim.stats.check_and_update_disease()

	# Act
	var can_mission = sim.is_mission_available()

	# Assert
	assert_bool(can_mission).is_false()


func test_disease_rejects_mission_without_consuming_period() -> void:
	# Arrange
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()
	sim.stats.set_stress(80)
	sim.stats.check_and_update_disease()

	# Act
	var result: PeriodResult = sim.advance_period("mission_missao_tecnica")

	# Assert
	assert_bool(result.completed).is_false()
	assert_str(result.error_message).is_equal("Missions are unavailable while diseased.")
	assert_int(sim.calendar.completed_periods).is_equal(0)


func test_year_2_stipend_comes_at_period_37() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)

	# Act - Advance to period 36 (end of year 1)
	for i in range(35):
		sim.advance_period("leisure_descanso", 42 + i)

	# Period 36 is last of year 1, age 12
	assert_int(sim.calendar.get_year()).is_equal(1)
	assert_int(sim.calendar.get_age()).is_equal(12)

	# The Year 2 stipend is credited before its first choice
	var year_end_result: PeriodResult = sim.advance_period("leisure_descanso", 42 + 35)
	assert_int(sim.calendar.get_year()).is_equal(2)
	assert_bool(year_end_result.year_stipend_given).is_true()
	assert_int(sim.economy.get_credits()).is_equal(400)
	var first_year_two_result: PeriodResult = sim.advance_period("leisure_descanso", 42 + 36)
	assert_bool(first_year_two_result.year_stipend_given).is_false()
	assert_int(sim.economy.get_credits()).is_equal(400)

func test_stat_clamp_applied_after_activity() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)

	# Act - Push INT to 99, then study should not overshoot
	sim.stats.set_stat("int", 99)
	sim.advance_period("study_curso_tecnologia_l1", 42)

	# Assert - INT clamped to 100
	assert_int(sim.stats.get_stat("int")).is_equal(100)

func test_stress_never_goes_negative() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.stats.set_stress(5)

	# Act - Descanso reduces by 15, should clamp to 0
	sim.advance_period("leisure_descanso", 42)

	# Assert
	assert_int(sim.stats.get_stress()).is_equal(0)

func test_get_available_activities_changes_with_disease() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()

	# Act - Get available when healthy
	var available = sim.get_available_activities()

	# Assert - Missions available
	assert_int(available.mission.size()).is_equal(3)

	# Act - Make player diseased
	sim.stats.set_stress(80)
	sim.stats.check_and_update_disease()
	available = sim.get_available_activities()

	# Assert - No missions available
	assert_int(available.mission.size()).is_equal(0)

func test_state_can_be_saved_and_loaded() -> void:
	# Arrange
	var sim1 = SimulationCore.new()
	sim1.initialize()
	sim1.set_seed(12345)
	sim1.advance_period("study_curso_tecnologia_l1", 12345)
	sim1.advance_period("work_trabalho_reparo_leve_l1", 12345 + 1)

	# Act
	var state = sim1.get_state()

	# Act - Load into new simulation
	var sim2 = SimulationCore.new()
	sim2.initialize()
	sim2.load_state(state)

	# Assert - States match
	assert_int(sim2.calendar.completed_periods).is_equal(sim1.calendar.completed_periods)
	assert_int(sim2.stats.get_stress()).is_equal(sim1.stats.get_stress())
	assert_int(sim2.economy.get_credits()).is_equal(sim1.economy.get_credits())

func test_three_full_campaigns_complete_deterministically() -> void:
	# Arrange
	var seeds = [100, 200, 300]

	for seed in seeds:
		var sim = SimulationCore.new()
		assert_bool(sim.initialize()).is_true()
		sim.set_seed(seed)

		# Act - Run full campaign
		for i in range(108):
			var choice: String = "mission_missao_tecnica" if i % 4 == 0 else "leisure_descanso"
			var result = sim.advance_period(choice, seed + i)
			assert_bool(result.completed).is_true()
			assert_str(result.error_message).is_empty()

		# Assert
		assert_bool(sim.is_campaign_complete()).is_true()
		assert_int(sim.get_age()).is_equal(15)

func test_same_seed_reproduces_identical_campaign_state() -> void:
	# Arrange
	var first: SimulationCore = _run_seeded_campaign(7123)
	var second: SimulationCore = _run_seeded_campaign(7123)

	# Assert
	assert_str(JSON.stringify(first.get_state())).is_equal(JSON.stringify(second.get_state()))


func _run_seeded_campaign(seed_value: int) -> SimulationCore:
	var sim: SimulationCore = SimulationCore.new()
	sim.initialize()
	sim.set_seed(seed_value)
	for period_index: int in range(sim.calendar.total_periods):
		var choice: String = "mission_missao_tecnica" if period_index % 4 == 0 else "leisure_descanso"
		var result: PeriodResult = sim.advance_period(choice)
		assert_bool(result.completed).is_true()
	return sim