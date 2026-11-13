extends Control
class_name ActivityResultScreen

## Presents applied PeriodResult values only; it never resolves or mutates a period.

signal result_continued
signal activity_completed

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

var _title_label: Label
var _outcome_label: Label
var _period_label: Label
var _description_label: Label
var _placeholder_label: Label
var _changes_container: VBoxContainer
var _values_container: VBoxContainer
var _continue_button: Button
var _skip_button: Button
var _result: PeriodResult
var _simulation: SimulationCore


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ResultPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "ResultLayout"
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.name = "Header"
	layout.add_child(header)
	_outcome_label = Label.new()
	_outcome_label.name = "OutcomeIndicator"
	_outcome_label.custom_minimum_size.x = 40.0
	header.add_child(_outcome_label)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_title_label)
	_period_label = Label.new()
	_period_label.name = "PeriodLabel"
	header.add_child(_period_label)

	_description_label = Label.new()
	_description_label.name = "SummaryLabel"
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_description_label)

	var placeholder_panel: PanelContainer = PanelContainer.new()
	placeholder_panel.name = "ActivityPlaceholderPanel"
	placeholder_panel.custom_minimum_size = Vector2(0.0, 128.0)
	placeholder_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(placeholder_panel)
	var placeholder_center: CenterContainer = CenterContainer.new()
	placeholder_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder_panel.add_child(placeholder_center)
	_placeholder_label = Label.new()
	_placeholder_label.name = "ActivityPlaceholderLabel"
	_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder_center.add_child(_placeholder_label)

	var result_heading: Label = Label.new()
	result_heading.text = Localization.text("ui.atributos")
	layout.add_child(result_heading)
	_changes_container = VBoxContainer.new()
	_changes_container.name = "ChangesContainer"
	layout.add_child(_changes_container)

	var values_heading: Label = Label.new()
	values_heading.text = Localization.text("ui.status")
	layout.add_child(values_heading)
	_values_container = VBoxContainer.new()
	_values_container.name = "ValuesContainer"
	_values_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_values_container)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)
	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = Localization.text("ui.pular_apresentacao")
	_skip_button.custom_minimum_size = Vector2(0.0, 44.0)
	_skip_button.focus_mode = Control.FOCUS_ALL
	_skip_button.pressed.connect(_on_continue_pressed)
	footer.add_child(_skip_button)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = Localization.text("ui.continuar")
	_continue_button.custom_minimum_size = Vector2(0.0, 44.0)
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.pressed.connect(_on_continue_pressed)
	footer.add_child(_continue_button)


func show_result(result: PeriodResult, simulation: SimulationCore) -> void:
	_result = result
	_simulation = simulation
	visible = true
	display_result(result, simulation)
	if _continue_button != null:
		_continue_button.disabled = false
		_skip_button.disabled = false
		_continue_button.grab_focus()


func display_result(result: PeriodResult, simulation: SimulationCore) -> void:
	_result = result
	_simulation = simulation
	if not is_node_ready():
		return
	var record: Dictionary = _activity_record(result)
	if (
		record.is_empty()
		or not record.get("name", "") is String
		or str(record.get("name", "")).is_empty()
	):
		push_error("activity_data_missing_or_malformed_record:%s" % result.activity_id)
	var succeeded: bool = result.completed
	if result.activity_type == PeriodResult.ActivityType.MISSION:
		succeeded = result.mission_success
	_outcome_label.text = (
		"✓ %s" % Localization.text("ui.resultado_sucesso")
		if succeeded
		else "× %s" % Localization.text("ui.resultado_falha")
	)
	_outcome_label.tooltip_text = Localization.text("ui.missao") if result.activity_type == PeriodResult.ActivityType.MISSION else ""
	var activity_name: String = _activity_name(result, record)
	_title_label.text = activity_name
	_placeholder_label.text = activity_name
	_period_label.text = _format_period(result)
	_description_label.text = str(record.get("description", ""))
	_build_changes(result)
	_build_resulting_values(result)
	activity_completed.emit()


func _activity_record(result: PeriodResult) -> Dictionary:
	if _simulation == null:
		return {}
	match result.activity_type:
		PeriodResult.ActivityType.STUDY, PeriodResult.ActivityType.WORK, PeriodResult.ActivityType.LEISURE:
			return _simulation.activities.get_course(result.activity_id)
		PeriodResult.ActivityType.MISSION:
			return _simulation.activities.get_mission(result.activity_id)
	return {}


func _activity_name(result: PeriodResult, record: Dictionary) -> String:
	var name_keys: Dictionary = {
		"curso_tecnologia": "courses.curso_tecnologia",
		"curso_comunicacao": "courses.curso_comunicacao",
		"curso_artes": "courses.curso_artes"
	}
	if name_keys.has(result.activity_id):
		return Localization.text(str(name_keys[result.activity_id]))
	var name: Variant = record.get("name", "")
	if name is String and not str(name).is_empty():
		return str(name)
	return "%s · %s" % [
		Localization.text("ui.indisponivel"),
		result.activity_id
	]


func _format_period(result: PeriodResult) -> String:
	var months: Array[String] = Localization.get_string_array("calendar.months")
	var weekdays: Array[String] = Localization.get_string_array("calendar.weekdays")
	if result.month < 1 or result.month > months.size() or result.period_num < 1 or result.period_num > weekdays.size():
		return Localization.text("ui.indisponivel")
	var date: String = Localization.format(
		"ui.data_format", {"year": result.year, "month": months[result.month - 1]}
	)
	var period: String = Localization.format(
		"ui.periodo_format",
		{
			"weekday": weekdays[result.period_num - 1],
			"day": 1 + (result.period_num - 1) * 10,
			"period": result.period_num
		}
	)
	return "%s · %s" % [date, period]


func _build_changes(result: PeriodResult) -> void:
	_clear_children(_changes_container)
	if result.credits_change != 0:
		_add_change_row(
			Localization.text("ui.creditos"),
			result.credits_change
		)
	for stat_id: String in result.stat_changes:
		if STAT_NAME_KEYS.has(stat_id):
			_add_change_row(Localization.text(str(STAT_NAME_KEYS[stat_id])), int(result.stat_changes[stat_id]))
	for reputation_id: String in result.rep_gained:
		if REPUTATION_NAME_KEYS.has(reputation_id):
			_add_change_row(
				Localization.text(str(REPUTATION_NAME_KEYS[reputation_id])),
				int(result.rep_gained[reputation_id])
			)
	if result.stress_change != 0:
		_add_change_row(Localization.text("ui.stress"), result.stress_change)


func _build_resulting_values(result: PeriodResult) -> void:
	_clear_children(_values_container)
	var stats: Dictionary = result.post_period_state.get("stats", {})
	for stat_id: String in STAT_NAME_KEYS:
		if stats.has(stat_id):
			_add_value_row(
				Localization.text(str(STAT_NAME_KEYS[stat_id])),
				int(stats[stat_id])
			)
	_add_value_row(Localization.text("ui.stress"), result.stress_final)
	var economy: Dictionary = result.post_period_state.get("economy", {})
	if economy.has("credits"):
		_add_value_row(
			Localization.text("ui.creditos"),
			int(economy["credits"])
		)


func _add_change_row(label_text: String, delta: int) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = _format_signed(delta)
	value_label.add_theme_color_override(
		"font_color",
		Color(0.45, 0.85, 0.45) if delta > 0 else Color(0.94, 0.4, 0.4)
	)
	row.add_child(value_label)
	_changes_container.add_child(row)


func _add_value_row(label_text: String, value: int) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = str(value)
	row.add_child(value_label)
	_values_container.add_child(row)


func _format_signed(value: int) -> String:
	return ("+" if value > 0 else "") + str(value)


func _clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_continue_pressed() -> void:
	if _continue_button != null:
		_continue_button.disabled = true
	if _skip_button != null:
		_skip_button.disabled = true
	result_continued.emit()


func hide_result() -> void:
	visible = false
