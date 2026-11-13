extends Control
class_name ActivitySelection

## Displays one activity category and emits a draft choice; it never mutates the simulation.

signal activity_selected(choice_data: Dictionary)
signal activity_selection_closed

const STAT_NAME_KEYS: Dictionary = {
	"str": "stats.forca",
	"int": "stats.inteligencia",
	"cha": "stats.carisma",
	"ref": "stats.refinamento",
	"sta": "stats.resistencia",
	"eth": "stats.etica"
}

var _choices: Array[Dictionary] = []
var _credits: int = 0
var _period_index: int = 0
var _category_label: String = ""
var _interaction_enabled: bool = true
var _cards: VBoxContainer
var _credit_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var focused_activity_id: String = ""
	if _cards != null:
		for child: Node in _cards.get_children():
			var existing_card: Button = child as Button
			if existing_card != null and existing_card.has_focus():
				focused_activity_id = existing_card.name.trim_prefix("Card_")
				break

	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "ActivitySelectionLayout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)

	var heading: HBoxContainer = HBoxContainer.new()
	heading.name = "Heading"
	layout.add_child(heading)

	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = _category_label
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)

	_credit_label = Label.new()
	_credit_label.name = "CreditsLabel"
	_credit_label.text = _format_credits(_credits)
	heading.add_child(_credit_label)

	_cards = VBoxContainer.new()
	_cards.name = "ActivityCards"
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_cards)
	for choice: Dictionary in _choices:
		_cards.add_child(_build_activity_card(choice))
	if not focused_activity_id.is_empty():
		var focused_card: Button = _cards.get_node_or_null(
			"Card_%s" % focused_activity_id
		) as Button
		if focused_card != null and not focused_card.disabled:
			focused_card.grab_focus()


func _build_activity_card(choice: Dictionary) -> Button:
	var card: Button = Button.new()
	card.name = "Card_%s" % str(choice.get("id", "unknown"))
	card.custom_minimum_size = Vector2(0.0, 52.0)
	card.focus_mode = Control.FOCUS_ALL
	card.disabled = not _interaction_enabled or not bool(choice.get("can_afford", false))

	var display_name: String = str(choice.get("display_name", ""))
	var level: int = int(choice.get("level", 1))
	var details: Array[String] = [display_name]
	var activity_type: String = str(choice.get("activity_type", ""))
	if level > 0 and activity_type in ["study", "work"]:
		details.append(Localization.format("ui.nivel_curso_format", {"level": level}))

	var credit_delta: int = int(choice.get("income", 0)) - int(choice.get("cost", 0))
	if credit_delta != 0:
		details.append(_format_credits(credit_delta))

	var preview: Dictionary = choice.get("preview", {})
	for stat_id: String in preview:
		var delta: int = int(preview[stat_id])
		if stat_id == "stress":
			details.append("%s: %s" % [Localization.text("ui.stress"), _format_signed(delta)])
		elif STAT_NAME_KEYS.has(stat_id):
			details.append(
				"%s: %s" % [
					Localization.text(str(STAT_NAME_KEYS[stat_id])),
					_format_signed(delta)
				]
			)

	if choice.has("error"):
		details.append(
			"%s · %s" % [Localization.text("ui.indisponivel"), str(choice.get("id", ""))]
		)
	elif not bool(choice.get("can_afford", false)):
		match str(choice.get("reason", "")):
			"disease":
				details.append(Localization.text("ui.doenca_ativa"))
			"insufficient_credits":
				details.append(
					Localization.format(
						"ui.creditos_insuficientes_format",
						{
							"available": Localization.format(
								"ui.creditos_format",
								{"value": int(choice.get("available_credits", 0))}
							),
							"cost": Localization.format(
								"ui.creditos_format",
								{"value": int(choice.get("cost", 0))}
							)
						}
					)
				)
			_:
				details.append(Localization.text("ui.indisponivel"))
	card.text = "\n".join(details)
	card.tooltip_text = card.text
	card.pressed.connect(_on_activity_card_pressed.bind(choice))
	return card


func _format_credits(value: int) -> String:
	var formatted: String = Localization.format("ui.creditos_format", {"value": absi(value)})
	if value < 0:
		return "-" + formatted
	if value > 0:
		return "+" + formatted
	return formatted


func _format_signed(value: int) -> String:
	return ("+" if value > 0 else "") + str(value)


func show_activity_selection(
	choices: Array[Dictionary],
	credits: int,
	period: int,
	category_label: String,
	interaction_enabled: bool = true
) -> void:
	_choices = choices.duplicate(true)
	_credits = credits
	_period_index = period
	_category_label = category_label
	_interaction_enabled = interaction_enabled
	custom_minimum_size = Vector2(0.0, 40.0 + _choices.size() * 58.0)
	if is_node_ready():
		_build_ui()
	visible = true


func _on_activity_card_pressed(choice: Dictionary) -> void:
	if not _interaction_enabled or not bool(choice.get("can_afford", false)):
		return
	var selected: Dictionary = choice.duplicate(true)
	selected["period_index"] = _period_index
	activity_selected.emit(selected)


func close() -> void:
	visible = false
	activity_selection_closed.emit()
