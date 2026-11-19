extends Control
class_name MainScreen

signal schedule_requested(source: String)
signal destination_requested(destination: String)
signal return_to_title_requested
signal save_requested

const THEME_PATH: String = "res://src/ui/UITheme.tres"
const CHARACTER_ASSET: StringName = &"char_rat_idle"
const BACKGROUND_ASSET: StringName = &"bg_bedroom_day"
const MENU_IDS: Array[String] = [
	"agenda", "perfil", "cidade", "equipamento", "falar", "missao"
]
const MENU_ICON_IDS: Array[StringName] = [
	&"icon_agenda", &"icon_profile", &"icon_city", &"icon_equipment",
	&"icon_talk", &"icon_mission"
]
const MONTHS_KEY: String = "calendar.months"
const WEEKDAYS_KEY: String = "calendar.weekdays"

var simulation: SimulationCore
var _profile: Dictionary = {}
var _assets: AssetResolver
var _calendar_panel: PanelContainer
var _year_label: Label
var _period_label: Label
var _progress_label: Label
var _name_label: Label
var _age_label: Label
var _credits_label: Label
var _status_button: Button
var _new_campaign_button: Button
var _schedule_button: Button
var _save_button: Button
var _menu_buttons: Array[Button] = []
var _status_panel: StatusPanel
var _schedule_flow: MonthlyScheduleFlow
var _item_management_screen: ItemManagementScreen
var _game_manager: GameManager
var _profile_screen: ProfileScreen
var _talk_screen: TalkScreen


func _ready() -> void:
	_build_screen()
	_schedule_flow = MonthlyScheduleFlow.new()
	_schedule_flow.name = "MonthlyScheduleFlow"
	add_child(_schedule_flow)
	_schedule_flow.bind_main_screen(self)
	_schedule_flow.set_data_manager(get_node_or_null("/root/Data") as DataManager)
	schedule_requested.connect(_schedule_flow.on_schedule_requested)
	_game_manager = get_node_or_null("/root/Game") as GameManager
	if _game_manager == null:
		push_error("GameManager autoload is unavailable; a campaign cannot be started.")
	else:
		_game_manager.game_started.connect(_on_game_started)
	update_simulation(simulation)
	if simulation == null and _new_campaign_button != null:
		_new_campaign_button.grab_focus()


func update_simulation(sim: SimulationCore, profile: Dictionary = {}) -> void:
	simulation = sim
	if _schedule_flow != null:
		_schedule_flow.update_simulation(sim)
	if _item_management_screen != null:
		_item_management_screen.update_simulation(sim)
	_profile = profile.duplicate(true)
	if _profile.is_empty():
		var data_manager: DataManager = get_node_or_null("/root/Data") as DataManager
		if data_manager != null:
			var save_data: Dictionary = data_manager.get_current_data()
			var saved_character: Variant = save_data.get("character", {})
			if saved_character is Dictionary:
				_profile = saved_character.duplicate(true)

	if not is_node_ready():
		return

	_update_calendar()
	_update_character_card()
	_update_status()
	_update_availability()
	_refresh_character_art()


func _refresh_character_art() -> void:
	var character: TextureRect = get_node_or_null("CharacterVisual") as TextureRect
	if character != null:
		character.texture = _assets.get_texture(ArtPresentation.character_id(simulation), &"characters")


func resume_saved_flow() -> void:
	if _schedule_flow == null:
		push_error("Cannot resume a campaign before the schedule flow is ready.")
		return
	var data_manager: DataManager = get_node_or_null("/root/Data") as DataManager
	if data_manager == null:
		push_error("Cannot resume a saved schedule because DataManager is unavailable.")
		return
	_schedule_flow.resume_saved_flow(data_manager.get_flow_state())


func refresh_credits() -> void:
	_update_character_card()
	_update_status()
	_update_availability()
	_refresh_character_art()


func get_menu_button_count() -> int:
	return _menu_buttons.size()


func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shared_theme: Theme = load(THEME_PATH) as Theme
	if shared_theme == null:
		push_error("Could not load UI theme: %s." % THEME_PATH)
		return
	_assets = get_node_or_null("/root/Assets") as AssetResolver
	if _assets == null:
		_assets = AssetResolver.new()
		_assets.name = "LocalAssetResolver"
		add_child(_assets)
	theme = shared_theme
	if not UIThemeResource.apply_runtime_assets(shared_theme, _assets):
		return

	_build_background()
	_build_character_visual()
	_build_calendar()
	var title_button: Button = Button.new()
	title_button.name = "TitleButton"
	title_button.text = Localization.text("ui.menu_principal")
	title_button.position = Vector2(16, 156)
	title_button.size = Vector2(180, 44)
	title_button.pressed.connect(func() -> void: return_to_title_requested.emit())
	add_child(title_button)
	_build_character_card()
	_build_status_panel()
	_build_menu()
	_build_schedule_button()
	_build_save_button()
	_build_item_management_screen()
	_configure_focus_navigation()


func _build_item_management_screen() -> void:
	_item_management_screen = ItemManagementScreen.new()
	_item_management_screen.name = "ItemManagementScreen"
	_item_management_screen.set_asset_resolver(_assets)
	_item_management_screen.visible = false
	_item_management_screen.closed.connect(_on_item_management_screen_closed)
	_item_management_screen.credits_changed.connect(refresh_credits)
	add_child(_item_management_screen)


func _build_background() -> void:
	var background: TextureRect = TextureRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = _assets.get_texture(BACKGROUND_ASSET, &"backgrounds")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)


func _build_character_visual() -> void:
	var character: TextureRect = TextureRect.new()
	character.name = "CharacterVisual"
	character.position = Vector2(230.0, 84.0)
	character.size = Vector2(420.0, 470.0)
	character.texture = _assets.get_texture(CHARACTER_ASSET, &"characters")
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character.z_index = -1
	add_child(character)


func _build_calendar() -> void:
	_calendar_panel = _create_panel("CalendarPanel", Vector2(16.0, 16.0), Vector2(334.0, 132.0))
	var content: VBoxContainer = _add_panel_content(_calendar_panel)
	_year_label = _add_label(content, "CalendarYear", "", 18)
	_period_label = _add_label(content, "CalendarPeriod", "", 16)
	_progress_label = _add_label(content, "CalendarProgress", "", 14)


func _build_character_card() -> void:
	var card: PanelContainer = _create_panel(
		"CharacterCard", Vector2(684.0, 16.0), Vector2(324.0, 176.0)
	)
	var content: VBoxContainer = _add_panel_content(card)
	_name_label = _add_label(content, "CharacterName", "", 20)
	_age_label = _add_label(content, "CharacterAge", "", 16)
	_credits_label = _add_label(content, "CharacterCredits", "", 16)

	_status_button = Button.new()
	_status_button.name = "StatusToggle"
	_status_button.text = Localization.text("ui.status")
	_status_button.custom_minimum_size = Vector2(0.0, 42.0)
	_status_button.focus_mode = Control.FOCUS_ALL
	_status_button.pressed.connect(_on_status_toggle_pressed)
	content.add_child(_status_button)

	_new_campaign_button = Button.new()
	_new_campaign_button.name = "NewCampaignButton"
	_new_campaign_button.text = Localization.text("ui.nova_campanha")
	_new_campaign_button.custom_minimum_size = Vector2(0.0, 42.0)
	_new_campaign_button.focus_mode = Control.FOCUS_ALL
	_new_campaign_button.pressed.connect(_on_new_campaign_pressed)
	content.add_child(_new_campaign_button)


func _build_status_panel() -> void:
	_status_panel = StatusPanel.new()
	_status_panel.name = "StatusPanel"
	_status_panel.position = Vector2(684.0, 204.0)
	_status_panel.size = Vector2(324.0, 390.0)
	_status_panel.custom_minimum_size = Vector2(324.0, 390.0)
	add_child(_status_panel)
	_status_panel.set_expanded(false)


func _build_menu() -> void:
	var menu_panel: PanelContainer = _create_panel(
		"MenuPanel", Vector2(16.0, 556.0), Vector2(650.0, 196.0)
	)
	var grid: GridContainer = GridContainer.new()
	grid.name = "MenuGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_add_panel_content(menu_panel).add_child(grid)

	for index: int in MENU_IDS.size():
		var destination: String = MENU_IDS[index]
		var button: Button = _make_menu_button(destination, MENU_ICON_IDS[index])
		grid.add_child(button)
		_menu_buttons.append(button)


func _make_menu_button(destination: String, icon_id: StringName) -> Button:
	var button: Button = Button.new()
	button.name = "Menu_%s" % destination
	button.custom_minimum_size = Vector2(198.0, 80.0)
	button.focus_mode = Control.FOCUS_ALL
	button.tooltip_text = Localization.text("ui.tooltip.%s" % destination)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8.0
	row.offset_top = 6.0
	row.offset_right = -8.0
	row.offset_bottom = -6.0

	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(40.0, 40.0)
	icon.texture = _assets.get_texture(icon_id, &"icons")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var label: Label = Label.new()
	label.name = "Label"
	label.text = Localization.text("ui.%s" % destination)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 100.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	button.pressed.connect(_on_menu_pressed.bind(destination))
	return button


func _build_schedule_button() -> void:
	_schedule_button = Button.new()
	_schedule_button.name = "ScheduleButton"
	_schedule_button.position = Vector2(684.0, 670.0)
	_schedule_button.size = Vector2(324.0, 82.0)
	_schedule_button.custom_minimum_size = Vector2(0.0, 54.0)
	_schedule_button.text = Localization.text("ui.agendar")
	_schedule_button.focus_mode = Control.FOCUS_ALL
	_schedule_button.pressed.connect(_on_schedule_pressed)
	add_child(_schedule_button)


func _build_save_button() -> void:
	_save_button = Button.new()
	_save_button.name = "SaveButton"
	_save_button.position = Vector2(684.0, 612.0)
	_save_button.size = Vector2(324.0, 44.0)
	_save_button.text = Localization.text("ui.salvar_campanha")
	_save_button.focus_mode = Control.FOCUS_ALL
	_save_button.pressed.connect(func() -> void: save_requested.emit())
	add_child(_save_button)


func _configure_focus_navigation() -> void:
	if _status_button == null or _schedule_button == null or _menu_buttons.size() != 6:
		return
	for index: int in _menu_buttons.size():
		var button: Button = _menu_buttons[index]
		var column: int = index % 3
		var row: int = index / 3
		var left_index: int = index - 1 if column > 0 else index
		var right_index: int = index + 1 if column < 2 else index
		var top_index: int = index - 3 if row > 0 else -1
		var bottom_index: int = index + 3 if row == 0 else -1
		button.focus_neighbor_left = (
			_menu_buttons[left_index].get_path()
			if column > 0
			else _status_button.get_path()
		)
		button.focus_neighbor_right = (
			_menu_buttons[right_index].get_path()
			if column < 2
			else _schedule_button.get_path()
		)
		button.focus_neighbor_top = (
			_menu_buttons[top_index].get_path()
			if top_index >= 0
			else _status_button.get_path()
		)
		button.focus_neighbor_bottom = (
			_menu_buttons[bottom_index].get_path()
			if bottom_index >= 0
			else _schedule_button.get_path()
		)

	_status_button.focus_neighbor_bottom = _menu_buttons[0].get_path()
	_status_button.focus_neighbor_right = _menu_buttons[0].get_path()
	_schedule_button.focus_neighbor_top = _menu_buttons[5].get_path()
	_schedule_button.focus_neighbor_left = _menu_buttons[5].get_path()


func _create_panel(panel_name: String, panel_position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = panel_name
	panel.position = panel_position
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(panel)
	return panel


func _add_panel_content(panel: PanelContainer) -> VBoxContainer:
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)
	return content


func _add_label(parent: Node, label_name: String, text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label


func _update_calendar() -> void:
	if _year_label == null:
		return
	if simulation == null:
		_year_label.text = Localization.text("ui.indisponivel")
		_period_label.text = Localization.text("ui.indisponivel")
		_progress_label.text = Localization.text("ui.sem_campanha")
		return

	var months: Array[String] = Localization.get_string_array(MONTHS_KEY)
	var weekdays: Array[String] = Localization.get_string_array(WEEKDAYS_KEY)
	var month_index: int = simulation.calendar.month - 1
	var period_index: int = simulation.calendar.period - 1
	if month_index < 0 or month_index >= months.size():
		push_error("Calendar month is outside the localized month table.")
		_year_label.text = Localization.text("ui.indisponivel")
		return
	if period_index < 0 or period_index >= weekdays.size():
		push_error("Calendar period is outside the localized weekday table.")
		_year_label.text = Localization.text("ui.indisponivel")
		return

	_year_label.text = Localization.format(
		"ui.data_format",
		{"year": simulation.calendar.year, "month": months[month_index]}
	)
	_period_label.text = Localization.format(
		"ui.periodo_format",
		{
			"weekday": weekdays[period_index],
			"day": simulation.calendar.get_day_of_month(),
			"period": simulation.calendar.period
		}
	)
	_progress_label.text = Localization.format(
		"ui.periodos_concluidos_format",
		{
			"completed": simulation.calendar.completed_periods,
			"total": simulation.calendar.total_periods
		}
	)


func _update_character_card() -> void:
	if _name_label == null:
		return
	var has_campaign: bool = simulation != null
	if _save_button != null:
		_save_button.visible = has_campaign
		_save_button.disabled = not has_campaign
	_age_label.visible = has_campaign
	_credits_label.visible = has_campaign
	_status_button.visible = has_campaign
	_new_campaign_button.visible = not has_campaign
	if simulation == null:
		_name_label.text = Localization.text("ui.sem_campanha")
		_age_label.text = Localization.text("ui.indisponivel")
		_credits_label.text = Localization.text("ui.indisponivel")
		return

	var saved_name: Variant = _profile.get("name")
	var character_name: String = (
		str(saved_name) if saved_name is String and not str(saved_name).strip_edges().is_empty()
		else Localization.text("ui.indisponivel")
	)
	_name_label.text = character_name
	_age_label.text = Localization.format("ui.idade_format", {"value": simulation.get_age()})
	_credits_label.text = Localization.format(
		"ui.creditos_format", {"value": simulation.economy.get_credits()}
	)


func _update_status() -> void:
	if _status_panel != null:
		_status_panel.update_from_simulation(simulation)


func _update_availability() -> void:
	var has_campaign: bool = simulation != null
	var can_plan_month: bool = (
		has_campaign and not simulation.is_campaign_complete() and simulation.calendar.period == 1
	)
	for index: int in _menu_buttons.size():
		var button: Button = _menu_buttons[index]
		button.disabled = not has_campaign
		if MENU_IDS[index] == "agenda":
			button.disabled = not can_plan_month
		elif MENU_IDS[index] == "missao":
			button.disabled = (
				not can_plan_month or not has_campaign or not simulation.is_mission_available()
			)
	_schedule_button.disabled = not can_plan_month


func _on_status_toggle_pressed() -> void:
	if _status_panel == null:
		return
	_status_panel.toggle_expanded()
	_update_status_toggle_text()


func _update_status_toggle_text() -> void:
	if _status_button == null or _status_panel == null:
		return
	_status_button.text = (
		Localization.text("ui.fechar")
		if _status_panel.expanded
		else Localization.text("ui.status")
	)


func _on_schedule_pressed() -> void:
	schedule_requested.emit("primary")


func _on_new_campaign_pressed() -> void:
	if _game_manager == null:
		push_error("Cannot start a campaign because GameManager is unavailable.")
		return
	_game_manager.start_new_game()


func _on_game_started() -> void:
	if _game_manager == null or _game_manager.simulation == null:
		push_error("GameManager reported a started campaign without a simulation.")
		return
	update_simulation(_game_manager.simulation)
	if not _schedule_button.disabled:
		_schedule_button.grab_focus()


func _on_menu_pressed(destination: String) -> void:
	if simulation == null:
		return
	if destination == "perfil":
		if _profile_screen == null:
			_profile_screen = ProfileScreen.new()
			_profile_screen.name = "ProfileScreen"
			_profile_screen.closed.connect(func() -> void: _menu_buttons[1].grab_focus())
			add_child(_profile_screen)
		_profile_screen.move_to_front()
		_profile_screen.show_profile(simulation, _profile)
		return
	if destination == "falar":
		if _talk_screen == null:
			_talk_screen = TalkScreen.new()
			_talk_screen.name = "TalkScreen"
			_talk_screen.closed.connect(func() -> void: _menu_buttons[4].grab_focus())
			add_child(_talk_screen)
		_talk_screen.move_to_front()
		_talk_screen.open_conversation(simulation, _profile)
		return
	if destination == "agenda":
		schedule_requested.emit("agenda")
		return
	if destination == "missao":
		schedule_requested.emit("mission")
		return
	if destination == "cidade":
		_item_management_screen.open("shops", simulation)
		return
	if destination == "equipamento":
		_item_management_screen.open("equipment", simulation)
		return
	destination_requested.emit(destination)


func _on_item_management_screen_closed() -> void:
	refresh_credits()
	var menu_index: int = MENU_IDS.find(
		"cidade" if _item_management_screen._mode == "shops" else "equipamento"
	)
	if menu_index >= 0 and menu_index < _menu_buttons.size():
		_menu_buttons[menu_index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or _status_panel == null:
		return
	if not _status_panel.expanded:
		return
	_status_panel.set_expanded(false)
	_update_status_toggle_text()
	_status_button.grab_focus()
	get_viewport().set_input_as_handled()
