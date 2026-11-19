class_name TalkScreen
extends Control

## Short, read-only family conversations. No hidden attribute or time rewards.
signal closed
var _reply: Label
var _portrait: TextureRect
var _simulation: SimulationCore
var _profile: Dictionary

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_top = 24
	panel.offset_right = -24
	panel.offset_bottom = -24
	add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = Localization.text("ui.falar")
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)
	_portrait = ArtPresentation.artwork(layout, &"bg_bedroom_day", Vector2(0, 260), "ConversationPortrait")
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reply = Label.new()
	_reply.name = "Reply"
	_reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reply.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reply.add_theme_font_size_override("font_size", 20)
	layout.add_child(_reply)
	for topic: String in ["wellbeing", "study", "city"]:
		var button: Button = Button.new()
		button.name = "Topic_" + topic
		button.text = Localization.text("ui.talk_" + topic)
		button.custom_minimum_size.y = 44
		button.pressed.connect(_answer.bind(topic))
		layout.add_child(button)
	var close: Button = Button.new()
	close.name = "CloseButton"
	close.text = Localization.text("ui.voltar")
	close.custom_minimum_size.y = 44
	close.pressed.connect(close_conversation)
	layout.add_child(close)

func open_conversation(sim: SimulationCore, profile: Dictionary) -> void:
	_simulation = sim
	_profile = profile
	if theme != null:
		_portrait.custom_minimum_size.y = 260.0 / maxf(theme.default_base_scale, 1.0)
	visible = true
	_answer("wellbeing")
	(find_child("Topic_wellbeing", true, false) as Button).grab_focus()

func _answer(topic: String) -> void:
	var state: String = "normal"
	if _simulation.stats.is_diseased:
		state = "sick"
	elif _simulation.stats.get_stress() >= _simulation.stats.get_disease_threshold() / 2:
		state = "tired"
	var key: String = "ui.talk_reply_" + (state if topic == "wellbeing" else topic)
	_reply.text = Localization.format(key, {"name": _profile.get("name", _simulation.character_name)})
	var face: StringName = &"portrait_rat_neutral"
	if state == "sick":
		face = &"portrait_rat_sick"
	elif state == "tired":
		face = &"portrait_rat_tired"
	elif topic == "study":
		face = &"portrait_rat_happy"
	_portrait.texture = Assets.get_texture(face, &"characters")
	EventBus.ui_audio_requested.emit("ui_confirm")

func close_conversation() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_conversation()
		get_viewport().set_input_as_handled()
