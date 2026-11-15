extends Control
class_name EventChoiceScreen

signal option_selected(option_id: String)

var _title_label: Label
var _description_label: Label
var _options_container: VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "EventPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560.0, 360.0)
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "EventLayout"
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	_title_label = Label.new()
	_title_label.name = "EventTitle"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_title_label)

	_description_label = Label.new()
	_description_label.name = "EventDescription"
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_description_label)

	_options_container = VBoxContainer.new()
	_options_container.name = "EventOptions"
	_options_container.add_theme_constant_override("separation", 8)
	layout.add_child(_options_container)


func open_event(event_data: Dictionary) -> bool:
	var event_id: Variant = event_data.get("id", "")
	var event_name: Variant = event_data.get("name", "")
	var description: Variant = event_data.get("description", "")
	var options: Variant = event_data.get("options", [])
	if (
		not event_id is String
		or event_id.is_empty()
		or not event_name is String
		or not description is String
		or not options is Array
		or options.is_empty()
	):
		push_error("Cannot show event choice screen with invalid event data.")
		return false
	if not is_node_ready():
		push_error("Event choice screen must enter the scene tree before opening an event.")
		return false
	_title_label.text = str(event_name)
	_description_label.text = str(description)
	for child: Node in _options_container.get_children():
		_options_container.remove_child(child)
		child.queue_free()
	for option: Variant in options:
		if not option is Dictionary:
			push_error("Event '%s' has a malformed option." % event_id)
			return false
		var option_id: Variant = option.get("id", "")
		var option_text: Variant = option.get("text", "")
		if not option_id is String or option_id.is_empty() or not option_text is String:
			push_error("Event '%s' has an option without a valid ID or label." % event_id)
			return false
		var button: Button = Button.new()
		button.name = "Option_%s" % option_id
		button.text = str(option_text)
		button.custom_minimum_size = Vector2(0.0, 48.0)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_option_pressed.bind(str(option_id)))
		button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
		_options_container.add_child(button)
	if _options_container.get_child_count() == 0:
		return false
	visible = true
	(_options_container.get_child(0) as Button).grab_focus()
	return true


func _on_option_pressed(option_id: String) -> void:
	option_selected.emit(option_id)


func close_event() -> void:
	visible = false
