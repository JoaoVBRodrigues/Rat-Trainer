extends GdUnitTestSuite

func test_loader_loads_all_json() -> void:
	var loader_class := preload("res://src/data/DataLoader.gd")
	var data: DataLoader = loader_class.load_all()

	assert_object(data).is_not_null()
	assert_bool(data.is_valid()).is_true()
	assert_int(data.activities.size()).is_greater(0)
	assert_int(data.items.size()).is_greater(0)
	assert_int(data.events.size()).is_greater(0)
	assert_int(data.endings.size()).is_greater(0)
	assert_int(data.missions.size()).is_greater(0)

func test_validator_reports_duplicate_model_ids() -> void:
	var activities: Array = []
	var duplicate1 := ActivityDef.new()
	duplicate1.id = "test_id"
	var duplicate2 := ActivityDef.new()
	duplicate2.id = "test_id"
	activities.append(duplicate1)
	activities.append(duplicate2)

	var errors: Array[String] = DataValidator.validate_unique_ids(activities, "activities")

	assert_int(errors.size()).is_greater(0)
	assert_str(errors[0]).contains("duplicate ID 'test_id'")