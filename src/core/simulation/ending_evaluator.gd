extends RefCounted
class_name EndingEvaluator

const STAT_FIELDS: Array[String] = ["int", "str", "cha", "ref", "sta", "eth"]
const REPUTATION_FIELDS: Array[String] = ["hacker_rep", "social_rep", "fighter_rep"]
const FLAG_FIELDS: Array[String] = [
	"community_help",
	"criminal_record",
	"disappear_from_society",
	"tech_experiments"
]
const MISSION_COUNT_FIELD: String = "missoes_tecnicas_concluidas"

var _ending_defs: Array[EndingDef] = []
var _default_ending_id: String = ""


func load_endings(json_path: String) -> bool:
	if not FileAccess.file_exists(json_path):
		push_error("Ending data file does not exist: %s." % json_path)
		return false
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Could not open endings file: %s." % json_path)
		return false
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Invalid JSON in %s at line %d: %s."
			% [json_path, parser.get_error_line(), parser.get_error_message()]
		)
		return false
	return load_endings_from_data(parser.data)


func load_endings_from_data(data: Variant) -> bool:
	_ending_defs.clear()
	_default_ending_id = ""
	if not data is Dictionary:
		push_error("Endings data must be a JSON object.")
		return false
	var entries: Variant = data.get("endings", null)
	if not entries is Array or entries.is_empty():
		push_error("Endings data must contain a non-empty 'endings' array.")
		return false

	for entry: Variant in entries:
		if not entry is Dictionary:
			push_error("Endings data contains an invalid entry.")
			_ending_defs.clear()
			return false
		var id: Variant = entry.get("id", null)
		var ending_name: Variant = entry.get("name", null)
		var description: Variant = entry.get("description", null)
		var priority: Variant = entry.get("priority", null)
		var is_default: Variant = entry.get("is_default", false)
		var conditions: Variant = entry.get("conditions", {})
		var metadata_valid: bool = (
			id is String and not id.is_empty()
			and ending_name is String and not ending_name.is_empty()
			and description is String and not description.is_empty()
			and _is_positive_integer(priority)
			and (is_default == null or typeof(is_default) == TYPE_BOOL)
			and conditions is Dictionary
		)
		var conditions_valid: bool = conditions is Dictionary and _validate_condition_node(
			conditions
		)
		if (
			not metadata_valid
			or not conditions_valid
		):
			push_error(
				"Ending entry '%s' has invalid metadata (%s) or conditions (%s)."
				% [str(id), metadata_valid, conditions_valid]
			)
			_ending_defs.clear()
			return false
		_ending_defs.append(EndingDef.from_dict(entry))

	if not _validate_endings():
		_ending_defs.clear()
		_default_ending_id = ""
		return false
	return true


func _validate_endings() -> bool:
	var seen_ids: Dictionary = {}
	var seen_priorities: Dictionary = {}
	var default_count: int = 0
	var highest_priority: int = 0
	for ending: EndingDef in _ending_defs:
		if seen_ids.has(ending.id):
			push_error("Duplicate ending ID: %s." % ending.id)
			return false
		if seen_priorities.has(ending.priority):
			push_error("Duplicate ending priority: %d." % ending.priority)
			return false
		seen_ids[ending.id] = true
		seen_priorities[ending.priority] = true
		highest_priority = maxi(highest_priority, ending.priority)
		if ending.is_default:
			default_count += 1
			_default_ending_id = ending.id
			if not ending.conditions.is_empty():
				push_error("Default ending '%s' must not have conditions." % ending.id)
				return false
	if default_count != 1:
		push_error("Endings data must declare exactly one default ending.")
		return false
	var default_ending: EndingDef = get_ending_by_id(_default_ending_id)
	if default_ending == null or default_ending.priority != highest_priority:
		push_error("Default ending must have the lowest selection priority (last in order).")
		return false
	return true


func _validate_condition_node(node: Variant) -> bool:
	if not node is Dictionary:
		return false
	if node.is_empty():
		return true
	if node.has("all") or node.has("and") or node.has("any") or node.has("or"):
		if node.size() != 1:
			return false
		var group_key: String = str(node.keys()[0])
		var children: Variant = node[group_key]
		if not children is Array or children.is_empty():
			return false
		for child: Variant in children:
			if not _validate_condition_node(child):
				return false
		return true
	if node.has("field"):
		return _validate_explicit_condition(node)
	for key: Variant in node:
		if not key is String or not _validate_legacy_condition(str(key), node[key]):
			return false
	return true


func _validate_explicit_condition(node: Dictionary) -> bool:
	if node.size() != 3:
		return false
	var field: Variant = node.get("field", null)
	var operator: Variant = node.get("op", null)
	var value: Variant = node.get("value", null)
	if not field is String or not operator is String:
		return false
	if FLAG_FIELDS.has(field):
		return typeof(value) == TYPE_BOOL and operator in ["==", "!="]
	if not _is_numeric_field(field) or typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if not operator in [">", ">=", "<", "<=", "==", "!="]:
		return false
	return _numeric_value_in_range(field, float(value))


func _validate_legacy_condition(key: String, value: Variant) -> bool:
	if FLAG_FIELDS.has(key):
		return typeof(value) == TYPE_BOOL
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var parsed_field: Dictionary = _parse_numeric_field(key)
	if parsed_field.is_empty():
		return false
	return _numeric_value_in_range(str(parsed_field.field), float(value))


func _numeric_value_in_range(field: String, value: float) -> bool:
	if not is_finite(value) or value != floorf(value):
		return false
	if _is_mission_count_field(field):
		return value >= 0.0
	return value >= 0.0 and value <= 100.0


func _is_positive_integer(value: Variant) -> bool:
	return (
		typeof(value) in [TYPE_INT, TYPE_FLOAT]
		and float(value) >= 1.0
		and float(value) == floorf(float(value))
	)


func _is_numeric_field(field: String) -> bool:
	return STAT_FIELDS.has(field) or REPUTATION_FIELDS.has(field) or _is_mission_count_field(field)


func _is_mission_count_field(field: String) -> bool:
	return field == MISSION_COUNT_FIELD


func _parse_numeric_field(key: String) -> Dictionary:
	var operator: String = ">="
	var field: String = key
	var suffixes: Dictionary = {
		"_min": ">=",
		"_max": "<=",
		"_lt": "<",
		"_le": "<=",
		"_gt": ">",
		"_ge": ">=",
		"_eq": "=="
	}
	for suffix: String in suffixes:
		if key.ends_with(suffix):
			field = key.trim_suffix(suffix)
			operator = str(suffixes[suffix])
			break
	if not _is_numeric_field(field):
		return {}
	return {"field": field, "op": operator}


func evaluate(
	state: CharacterState,
	stats: StatsSystem,
	activities: ActivitySystem,
	mission_count: int = 0
) -> EndingDef:
	var default_ending: EndingDef = get_ending_by_id(_default_ending_id)
	for ending: EndingDef in _sorted_endings():
		if ending.is_default:
			continue
		if _evaluate_condition_node(
			ending.conditions, state, stats, activities, mission_count
		):
			return ending
	if default_ending == null:
		push_error("No valid default ending is loaded.")
	return default_ending


## Evaluates a simulation's current state for its ending.
## Usage: var ending: EndingDef = evaluator.evaluate_simulation(simulation)
func evaluate_simulation(simulation: SimulationCore) -> EndingDef:
	if simulation == null:
		push_error("Cannot evaluate an ending without a simulation.")
		return null
	var state_data: Dictionary = simulation.get_ending_state()
	if state_data.is_empty():
		push_error("Cannot evaluate an ending from an unavailable simulation state.")
		return null
	var state: CharacterState = _build_character_state(state_data)
	if state == null:
		return null
	return evaluate(
		state,
		simulation.stats,
		simulation.activities,
		int(state_data.get("missions_technical_completed", 0))
	)


func _sorted_endings() -> Array[EndingDef]:
	var ordered: Array[EndingDef] = _ending_defs.duplicate()
	ordered.sort_custom(
		func(left: EndingDef, right: EndingDef) -> bool:
			return left.priority < right.priority
	)
	return ordered


func _evaluate_condition_node(
	node: Dictionary,
	state: CharacterState,
	stats: StatsSystem,
	activities: ActivitySystem,
	mission_count: int
) -> bool:
	if node.is_empty():
		return true
	if node.has("all") or node.has("and"):
		var children: Array = node.get("all", node.get("and", []))
		for child: Dictionary in children:
			if not _evaluate_condition_node(child, state, stats, activities, mission_count):
				return false
		return true
	if node.has("any") or node.has("or"):
		var children: Array = node.get("any", node.get("or", []))
		for child: Dictionary in children:
			if _evaluate_condition_node(child, state, stats, activities, mission_count):
				return true
		return false
	if node.has("field"):
		return _evaluate_explicit_condition(node, state, stats, mission_count)
	for key: String in node:
		if not _evaluate_legacy_condition(key, node[key], state, stats, mission_count):
			return false
	return true


func _evaluate_explicit_condition(
	node: Dictionary,
	state: CharacterState,
	stats: StatsSystem,
	mission_count: int
) -> bool:
	var field: String = str(node.field)
	var operator: String = str(node.op)
	var value: Variant = node.value
	if FLAG_FIELDS.has(field):
		return _compare_boolean(_get_flag(field, state), bool(value), operator)
	return _compare_numeric(
		_get_numeric_value(field, stats, mission_count),
		float(value),
		operator
	)


func _evaluate_legacy_condition(
	key: String,
	value: Variant,
	state: CharacterState,
	stats: StatsSystem,
	mission_count: int
) -> bool:
	if FLAG_FIELDS.has(key):
		return _get_flag(key, state) == bool(value)
	var parsed_field: Dictionary = _parse_numeric_field(key)
	if parsed_field.is_empty():
		return false
	return _compare_numeric(
		_get_numeric_value(str(parsed_field.field), stats, mission_count),
		float(value),
		str(parsed_field.op)
	)


func _get_numeric_value(field: String, stats: StatsSystem, mission_count: int) -> float:
	match field:
		"int", "str", "cha", "ref", "sta", "eth":
			return float(stats.get_stat(field))
		"hacker_rep":
			return float(stats.get_reputation("hacker"))
		"social_rep":
			return float(stats.get_reputation("social"))
		"fighter_rep":
			return float(stats.get_reputation("fighter"))
		MISSION_COUNT_FIELD:
			return float(mission_count)
	return 0.0


func _get_flag(field: String, state: CharacterState) -> bool:
	match field:
		"community_help":
			return state.community_help
		"criminal_record":
			return state.criminal_record
		"disappear_from_society":
			return state.disappear_from_society
		"tech_experiments":
			return state.tech_experiments
	return false


func _compare_numeric(actual: float, expected: float, operator: String) -> bool:
	match operator:
		">":
			return actual > expected
		">=":
			return actual >= expected
		"<":
			return actual < expected
		"<=":
			return actual <= expected
		"==":
			return actual == expected
		"!=":
			return actual != expected
	return false


func _compare_boolean(actual: bool, expected: bool, operator: String) -> bool:
	match operator:
		"==":
			return actual == expected
		"!=":
			return actual != expected
	return false


func _condition_distance(
	node: Dictionary,
	state: CharacterState,
	stats: StatsSystem,
	mission_count: int
) -> int:
	if node.is_empty():
		return 0
	if node.has("all") or node.has("and"):
		var total: int = 0
		var children: Array = node.get("all", node.get("and", []))
		for child: Dictionary in children:
			total += _condition_distance(child, state, stats, mission_count)
		return total
	if node.has("any") or node.has("or"):
		var shortest: int = 2147483647
		var children: Array = node.get("any", node.get("or", []))
		for child: Dictionary in children:
			shortest = mini(
				shortest,
				_condition_distance(child, state, stats, mission_count)
			)
		return shortest
	if node.has("field"):
		return _explicit_condition_distance(node, state, stats, mission_count)
	var total: int = 0
	for key: String in node:
		total += _legacy_condition_distance(key, node[key], state, stats, mission_count)
	return total


func _explicit_condition_distance(
	node: Dictionary,
	state: CharacterState,
	stats: StatsSystem,
	mission_count: int
) -> int:
	var field: String = str(node.field)
	var operator: String = str(node.op)
	var expected: Variant = node.value
	if FLAG_FIELDS.has(field):
		return 0 if _compare_boolean(_get_flag(field, state), bool(expected), operator) else 1
	return _numeric_distance(
		_get_numeric_value(field, stats, mission_count),
		float(expected),
		operator
	)


func _legacy_condition_distance(
	key: String,
	value: Variant,
	state: CharacterState,
	stats: StatsSystem,
	mission_count: int
) -> int:
	if FLAG_FIELDS.has(key):
		return 0 if _get_flag(key, state) == bool(value) else 1
	var parsed_field: Dictionary = _parse_numeric_field(key)
	if parsed_field.is_empty():
		return 2147483647
	return _numeric_distance(
		_get_numeric_value(str(parsed_field.field), stats, mission_count),
		float(value),
		str(parsed_field.op)
	)


func _numeric_distance(actual: float, expected: float, operator: String) -> int:
	if _compare_numeric(actual, expected, operator):
		return 0
	match operator:
		">":
			return int(expected - actual) + 1
		">=":
			return int(expected - actual)
		"<":
			return int(actual - expected) + 1
		"<=":
			return int(actual - expected)
		"==":
			return int(absf(actual - expected))
		"!=":
			return 1
	return 2147483647


func get_ending_by_id(id: String) -> EndingDef:
	for ending: EndingDef in _ending_defs:
		if ending.id == id:
			return ending
	return null


func get_all_ending_ids() -> Array[String]:
	var ids: Array[String] = []
	for ending: EndingDef in _ending_defs:
		ids.append(ending.id)
	return ids


func get_ending_promotion_debug(simulation: SimulationCore) -> Dictionary:
	if simulation == null:
		return {}
	var state_data: Dictionary = simulation.get_ending_state()
	if state_data.is_empty():
		push_error("Cannot inspect ending promotion from an unavailable simulation state.")
		return {}
	var state: CharacterState = _build_character_state(state_data)
	if state == null:
		return {}
	var mission_count: int = int(state_data.get("missions_technical_completed", 0))
	var selected: EndingDef = evaluate(
		state,
		simulation.stats,
		simulation.activities,
		mission_count
	)
	var results: Dictionary = {}
	for ending: EndingDef in _ending_defs:
		var qualified: bool = ending.is_default or _evaluate_condition_node(
			ending.conditions, state, simulation.stats, simulation.activities, mission_count
		)
		var distance: int = 0 if ending.is_default else _condition_distance(
			ending.conditions, state, simulation.stats, mission_count
		)
		results[ending.id] = {
			"selected": selected != null and selected.id == ending.id,
			"qualified": qualified,
			"distance": distance,
			"priority": ending.priority,
			"shadowed_by": (
				selected.id
				if qualified and not ending.is_default and selected != null and selected.id != ending.id
				else ""
			)
		}
	return results


func _build_character_state(state_data: Dictionary) -> CharacterState:
	var stats_value: Variant = state_data.get("stats", null)
	var reputations_value: Variant = state_data.get("reputations", null)
	if not stats_value is Dictionary or not reputations_value is Dictionary:
		push_error("Ending state has invalid stats or reputations.")
		return null

	var state: CharacterState = CharacterState.new()
	state.stats = stats_value.duplicate(true)
	state.reputations = reputations_value.duplicate(true)
	state.tech_experiments = bool(state_data.get("tech_experiments", false))
	state.criminal_record = bool(state_data.get("criminal_record", false))
	state.community_help = bool(state_data.get("community_help", false))
	state.disappear_from_society = bool(state_data.get("disappear_from_society", false))
	return state


func _create_default_ending() -> EndingDef:
	var ending: EndingDef = get_ending_by_id(_default_ending_id)
	if ending != null:
		return ending
	push_error("Cannot create a fallback ending without a loaded default ending.")
	return null


func reset() -> void:
	_ending_defs.clear()
	_default_ending_id = ""