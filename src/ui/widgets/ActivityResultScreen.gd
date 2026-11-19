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
var _inventory_warning_label: Label
var _placeholder_label: Label
var _changes_container: VBoxContainer
var _values_container: VBoxContainer
var _continue_button: Button
var _skip_button: Button
var _result: PeriodResult
var _simulation: SimulationCore
var _artwork: TextureRect
var _character_art: TextureRect


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ResultPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	UIThemeResource.frame_panel(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "ResultLayout"
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	_outcome_label = Label.new()
	_outcome_label.name = "OutcomeIndicator"
	header.add_child(_outcome_label)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_FILL
	_title_label.custom_minimum_size.y = 36
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_title_label)
	_period_label = Label.new()
	_period_label.name = "PeriodLabel"
	_period_label.custom_minimum_size.x = 300
	_period_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_period_label)
	_description_label = Label.new()
	_description_label.name = "SummaryLabel"
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_description_label)
	_inventory_warning_label = Label.new()
	_inventory_warning_label.name = "InventoryWarning"
	_inventory_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_inventory_warning_label)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	layout.add_child(body)
	var illustration: VBoxContainer = VBoxContainer.new()
	illustration.name = "ResultIllustration"
	illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustration.add_theme_constant_override("separation", 20)
	body.add_child(illustration)
	_artwork = ArtPresentation.artwork(illustration, &"bg_school", Vector2(0, 240), "ActivityArtwork")
	var portrait_stage: Control = Control.new()
	portrait_stage.name = "ResultPortraitStage"
	portrait_stage.custom_minimum_size.x = 360
	portrait_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_stage.clip_contents = true
	portrait_stage.z_index = 1
	body.add_child(portrait_stage)
	_character_art = TextureRect.new()
	_character_art.name = "ResultCharacter"
	_character_art.position = Vector2(-64, -10)
	_character_art.size = Vector2(500, 800)
	_character_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_character_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_stage.add_child(_character_art)
	# Accessible activity text is retained without the former zero-width CenterContainer.
	_placeholder_label = Label.new()
	_placeholder_label.name = "ActivityPlaceholderLabel"
	_placeholder_label.visible = false
	layout.add_child(_placeholder_label)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ResultDetails"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	illustration.add_child(scroll)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 32)
	scroll.add_child(columns)
	_changes_container = _detail_column(columns, "ChangesContainer", "ui.atributos")
	_values_container = _detail_column(columns, "ValuesContainer", "ui.status")
	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)
	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = Localization.text("ui.pular_apresentacao")
	_skip_button.custom_minimum_size = Vector2(0, 44)
	_skip_button.pressed.connect(_on_continue_pressed)
	footer.add_child(_skip_button)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = Localization.text("ui.continuar")
	_continue_button.custom_minimum_size = Vector2(150, 44)
	_continue_button.pressed.connect(_on_continue_pressed)
	footer.add_child(_continue_button)

func _detail_column(parent: HBoxContainer, node_name: String, title_key: String) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var title: Label = Label.new()
	title.text = Localization.text(title_key)
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	var entries: VBoxContainer = VBoxContainer.new()
	entries.name = node_name
	column.add_child(entries)
	return entries


func show_result(result: PeriodResult, simulation: SimulationCore) -> void:
	_result = result
	_simulation = simulation
	visible = true
	display_result(result, simulation)
	if _continue_button != null:
		_continue_button.disabled = false
		_skip_button.disabled = false
		_continue_button.grab_focus()
		_continue_button.text = Localization.text("ui.continuar")


func show_save_error() -> void:
	_inventory_warning_label.text = Localization.text("ui.save_retry")
	_inventory_warning_label.visible = true
	_continue_button.text = Localization.text("ui.retry_save")
	_continue_button.disabled = false
	_skip_button.disabled = true


func display_result(result: PeriodResult, simulation: SimulationCore) -> void:
	_result = result
	_simulation = simulation
	if not is_node_ready():
		return
	_artwork.texture = Assets.get_texture(ArtPresentation.activity_id(result), &"backgrounds")
	_character_art.texture = Assets.get_texture(ArtPresentation.character_id(simulation), &"characters")
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
	elif not result.event_outcome.is_empty():
		succeeded = result.event_outcome == "success"
	_outcome_label.text = (
		"✓ %s" % Localization.text("ui.resultado_sucesso")
		if succeeded
		else "× %s" % Localization.text("ui.resultado_falha")
	)
	_outcome_label.tooltip_text = Localization.text("ui.missao") if result.activity_type == PeriodResult.ActivityType.MISSION else ""
	var activity_name: String = _activity_name(result, record)
	_title_label.text = activity_name
	_placeholder_label.text = activity_name
	if not result.encounter_monster_name.is_empty():
		_placeholder_label.text = "%s\n%s" % [
			result.encounter_monster_name,
			result.encounter_description
		]
		_description_label.text = result.encounter_description
	_period_label.text = _format_period(result)
	_inventory_warning_label.visible = not result.inventory_warning_key.is_empty()
	if _inventory_warning_label.visible:
		_inventory_warning_label.text = Localization.text(result.inventory_warning_key)
	if result.encounter_monster_name.is_empty():
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
		PeriodResult.ActivityType.EVENT:
			return _simulation.events.get_event_by_id(result.event_id)
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
	var stat_state: Dictionary = result.post_period_state.get("stats", {})
	var stats: Dictionary = stat_state.get("stats", stat_state)
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
