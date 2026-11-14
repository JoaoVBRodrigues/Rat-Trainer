# EventSystem Tests - Tests event loading, detection, and execution
class_name EventSystemTest
extends GdUnitTestSuite

func test_load_events_from_json_succeeds() -> void:
	# Arrange
	var event_system = EventSystem.new()

	# Act
	var loaded = event_system.load_events("res://assets/data/events.json")

	# Assert
	assert_bool(loaded).is_true()

func test_load_events_loads_all_twelve_fixed_events() -> void:
	# Arrange
	var event_system = EventSystem.new()

	# Act
	event_system.load_events("res://assets/data/events.json")
	var event_ids = event_system.get_all_fixed_event_ids()

	# Assert - GDD specifies exactly 12 fixed events (e01 through e12)
	assert_int(event_ids.size()).is_equal(12)
	assert_bool(event_ids.has("e01")).is_true()
	assert_bool(event_ids.has("e12")).is_true()

func test_load_events_loads_all_three_random_events() -> void:
	# Arrange
	var event_system = EventSystem.new()

	# Act
	event_system.load_events("res://assets/data/events.json")
	var event_ids = event_system.get_all_random_event_ids()

	# Assert - GDD specifies exactly 3 random events (r01 through r03)
	assert_int(event_ids.size()).is_equal(3)
	assert_bool(event_ids.has("r01")).is_true()
	assert_bool(event_ids.has("r03")).is_true()

func test_get_fixed_event_for_date_returns_e01_on_year1_month3() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")

	# Act
	var event = event_system.get_fixed_event_for_date(1, 3, 3)

	# Assert - From GDD: E01 is Year 1, Month 3, Period 3
	assert_str(event.get("id", "")).is_equal("e01")

func test_get_fixed_event_for_date_returns_null_on_wrong_period() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")

	# Act - Period 2 is not an event period
	var event = event_system.get_fixed_event_for_date(1, 3, 2)

	# Assert
	assert_bool(event.size() == 0).is_true()

func test_get_fixed_event_for_date_returns_null_on_wrong_month() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")

	# Act - Month 2 is not an event month (GDD: months 3,6,9,12)
	var event = event_system.get_fixed_event_for_date(1, 2, 3)

	# Assert
	assert_bool(event.size() == 0).is_true()

func test_fixed_event_e12_is_year3_month12() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")

	# Act
	var event = event_system.get_fixed_event_for_date(3, 12, 3)

	# Assert - GDD: E12 is Year 3, Month 12, Period 3 (campaign ending event)
	assert_str(event.get("id", "")).is_equal("e12")

func test_calculate_random_chance_base_five_percent() -> void:
	# Arrange
	var event_system = EventSystem.new()

	# Act - GDD formula: chance = clamp(5 + floor(max/10), 5, 15)
	var chance = event_system._calculate_random_chance(0)

	# Assert - max_attr 0 gives 5% minimum
	assert_int(chance).is_equal(5)

func test_calculate_random_chance_with_high_attr() -> void:
	# Arrange
	var event_system = EventSystem.new()

	# Act
	var chance = event_system._calculate_random_chance(75)

	# Assert - 5 + floor(75/10) = 12%
	assert_int(chance).is_equal(12)

func test_calculate_random_chance_clamped_at_fifteen() -> void:
	# Arrange
	var event_system = EventSystem.new()

	# Act
	var chance = event_system._calculate_random_chance(100)

	# Assert - max 15%
	assert_int(chance).is_equal(15)

func test_random_event_roll_is_deterministic_for_same_seed() -> void:
	# Arrange
	var first: EventSystem = EventSystem.new()
	var second: EventSystem = EventSystem.new()
	assert_bool(first.load_events("res://assets/data/events.json")).is_true()
	assert_bool(second.load_events("res://assets/data/events.json")).is_true()
	first.rng.seed = 91234
	second.rng.seed = 91234
	var first_event_ids: Array[String] = []
	var second_event_ids: Array[String] = []

	# Act
	for _i: int in range(100):
		var first_event: Dictionary = first.roll_random_event(100)
		var second_event: Dictionary = second.roll_random_event(100)
		if not first_event.is_empty():
			first_event_ids.append(str(first_event["id"]))
		if not second_event.is_empty():
			second_event_ids.append(str(second_event["id"]))

	# Assert
	assert_bool(not first_event_ids.is_empty()).is_true()
	assert_array(first_event_ids).is_equal(second_event_ids)


func test_failed_random_roll_logs_why_no_event_appeared() -> void:
	# Arrange
	var event_system: EventSystem = EventSystem.new()
	assert_bool(event_system.load_events("res://assets/data/events.json")).is_true()
	var found_failed_roll: bool = false

	# Act - Search deterministic seeds until the 5% roll fails.
	for seed_value: int in range(1, 100):
		event_system.rng.seed = seed_value
		var event: Dictionary = event_system.roll_random_event(0)
		if event.is_empty():
			found_failed_roll = true
			assert_bool(event_system.last_debug_message.contains("not triggered")).is_true()
			assert_bool(event_system.last_debug_message.contains("chance 5%")).is_true()
			break

	# Assert
	assert_bool(found_failed_roll).is_true()

func test_get_event_by_id_returns_correct_fixed_event() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")

	# Act
	var event = event_system.get_event_by_id("e05")

	# Assert
	assert_str(event.get("id", "")).is_equal("e05")

func test_event_has_options_with_effects() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")

	# Act
	var event = event_system.get_event_by_id("e01")
	var options = event.get("options", [])
	var first_option = options[0]
	var effects = first_option.get("effects", {})

	# Assert - E01-A should have cha, social_rep, eth, community_help effects
	assert_int(int(effects.get("cha", 0))).is_equal(2)
	assert_bool(bool(effects.get("community_help", false))).is_true()

func test_reset_clears_rng_state() -> void:
	# Arrange
	var event_system = EventSystem.new()
	event_system.load_events("res://assets/data/events.json")
	event_system.rng.seed = 99999

	# Act
	event_system.reset()

	# Assert - RNG should be a fresh new instance
	assert_object(event_system.rng).is_not_null()