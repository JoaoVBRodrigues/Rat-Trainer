extends Node
class_name MonthlyScheduleFlow

## Coordinates the monthly planning and presentation flow without owning simulation state.

const CATEGORY_IDS: Array[String] = ["study", "work", "mission", "leisure"]
const PERIOD_COUNT: int = 3
const COURSE_NAME_KEYS: Dictionary = {
	"curso_tecnologia": "courses.curso_tecnologia",
	"curso_comunicacao": "courses.curso_comunicacao",
	"curso_artes": "courses.curso_artes"
}

var _main_screen: Control
var _simulation: SimulationCore
var _schedule_screen: ScheduleScreen
var _result_screen: ActivityResultScreen
var _summary_screen: MonthSummaryScreen
var _encounter_screen: EncounterScreen
var _draft: MonthSchedule
var _previous_schedule: MonthSchedule
var _previous_schedule_calendar: CalendarSystem
var _previous_schedule_completed_periods: int = -1
var _initial_state: Dictionary = {}
var _results: Array[PeriodResult] = []
var _next_period_index: int = 0
var _test_mode: bool = false
var _active: bool = false
var _recovery_blocked: bool = false
var _last_report: Dictionary = {}


func bind_main_screen(screen: Control) -> void:
	_main_screen = screen


func update_simulation(simulation: SimulationCore) -> void:
	if _simulation != simulation:
		_previous_schedule = null
		_previous_schedule_calendar = null
		_previous_schedule_completed_periods = -1
	_simulation = simulation


func on_schedule_requested(source: String) -> void:
	if _simulation == null or _active:
		return
	if _simulation.is_campaign_complete() or _simulation.calendar.period != 1:
		return
	_active = true
	_recovery_blocked = false
	_draft = MonthSchedule.new()
	_draft.credits_at_start = _simulation.economy.get_credits()
	_ensure_screens()
	_schedule_screen.open_schedule(
		_simulation,
		_draft,
		_available_previous_schedule(),
		_build_activity_choices(),
		"",
		0,
		true,
		0,
		false,
		"mission" if source == "mission" else "study"
	)
	_schedule_screen.visible = true


func _ensure_screens() -> void:
	if _main_screen == null:
		return
	if _schedule_screen == null:
		_schedule_screen = ScheduleScreen.new()
		_schedule_screen.name = "MonthlyScheduleScreen"
		_schedule_screen.schedule_confirmed.connect(_on_schedule_confirmed)
		_schedule_screen.schedule_cancelled.connect(_on_schedule_cancelled)
		_main_screen.add_child(_schedule_screen)
	if _result_screen == null:
		_result_screen = ActivityResultScreen.new()
		_result_screen.name = "ActivityResultScreen"
		_result_screen.result_continued.connect(_on_result_continued)
		_main_screen.add_child(_result_screen)
		_result_screen.visible = false
	if _summary_screen == null:
		_summary_screen = MonthSummaryScreen.new()
		_summary_screen.name = "MonthSummaryScreen"
		_summary_screen.summary_finished.connect(_on_summary_finished)
		_main_screen.add_child(_summary_screen)
		_summary_screen.visible = false
	if _encounter_screen == null:
		_encounter_screen = EncounterScreen.new()
		_encounter_screen.name = "EncounterScreen"
		_encounter_screen.encounter_resolved.connect(_on_encounter_resolved)
		_main_screen.add_child(_encounter_screen)
		_encounter_screen.visible = false


func _build_activity_choices() -> Dictionary:
	var choices_by_category: Dictionary = {}
	var available: Dictionary = _simulation.get_available_activities()
	var activity_system: ActivitySystem = _simulation.activities

	for category: String in CATEGORY_IDS:
		var choices: Array[Dictionary] = []
		var activity_ids: Array = available.get(category, [])
		if category == "mission":
			activity_ids = activity_system.get_available_missions()
		for raw_id: Variant in activity_ids:
			var activity_id: String = str(raw_id)
			var choice: Dictionary = _build_activity_choice(category, activity_id)
			choices.append(choice)
		choices_by_category[category] = choices

	for category: String in CATEGORY_IDS:
		var choices: Array = choices_by_category[category]
		var label: String = _category_label(category, choices)
		for choice_index: int in choices.size():
			choices[choice_index]["category_label"] = label
		choices_by_category[category] = choices
	return choices_by_category


func _build_activity_choice(category: String, activity_id: String) -> Dictionary:
	var activity_system: ActivitySystem = _simulation.activities
	var level: int = 1
	var cost: int = 0
	var income: int = 0
	var preview: Dictionary = {}
	var activity_record: Dictionary = {}
	var can_afford: bool = true
	var reason: String = ""
	var display_id: String = activity_id

	match category:
		"study":
			level = activity_system.get_course_level(activity_id)
			var execution: Dictionary = activity_system.execute_study(activity_id, level)
			if execution.has("error"):
				return _activity_data_error_choice(category, activity_id, "study_execution")
			cost = int(execution.get("cost", 0))
			preview = _merge_preview(
				execution.get("stat_gains", {}),
				int(execution.get("stress_delta", 0))
			)
			activity_record = activity_system.get_course(activity_id)
		"work":
			level = activity_system.get_job_level(activity_id)
			var execution: Dictionary = activity_system.execute_work(activity_id, level)
			if execution.has("error"):
				return _activity_data_error_choice(category, activity_id, "work_execution")
			income = int(execution.get("income", 0))
			preview = _merge_preview(
				execution.get("stat_gains", {}),
				int(execution.get("stress_delta", 0))
			)
			activity_record = activity_system.get_course(activity_id)
		"mission":
			activity_record = activity_system.get_mission(activity_id)
			if activity_record.is_empty():
				return _activity_data_error_choice(category, activity_id, "missing_record")
			preview = {"stress": int(activity_record.get("stress", 0))}
			var availability_error: String = _simulation.get_mission_availability_error(activity_id)
			can_afford = availability_error.is_empty()
			if not can_afford:
				reason = (
					"disease"
					if _simulation.stats.is_mission_blocked_by_disease()
					else "mission_requirements"
				)
		"leisure":
			var execution: Dictionary = activity_system.execute_leisure(activity_id)
			if execution.has("error"):
				return _activity_data_error_choice(category, activity_id, "leisure_execution")
			preview = _merge_preview(
				execution.get("stat_gains", {}),
				int(execution.get("stress_delta", 0))
			)
			cost = int(execution.get("cost", 0))
			display_id = (
				"lazer_descanso" if activity_id == "descanso"
				else "lazer_passeio_comunitario" if activity_id == "passeio_comunitario"
				else activity_id
			)
			activity_record = activity_system.get_course(display_id)
	if activity_record.is_empty():
		return _activity_data_error_choice(category, activity_id, "missing_record")
	var activity_name: Variant = activity_record.get("name", "")
	if not activity_name is String or str(activity_name).is_empty():
		return _activity_data_error_choice(category, activity_id, "malformed_record")

	if category == "study" or category == "leisure":
		can_afford = _simulation.economy.can_afford(cost)
		if not can_afford:
			reason = "insufficient_credits"
	return {
		"id": activity_id,
		"activity_type": category,
		"level": level,
		"cost": cost,
		"income": income,
		"can_afford": can_afford,
		"reason": reason,
		"preview": preview,
		"display_name": _activity_display_name(display_id, activity_record),
		"record": activity_record.duplicate(true)
	}


func _activity_data_error_choice(
	category: String,
	activity_id: String,
	error_kind: String
) -> Dictionary:
	var stable_error_id: String = "activity_data_%s:%s:%s" % [
		error_kind,
		category,
		activity_id
	]
	push_error(stable_error_id)
	var activity_record: Dictionary = {}
	if _simulation != null and _simulation.activities != null:
		if category == "mission":
			activity_record = _simulation.activities.get_mission(activity_id)
		else:
			var display_id: String = (
				"lazer_descanso" if activity_id == "descanso"
				else "lazer_passeio_comunitario"
				if activity_id == "passeio_comunitario"
				else activity_id
			)
			activity_record = _simulation.activities.get_course(display_id)
	var display_name: String = _activity_display_name(activity_id, activity_record)
	if display_name.is_empty():
		display_name = Localization.text("ui.indisponivel")
	return {
		"id": activity_id,
		"activity_type": category,
		"level": 1,
		"cost": 0,
		"income": 0,
		"can_afford": false,
		"reason": "error",
		"error": stable_error_id,
		"preview": {},
		"display_name": display_name,
		"record": activity_record.duplicate(true)
	}


func _merge_preview(stat_gains: Variant, stress_delta: int) -> Dictionary:
	var preview: Dictionary = stat_gains.duplicate(true) if stat_gains is Dictionary else {}
	if stress_delta != 0:
		preview["stress"] = stress_delta
	return preview


func _activity_display_name(activity_id: String, record: Dictionary) -> String:
	if COURSE_NAME_KEYS.has(activity_id):
		return Localization.text(str(COURSE_NAME_KEYS[activity_id]))
	return str(record.get("name", ""))


func _category_label(category: String, choices: Array) -> String:
	if choices.is_empty():
		return Localization.text("ui.indisponivel")
	var record: Dictionary = choices[0].get("record", {})
	var display_name: String = str(record.get("name", choices[0].get("display_name", "")))
	var separator: int = display_name.find(" - ")
	if separator > 0:
		return display_name.substr(0, separator)
	if category == "leisure" and choices.size() > 1:
		return "%s / %s" % [
			display_name,
			str(choices[1].get("display_name", ""))
		]
	var space: int = display_name.find(" ")
	return display_name.substr(0, space) if space > 0 else display_name


func _on_schedule_confirmed(schedule: MonthSchedule) -> void:
	if _simulation == null or _recovery_blocked:
		return
	var resume_index: int = _next_period_index if not _results.is_empty() else 0
	var validated_schedule: MonthSchedule = schedule.duplicate_schedule()
	if (
		not _refresh_schedule_values(validated_schedule, resume_index)
		or not _validate_schedule(validated_schedule, resume_index)
	):
		_show_schedule_error(resume_index, resume_index == 0)
		return
	_draft = validated_schedule
	if resume_index == 0:
		_draft.credits_at_start = _simulation.economy.get_credits()
		_initial_state = _simulation.get_state()
		_results.clear()
		_next_period_index = 0
	_test_mode = false
	_schedule_screen.visible = false
	_resolve_next_period()


func _validate_schedule(schedule: MonthSchedule, start_index: int = 0) -> bool:
	if not schedule.is_month_selected() or _simulation.calendar.period != start_index + 1:
		return false
	var balance: int = _simulation.economy.get_credits()
	for period_index: int in range(start_index, PERIOD_COUNT):
		var selection: Dictionary = schedule.get_selection(period_index)
		if not _selection_is_available(selection):
			return false
		var cost: int = int(selection.get("cost", 0))
		if balance < cost:
			return false
		balance -= cost
		balance += int(selection.get("income", 0))
	return true


func _refresh_schedule_values(schedule: MonthSchedule, start_index: int = 0) -> bool:
	for period_index: int in range(start_index, PERIOD_COUNT):
		var selection: Dictionary = schedule.get_selection(period_index)
		if not schedule.has_selection(period_index):
			return false
		var activity_id: String = str(selection.get("activity_id", ""))
		var activity_type: int = int(selection.get("activity_type", MonthSchedule.ActivityPeriod.NONE))
		var level: int = int(selection.get("level", 1))
		var cost: int = 0
		var income: int = 0
		match activity_type:
			MonthSchedule.ActivityPeriod.STUDY:
				if not _simulation.activities.get_available_courses().has(activity_id):
					return false
				var study: Dictionary = _simulation.activities.execute_study(activity_id, level)
				if study.has("error"):
					return false
				cost = int(study.get("cost", 0))
			MonthSchedule.ActivityPeriod.WORK:
				if not _simulation.activities.get_available_tasks().has(activity_id):
					return false
				level = _simulation.activities.get_job_level(activity_id)
				var work: Dictionary = _simulation.activities.execute_work(activity_id, level)
				if work.has("error"):
					return false
				income = int(work.get("income", 0))
			MonthSchedule.ActivityPeriod.MISSION:
				if not _simulation.activities.get_available_missions().has(activity_id):
					return false
				if not _simulation.get_mission_availability_error(activity_id).is_empty():
					return false
			MonthSchedule.ActivityPeriod.LEISURE:
				if not _simulation.activities.get_available_leisure().has(activity_id):
					return false
				var leisure: Dictionary = _simulation.activities.execute_leisure(activity_id)
				if leisure.has("error"):
					return false
				cost = int(leisure.get("cost", 0))
			_:
				return false
		if not schedule.set_selection(
			period_index,
			activity_type as MonthSchedule.ActivityPeriod,
			activity_id,
			level,
			cost,
			true,
			"",
			income
		):
			return false
	return true


func _selection_is_available(selection: Dictionary) -> bool:
	var activity_id: String = str(selection.get("activity_id", ""))
	var activity_type: int = int(selection.get("activity_type", MonthSchedule.ActivityPeriod.NONE))
	match activity_type:
		MonthSchedule.ActivityPeriod.STUDY:
			return (
				_simulation.activities.get_available_courses().has(activity_id)
				and int(selection.get("level", 0)) <= _simulation.activities.get_course_level(activity_id)
				and int(selection.get("level", 0)) >= 1
			)
		MonthSchedule.ActivityPeriod.WORK:
			return (
				_simulation.activities.get_available_tasks().has(activity_id)
				and int(selection.get("level", 0)) == _simulation.activities.get_job_level(activity_id)
			)
		MonthSchedule.ActivityPeriod.MISSION:
			return (
				_simulation.activities.get_available_missions().has(activity_id)
				and _simulation.get_mission_availability_error(activity_id).is_empty()
			)
		MonthSchedule.ActivityPeriod.LEISURE:
			return _simulation.activities.get_available_leisure().has(activity_id)
	return false


func _resolve_next_period() -> void:
	if _next_period_index >= PERIOD_COUNT:
		_finish_execution()
		return
	if _simulation.calendar.period != _next_period_index + 1:
		_pause_execution()
		return

	var selection: Dictionary = _draft.get_selection(_next_period_index)
	if not _selection_is_available(selection):
		_show_schedule_error(_next_period_index, false)
		return

	var result: PeriodResult = _simulation.advance_period(_choice_string(selection))

	# Physical missions may trigger an encounter that requires player choice before
	# the period completes. The encounter resolution itself advances the calendar.
	if has_pending_encounter():
		if _test_mode:
			# Deterministic test route resolves the encounter automatically.
			var encounter_result: PeriodResult = resolve_pending_encounter(0)
			if not encounter_result.error_message.is_empty():
				_show_schedule_error(_next_period_index, false)
				return
			_results.append(encounter_result)
			_next_period_index += 1
			return
		_show_encounter_screen()
		return

	if not result.completed:
		_show_schedule_error(_next_period_index, false)
		return

	_results.append(result)
	_next_period_index += 1
	if _test_mode:
		return
	_result_screen.show_result(result, _simulation)


func _choice_string(selection: Dictionary) -> String:
	var activity_id: String = str(selection.get("activity_id", ""))
	var level: int = int(selection.get("level", 1))
	match int(selection.get("activity_type", MonthSchedule.ActivityPeriod.NONE)):
		MonthSchedule.ActivityPeriod.STUDY:
			return "study_%s_l%d" % [activity_id, level]
		MonthSchedule.ActivityPeriod.WORK:
			return "work_%s_l%d" % [activity_id, level]
		MonthSchedule.ActivityPeriod.MISSION:
			return "mission_%s" % activity_id
		MonthSchedule.ActivityPeriod.LEISURE:
			return "leisure_%s" % activity_id
	return ""


func _on_result_continued() -> void:
	_result_screen.hide_result()
	_resolve_next_period()


func _finish_execution() -> void:
	var final_state: Dictionary = _simulation.get_state()
	_last_report = _build_report(_initial_state, final_state)
	_previous_schedule = _draft.duplicate_schedule()
	_previous_schedule_calendar = _simulation.calendar
	_previous_schedule_completed_periods = _simulation.calendar.completed_periods
	if not _test_mode:
		_summary_screen.display_month_summary(_initial_state, final_state, _results)
		_summary_screen.visible = true


func _build_report(pre_state: Dictionary, post_state: Dictionary) -> Dictionary:
	var pre_stats: Dictionary = pre_state.get("stats", {})
	var post_stats: Dictionary = post_state.get("stats", {})
	var stat_deltas: Dictionary = {}
	for stat_id: String in ["str", "int", "cha", "ref", "sta", "eth"]:
		stat_deltas[stat_id] = int(post_stats.get(stat_id, 0)) - int(pre_stats.get(stat_id, 0))
	var pre_economy: Dictionary = pre_state.get("economy", {})
	var post_economy: Dictionary = post_state.get("economy", {})
	return {
		"completed": _results.size() == PERIOD_COUNT,
		"results": _results.duplicate(),
		"pre_state": pre_state.duplicate(true),
		"post_state": post_state.duplicate(true),
		"stat_deltas": stat_deltas,
		"credits_delta": int(post_economy.get("credits", 0)) - int(pre_economy.get("credits", 0)),
		"credits_final": int(post_economy.get("credits", 0)),
		"stress_delta": int(post_stats.get("stress", 0)) - int(pre_stats.get("stress", 0)),
		"stress_final": int(post_stats.get("stress", 0))
	}


func _show_encounter_screen() -> void:
	if _encounter_screen == null:
		_ensure_screens()
	if _encounter_screen == null:
		return
	var encounter: Dictionary = get_pending_encounter()
	var monster_id: String = str(encounter.get("encounter_monster_id", ""))
	var monster_name: String = str(encounter.get("encounter_monster_name", ""))
	var monster_description: String = str(
		encounter.get("encounter_monster_description", "")
	)
	if monster_name.is_empty():
		monster_name = Localization.text("ui.indisponivel")
	if _result_screen != null:
		_result_screen.hide_result()
	_encounter_screen.open_encounter(monster_id, monster_name, monster_description)
	_encounter_screen.visible = true


func _on_encounter_resolved(option: int) -> void:
	var result: PeriodResult = resolve_pending_encounter(option)
	if not result.error_message.is_empty():
		push_error("encounter_resolution_failed:%s" % result.error_message)
		if _encounter_screen != null:
			_encounter_screen.show_resolution_error(result.error_message)
			_encounter_screen.visible = true
		return
	if result.completed:
		_encounter_screen.hide_encounter()
		_results.append(result)
		_next_period_index += 1
		if _test_mode:
			return
		if _result_screen != null:
			_result_screen.show_result(result, _simulation)
		return


func _show_schedule_error(period_index: int, can_cancel: bool) -> void:
	if _result_screen != null:
		_result_screen.hide_result()
	if _schedule_screen == null:
		_ensure_screens()
	if _schedule_screen == null:
		return
	var previous: MonthSchedule = _available_previous_schedule() if period_index == 0 else null
	_schedule_screen.open_schedule(
		_simulation,
		_draft,
		previous,
		_build_activity_choices(),
		"error",
		period_index,
		can_cancel,
		period_index
	)
	_schedule_screen.visible = true


func _pause_execution() -> void:
	_active = true
	if _schedule_screen != null:
		_schedule_screen.open_schedule(
			_simulation,
			_draft,
			null,
			_build_activity_choices(),
			"blocked_recovery",
			_next_period_index,
			false,
			_next_period_index,
			true
		)
		_schedule_screen.visible = true
	if _result_screen != null:
		_result_screen.hide_result()


func _on_schedule_cancelled() -> void:
	if _next_period_index > 0 or _recovery_blocked:
		return
	_close_flow()


func _on_summary_finished() -> void:
	if _simulation == null:
		return
	if _main_screen != null:
		_main_screen.update_simulation(_simulation)
	_close_flow()
	if _main_screen != null:
		var schedule_button: Button = _main_screen.find_child("ScheduleButton", true, false) as Button
		if schedule_button != null:
			schedule_button.grab_focus()


func _close_flow() -> void:
	if _schedule_screen != null:
		_schedule_screen.visible = false
	if _result_screen != null:
		_result_screen.hide_result()
	if _summary_screen != null:
		_summary_screen.visible = false
	_active = false
	_test_mode = false


func get_last_report() -> Dictionary:
	return _last_report.duplicate(true)


func _available_previous_schedule() -> MonthSchedule:
	if _previous_schedule == null or _simulation == null:
		return null
	if _simulation.calendar != _previous_schedule_calendar:
		return null
	if _simulation.calendar.completed_periods != _previous_schedule_completed_periods:
		return null
	return _previous_schedule.duplicate_schedule()


## Deterministic route for isolated integration tests; executes the same validation and resolver.
func run_month_for_test(schedule: MonthSchedule, seed: int) -> Dictionary:
	_last_report.clear()
	if _simulation == null or schedule == null:
		return {"completed": false, "error": "Simulation and schedule are required."}
	if _simulation.calendar.period != 1 or _simulation.get_remaining_periods() < PERIOD_COUNT:
		return {"completed": false, "error": "Schedule requires a full month boundary."}
	var validated_schedule: MonthSchedule = schedule.duplicate_schedule()
	if not _refresh_schedule_values(validated_schedule, 0) or not _validate_schedule(validated_schedule, 0):
		return {"completed": false, "error": "Schedule is invalid."}
	_simulation.set_seed(seed)
	_draft = validated_schedule
	_initial_state = _simulation.get_state()
	_results.clear()
	_next_period_index = 0
	_test_mode = true
	_recovery_blocked = false
	while _next_period_index < PERIOD_COUNT and not _recovery_blocked:
		var previous_count: int = _results.size()
		_resolve_next_period()
		if _results.size() == previous_count:
			break
	if _results.size() == PERIOD_COUNT:
		_finish_execution()
	else:
		_last_report = {
			"completed": false,
			"results": _results.duplicate(),
			"next_period_index": _next_period_index
		}
	_test_mode = false
	return get_last_report()


func get_pending_encounter() -> Dictionary:
	if _simulation == null:
		return {}
	return _simulation.get_pending_encounter()


func has_pending_encounter() -> bool:
	if _simulation == null:
		return false
	return _simulation.has_pending_encounter()


func resolve_pending_encounter(option: int) -> PeriodResult:
	if _simulation == null:
		var result: PeriodResult = PeriodResult.new()
		result.error_message = "No simulation available."
		return result
	return _simulation.resolve_pending_encounter(option)
