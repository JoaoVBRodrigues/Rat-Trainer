extends RefCounted
class_name MonthSchedule

## Editable, in-memory draft of one month's three activity choices.

enum ActivityPeriod { NONE, STUDY, WORK, MISSION, LEISURE }

const PERIOD_COUNT: int = 3

var selections: Array[Dictionary] = []
var is_complete: bool = false
var credits_at_start: int = 0


func _init() -> void:
	clear()


func clear() -> void:
	selections.clear()
	for index: int in PERIOD_COUNT:
		selections.append(_empty_selection(index))
	is_complete = false
	credits_at_start = 0


func _empty_selection(period_index: int) -> Dictionary:
	return {
		"period": period_index + 1,
		"activity_type": ActivityPeriod.NONE,
		"activity_id": "",
		"level": 0,
		"cost": 0,
		"income": 0,
		"can_afford": false,
		"reason": ""
	}


func set_selection(
	period_index: int,
	activity_type: ActivityPeriod,
	activity_id: String,
	level: int,
	cost: int,
	can_afford: bool,
	reason: String = "",
	income: int = 0
) -> bool:
	if period_index < 0 or period_index >= PERIOD_COUNT:
		return false
	if activity_type == ActivityPeriod.NONE or activity_id.is_empty():
		return false
	if level < 1 or cost < 0 or income < 0:
		return false

	selections[period_index] = {
		"period": period_index + 1,
		"activity_type": activity_type,
		"activity_id": activity_id,
		"level": level,
		"cost": cost,
		"income": income,
		"can_afford": can_afford,
		"reason": reason
	}
	is_complete = is_month_selected()
	return true


func get_selection(period_index: int) -> Dictionary:
	if period_index < 0 or period_index >= PERIOD_COUNT:
		return {}
	return selections[period_index].duplicate(true)


func has_selection(period_index: int) -> bool:
	if period_index < 0 or period_index >= PERIOD_COUNT:
		return false
	return int(selections[period_index].get("activity_type", ActivityPeriod.NONE)) != ActivityPeriod.NONE


func get_total_cost() -> int:
	var total: int = 0
	for selection: Dictionary in selections:
		total += int(selection.get("cost", 0))
	return total


func is_month_selected() -> bool:
	for index: int in PERIOD_COUNT:
		if not has_selection(index):
			return false
	return true


func is_valid() -> bool:
	if not is_month_selected():
		return false
	for selection: Dictionary in selections:
		if not bool(selection.get("can_afford", false)):
			return false
	return true


func clear_selection(period_index: int) -> void:
	if period_index < 0 or period_index >= PERIOD_COUNT:
		return
	selections[period_index] = _empty_selection(period_index)
	is_complete = is_month_selected()


func duplicate_schedule() -> MonthSchedule:
	var copy: MonthSchedule = MonthSchedule.new()
	copy.load_state(get_state())
	return copy


func get_state() -> Dictionary:
	return {
		"selections": selections.duplicate(true),
		"is_complete": is_complete,
		"credits_at_start": credits_at_start
	}


func load_state(state: Dictionary) -> bool:
	var loaded_selections: Variant = state.get("selections", [])
	if not loaded_selections is Array or loaded_selections.size() != PERIOD_COUNT:
		return false

	var validated: Array[Dictionary] = []
	for index: int in PERIOD_COUNT:
		var selection: Variant = loaded_selections[index]
		if not selection is Dictionary:
			return false
		var activity_type: Variant = selection.get("activity_type", ActivityPeriod.NONE)
		var activity_id: Variant = selection.get("activity_id", "")
		var level: Variant = selection.get("level", 0)
		var cost: Variant = selection.get("cost", 0)
		var income: Variant = selection.get("income", 0)
		if not activity_type is int or activity_type < ActivityPeriod.NONE or activity_type > ActivityPeriod.LEISURE:
			return false
		if not activity_id is String or not level is int or not cost is int or not income is int:
			return false
		if cost < 0 or income < 0:
			return false
		validated.append(selection.duplicate(true))

	selections = validated
	is_complete = is_month_selected()
	credits_at_start = int(state.get("credits_at_start", 0))
	return true
