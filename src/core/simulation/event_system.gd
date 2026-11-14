extends RefCounted
class_name EventSystem

const FIXED_EVENT_MONTHS: Array[int] = [3, 6, 9, 12]
const FIXED_EVENT_PERIOD: int = 3
const RANDOM_EVENT_MIN_CHANCE: int = 5
const RANDOM_EVENT_MAX_CHANCE: int = 15

var _events: Dictionary = {}  # id -> raw event dictionary
var _random_events: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## When true, also prints diagnostic decisions to Godot's output.
var debug_enabled: bool = false
## Most recent event decision, retained even when console debug output is disabled.
var last_debug_message: String = ""


func load_events(json_path: String) -> bool:
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("EventSystem: could not open %s" % json_path)
		return false

	var parser: JSON = JSON.new()
	var result: Error = parser.parse(file.get_as_text())
	file.close()
	if result != OK:
		push_error("EventSystem: invalid JSON in %s" % json_path)
		return false

	var data: Variant = parser.data
	if not data is Dictionary:
		push_error("EventSystem: expected JSON object in %s" % json_path)
		return false

	var events_data: Variant = data.get("events", [])
	var random_data: Variant = data.get("random_events", [])

	if events_data is Array:
		for entry in events_data:
			if entry is Dictionary:
				var id: String = str(entry.get("id", ""))
				if not id.is_empty():
					_events[id] = entry.duplicate(true)

	if random_data is Array:
		for entry in random_data:
			if entry is Dictionary:
				_random_events.append(entry.duplicate(true))

	return true


func get_fixed_event_for_date(year: int, month: int, period: int) -> Dictionary:
	if month not in FIXED_EVENT_MONTHS or period != FIXED_EVENT_PERIOD:
		return {}

	var event_id: String = _calculate_fixed_event_id(year, month)
	return _events.get(event_id, {})


func _calculate_fixed_event_id(year: int, month: int) -> String:
	var year_index: int = year - 1
	var month_index: int = int(FIXED_EVENT_MONTHS.find(month))
	return "e%02d" % (year_index * 4 + month_index + 1)


func should_trigger_random_event() -> bool:
	# Called when not in a fixed event period
	return rng.randi_range(1, 100) <= RANDOM_EVENT_MIN_CHANCE  # Base 5%


func roll_random_event(max_attr: int) -> Dictionary:
	var chance: int = _calculate_random_chance(max_attr)
	if _random_events.is_empty():
		_set_debug_message("Random event not triggered: the event pool is empty.")
		return {}

	var roll: int = rng.randi_range(0, 99)
	if roll >= chance:
		_set_debug_message(
			"Random event not triggered: roll %d >= chance %d%% (max attribute %d)."
			% [roll, chance, max_attr]
		)
		return {}

	var index: int = rng.randi_range(0, _random_events.size() - 1)
	var event: Dictionary = _random_events[index].duplicate(true)
	_set_debug_message(
		"Random event triggered: %s (roll %d < chance %d%%; max attribute %d)."
		% [str(event.get("id", "")), roll, chance, max_attr]
	)
	return event


## Records why a random event check was skipped.
## Example: record_random_check_skipped("fixed event e01 has priority").
func record_random_check_skipped(reason: String) -> void:
	_set_debug_message("Random event check skipped: %s." % reason)


func _set_debug_message(message: String) -> void:
	last_debug_message = message
	if debug_enabled:
		print("[EventSystem] %s" % message)


func _calculate_random_chance(max_attr: int) -> int:
	return clampi(RANDOM_EVENT_MIN_CHANCE + int(max_attr / 10), RANDOM_EVENT_MIN_CHANCE, RANDOM_EVENT_MAX_CHANCE)


func get_state() -> Dictionary:
	return {
		"loaded": !_events.is_empty()
	}


func load_state(state: Dictionary) -> bool:
	return true


func reset() -> void:
	rng = RandomNumberGenerator.new()


func get_event_by_id(id: String) -> Dictionary:
	if id.begins_with("e"):
		return _events.get(id, {})
	if id.begins_with("r"):
		for event in _random_events:
			if event.get("id", "") == id:
				return event.duplicate(true)
	return {}


func get_all_fixed_event_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _events.keys():
		ids.append(key)
	return ids


func get_all_random_event_ids() -> Array[String]:
	var ids: Array[String] = []
	for event in _random_events:
		var id: String = str(event.get("id", ""))
		if not id.is_empty():
			ids.append(id)
	return ids