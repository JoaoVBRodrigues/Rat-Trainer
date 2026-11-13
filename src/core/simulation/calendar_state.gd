extends RefCounted
class_name CalendarState

var completed_periods: int = 0
var total_periods: int = 108
var years: int = 3
var months_per_year: int = 12
var periods_per_month: int = 3
var is_completed: bool = false
var year: int = 1
var month: int = 1
var period: int = 1
var age: int = 12


func _init(
	p_completed_periods: int = 0,
	p_years: int = 3,
	p_months_per_year: int = 12,
	p_periods_per_month: int = 3
) -> void:
	years = p_years
	months_per_year = p_months_per_year
	periods_per_month = p_periods_per_month
	total_periods = years * months_per_year * periods_per_month
	completed_periods = clampi(p_completed_periods, 0, total_periods)
	_update_calculated()


func advance() -> CalendarState:
	return CalendarState.new(
		completed_periods + 1, years, months_per_year, periods_per_month
	)


func to_dict() -> Dictionary:
	return {
		"completed_periods": completed_periods,
		"total_periods": total_periods,
		"years": years,
		"months_per_year": months_per_year,
		"periods_per_month": periods_per_month,
		"is_completed": is_completed,
		"year": year,
		"month": month,
		"period": period,
		"age": age
	}


func load_state(state: Dictionary) -> bool:
	var saved_years: int = int(state.get("years", years))
	var saved_months: int = int(state.get("months_per_year", months_per_year))
	var saved_periods_per_month: int = int(state.get("periods_per_month", periods_per_month))
	var saved_completed_periods: int = int(state.get("completed_periods", -1))
	if saved_years < 1 or saved_months < 1 or saved_periods_per_month < 1:
		return false
	var saved_total: int = saved_years * saved_months * saved_periods_per_month
	if saved_completed_periods < 0 or saved_completed_periods > saved_total:
		return false

	years = saved_years
	months_per_year = saved_months
	periods_per_month = saved_periods_per_month
	total_periods = saved_total
	completed_periods = saved_completed_periods
	_update_calculated()
	return true


func _update_calculated() -> void:
	is_completed = completed_periods >= total_periods
	if is_completed:
		year = years
		month = months_per_year
		period = periods_per_month
		age = 12 + years
		return

	var periods_per_year: int = months_per_year * periods_per_month
	year = floori(float(completed_periods) / float(periods_per_year)) + 1
	month = floori(float(completed_periods % periods_per_year) / float(periods_per_month)) + 1
	period = (completed_periods % periods_per_month) + 1
	age = 12 + year - 1
