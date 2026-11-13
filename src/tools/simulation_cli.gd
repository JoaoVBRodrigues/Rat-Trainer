extends SceneTree

const COURSE_BY_MONTH: Array[String] = [
	"curso_tecnologia",
	"curso_comunicacao",
	"curso_artes"
]

var _exit_code: int = 0


func _initialize() -> void:
	var seed_value: int = 12345
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		if not user_args[0].is_valid_int():
			push_error("Usage: godot --headless --path . --script res://src/tools/simulation_cli.gd [seed]")
			_finish(2)
			return
		seed_value = int(user_args[0])

	var simulation: SimulationCore = SimulationCore.new()
	if not simulation.initialize():
		push_error("Simulation initialization failed.")
		_finish(1)
		return
	simulation.set_seed(seed_value)
	print("Rat Trainer deterministic simulation (seed %d)" % seed_value)

	for period_index: int in range(simulation.calendar.total_periods):
		var choice: String = _choose_activity(simulation)
		var result: PeriodResult = simulation.advance_period(choice)
		if not result.completed:
			push_error("Period %d failed: %s" % [period_index + 1, result.error_message])
			_finish(1)
			return
		if simulation.calendar.completed_periods % 36 == 0:
			_print_year_summary(simulation)

	print("Campaign completed: %d periods, age %d, credits %d." % [
		simulation.calendar.completed_periods,
		simulation.get_age(),
		simulation.economy.get_credits()
	])
	_finish(0)


func _choose_activity(simulation: SimulationCore) -> String:
	var current_month: int = simulation.calendar.get_month()
	var current_period: int = simulation.calendar.get_period()
	if current_period == 1:
		var course_index: int = (current_month - 1) % COURSE_BY_MONTH.size()
		var course_id: String = COURSE_BY_MONTH[course_index]
		var level: int = simulation.activities.get_course_level(course_id)
		var cost: int = simulation.activities.get_course_cost(course_id, level)
		if simulation.economy.get_credits() >= cost:
			return "study_%s_l%d" % [course_id, level]
		return "work_trabalho_reparo_leve"
	if current_period == 2:
		return "work_trabalho_reparo_leve"
	return "leisure_descanso"


func _print_year_summary(simulation: SimulationCore) -> void:
	var stats: Dictionary = simulation.stats.stats
	var completed_year: int = int(simulation.calendar.completed_periods / (
		simulation.calendar.months_per_year * simulation.calendar.periods_per_month
	))
	print(
		"Year %d — age %d | STR %d INT %d CHA %d REF %d STA %d ETH %d | Stress %d | Cr %d"
		% [
			completed_year,
			12 + completed_year,
			int(stats["str"]),
			int(stats["int"]),
			int(stats["cha"]),
			int(stats["ref"]),
			int(stats["sta"]),
			int(stats["eth"]),
			simulation.stats.get_stress(),
			simulation.economy.get_credits()
		]
	)


func _finish(code: int) -> void:
	_exit_code = code
	quit(_exit_code)
