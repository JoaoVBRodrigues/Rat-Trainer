extends Control
class_name CharacterCreationScreen

signal create_requested(character_name: String, guardian_name: String)
signal cancel_requested

var _character_name: LineEdit
var _guardian_name: LineEdit
var _name_error: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "CharacterCreationPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560.0, 360.0)
	panel.offset_left = -280.0
	panel.offset_top = -180.0
	panel.offset_right = 280.0
	panel.offset_bottom = 180.0
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "CharacterCreationLayout"
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title: Label = Label.new()
	title.text = Localization.text("ui.criacao_personagem")
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)

	var character_label: Label = Label.new()
	character_label.text = Localization.text("ui.nome")
	layout.add_child(character_label)
	_character_name = LineEdit.new()
	_character_name.name = "CharacterNameInput"
	_character_name.text = Localization.text("ui.nome_padrao")
	_character_name.max_length = 32
	_character_name.placeholder_text = Localization.text("ui.nome_padrao")
	layout.add_child(_character_name)

	var guardian_label: Label = Label.new()
	guardian_label.text = Localization.text("ui.nome_guardiao")
	layout.add_child(guardian_label)
	_guardian_name = LineEdit.new()
	_guardian_name.name = "GuardianNameInput"
	_guardian_name.text = Localization.text("ui.guardiao_padrao")
	_guardian_name.max_length = 32
	_guardian_name.placeholder_text = Localization.text("ui.guardiao_padrao")
	layout.add_child(_guardian_name)

	_name_error = Label.new()
	_name_error.name = "ValidationMessage"
	_name_error.text = ""
	layout.add_child(_name_error)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(buttons)
	var cancel_button: Button = Button.new()
	cancel_button.text = Localization.text("ui.cancelar")
	cancel_button.custom_minimum_size = Vector2(120.0, 44.0)
	cancel_button.focus_mode = Control.FOCUS_ALL
	cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	cancel_button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
	buttons.add_child(cancel_button)
	var create_button: Button = Button.new()
	create_button.name = "CreateCharacterButton"
	create_button.text = Localization.text("ui.novo_jogo")
	create_button.custom_minimum_size = Vector2(160.0, 44.0)
	create_button.focus_mode = Control.FOCUS_ALL
	create_button.pressed.connect(_on_create_pressed)
	create_button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
	buttons.add_child(create_button)


func _on_create_pressed() -> void:
	var name: String = _character_name.text.strip_edges()
	var guardian: String = _guardian_name.text.strip_edges()
	if name.is_empty():
		_name_error.text = Localization.text("ui.nome_obrigatorio")
		_character_name.grab_focus()
		return
	if guardian.is_empty():
		_name_error.text = Localization.text("ui.guardiao_obrigatorio")
		_guardian_name.grab_focus()
		return
	_name_error.text = ""
	create_requested.emit(name, guardian)
