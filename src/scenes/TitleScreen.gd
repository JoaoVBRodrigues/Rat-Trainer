extends Control
class_name TitleScreen

signal new_game_requested
signal continue_requested(save_id: String)
signal options_requested
signal gallery_requested
signal quit_requested

var _save_selector: OptionButton
var _continue_button: Button


func _ready() -> void:
	_build_ui()
	refresh_saves()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: TextureRect = ArtPresentation.artwork(self, &"bg_bedroom_day", Vector2.ZERO, "TitleBackground")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.55, 0.55, 0.55)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "TitlePanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560.0, 560.0)
	panel.offset_left = -280.0
	panel.offset_top = -280.0
	panel.offset_right = 280.0
	panel.offset_bottom = 280.0
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "TitleLayout"
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = Localization.text("ui.title")
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	_add_button(
		layout,
		"NewGameButton",
		"ui.novo_jogo",
		func() -> void: new_game_requested.emit()
	)
	var continue_row: HBoxContainer = HBoxContainer.new()
	continue_row.add_theme_constant_override("separation", 8)
	layout.add_child(continue_row)
	_save_selector = OptionButton.new()
	_save_selector.name = "SaveSelector"
	_save_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_selector.focus_mode = Control.FOCUS_ALL
	continue_row.add_child(_save_selector)
	_continue_button = _add_button(
		continue_row, "ContinueButton", "ui.continuar", _on_continue_pressed
	)
	_add_button(
		layout,
		"GalleryButton",
		"ui.galeria_finais",
		func() -> void: gallery_requested.emit()
	)
	_add_button(
		layout,
		"OptionsButton",
		"ui.opcoes",
		func() -> void: options_requested.emit()
	)
	_add_button(layout, "QuitButton", "ui.sair", func() -> void: quit_requested.emit())


func _add_button(
	parent: Node,
	button_name: String,
	text_key: String,
	callback: Callable
) -> Button:
	var button: Button = Button.new()
	button.name = button_name
	button.text = Localization.text(text_key)
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
	parent.add_child(button)
	return button


func refresh_saves() -> void:
	if _save_selector == null:
		return
	_save_selector.clear()
	var data_manager: DataManager = get_node_or_null("/root/Data") as DataManager
	if data_manager == null:
		push_error("Cannot list saved campaigns because DataManager is unavailable.")
		_continue_button.disabled = true
		_save_selector.disabled = true
		return
	var available_ids: Array[String] = data_manager.get_available_save_ids()
	for save_id: String in available_ids:
		var summary: Dictionary = data_manager.get_save_summary(save_id)
		if summary.is_empty():
			continue
		var name: String = str(summary.get("name", ""))
		var save_label: String = _save_id_label(save_id)
		var label: String = Localization.format(
			"ui.save_entry_format",
			{
				"save": save_label,
				"name": name,
				"turns": int(summary.get("turns_completed", 0))
			}
		)
		_save_selector.add_item(label)
		_save_selector.set_item_metadata(_save_selector.item_count - 1, save_id)
	if _save_selector.item_count == 0:
		_save_selector.add_item(Localization.text("ui.sem_save"))
		_save_selector.set_item_disabled(0, true)
		_save_selector.disabled = true
	else:
		_save_selector.disabled = false
	_continue_button.disabled = available_ids.is_empty()


func _save_id_label(save_id: String) -> String:
	if save_id == DataManager.AUTOSAVE_ID:
		return Localization.text("ui.autosave")
	if save_id == DataManager.MONTHLY_SNAPSHOT_ID:
		return Localization.text("ui.snapshot_mensal")
	if save_id.begins_with("slot_"):
		return Localization.format(
			"ui.slot_numero_format",
			{"slot": save_id.trim_prefix("slot_").to_int() + 1}
		)
	return Localization.text("ui.indisponivel")


func _on_continue_pressed() -> void:
	if _save_selector == null or _save_selector.item_count == 0:
		return
	var selected_index: int = _save_selector.selected
	if selected_index < 0 or _save_selector.is_item_disabled(selected_index):
		return
	var save_id: Variant = _save_selector.get_item_metadata(selected_index)
	if not save_id is String or save_id.is_empty():
		push_error("Selected save entry has no valid identifier.")
		return
	continue_requested.emit(save_id)
