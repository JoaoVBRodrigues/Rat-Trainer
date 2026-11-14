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


func test_physical_encounter_loads_monster_display_name() -> void:
	# Arrange
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()

	# Act
	var monster: Dictionary = sim.activities.get_monster_for_mission("missao_fisica_drones")

	# Assert
	assert_str(monster.get("name", "")).is_equal("Drone Patrulha")


func test_invalid_encounter_option_preserves_pending_encounter() -> void:
	# Arrange
	var encounter: Dictionary = _find_open_physical_encounter("missao_fisica_ruinas")
	assert_bool(encounter.is_empty()).is_false()
	var sim: SimulationCore = encounter["simulation"]
	var pending: PeriodResult = encounter["result"]
	assert_bool(pending.is_encounter_pending).is_true()

	# Act
	var invalid_result: PeriodResult = sim.resolve_pending_encounter(-1)

	# Assert
	assert_bool(invalid_result.error_message.is_empty()).is_false()
	assert_bool(sim.has_pending_encounter()).is_true()
	assert_int(sim.calendar.completed_periods).is_equal(0)
	assert_bool(sim.get_state().is_empty()).is_true()


func test_encounter_completion_preserves_original_period_and_advances_once() -> void:
	# Arrange
	var encounter: Dictionary = _find_open_physical_encounter("missao_fisica_ruinas")
	assert_bool(encounter.is_empty()).is_false()
	var sim: SimulationCore = encounter["simulation"]
	var pending: PeriodResult = encounter["result"]
	assert_int(sim.calendar.completed_periods).is_equal(0)

	# Act
	var result: PeriodResult = sim.resolve_pending_encounter(
		ActivitySystem.EncounterOption.FLEE
	)

	# Assert
	assert_bool(result.completed).is_true()
	assert_int(result.period).is_equal(pending.period)
	assert_int(result.year).is_equal(pending.year)
	assert_int(result.month).is_equal(pending.month)
	assert_int(result.period_num).is_equal(pending.period_num)
	assert_str(result.activity_id).is_equal("missao_fisica_ruinas")
	assert_int(sim.calendar.completed_periods).is_equal(1)
	assert_bool(sim.has_pending_encounter()).is_false()


func test_fight_defeat_applies_only_stress_and_no_stat_or_crime_loss() -> void:
	# Arrange
	var found_defeat: bool = false
	for seed_value: int in range(1, 301):
		var encounter: Dictionary = _open_physical_encounter(
			"missao_fisica_ruinas", ActivitySystem.EncounterOption.FIGHT, seed_value
		)
		if encounter.is_empty():
			continue
		var sim: SimulationCore = encounter["simulation"]
		var result: PeriodResult = sim.resolve_pending_encounter(
			ActivitySystem.EncounterOption.FIGHT
		)
		if result.mission_success:
			continue

		# Assert
		found_defeat = true
		assert_int(result.stress_change).is_equal(10)
		assert_int(sim.stats.get_stress()).is_equal(10)
		assert_bool(result.stat_changes.is_empty()).is_true()
		assert_int(sim.stats.get_stat("str")).is_equal(15)
		assert_bool(sim.criminal_record).is_false()
		assert_bool(result.encounter_orac_returned).is_true()
		assert_int(result.items_gained.size()).is_equal(0)
		assert_int(sim.calendar.completed_periods).is_equal(1)
		break
	assert_bool(found_defeat).is_true()


func test_failed_non_fight_encounter_also_returns_nyx_home() -> void:
	# Arrange
	var found_failure: bool = false
	for seed_value: int in range(1, 301):
		var encounter: Dictionary = _open_physical_encounter(
			"missao_fisica_ruinas", ActivitySystem.EncounterOption.TALK, seed_value
		)
		if encounter.is_empty():
			continue
		var sim: SimulationCore = encounter["simulation"]
		sim.stats.set_stat("cha", 0)
		sim.stats.set_stat("int", 0)

		# Act
		var result: PeriodResult = sim.resolve_pending_encounter(
			ActivitySystem.EncounterOption.TALK
		)
		if result.mission_success:
			continue

		# Assert
		found_failure = true
		assert_bool(result.encounter_orac_returned).is_true()
		assert_bool(result.encounter_description.is_empty()).is_false()
		assert_int(result.stress_change).is_equal(8)
		assert_int(sim.calendar.completed_periods).is_equal(1)
		break
	assert_bool(found_failure).is_true()


func test_conversation_success_grants_half_reward_and_exact_stress() -> void:
	# Arrange
	var found_success: bool = false
	for seed_value: int in range(1, 301):
		var encounter: Dictionary = _open_physical_encounter(
			"missao_fisica_ruinas", ActivitySystem.EncounterOption.TALK, seed_value
		)
		if encounter.is_empty():
			continue
		var sim: SimulationCore = encounter["simulation"]
		sim.stats.set_stat("cha", 70)
		sim.stats.set_stat("int", 100)
		var result: PeriodResult = sim.resolve_pending_encounter(
			ActivitySystem.EncounterOption.TALK
		)
		if not result.mission_success:
			continue

		# Assert
		found_success = true
		assert_int(result.credits_change).is_equal(12)
		assert_int(result.stat_changes.get("cha", 0)).is_equal(1)
		assert_int(result.rep_gained.get("social", 0)).is_equal(2)
		assert_int(result.stress_change).is_equal(6)
		assert_bool(result.stat_changes.has("str")).is_false()
		break
	assert_bool(found_success).is_true()


func test_successful_fight_rewards_and_recovery_drop_are_applied_once() -> void:
	# Arrange
	var found_reward_and_drop: bool = false
	for seed_value: int in range(1, 1001):
		var encounter: Dictionary = _open_physical_encounter(
			"missao_fisica_ruinas", ActivitySystem.EncounterOption.FIGHT, seed_value
		)
		if encounter.is_empty():
			continue
		var sim: SimulationCore = encounter["simulation"]
		var result: PeriodResult = sim.resolve_pending_encounter(
			ActivitySystem.EncounterOption.FIGHT
		)
		if not result.mission_success or not result.items_gained.has("adesivo_recuperacao"):
			continue

		# Assert
		found_reward_and_drop = true
		assert_int(result.credits_change).is_equal(25)
		assert_int(result.stat_changes.get("str", 0)).is_equal(2)
		assert_int(result.rep_gained.get("fighter", 0)).is_equal(5)
		assert_int(result.items_gained.size()).is_equal(1)
		assert_int(sim.get_item_count("adesivo_recuperacao")).is_equal(1)
		var duplicate_resolution: PeriodResult = sim.resolve_pending_encounter(
			ActivitySystem.EncounterOption.FIGHT
		)
		assert_bool(duplicate_resolution.error_message.is_empty()).is_false()
		assert_int(sim.get_item_count("adesivo_recuperacao")).is_equal(1)
		break
	assert_bool(found_reward_and_drop).is_true()


func test_drones_success_applies_counter_effect_from_mission_data() -> void:
	# Arrange
	var found_success: bool = false
	for seed_value: int in range(1, 501):
		var encounter: Dictionary = _open_physical_encounter(
			"missao_fisica_drones", ActivitySystem.EncounterOption.FIGHT, seed_value
		)
		if encounter.is_empty():
			continue
		var sim: SimulationCore = encounter["simulation"]
		var result: PeriodResult = sim.resolve_pending_encounter(
			ActivitySystem.EncounterOption.FIGHT
		)
		if not result.mission_success:
			continue

		# Assert
		found_success = true
		assert_int(sim.get_state()["missions_technical_completed"]).is_equal(1)
		assert_int(sim.get_state()["activities"]["missions_technical_completed"]).is_equal(1)
		assert_int(result.mission_count).is_equal(1)
		assert_int(result.credits_change).is_equal(30)
		break
	assert_bool(found_success).is_true()


func test_equipped_item_ids_default_empty_and_round_trip_in_simulation_state() -> void:
	# Arrange
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()
	assert_int(sim.get_equipped_item_ids().size()).is_equal(0)
	assert_bool(sim.set_equipped_item_ids(["kit_ferramentas"])).is_true()
	var snapshot: Dictionary = sim.get_state()
	var restored: SimulationCore = SimulationCore.new()
	assert_bool(restored.initialize()).is_true()

	# Act
	var loaded: bool = restored.load_state(snapshot)

	# Assert
	assert_bool(loaded).is_true()
	assert_array(restored.get_equipped_item_ids()).contains_exactly_in_any_order(
		"kit_ferramentas"
	)


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

	# Act - Run 9 periods accounting for events at months 3, 6, 9 period 3
	var choices: Array[String] = [
		"study_curso_tecnologia_l1",
		"work_trabalho_reparo_leve_l1",
		"leisure_descanso",
		"study_curso_comunicacao_l1",
		"work_trabalho_reparo_leve_l1",
		"leisure_descanso",
		"study_curso_artes_l1",
		"work_trabalho_reparo_leve_l1",
		"leisure_descanso"
	]

	var results: Array[PeriodResult] = []
	for i in range(9):
		var choice: String = choices[i]
		var result: PeriodResult = sim.advance_period(choice, 12345 + i)
		while result.is_event_pending:
			var event_option: String = _get_event_option_for_result(result)
			result = sim.advance_period(event_option, 12345 + i)
		results.append(result)

	# Check all completed successfully
	for result: PeriodResult in results:
		assert_bool(result.completed).is_true()

	# Verify final state after 9 periods; only E01 occurs in this range (year 1, month 3).
	# Period 0: study_curso_tecnologia_l1 - INT +12, -8 credits
	# Period 1: work_trabalho_reparo_leve - +15 credits
	# Period 2: leisure_descanso - stress -5 (clamped to 0)
	# Periods 3-7: normal activities, with any random events resolved separately
	# Period 8: fixed event E01 resolved
	assert_int(sim.stats.get_stat("int")).is_equal(33)
	assert_int(sim.stats.get_stat("cha")).is_equal(25)
	assert_int(sim.stats.get_stat("ref")).is_equal(28)
	assert_int(sim.economy.get_credits()).is_equal(226)
	assert_int(sim.stats.get_stat("eth")).is_equal(53)
	assert_int(sim.calendar.completed_periods).is_equal(9)

func test_campaign_completes_after_108_periods_deterministic() -> void:
	# Arrange - Using a fixed seed for determinism
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(12345)

	# Act - Run full campaign with leisure (always succeeds)
	for i in range(108):
		var result = sim.advance_period("leisure_descanso", 12345 + i)
		while result.is_event_pending:
			var event_id: String = result.event_id
			result = sim.advance_period("%s_a" % event_id, 12345 + i)
			assert_bool(result.completed).is_true()

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

	# Act - Month 3, 6, 9, 12 period 3 are event periods
	var event_periods: Array[int] = [2, 5, 8, 11]  # 0-indexed
	for period_index: int in range(36):
		var choice: String = "leisure_descanso"
		var result: PeriodResult = sim.advance_period(choice)

		# Handle event if triggered
		if result.is_event_pending:
			var event_id: String = result.event_id
			result = sim.advance_period("%s_a" % event_id)

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
	sim.set_seed(42)
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
	# Month 3, 6, 9, 12 period 3 are event periods
	var event_periods: Array[int] = [2, 5, 8, 11]  # 0-indexed for year 1

	for i in range(35):
		var result: PeriodResult = sim.advance_period("leisure_descanso", 42 + i)
		# Handle event if triggered
		if result.is_event_pending:
			var event_id: String = result.event_id
			result = sim.advance_period("%s_a" % event_id, 42 + i)

	# Period 36 corresponds to year 1 month 12 period 3 (index 35 = 11+24 = month 12 period 3)
	# But we've only done 35 advances, so we're at period 35
	assert_int(sim.calendar.completed_periods).is_equal(35)

	# Advance to period 36 - this is Month 12, Period 3 which is event e04
	var year_end_result: PeriodResult = sim.advance_period("leisure_descanso", 42 + 35)
	if year_end_result.is_event_pending:
		year_end_result = sim.advance_period("e04_a", 42 + 35)

	# Year 2 stipend is credited after advancing to a new year period
	assert_int(sim.calendar.get_year()).is_equal(2)
	assert_bool(year_end_result.year_stipend_given).is_true()
	assert_int(sim.economy.get_credits()).is_equal(400)

	# Next period should not give another stipend
	var first_year_two_result: PeriodResult = sim.advance_period("leisure_descanso", 42 + 36)
	if first_year_two_result.is_event_pending:
		first_year_two_result = sim.advance_period("e05_a", 42 + 36)
	assert_bool(first_year_two_result.year_stipend_given).is_false()
	assert_int(sim.economy.get_credits()).is_equal(400)

func test_stat_clamp_applied_after_activity() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)

	# Act - Push INT to 99, then study should not overshoot
	sim.stats.set_stat("int", 99)
	var result: PeriodResult = sim.advance_period("study_curso_tecnologia_l1", 42)
	while result.is_event_pending:
		result = sim.advance_period("e01_a", 42)

	# Assert - INT clamped to 100
	assert_int(sim.stats.get_stat("int")).is_equal(100)

func test_stress_never_goes_negative() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.stats.set_stress(5)

	# Act - Descanso reduces by 15, should clamp to 0
	var result: PeriodResult = sim.advance_period("leisure_descanso", 42)
	while result.is_event_pending:
		result = sim.advance_period("e01_a", 42)

	# Assert
	assert_int(sim.stats.get_stress()).is_equal(0)

func test_get_available_activities_changes_with_disease() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()

	# Act - Get available when healthy
	var available = sim.get_available_activities()

	# Assert - Missions available
	assert_int(available.mission.size()).is_equal(5)

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
			# Always call with normal choice first - event detection happens internally
			var choice: String = _get_activity_choice(i)
			var result: PeriodResult = sim.advance_period(choice, seed + i)

			# Handle event resolution (either fixed or random event triggered)
			while result.is_event_pending:
				var event_option: String = _get_event_option_for_result(result)
				result = sim.advance_period(event_option, seed + i)

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


func test_event_eth_applied_only_once_per_choice() -> void:
	# Arrange
	var sim = SimulationCore.new()
	sim.initialize()
	sim.set_seed(42)

	# Act - Advance through 8 periods
	# Note: Random events CAN trigger in these periods; we resolve them to reach Month 3, Period 3
	# e01 is a fixed event at Year 1, Month 3, Period 3 (completed_periods=8)
	var result: PeriodResult
	for i in range(8):
		result = sim.advance_period("leisure_descanso", 42 + i)
		while result.is_event_pending:
			var event_option: String = _get_event_option_for_result(result)
			result = sim.advance_period(event_option, 42 + i)

	# Verify we're at Month 3, Period 3 before triggering e01
	assert_int(sim.calendar.get_month()).is_equal(3)
	assert_int(sim.calendar.get_period()).is_equal(3)

	# Now advance the 9th period - e01 should trigger as a fixed event
	result = sim.advance_period("leisure_descanso", 42 + 8)

	# Assert - e01 should be pending as a fixed event
	assert_bool(result.is_event_pending).is_true()
	assert_str(result.event_id).is_equal("e01")

	# Record ETH before resolving e01
	var eth_before: int = sim.stats.get_stat("eth")

	# Resolve e01 with option "a" (Ajudar) - gives ETH +3
	result = sim.advance_period("e01_a", 42 + 8)

	# Assert - Verify ETH was added exactly once by e01's "Ajudar" option (+3)
	assert_int(result.stat_changes.get("eth", 0)).is_equal(3)
	assert_int(sim.stats.get_stat("eth") - eth_before).is_equal(3)


func test_festival_presentation_fails_below_ref_threshold() -> void:
	# Arrange
	var sim: SimulationCore = _simulation_at_first_year_festival(49)

	# Act
	var pending: PeriodResult = sim.advance_period("leisure_descanso")
	assert_bool(pending.is_event_pending).is_true()
	assert_str(pending.event_id).is_equal("e04")
	var result: PeriodResult = sim.advance_period("e04_a")

	# Assert
	assert_str(result.event_outcome).is_equal("failure")
	assert_int(result.stat_changes.get("ref", 0)).is_equal(2)
	assert_int(result.rep_gained.get("social", 0)).is_equal(0)


func test_festival_presentation_succeeds_at_ref_threshold() -> void:
	# Arrange
	var sim: SimulationCore = _simulation_at_first_year_festival(50)

	# Act
	var pending: PeriodResult = sim.advance_period("leisure_descanso")
	assert_bool(pending.is_event_pending).is_true()
	assert_str(pending.event_id).is_equal("e04")
	var result: PeriodResult = sim.advance_period("e04_a")

	# Assert
	assert_str(result.event_outcome).is_equal("success")
	assert_int(result.stat_changes.get("ref", 0)).is_equal(2)
	assert_int(result.rep_gained.get("social", 0)).is_equal(5)


func test_random_event_check_is_not_repeated_for_invalid_choice() -> void:
	# Arrange / Act
	for seed_value: int in range(1, 100):
		var sim: SimulationCore = SimulationCore.new()
		assert_bool(sim.initialize()).is_true()
		sim.stats.set_stat("int", 0)
		sim.stats.set_stat("cha", 0)
		sim.stats.set_stat("ref", 0)
		var first_result: PeriodResult = sim.advance_period("invalid_choice", seed_value)
		if first_result.is_event_pending:
			continue

		var first_diagnostic: String = sim.events.last_debug_message
		var restored_sim: SimulationCore = SimulationCore.new()
		assert_bool(restored_sim.initialize()).is_true()
		assert_bool(restored_sim.load_state(sim.get_state())).is_true()
		var retry_result: PeriodResult = restored_sim.advance_period(
			"invalid_choice", seed_value + 1000
		)

		# Assert
		assert_bool(first_result.error_message.is_empty()).is_false()
		assert_bool(retry_result.error_message.is_empty()).is_false()
		assert_bool(retry_result.is_event_pending).is_false()
		assert_bool(first_diagnostic.contains("not triggered")).is_true()
		assert_bool(restored_sim.events.last_debug_message.contains("already checked")).is_true()
		return

	assert_bool(false).is_true()


func test_fixed_event_debug_log_explains_random_check_skip() -> void:
	# Arrange
	var sim: SimulationCore = _simulation_at_first_year_festival(15)

	# Act
	var result: PeriodResult = sim.advance_period("leisure_descanso")

	# Assert
	assert_bool(result.is_event_pending).is_true()
	assert_str(result.event_id).is_equal("e04")
	assert_bool(sim.events.last_debug_message.contains("fixed event e04 has priority")).is_true()


func test_two_year_campaign_contains_varied_fixed_and_random_events() -> void:
	# Arrange
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()
	sim.stats.set_stat("int", 100)
	sim.stats.set_stat("cha", 100)
	sim.stats.set_stat("ref", 100)
	var event_counts: Dictionary = {}

	# Act
	for period_index: int in range(72):
		var result: PeriodResult = sim.advance_period("leisure_descanso", 20250212 + period_index)
		while result.is_event_pending:
			var event_id: String = result.event_id
			event_counts[event_id] = int(event_counts.get(event_id, 0)) + 1
			result = sim.advance_period(
				_get_event_option_for_result(result), 20250212 + period_index
			)
		assert_bool(result.completed).is_true()

	# Assert - The two-year campaign includes all eight fixed events and multiple random types.
	for event_number: int in range(1, 9):
		assert_bool(event_counts.has("e%02d" % event_number)).is_true()
	var random_event_types: int = 0
	for event_id: String in ["r01", "r02", "r03"]:
		if event_counts.has(event_id):
			random_event_types += 1
	assert_bool(random_event_types >= 2).is_true()


func _find_open_physical_encounter(mission_id: String) -> Dictionary:
	for seed_value: int in range(1, 1001):
		var encounter: Dictionary = _open_physical_encounter(
			mission_id, ActivitySystem.EncounterOption.FIGHT, seed_value
		)
		if not encounter.is_empty():
			return encounter
	return {}


func _open_physical_encounter(
	mission_id: String, _option: int, seed_value: int
) -> Dictionary:
	var sim: SimulationCore = SimulationCore.new()
	if not sim.initialize():
		return {}
	if mission_id == "missao_fisica_drones":
		sim.stats.set_stat("int", 27)
		if not sim.set_equipped_item_ids(["kit_ferramentas"]):
			return {}
	elif mission_id == "missao_fisica_infiltracao":
		sim.stats.set_stat("str", 25)
		if not sim.set_equipped_item_ids(["kit_ferramentas", "casaco_acolchoado"]):
			return {}
	sim.set_seed(seed_value)
	var pending: PeriodResult = sim.advance_period(
		"mission_%s" % mission_id, seed_value
	)
	if pending.is_event_pending or not pending.is_encounter_pending:
		return {}
	return {"simulation": sim, "result": pending}


func _simulation_at_first_year_festival(ref_value: int) -> SimulationCore:
	var sim: SimulationCore = SimulationCore.new()
	assert_bool(sim.initialize()).is_true()
	for period_index: int in range(35):
		var result: PeriodResult = sim.advance_period("leisure_descanso", 3100 + period_index)
		while result.is_event_pending:
			result = sim.advance_period(
				_get_event_option_for_result(result), 3100 + period_index
			)
		assert_bool(result.completed).is_true()
	sim.stats.set_stat("ref", ref_value)
	return sim


func _run_seeded_campaign(seed_value: int) -> SimulationCore:
	var sim: SimulationCore = SimulationCore.new()
	sim.initialize()
	sim.set_seed(seed_value)
	for period_index: int in range(sim.calendar.total_periods):
		var choice: String = _get_activity_choice(period_index)
		var result: PeriodResult = sim.advance_period(choice)

		while result.is_event_pending:
			var event_option: String = _get_event_option_for_result(result)
			result = sim.advance_period(event_option)

		assert_bool(result.completed).is_true()
	return sim


func _get_activity_choice(period_index: int) -> String:
	# Normal activity selection - events are handled internally by advance_period
	if period_index % 4 == 0:
		return "mission_missao_tecnica_l1"
	return "leisure_descanso"


func _get_event_option_for_result(result: PeriodResult) -> String:
	# Return the first available event option for the pending event
	var event_id: String = result.event_id
	if event_id.begins_with("e"):
		return "%s_a" % event_id  # Fixed events use option "a"
	if event_id.begins_with("r"):
		return "%s_a" % event_id  # Random events use option "a"
	return "option_a"  # Fallback