# GDD: Test Cases
class_name ActivitySystemTest
extends GdUnitTestSuite

# ActivitySystem Tests - Tests study, work, mission, and leisure activities

func test_load_activities_from_json_succeeds() -> void:
	# Arrange
	var act = ActivitySystem.new()

	# Act
	var loaded = act.load_activities("res://assets/data/activities.json")

	# Assert
	assert_bool(loaded).is_true()

func test_load_missions_from_json_succeeds() -> void:
	# Arrange
	var act = ActivitySystem.new()

	# Act
	var loaded = act.load_missions("res://assets/data/missions.json")

	# Assert
	assert_bool(loaded).is_true()

func test_study_curso_tecnologia_level_1_gains_12_int_cost_8() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_study("curso_tecnologia", 1)

	# Assert - from GDD: Tecnologia level 1: +12 INT, 8 Cr, +2 Stress
	assert_int(result.get("stat_gains").get("int", 0)).is_equal(12)
	assert_int(result.get("cost")).is_equal(8)
	assert_int(result.get("stress_delta")).is_equal(2)

func test_study_curso_tecnologia_level_2_gains_15_int_cost_16() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_study("curso_tecnologia", 2)

	# Assert
	assert_int(result.get("stat_gains").get("int", 0)).is_equal(15)
	assert_int(result.get("cost")).is_equal(16)

func test_study_comunicacao_gains_cha_and_ref() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_study("curso_comunicacao", 1)

	# Assert - from GDD: +8 CHA, +5 REF at level 1
	assert_int(result.get("stat_gains").get("cha", 0)).is_equal(8)
	assert_int(result.get("stat_gains").get("ref", 0)).is_equal(5)
	assert_int(result.get("cost")).is_equal(6)

func test_work_reparo_leve_l1_income_15_stress_3() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_work("trabalho_reparo_leve", 1)

	# Assert
	assert_int(result.get("income")).is_equal(15)
	assert_int(result.get("stat_gains").get("int", 0)).is_equal(2)
	assert_int(result.get("stress_delta")).is_equal(3)

func test_work_reparo_leve_l2_promotion_income_floor_15_1_5() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_work("trabalho_reparo_leve", 2)

	# Assert - floor(15 * 1.5) = 22
	assert_int(result.get("income")).is_equal(22)

func test_mission_fisica_ruinas_has_str_test_no_auto_success() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()

	# Act
	var result = act.resolve_mission(
		"missao_fisica_ruinas",
		{"str": 15, "int": 15, "cha": 15, "ref": 15, "sta": 20, "eth": 50},
		42
	)

	# Assert
	assert_str(result.get("mission_type")).is_equal("physical")
	assert_bool(result.get("encounter_pending", false)).is_true()

func test_success_chance_calculated_correctly_from_gdd() -> void:
	# Arrange
	var act = ActivitySystem.new()

	# Act - GDD formula: 50 + (attr - 50) + floor(ETH/10), clamped 5-95
	var chance = act.calculate_success_chance(65, 40)

	# Assert - 50 + 15 + 4 = 69
	assert_int(chance).is_equal(69)

func test_success_chance_clamped_to_five_min() -> void:
	# Arrange
	var act = ActivitySystem.new()

	# Act
	var chance = act.calculate_success_chance(0, 0)

	# Assert - clamped to 5 from GDD
	assert_int(chance).is_equal(5)

func test_success_chance_clamped_to_95_max() -> void:
	# Arrange
	var act = ActivitySystem.new()

	# Act
	var chance = act.calculate_success_chance(100, 100)

	# Assert - clamped to 95 from GDD
	assert_int(chance).is_equal(95)

func test_leisure_descanso_reduces_stress_by_15() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_leisure("descanso")

	# Assert
	assert_int(result.get("stress_delta")).is_equal(-15)
	assert_int(result.get("cost")).is_equal(0)

func test_leisure_passeio_increases_cha_minus_5_stress() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_leisure("passeio_comunitario")

	# Assert
	assert_int(result.get("stat_gains").get("cha", 0)).is_equal(2)
	assert_int(result.get("stress_delta")).is_equal(-5)

func test_study_is_type_study() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var result = act.execute_study("curso_tecnologia", 1)

	# Assert
	assert_int(result.get("activity_type", -1)).is_equal(ActivitySystem.ActivityType.STUDY)

func test_mission_tecnica_has_no_cost_upfront() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_missions("res://assets/data/missions.json")

	# Act
	var result = act.execute_mission("missao_tecnica", 15, 50, 42)

	# Assert - Missions don't cost credits upfront
	assert_int(result.get("cost", 0)).is_equal(0)

func test_mission_physical_stress_is_4_plus_combat() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()
	act.rng.seed = 42

	# Act
	var result = act.resolve_encounter(
		ActivitySystem.EncounterOption.TALK,
		"drone_patrulha",
		{"str": 40, "int": 40, "cha": 70, "ref": 30, "sta": 40, "eth": 0}
	)

	# Regression: every option uses the configured stat pair and shared chance formula.
	assert_int(result.get("success_chance", -1)).is_equal(64)


func test_each_encounter_option_uses_its_approved_stat_pair_and_formula() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()
	var current_stats: Dictionary = {
		"str": 60, "sta": 40, "cha": 70, "int": 40, "ref": 30
	}

	# Act / Assert
	assert_int(act.calculate_encounter_success_chance(
		ActivitySystem.EncounterOption.FIGHT, current_stats, 50
	)).is_equal(59)
	assert_int(act.calculate_encounter_success_chance(
		ActivitySystem.EncounterOption.TALK, current_stats, 50
	)).is_equal(64)
	assert_int(act.calculate_encounter_success_chance(
		ActivitySystem.EncounterOption.FLEE, current_stats, 50
	)).is_equal(48)
	assert_int(act.calculate_encounter_success_chance(
		ActivitySystem.EncounterOption.HIDE, current_stats, 50
	)).is_equal(52)


func test_encounter_chance_clamps_to_five_and_ninety_five() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()

	# Act
	var minimum: int = act.calculate_encounter_success_chance(
		ActivitySystem.EncounterOption.FIGHT, {"str": 0, "sta": 0}, 100
	)
	var maximum: int = act.calculate_encounter_success_chance(
		ActivitySystem.EncounterOption.FIGHT, {"str": 100, "sta": 100}, 0, 10
	)

	# Assert
	assert_int(minimum).is_equal(5)
	assert_int(maximum).is_equal(95)


func test_roll_equal_to_chance_fails() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()

	# Act / Assert
	assert_bool(act._is_roll_successful(57, 57)).is_false()
	assert_bool(act._is_roll_successful(56, 57)).is_true()


func test_encounter_outcome_is_repeatable_for_the_same_seed() -> void:
	# Arrange
	var first: ActivitySystem = _make_encounter_activity_system()
	var second: ActivitySystem = _make_encounter_activity_system()
	var current_stats: Dictionary = {"str": 50, "sta": 50}
	first.rng.seed = 12345
	second.rng.seed = 12345

	# Act
	var first_result: Dictionary = first.resolve_encounter(
		ActivitySystem.EncounterOption.FIGHT, "rastreador", current_stats
	)
	var second_result: Dictionary = second.resolve_encounter(
		ActivitySystem.EncounterOption.FIGHT, "rastreador", current_stats
	)

	# Assert
	assert_bool(first_result.get("success", false)).is_equal(
		second_result.get("success", false)
	)
	assert_int(first_result.get("success_chance", -1)).is_equal(
		second_result.get("success_chance", -2)
	)


func test_required_equipment_blocks_mission_and_applies_only_when_equipped() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()
	var stats: Dictionary = {"str": 25, "int": 27, "cha": 15, "ref": 15, "sta": 20, "eth": 50}

	# Act / Assert
	assert_bool(
		act.get_mission_availability_error("missao_fisica_drones", stats).contains(
			"kit_ferramentas"
		)
	).is_true()
	assert_bool(act.set_equipped_item_ids(["kit_ferramentas"])).is_true()
	assert_str(
		act.get_mission_availability_error("missao_fisica_drones", stats)
	).is_equal("")
	assert_bool(
		act.get_mission_availability_error("missao_fisica_infiltracao", stats).contains(
			"casaco_acolchoado"
		)
	).is_true()
	assert_bool(
		act.set_equipped_item_ids(["kit_ferramentas", "casaco_acolchoado"])
	).is_true()
	assert_int(act.get_mission_equipment_bonus("missao_fisica_infiltracao")).is_equal(10)


func test_each_option_returns_exact_stress_for_success_and_failure() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()
	var option_stress: Dictionary = {
		0: [3, 6], 1: [2, 4], 2: [2, 6], 3: [1, 6]
	}
	var current_stats: Dictionary = {
		"str": 50, "sta": 50, "cha": 50, "int": 50, "ref": 50
	}

	# Act / Assert
	for option_id: int in range(4):
		var saw_success: bool = false
		var saw_failure: bool = false
		for seed_value: int in range(1, 201):
			act.rng.seed = seed_value
			var result: Dictionary = act.resolve_encounter(
				option_id, "drone_patrulha", current_stats
			)
			var succeeded: bool = bool(result.get("success", false))
			var stress_pair: Array = option_stress[option_id]
			var extra_stress: int = int(stress_pair[0] if succeeded else stress_pair[1])
			assert_int(result.get("stress_delta", -1)).is_equal(4 + extra_stress)
			saw_success = saw_success or succeeded
			saw_failure = saw_failure or not succeeded
			if saw_success and saw_failure:
				break
		assert_bool(saw_success).is_true()
		assert_bool(saw_failure).is_true()


func test_flee_uses_stamina_and_refinement_instead_of_always_succeeding() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()
	act.rng.seed = 17

	# Act
	var result: Dictionary = act.resolve_encounter(
		ActivitySystem.EncounterOption.FLEE,
		"drone_patrulha",
		{"sta": 40, "ref": 30}
	)

	# Assert: 50 + floor((40 - 50) / 2) + floor(30 / 10) = 48.
	assert_int(result.get("success_chance", -1)).is_equal(48)


func test_hide_uses_intelligence_and_charisma_instead_of_always_succeeding() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()
	act.rng.seed = 23

	# Act
	var result: Dictionary = act.resolve_encounter(
		ActivitySystem.EncounterOption.HIDE,
		"drone_patrulha",
		{"int": 40, "cha": 30}
	)

	# Assert: 50 + floor((40 - 50) / 2) + floor(30 / 10) = 48.
	assert_int(result.get("success_chance", -1)).is_equal(48)


func test_mission_attribute_requirement_blocks_underqualified_nyx() -> void:
	# Arrange
	var act: ActivitySystem = _make_encounter_activity_system()

	# Act
	var result: Dictionary = act.resolve_mission(
		"missao_fisica_drones",
		{"str": 15, "int": 26, "cha": 15, "ref": 15, "sta": 20, "eth": 50}
	)

	# Assert
	assert_bool(result.has("error")).is_true()


func _make_encounter_activity_system() -> ActivitySystem:
	var act: ActivitySystem = ActivitySystem.new()
	act.load_missions("res://assets/data/missions.json")
	act.load_monsters("res://assets/data/monsters.json")
	act.load_encounter_rules("res://assets/data/encounter_rules.json")
	return act

func test_job_streak_tracking() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act - First use
	act.increment_job_streak("trabalho_reparo_leve")
	var streak1 = act.get_job_streak("trabalho_reparo_leve")

	# Assert
	assert_int(streak1).is_equal(1)

	# Act - Increment again
	act.increment_job_streak("trabalho_reparo_leve")
	var streak2 = act.get_job_streak("trabalho_reparo_leve")

	# Assert
	assert_int(streak2).is_equal(2)

func test_get_available_courses_returns_only_study() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var available = act.get_available_courses()

	# Assert - Should include curso_tecnologia, curso_comunicacao, curso_artes
	assert_bool(available.has("curso_tecnologia")).is_true()
	assert_bool(available.has("curso_comunicacao")).is_true()
	assert_bool(available.has("curso_artes")).is_true()

func test_get_available_tasks_returns_only_work() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_activities("res://assets/data/activities.json")

	# Act
	var available = act.get_available_tasks()

	# Assert - Should include work tasks
	assert_bool(available.has("trabalho_reparo_leve")).is_true()
	assert_bool(available.has("trabalho_entrega_assistida")).is_true()
	assert_bool(available.has("trabalho_apoio_comunitario")).is_true()

func test_get_available_missions_returns_all_missions() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_missions("res://assets/data/missions.json")

	# Act
	var available = act.get_available_missions()

	# Assert - Should include all 5 mission types
	assert_int(available.size()).is_equal(5)
	assert_bool(available.find("missao_fisica_ruinas") != -1).is_true()
	assert_bool(available.find("missao_fisica_drones") != -1).is_true()
	assert_bool(available.find("missao_fisica_infiltracao") != -1).is_true()
	assert_bool(available.find("missao_tecnica") != -1).is_true()
	assert_bool(available.find("missao_comunitaria") != -1).is_true()

func test_get_available_leisure_returns_descanso_and_passeio() -> void:
	# Arrange
	var act = ActivitySystem.new()

	# Act
	var available = act.get_available_leisure()

	# Assert
	assert_int(available.size()).is_equal(2)
	assert_bool(available.find("descanso") != -1).is_true()
	assert_bool(available.find("passeio_comunitario") != -1).is_true()