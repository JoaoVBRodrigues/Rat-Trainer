extends Control
class_name EncounterScreen

signal encounter_resolved(option: int)

const OPTION_LABELS: Dictionary = {
	0: "lutar",
	1: "conversar",
	2: "fugir",
	3: "esconder"
}

var _monster_name: String = ""
var _monster_id: String = ""
var _options_container: VBoxContainer
var _monster_label: Label
var _instructions_label: Label
var _scene_label: Label
var _error_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "EncounterPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "EncounterLayout"
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var monster_header: HBoxContainer = HBoxContainer.new()
	monster_header.name = "MonsterHeader"
	monster_header.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(monster_header)

	var monster_icon: TextureRect = TextureRect.new()
	monster_icon.name = "MonsterIcon"
	monster_icon.custom_minimum_size = Vector2(64.0, 64.0)
	monster_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster_header.add_child(monster_icon)

	_monster_label = Label.new()
	_monster_label.name = "MonsterName"
	_monster_label.add_theme_font_size_override("font_size", 20)
	monster_header.add_child(_monster_label)

	_instructions_label = Label.new()
	_instructions_label.name = "Instructions"
	_instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_instructions_label)

	_scene_label = Label.new()
	_scene_label.name = "ScenePlaceholder"
	_scene_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scene_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scene_label.custom_minimum_size = Vector2(0.0, 96.0)
	layout.add_child(_scene_label)

	_error_label = Label.new()
	_error_label.name = "ResolutionError"
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.visible = false
	layout.add_child(_error_label)

	_options_container = VBoxContainer.new()
	_options_container.name = "OptionsContainer"
	_options_container.add_theme_constant_override("separation", 8)
	layout.add_child(_options_container)

	_build_option_buttons()


func _build_option_buttons() -> void:
	for child: Node in _options_container.get_children():
		_options_container.remove_child(child)
		child.queue_free()

	for option_id: int in OPTION_LABELS.keys():
		var option_btn: Button = Button.new()
		option_btn.name = "Option_%d_Button" % option_id
		option_btn.custom_minimum_size = Vector2(0.0, 48.0)
		option_btn.focus_mode = Control.FOCUS_ALL
		option_btn.text = Localization.text("ui.%s" % OPTION_LABELS[option_id])
		option_btn.pressed.connect(_on_option_pressed.bind(option_id))
		_options_container.add_child(option_btn)


func open_encounter(
	monster_id: String, monster_name: String, monster_description: String = ""
) -> void:
	_monster_id = monster_id
	_monster_name = monster_name

	if _monster_label != null:
		_monster_label.text = monster_name

	if _instructions_label != null:
		_instructions_label.text = Localization.text("ui.encounter.instrucoes")
	if _scene_label != null:
		_scene_label.text = monster_description
	if _error_label != null:
		_error_label.text = ""
		_error_label.visible = false

	visible = true
	if OPTION_LABELS.has(0):
		var first_btn: Button = find_child("Option_%d_Button" % 0, true, false) as Button
		if first_btn != null:
			first_btn.grab_focus()


func _on_option_pressed(option_id: int) -> void:
	encounter_resolved.emit(option_id)
	visible = false


func hide_encounter() -> void:
	visible = false


func show_resolution_error(message: String) -> void:
	if _error_label == null:
		return
	_error_label.text = "%s · %s" % [Localization.text("ui.indisponivel"), message]
	_error_label.visible = true