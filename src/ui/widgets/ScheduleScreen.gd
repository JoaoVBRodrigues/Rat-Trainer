extends Control
class_name ScheduleScreen

## Planning screen. It owns only a draft MonthSchedule and emits it for validation.

signal schedule_confirmed(schedule: MonthSchedule)
signal schedule_cancelled

const CATEGORY_IDS: Array[String] = ["study", "work", "mission", "leisure"]
const PERIOD_COUNT: int = 3

var _simulation: SimulationCore
var _schedule: MonthSchedule
var _previous_schedule: MonthSchedule
var _choices_by_category: Dictionary = {}
var _active_category: String = "study"
var _active_period: int = 0
var _period_buttons: Array[Button] = []
var _category_buttons: Dictionary = {}
var _category_row: HBoxContainer
var _selection_host: ActivitySelection
var _status_label: Label
var _confirm_button: Button
var _repeat_button: Button
var _cancel_button: Button
var _credits_label: Label
var _cancel_allowed: bool = true
var _first_editable_period: int = 0
var _recovery_blocked: bool = false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "SchedulePanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "ScheduleLayout"
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.name = "Header"
	layout.add_child(header)
	var title: Label = Label.new()
	title.text = Localization.text("ui.agenda")
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_credits_label = Label.new()
	_credits_label.name = "CreditsLabel"
	header.add_child(_credits_label)

	var slots: HBoxContainer = HBoxContainer.new()
	slots.name = "PeriodsContainer"
	slots.add_theme_constant_override("separation", 8)
	layout.add_child(slots)
	_period_buttons.clear()
	for period_index: int in PERIOD_COUNT:
		var slot: Button = Button.new()
		slot.name = "Period_%d" % (period_index + 1)
		slot.custom_minimum_size = Vector2(0.0, 68.0)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.focus_mode = Control.FOCUS_ALL
		slot.pressed.connect(_on_period_pressed.bind(period_index))
		slots.add_child(slot)
		_period_buttons.append(slot)

	_category_row = HBoxContainer.new()
	_category_row.name = "CategoryTabs"
	_category_row.add_theme_constant_override("separation", 6)
	layout.add_child(_category_row)
	_category_buttons.clear()
	for category: String in CATEGORY_IDS:
		var tab: Button = Button.new()
		tab.name = "Category_%s" % category
		tab.custom_minimum_size = Vector2(0.0, 44.0)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.focus_mode = Control.FOCUS_ALL
		tab.pressed.connect(_on_category_pressed.bind(category))
		_category_row.add_child(tab)
		_category_buttons[category] = tab

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ActivityScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	_selection_host = ActivitySelection.new()
	_selection_host.name = "ActivitySelection"
	_selection_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_selection_host.activity_selected.connect(_on_activity_selected)
	scroll.add_child(_selection_host)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.focus_mode = Control.FOCUS_ALL
	layout.add_child(_status_label)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 8)
	layout.add_child(footer)
	_repeat_button = Button.new()
	_repeat_button.name = "RepeatButton"
	_repeat_button.custom_minimum_size = Vector2(0.0, 44.0)
	_repeat_button.focus_mode = Control.FOCUS_ALL
	_repeat_button.text = "↻ " + Localization.text("ui.repetir_agenda")
	_repeat_button.pressed.connect(_on_repeat_pressed)
	footer.add_child(_repeat_button)

	_cancel_button = Button.new()
	_cancel_button.name = "CancelButton"
	_cancel_button.custom_minimum_size = Vector2(0.0, 44.0)
	_cancel_button.focus_mode = Control.FOCUS_ALL
	_cancel_button.text = Localization.text("ui.cancelar")
	_cancel_button.pressed.connect(_on_cancel_pressed)
	footer.add_child(_cancel_button)

	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmButton"
	_confirm_button.custom_minimum_size = Vector2(0.0, 44.0)
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.focus_mode = Control.FOCUS_ALL
	_confirm_button.text = Localization.text("ui.agendar")
	_confirm_button.pressed.connect(_on_confirm_pressed)
	footer.add_child(_confirm_button)


func open_schedule(
	simulation: SimulationCore,
	draft: MonthSchedule,
	previous_schedule: MonthSchedule,
	choices_by_category: Dictionary,
	error_message: String = "",
	active_period_index: int = 0,
	cancel_allowed: bool = true,
	first_editable_period: int = 0,
	recovery_blocked: bool = false
) -> void:
	_simulation = simulation
	_schedule = draft.duplicate_schedule()
	_previous_schedule = (
		previous_schedule.duplicate_schedule() if previous_schedule != null else null
	)
	_choices_by_category = choices_by_category.duplicate(true)
	_active_period = clampi(active_period_index, 0, PERIOD_COUNT - 1)
	_active_category = "study"
	_cancel_allowed = cancel_allowed
	_first_editable_period = clampi(first_editable_period, 0, PERIOD_COUNT - 1)
	_recovery_blocked = recovery_blocked
	if _active_period < _first_editable_period:
		_active_period = _first_editable_period
	if is_node_ready():
		_refresh()
		_status_label.text = (
			Localization.text("ui.indisponivel")
			if recovery_blocked or not error_message.is_empty()
			else ""
		)
	visible = true
	if is_node_ready() and not _period_buttons.is_empty():
		if _recovery_blocked:
			_status_label.grab_focus()
		else:
			_period_buttons[_first_editable_period].grab_focus()


func get_draft() -> MonthSchedule:
	return _schedule.duplicate_schedule() if _schedule != null else MonthSchedule.new()


func _on_period_pressed(period_index: int) -> void:
	if _recovery_blocked or period_index < _first_editable_period:
		return
	_active_period = period_index
	_refresh()


func _on_category_pressed(category: String) -> void:
	if _recovery_blocked:
		return
	_active_category = category
	_refresh_activity_list()


func _on_activity_selected(choice: Dictionary) -> void:
	if _recovery_blocked:
		return
	var period_index: int = int(choice.get("period_index", -1))
	if (
		period_index < _first_editable_period
		or period_index < 0
		or period_index >= PERIOD_COUNT
	):
		return
	var category: String = str(choice.get("activity_type", ""))
	var activity_period: MonthSchedule.ActivityPeriod = _period_from_category(category)
	if activity_period == MonthSchedule.ActivityPeriod.NONE:
		return
	var cost: int = int(choice.get("cost", 0))
	var income: int = int(choice.get("income", 0))
	_schedule.set_selection(
		period_index,
		activity_period,
		str(choice.get("id", "")),
		int(choice.get("level", 1)),
		cost,
		true,
		"",
		income
	)
	_active_period = period_index
	_update_affordability()
	_refresh()


func _period_from_category(category: String) -> MonthSchedule.ActivityPeriod:
	match category:
		"study":
			return MonthSchedule.ActivityPeriod.STUDY
		"work":
			return MonthSchedule.ActivityPeriod.WORK
		"mission":
			return MonthSchedule.ActivityPeriod.MISSION
		"leisure":
			return MonthSchedule.ActivityPeriod.LEISURE
	return MonthSchedule.ActivityPeriod.NONE


func _category_from_period(activity_period: int) -> String:
	match activity_period:
		MonthSchedule.ActivityPeriod.STUDY:
			return "study"
		MonthSchedule.ActivityPeriod.WORK:
			return "work"
		MonthSchedule.ActivityPeriod.MISSION:
			return "mission"
		MonthSchedule.ActivityPeriod.LEISURE:
			return "leisure"
	return ""


func _update_affordability() -> void:
	if _simulation == null:
		return
	var balance: int = _simulation.economy.get_credits()
	for period_index: int in PERIOD_COUNT:
		var selection: Dictionary = _schedule.get_selection(period_index)
		if not _schedule.has_selection(period_index):
			continue
		var cost: int = int(selection.get("cost", 0))
		var can_afford: bool = true
		if period_index >= _first_editable_period:
			can_afford = balance >= cost
		selection["can_afford"] = can_afford
		selection["reason"] = "" if can_afford else "blocked"
		_schedule.selections[period_index] = selection
		if can_afford and period_index >= _first_editable_period:
			balance -= cost
			balance += int(selection.get("income", 0))
	_schedule.is_complete = _schedule.is_month_selected()


func _refresh() -> void:
	if _schedule == null:
		return
	var credits: int = _simulation.economy.get_credits() if _simulation != null else 0
	_credits_label.text = Localization.format("ui.creditos_format", {"value": credits})
	for period_index: int in PERIOD_COUNT:
		var selection: Dictionary = _schedule.get_selection(period_index)
		var date_label: String = _period_date_label(period_index + 1)
		var chosen_name: String = _selection_name(selection)
		_period_buttons[period_index].text = (
			date_label if chosen_name.is_empty() else date_label + "\n" + chosen_name
		)
		_period_buttons[period_index].button_pressed = period_index == _active_period
		_period_buttons[period_index].disabled = (
			_recovery_blocked or period_index < _first_editable_period
		)
		_period_buttons[period_index].tooltip_text = _period_buttons[period_index].text
	_update_category_tabs()
	_refresh_activity_list()
	_update_footer()


func _period_date_label(period_index: int) -> String:
	var weekdays: Array[String] = Localization.get_string_array("calendar.weekdays")
	if weekdays.size() < period_index:
		return Localization.text("ui.indisponivel")
	return Localization.format(
		"ui.periodo_format",
		{
			"weekday": weekdays[period_index - 1],
			"day": 1 + (period_index - 1) * 10,
			"period": period_index
		}
	)


func _selection_name(selection: Dictionary) -> String:
	if int(selection.get("activity_type", MonthSchedule.ActivityPeriod.NONE)) == MonthSchedule.ActivityPeriod.NONE:
		return ""
	var category: String = _category_from_period(int(selection["activity_type"]))
	for choice: Dictionary in _choices_by_category.get(category, []):
		if str(choice.get("id", "")) == str(selection.get("activity_id", "")):
			return str(choice.get("display_name", ""))
	return ""


func _update_category_tabs() -> void:
	for category: String in CATEGORY_IDS:
		var tab: Button = _category_buttons[category]
		var choices: Array = _choices_by_category.get(category, [])
		var label: String = ""
		for choice: Dictionary in choices:
			label = str(choice.get("category_label", ""))
			if not label.is_empty():
				break
		tab.text = label if not label.is_empty() else Localization.text("ui.indisponivel")
		tab.button_pressed = category == _active_category
		tab.tooltip_text = tab.text
		tab.disabled = _recovery_blocked


func _refresh_activity_list() -> void:
	if _selection_host == null:
		return
	var choices: Array[Dictionary] = []
	var available_credits: int = _credits_available_for_active_period()
	for choice: Dictionary in _choices_by_category.get(_active_category, []):
		var current_choice: Dictionary = choice.duplicate(true)
		current_choice["available_credits"] = available_credits
		if _active_category != "mission" and not current_choice.has("error"):
			current_choice["can_afford"] = available_credits >= int(current_choice.get("cost", 0))
			current_choice["reason"] = (
				"" if bool(current_choice["can_afford"]) else "insufficient_credits"
			)
		choices.append(current_choice)
	var category_label: String = str(_category_buttons[_active_category].text)
	_selection_host.show_activity_selection(
		choices,
		available_credits,
		_active_period,
		category_label,
		not _recovery_blocked
	)


func _credits_available_for_active_period() -> int:
	var balance: int = _simulation.economy.get_credits() if _simulation != null else 0
	for period_index: int in range(_first_editable_period, _active_period):
		var selection: Dictionary = _schedule.get_selection(period_index)
		if not _schedule.has_selection(period_index):
			continue
		balance -= int(selection.get("cost", 0))
		balance += int(selection.get("income", 0))
	return maxi(balance, 0)


func _update_footer() -> void:
	_update_affordability()
	var valid: bool = _schedule.is_month_selected()
	if valid:
		for selection: Dictionary in _schedule.selections:
			if not bool(selection.get("can_afford", false)):
				valid = false
				break
	_confirm_button.disabled = not valid
	_repeat_button.visible = _previous_schedule != null and _first_editable_period == 0
	_repeat_button.disabled = _recovery_blocked
	_cancel_button.disabled = not _cancel_allowed or _recovery_blocked
	if _recovery_blocked:
		_confirm_button.disabled = true
		_status_label.text = Localization.text("ui.indisponivel")
	elif _status_label.text.is_empty() and not valid:
		_status_label.text = Localization.text("ui.indisponivel")


func _on_repeat_pressed() -> void:
	if _recovery_blocked or _previous_schedule == null:
		return
	_schedule = _previous_schedule.duplicate_schedule()
	_active_period = 0
	_update_affordability()
	_status_label.text = ""
	_refresh()


func _on_confirm_pressed() -> void:
	if _recovery_blocked:
		return
	_update_affordability()
	if not _confirm_button.disabled:
		schedule_confirmed.emit(_schedule.duplicate_schedule())


func _on_cancel_pressed() -> void:
	if _cancel_allowed and not _recovery_blocked:
		schedule_cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
	if (
		visible
		and _cancel_allowed
		and not _recovery_blocked
		and event.is_action_pressed("ui_cancel")
	):
		schedule_cancelled.emit()
		get_viewport().set_input_as_handled()
