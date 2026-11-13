extends GdUnitTestSuite

func test_character_state_default_values() -> void:
	# Arrange
	var state := CharacterState.new()

	# Assert
	assert_int(state.stats["str"]).is_equal(15)
	assert_int(state.stats["int"]).is_equal(15)
	assert_int(state.stats["cha"]).is_equal(15)
	assert_int(state.stats["ref"]).is_equal(15)
	assert_int(state.stats["sta"]).is_equal(20)
	assert_int(state.stats["eth"]).is_equal(50)  # Per MVP decisions: ETH starts at 50
	assert_int(state.age).is_equal(12)
	assert_int(state.current_year).is_equal(1)
	assert_int(state.current_month).is_equal(1)
	assert_array(state.inventory).is_empty()
	assert_int(state.credits).is_equal(0)

func test_character_state_serialization() -> void:
	# Arrange
	var state := CharacterState.new()
	state.stats["str"] = 50
	state.credits = 100
	state.stress = 20
	state.tech_experiments = true
	state.community_help = true

	# Act
	var dict: Dictionary = state.to_dict()
	var restored: CharacterState = CharacterState.from_dict(dict)

	# Assert
	assert_int(restored.stats["str"]).is_equal(50)
	assert_int(restored.credits).is_equal(100)
	assert_int(restored.stress).is_equal(20)
	assert_bool(restored.tech_experiments).is_true()
	assert_bool(restored.community_help).is_true()

func test_character_state_flags() -> void:
	# Arrange
	var state := CharacterState.new()

	# Assert initial flag values
	assert_bool(state.tech_experiments).is_false()
	assert_bool(state.criminal_record).is_false()
	assert_bool(state.community_help).is_false()
	assert_bool(state.disappear_from_society).is_false()

	# Act - set flags
	state.tech_experiments = true
	state.criminal_record = true
	state.community_help = true
	state.disappear_from_society = true

	# Assert
	assert_bool(state.tech_experiments).is_true()
	assert_bool(state.criminal_record).is_true()
	assert_bool(state.community_help).is_true()
	assert_bool(state.disappear_from_society).is_true()