extends RefCounted
class_name CalendarSystem

signal campaign_completed(age: int)

const STARTING_AGE: int = 12
const WEEKDAY_LABELS: Array[String] = ["Monday", "Wednesday", "Friday"]

var years: int = 3
var months_per_year: int = 12
var periods_per_month: int = 3
var completed_periods: int = 0
var total_periods: int = 108
var year: int = 1
var month: int = 1
var period: int = 1
var age: int = STARTING_AGE
var turn_number: int = 1


func initialize_from_config(config_path: String = "res://assets/data/calendar.json") -> bool:
	if not FileAccess.file_exists(config_path):
		push_error("Calendar configuration does not exist: %s." % config_path)
		return false
	var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("Could not open calendar configuration: %s." % config_path)
		return false

	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Invalid calendar JSON at line %d: %s."
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return false
	if not parser.data is Dictionary:
		push_error("Calendar configuration must be a JSON object.")
		return false
	var calendar_data: Variant = parser.data.get("calendar")
	if not calendar_data is Dictionary:
		push_error("Calendar configuration is missing the 'calendar' object.")
		return false

	var configured_years: Variant = calendar_data.get("years")
	var configured_months: Variant = calendar_data.get("months")
	var configured_periods: Variant = calendar_data.get("periods")
	if not _is_positive_integer(configured_years):
		push_error("Calendar 'years' must be a positive integer.")
		return false
	if not _is_positive_integer(configured_months):
		push_error("Calendar 'months' must be a positive integer.")
		return false
	if not _is_positive_integer(configured_periods):
		push_error("Calendar 'periods' must be a positive integer.")
		return false

	years = int(configured_years)
	months_per_year = int(configured_months)
	periods_per_month = int(configured_periods)
	total_periods = years * months_per_year * periods_per_month
	reset()
	return true


func start_new_game() -> void:
	reset()


func reset() -> void:
	completed_periods = 0
	_update_calculated_values()


func get_calendar_state() -> CalendarState:
	return CalendarState.new(completed_periods, years, months_per_year, periods_per_month)


func load_state(state: Dictionary) -> bool:
	var calendar_state: CalendarState = CalendarState.new(
		0, years, months_per_year, periods_per_month
	)
	if not calendar_state.load_state(state):
		return false
	years = calendar_state.years
	months_per_year = calendar_state.months_per_year
	periods_per_month = calendar_state.periods_per_month
	total_periods = calendar_state.total_periods
	completed_periods = calendar_state.completed_periods
	_update_calculated_values()
	return true


func advance_period() -> bool:
	if is_campaign_complete():
		return false
	completed_periods += 1
	_update_calculated_values()
	if is_campaign_complete():
		campaign_completed.emit(age)
	return true


func is_campaign_complete() -> bool:
	return completed_periods >= total_periods


func is_new_year_period() -> bool:
	var periods_per_year: int = months_per_year * periods_per_month
	return not is_campaign_complete() and completed_periods % periods_per_year == 0


func is_month_end() -> bool:
	return period == periods_per_month


func is_year_end() -> bool:
	return is_month_end() and month == months_per_year


func get_year() -> int:
	return year


func get_month() -> int:
	return month


func get_period() -> int:
	return period


func get_age() -> int:
	return age


func get_turn_number() -> int:
	return turn_number


func get_periods_completed() -> int:
	return completed_periods


func get_day_of_month() -> int:
	return 1 + (period - 1) * 10


func get_weekday_label() -> String:
	return WEEKDAY_LABELS[mini(period - 1, WEEKDAY_LABELS.size() - 1)]


func get_date_string() -> String:
	return "Year %d, Month %d, Day %d (%s)" % [
		year, month, get_day_of_month(), get_weekday_label()
	]


func get_remaining_periods() -> int:
	return maxi(total_periods - completed_periods, 0)


func get_period_info() -> Dictionary:
	return {
		"completed_periods": completed_periods,
		"turn_number": turn_number,
		"year": year,
		"month": month,
		"period": period,
		"day": get_day_of_month(),
		"age": age,
		"is_campaign_complete": is_campaign_complete(),
		"weekday": get_weekday_label(),
		"total_periods": total_periods,
		"remaining_periods": get_remaining_periods()
	}


func _update_calculated_values() -> void:
	turn_number = mini(completed_periods + 1, total_periods)
	var state: CalendarState = get_calendar_state()
	year = state.year
	month = state.month
	period = state.period
	age = state.age


static func _is_positive_integer(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	var numeric_value: float = float(value)
	return numeric_value > 0.0 and floorf(numeric_value) == numeric_value
