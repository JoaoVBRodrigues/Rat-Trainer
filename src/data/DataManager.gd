class_name DataManager
extends Node

const SAVE_DIR: String = "user://saves"
const SAVE_EXTENSION: String = ".rat-save"
const SAVE_SLOT_COUNT: int = 3

var save_dir: String = SAVE_DIR

signal save_completed(slot: int)
signal load_completed(data: Dictionary)
signal load_failed(reason: String)
signal save_failed(reason: String)

var _current_data: Dictionary = {}


func _ready() -> void:
	_initialize_save_dir()


func _initialize_save_dir() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(save_dir)
	var error: Error = DirAccess.make_dir_recursive_absolute(absolute_path)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create save directory '%s': %s." % [save_dir, error_string(error)])


func save_current(slot: int) -> bool:
	if not _is_valid_slot(slot):
		var reason: String = "Save slot must be between 0 and %d." % (SAVE_SLOT_COUNT - 1)
		push_error(reason)
		save_failed.emit(reason)
		return false

	var save_data: Dictionary = _current_data.duplicate(true)
	var path: String = save_dir.path_join("slot_%d%s" % [slot, SAVE_EXTENSION])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var reason: String = "Could not open save slot %d at '%s'." % [slot, path]
		push_error(reason)
		save_failed.emit(reason)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		var reason: String = "Could not write save slot %d: %s." % [slot, error_string(write_error)]
		push_error(reason)
		save_failed.emit(reason)
		return false

	save_completed.emit(slot)
	return true


func load_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return _report_load_failure("Save slot must be between 0 and %d." % (SAVE_SLOT_COUNT - 1))

	var path: String = save_dir.path_join("slot_%d%s" % [slot, SAVE_EXTENSION])
	if not FileAccess.file_exists(path):
		return _report_load_failure("Save slot %d was not found." % slot)

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _report_load_failure("Could not open save slot %d." % slot)

	var content: String = file.get_as_text()
	file.close()

	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(content)
	if parse_error != OK:
		return _report_load_failure(
			"Save slot %d contains invalid JSON at line %d: %s."
			% [slot, parser.get_error_line(), parser.get_error_message()]
		)

	var parsed_data: Variant = parser.data
	if not parsed_data is Dictionary:
		return _report_load_failure("Save slot %d must contain a JSON object." % slot)

	_current_data = parsed_data
	load_completed.emit(_current_data.duplicate(true))
	return true


func get_current_data() -> Dictionary:
	return _current_data.duplicate(true)


func initialize_new_save() -> void:
	_current_data = {
		"character": {
			"name": "Nyx",
			"age": 12,
			"stats": {
				"STR": 15, "INT": 15, "CHA": 15,
				"REF": 15, "STA": 20, "ETH": 50
			},
			"stress": 0,
			"credits": 200
		},
		"progress": {
			"year": 1,
			"month": 1,
			"period": 1,
			"turns_completed": 0,
			"turns_total": 108,
			"ending_id": "",
			"unlocked_endings": []
		},
		"activities": {
			"courses": {"enrollment": [], "levels": {}},
			"jobs": {"current": null, "level": 1, "months": 0}
		},
		"reputation": {
			"FighterRep": 0,
			"SocialRep": 0,
			"HackerRep": 0
		},
		"flags": {},
		"events": {
			"completed": [],
			"missed": []
		},
		"inventory": {
			"weapons": [],
			"armor": [],
			"consumables": []
		},
		"economy": {
			"monthly_stipend": 200,
			"total_earned": 0,
			"total_spent": 0
		}
	}


func set_data(data: Dictionary) -> void:
	_current_data = data.duplicate(true)


func record_ending(ending_id: String) -> bool:
	if ending_id.is_empty():
		push_error("Cannot record an empty ending ID.")
		return false
	var progress_value: Variant = _current_data.get("progress", null)
	if not progress_value is Dictionary:
		push_error("Cannot record an ending without valid campaign progress data.")
		return false
	var progress: Dictionary = progress_value
	var unlocked_value: Variant = progress.get("unlocked_endings", [])
	if not unlocked_value is Array:
		push_error("Saved unlocked endings must be an array.")
		return false

	var unlocked_endings: Array[String] = []
	for value: Variant in unlocked_value:
		if not value is String or value.is_empty():
			push_error("Saved unlocked endings contains an invalid ending ID.")
			return false
		if unlocked_endings.has(value):
			push_error("Saved unlocked endings contains duplicate ID '%s'." % value)
			return false
		unlocked_endings.append(value)
	if not unlocked_endings.has(ending_id):
		unlocked_endings.append(ending_id)

	progress["ending_id"] = ending_id
	progress["unlocked_endings"] = unlocked_endings
	_current_data["progress"] = progress
	return true


func get_unlocked_endings() -> Array[String]:
	var result: Array[String] = []
	if _current_data.is_empty():
		return result
	var progress_value: Variant = _current_data.get("progress", null)
	if progress_value == null:
		return result
	if not progress_value is Dictionary:
		push_error("Saved campaign progress must be an object.")
		return result
	var unlocked_value: Variant = progress_value.get("unlocked_endings", [])
	if not unlocked_value is Array:
		push_error("Saved unlocked endings must be an array.")
		return result
	for value: Variant in unlocked_value:
		if not value is String or value.is_empty():
			push_error("Saved unlocked endings contains an invalid ending ID.")
			return []
		if result.has(value):
			push_error("Saved unlocked endings contains duplicate ID '%s'." % value)
			return []
		result.append(value)
	return result


func get_save_slots() -> Array[int]:
	var slots: Array[int] = []
	for slot in range(SAVE_SLOT_COUNT):
		var path: String = save_dir.path_join("slot_%d%s" % [slot, SAVE_EXTENSION])
		if FileAccess.file_exists(path):
			slots.append(slot)
	return slots


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SAVE_SLOT_COUNT


func _report_load_failure(reason: String) -> bool:
	push_error(reason)
	load_failed.emit(reason)
	return false
