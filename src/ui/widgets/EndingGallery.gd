extends Control
class_name EndingGallery

signal gallery_finished

const ENDING_NAME_KEYS: Dictionary = {
	"evadida_do_sistema": "endings.name_evadida_do_sistema",
	"aprendiz_de_ciborgues": "endings.name_aprendiz_de_ciborgues",
	"tecnica_juvenil_da_cidade": "endings.name_tecnica_juvenil_da_cidade",
	"guardia_da_rede": "endings.name_guardia_da_rede",
	"lider_comunitaria_jovem": "endings.name_lider_comunitaria_jovem",
	"promessa_corporativa": "endings.name_promessa_corporativa",
	"recruta_do_submundo": "endings.name_recruta_do_submundo",
	"voz_das_ruas": "endings.name_voz_das_ruas",
	"mediadora_comunitaria": "endings.name_mediadora_comunitaria",
	"autora_emergente": "endings.name_autora_emergente",
	"mecanica_de_campo": "endings.name_mecanica_de_campo",
	"defensora_das_ruas": "endings.name_defensora_das_ruas",
	"hacker_de_elite": "endings.name_hacker_de_elite",
	"artista_emergente": "endings.name_artista_emergente",
	"caminho_equilibrado": "endings.name_caminho_equilibrado"
}
const ENDING_DESCRIPTION_KEYS: Dictionary = {
	"evadida_do_sistema": "endings.description_evadida_do_sistema",
	"aprendiz_de_ciborgues": "endings.description_aprendiz_de_ciborgues",
	"tecnica_juvenil_da_cidade": "endings.description_tecnica_juvenil_da_cidade",
	"guardia_da_rede": "endings.description_guardia_da_rede",
	"lider_comunitaria_jovem": "endings.description_lider_comunitaria_jovem",
	"promessa_corporativa": "endings.description_promessa_corporativa",
	"recruta_do_submundo": "endings.description_recruta_do_submundo",
	"voz_das_ruas": "endings.description_voz_das_ruas",
	"mediadora_comunitaria": "endings.description_mediadora_comunitaria",
	"autora_emergente": "endings.description_autora_emergente",
	"mecanica_de_campo": "endings.description_mecanica_de_campo",
	"defensora_das_ruas": "endings.description_defensora_das_ruas",
	"hacker_de_elite": "endings.description_hacker_de_elite",
	"artista_emergente": "endings.description_artista_emergente",
	"caminho_equilibrado": "endings.description_caminho_equilibrado"
}

var _ending_ids: Array[String] = []
var _unlocked_endings: Array[String] = []
var _scroll_container: ScrollContainer
var _grid_container: GridContainer
var _close_button: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "GalleryPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = -16.0
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "GalleryLayout"
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var title_label: Label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.text = Localization.text("ui.galeria_finais")
	layout.add_child(title_label)

	var description_label: Label = Label.new()
	description_label.name = "DescriptionLabel"
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.text = Localization.text("ui.galeria_finais_instrucao")
	layout.add_child(description_label)

	_scroll_container = ScrollContainer.new()
	_scroll_container.name = "EndingScroll"
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(_scroll_container)

	_grid_container = GridContainer.new()
	_grid_container.name = "EndingGrid"
	_grid_container.columns = 2
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_container.add_theme_constant_override("h_separation", 12)
	_grid_container.add_theme_constant_override("v_separation", 12)
	_scroll_container.add_child(_grid_container)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "GalleryFooter"
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = Localization.text("ui.fechar")
	_close_button.custom_minimum_size = Vector2(120.0, 44.0)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.pressed.connect(_on_close_pressed)
	footer.add_child(_close_button)

	_build_gallery_grid()


func load_gallery(ending_ids: Array[String], unlocked_ids: Array[String]) -> void:
	_ending_ids = ending_ids.duplicate()
	_unlocked_endings = unlocked_ids.duplicate()
	_build_gallery_grid()


func open_gallery(ending_ids: Array[String], unlocked_ids: Array[String]) -> void:
	load_gallery(ending_ids, unlocked_ids)
	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0
	visible = true
	call_deferred("_focus_first_entry")


func _build_gallery_grid() -> void:
	if _grid_container == null:
		return

	for child: Node in _grid_container.get_children():
		_grid_container.remove_child(child)
		child.queue_free()

	for ending_id: String in _ending_ids:
		_grid_container.add_child(_create_ending_card(ending_id))


func _create_ending_card(ending_id: String) -> Button:
	var card: Button = Button.new()
	card.name = "Ending_%s_Card" % ending_id
	card.custom_minimum_size = Vector2(0.0, 120.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL

	var is_unlocked: bool = _unlocked_endings.has(ending_id)
	var state_text: String = Localization.text(
		"ui.galeria_estado_desbloqueado"
		if is_unlocked
		else "ui.galeria_fim_bloqueado"
	)
	var name_key: String = str(ENDING_NAME_KEYS.get(ending_id, "ui.indisponivel"))
	var description_key: String = str(
		ENDING_DESCRIPTION_KEYS.get(ending_id, "ui.indisponivel")
	)
	var ending_name: String = Localization.text(name_key)
	var ending_description: String = Localization.text(description_key)
	card.tooltip_text = "%s. %s. %s" % [ending_name, ending_description, state_text]

	var content: HBoxContainer = HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8.0
	content.offset_top = 6.0
	content.offset_right = -8.0
	content.offset_bottom = -6.0

	var icon: TextureRect = TextureRect.new()
	icon.name = "EndingIcon"
	icon.custom_minimum_size = Vector2(64.0, 64.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var assets: AssetResolver = get_node_or_null("/root/Assets") as AssetResolver
	if assets != null:
		icon.texture = assets.get_texture(StringName(ending_id), &"endings")
	content.add_child(icon)

	var text_container: VBoxContainer = VBoxContainer.new()
	text_container.alignment = BoxContainer.ALIGNMENT_CENTER
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_container)

	var name_label: Label = Label.new()
	name_label.name = "EndingName"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text = ending_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(name_label)

	var description_label: Label = Label.new()
	description_label.name = "EndingDescription"
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.text = ending_description
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(description_label)

	var state_label: Label = Label.new()
	state_label.name = "EndingStatus"
	state_label.add_theme_font_size_override("font_size", 14)
	state_label.text = state_text
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(state_label)

	card.focus_entered.connect(_on_card_focus_entered.bind(card))
	return card


func _focus_first_entry() -> void:
	if not visible or _grid_container == null or _grid_container.get_child_count() == 0:
		_close_button.grab_focus()
		return
	var first_entry: Button = _grid_container.get_child(0) as Button
	if first_entry != null:
		first_entry.grab_focus()
		_scroll_container.ensure_control_visible(first_entry)
		_scroll_container.scroll_vertical = 0


func _on_card_focus_entered(card: Button) -> void:
	if _scroll_container != null and is_instance_valid(card):
		_scroll_container.ensure_control_visible(card)


func _on_close_pressed() -> void:
	_close_gallery()


func _close_gallery() -> void:
	if not visible:
		return
	visible = false
	gallery_finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close_gallery()
		get_viewport().set_input_as_handled()


func get_unlocked_count() -> int:
	var unlocked_count: int = 0
	for ending_id: String in _ending_ids:
		if _unlocked_endings.has(ending_id):
			unlocked_count += 1
	return unlocked_count


func is_ending_unlocked(ending_id: String) -> bool:
	return _unlocked_endings.has(ending_id)
