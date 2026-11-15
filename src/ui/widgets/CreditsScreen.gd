extends Control
class_name CreditsScreen

signal credits_closed

const CREDITS_HEIGHT: int = 200

var _title_label: Label
var _credits_label: Label
var _close_button: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
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
	panel.name = "CreditsPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.z_index = 1
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "CreditsLayout"
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.text = Localization.text("ui.creditos")
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_title_label)

	_credits_label = Label.new()
	_credits_label.name = "CreditsLabel"
	_credits_label.add_theme_font_size_override("font_size", 18)
	_credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits_label.text = Localization.text("ui.credits.text")
	layout.add_child(_credits_label)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "CreditsFooter"
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = Localization.text("ui.fechar")
	_close_button.custom_minimum_size = Vector2(0.0, 44.0)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.pressed.connect(_on_close_pressed)
	footer.add_child(_close_button)


func show_credits() -> void:
	visible = true
	if _close_button != null:
		_close_button.grab_focus()


func _on_close_pressed() -> void:
	visible = false
	credits_closed.emit()


func hide_credits() -> void:
	visible = false