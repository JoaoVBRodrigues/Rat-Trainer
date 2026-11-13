class_name DataLoader
extends RefCounted

const SUPPORTED_SCHEMA_VERSION: int = 1

var schema_version: int = 0
var calendar: Dictionary = {}
var stats: Array = []
var activities: Array = []
var items: Array = []
var events: Array = []
var endings: Array = []
var missions: Array = []
var random_events: Array = []
var load_errors: Array[String] = []
var validation_errors: Array[String] = []

signal load_complete
signal load_failed(error: String)


static func load_all(path: String = "res://assets/data") -> DataLoader:
	var loader := DataLoader.new()
	var schema_data: Dictionary = loader._read_json_object(
		path.path_join("schema_version.json"), "schema_version"
	)
	if schema_data.has("schema_version") and _is_number(schema_data["schema_version"]):
		loader.schema_version = int(schema_data["schema_version"])
	else:
		loader.load_errors.append(
			"%s: schema_version must be an integer."
			% path.path_join("schema_version.json")
		)

	loader.calendar = loader._read_data_dictionary(path, "calendar.json", "calendar")
	loader.stats = loader._read_data_array(path, "stats.json", "stats")
	loader.activities = loader._load_models(path, "activities.json", "activities", ActivityDef)
	loader.items = loader._load_models(path, "items.json", "items", ItemDef)

	var event_data: Dictionary = loader._read_data_object(path, "events.json", "events")
	loader.events = loader._models_from_array(event_data, "events", path.path_join("events.json"), EventDef)
	loader.random_events = loader._models_from_array(
		event_data, "random_events", path.path_join("events.json"), EventDef
	)
	loader.endings = loader._load_models(path, "endings.json", "endings", EndingDef)
	loader.missions = loader._load_models(path, "missions.json", "missions", MissionDef)

	loader.validation_errors = DataValidator.validate_all(loader)
	loader.validation_errors.append_array(loader.load_errors)
	if loader.validation_errors.is_empty():
		loader.load_complete.emit()
	else:
		loader.load_failed.emit("; ".join(loader.validation_errors))
	return loader


func is_valid() -> bool:
	return validation_errors.is_empty()


func _read_json_object(file_path: String, required_key: String = "") -> Dictionary:
	if not FileAccess.file_exists(file_path):
		load_errors.append("%s: data file does not exist." % file_path)
		return {}

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		load_errors.append(
			"%s: could not open data file (%s)." % [file_path, error_string(FileAccess.get_open_error())]
		)
		return {}

	var content: String = file.get_as_text()
	file.close()

	var parser := JSON.new()
	var parse_result: Error = parser.parse(content)
	if parse_result != OK:
		load_errors.append(
			"%s: invalid JSON at line %d: %s"
			% [file_path, parser.get_error_line(), parser.get_error_message()]
		)
		return {}

	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		load_errors.append("%s: expected a JSON object." % file_path)
		return {}
	if not required_key.is_empty() and not parsed.has(required_key):
		load_errors.append("%s: missing required key '%s'." % [file_path, required_key])
		return {}
	return parsed


func _read_data_object(base_path: String, file_name: String, required_key: String) -> Dictionary:
	var file_path: String = base_path.path_join(file_name)
	var data: Dictionary = _read_json_object(file_path, required_key)
	if data.is_empty():
		return {}

	if not data.has("schema_version") or not _is_number(data["schema_version"]):
		load_errors.append("%s: missing or invalid schema_version." % file_path)
	elif int(data["schema_version"]) != schema_version:
		load_errors.append(
			"%s: schema_version %s does not match schema_version.json (%d)."
			% [file_path, data["schema_version"], schema_version]
		)
	return data


func _read_data_dictionary(base_path: String, file_name: String, key: String) -> Dictionary:
	var file_path: String = base_path.path_join(file_name)
	var data: Dictionary = _read_data_object(base_path, file_name, key)
	var value: Variant = data.get(key)
	if not value is Dictionary:
		load_errors.append("%s: '%s' must be an object." % [file_path, key])
		return {}
	return value


func _read_data_array(base_path: String, file_name: String, key: String) -> Array:
	var file_path: String = base_path.path_join(file_name)
	var data: Dictionary = _read_data_object(base_path, file_name, key)
	var value: Variant = data.get(key)
	if not value is Array:
		load_errors.append("%s: '%s' must be an array." % [file_path, key])
		return []
	return value


func _load_models(
	base_path: String, file_name: String, key: String, model_class: Script
) -> Array:
	var data: Dictionary = _read_data_object(base_path, file_name, key)
	return _models_from_array(data, key, base_path.path_join(file_name), model_class)


func _models_from_array(
	data: Dictionary, key: String, file_path: String, model_class: Script
) -> Array:
	var value: Variant = data.get(key)
	if not value is Array:
		load_errors.append("%s: '%s' must be an array." % [file_path, key])
		return []

	var models: Array = []
	for index in value.size():
		var entry: Variant = value[index]
		if not entry is Dictionary:
			load_errors.append("%s: '%s[%d]' must be an object." % [file_path, key, index])
			continue
		models.append(model_class.from_dict(entry))
	return models


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
