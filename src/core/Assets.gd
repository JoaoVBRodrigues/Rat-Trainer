class_name AssetResolver
extends Node

const VALID_CATEGORIES: Array[StringName] = [
	&"ui", &"characters", &"backgrounds", &"icons", &"items", &"monsters", &"endings", &"fx"
]

var art_root: String = "res://assets/art"
var placeholder_root: String = "res://assets/placeholders"

var _debug_mode: bool = false
var _texture_cache: Dictionary = {}
var _generated_cache: Dictionary = {}
var _warned_missing: Dictionary = {}
var _resolution_by_asset: Dictionary = {}
var _resolution_counts: Dictionary = {
	"final": 0,
	"placeholder": 0,
	"generated": 0
}
var _id_regex: RegEx = RegEx.new()


func _ready() -> void:
	_debug_mode = bool(ProjectSettings.get_setting("debug/show_asset_report", false))
	var regex_error: Error = _id_regex.compile("^[a-z0-9_]+$")
	if regex_error != OK:
		push_error("AssetResolver could not compile its asset ID validation pattern.")


func _exit_tree() -> void:
	if _debug_mode:
		print("[Assets] Resolution report: %s" % str(get_debug_report()))


func get_texture(id: StringName, category: StringName) -> Texture2D:
	var asset_id: String = str(id)
	var category_name: String = str(category)
	var asset_key: String = "%s/%s" % [category_name, asset_id]

	if not VALID_CATEGORIES.has(category):
		push_error("Unsupported texture category '%s' for asset '%s'." % [category_name, asset_id])
		return _get_generated_texture(asset_key, "invalid_asset", category_name, asset_key)
	if asset_id.is_empty() or _id_regex.search(asset_id) == null:
		push_error("Invalid asset ID '%s'; IDs may contain lowercase letters, digits, and underscores." % asset_id)
		return _get_generated_texture(asset_key, "invalid_asset", category_name, asset_key)

	var final_path: String = art_root.path_join(category_name).path_join("%s.png" % asset_id)
	var final_texture: Texture2D = _load_file_texture(final_path)
	if final_texture != null:
		_record_resolution(asset_key, "final")
		return final_texture

	var placeholder_path: String = placeholder_root.path_join(category_name).path_join("%s.png" % asset_id)
	var placeholder_texture: Texture2D = _load_file_texture(placeholder_path)
	if placeholder_texture != null:
		_record_resolution(asset_key, "placeholder")
		return placeholder_texture

	return _get_generated_texture(asset_key, asset_id, category_name, asset_key)


func get_debug_report() -> Dictionary:
	return {
		"final_assets": int(_resolution_counts["final"]),
		"placeholders": int(_resolution_counts["placeholder"]),
		"generated": int(_resolution_counts["generated"]),
		"unique_assets": _resolution_by_asset.size()
	}


func _load_file_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null

	var modified_time: int = FileAccess.get_modified_time(path)
	var cached_entry: Variant = _texture_cache.get(path)
	if cached_entry is Dictionary and int(cached_entry.get("modified_time", -1)) == modified_time:
		var cached_texture: Texture2D = cached_entry.get("texture") as Texture2D
		if cached_texture != null:
			return cached_texture

	var texture: Texture2D
	if path.begins_with("res://"):
		var loaded_resource: Resource = ResourceLoader.load(
			path,
			"",
			ResourceLoader.CACHE_MODE_IGNORE
		)
		texture = loaded_resource as Texture2D
		if texture == null:
			push_error("Could not load imported texture resource '%s'." % path)
			return null
	else:
		var image: Image = Image.new()
		var load_error: Error = image.load(path)
		if load_error != OK or image.is_empty():
			push_error("Could not load texture '%s': %s." % [path, error_string(load_error)])
			return null
		texture = ImageTexture.create_from_image(image)

	_texture_cache[path] = {
		"modified_time": modified_time,
		"texture": texture
	}
	return texture


func _get_generated_texture(
	cache_key: String,
	id: String,
	category: String,
	asset_key: String
) -> Texture2D:
	var cached_texture: Texture2D = _generated_cache.get(cache_key) as Texture2D
	if cached_texture == null:
		cached_texture = ProceduralPlaceholders.create_texture(id, category)
		_generated_cache[cache_key] = cached_texture
		if not _warned_missing.has(asset_key):
			_warned_missing[asset_key] = true
			push_warning("No final asset or placeholder found for '%s'; using a generated texture." % asset_key)

	_record_resolution(asset_key, "generated")
	return cached_texture


func _record_resolution(asset_key: String, source: String) -> void:
	var previous_source: String = str(_resolution_by_asset.get(asset_key, ""))
	if previous_source == source:
		return
	if not previous_source.is_empty():
		_resolution_counts[previous_source] = int(_resolution_counts[previous_source]) - 1
	_resolution_counts[source] = int(_resolution_counts[source]) + 1
	_resolution_by_asset[asset_key] = source