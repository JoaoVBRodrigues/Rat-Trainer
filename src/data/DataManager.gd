class_name DataManager
extends Node

const SAVE_DIR: String = "user://saves"
const SAVE_EXTENSION: String = ".rat-save"
const SAVE_SLOT_COUNT: int = 3
const CURRENT_SCHEMA_VERSION: int = 1
const AUTOSAVE_ID: String = "autosave"
const MONTHLY_SNAPSHOT_ID: String = "monthly_snapshot"
const DEFAULT_SETTINGS: Dictionary = {
	"music_volume": 100,
	"sfx_volume": 100,
	"animation_speed": 100,
	"text_scale": 100
}

var save_dir: String = SAVE_DIR
var settings_path: String = "user://settings.json"

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
		return _report_save_failure(
			"Save slot must be between 0 and %d." % (SAVE_SLOT_COUNT - 1)
		)
	if not _capture_metadata():
		return false
	var path: String = _slot_path(slot)
	if not _write_save(path):
		return false
	save_completed.emit(slot)
	return true


func save_autosave() -> bool:
	if not _capture_metadata() or not _write_save(_save_id_path(AUTOSAVE_ID)):
		return false
	save_completed.emit(-1)
	return true


func save_monthly_snapshot() -> bool:
	if not _capture_metadata() or not _write_save(_save_id_path(MONTHLY_SNAPSHOT_ID)):
		return false
	save_completed.emit(-2)
	return true


func load_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return _report_load_failure(
			"Save slot must be between 0 and %d." % (SAVE_SLOT_COUNT - 1)
		)
	return _load_path(_slot_path(slot), "Save slot %d" % slot)


func load_save_id(save_id: String) -> bool:
	if save_id == AUTOSAVE_ID or save_id == MONTHLY_SNAPSHOT_ID:
		return _load_path(_save_id_path(save_id), save_id)
	if save_id.begins_with("slot_"):
		var parsed_slot: int = save_id.trim_prefix("slot_").to_int()
		if _is_valid_slot(parsed_slot) and save_id == "slot_%d" % parsed_slot:
			return load_slot(parsed_slot)
	return _report_load_failure("Unknown save identifier '%s'." % save_id)


func load_autosave() -> bool:
	return _load_path(_save_id_path(AUTOSAVE_ID), AUTOSAVE_ID)


func load_monthly_snapshot() -> bool:
	return _load_path(_save_id_path(MONTHLY_SNAPSHOT_ID), MONTHLY_SNAPSHOT_ID)


func get_current_data() -> Dictionary:
	return _current_data.duplicate(true)


func initialize_new_save(character_name: String = "Nyx Volt", guardian_name: String = "ORAC") -> void:
	var safe_name: String = character_name.strip_edges()
	var safe_guardian: String = guardian_name.strip_edges()
	if safe_name.is_empty():
		safe_name = "Nyx Volt"
	if safe_guardian.is_empty():
		safe_guardian = "ORAC"
	_current_data = {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"rng_state": 1,
		"character": {
			"name": safe_name,
			"guardian_name": safe_guardian,
			"age": 12,
			"credits": 200,
			"stats": {"STR": 15, "INT": 15, "CHA": 15, "REF": 15, "STA": 20, "ETH": 50},
			"stress": 0,
			"reputation": {"fighter": 0, "social": 0, "hacker": 0},
			"flags": {
				"community_help": false,
				"criminal_record": false,
				"tech_experiments": false,
				"disappear_from_society": false
			},
			"inventory": {
				"items": [],
				"equipped_hand": null,
				"equipped_protection": null
			}
		},
		"progress": {
			"turns_completed": 0,
			"ending_id": "",
			"unlocked_endings": []
		},
		"flow": {},
		"metadata": {
			"created_at": _timestamp(),
			"saved_at": "",
			"game_version": str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
		}
	}


func set_data(data: Dictionary) -> void:
	_current_data = data.duplicate(true)


func set_simulation_state(state: Dictionary) -> bool:
	if state.is_empty():
		return _report_save_failure("Cannot persist an empty simulation state.")
	var progress_value: Variant = _current_data.get("progress", {})
	if not progress_value is Dictionary:
		return _report_save_failure("Cannot persist simulation state without campaign progress.")
	var calendar_value: Variant = state.get("calendar", {})
	if not calendar_value is Dictionary:
		return _report_save_failure("Simulation state has no valid calendar.")
	var turns_value: Variant = calendar_value.get("completed_periods", null)
	if not turns_value is int or turns_value < 0 or turns_value > 108:
		return _report_save_failure("Simulation state has an invalid completed-period count.")
	var rng_state: Variant = state.get("rng_state", null)
	if not rng_state is int:
		return _report_save_failure("Simulation state has an invalid RNG state.")
	var persisted_state: Dictionary = state.duplicate(true)
	var persisted_calendar: Dictionary = calendar_value.duplicate(true)
	persisted_calendar.erase("completed_periods")
	persisted_state["calendar"] = persisted_calendar
	persisted_state.erase("rng_state")
	_current_data["simulation"] = persisted_state
	_current_data["rng_state"] = rng_state
	var progress: Dictionary = progress_value
	progress["turns_completed"] = turns_value
	_current_data["progress"] = progress
	return true


func set_flow_state(state: Dictionary) -> bool:
	if not _current_data.has("progress"):
		return _report_save_failure("Cannot persist schedule state without campaign progress.")
	_current_data["flow"] = state.duplicate(true)
	return true


func get_flow_state() -> Dictionary:
	var value: Variant = _current_data.get("flow", {})
	if not value is Dictionary:
		push_error("Saved schedule state must be an object.")
		return {}
	return value.duplicate(true)


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
	for slot: int in range(SAVE_SLOT_COUNT):
		if FileAccess.file_exists(_slot_path(slot)):
			slots.append(slot)
	return slots


func get_available_save_ids() -> Array[String]:
	var ids: Array[String] = []
	for save_id: String in [AUTOSAVE_ID, MONTHLY_SNAPSHOT_ID]:
		if FileAccess.file_exists(_save_id_path(save_id)):
			ids.append(save_id)
	for slot: int in range(SAVE_SLOT_COUNT):
		if FileAccess.file_exists(_slot_path(slot)):
			ids.append("slot_%d" % slot)
	return ids


func get_save_summary(save_id: String) -> Dictionary:
	var path: String = _path_for_save_id(save_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var data: Dictionary = _read_and_migrate_save(path, save_id)
	if data.is_empty():
		return {}
	var character: Dictionary = data.get("character", {})
	var progress: Dictionary = data.get("progress", {})
	return {
		"id": save_id,
		"name": str(character.get("name", "")),
		"turns_completed": int(progress.get("turns_completed", 0)),
		"ending_id": str(progress.get("ending_id", ""))
	}


func get_settings() -> Dictionary:
	if not FileAccess.file_exists(settings_path):
		return DEFAULT_SETTINGS.duplicate(true)
	var file: FileAccess = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		push_error("Could not open settings file '%s'." % settings_path)
		return {}
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		push_error("Settings file '%s' contains invalid JSON or a non-object root." % settings_path)
		return {}
	var settings: Dictionary = _normalize_json_numbers(parser.data)
	if not _validate_settings(settings):
		push_error("Settings file '%s' contains invalid values." % settings_path)
		return {}
	return settings.duplicate(true)


func save_settings(settings: Dictionary) -> bool:
	if not _validate_settings(settings):
		return _report_save_failure("Settings contain unsupported values.")
	return _write_json_atomic(settings_path, settings)


func _load_path(path: String, label: String) -> bool:
	if not FileAccess.file_exists(path):
		return _report_load_failure("%s was not found." % label)
	var loaded_data: Dictionary = _read_and_migrate_save(path, label)
	if loaded_data.is_empty():
		return false
	_current_data = loaded_data
	load_completed.emit(_current_data.duplicate(true))
	return true


func _read_and_migrate_save(path: String, label: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_report_load_failure("Could not open %s at '%s'." % [label, path])
		return {}
	var content: String = file.get_as_text()
	file.close()

	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(content)
	if parse_error != OK:
		_report_load_failure(
			"%s contains invalid JSON at line %d: %s."
			% [label, parser.get_error_line(), parser.get_error_message()]
		)
		return {}
	if not parser.data is Dictionary:
		_report_load_failure("%s must contain a JSON object." % label)
		return {}

	var save_data: Dictionary = _normalize_json_numbers(parser.data)
	if not _restore_exact_rng_state(save_data, content, label):
		return {}
	if not _migrate_save(save_data, label):
		return {}
	if not _validate_save(save_data, label):
		return {}
	return save_data


func _migrate_save(save_data: Dictionary, label: String) -> bool:
	var version: Variant = save_data.get("schema_version", 0)
	if not version is int or version < 0:
		_report_load_failure("%s has an invalid schema version." % label)
		return false
	if version > CURRENT_SCHEMA_VERSION:
		_report_load_failure(
			"%s uses unsupported schema version %d (this build supports %d)."
			% [label, version, CURRENT_SCHEMA_VERSION]
		)
		return false
	if version == 0:
		var character_value: Variant = save_data.get("character", {})
		var progress_value: Variant = save_data.get("progress", {})
		if not character_value is Dictionary or not progress_value is Dictionary:
			_report_load_failure("%s cannot be migrated: character or progress is not an object." % label)
			return false
		var character: Dictionary = character_value
		var progress: Dictionary = progress_value
		if not character.has("name"):
			character["name"] = "Nyx Volt"
		if not character.has("guardian_name"):
			character["guardian_name"] = "ORAC"
		if not progress.has("turns_completed"):
			var legacy_simulation: Variant = save_data.get("simulation", {})
			var calendar_value_for_turns: Variant = (
				legacy_simulation.get("calendar", {})
				if legacy_simulation is Dictionary
				else {}
			)
			var saved_turns: Variant = (
				calendar_value_for_turns.get("completed_periods", null)
				if calendar_value_for_turns is Dictionary
				else null
			)
			var turns: int = (
				saved_turns
				if saved_turns is int and saved_turns >= 0 and saved_turns <= 108
				else _turns_from_legacy_calendar(progress)
			)
			progress["turns_completed"] = turns
		if not progress.has("ending_id"):
			progress["ending_id"] = ""
		if not progress.has("unlocked_endings"):
			progress["unlocked_endings"] = []
		if not save_data.has("rng_state"):
			var legacy_simulation: Variant = save_data.get("simulation", {})
			var legacy_rng: Variant = (
				legacy_simulation.get("rng_state", 1)
				if legacy_simulation is Dictionary
				else 1
			)
			save_data["rng_state"] = legacy_rng if legacy_rng is int else 1
		var legacy_simulation_value: Variant = save_data.get("simulation", {})
		if legacy_simulation_value is Dictionary:
			var legacy_simulation_data: Dictionary = legacy_simulation_value
			var legacy_calendar: Variant = legacy_simulation_data.get("calendar", {})
			legacy_simulation_data.erase("rng_state")
			if legacy_calendar is Dictionary:
				var normalized_calendar: Dictionary = legacy_calendar.duplicate(true)
				normalized_calendar.erase("completed_periods")
				legacy_simulation_data["calendar"] = normalized_calendar
			save_data["simulation"] = legacy_simulation_data
		save_data["character"] = character
		save_data["progress"] = progress
		if not save_data.get("metadata") is Dictionary:
			save_data["metadata"] = {"created_at": "", "saved_at": "", "game_version": "legacy"}
		save_data["schema_version"] = CURRENT_SCHEMA_VERSION
	elif version != CURRENT_SCHEMA_VERSION:
		_report_load_failure("%s has no migration path from schema version %d." % [label, version])
		return false
	return true


func _turns_from_legacy_calendar(progress: Dictionary) -> int:
	var turns_value: Variant = progress.get("turns", progress.get("turns_completed", null))
	if turns_value is int and turns_value >= 0 and turns_value <= 108:
		return turns_value
	var year: int = int(progress.get("year", 1))
	var month: int = int(progress.get("month", 1))
	var period: int = int(progress.get("period", 1))
	if year < 1 or year > 3 or month < 1 or month > 12 or period < 1 or period > 3:
		return 0
	return ((year - 1) * 36) + ((month - 1) * 3) + period - 1


func _validate_save(save_data: Dictionary, label: String, load_context: bool = true) -> bool:
	var version: Variant = save_data.get("schema_version")
	var character_value: Variant = save_data.get("character")
	var progress_value: Variant = save_data.get("progress")
	if version != CURRENT_SCHEMA_VERSION:
		return _report_validation_failure("%s has an unsupported schema version." % label, load_context)
	if not character_value is Dictionary or not progress_value is Dictionary:
		return _report_validation_failure("%s is missing character or progress data." % label, load_context)
	var character: Dictionary = character_value
	var progress: Dictionary = progress_value
	if not character.get("name") is String or str(character.get("name", "")).strip_edges().is_empty():
		return _report_validation_failure("%s has an invalid character name." % label, load_context)
	if not character.get("guardian_name") is String:
		return _report_validation_failure("%s has an invalid guardian name." % label, load_context)
	var rng_state: Variant = save_data.get("rng_state", null)
	if not rng_state is int:
		return _report_validation_failure("%s has an invalid RNG state." % label, load_context)
	var turns: Variant = progress.get("turns_completed")
	var ending_id: Variant = progress.get("ending_id", "")
	var unlocked: Variant = progress.get("unlocked_endings", [])
	if not turns is int or turns < 0 or turns > 108:
		return _report_validation_failure("%s has an invalid completed-period count." % label, load_context)
	if not ending_id is String or not unlocked is Array:
		return _report_validation_failure("%s has invalid ending progress." % label, load_context)
	var seen_endings: Array[String] = []
	for ending: Variant in unlocked:
		if not ending is String or ending.is_empty() or seen_endings.has(ending):
			return _report_validation_failure("%s has invalid or duplicate unlocked endings." % label, load_context)
		seen_endings.append(ending)
	var simulation: Variant = save_data.get("simulation", {})
	if not simulation is Dictionary:
		return _report_validation_failure("%s has an invalid simulation state." % label, load_context)
	if simulation is Dictionary and not simulation.is_empty():
		var calendar: Variant = simulation.get("calendar", {})
		if not calendar is Dictionary:
			return _report_validation_failure("%s has an invalid calendar state." % label, load_context)
		if calendar.has("completed_periods") or simulation.has("rng_state"):
			return _report_validation_failure(
				"%s stores duplicated campaign or RNG state." % label,
				load_context
			)
	var flow: Variant = save_data.get("flow", {})
	if not flow is Dictionary:
		return _report_validation_failure("%s has an invalid schedule state." % label, load_context)
	return true


func _report_validation_failure(reason: String, load_context: bool) -> bool:
	if load_context:
		return _report_load_failure(reason)
	return _report_save_failure(reason)


func _capture_metadata() -> bool:
	if _current_data.is_empty():
		return _report_save_failure("Cannot save because there is no active campaign data.")
	if not _current_data.has("schema_version"):
		_current_data["schema_version"] = CURRENT_SCHEMA_VERSION
	var metadata_value: Variant = _current_data.get("metadata", {})
	if not metadata_value is Dictionary:
		return _report_save_failure("Cannot save because metadata is invalid.")
	var metadata: Dictionary = metadata_value
	metadata["saved_at"] = _timestamp()
	_current_data["metadata"] = metadata
	return _validate_save(_current_data, "Current save", false)


func _write_save(path: String) -> bool:
	if not _validate_save(_current_data, "Current save", false):
		return false
	return _write_json_atomic(path, _current_data)


func _write_json_atomic(path: String, data: Dictionary) -> bool:
	var parent_path: String = path.get_base_dir()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(parent_path)
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return _report_save_failure(
			"Could not create directory '%s': %s." % [parent_path, error_string(directory_error)]
		)

	var temporary_path: String = "%s.tmp" % path
	var backup_path: String = "%s.bak" % path
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _report_save_failure("Could not open temporary save file '%s'." % temporary_path)
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
		return _report_save_failure("Could not write '%s': %s." % [temporary_path, error_string(write_error)])

	var absolute_path: String = ProjectSettings.globalize_path(path)
	var absolute_temp: String = ProjectSettings.globalize_path(temporary_path)
	var absolute_backup: String = ProjectSettings.globalize_path(backup_path)
	var has_original: bool = FileAccess.file_exists(path)
	if has_original:
		if FileAccess.file_exists(backup_path):
			var remove_backup_error: Error = DirAccess.remove_absolute(absolute_backup)
			if remove_backup_error != OK:
				DirAccess.remove_absolute(absolute_temp)
				return _report_save_failure(
					"Could not clear previous backup '%s': %s."
					% [backup_path, error_string(remove_backup_error)]
				)
		var backup_error: Error = DirAccess.rename_absolute(absolute_path, absolute_backup)
		if backup_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return _report_save_failure(
				"Could not protect the previous save '%s': %s."
				% [path, error_string(backup_error)]
			)

	var replace_error: Error = DirAccess.rename_absolute(absolute_temp, absolute_path)
	if replace_error != OK:
		if has_original:
			var restore_error: Error = DirAccess.rename_absolute(absolute_backup, absolute_path)
			if restore_error != OK:
				return _report_save_failure(
					"Save replacement failed and the previous save could not be restored: %s."
					% error_string(restore_error)
				)
		DirAccess.remove_absolute(absolute_temp)
		return _report_save_failure(
			"Could not replace save file '%s': %s." % [path, error_string(replace_error)]
		)
	if has_original:
		DirAccess.remove_absolute(absolute_backup)
	return true


func _validate_settings(settings: Dictionary) -> bool:
	for key: String in DEFAULT_SETTINGS:
		var value: Variant = settings.get(key, null)
		if not value is int:
			return false
		if key == "music_volume" or key == "sfx_volume":
			if value < 0 or value > 100:
				return false
		elif key == "animation_speed":
			if value < 50 or value > 200:
				return false
		elif key == "text_scale":
			if value < 80 or value > 150:
				return false
	return true


func _normalize_json_numbers(value: Variant) -> Variant:
	if value is float:
		if absf(value) <= 9007199254740991.0 and value == floorf(value):
			return int(value)
		return value
	if value is Array:
		var normalized_array: Array = []
		for item: Variant in value:
			normalized_array.append(_normalize_json_numbers(item))
		return normalized_array
	if value is Dictionary:
		var normalized_dictionary: Dictionary = {}
		for key: Variant in value:
			normalized_dictionary[key] = _normalize_json_numbers(value[key])
		return normalized_dictionary
	return value


func _restore_exact_rng_state(save_data: Dictionary, content: String, label: String) -> bool:
	var pattern: RegEx = RegEx.new()
	if pattern.compile('"rng_state"\\s*:\\s*(-?[0-9]+)(?:\\s*[,}])') != OK:
		return _report_load_failure("Could not compile the RNG-state parser for %s." % label)
	var matches: Array[RegExMatch] = pattern.search_all(content)
	if matches.is_empty():
		return true
	var exact_rng_state: int = matches[0].get_string(1).to_int()
	if save_data.has("rng_state"):
		save_data["rng_state"] = exact_rng_state
		return true
	var simulation_value: Variant = save_data.get("simulation", {})
	if simulation_value is Dictionary and simulation_value.has("rng_state"):
		simulation_value["rng_state"] = exact_rng_state
		save_data["simulation"] = simulation_value
	return true


func _path_for_save_id(save_id: String) -> String:
	if save_id == AUTOSAVE_ID or save_id == MONTHLY_SNAPSHOT_ID:
		return _save_id_path(save_id)
	if save_id.begins_with("slot_"):
		var slot: int = save_id.trim_prefix("slot_").to_int()
		if _is_valid_slot(slot) and save_id == "slot_%d" % slot:
			return _slot_path(slot)
	return ""


func _slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%d%s" % [slot, SAVE_EXTENSION])


func _save_id_path(save_id: String) -> String:
	return save_dir.path_join("%s%s" % [save_id, SAVE_EXTENSION])


func _timestamp() -> String:
	return Time.get_datetime_string_from_system(true, true)


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SAVE_SLOT_COUNT


func _report_load_failure(reason: String) -> bool:
	push_error(reason)
	load_failed.emit(reason)
	return false


func _report_save_failure(reason: String) -> bool:
	push_error(reason)
	save_failed.emit(reason)
	return false
