extends GUTTestSuite

## Tests for Assets.gd resolver
## Verifies fallback chain: Final asset > Placeholder > Generated

func test_get_texture_returns_final_asset_when_exists() -> void:
	# Arrange: Create a temporary test asset
	var test_image: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	test_image.fill(Color(1, 0, 0, 1))
	var test_texture: ImageTexture = ImageTexture.create_from_image(test_image)

	var test_path: String = "res://assets/art/icons/test_final_asset.png"
	ResourceSaver.save(test_texture, test_path)

	var assets: Object = preload("res://src/core/Assets.gd").new()
	add_child(assets)

	# Act
	var result: Texture2D = assets.get_texture("test_final_asset", "icons")

	# Assert
	assert_not_null(result, "Should return a texture for existing asset")

	# Cleanup
	assets.queue_free()
	DirAccess.remove_absolute(test_path)

func test_get_texture_falls_back_to_placeholder() -> void:
	# Arrange
	var assets: Object = preload("res://src/core/Assets.gd").new()
	add_child(assets)

	# Act - request icon that should use placeholder
	var result: Texture2D = assets.get_texture("icon_stat_str", "icons")

	# Assert
	assert_not_null(result, "Should return a texture (placeholder)")
	assert_true(result is Texture2D, "Result should be Texture2D instance")

	assets.queue_free()

func test_get_texture_generates_texture_when_missing() -> void:
	# Arrange
	var assets: Object = preload("res://src/core/Assets.gd").new()
	add_child(assets)

	# Act - request completely missing icon
	var result: Texture2D = assets.get_texture("nonexistent_icon_xyz", "icons")

	# Assert
	assert_not_null(result, "Should generate procedural texture for missing asset")
	assert_true(result is Texture2D, "Generated result should be Texture2D")

	assets.queue_free()

func test_generated_texture_has_valid_properties() -> void:
	# Arrange
	var assets: Object = preload("res://src/core/Assets.gd").new()
	add_child(assets)

	# Act
	var result: Texture2D = assets.get_texture("test_generated_props", "ui")
	var image: Image = result.get_image()

	# Assert
	assert_not_null(image, "Generated texture should have valid image")
	assert_int(image.get_width()).is_greater(0, "Texture width should be positive")
	assert_int(image.get_height()).is_greater(0, "Texture height should be positive")

	assets.queue_free()

func test_get_debug_report_returns_valid_structure() -> void:
	# Arrange
	var assets: Object = preload("res://src/core/Assets.gd").new()
	add_child(assets)

	# Act
	var report: Dictionary = assets.get_debug_report()

	# Assert
	assert_true(report.has("final_assets"), "Report must have 'final_assets' key")
	assert_true(report.has("placeholders"), "Report must have 'placeholders' key")
	assert_true(report.has("generated"), "Report must have 'generated' key")

	assert_int(report["final_assets"]).is_greater_equal(0, "final_assets must be >= 0")
	assert_int(report["placeholders"]).is_greater_equal(0, "placeholders must be >= 0")
	assert_int(report["generated"]).is_greater_equal(0, "generated must be >= 0")

	assets.queue_free()