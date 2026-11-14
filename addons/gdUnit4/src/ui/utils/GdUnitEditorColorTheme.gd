## Provides editor theme colors sourced from [EditorSettings].
## Add this node to the scene tree so it auto-refreshes colors when the
## editor theme changes ([constant EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED]).
@tool
class_name GdUnitEditorColorTheme
extends Node


# Literal value of EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED.
# The editor classes must not be referenced by name anywhere in this script:
# they do not exist in template builds (exported games, CLI runners), where a
# direct reference fails to PARSE this script and every script depending on
# it - the runtime Engine.is_editor_hint() guard never gets a chance.
const _NOTIFICATION_EDITOR_SETTINGS_CHANGED := 10000

static var _reported_missing_settings: Dictionary = {}

static var text_color := Color.WEB_GRAY
static var folder_color := Color.LIGHT_SKY_BLUE
static var function_definition_color := Color.ANTIQUE_WHITE
static var engine_type_color := Color.ANTIQUE_WHITE
static var value_color := Color.DODGER_BLUE

# test state colors
static var state_initial := Color.LIGHT_GRAY
static var state_success := Color.WEB_GREEN
static var state_warning := Color.DARK_GOLDENROD
static var state_flaky := Color.GREEN_YELLOW
static var state_failure := Color.ORANGE_RED
static var state_error := Color.DARK_RED
static var state_skipped := Color.WEB_GRAY
static var state_orphan := Color.DARK_GOLDENROD


func _ready() -> void:
	setup()


func _notification(what: int) -> void:
	if what == _NOTIFICATION_EDITOR_SETTINGS_CHANGED:
		setup()


static func setup() -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return
	# Resolved via the singleton registry instead of naming EditorInterface -
	# see the parse-time note above; on template builds the defaults apply.
	var editor_interface: Object = Engine.get_singleton("EditorInterface")
	var settings: Object = editor_interface.call("get_editor_settings")
	text_color = _get_editor_color(
		settings, "text_editor/theme/highlighting/text_color", Color.WEB_GRAY
	)
	folder_color = _get_editor_color(
		settings, "text_editor/theme/highlighting/member_variable_color", Color.LIGHT_SKY_BLUE
	)
	function_definition_color = _get_editor_color(
		settings,
		"text_editor/theme/highlighting/gdscript/function_definition_color",
		Color.ANTIQUE_WHITE
	)
	engine_type_color = _get_editor_color(
		settings, "text_editor/theme/highlighting/engine_type_color", Color.ANTIQUE_WHITE
	)
	value_color = _get_editor_color(
		settings, "text_editor/theme/highlighting/function_color", Color.DODGER_BLUE
	)
	# init test state colors
	state_initial = text_color
	state_success = _get_editor_color(
		settings, "editors/animation/onion_layers_future_color", Color.WEB_GREEN
	)
	state_warning = _get_editor_color(
		settings,
		"text_editor/theme/highlighting/comment_markers/warning_color",
		Color.DARK_GOLDENROD
	)
	state_flaky = _get_editor_color(
		settings,
		"text_editor/theme/highlighting/gdscript/node_reference_color",
		Color.GREEN_YELLOW
	)
	state_failure = _get_editor_color(
		settings,
		"text_editor/theme/highlighting/comment_markers/critical_color",
		Color.ORANGE_RED
	)
	state_error = _get_editor_color(
		settings, "editors/2d/smart_snapping_line_color", Color.DARK_RED
	)
	state_orphan = _get_editor_color(
		settings,
		"text_editor/theme/highlighting/string_placeholder_color",
		Color.DARK_GOLDENROD
	)


static func _get_editor_color(
	settings: Object, setting_path: String, fallback: Color
) -> Color:
	var setting_value: Variant = settings.call("get_setting", setting_path)
	if setting_value is Color:
		return setting_value
	if not _reported_missing_settings.has(setting_path):
		push_warning(
			"Godot editor setting '%s' is missing or is not a Color; using the default color."
			% setting_path
		)
		_reported_missing_settings[setting_path] = true
	return fallback
