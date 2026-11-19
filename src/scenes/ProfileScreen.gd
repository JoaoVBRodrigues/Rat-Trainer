extends Control
class_name ProfileScreen

signal closed
signal credits_changed

var _character_image: TextureRect
var _name_label: Label
var _age_label: Label
var _credits_label: Label
var _stats_panel: StatusPanel
var _close_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.035, 0.02, 0.04, 0.94)
	add_child(backdrop)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ProfileWindow"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_top = 24
	panel.offset_right = -24
	panel.offset_bottom = -24
	add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	var header: HBoxContainer = HBoxContainer.new()
	layout.add_child(header)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_name_label)
	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = Localization.text("ui.voltar")
	_close_button.custom_minimum_size = Vector2(120, 44)
	_close_button.pressed.connect(close)
	header.add_child(_close_button)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	layout.add_child(body)
	var portrait: VBoxContainer = VBoxContainer.new()
	portrait.custom_minimum_size.x = 280
	body.add_child(portrait)
	_character_image = TextureRect.new()
	_character_image.name = "ProfileCharacter"
	_character_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_character_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.add_child(_character_image)
	_age_label = Label.new()
	portrait.add_child(_age_label)
	_credits_label = Label.new()
	portrait.add_child(_credits_label)
	_stats_panel = StatusPanel.new()
	_stats_panel.name = "ProfileStats"
	_stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_stats_panel)
	_stats_panel.set_expanded(true)

func show_profile(sim: SimulationCore, profile: Dictionary = {}) -> void:
	visible = true
	_name_label.text = str(profile.get("name", sim.character_name))
	_age_label.text = Localization.format("ui.idade_format", {"value": sim.get_age()})
	update_credits(sim.economy.get_credits())
	_character_image.texture = Assets.get_texture(ArtPresentation.character_id(sim), &"characters")
	_stats_panel.update_from_simulation(sim)
	_close_button.grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func update_credits(credits: int) -> void:
	_credits_label.text = Localization.format("ui.creditos_format", {"value": credits})

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
