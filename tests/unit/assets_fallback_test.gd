extends GdUnitTestSuite

const ASSET_RESOLVER_SCRIPT: GDScript = preload("res://src/core/Assets.gd")
const TEST_ROOT: String = "user://gdunit_assets_fallback"

var _created_files: Array[String] = []
var _created_directories: Array[String] = []


func test_final_asset_overrides_placeholder() -> void:
	# Arrange
	var art_root: String = "res://assets/placeholders"
	var placeholder_root: String = TEST_ROOT.path_join("priority_placeholders")
	_create_png(placeholder_root, "icons", "icon_stat_str", Color(0.1, 0.1, 0.9))
	var resolver: AssetResolver = _create_resolver(art_root, placeholder_root)

	# Act
	var resolved: Texture2D = resolver.get_texture(&"icon_stat_str", &"icons")
	var report: Dictionary = resolver.get_debug_report()

	# Assert
	assert_bool(resolved != null).is_true()
	assert_int(resolved.get_width()).is_equal(48)
	assert_int(report["final_assets"]).is_equal(1)
	assert_int(report["placeholders"]).is_equal(0)


func test_placeholder_fallback_tracks_final_asset_creation_and_removal() -> void:
	# Arrange
	var art_root: String = TEST_ROOT.path_join("live_art")
	var placeholder_root: String = TEST_ROOT.path_join("live_placeholders")
	_create_png(placeholder_root, "icons", "probe_live", Color(0.1, 0.1, 0.9))
	var resolver: AssetResolver = _create_resolver(art_root, placeholder_root)

	# Act and assert: starts at the placeholder.
	var initial: Texture2D = resolver.get_texture(&"probe_live", &"icons")
	var placeholder_pixel: Color = initial.get_image().get_pixel(5, 5)
	assert_bool(placeholder_pixel.b > placeholder_pixel.r).is_true()

	# Act and assert: a newly added final PNG takes precedence.
	_create_png(art_root, "icons", "probe_live", Color(0.9, 0.1, 0.1))
	var final_art: Texture2D = resolver.get_texture(&"probe_live", &"icons")
	var final_pixel: Color = final_art.get_image().get_pixel(5, 5)
	assert_bool(final_pixel.r > final_pixel.b).is_true()

	# Act and assert: removing final art restores the placeholder.
	var final_path: String = _absolute_asset_path(art_root, "icons", "probe_live")
	var remove_error: Error = DirAccess.remove_absolute(final_path)
	assert_int(remove_error).is_equal(OK)
	_created_files.erase(final_path)
	var restored: Texture2D = resolver.get_texture(&"probe_live", &"icons")
	var restored_pixel: Color = restored.get_image().get_pixel(5, 5)
	assert_bool(restored_pixel.b > restored_pixel.r).is_true()


func test_generated_texture_is_used_when_both_files_are_missing() -> void:
	# Arrange
	var resolver: AssetResolver = _create_resolver(
		TEST_ROOT.path_join("missing_art"),
		TEST_ROOT.path_join("missing_placeholders")
	)

	# Act
	var resolved: Texture2D = resolver.get_texture(&"probe_missing", &"icons")
	var report: Dictionary = resolver.get_debug_report()

	# Assert
	assert_bool(resolved != null).is_true()
	assert_bool(resolved.get_width() > 0 and resolved.get_height() > 0).is_true()
	assert_int(report["generated"]).is_equal(1)


func after_test() -> void:
	for file_path: String in _created_files:
		DirAccess.remove_absolute(file_path)
	_created_files.clear()
	_created_directories.sort_custom(
		func(left: String, right: String) -> bool:
			return left.length() > right.length()
	)
	for directory_path: String in _created_directories:
		if DirAccess.dir_exists_absolute(directory_path):
			var remove_error: Error = DirAccess.remove_absolute(directory_path)
			assert_int(remove_error).is_equal(OK)
	_created_directories.clear()


func _create_resolver(art_root: String, placeholder_root: String) -> AssetResolver:
	var resolver: AssetResolver = auto_free(ASSET_RESOLVER_SCRIPT.new())
	add_child(resolver)
	resolver.art_root = ProjectSettings.globalize_path(art_root)
	resolver.placeholder_root = ProjectSettings.globalize_path(placeholder_root)
	return resolver


func _create_png(root: String, category: String, asset_id: String, color: Color) -> void:
	var absolute_directory: String = ProjectSettings.globalize_path(root.path_join(category))
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	assert_int(directory_error).is_equal(OK)
	if absolute_directory not in _created_directories:
		_created_directories.append(absolute_directory)
	var absolute_root: String = ProjectSettings.globalize_path(root)
	if absolute_root not in _created_directories:
		_created_directories.append(absolute_root)
	var absolute_test_root: String = ProjectSettings.globalize_path(TEST_ROOT)
	if absolute_test_root not in _created_directories:
		_created_directories.append(absolute_test_root)

	var image: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var absolute_path: String = _absolute_asset_path(root, category, asset_id)
	var save_error: Error = image.save_png(absolute_path)
	assert_int(save_error).is_equal(OK)
	_created_files.append(absolute_path)


func _absolute_asset_path(root: String, category: String, asset_id: String) -> String:
	var path: String = root.path_join(category).path_join("%s.png" % asset_id)
	return ProjectSettings.globalize_path(path)
