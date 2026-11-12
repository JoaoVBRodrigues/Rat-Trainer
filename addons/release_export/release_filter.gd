@tool
extends EditorExportPlugin

const DEV_AUTOLOADS := ["autoload/FunplayMcpRuntimeBridge", "autoload/_mcp_game_helper"]
var _saved: Dictionary = {}

func _get_name() -> String:
	return "MestreDaMesaReleaseFilter"

func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_saved.clear()
	for key in DEV_AUTOLOADS:
		if ProjectSettings.has_setting(key):
			_saved[key] = ProjectSettings.get_setting(key)
			ProjectSettings.clear(key)

func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if path.begins_with("res://addons/funplay_mcp/") or path.begins_with("res://addons/godot_ai/") or path.begins_with("res://.funplay/") or path.begins_with("res://tests/") or path.begins_with("res://scripts/") or path.begins_with("res://docs/"):
		skip()

func _export_end() -> void:
	for key in _saved:
		ProjectSettings.set_setting(key, _saved[key])
	_saved.clear()
