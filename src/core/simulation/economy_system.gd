extends RefCounted
class_name EconomySystem

const STARTING_CREDITS: int = 0
const YEARLY_STIPEND: int = 200

var credits: int = STARTING_CREDITS
var total_years: int = 3
var _years_stipend_given: Array[bool] = []
var _current_year: int = 1


func start_new_game(configured_years: int = 3) -> void:
	total_years = maxi(configured_years, 1)
	credits = STARTING_CREDITS
	_current_year = 1
	_years_stipend_given.clear()
	_years_stipend_given.resize(total_years)
	_years_stipend_given.fill(false)


func get_credits() -> int:
	return credits


func can_afford(cost: int) -> bool:
	return cost >= 0 and credits >= cost


func pay(cost: int) -> bool:
	if not can_afford(cost):
		return false
	credits -= cost
	return true


func receive_income(amount: int) -> bool:
	if amount < 0:
		push_error("Income cannot be negative.")
		return false
	credits += amount
	return true


func start_year(year_number: int) -> int:
	if year_number < 1 or year_number > total_years:
		return 0
	_current_year = year_number
	if _years_stipend_given[year_number - 1]:
		return 0
	_years_stipend_given[year_number - 1] = true
	return YEARLY_STIPEND


func get_stipend_status(year_number: int) -> Dictionary:
	if year_number < 1 or year_number > total_years:
		return {"given": true, "eligible": false}
	var was_given: bool = _years_stipend_given[year_number - 1]
	return {"given": was_given, "eligible": not was_given}


func get_state() -> Dictionary:
	return {
		"credits": credits,
		"current_year": _current_year,
		"total_years": total_years,
		"years_stipend_given": _years_stipend_given.duplicate()
	}


func load_state(state: Dictionary) -> bool:
	var saved_credits: Variant = state.get("credits")
	var saved_years: Variant = state.get("total_years", total_years)
	var saved_stipends: Variant = state.get("years_stipend_given")
	var saved_current_year: Variant = state.get("current_year", 1)
	if not saved_credits is int or saved_credits < 0:
		return false
	if not saved_years is int or saved_years < 1:
		return false
	if not saved_current_year is int or saved_current_year < 1 or saved_current_year > saved_years:
		return false
	if not saved_stipends is Array or saved_stipends.size() != saved_years:
		return false
	for stipend_value: Variant in saved_stipends:
		if not stipend_value is bool:
			return false

	credits = saved_credits
	total_years = saved_years
	_current_year = saved_current_year
	_years_stipend_given.clear()
	for stipend_value: bool in saved_stipends:
		_years_stipend_given.append(stipend_value)
	return true


func reset() -> void:
	start_new_game(total_years)
