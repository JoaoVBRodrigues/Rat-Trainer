extends GdUnitTestSuite

const DATA_FILES: Array[String] = [
	"schema_version.json",
	"calendar.json",
	"stats.json",
	"activities.json",
	"items.json",
	"shops.json",
	"events.json",
	"endings.json",
	"missions.json",
	"monsters.json",
	"encounter_rules.json"
]

var _fixture_paths: Array[String] = []


func after_test() -> void:
	for fixture_path in _fixture_paths:
		for file_name in DATA_FILES:
			var file_path: String = fixture_path.path_join(file_name)
			if FileAccess.file_exists(file_path):
				var remove_error: Error = DirAccess.remove_absolute(
					ProjectSettings.globalize_path(file_path)
				)
				assert_int(remove_error).is_equal(OK)
		var remove_dir_error: Error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(fixture_path)
		)
		assert_int(remove_dir_error).is_equal(OK)
	_fixture_paths.clear()


func test_real_data_loads_without_errors() -> void:
	# Arrange
	var loader: DataLoader = DataLoader.load_all()

	# Assert
	assert_bool(loader.is_valid()).is_true()
	assert_array(loader.validation_errors).is_empty()
	assert_int(loader.activities.size()).is_equal(8)
	assert_int(loader.items.size()).is_equal(3)
	assert_int(loader.events.size()).is_equal(12)
	assert_int(loader.random_events.size()).is_equal(3)
	assert_int(loader.endings.size()).is_equal(15)
	assert_int(loader.missions.size()).is_equal(5)
	assert_int(loader.monsters.size()).is_equal(3)
	assert_int(loader.stats.size()).is_equal(6)
	assert_bool(loader.encounter_rules.has("encounter_rules")).is_true()


func test_all_data_files_are_utf8_json() -> void:
	for file_name in DATA_FILES:
		var file_path: String = "res://assets/data".path_join(file_name)
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		assert_object(file).is_not_null()
		var parser := JSON.new()
		assert_int(parser.parse(file.get_as_text())).is_equal(OK)
		file.close()


func test_stats_match_mvp_initial_values() -> void:
	var loader: DataLoader = DataLoader.load_all()
	var expected_starts: Dictionary = {
		"str": 15, "int": 15, "cha": 15, "ref": 15, "sta": 20, "eth": 50
	}
	var found_stats: Dictionary = {}

	for stat in loader.stats:
		var stat_id: String = stat.get("id", "")
		found_stats[stat_id] = true
		assert_int(int(stat.get("start", -1))).is_equal(expected_starts[stat_id])

	assert_int(found_stats.size()).is_equal(expected_starts.size())


func test_study_courses_have_gdd_gains_per_level() -> void:
	var loader: DataLoader = DataLoader.load_all()
	var communication_course: ActivityDef

	for activity in loader.activities:
		if activity.type == "study":
			assert_bool(activity.gains.has("l1")).is_true()
			assert_bool(activity.gains.has("l2")).is_true()
			assert_bool(activity.gains.has("l3")).is_true()
			for level in ["l1", "l2", "l3"]:
				assert_bool(activity.gain_for_level(int(level.substr(1))).is_empty()).is_false()
		if activity.id == "curso_comunicacao":
			communication_course = activity

	assert_object(communication_course).is_not_null()
	assert_float(float(communication_course.gain_for_level(1)["cha"])).is_equal(8.0)
	assert_float(float(communication_course.gain_for_level(1)["ref"])).is_equal(5.0)


func test_calendar_has_108_decisions() -> void:
	var loader: DataLoader = DataLoader.load_all()
	assert_float(float(loader.calendar.get("years", 0))).is_equal(3.0)
	assert_float(float(loader.calendar.get("months", 0))).is_equal(12.0)
	assert_float(float(loader.calendar.get("periods", 0))).is_equal(3.0)
	assert_int(
		int(loader.calendar["years"]) * int(loader.calendar["months"]) * int(loader.calendar["periods"])
	).is_equal(108)


func test_items_match_the_three_mvp_items() -> void:
	var loader: DataLoader = DataLoader.load_all()
	var item_ids: Array[String] = []
	for item in loader.items:
		item_ids.append(item.id)
		assert_bool(item.cost > 0).is_true()

	assert_array(item_ids).contains_exactly_in_any_order(
		"kit_ferramentas", "casaco_acolchoado", "adesivo_recuperacao"
	)
	assert_int(loader.shops.size()).is_equal(3)
	assert_int(loader.inventory_limit).is_equal(10)


func test_fixed_events_use_the_approved_calendar() -> void:
	var loader: DataLoader = DataLoader.load_all()
	var expected_months: Array[int] = [3, 6, 9, 12]
	var fixed_event_ids: Dictionary = {}

	for event in loader.events:
		assert_bool(expected_months.has(event.month)).is_true()
		assert_int(event.period).is_equal(3)
		fixed_event_ids[event.id] = true

	assert_int(fixed_event_ids.size()).is_equal(12)
	assert_int(loader.random_events.size()).is_equal(3)


func test_endings_match_the_approved_count_and_reachable_thresholds() -> void:
	var loader: DataLoader = DataLoader.load_all()
	assert_int(loader.endings.size()).is_equal(15)

	var corporate: EndingDef = _find_ending(loader.endings, "promessa_corporativa")
	assert_object(corporate).is_not_null()
	assert_float(float(corporate.conditions["eth_max"])).is_equal(30.0)
	assert_bool(corporate.conditions.has("eth_lt")).is_false()

	var recruit: EndingDef = _find_ending(loader.endings, "recruta_do_submundo")
	assert_object(recruit).is_not_null()
	assert_float(float(recruit.conditions["eth_max"])).is_equal(35.0)
	assert_bool(recruit.conditions.has("eth_lt")).is_false()


func test_missions_match_gdd_success_effects() -> void:
	var loader: DataLoader = DataLoader.load_all()
	assert_int(loader.missions.size()).is_equal(5)

	var physical_ruins: MissionDef = _find_mission(loader.missions, "missao_fisica_ruinas")
	assert_object(physical_ruins).is_not_null()
	assert_float(float(physical_ruins.success_effects["str"])).is_equal(2.0)
	assert_float(float(physical_ruins.success_effects["fighter_rep"])).is_equal(5.0)
	assert_bool(physical_ruins.success_effects.has("int")).is_false()

	var physical_drones: MissionDef = _find_mission(loader.missions, "missao_fisica_drones")
	assert_object(physical_drones).is_not_null()
	assert_int(physical_drones.difficulty).is_equal(50)
	assert_int(physical_drones.minimum_attribute).is_equal(27)
	assert_array(physical_drones.required_equipment).contains_exactly_in_any_order(
		"kit_ferramentas"
	)

	var physical_infil: MissionDef = _find_mission(loader.missions, "missao_fisica_infiltracao")
	assert_object(physical_infil).is_not_null()
	assert_int(physical_infil.difficulty).is_equal(60)
	assert_float(float(physical_infil.success_effects["credits"])).is_equal(35.0)
	assert_int(physical_infil.minimum_attribute).is_equal(25)
	assert_array(physical_infil.required_equipment).contains_exactly_in_any_order(
		"kit_ferramentas", "casaco_acolchoado"
	)
	var encounter_rules: Dictionary = loader.encounter_rules["encounter_rules"]
	var chance: Dictionary = encounter_rules["chance"]
	assert_float(float(chance["base"])).is_equal(50.0)
	assert_float(float(chance["minimum"])).is_equal(5.0)
	assert_float(float(chance["maximum"])).is_equal(95.0)
	assert_float(float(chance["equipment_bonus_per_item"])).is_equal(5.0)
	assert_float(float(chance["maximum_equipment_bonus"])).is_equal(10.0)
	assert_float(float(encounter_rules["drop"]["chance_percent"])).is_equal(25.0)


func test_duplicate_id_in_json_fixture_is_rejected() -> void:
	# Arrange
	var fixture_path: String = _create_fixture_data()
	assert_bool(not fixture_path.is_empty()).is_true()
	var activities_path: String = fixture_path.path_join("activities.json")
	var activity_data: Dictionary = _read_json_object(activities_path)
	var activities: Array = activity_data["activities"]
	activities.append(activities[0].duplicate(true))
	assert_bool(_write_json_object(activities_path, activity_data)).is_true()

	# Act
	var loader: DataLoader = DataLoader.load_all(fixture_path)

	# Assert
	assert_bool(loader.is_valid()).is_false()
	assert_bool(_errors_contain(loader.validation_errors, "duplicate ID 'curso_tecnologia'")).is_true()


func test_new_course_loads_from_json_with_multiple_attribute_gains() -> void:
	# Arrange
	var fixture_path: String = _create_fixture_data()
	assert_bool(not fixture_path.is_empty()).is_true()
	var activities_path: String = fixture_path.path_join("activities.json")
	var activity_data: Dictionary = _read_json_object(activities_path)
	activity_data["activities"].append({
		"id": "curso_fixture",
		"type": "study",
		"name": "Curso de teste",
		"gains": {
			"l1": {"cha": 5, "ref": 4},
			"l2": {"cha": 8, "ref": 7},
			"l3": {"cha": 11, "ref": 10}
		},
		"cost_l1": 5,
		"cost_l2": 10,
		"cost_l3": 15,
		"stress": 2
	})
	assert_bool(_write_json_object(activities_path, activity_data)).is_true()

	# Act
	var loader: DataLoader = DataLoader.load_all(fixture_path)
	var course: ActivityDef = _find_activity(loader.activities, "curso_fixture")

	# Assert
	assert_bool(loader.is_valid()).is_true()
	assert_object(course).is_not_null()
	assert_float(float(course.gain_for_level(1)["cha"])).is_equal(5.0)
	assert_float(float(course.gain_for_level(1)["ref"])).is_equal(4.0)
	assert_float(float(course.gain_for_level(3)["cha"])).is_equal(11.0)
	assert_float(float(course.gain_for_level(3)["ref"])).is_equal(10.0)


func test_missing_calendar_key_fails_loading_explicitly() -> void:
	# Arrange
	var fixture_path: String = _create_fixture_data()
	assert_bool(not fixture_path.is_empty()).is_true()
	var calendar_path: String = fixture_path.path_join("calendar.json")
	assert_bool(
		_write_json_object(calendar_path, {"schema_version": 1, "wrong_key": {}})
	).is_true()

	# Act
	var loader: DataLoader = DataLoader.load_all(fixture_path)

	# Assert
	assert_bool(loader.is_valid()).is_false()
	assert_bool(_errors_contain(loader.validation_errors, "missing required key 'calendar'")).is_true()


func _create_fixture_data() -> String:
	var fixture_path: String = "user://data_integration_%d" % Time.get_ticks_usec()
	var absolute_path: String = ProjectSettings.globalize_path(fixture_path)
	if DirAccess.make_dir_recursive_absolute(absolute_path) != OK:
		return ""
	_fixture_paths.append(fixture_path)

	for file_name in DATA_FILES:
		var source_path: String = "res://assets/data".path_join(file_name)
		var destination_path: String = fixture_path.path_join(file_name)
		var source_file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
		if source_file == null:
			return ""
		var contents: PackedByteArray = source_file.get_buffer(source_file.get_length())
		source_file.close()
		var destination_file: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
		if destination_file == null:
			return ""
		destination_file.store_buffer(contents)
		destination_file.close()
	return fixture_path


func _read_json_object(file_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_result: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_result != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _write_json_object(file_path: String, data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func _errors_contain(errors: Array[String], fragment: String) -> bool:
	for error_message in errors:
		if error_message.contains(fragment):
			return true
	return false


func _find_activity(activities: Array, activity_id: String) -> ActivityDef:
	for activity in activities:
		if activity.id == activity_id:
			return activity
	return null


func _find_ending(endings: Array, ending_id: String) -> EndingDef:
	for ending in endings:
		if ending.id == ending_id:
			return ending
	return null


func _find_mission(missions: Array, mission_id: String) -> MissionDef:
	for mission in missions:
		if mission.id == mission_id:
			return mission
	return null
