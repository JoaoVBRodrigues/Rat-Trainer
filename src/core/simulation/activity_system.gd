extends RefCounted
class_name ActivitySystem

enum ActivityType { NONE, STUDY, WORK, MISSION, LEISURE }

const XP_PER_SESSION: int = 10
const JOB_TASK_IDS: Array[String] = [
	"trabalho_reparo_leve",
	"trabalho_entrega_assistida",
	"trabalho_apoio_comunitario"
]
const MISSION_REWARD_KEYS: Dictionary = {
	"fighter_rep": "fighter",
	"social_rep": "social",
	"hacker_rep": "hacker"
}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _activities: Dictionary = {}
var _missions: Dictionary = {}
var _course_xp: Dictionary = {}
var _job_streaks: Dictionary = {}
var _job_levels: Dictionary = {}
var _job_tasks_used_this_month: Dictionary = {}
var _missions_technical_completed: int = 0


func load_activities(json_path: String) -> bool:
	var records: Array = _read_records(json_path, "activities")
	if records.is_empty():
		return false
	var loaded: Dictionary = {}
	for index: int in records.size():
		var record: Variant = records[index]
		if not record is Dictionary or not record.get("id") is String:
			push_error("%s: activities[%d] must have a string ID." % [json_path, index])
			return false
		var id: String = record["id"]
		if loaded.has(id):
			push_error("%s: duplicate activity ID '%s'." % [json_path, id])
			return false
		loaded[id] = record.duplicate(true)
	_activities = loaded
	_initialize_job_state()
	return true


func load_missions(json_path: String) -> bool:
	var records: Array = _read_records(json_path, "missions")
	if records.is_empty():
		return false
	var loaded: Dictionary = {}
	for index: int in records.size():
		var record: Variant = records[index]
		if not record is Dictionary or not record.get("id") is String:
			push_error("%s: missions[%d] must have a string ID." % [json_path, index])
			return false
		var id: String = record["id"]
		if loaded.has(id):
			push_error("%s: duplicate mission ID '%s'." % [json_path, id])
			return false
		loaded[id] = record.duplicate(true)
	_missions = loaded
	return true


func get_course(course_id: String) -> Dictionary:
	var record: Variant = _activities.get(course_id, {})
	return record.duplicate(true) if record is Dictionary else {}


func get_mission(mission_id: String) -> Dictionary:
	var record: Variant = _missions.get(mission_id, {})
	return record.duplicate(true) if record is Dictionary else {}


func execute_study(course_id: String, level: int, _optional_rng_seed: int = 0) -> Dictionary:
	var course: Dictionary = get_course(course_id)
	if course.is_empty() or course.get("type") != "study":
		return {"error": "Invalid study course: %s" % course_id}
	if level < 1 or level > 3:
		return {"error": "Study level must be between 1 and 3."}
	var gains: Variant = course.get("gains", {}).get("l%d" % level)
	var cost: Variant = course.get("cost_l%d" % level)
	if not gains is Dictionary or not _is_integer_value(cost):
		return {"error": "Study course '%s' has incomplete level %d data." % [course_id, level]}
	var normalized_gains: Dictionary = _normalize_integer_dictionary(gains)
	if normalized_gains.is_empty():
		return {"error": "Study course '%s' has invalid level %d gains." % [course_id, level]}
	return {
		"activity_type": ActivityType.STUDY,
		"activity_id": course_id,
		"level": level,
		"stat_gains": normalized_gains,
		"cost": int(cost),
		"stress_delta": int(course.get("stress", 0)),
		"xp_gain": XP_PER_SESSION
	}


func get_course_cost(course_id: String, level: int) -> int:
	var course: Dictionary = get_course(course_id)
	var cost: Variant = course.get("cost_l%d" % level, 0)
	return int(cost) if _is_integer_value(cost) else 0


func get_course_gains(course_id: String, level: int) -> Dictionary:
	var course: Dictionary = get_course(course_id)
	var gains: Variant = course.get("gains", {}).get("l%d" % level, {})
	return _normalize_integer_dictionary(gains) if gains is Dictionary else {}


func get_course_xp(course_id: String) -> int:
	return int(_course_xp.get(course_id, 0))


func get_course_level(course_id: String) -> int:
	var xp: int = get_course_xp(course_id)
	if xp >= 250:
		return 3
	if xp >= 100:
		return 2
	return 1


func add_course_xp(course_id: String, amount: int = XP_PER_SESSION) -> int:
	if not _activities.has(course_id) or amount < 0:
		push_error("Cannot award XP to unknown course '%s' or with negative XP." % course_id)
		return 0
	var previous_xp: int = get_course_xp(course_id)
	var updated_xp: int = mini(previous_xp + amount, 250)
	_course_xp[course_id] = updated_xp
	return updated_xp - previous_xp


func execute_work(task_id: String, level: int = 1, _optional_rng_seed: int = 0) -> Dictionary:
	var task: Dictionary = get_course(task_id)
	if task.is_empty() or task.get("type") != "work":
		return {"error": "Invalid work task: %s" % task_id}
	if level < 1 or level > 2:
		return {"error": "Work level must be 1 or 2."}
	var gains: Variant = task.get("gains", {}).get("l%d" % level)
	var base_income: Variant = task.get("income_l1")
	if not gains is Dictionary or not _is_integer_value(base_income):
		return {"error": "Work task '%s' has incomplete data." % task_id}
	var normalized_gains: Dictionary = _normalize_integer_dictionary(gains)
	if normalized_gains.is_empty():
		return {"error": "Work task '%s' has invalid level %d gains." % [task_id, level]}
	var income: int = int(base_income)
	if level == 2:
		income = floori(float(income) * 1.5)
	return {
		"activity_type": ActivityType.WORK,
		"activity_id": task_id,
		"level": level,
		"stat_gains": normalized_gains,
		"income": income,
		"stress_delta": int(task.get("stress", 0)),
		"cost": 0
	}


func calculate_success_chance(relevant_attr: int, eth: int) -> int:
	return clampi(50 + relevant_attr - 50 + floori(float(eth) / 10.0), 5, 95)


func calculate_physical_success_chance(strength: int, stamina: int, difficulty: int) -> int:
	var strength_modifier: int = floori(float(strength - difficulty) / 2.0)
	return clampi(50 + strength_modifier + floori(float(stamina) / 10.0), 5, 95)


func execute_mission(
	mission_id: String, relevant_attr: int, eth: int, rng_seed: int = 0
) -> Dictionary:
	var mission: Dictionary = get_mission(mission_id)
	if mission.is_empty():
		return {"error": "Invalid mission: %s" % mission_id}
	if rng_seed != 0:
		rng.seed = rng_seed
	var chance: int = calculate_success_chance(relevant_attr, eth)
	var succeeded: bool = roll_mission_success(chance)
	return {
		"activity_type": ActivityType.MISSION,
		"activity_id": mission_id,
		"mission_type": str(mission.get("type", "")),
		"success": succeeded,
		"success_chance": chance,
		"stress_delta": int(mission.get("stress", 0)),
		"success_effects": mission.get("success_effects", {}).duplicate(true) if succeeded else {},
		"cost": 0
	}


func resolve_mission(mission_id: String, current_stats: Dictionary) -> Dictionary:
	var mission: Dictionary = get_mission(mission_id)
	if mission.is_empty():
		return {"error": "Invalid mission: %s" % mission_id}
	var mission_type: String = str(mission.get("type", ""))
	var chance: int
	if mission_type == "physical":
		chance = calculate_physical_success_chance(
			int(current_stats.get("str", 0)),
			int(current_stats.get("sta", 0)),
			int(mission.get("difficulty", 35))
		)
	else:
		var stat_id: String = str(mission.get("stat_test", ""))
		if not current_stats.has(stat_id):
			return {"error": "Mission '%s' references unknown stat '%s'." % [mission_id, stat_id]}
		chance = calculate_success_chance(
			int(current_stats[stat_id]), int(current_stats.get("eth", 0))
		)
	var succeeded: bool = roll_mission_success(chance)
	var effects: Variant = mission.get("success_effects", {})
	if not effects is Dictionary:
		return {"error": "Mission '%s' has invalid success effects." % mission_id}
	var activity_stress: int = int(mission.get("stress", 0))
	var combat_stress: int = 0
	if mission_type == "physical":
		combat_stress = 3 if succeeded else 6
	return {
		"activity_type": ActivityType.MISSION,
		"activity_id": mission_id,
		"mission_type": mission_type,
		"success": succeeded,
		"success_chance": chance,
		"stress_delta": activity_stress + combat_stress,
		"activity_stress": activity_stress,
		"combat_stress": combat_stress,
		"success_effects": effects.duplicate(true) if succeeded else {},
		"cost": 0
	}


func roll_mission_success(chance: int, rng_seed: int = 0) -> bool:
	if rng_seed != 0:
		rng.seed = rng_seed
	return rng.randi_range(0, 99) < clampi(chance, 5, 95)


func execute_leisure(option_id: String, _rng_seed: int = 0) -> Dictionary:
	var aliases: Dictionary = {
		"descanso": "lazer_descanso",
		"passeio_comunitario": "lazer_passeio_comunitario"
	}
	var activity_id: String = str(aliases.get(option_id, option_id))
	var activity: Dictionary = get_course(activity_id)
	if activity.is_empty() or activity.get("type") != "leisure":
		return {"error": "Invalid leisure option: %s" % option_id}
	var gains: Variant = activity.get("gains", {}).get("l1", {})
	if not gains is Dictionary:
		return {"error": "Leisure option '%s' has invalid gains." % activity_id}
	var stat_gains: Dictionary = _normalize_integer_dictionary(gains)
	if stat_gains.is_empty():
		return {"error": "Leisure option '%s' has invalid gains." % activity_id}
	var stress_delta: int = int(stat_gains.get("stress", 0))
	stat_gains.erase("stress")
	return {
		"activity_type": ActivityType.LEISURE,
		"activity_id": activity_id,
		"level": 1,
		"stat_gains": stat_gains,
		"stress_delta": stress_delta,
		"cost": int(activity.get("cost_l1", 0))
	}


func mark_task_used(task_id: String) -> void:
	if _job_tasks_used_this_month.has(task_id):
		_job_tasks_used_this_month[task_id] = true


func increment_job_streak(task_id: String) -> int:
	if not _job_streaks.has(task_id):
		push_error("Unknown job task '%s'." % task_id)
		return 0
	_job_streaks[task_id] = int(_job_streaks[task_id]) + 1
	if int(_job_streaks[task_id]) >= 4:
		_job_levels[task_id] = 2
	return int(_job_streaks[task_id])


func reset_job_streak(task_id: String) -> void:
	if _job_streaks.has(task_id):
		_job_streaks[task_id] = 0


func get_job_streak(task_id: String) -> int:
	return int(_job_streaks.get(task_id, 0))


func get_job_level(task_id: String) -> int:
	return int(_job_levels.get(task_id, 1))


func close_month() -> Dictionary:
	var streaks_incremented: Dictionary = {}
	var promotions: Dictionary = {}
	for task_id: String in JOB_TASK_IDS:
		var was_used: bool = bool(_job_tasks_used_this_month.get(task_id, false))
		var previous_level: int = get_job_level(task_id)
		if was_used:
			streaks_incremented[task_id] = increment_job_streak(task_id)
			if previous_level == 1 and get_job_level(task_id) == 2:
				promotions[task_id] = 2
		else:
			reset_job_streak(task_id)
		_job_tasks_used_this_month[task_id] = false
	return {"streaks_incremented": streaks_incremented, "promotions": promotions}


func get_available_courses() -> Array[String]:
	var result: Array[String] = []
	for id: String in _activities:
		if _activities[id].get("type") == "study":
			result.append(id)
	return result


func get_available_tasks() -> Array[String]:
	var result: Array[String] = []
	for id: String in _activities:
		if _activities[id].get("type") == "work":
			result.append(id)
	return result


func get_available_missions() -> Array[String]:
	var result: Array[String] = []
	for id: String in _missions:
		result.append(id)
	return result


func get_available_leisure() -> Array[String]:
	return ["descanso", "passeio_comunitario"]


func get_state() -> Dictionary:
	return {
		"course_xp": _course_xp.duplicate(true),
		"job_streaks": _job_streaks.duplicate(true),
		"job_levels": _job_levels.duplicate(true),
		"job_tasks_used_this_month": _job_tasks_used_this_month.duplicate(true),
		"missions_technical_completed": _missions_technical_completed
	}


func load_state(state: Dictionary) -> bool:
	var saved_course_xp: Variant = state.get("course_xp", {})
	var saved_job_streaks: Variant = state.get("job_streaks", {})
	var saved_job_levels: Variant = state.get("job_levels", {})
	var saved_tasks_used: Variant = state.get("job_tasks_used_this_month", {})
	var saved_mission_count: Variant = state.get("missions_technical_completed", 0)
	if not saved_course_xp is Dictionary or not saved_job_streaks is Dictionary:
		return false
	if not saved_job_levels is Dictionary or not saved_tasks_used is Dictionary:
		return false
	if not saved_mission_count is int or saved_mission_count < 0:
		return false

	_course_xp.clear()
	for course_id: String in saved_course_xp:
		var xp_value: Variant = saved_course_xp[course_id]
		if not _activities.has(course_id) or not xp_value is int or xp_value < 0 or xp_value > 250:
			return false
		_course_xp[course_id] = xp_value
	_job_streaks.clear()
	_job_levels.clear()
	_job_tasks_used_this_month.clear()
	for task_id: String in JOB_TASK_IDS:
		var streak: Variant = saved_job_streaks.get(task_id, 0)
		var level: Variant = saved_job_levels.get(task_id, 1)
		var used: Variant = saved_tasks_used.get(task_id, false)
		if not streak is int or streak < 0 or not level is int or level < 1 or level > 2:
			return false
		if not used is bool:
			return false
		_job_streaks[task_id] = streak
		_job_levels[task_id] = level
		_job_tasks_used_this_month[task_id] = used
	_missions_technical_completed = saved_mission_count
	return true


func reset() -> void:
	_course_xp.clear()
	_missions_technical_completed = 0
	_initialize_job_state()


func _initialize_job_state() -> void:
	for task_id: String in JOB_TASK_IDS:
		_job_streaks[task_id] = 0
		_job_levels[task_id] = 1
		_job_tasks_used_this_month[task_id] = false


func _read_records(json_path: String, key: String) -> Array:
	if not FileAccess.file_exists(json_path):
		push_error("Data file does not exist: %s." % json_path)
		return []
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Could not open data file: %s." % json_path)
		return []
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Invalid JSON in %s at line %d: %s."
			% [json_path, parser.get_error_line(), parser.get_error_message()]
		)
		return []
	if not parser.data is Dictionary:
		push_error("%s must contain a JSON object." % json_path)
		return []
	var records: Variant = parser.data.get(key)
	if not records is Array:
		push_error("%s is missing the '%s' array." % [json_path, key])
		return []
	return records


static func _is_integer_value(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	var numeric_value: float = float(value)
	return floorf(numeric_value) == numeric_value


static func _normalize_integer_dictionary(values: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key: Variant in values:
		if not key is String or not _is_integer_value(values[key]):
			return {}
		normalized[key] = int(values[key])
	return normalized
