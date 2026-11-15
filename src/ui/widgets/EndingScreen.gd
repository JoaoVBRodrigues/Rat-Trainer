extends Control
class_name EndingScreen

signal ending_finished
signal show_credits

const STAT_NAME_KEYS: Dictionary = {
	"str": "stats.forca",
	"int": "stats.inteligencia",
	"cha": "stats.carisma",
	"ref": "stats.refinamento",
	"sta": "stats.resistencia",
	"eth": "stats.etica"
}
const REPUTATION_NAME_KEYS: Dictionary = {
	"fighter": "ui.rep_fighter",
	"social": "ui.rep_social",
	"hacker": "ui.rep_hacker"
}
const PROFESSION_KEYS: Dictionary = {
	"evadida_do_sistema": "endings.profissao_evadida",
	"aprendiz_de_ciborgues": "endings.profissao_aprendiz",
	"tecnica_juvenil_da_cidade": "endings.profissao_tecnico",
	"guardia_da_rede": "endings.profissao_guarda_rede",
	"lider_comunitaria_jovem": "endings.profissao_lider",
	"promessa_corporativa": "endings.profissao_corporativa",
	"recruta_do_submundo": "endings.profissao_submundo",
	"voz_das_ruas": "endings.profissao_resistencia",
	"mediadora_comunitaria": "endings.profissao_mediadora",
	"autora_emergente": "endings.profissao_artista",
	"mecanica_de_campo": "endings.profissao_mecanica",
	"defensora_das_ruas": "endings.profissao_defensora",
	"hacker_de_elite": "endings.profissao_hacker",
	"artista_emergente": "endings.profissao_artista_emergente",
	"caminho_equilibrado": "endings.profissao_equilibrado"
}

var _title_label: Label
var _ending_name_label: Label
var _description_label: Label
var _character_summary_label: Label
var _attributes_container: VBoxContainer
var _credits_label: Label
var _profession_label: Label
var _continue_button: Button
var _credits_button: Button
var _ending_id: String = ""
var _simulation: SimulationCore = null


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg: TextureRect = TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var assets := get_node_or_null("/root/Assets") as AssetResolver
	if assets != null:
		bg.texture = assets.get_texture(&"bg_ending", &"backgrounds")
	else:
		var default := preload("res://icon.svg") as Texture2D
		bg.texture = default
	add_child(bg)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "EndingPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.z_index = 1
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "EndingLayout"
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.text = Localization.text("ui.fim_jogo")
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title_label)

	var ending_header: HBoxContainer = HBoxContainer.new()
	ending_header.name = "EndingHeader"
	ending_header.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(ending_header)

	var icon: TextureRect = TextureRect.new()
	icon.name = "EndingIcon"
	icon.custom_minimum_size = Vector2(96.0, 96.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ending_header.add_child(icon)

	_ending_name_label = Label.new()
	_ending_name_label.name = "EndingName"
	_ending_name_label.add_theme_font_size_override("font_size", 24)
	_ending_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_header.add_child(_ending_name_label)

	_description_label = Label.new()
	_description_label.name = "DescriptionLabel"
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_description_label)

	_character_summary_label = Label.new()
	_character_summary_label.name = "CharacterSummary"
	_character_summary_label.add_theme_font_size_override("font_size", 18)
	_character_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_character_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_character_summary_label)

	var attributes_heading := Label.new()
	attributes_heading.name = "AttributesHeading"
	attributes_heading.text = Localization.text("ui.atributos")
	layout.add_child(attributes_heading)
	_attributes_container = VBoxContainer.new()
	_attributes_container.name = "AttributesContainer"
	layout.add_child(_attributes_container)

	var credits_heading := Label.new()
	credits_heading.name = "CreditsHeading"
	credits_heading.text = Localization.text("ui.creditos")
	layout.add_child(credits_heading)
	_credits_label = Label.new()
	_credits_label.name = "CreditsValue"
	layout.add_child(_credits_label)

	var profession_heading := Label.new()
	profession_heading.name = "ProfessionHeading"
	profession_heading.text = Localization.text("ui.profissao")
	layout.add_child(profession_heading)
	_profession_label = Label.new()
	_profession_label.name = "ProfessionValue"
	layout.add_child(_profession_label)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "EndingFooter"
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = Localization.text("ui.continuar")
	_continue_button.custom_minimum_size = Vector2(0.0, 44.0)
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.pressed.connect(_on_continue_pressed)
	footer.add_child(_continue_button)

	_credits_button = Button.new()
	_credits_button.name = "CreditsButton"
	_credits_button.text = Localization.text("ui.creditos")
	_credits_button.custom_minimum_size = Vector2(0.0, 44.0)
	_credits_button.focus_mode = Control.FOCUS_ALL
	_credits_button.pressed.connect(_on_credits_pressed)
	footer.add_child(_credits_button)


func show_ending(ending_id: String, simulation: SimulationCore) -> void:
	_ending_id = ending_id
	_simulation = simulation
	if _continue_button != null:
		_continue_button.disabled = false
	_build_display()
	visible = true
	if _continue_button != null:
		_continue_button.grab_focus()


func _build_display() -> void:
	if _simulation == null:
		return

	var evaluator := EndingEvaluator.new()
	if not evaluator.load_endings("res://assets/data/endings.json"):
		push_error("Could not load ending catalog for the ending screen.")
		return
	var ending := evaluator.get_ending_by_id(_ending_id)
	if ending == null:
		push_error("Could not find ending '%s' for the ending screen." % _ending_id)
		return

	if _ending_name_label != null:
		_ending_name_label.text = Localization.text("endings.name_" + _ending_id)

	if _description_label != null:
		_description_label.text = Localization.text("endings.description_" + _ending_id)

	if _character_summary_label != null:
		var name: String = str(_simulation.get_character_name() if _simulation.has_method("get_character_name") else "Nyx")
		var age: int = _simulation.get_age()
		_character_summary_label.text = Localization.format("endings.character_summary", {"name": name, "age": age})

	_build_attributes(_simulation)
	_build_credits(_simulation)
	_build_profession(_ending_id)
	_build_icon(_ending_id)


func _build_attributes(sim: SimulationCore) -> void:
	if _attributes_container == null or sim == null:
		return

	for child: Node in _attributes_container.get_children():
		_attributes_container.remove_child(child)
		child.queue_free()

	var stats := sim.stats
	for stat_id: String in STAT_NAME_KEYS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var name_label: Label = Label.new()
		name_label.text = Localization.text(str(STAT_NAME_KEYS[stat_id]))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var value_label: Label = Label.new()
		value_label.text = str(stats.get_stat(stat_id))
		row.add_child(value_label)

		_attributes_container.add_child(row)


func _build_credits(sim: SimulationCore) -> void:
	if _credits_label != null and sim != null:
		var credits: int = sim.economy.get_credits()
		_credits_label.text = Localization.format("ui.creditos_format", {"value": credits})


func _build_profession(ending_id: String) -> void:
	if _profession_label != null:
		var key: String = str(PROFESSION_KEYS.get(ending_id, ""))
		if key.is_empty():
			_profession_label.text = _get_profession_name(ending_id)
			return
		_profession_label.text = Localization.text(key)


func _get_profession_name(ending_id: String) -> String:
	match ending_id:
		"evadida_do_sistema":
			return "Desaparecida da Sociedade"
		"aprendiz_de_ciborgues":
			return "Aprendiz de Ciborgues"
		"tecnica_juvenil_da_cidade":
			return "Técnica Juvenil da Cidade"
		"guardia_da_rede":
			return "Guardiã da Rede"
		"lider_comunitaria_jovem":
			return "Líder Comunitária Jovem"
		"promessa_corporativa":
			return "Promessa Corporativa"
		"recruta_do_submundo":
			return "Recruta do Submundo"
		"voz_das_ruas":
			return "Voz das Ruas"
		"mediadora_comunitaria":
			return "Mediadora Comunitária"
		"autora_emergente":
			return "Autora Emergente"
		"mecanica_de_campo":
			return "Mecânica de Campo"
		"defensora_das_ruas":
			return "Defensora das Ruas"
		"hacker_de_elite":
			return "Hacker de Elite"
		"artista_emergente":
			return "Artista Emergente"
		_:
			return "Caminho Equilibrado"


func _build_icon(ending_id: String) -> void:
	# Find icon texture in assets
	var assets := get_node_or_null("/root/Assets") as AssetResolver
	if assets == null:
		return

	var texture: Texture2D = assets.get_texture(StringName(ending_id), &"endings")
	if texture == null:
		# Fallback to generic icon
		texture = assets.get_texture(&"icon_ending", &"ui")

	# Apply texture to icon if found
	var icon := get_node_or_null("EndingPanel/EndingLayout/EndingHeader/EndingIcon") as TextureRect
	if icon != null and texture != null:
		icon.texture = texture


func _on_continue_pressed() -> void:
	_continue_button.disabled = true
	ending_finished.emit()


func _on_credits_pressed() -> void:
	# Navigate to credits/about screen
	# This would typically push a credits screen onto a stack
	emit_signal("show_credits")


func hide_ending() -> void:
	visible = false
	_ending_id = ""