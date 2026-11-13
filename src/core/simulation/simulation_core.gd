extends RefCounted
class_name SimulationCore

const DEFAULT_CALENDAR_PATH: String = "res://assets/data/calendar.json"
const DEFAULT_ACTIVITIES_PATH: String = "res://assets/data/activities.json"
const DEFAULT_MISSIONS_PATH: String = "res://assets/data/missions.json"

var calendar: CalendarSystem
var stats: StatsSystem
var economy: EconomySystem
var activities: ActivitySystem
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var tech_experiments: bool = false
var criminal_record: bool = false
var community_help: bool = false
var disappear_from_society: bool = false
var _missions_technical_completed: int = 0
var _calendar_config_path: String = DEFAULT_CALENDAR_PATH
var _activities_path: String = DEFAULT_ACTIVITIES_PATH
var _missions_path: String = DEFAULT_MISSIONS_PATH


func initialize(
	calendar_config_path: String = DEFAULT_CALENDAR_PATH,
	activities_path: String = DEFAULT_ACTIVITIES_PATH,
	missions_path: String = DEFAULT_MISSIONS_PATH
) -> bool:
	_calendar_config_path = calendar_config_path
	_activities_path = activities_path
	_missions_path = missions_path
	calendar = CalendarSystem.new()
	stats = StatsSystem.new()
	economy = EconomySystem.new()
	activities = ActivitySystem.new()
	if not calendar.initialize_from_config(_calendar_config_path):
		return false
	stats.initialize()
	economy.start_new_game(calendar.years)
	activities.rng = rng
	if not activities.load_activities(_activities_path):
		return false
	if not activities.load_missions(_missions_path):
		return false
	start_new_game()
	return true


func start_new_game() -> void:
	calendar.start_new_game()
	stats.initialize()
	economy.start_new_game(calendar.years)
	activities.reset()
	_reset_campaign_flags()
	_credit_stipend_if_due()


func set_seed(seed_value: int) -> void:
	rng.seed = seed_value
	if activities != null:
		activities.rng = rng


func advance_period(choice: String, period_seed: int = 0) -> PeriodResult:
	var result: PeriodResult = PeriodResult.new()
	if not _systems_are_initialized():
		result.error_message = "SimulationCore must be initialized before advancing."
		return result
	if calendar.is_campaign_complete():
		result.error_message = "Campaign already completed."
		return result
	if period_seed != 0:
		rng.seed = period_seed

	var parsed_choice: Dictionary = _parse_choice(choice)
	if parsed_choice.has("error"):
		result.error_message = str(parsed_choice["error"])
		return result
	if parsed_choice["type"] == "mission" and stats.is_mission_blocked_by_disease():
		result.error_message = "Missions are unavailable while diseased."
		return result

	var activity_result: Dictionary = _resolve_activity(parsed_choice)
	if activity_result.has("error"):
		result.error_message = str(activity_result["error"])
		return result

	var cost: int = int(activity_result.get("cost", 0))
	if not economy.can_afford(cost):
		result.error_message = "Cannot afford activity."
		return result

	result.pre_period_state = get_state()
	result.period = calendar.get_turn_number()
	result.year = calendar.get_year()
	result.month = calendar.get_month()
	result.period_num = calendar.get_period()
	result.age = calendar.get_age()
	result.is_diseased_before = stats.is_diseased
	result.activity_type = int(activity_result["activity_type"])
	result.activity_id = str(activity_result["activity_id"])
	result.activity_level = int(activity_result.get("level", 1))
	result.success_chance = int(activity_result.get("success_chance", 0))
	result.mission_success = bool(activity_result.get("success", false))

	if cost > 0:
		economy.pay(cost)
		result.credits_change -= cost

	var income: int = int(activity_result.get("income", 0))
	if income > 0:
		economy.receive_income(income)
		result.credits_change += income

	_apply_activity_effects(parsed_choice, activity_result, result)
	if calendar.is_month_end():
		var month_result: Dictionary = activities.close_month()
		result.month_end_processed = true
		result.streaks_incremented = month_result["streaks_incremented"]
		result.promotion_unlocked = not month_result["promotions"].is_empty()

	stats.check_and_update_disease()
	result.is_diseased_after = stats.is_diseased
	calendar.advance_period()
	var next_year_stipend: int = _credit_stipend_if_due()
	if next_year_stipend > 0:
		result.year_stipend_given = true
		result.credits_change += next_year_stipend
	result.completed = true
	result.post_period_state = get_state()
	return result


func get_state() -> Dictionary:
	if not _systems_are_initialized():
		return {}
	return {
		"calendar": calendar.get_calendar_state().to_dict(),
		"stats": stats.get_state(),
		"economy": economy.get_state(),
		"activities": activities.get_state(),
		"tech_experiments": tech_experiments,
		"criminal_record": criminal_record,
		"community_help": community_help,
		"disappear_from_society": disappear_from_society,
		"missions_technical_completed": _missions_technical_completed
	}


func load_state(state: Dictionary) -> bool:
	if not _systems_are_initialized():
		return false
	var saved_calendar: Variant = state.get("calendar")
	var saved_stats: Variant = state.get("stats")
	var saved_economy: Variant = state.get("economy")
	var saved_activities: Variant = state.get("activities", {})
	if not saved_calendar is Dictionary or not saved_stats is Dictionary:
		return false
	if not saved_economy is Dictionary or not saved_activities is Dictionary:
		return false

	var calendar_copy: CalendarSystem = CalendarSystem.new()
	if not calendar_copy.initialize_from_config(_calendar_config_path):
		return false
	var stats_copy: StatsSystem = StatsSystem.new()
	stats_copy.initialize()
	var economy_copy: EconomySystem = EconomySystem.new()
	economy_copy.start_new_game(calendar_copy.years)
	var activities_copy: ActivitySystem = ActivitySystem.new()
	if not activities_copy.load_activities(_activities_path):
		return false
	if not activities_copy.load_missions(_missions_path):
		return false
	if not calendar_copy.load_state(saved_calendar):
		return false
	if not stats_copy.load_state(saved_stats):
		return false
	if not economy_copy.load_state(saved_economy):
		return false
	if not activities_copy.load_state(saved_activities):
		return false

	calendar = calendar_copy
	stats = stats_copy
	economy = economy_copy
	activities = activities_copy
	activities.rng = rng
	tech_experiments = bool(state.get("tech_experiments", false))
	criminal_record = bool(state.get("criminal_record", false))
	community_help = bool(state.get("community_help", false))
	disappear_from_society = bool(state.get("disappear_from_society", false))
	var mission_count: Variant = state.get("missions_technical_completed", 0)
	if not mission_count is int or mission_count < 0:
		return false
	_missions_technical_completed = mission_count
	_credit_stipend_if_due()
	return true


func is_campaign_complete() -> bool:
	return calendar != null and calendar.is_campaign_complete()


func get_age() -> int:
	return calendar.get_age() if calendar != null else 12


func get_remaining_periods() -> int:
	return calendar.get_remaining_periods() if calendar != null else 0


func get_available_activities() -> Dictionary:
	if not _systems_are_initialized():
		return {"study": [], "work": [], "mission": [], "leisure": []}
	var available_missions: Array[String] = []
	if not stats.is_mission_blocked_by_disease():
		available_missions = activities.get_available_missions()
	return {
		"study": activities.get_available_courses(),
		"work": activities.get_available_tasks(),
		"mission": available_missions,
		"leisure": activities.get_available_leisure()
	}


func is_mission_available() -> bool:
	return _systems_are_initialized() and not stats.is_mission_blocked_by_disease()


func _credit_stipend_if_due() -> int:
	if not _systems_are_initialized() or not calendar.is_new_year_period():
		return 0
	var stipend_status: Dictionary = economy.get_stipend_status(calendar.get_year())
	if not bool(stipend_status["eligible"]):
		return 0

	var stipend: int = economy.start_year(calendar.get_year())
	if stipend <= 0:
		return 0
	if not economy.receive_income(stipend):
		push_error("Could not credit the yearly stipend for year %d." % calendar.get_year())
		return 0
	return stipend


func _parse_choice(choice: String) -> Dictionary:
	var separator: int = choice.find("_")
	if separator <= 0 or separator == choice.length() - 1:
		return {"error": "Invalid choice '%s'; expected type_ID[_lN][_experiment]." % choice}
	var activity_type: String = choice.substr(0, separator)
	var activity_id: String = choice.substr(separator + 1)
	var experiment: bool = false
	if activity_id.ends_with("_experiment"):
		experiment = true
		activity_id = activity_id.trim_suffix("_experiment")

	var requested_level: int = 0
	var level_marker: int = activity_id.rfind("_l")
	if level_marker >= 0 and level_marker + 3 == activity_id.length():
		var level_text: String = activity_id.substr(level_marker + 2, 1)
		if level_text.is_valid_int():
			requested_level = int(level_text)
			activity_id = activity_id.substr(0, level_marker)

	if activity_type not in ["study", "work", "mission", "leisure"]:
		return {"error": "Unknown activity type '%s'." % activity_type}
	if activity_id.is_empty():
		return {"error": "Activity ID cannot be empty."}
	return {
		"type": activity_type,
		"id": activity_id,
		"level": requested_level,
		"experiment": experiment
	}


func _resolve_activity(parsed_choice: Dictionary) -> Dictionary:
	var activity_type: String = str(parsed_choice["type"])
	var activity_id: String = str(parsed_choice["id"])
	var requested_level: int = int(parsed_choice["level"])
	if activity_type == "study":
		var course: Dictionary = activities.get_course(activity_id)
		if course.is_empty():
			return {"error": "Unknown study course '%s'." % activity_id}
		var level: int = requested_level if requested_level > 0 else activities.get_course_level(activity_id)
		if level > activities.get_course_level(activity_id):
			return {"error": "Study level %d is locked for '%s'." % [level, activity_id]}
		return activities.execute_study(activity_id, level)
	if activity_type == "work":
		var task: Dictionary = activities.get_course(activity_id)
		if task.is_empty():
			return {"error": "Unknown work task '%s'." % activity_id}
		var level: int = activities.get_job_level(activity_id)
		if requested_level > 0 and requested_level != level:
			return {"error": "Work task '%s' is currently level %d." % [activity_id, level]}
		return activities.execute_work(activity_id, level)
	if activity_type == "mission":
		if not activities.get_mission(activity_id).is_empty():
			var mission_result: Dictionary = activities.resolve_mission(
				activity_id, stats.get_base_stats()
			)
			if not mission_result.has("error") and bool(mission_result.get("success", false)):
				var effects: Dictionary = mission_result.get("success_effects", {})
				mission_result["income"] = int(effects.get("credits", 0))
			return mission_result
		return {"error": "Unknown mission '%s'." % activity_id}
	return activities.execute_leisure(activity_id)


func _apply_activity_effects(
	parsed_choice: Dictionary, activity_result: Dictionary, result: PeriodResult
) -> void:
	var activity_type: String = str(parsed_choice["type"])
	var activity_id: String = str(activity_result["activity_id"])
	var stat_gains: Variant = activity_result.get("stat_gains", {})
	if stat_gains is Dictionary:
		for stat_id: String in stat_gains:
			var actual_delta: int = stats.add_stat(stat_id, int(stat_gains[stat_id]))
			if actual_delta != 0:
				result.stat_changes[stat_id] = actual_delta

	var requested_stress: int = int(activity_result.get("stress_delta", 0))
	result.stress_change = stats.add_stress(requested_stress)
	result.stress_final = stats.get_stress()

	if activity_type == "study":
		var xp_awarded: int = activities.add_course_xp(
			activity_id, int(activity_result.get("xp_gain", ActivitySystem.XP_PER_SESSION))
		)
		result.xp_gained[activity_id] = xp_awarded
		if bool(parsed_choice["experiment"]) and activity_id == "curso_tecnologia":
			tech_experiments = true
			result.flags_set["tech_experiments"] = true
	elif activity_type == "work":
		activities.mark_task_used(activity_id)
	elif activity_type == "mission":
		var effects: Dictionary = activity_result.get("success_effects", {})
		if bool(activity_result.get("success", false)):
			_apply_mission_effects(effects, result)
			if activity_id == "missao_tecnica":
				_missions_technical_completed += 1
				result.mission_count = 1
				if bool(parsed_choice["experiment"]):
					tech_experiments = true
					result.flags_set["tech_experiments"] = true
			if bool(effects.get("community_help", false)):
				community_help = true
				result.flags_set["community_help"] = true


func _apply_mission_effects(effects: Dictionary, result: PeriodResult) -> void:
	for stat_id: String in ["str", "int", "cha", "ref", "sta"]:
		var delta: int = int(effects.get(stat_id, 0))
		if delta != 0:
			var actual_delta: int = stats.add_stat(stat_id, delta)
			if actual_delta != 0:
				result.stat_changes[stat_id] = int(result.stat_changes.get(stat_id, 0)) + actual_delta
	var eth_delta: int = int(effects.get("eth", 0))
	if eth_delta != 0:
		result.eth_change = stats.add_ethics(eth_delta)
	var reputation_keys: Dictionary = {
		"fighter_rep": "fighter",
		"social_rep": "social",
		"hacker_rep": "hacker"
	}
	for effect_key: String in reputation_keys:
		var delta: int = int(effects.get(effect_key, 0))
		if delta != 0:
			var reputation_id: String = str(reputation_keys[effect_key])
			var actual_delta: int = stats.add_reputation(reputation_id, delta)
			if actual_delta != 0:
				result.rep_gained[reputation_id] = actual_delta


func _systems_are_initialized() -> bool:
	return calendar != null and stats != null and economy != null and activities != null


func _reset_campaign_flags() -> void:
	tech_experiments = false
	criminal_record = false
	community_help = false
	disappear_from_society = false
	_missions_technical_completed = 0
