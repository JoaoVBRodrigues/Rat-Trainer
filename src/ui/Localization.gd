class_name Localization
extends RefCounted

const DEFAULT_LOCALE: String = "pt_BR"
const STRINGS_PATH_FORMAT: String = "res://assets/data/strings_%s.json"

static var _loaded_locale: String = ""
static var _strings: Dictionary = {}


static func ensure_loaded(locale: String = DEFAULT_LOCALE) -> bool:
	if _loaded_locale == locale and not _strings.is_empty():
		return true

	var path: String = STRINGS_PATH_FORMAT % locale
	if not FileAccess.file_exists(path):
		push_error("Localization file does not exist: %s." % path)
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open localization file: %s." % path)
		return false

	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Invalid localization JSON at line %d: %s."
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return false
	if not parser.data is Dictionary:
		push_error("Localization data must be a JSON object: %s." % path)
		return false

	_strings = parser.data
	_loaded_locale = locale
	return true


static func text(string_id: String) -> String:
	var value: Variant = _resolve(string_id)
	if not value is String:
		push_error("Localization key '%s' must resolve to a string." % string_id)
		return "[missing:%s]" % string_id
	return value


static func format(string_id: String, values: Dictionary) -> String:
	return text(string_id).format(values)


static func get_string_array(string_id: String) -> Array[String]:
	var value: Variant = _resolve(string_id)
	if not value is Array:
		push_error("Localization key '%s' must resolve to an array." % string_id)
		return []

	var result: Array[String] = []
	for item: Variant in value:
		if not item is String:
			push_error("Localization key '%s' contains a non-string value." % string_id)
			return []
		result.append(item)
	return result


static func _resolve(string_id: String) -> Variant:
	if not ensure_loaded():
		return null

	var value: Variant = _strings
	for segment: String in string_id.split(".", false):
		if not value is Dictionary or not value.has(segment):
			push_error("Missing localization key '%s'." % string_id)
			return null
		value = value[segment]
	return value
