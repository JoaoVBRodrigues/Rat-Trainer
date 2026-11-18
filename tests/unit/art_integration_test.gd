extends GdUnitTestSuite


func test_every_installed_game_texture_resolves_as_final_art() -> void:
	var resolver: AssetResolver = auto_free(AssetResolver.new())
	add_child(resolver)
	var texture_count: int = 0
	for category: StringName in AssetResolver.VALID_CATEGORIES:
		var directory: String = "res://assets/art".path_join(str(category))
		for file_name: String in DirAccess.get_files_at(directory):
			if not file_name.ends_with(".png"):
				continue
			var texture: Texture2D = resolver.get_texture(
				StringName(file_name.get_basename()), category
			)
			assert_object(texture).is_not_null()
			assert_bool(texture.get_width() > 0 and texture.get_height() > 0).is_true()
			texture_count += 1
	var report: Dictionary = resolver.get_debug_report()
	assert_bool(texture_count > 0).is_true()
	assert_int(report["final_assets"]).is_equal(texture_count)
	assert_int(report["placeholders"]).is_equal(0)
	assert_int(report["generated"]).is_equal(0)


func test_catalog_items_use_their_individual_installed_art() -> void:
	var loader: DataLoader = DataLoader.load_all()
	var resolver: AssetResolver = auto_free(AssetResolver.new())
	add_child(resolver)
	assert_bool(loader.is_valid()).is_true()
	for item: ItemDef in loader.items:
		assert_str(str(item.icon)).is_equal(str(item.id))
		assert_bool(FileAccess.file_exists(
			"res://assets/art/items/%s.png" % str(item.icon)
		)).is_true()
		assert_object(resolver.get_texture(item.icon, &"items")).is_not_null()
	assert_int(resolver.get_debug_report()["final_assets"]).is_equal(loader.items.size())


func test_encounters_display_the_matching_installed_monster_texture() -> void:
	var screen: EncounterScreen = auto_free(EncounterScreen.new())
	add_child(screen)
	var assets: AssetResolver = get_node("/root/Assets") as AssetResolver
	var icon: TextureRect = screen.find_child("MonsterIcon", true, false) as TextureRect
	assert_object(icon).is_not_null()
	for monster_id: String in ["rastreador", "drone_patrulha", "sentinela"]:
		screen.open_encounter(monster_id, monster_id)
		assert_object(icon.texture).is_same(assets.get_texture(
			StringName(monster_id), &"monsters"
		))
		screen.hide_encounter()
