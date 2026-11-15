extends SceneTree

# Balance check simulation runner
# Runs 1000 campaigns per strategy and outputs metrics to CSV/MD
# Usage: godot --headless --path . --script res://src/tools/balance_runner.gd [seed_base] [campaigns_per_strategy]

const STRATEGIES: Array[String] = [
	"guerreira",
	"hacker_int",
	"social_cha",
	"trabalhadora",
	"aleatoria",
	"equilibrada",
	"pouco_descanso",
	"so_lazer"
]

const DEFAULT_N_CAMPAIGNS: int = 1000
const DEFAULT_SEED_BASE: int = 10000

# All possible ending IDs from endings.json
const ALL_ENDING_IDS: Array[String] = [
	"evadida_do_sistema",
	"aprendiz_de_ciborgues",
	"tecnica_juvenil_da_cidade",
	"guardia_da_rede",
	"lider_comunitaria_jovem",
	"promessa_corporativa",
	"recruta_do_submundo",
	"voz_das_ruas",
	"mediadora_comunitaria",
	"autora_emergente",
	"mecanica_de_campo",
	"defensora_das_ruas",
	"hacker_de_elite",
	"artista_emergente",
	"caminho_equilibrado"
]

var _n_campaigns: int = DEFAULT_N_CAMPAIGNS
var _seed_base: int = DEFAULT_SEED_BASE
var _exit_code: int = 0

var _results: Array[Dictionary] = []
var _run_errors: int = 0
var _endings_blocked: bool = false
var _ending_evaluator: EndingEvaluator = EndingEvaluator.new()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_parse_args(args)

	print("Balance runner: %d campaigns per strategy, seed base %d" % [_n_campaigns, _seed_base])
	print("Strategies: %s" % [_strategy_list()])

	_endings_blocked = not _ending_evaluator.load_endings("res://assets/data/endings.json")
	if _endings_blocked:
		print("WARNING: Ending distribution is NOT ASSESSED; the ending catalog failed validation.")

	for strategy_idx: int in range(STRATEGIES.size()):
		var strategy: String = STRATEGIES[strategy_idx]
		print("\nRunning strategy: %s" % strategy)
		for campaign_idx: int in range(_n_campaigns):
			var seed: int = _seed_base + (strategy_idx * _n_campaigns) + campaign_idx
			_run_campaign(strategy, seed)

	_generate_reports()
	_finish(_exit_code)


func _strategy_list() -> String:
	var parts: Array[String] = []
	for s: String in STRATEGIES:
		parts.append(s)
	return ",".join(parts)


func _parse_args(args: PackedStringArray) -> void:
	var positional: Array[int] = []
	var i: int = 0
	while i < args.size():
		var arg: String = args[i]
		if arg == "--":
			i += 1
			continue
		if arg == "-h" or arg == "--help":
			print("Usage: balance_runner.gd [seed_base] [campaigns_per_strategy]")
			print("  seed_base               Base seed (default: 10000)")
			print("  campaigns_per_strategy  Number of campaigns per strategy (default: 1000)")
			_finish(0)
			return
		if arg == "-n" and i + 1 < args.size():
			var next_arg: String = args[i + 1]
			if next_arg.is_valid_int():
				_n_campaigns = int(next_arg)
				i += 2
				continue
		if arg.is_valid_int():
			positional.append(int(arg))
		i += 1
	if positional.size() >= 1:
		_seed_base = positional[0]
	if positional.size() >= 2:
		_n_campaigns = positional[1]


func _run_campaign(strategy: String, seed: int) -> void:
	var simulation: SimulationCore = SimulationCore.new()
	if not simulation.initialize():
		print("  ERROR: Failed to initialize simulation for seed %d" % seed)
		_run_errors += 1
		return

	simulation.set_seed(seed)

	# Track per-year metrics: index 0 = year 1, index 1 = year 2, index 2 = year 3
	var year_diseased_count: Array[int] = [0, 0, 0]
	var year_start_credits: Array[int] = [0, 0, 0]
	var year_start_stress: Array[int] = [0, 0, 0]
	var year_start_age: Array[int] = [12, 12, 12]
	var year_end_credits: Array[int] = [0, 0, 0]
	var year_end_stress: Array[int] = [0, 0, 0]

	# Initialize year 1 start (before any period)
	year_start_credits[0] = simulation.economy.get_credits()
	year_start_stress[0] = simulation.stats.get_stress()
	year_start_age[0] = 12

	var total_diseased_periods: int = 0
	var minimum_credits: int = simulation.economy.get_credits()
	var ended_year_metrics: Array[Dictionary] = []

	for period_index: int in range(simulation.calendar.total_periods):
		var turn_number: int = period_index + 1

		# Capture year start state at the first period of years 2 and 3 (periods 37, 73)
		if turn_number == 37:
			year_start_credits[1] = simulation.economy.get_credits()
			year_start_stress[1] = simulation.stats.get_stress()
			year_start_age[1] = 13
		elif turn_number == 73:
			year_start_credits[2] = simulation.economy.get_credits()
			year_start_stress[2] = simulation.stats.get_stress()
			year_start_age[2] = 14

		var choice: String = _choose_activity(simulation, strategy, period_index, seed)
		var result: PeriodResult = simulation.advance_period(choice, seed + period_index)
		minimum_credits = mini(minimum_credits, simulation.economy.get_credits())

		var resolution_attempts: int = 0
		while (result.is_event_pending or result.is_encounter_pending) and resolution_attempts < 10:
			resolution_attempts += 1

			if result.is_event_pending:
				if result.event_options.is_empty():
					print("  ERROR: No event options for %s at period %d" % [result.event_id, period_index])
					_run_errors += 1
					break
				var first_option: Dictionary = result.event_options[0]
				var event_option: String = str(first_option.get("id", ""))
				result = simulation.advance_period(event_option, seed + period_index)
			elif result.is_encounter_pending:
				var encounter_option: int = PeriodResult.EncounterOption.FIGHT
				result = simulation.resolve_pending_encounter(encounter_option)
			minimum_credits = mini(minimum_credits, simulation.economy.get_credits())

			if not result.completed:
				if resolution_attempts >= 10:
					print("  ERROR: Resolution loop for seed %d, strategy %s, period %d" % [seed, strategy, period_index])
				elif result.is_event_pending or result.is_encounter_pending:
					print("  ERROR: Still pending at period %d for seed %d, strategy %s" % [period_index, seed, strategy])
				else:
					print("  ERROR: Period %d failed for seed %d, strategy %s: %s" % [period_index, seed, strategy, result.error_message])
				_run_errors += 1
				return

		# Count disease periods per year
		if result.is_diseased_after:
			total_diseased_periods += 1
			if turn_number <= 36:
				year_diseased_count[0] += 1
			elif turn_number <= 72:
				year_diseased_count[1] += 1
			else:
				year_diseased_count[2] += 1

		# Capture year end state at periods 36, 72, 108
		var completed: int = simulation.calendar.completed_periods
		if completed == 36 or completed == 72 or completed == 108:
			var ended_year: int = 1
			if completed == 72:
				ended_year = 2
			elif completed == 108:
				ended_year = 3
			year_end_credits[ended_year - 1] = simulation.economy.get_credits()
			year_end_stress[ended_year - 1] = simulation.stats.get_stress()
			ended_year_metrics.append({
				"year": ended_year,
				"start_credits": year_start_credits[ended_year - 1],
				"start_stress": year_start_stress[ended_year - 1],
				"end_credits": year_end_credits[ended_year - 1],
				"end_stress": year_end_stress[ended_year - 1],
				"age": result.age,
				"diseased_periods": year_diseased_count[ended_year - 1]
			})

	var ending_id: String = _evaluate_ending(simulation)
	var has_ending: bool = not ending_id.is_empty()

	var campaign_result := {
		"strategy": strategy,
		"seed": seed,
		"ending_id": ending_id,
		"has_ending": has_ending,
		"final_credits": simulation.economy.get_credits(),
		"final_stress": simulation.stats.get_stress(),
		"diseased_periods": total_diseased_periods,
		"minimum_credits": minimum_credits,
		"fled": "NOT ASSESSED",
		"mission_count": simulation._missions_technical_completed,
		"year_metrics": ended_year_metrics
	}

	_results.append(campaign_result)

	if _results.size() % 100 == 0:
		print("  Completed %d/%d campaigns..." % [_results.size(), _n_campaigns * STRATEGIES.size()])


func _evaluate_ending(simulation: SimulationCore) -> String:
	if _endings_blocked:
		return ""
	var selected: EndingDef = _ending_evaluator.evaluate_simulation(simulation)
	if selected == null:
		return ""
	return selected.id


func _choose_activity(simulation: SimulationCore, strategy: String, period_idx: int, seed: int) -> String:
	var period: int = simulation.calendar.get_period()
	var credits: int = simulation.economy.get_credits()

	var can_do_mission: bool = not simulation.stats.is_mission_blocked_by_disease()

	match strategy:
		"guerreira":
			if period == 1:
				var cost: int = simulation.activities.get_course_cost("curso_tecnologia", 1)
				if credits >= cost:
					return "study_curso_tecnologia_l1"
				return "work_trabalho_reparo_leve"
			if period == 2:
				if can_do_mission:
					return "mission_missao_fisica_ruinas"
				return "work_trabalho_reparo_leve"
			return "leisure_descanso"

		"hacker_int":
			if period == 1:
				var level: int = simulation.activities.get_course_level("curso_tecnologia")
				var cost: int = simulation.activities.get_course_cost("curso_tecnologia", level)
				if credits >= cost:
					return "study_curso_tecnologia_l%d" % level
			if period == 2:
				if can_do_mission:
					return "mission_missao_tecnica"
				var level: int = simulation.activities.get_course_level("curso_tecnologia")
				var cost: int = simulation.activities.get_course_cost("curso_tecnologia", level)
				if credits >= cost:
					return "study_curso_tecnologia_l%d" % level
			return "leisure_descanso"

		"social_cha":
			if period == 1:
				var level: int = simulation.activities.get_course_level("curso_comunicacao")
				var cost: int = simulation.activities.get_course_cost("curso_comunicacao", level)
				if credits >= cost:
					return "study_curso_comunicacao_l%d" % level
			if period == 2:
				if can_do_mission:
					return "mission_missao_comunitaria"
				return "work_trabalho_reparo_leve"
			return "leisure_passeio_comunitario"

		"trabalhadora":
			if period == 1:
				var level: int = simulation.activities.get_job_level("trabalho_reparo_leve")
				if level < 2:
					return "work_trabalho_reparo_leve"
				return "work_trabalho_entrega_assistida"
			if period == 2:
				return "work_trabalho_entrega_assistida"
			return "leisure_descanso"

		"aleatoria":
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = seed + period_idx
			var roll: int = rng.randi_range(0, 100)
			if roll < 25:
				return _choose_activity(simulation, "guerreira", period_idx, seed)
			elif roll < 50:
				return _choose_activity(simulation, "hacker_int", period_idx, seed)
			elif roll < 75:
				return _choose_activity(simulation, "social_cha", period_idx, seed)
			elif roll < 90:
				return _choose_activity(simulation, "trabalhadora", period_idx, seed)
			elif roll < 95 and credits >= 8:
				return "study_curso_tecnologia_l1"
			else:
				return "work_trabalho_reparo_leve"

		"equilibrada":
			if period == 1:
				var level: int = simulation.activities.get_course_level("curso_tecnologia")
				var cost: int = simulation.activities.get_course_cost("curso_tecnologia", level)
				if credits >= cost:
					return "study_curso_tecnologia_l%d" % level
			if period == 2:
				if credits < 50 or not can_do_mission:
					return "work_trabalho_reparo_leve"
				return "mission_missao_tecnica"
			return "leisure_descanso"

		"pouco_descanso":
			if period == 1:
				var level: int = simulation.activities.get_course_level("curso_tecnologia")
				var cost: int = simulation.activities.get_course_cost("curso_tecnologia", level)
				if credits >= cost:
					return "study_curso_tecnologia_l%d" % level
			if period == 2:
				if can_do_mission:
					return "mission_missao_tecnica"
				var level: int = simulation.activities.get_course_level("curso_tecnologia")
				var cost: int = simulation.activities.get_course_cost("curso_tecnologia", level)
				if credits >= cost:
					return "study_curso_tecnologia_l%d" % level
				return "work_trabalho_reparo_leve"
			return "work_trabalho_reparo_leve"

		"so_lazer":
			return "leisure_descanso"

		_:
			if period == 1:
				return "study_curso_tecnologia_l1"
			if period == 2:
				return "work_trabalho_reparo_leve"
			return "leisure_descanso"


func _generate_reports() -> void:
	var date_str: String = _get_date_string()
	var md_path: String = "res://tests/reports/balance-%s.md" % date_str
	var csv_path: String = "res://tests/reports/balance-%s.csv" % date_str
	var csv_year_path: String = "res://tests/reports/balance-%s-years.csv" % date_str

	var dir := DirAccess.open("res://tests")
	if dir:
		if not dir.dir_exists("reports"):
			dir.make_dir("reports")

	_generate_campaign_csv(csv_path)
	_generate_yearly_csv(csv_year_path)
	_generate_markdown(md_path, date_str)

	print("\nReports generated:")
	print("  CSV (campaigns): %s" % csv_path)
	print("  CSV (years): %s" % csv_year_path)
	print("  MD: %s" % md_path)


func _get_date_string() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d%02d%02d" % [date.year, date.month, date.day]


func _generate_campaign_csv(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open CSV file: %s" % path)
		_finish(1)
		return

	file.store_line("strategy,seed,ending_id,has_ending,final_credits,final_stress,minimum_credits,diseased_periods,fled,mission_count")
	for result: Dictionary in _results:
		file.store_line("%s,%d,%s,%s,%d,%d,%d,%d,%s,%d"
			% [
				result.strategy,
				result.seed,
				result.ending_id,
				result.has_ending,
				result.final_credits,
				result.final_stress,
				result.minimum_credits,
				result.diseased_periods,
				result.fled,
				result.mission_count
			])

	file.close()


func _generate_yearly_csv(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open CSV file: %s" % path)
		_finish(1)
		return

	file.store_line("strategy,year,avg_start_credits,avg_start_stress,avg_end_credits,avg_end_stress,avg_age,total_diseased_periods")

	# Process each strategy
	for strategy: String in STRATEGIES:
		# Collect year data: year 1, 2, 3
		var year_1_data: Array = []
		var year_2_data: Array = []
		var year_3_data: Array = []

		for result: Dictionary in _results:
			if result.strategy != strategy:
				continue
			for yd: Dictionary in result.year_metrics:
				if yd.year == 1:
					year_1_data.append(yd)
				elif yd.year == 2:
					year_2_data.append(yd)
				else:
					year_3_data.append(yd)

		for year_idx: int in range(3):
			var data: Array
			match year_idx:
				0: data = year_1_data
				1: data = year_2_data
				2: data = year_3_data

			if data.is_empty():
				continue

			# Calculate averages
			var sum_start_credits: int = 0
			var sum_start_stress: int = 0
			var sum_end_credits: int = 0
			var sum_end_stress: int = 0
			var sum_age: int = 0
			var total_diseased: int = 0

			for d: Dictionary in data:
				sum_start_credits += d.start_credits
				sum_start_stress += d.start_stress
				sum_end_credits += d.end_credits
				sum_end_stress += d.end_stress
				sum_age += d.age
				total_diseased += d.diseased_periods

			var n: int = data.size()
			file.store_line("%s,%d,%.1f,%.1f,%.1f,%.1f,%.1f,%d"
				% [strategy, year_idx + 1,
				   float(sum_start_credits) / n,
				   float(sum_start_stress) / n,
				   float(sum_end_credits) / n,
				   float(sum_end_stress) / n,
				   float(sum_age) / n,
				   total_diseased])

	file.close()


func _generate_markdown(path: String, date_str: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open MD file: %s" % path)
		_finish(1)
		return

	file.store_line("# Balance Check Report")
	file.store_line("")
	file.store_line("**Date:** %s" % date_str)
	file.store_line("**Campaigns per strategy:** %d" % _n_campaigns)
	file.store_line("**Total campaigns:** %d" % _results.size())
	file.store_line("")
	file.store_line("## Summary")
	file.store_line("")

	var strategy_stats: Dictionary = {}
	for result: Dictionary in _results:
		var strategy: String = result.strategy
		if not strategy_stats.has(strategy):
			strategy_stats[strategy] = {
				"count": 0,
				"total_credits": 0,
				"total_stress": 0,
				"minimum_credits": result.minimum_credits,
				"negative_balance_campaigns": 0,
				"endings": {},
				"diseased_count": 0,
				"fled_count": 0,
				"year_data": []
			}
		var stats: Dictionary = strategy_stats[strategy]
		stats.count += 1
		stats.total_credits += result.final_credits
		stats.total_stress += result.final_stress
		stats.minimum_credits = mini(stats.minimum_credits, result.minimum_credits)
		if result.minimum_credits < 0:
			stats.negative_balance_campaigns += 1
		stats.diseased_count += result.diseased_periods
		stats.fled_count += 1 if result.fled != "NOT ASSESSED" else 0

		if result.has_ending:
			var ending_id: String = result.ending_id
			if not stats.endings.has(ending_id):
				stats.endings[ending_id] = 0
			stats.endings[ending_id] += 1

		# Aggregate year metrics for average calculation
		for year_data: Dictionary in result.year_metrics:
			stats.year_data.append(year_data)

	file.store_line("### Campaign Distribution by Strategy")
	file.store_line("")
	file.store_line("| Strategy | Campaigns | Avg Credits | Avg Stress | Lowest Balance | Campaigns Below Zero | Disease Rate | Flee Rate |")
	file.store_line("|----------|-----------|-------------|------------|----------------|-----------------------|--------------|-----------|")

	for strategy: String in STRATEGIES:
		if strategy_stats.has(strategy):
			var s: Dictionary = strategy_stats[strategy]
			var avg_credits: float = float(s.total_credits) / float(s.count)
			var avg_stress: float = float(s.total_stress) / float(s.count)
			var total_periods: int = s.count * 108
			var disease_rate: float = float(s.diseased_count) / float(total_periods) * 100
			file.store_line("| %s | %d | %.1f | %.1f | %d | %d | %.1f%% | NOT ASSESSED |"
				% [strategy, s.count, avg_credits, avg_stress, s.minimum_credits, s.negative_balance_campaigns, disease_rate])

	file.store_line("")
	file.store_line("### Ending Distribution")
	file.store_line("")

	if _endings_blocked:
		file.store_line("**NOT ASSESSED** — Ending distribution is unavailable because `assets/data/endings.json` failed to load.")
		file.store_line("")
		file.store_line("The `EndingEvaluator.load_endings_from_data()` validation rejects the catalog: every entry requires `priority` (integer 1–15, unique) and `is_default` (boolean, exactly one true). The current `endings.json` is missing these fields, so no ending can be selected and all campaigns report `ending_id` empty in the CSV.")
		file.store_line("")
		file.store_line("This is a data-blocker, not a simulation result. Fixing the catalog (adding `priority`/`is_default` per `design/gdd/endings.md`) will unblock ending evaluation on the next run.")
		file.store_line("")
		file.store_line("### Endings by Strategy")
		file.store_line("")
		file.store_line("**NOT ASSESSED** — Same blocker as above; per-strategy ending counts are unavailable.")
		file.store_line("")
		file.store_line("### Endings Above 40%% Threshold by Strategy")
		file.store_line("")
		file.store_line("**NOT ASSESSED** — Threshold comparison cannot run while the ending catalog is blocked.")
		file.store_line("")
	else:
		# Build complete ending distribution including zero-occurrence endings
		var all_endings: Dictionary = {}
		for ending_id: String in ALL_ENDING_IDS:
			all_endings[ending_id] = 0
		for strategy: String in STRATEGIES:
			if strategy_stats.has(strategy):
				for ending_id: String in strategy_stats[strategy].endings.keys():
					if not all_endings.has(ending_id):
						all_endings[ending_id] = 0
					all_endings[ending_id] += strategy_stats[strategy].endings[ending_id]

		file.store_line("| Ending | Total |")
		file.store_line("|--------|-------|")
		for ending_id: String in ALL_ENDING_IDS:
			var count: int = all_endings.get(ending_id, 0)
			file.store_line("| %s | %d |" % [ending_id, count])

		file.store_line("")
		file.store_line("### Endings with Zero Occurrences")
		file.store_line("")
		var zero_endings: Array[String] = []
		for ending_id: String in ALL_ENDING_IDS:
			if all_endings.get(ending_id, 0) == 0:
				zero_endings.append(ending_id)
		if zero_endings.size() == 0:
			file.store_line("All 15 endings were achieved at least once.")
		else:
			file.store_line("The following endings had zero occurrences:")
			for ending_id: String in zero_endings:
				file.store_line("- %s" % ending_id)

		file.store_line("")
		file.store_line("### Endings by Strategy")
		file.store_line("")

		for strategy: String in STRATEGIES:
			if not strategy_stats.has(strategy):
				continue
			file.store_line("**%s**:" % strategy)
			for ending_id: String in ALL_ENDING_IDS:
				var count: int = strategy_stats[strategy].endings.get(ending_id, 0)
				if count > 0:
					file.store_line("- %s: %d" % [ending_id, count])
			file.store_line("")

		file.store_line("### Endings Above 40%% Threshold by Strategy")
		file.store_line("")
		file.store_line("Threshold: strictly greater than 40%% of campaigns per strategy (calculated per strategy)")
		file.store_line("")
		for strategy: String in STRATEGIES:
			if not strategy_stats.has(strategy):
				continue
			var s: Dictionary = strategy_stats[strategy]
			var threshold_min: int = int(float(s.count) * 0.4) + 1  # Strictly greater than 40%
			file.store_line("**%s** (threshold: > %d of %d):" % [strategy, threshold_min - 1, s.count])
			var any_above: bool = false
			for ending_id: String in ALL_ENDING_IDS:
				var count: int = s.endings.get(ending_id, 0)
				if count > threshold_min - 1:
					file.store_line("- %s: %d (%.1f%%)" % [ending_id, count, float(count) / float(s.count) * 100])
					any_above = true
			if not any_above:
				file.store_line("- None")
			file.store_line("")

	file.store_line("")
	file.store_line("### Flee Metric")
	file.store_line("")
	file.store_line("**NOT ASSESSED** — The current bots always choose FIGHT for encounters, so this run does not exercise FLEE or HIDE. The GDD defines those actions, but this run cannot estimate their frequency or outcomes.")

	file.store_line("")
	file.store_line("## Annual Metrics by Strategy")
	file.store_line("")
	file.store_line("Averaged over %d campaigns per strategy." % _n_campaigns)
	file.store_line("")
	file.store_line("| Strategy | Year | Avg Start Credits | Avg Start Stress | Avg End Credits | Avg End Stress | Avg Age | Total Diseased Period |")
	file.store_line("|----------|------|-------------------|------------------|-----------------|----------------|---------|------------------------|")

	for strategy: String in STRATEGIES:
		if not strategy_stats.has(strategy):
			continue
		var ys: Dictionary = strategy_stats[strategy]
		# Year 1 data (index 0)
		var year_1_data: Array = []
		var year_2_data: Array = []
		var year_3_data: Array = []
		for yd: Dictionary in ys.year_data:
			if yd.year == 1:
				year_1_data.append(yd)
			elif yd.year == 2:
				year_2_data.append(yd)
			else:
				year_3_data.append(yd)

		for year_idx: int in range(3):
			var data: Array
			match year_idx:
				0: data = year_1_data
				1: data = year_2_data
				2: data = year_3_data

			if data.is_empty():
				continue

			var avg_start_credits: float = 0.0
			var avg_start_stress: float = 0.0
			var avg_end_credits: float = 0.0
			var avg_end_stress: float = 0.0
			var total_diseased: int = 0

			for d: Dictionary in data:
				avg_start_credits += float(d.start_credits)
				avg_start_stress += float(d.start_stress)
				avg_end_credits += float(d.end_credits)
				avg_end_stress += float(d.end_stress)
				total_diseased += d.diseased_periods

			var n: int = data.size()
			avg_start_credits /= n
			avg_start_stress /= n
			avg_end_credits /= n
			avg_end_stress /= n

			file.store_line("| %s | %d | %.1f | %.1f | %.1f | %.1f | %d | %d |"
				% [strategy, year_idx + 1, avg_start_credits, avg_start_stress, avg_end_credits, avg_end_stress, 12 + year_idx, total_diseased])

	file.store_line("")
	file.store_line("## Interpretation Limits")
	file.store_line("")
	file.store_line("- Annual credit and Stress values are averages of campaign start/end snapshots, not averages across every period within the year.")
	file.store_line("- Matching year-end and next-year-start credit snapshots do not independently verify the amount or timing of a stipend; use a focused test or transaction-level evidence.")
	file.store_line("- Positive final credits do not prove the balance never went negative. `Lowest Balance` records the minimum observed after each activity and encounter resolution in each campaign.")
	file.store_line("- This report does not verify exact per-action Stress deltas. Use focused tests for rest, study, work, and mission deltas.")
	file.store_line("- Disease percentages are observations. The GDD defines the disease transition threshold, not an expected disease-rate target.")

	file.store_line("")
	file.store_line("## Disease Analysis")
	file.store_line("")
	file.store_line("**Metric Definition:** Number of campaign periods where disease was active (`is_diseased_after=true`). Disease threshold is `60 + floor(STA/5)` per `stats-and-stress.md`.")
	file.store_line("")
	file.store_line("**Disease Threshold Reference:**")
	file.store_line("- STA 20: threshold 64 (disease at Stress >= 64)")
	file.store_line("- STA 100: threshold 80 (disease at Stress >= 80)")
	file.store_line("")
	file.store_line("**Observed Disease Rates:**")
	file.store_line("")
	file.store_line("| Strategy | Disease Periods | %% of Periods |")
	file.store_line("|----------|-----------------|---------------|")
	for strategy: String in STRATEGIES:
		if strategy_stats.has(strategy):
			var s: Dictionary = strategy_stats[strategy]
			var total_periods: int = s.count * 108
			var disease_rate: float = float(s.diseased_count) / float(total_periods) * 100
			file.store_line("| %s | %d | %.1f%% |" % [strategy, s.diseased_count, disease_rate])

	file.store_line("")
	file.store_line("## Data Sources")
	file.store_line("")
	file.store_line("- `design/gdd/endings.md` - Ending conditions and priorities")
	file.store_line("- `design/gdd/stats-and-stress.md` - Stats, stress, disease thresholds")
	file.store_line("- `design/gdd/activities.md` - Activity effects and stress changes")
	file.store_line("- `design/gdd/economy.md` - Credits system and income")
	file.store_line("- `design/gdd/events.md` - Event options and effects")
	file.store_line("- `design/gdd/auto-combat.md` - Encounter resolution")
	file.store_line("")

	file.close()


func _finish(code: int) -> void:
	if _run_errors > 0:
		print("\nErrors encountered: %d" % _run_errors)
		code = 1
	_exit_code = code
	quit(_exit_code)