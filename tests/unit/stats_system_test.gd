# GDD: Test Cases
class_name StatsSystemTest
extends GdUnitTestSuite

# StatsSystem Tests - Tests attribute stat, stress, disease, and reputation mechanics

func test_initialize_sets_default_stat_values() -> void:
	# Arrange
	var stats = StatsSystem.new()

	# Act
	stats.initialize()

	# Assert - from GDD: STR 15, INT 15, CHA 15, REF 15, STA 20, ETH 50
	assert_int(stats.get_stat("str")).is_equal(15)
	assert_int(stats.get_stat("int")).is_equal(15)
	assert_int(stats.get_stat("cha")).is_equal(15)
	assert_int(stats.get_stat("ref")).is_equal(15)
	assert_int(stats.get_stat("sta")).is_equal(20)
	assert_int(stats.get_stat("eth")).is_equal(50)

func test_disease_threshold_uses_stamina_value() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("sta", 20)

	# Assert - disease threshold from GDD: 60 + floor(STA/5)
	assert_int(stats.get_disease_threshold()).is_equal(64)

func test_add_stat_applies_clamp_on_overflow() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("int", 96)

	# Act - Add 12, should clamp to 100
	var actual_delta = stats.add_stat("int", 12)

	# Assert
	assert_int(actual_delta).is_equal(4)  # Only 4 points actually added
	assert_int(stats.get_stat("int")).is_equal(100)

func test_add_stat_applies_clamp_on_underflow() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("eth", 3)

	# Act - Subtract 5, should clamp to 0
	var actual_delta = stats.add_stat("eth", -5)

	# Assert
	assert_int(actual_delta).is_equal(-3)  # Only 3 points actually removed
	assert_int(stats.get_stat("eth")).is_equal(0)

func test_disease_starts_when_stress_at_or_above_threshold() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("sta", 20)  # Threshold = 64

	# Act & Assert - Not diseased at threshold
	stats.set_stress(64)
	stats.check_and_update_disease()
	assert_bool(stats.check_disease_state()).is_true()

	# Act - Still diseased above threshold
	stats.add_stress(10)
	assert_bool(stats.check_disease_state()).is_equal(stats.is_at_or_above_disease_threshold())

func test_disease_does_not_remove_periods() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("sta", 20)
	stats.set_stress(70)  # Above threshold
	stats.check_and_update_disease()

	# Assert - Disease should not affect period counter
	# (This is tested in SimulationCore, but we verify disease state is tracked)
	assert_bool(stats.check_disease_state()).is_true()

func test_stress_adds_and_clamps_to_100() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stress(95)

	# Act - Add stress that would exceed 100
	var actual_delta = stats.add_stress(10)

	# Assert
	assert_int(actual_delta).is_equal(5)  # Only 5 added
	assert_int(stats.get_stress()).is_equal(100)

func test_stress_can_recover_from_100() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stress(100)

	# Act - Stress recovery
	stats.add_stress(-20)

	# Assert
	assert_int(stats.get_stress()).is_equal(80)

func test_reputation_adds_and_clamps() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()

	# Act & Assert - Fighter reputation
	assert_int(stats.get_reputation("fighter")).is_equal(0)
	stats.add_reputation("fighter", 5)
	assert_int(stats.get_reputation("fighter")).is_equal(5)

	# Act - Clamp on overflow
	stats.set_reputation("fighter", 100)
	stats.add_reputation("fighter", 10)

	# Assert
	assert_int(stats.get_reputation("fighter")).is_equal(100)

func test_mission_blocked_when_diseased() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stress(80)  # High stress
	stats.check_and_update_disease()

	# Act
	var can_mission = stats.is_mission_blocked_by_disease()

	# Assert
	assert_bool(can_mission).is_true()

func test_missions_available_when_not_diseased() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stress(30)  # Below threshold
	stats.check_and_update_disease()

	# Assert
	assert_bool(stats.is_mission_blocked_by_disease()).is_false()

func test_sta_change_recalculates_threshold() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("sta", 100)
	stats._recalculate_threshold()

	# Assert - Threshold from GDD: 60 + floor(100/5) = 80
	assert_int(stats.get_disease_threshold()).is_equal(80)

func test_get_state_captures_all_values() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("str", 25)
	stats.set_stress(42)
	stats.add_reputation("hacker", 15)

	# Act
	var state = stats.get_state()

	# Assert
	assert_int(state.stress).is_equal(42)
	assert_int(state.stats.get("str", 0)).is_equal(25)
	assert_int(state.reputations.get("hacker", 0)).is_equal(15)

func test_load_state_restores_values() -> void:
	# Arrange
	var stats1 = StatsSystem.new()
	stats1.initialize()
	stats1.set_stat("str", 25)
	stats1.set_stress(42)
	stats1.add_reputation("hacker", 15)

	var state = stats1.get_state()

	# Act
	var stats2 = StatsSystem.new()
	stats2.initialize()
	stats2.load_state(state)

	# Assert
	assert_int(stats2.get_stat("str")).is_equal(25)
	assert_int(stats2.get_stress()).is_equal(42)
	assert_int(stats2.get_reputation("hacker")).is_equal(15)

func test_reset_returns_to_initial_state() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("str", 50)
	stats.set_stress(80)
	stats.add_reputation("social", 40)

	# Act
	stats.reset()

	# Assert
	assert_int(stats.get_stat("str")).is_equal(15)
	assert_int(stats.get_stress()).is_equal(0)
	assert_int(stats.get_reputation("social")).is_equal(0)

func test_is_at_or_above_disease_threshold_returns_true() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()
	stats.set_stat("sta", 20)  # Threshold = 64

	# Act & Assert - Exactly at threshold
	stats.set_stress(64)
	assert_bool(stats.is_at_or_above_disease_threshold()).is_true()

	# Act - Below threshold
	stats.set_stress(63)
	assert_bool(stats.is_at_or_above_disease_threshold()).is_false()

func test_check_disease_state_returns_current_disease_state() -> void:
	# Arrange
	var stats = StatsSystem.new()
	stats.initialize()

	# Assert - Initially healthy
	assert_bool(stats.check_disease_state()).is_false()

	# Act - Raise stress above threshold
	stats.set_stat("sta", 20)  # Threshold = 64
	stats.set_stress(70)
	stats.check_and_update_disease()

	# Assert - Now diseased
	assert_bool(stats.check_disease_state()).is_true()