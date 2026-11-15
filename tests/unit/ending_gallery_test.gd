extends GdUnitTestSuite


func test_catalog_displays_all_fifteen_localized_entries_and_statuses() -> void:
	# Arrange
	var ending_ids: Array[String] = _load_ending_ids()
	assert_int(ending_ids.size()).is_equal(15)
	var unlocked_ids: Array[String] = ["evadida_do_sistema"]
	var gallery: EndingGallery = auto_free(EndingGallery.new())
	add_child(gallery)
	await get_tree().process_frame

	# Act
	gallery.load_gallery(ending_ids, unlocked_ids)

	# Assert
	assert_int(gallery._grid_container.columns).is_equal(2)
	assert_int(gallery._grid_container.get_child_count()).is_equal(15)
	assert_int(gallery.get_unlocked_count()).is_equal(1)
	var title_label: Label = gallery.find_child("TitleLabel", true, false) as Label
	var description_label: Label = (
		gallery.find_child("DescriptionLabel", true, false) as Label
	)
	assert_bool(title_label.text.begins_with("[missing:")).is_false()
	assert_bool(description_label.text.begins_with("[missing:")).is_false()
	for ending_id: String in ending_ids:
		var card: Button = gallery._grid_container.get_node(
			"Ending_%s_Card" % ending_id
		) as Button
		var name_label: Label = card.find_child("EndingName", true, false) as Label
		var card_description_label: Label = (
			card.find_child("EndingDescription", true, false) as Label
		)
		var status_label: Label = card.find_child("EndingStatus", true, false) as Label
		assert_int(card.focus_mode).is_equal(Control.FOCUS_ALL)
		assert_str(name_label.text).is_not_empty()
		assert_str(card_description_label.text).is_not_empty()
		assert_bool(name_label.text.begins_with("endings.")).is_false()
		assert_bool(card_description_label.text.begins_with("endings.")).is_false()
		assert_bool(name_label.text.begins_with("[missing:")).is_false()
		assert_bool(card_description_label.text.begins_with("[missing:")).is_false()
		assert_bool(status_label.text.begins_with("[missing:")).is_false()
		assert_str(status_label.text).is_not_empty()
	var unlocked_card: Button = gallery._grid_container.get_node(
		"Ending_evadida_do_sistema_Card"
	) as Button
	var locked_card: Button = gallery._grid_container.get_node(
		"Ending_aprendiz_de_ciborgues_Card"
	) as Button
	var unlocked_status: Label = (
		unlocked_card.find_child("EndingStatus", true, false) as Label
	)
	var locked_status: Label = locked_card.find_child("EndingStatus", true, false) as Label
	assert_str(
		unlocked_status.text
	).is_equal(Localization.text("ui.galeria_estado_desbloqueado"))
	assert_str(
		locked_status.text
	).is_equal(Localization.text("ui.galeria_fim_bloqueado"))


func test_ending_screen_assets_resolve_to_asset_placeholders() -> void:
	# Arrange
	var ending_ids: Array[String] = _load_ending_ids()
	assert_int(ending_ids.size()).is_equal(15)
	var assets: AssetResolver = auto_free(AssetResolver.new())
	add_child(assets)

	# Act
	assert_object(assets.get_texture(&"bg_ending", &"backgrounds")).is_not_null()
	for ending_id: String in ending_ids:
		assert_object(assets.get_texture(StringName(ending_id), &"endings")).is_not_null()
	var report: Dictionary = assets.get_debug_report()

	# Assert
	assert_int(int(report.get("placeholders", 0))).is_equal(16)
	assert_int(int(report.get("generated", 0))).is_equal(0)


func test_ending_screen_strings_are_localized() -> void:
	# Arrange
	var keys: Array[String] = [
		"ui.fim_jogo",
		"ui.profissao",
		"endings.character_summary",
		"endings.profissao_evadida",
		"endings.profissao_aprendiz",
		"endings.profissao_tecnico",
		"endings.profissao_guarda_rede",
		"endings.profissao_lider",
		"endings.profissao_corporativa",
		"endings.profissao_submundo",
		"endings.profissao_resistencia",
		"endings.profissao_mediadora",
		"endings.profissao_artista",
		"endings.profissao_mecanica",
		"endings.profissao_defensora",
		"endings.profissao_hacker",
		"endings.profissao_artista_emergente",
		"endings.profissao_equilibrado"
	]

	# Act / Assert
	for key: String in keys:
		assert_bool(Localization.text(key).begins_with("[missing:")).is_false()


func test_showing_another_ending_reenables_continue_button() -> void:
	# Arrange
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	var ending_screen: EndingScreen = auto_free(EndingScreen.new())
	add_child(ending_screen)
	await get_tree().process_frame

	# Act
	ending_screen.show_ending("caminho_equilibrado", simulation)
	ending_screen._on_continue_pressed()
	assert_bool(ending_screen._continue_button.disabled).is_true()
	ending_screen.show_ending("caminho_equilibrado", simulation)

	# Assert
	assert_bool(ending_screen._continue_button.disabled).is_false()


func test_opening_focuses_entry_and_focus_scrolls_it_into_view() -> void:
	# Arrange
	var ending_ids: Array[String] = _load_ending_ids()
	assert_int(ending_ids.size()).is_equal(15)
	var gallery: EndingGallery = auto_free(EndingGallery.new())
	add_child(gallery)
	await get_tree().process_frame

	# Act
	gallery.open_gallery(ending_ids, [])
	await get_tree().process_frame
	var last_card: Button = gallery._grid_container.get_child(14) as Button
	last_card.grab_focus()

	# Assert
	assert_bool(gallery.visible).is_true()
	var first_card: Button = gallery._grid_container.get_child(0) as Button
	assert_bool(first_card.has_focus()).is_false()
	assert_bool(last_card.has_focus()).is_true()
	assert_int(gallery._scroll_container.scroll_vertical).is_greater(0)


func test_opening_hidden_gallery_starts_at_first_ending() -> void:
	# Arrange
	var ending_ids: Array[String] = _load_ending_ids()
	assert_int(ending_ids.size()).is_equal(15)
	var gallery: EndingGallery = auto_free(EndingGallery.new())
	gallery.visible = false
	gallery.size = Vector2(1024.0, 768.0)
	add_child(gallery)
	await get_tree().process_frame
	gallery.open_gallery(ending_ids, [])
	await get_tree().process_frame
	gallery._scroll_container.scroll_vertical = 240
	gallery._on_close_pressed()

	# Act
	gallery.open_gallery(ending_ids, [])

	# Assert
	assert_int(gallery._scroll_container.scroll_vertical).is_equal(0)
	await get_tree().process_frame
	assert_int(gallery._scroll_container.scroll_vertical).is_equal(0)


func test_close_button_closes_gallery_and_cards_are_informational_only() -> void:
	# Arrange
	var ending_ids: Array[String] = _load_ending_ids()
	assert_int(ending_ids.size()).is_equal(15)
	var unlocked_ids: Array[String] = ["hacker_de_elite"]
	var gallery: EndingGallery = auto_free(EndingGallery.new())
	add_child(gallery)
	await get_tree().process_frame
	gallery.open_gallery(ending_ids, unlocked_ids)
	await get_tree().process_frame
	var card: Button = gallery._grid_container.get_node(
		"Ending_hacker_de_elite_Card"
	) as Button

	# Act — activating a card does not select an ending or close the catalog.
	card.pressed.emit()

	# Assert
	assert_bool(gallery.visible).is_true()
	assert_bool(gallery.has_signal("ending_selected")).is_false()
	assert_array(unlocked_ids).contains_exactly(["hacker_de_elite"])
	assert_int(gallery.get_unlocked_count()).is_equal(1)
	assert_bool(gallery._close_button.visible).is_true()
	gallery._close_button.pressed.emit()
	assert_bool(gallery.visible).is_false()


func _load_ending_ids() -> Array[String]:
	var ending_ids: Array[String] = []
	var file: FileAccess = FileAccess.open("res://assets/data/endings.json", FileAccess.READ)
	if file == null:
		return ending_ids
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		file.close()
		return ending_ids
	file.close()
	if not parser.data is Dictionary:
		return ending_ids
	var entries: Variant = parser.data.get("endings", [])
	if not entries is Array:
		return ending_ids
	for entry: Variant in entries:
		if not entry is Dictionary:
			return []
		var ending_id: Variant = entry.get("id", "")
		if not ending_id is String or ending_id.is_empty() or ending_ids.has(ending_id):
			return []
		ending_ids.append(ending_id)
	return ending_ids
