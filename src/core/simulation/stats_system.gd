extends RefCounted
class_name StatsSystem

const INITIAL_STATS: Dictionary = {
	"str": 15, "int": 15, "cha": 15, "ref": 15, "sta": 20, "eth": 50
}
const INITIAL_REPUTATIONS: Dictionary = {"fighter": 0, "social": 0, "hacker": 0}
const DISEASE_STRESS_BASE: int = 60
const DISEASE_STA_DIVISOR: int = 5

var stats: Dictionary = {}
var stress: int = 0
var is_diseased: bool = false
var reputations: Dictionary = {}
var _disease_threshold: int = 64


func initialize() -> void:
	stats = INITIAL_STATS.duplicate(true)
	stress = 0
	is_diseased = false
	reputations = INITIAL_REPUTATIONS.duplicate(true)
	_recalculate_threshold()


func initialize_from_state(p_stats: Dictionary, p_stress: int) -> void:
	stats = INITIAL_STATS.duplicate(true)
	for stat_id: String in INITIAL_STATS:
		if p_stats.has(stat_id):
			stats[stat_id] = clampi(int(p_stats[stat_id]), 0, 100)
	stress = clampi(p_stress, 0, 100)
	reputations = INITIAL_REPUTATIONS.duplicate(true)
	_recalculate_threshold()
	check_and_update_disease()


func get_stat(stat_id: String) -> int:
	return int(stats.get(stat_id, 0))


func get_base_stats() -> Dictionary:
	return stats.duplicate(true)


func add_stat(stat_id: String, delta: int) -> int:
	if not stats.has(stat_id):
		push_error("Unknown stat ID '%s'." % stat_id)
		return 0
	var current_value: int = int(stats[stat_id])
	var new_value: int = clampi(current_value + delta, 0, 100)
	stats[stat_id] = new_value
	if stat_id == "sta":
		_recalculate_threshold()
	return new_value - current_value


func set_stat(stat_id: String, value: int) -> void:
	if not stats.has(stat_id):
		push_error("Unknown stat ID '%s'." % stat_id)
		return
	stats[stat_id] = clampi(value, 0, 100)
	if stat_id == "sta":
		_recalculate_threshold()


func get_stress() -> int:
	return stress


func add_stress(delta: int) -> int:
	var previous_value: int = stress
	stress = clampi(stress + delta, 0, 100)
	return stress - previous_value


func set_stress(value: int) -> void:
	stress = clampi(value, 0, 100)


func get_disease_threshold() -> int:
	return _disease_threshold


func is_at_or_above_disease_threshold() -> bool:
	return stress >= _disease_threshold


func check_disease_state() -> bool:
	return is_diseased


func check_disease() -> bool:
	return is_at_or_above_disease_threshold()


func check_and_update_disease() -> bool:
	var previous_state: bool = is_diseased
	is_diseased = is_at_or_above_disease_threshold()
	return previous_state != is_diseased


func get_reputation(rep_id: String) -> int:
	return int(reputations.get(rep_id, 0))


func add_reputation(rep_id: String, delta: int) -> int:
	if not reputations.has(rep_id):
		push_error("Unknown reputation ID '%s'." % rep_id)
		return 0
	var previous_value: int = int(reputations[rep_id])
	reputations[rep_id] = clampi(previous_value + delta, 0, 100)
	return int(reputations[rep_id]) - previous_value


func set_reputation(rep_id: String, value: int) -> void:
	if not reputations.has(rep_id):
		push_error("Unknown reputation ID '%s'." % rep_id)
		return
	reputations[rep_id] = clampi(value, 0, 100)


func is_mission_blocked_by_disease() -> bool:
	return is_diseased


func get_ethics() -> int:
	return get_stat("eth")


func add_ethics(delta: int) -> int:
	return add_stat("eth", delta)


func get_state() -> Dictionary:
	return {
		"stats": stats.duplicate(true),
		"stress": stress,
		"is_diseased": is_diseased,
		"reputations": reputations.duplicate(true)
	}


func load_state(state: Dictionary) -> bool:
	var saved_stats: Variant = state.get("stats")
	var saved_reputations: Variant = state.get("reputations", INITIAL_REPUTATIONS)
	var saved_stress: Variant = state.get("stress", 0)
	if not saved_stats is Dictionary or not saved_reputations is Dictionary:
		return false
	if not saved_stress is int or saved_stress < 0 or saved_stress > 100:
		return false
	for stat_id: String in INITIAL_STATS:
		if not saved_stats.has(stat_id):
			return false
		if not saved_stats[stat_id] is int or saved_stats[stat_id] < 0 or saved_stats[stat_id] > 100:
			return false
	for rep_id: String in INITIAL_REPUTATIONS:
		var rep_value: Variant = saved_reputations.get(rep_id, 0)
		if not rep_value is int or rep_value < 0 or rep_value > 100:
			return false

	stats = saved_stats.duplicate(true)
	stress = saved_stress
	reputations = INITIAL_REPUTATIONS.duplicate(true)
	for rep_id: String in INITIAL_REPUTATIONS:
		reputations[rep_id] = saved_reputations.get(rep_id, 0)
	_recalculate_threshold()
	check_and_update_disease()
	return true


func reset() -> void:
	initialize()


func _recalculate_threshold() -> void:
	_disease_threshold = DISEASE_STRESS_BASE + floori(float(get_stat("sta")) / DISEASE_STA_DIVISOR)
