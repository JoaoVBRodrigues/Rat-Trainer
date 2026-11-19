extends Control
class_name OptionsScreen

signal settings_changed(settings: Dictionary)
signal back_requested

var _settings: Dictionary = {}
var _sliders: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "OptionsPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640.0, 520.0)
	panel.offset_left = -320.0
	panel.offset_top = -260.0
	panel.offset_right = 320.0
	panel.offset_bottom = 260.0
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "OptionsLayout"
	layout.add_theme_constant_override("separation", 14)
	panel.add_child(layout)

	var title: Label = Label.new()
	title.text = Localization.text("ui.opcoes")
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)

	_add_slider(layout, "music_volume", 0.0, 100.0, 5.0)
	_add_slider(layout, "sfx_volume", 0.0, 100.0, 5.0)
	_add_slider(layout, "animation_speed", 50.0, 200.0, 25.0)
	_add_slider(layout, "text_scale", 80.0, 150.0, 5.0)

	var back_button: Button = Button.new()
	back_button.name = "OptionsBackButton"
	back_button.text = Localization.text("ui.voltar")
	back_button.custom_minimum_size = Vector2(0.0, 44.0)
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.pressed.connect(func() -> void: back_requested.emit())
	back_button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
	layout.add_child(back_button)


func _add_slider(
	parent: VBoxContainer,
	setting_id: String,
	minimum: float,
	maximum: float,
	step: float
) -> void:
	var row: VBoxContainer = VBoxContainer.new()
	row.name = "Setting_%s" % setting_id
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label: Label = Label.new()
	label.name = "Label"
	label.text = Localization.text("ui.%s" % setting_id)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(_on_slider_changed.bind(setting_id))
	row.add_child(slider)
	_sliders[setting_id] = slider


func load_settings(settings: Dictionary) -> bool:
	for key: String in ["music_volume", "sfx_volume", "animation_speed", "text_scale"]:
		var value: Variant = settings.get(key, null)
		if not value is int:
			push_error("Cannot display options because setting '%s' is invalid." % key)
			return false
	_settings = settings.duplicate(true)
	for setting_id: String in _sliders:
		var slider: HSlider = _sliders[setting_id] as HSlider
		slider.set_value_no_signal(float(_settings[setting_id]))
	return true


func _on_slider_changed(value: float, setting_id: String) -> void:
	_settings[setting_id] = roundi(value)
	settings_changed.emit(_settings.duplicate(true))
