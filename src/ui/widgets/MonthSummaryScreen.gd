extends Control
class_name MonthSummaryScreen

## Displays net month changes and resulting balances from the controller snapshots.

signal summary_finished

const STAT_NAME_KEYS: Dictionary = {
	"str": "stats.forca",
	"int": "stats.inteligencia",
	"cha": "stats.carisma",
	"ref": "stats.refinamento",
	"sta": "stats.resistencia",
	"eth": "stats.etica"
}

var _title_label: Label
var _summary_label: Label
var _attributes_container: VBoxContainer
var _credits_label: Label
var _stress_label: Label
var _finish_button: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "SummaryPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "SummaryLayout"
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.text = Localization.text("ui.resumo_mensal")
	layout.add_child(_title_label)
	_summary_label = Label.new()
	_summary_label.name = "SummaryLabel"
	layout.add_child(_summary_label)

	var attributes_heading: Label = Label.new()
	attributes_heading.text = Localization.text("ui.atributos")
	layout.add_child(attributes_heading)
	_attributes_container = VBoxContainer.new()
	_attributes_container.name = "Attributes"
	_attributes_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_attributes_container)

	_credits_label = Label.new()
	_credits_label.name = "CreditsLabel"
	layout.add_child(_credits_label)
	_stress_label = Label.new()
	_stress_label.name = "StressLabel"
	layout.add_child(_stress_label)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)
	_finish_button = Button.new()
	_finish_button.name = "FinishButton"
	_finish_button.text = Localization.text("ui.continuar")
	_finish_button.custom_minimum_size = Vector2(0.0, 44.0)
	_finish_button.focus_mode = Control.FOCUS_ALL
	_finish_button.pressed.connect(_on_finish_pressed)
	footer.add_child(_finish_button)


func display_month_summary(
	pre_state: Dictionary,
	post_state: Dictionary,
	_period_results: Array[PeriodResult] = []
) -> void:
	if not is_node_ready():
		return
	var pre_calendar: Dictionary = pre_state.get("calendar", {})
	var post_calendar: Dictionary = post_state.get("calendar", {})
	var completed: int = int(post_calendar.get("completed_periods", 0)) - int(pre_calendar.get("completed_periods", 0))
	_summary_label.text = Localization.format(
		"ui.periodos_concluidos_format", {"completed": completed, "total": completed}
	)
	_build_stat_deltas(pre_state, post_state)

	var pre_economy: Dictionary = pre_state.get("economy", {})
	var post_economy: Dictionary = post_state.get("economy", {})
	var credits_delta: int = int(post_economy.get("credits", 0)) - int(pre_economy.get("credits", 0))
	var final_credits: int = int(post_economy.get("credits", 0))
	_credits_label.text = "%s: %s · %s" % [
		Localization.text("ui.creditos"),
		Localization.format("ui.creditos_format", {"value": credits_delta}),
		Localization.format("ui.creditos_format", {"value": final_credits})
	]

	var pre_stats: Dictionary = pre_state.get("stats", {})
	var post_stats: Dictionary = post_state.get("stats", {})
	var stress_delta: int = int(post_stats.get("stress", 0)) - int(pre_stats.get("stress", 0))
	_stress_label.text = "%s: %s · %d" % [
		Localization.text("ui.stress"),
		_format_signed(stress_delta),
		int(post_stats.get("stress", 0))
	]
	_finish_button.disabled = false
	visible = true
	_finish_button.grab_focus()


func _build_stat_deltas(pre_state: Dictionary, post_state: Dictionary) -> void:
	for child: Node in _attributes_container.get_children():
		_attributes_container.remove_child(child)
		child.queue_free()
	var pre_stats: Dictionary = pre_state.get("stats", {})
	var post_stats: Dictionary = post_state.get("stats", {})
	for stat_id: String in STAT_NAME_KEYS:
		var before: int = int(pre_stats.get(stat_id, 0))
		var after: int = int(post_stats.get(stat_id, 0))
		var delta: int = after - before
		var row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = Label.new()
		name_label.text = Localization.text(str(STAT_NAME_KEYS[stat_id]))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var delta_label: Label = Label.new()
		delta_label.text = _format_signed(delta)
		delta_label.add_theme_color_override(
			"font_color",
			Color(0.45, 0.85, 0.45) if delta > 0 else Color(0.94, 0.4, 0.4)
		)
		row.add_child(delta_label)
		var value_label: Label = Label.new()
		value_label.text = str(after)
		row.add_child(value_label)
		_attributes_container.add_child(row)


func _format_signed(value: int) -> String:
	return ("+" if value > 0 else "") + str(value)


func _on_finish_pressed() -> void:
	if _finish_button != null:
		_finish_button.disabled = true
	summary_finished.emit()
