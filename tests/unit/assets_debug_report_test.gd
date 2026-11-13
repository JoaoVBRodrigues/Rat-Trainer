extends GdUnitTestSuite

const ASSET_RESOLVER_SCRIPT: GDScript = preload("res://src/core/Assets.gd")


func test_debug_report_starts_with_zero_resolutions() -> void:
	# Arrange
	var resolver: AssetResolver = auto_free(ASSET_RESOLVER_SCRIPT.new())
	add_child(resolver)

	# Act
	var report: Dictionary = resolver.get_debug_report()

	# Assert
	assert_int(report["final_assets"]).is_equal(0)
	assert_int(report["placeholders"]).is_equal(0)
	assert_int(report["generated"]).is_equal(0)
	assert_int(report["unique_assets"]).is_equal(0)