# GDD: Test Cases
class_name EconomySystemTest
extends GdUnitTestSuite

# EconomySystem Tests - Tests credits, costs, and stipend mechanics

func test_new_game_starts_with_no_credits_before_first_stipend() -> void:
	# Arrange
	var econ = EconomySystem.new()

	# Act
	econ.start_new_game()

	# Assert - SimulationCore credits the first stipend before period one.
	assert_int(econ.get_credits()).is_equal(0)

func test_can_afford_returns_true_when_sufficient() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))

	# Act & Assert
	assert_bool(econ.can_afford(100)).is_true()
	assert_bool(econ.can_afford(250)).is_false()

func test_can_afford_returns_false_when_insufficient() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))

	# Act & Assert
	assert_bool(econ.can_afford(300)).is_false()

func test_pay_deducts_credits_when_affordable() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))

	# Act
	var paid = econ.pay(50)

	# Assert
	assert_bool(paid).is_true()
	assert_int(econ.get_credits()).is_equal(150)

func test_pay_returns_false_when_unaffordable() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))

	# Act
	var paid = econ.pay(300)

	# Assert - No negative balance
	assert_bool(paid).is_false()
	assert_int(econ.get_credits()).is_equal(200)

func test_receive_income_adds_credits() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))

	# Act
	econ.receive_income(50)

	# Assert
	assert_int(econ.get_credits()).is_equal(250)

func test_stipend_given_at_start_of_each_year_total_600() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()

	# Act - Credit each stipend once, as SimulationCore does at year start.
	var stipend1 = econ.start_year(1)
	econ.receive_income(stipend1)
	assert_int(stipend1).is_equal(200)

	var stipend2 = econ.start_year(2)
	econ.receive_income(stipend2)
	assert_int(stipend2).is_equal(200)

	var stipend3 = econ.start_year(3)
	econ.receive_income(stipend3)
	assert_int(stipend3).is_equal(200)
	assert_int(econ.start_year(3)).is_equal(0)

	# Assert - Total: 200 + 200 + 200 = 600 credits from stipends
	assert_int(econ.get_credits()).is_equal(600)

func test_get_state_captures_credits() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))
	econ.receive_income(100)

	# Act
	var state = econ.get_state()

	# Assert
	assert_int(state.credits).is_equal(300)

func test_load_state_restores_credits() -> void:
	# Arrange
	var econ1 = EconomySystem.new()
	econ1.start_new_game()
	econ1.receive_income(econ1.start_year(1))
	econ1.receive_income(150)
	var state = econ1.get_state()

	# Act
	var econ2 = EconomySystem.new()
	econ2.load_state(state)

	# Assert
	assert_int(econ2.get_credits()).is_equal(350)

func test_activity_cost_blocked_without_credits() -> void:
	# Arrange
	var econ = EconomySystem.new()
	econ.start_new_game()
	econ.receive_income(econ.start_year(1))

	# Act - Try to pay for expensive activity
	var paid = econ.pay(250)

	# Assert
	assert_bool(paid).is_false()
	assert_int(econ.get_credits()).is_equal(200)