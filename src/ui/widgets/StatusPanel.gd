extends PanelContainer
class_name StatusPanel

const STAT_DATA_PATH: String = "res://assets/data/stats.json"
const STAT_IDS: Array[String] = ["str", "int", "cha", "ref", "sta", "eth"]
const REPUTATION_IDS: Array[String] = ["fighter", "social", "hacker"]
const COURSE_IDS: Array[String] = [
	"curso_tecnologia", "curso_comunicacao", "curso_artes"
]
const COURSE_NAME_KEYS: Dictionary = {
	"curso_tecnologia": "courses.curso_tecnologia",
	"curso_comunicacao": "courses.curso_comunicacao",
	"curso_artes": "courses.curso_artes"
}
const REPUTATION_NAME_KEYS: Dictionary = {
	"fighter": "ui.rep_fighter",
	"social": "ui.rep_social",
	"hacker": "ui.rep_hacker"
}

var expanded: bool = false
var _simulation: SimulationCore
var _stat_names: Dictionary = {}
var _stats_available: bool = false
var _content: VBoxContainer
var _body: VBoxContainer


func _ready() -> void:
	_stats_available = _load_stat_names()
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.add_theme_constant_override("separation", 4)
	add_child(_content)
	_refresh_display()


func update_from_simulation(sim: SimulationCore) -> void:
	_simulation = sim
	if is_node_ready():
		_refresh_display()


func toggle_expanded() -> void:
	set_expanded(not expanded)


func set_expanded(value: bool) -> void:
	expanded = value
	if not is_node_ready():
		return
	size.y = 500.0 if expanded else 390.0
	custom_minimum_size.y = size.y
	_refresh_display()


func _load_stat_names() -> bool:
	if not FileAccess.file_exists(STAT_DATA_PATH):
		push_error("Stat definitions do not exist: %s." % STAT_DATA_PATH)
		return false
	var file: FileAccess = FileAccess.open(STAT_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open stat definitions: %s." % STAT_DATA_PATH)
		return false

	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Invalid stat definitions at line %d: %s."
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return false
	if not parser.data is Dictionary:
		push_error("Stat definitions must be a JSON object.")
		return false
	var records: Variant = parser.data.get("stats")
	if not records is Array:
		push_error("Stat definitions must contain a 'stats' array.")
		return false

	var loaded_names: Dictionary = {}
	for record: Variant in records:
		if not record is Dictionary:
			push_error("Each stat definition must be an object.")
			return false
		var stat_id: Variant = record.get("id")
		var stat_name: Variant = record.get("name")
		if not stat_id is String or not stat_name is String:
			push_error("Each stat definition must contain string 'id' and 'name' fields.")
			return false
		var normalized_id: String = str(stat_id).to_lower()
		if loaded_names.has(normalized_id):
			push_error("Duplicate stat definition '%s'." % normalized_id)
			return false
		loaded_names[normalized_id] = str(stat_name)

	for stat_id: String in STAT_IDS:
		if not loaded_names.has(stat_id):
			push_error("Stat definitions are missing '%s'." % stat_id)
			return false
	_stat_names = loaded_names
	return true


func _refresh_display() -> void:
	if _content == null:
		return
	_remove_body()
	_body = VBoxContainer.new()
	_body.name = "StatusBody"
	_body.add_theme_constant_override("separation", 2)
	_content.add_child(_body)

	if _simulation == null:
		_add_body_label(_body, Localization.text("ui.sem_campanha"), 14)
		return
	if not _stats_available:
		_add_body_label(_body, Localization.text("ui.indisponivel"), 14)
		return

	if expanded:
		_build_detailed_status()
	else:
		_build_compact_status()


func _remove_body() -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


func _build_compact_status() -> void:
	_add_group_heading(_body, "ui.atributos")
	for row_start: int in range(0, STAT_IDS.size(), 2):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		for offset: int in 2:
			var stat_index: int = row_start + offset
			if stat_index >= STAT_IDS.size():
				continue
			var stat_id: String = STAT_IDS[stat_index]
			var entry: String = "%s: %d" % [
				str(_stat_names[stat_id]), _simulation.stats.get_stat(stat_id)
			]
			var stat_label: Label = _add_body_label(row, entry, 13)
			stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			stat_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_body.add_child(row)

	_add_group_heading(_body, "ui.combate")
	_add_body_label(_body, Localization.text("ui.combate_automatico"), 13)
	_add_group_heading(_body, "ui.reputacoes")
	_add_body_label(_body, _reputation_summary(), 13)
	_add_group_heading(_body, "ui.habilidades")
	_add_body_label(_body, _course_summary(), 13)


func _build_detailed_status() -> void:
	_add_group_heading(_body, "ui.atributos")
	for stat_id: String in STAT_IDS:
		_add_progress_row(
			_body,
			str(_stat_names[stat_id]),
			_simulation.stats.get_stat(stat_id),
			100
		)
	_add_progress_row(
		_body,
		Localization.text("ui.stress"),
		_simulation.stats.get_stress(),
		100
	)
	var disease_key: String = (
		"ui.doenca_ativa" if _simulation.stats.is_diseased else "ui.sem_doenca"
	)
	_add_body_label(_body, Localization.text(disease_key), 13)

	_add_group_heading(_body, "ui.combate")
	_add_body_label(_body, Localization.text("ui.combate_automatico"), 13)

	_add_group_heading(_body, "ui.reputacoes")
	for reputation_id: String in REPUTATION_IDS:
		var reputation_name: String = Localization.text(
			str(REPUTATION_NAME_KEYS[reputation_id])
		)
		_add_progress_row(
			_body,
			reputation_name,
			_simulation.stats.get_reputation(reputation_id),
			100
		)

	_add_group_heading(_body, "ui.habilidades")
	for course_id: String in COURSE_IDS:
		var course_name: String = Localization.text(str(COURSE_NAME_KEYS[course_id]))
		var course_level: int = _simulation.activities.get_course_level(course_id)
		_add_body_label(
			_body,
			"%s — %s" % [
				course_name,
				Localization.format("ui.nivel_curso_format", {"level": course_level})
			],
			13
		)


func _reputation_summary() -> String:
	var values: PackedStringArray = PackedStringArray()
	for reputation_id: String in REPUTATION_IDS:
		var name_key: String = str(REPUTATION_NAME_KEYS[reputation_id])
		values.append(
			"%s: %d" % [
				Localization.text(name_key),
				_simulation.stats.get_reputation(reputation_id)
			]
		)
	return " · ".join(values)


func _course_summary() -> String:
	var values: PackedStringArray = PackedStringArray()
	for course_id: String in COURSE_IDS:
		var course_name: String = Localization.text(str(COURSE_NAME_KEYS[course_id]))
		var level: int = _simulation.activities.get_course_level(course_id)
		values.append(
			"%s: %s" % [
				course_name,
				Localization.format("ui.nivel_curso_format", {"level": level})
			]
		)
	return " · ".join(values)


func _add_group_heading(parent: VBoxContainer, string_id: String) -> void:
	var heading: Label = _add_body_label(parent, Localization.text(string_id), 14)
	heading.add_theme_color_override("font_color", Color(0.42, 0.86, 0.91, 1.0))


func _add_progress_row(
	parent: VBoxContainer, row_name: String, value: int, maximum: int
) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_label: Label = _add_body_label(row, row_name, 12)
	name_label.custom_minimum_size.x = 94.0
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var progress: ProgressBar = ProgressBar.new()
	progress.name = "StatusProgress"
	progress.min_value = 0.0
	progress.max_value = maximum
	progress.value = value
	progress.show_percentage = false
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.custom_minimum_size = Vector2(80.0, 16.0)
	row.add_child(progress)

	var value_label: Label = _add_body_label(row, str(value), 12)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 28.0
	parent.add_child(row)


func _add_body_label(parent: Node, value: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label
