extends Control
class_name CalendarPanel

# Calendar display panel - shows year, month, day, period
# Updates every period and shows progress counter

signal period_changed

@export var show_week_labels: bool = true  # Decorative only, not used for game logic

const DAY_LABELS: Dictionary = {
	1: "Seg",  # Period 1
	2: "Qua",  # Period 2
	3: "Sex"   # Period 3
}

var _year: int = 1
var _month: int = 1
var _day_label: String = "Seg"
var _period_num: int = 1
var _completed_periods: int = 0
var _total_periods: int = 108


func _ready() -> void:
	_update_display()


func update_from_simulator(sim: SimulationCore) -> void:
	if sim == null:
		return
	_year = sim.calendar.year
	_month = sim.calendar.month
	_period_num = sim.calendar.get_period()
	_completed_periods = sim.calendar.completed_periods
	_total_periods = sim.calendar.total_periods
	_day_label = DAY_LABELS.get(_period_num, "")
	_update_display()


func _update_display() -> void:
	# Update calendar display - widget can be used standalone or as part of character card
	# Uses Theme colors when applied
	pass
