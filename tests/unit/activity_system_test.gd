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

func test_mission_fisica_has_str_test_no_auto_success() -> void:
	# Arrange
	var act = ActivitySystem.new()
	act.load_missions("res://assets/data/missions.json")

	# Act
	var result = act.execute_mission("missao_fisica", 15, 50, 42)  # Base stats

	# Assert
	assert_str(result.get("mission_type")).is_equal("physical")
	assert_int(result.get("success_chance")).is_equal(20)

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
	var act = ActivitySystem.new()
	act.load_missions("res://assets/data/missions.json")

	# Act
	var result = act.execute_mission("missao_fisica", 15, 50, 42)

	# Assert - Physical mission base stress is 4
	assert_int(result.get("stress_delta")).is_equal(4)

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

	# Assert - Should include all 3 mission types
	assert_int(available.size()).is_equal(3)
	assert_bool(available.find("missao_fisica") != -1).is_true()
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