extends Control
class_name MenuGrid

# Icon grid menu with 8 buttons: Agenda, Profile, City, Equipment, Talk, Mission, Rest, Options
# Supports mouse and keyboard/gamepad navigation with focus

enum MenuId { AGENDA, PROFILE, CITY, EQUIPMENT, TALK, MISSION, REST, OPTIONS }

const MENU_LABELS: Dictionary = {
    MenuId.AGENDA: "Agenda",
    MenuId.PROFILE: "Perfil",
    MenuId.CITY: "Cidade",
    MenuId.EQUIPMENT: "Equipamento",
    MenuId.TALK: "Falar",
    MenuId.MISSION: "Missão",
    MenuId.REST: "Descanso",
    MenuId.OPTIONS: "Opções"
}

const ICON_IDS: Dictionary = {
    MenuId.AGENDA: "icon_agenda",
    MenuId.PROFILE: "icon_profile",
    MenuId.CITY: "icon_city",
    MenuId.EQUIPMENT: "icon_equipment",
    MenuId.TALK: "icon_talk",
    MenuId.MISSION: "icon_mission",
    MenuId.REST: "icon_rest",
    MenuId.OPTIONS: "icon_options"
}

signal menu_item_selected(id: int)

# Node references
@onready var _button_grid: GridContainer = $"ButtonGrid"
@onready var _schedule_button: Button = $"ScheduleButton"

var _current_focused: int = MenuId.AGENDA


func _ready() -> void:
    _build_menu()
    _setup_navigation()
    if _schedule_button != null:
        _schedule_button.grab_focus()


func _build_menu() -> void:
    if _button_grid == null:
        return
    for i in range(MenuId.size()):
        var button: Button = _create_menu_button(i)
        _button_grid.add_child(button)


func _create_menu_button(id: int) -> Button:
    var button: Button = Button.new()
    button.name = "MenuButton" + str(id)
    button.focus_mode = Control.FOCUS_ALL
    var icon: TextureRect = TextureRect.new()
    icon.name = "Icon"
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

    var label: Label = Label.new()
    label.name = "Label"
    label.text = MENU_LABELS.get(id, "???")

    button.add_child(icon)
    button.add_child(label)
    button.pressed.connect(_on_button_pressed.bind(id))

    return button


func _setup_navigation() -> void:
    # Keyboard navigation
    pass


func _on_button_pressed(id: int) -> void:
    emit_signal("menu_item_selected", id)


func focus_next(direction: int = 1) -> void:
    _current_focused = posmod(_current_focused + direction, MenuId.size())
    _update_focus_visual()


func _update_focus_visual() -> void:
    # Update visual focus state
    pass


func enable_button(id: int, enabled: bool, reason: String = "") -> void:
    var button: Button = _button_grid.get_child(id) as Button
    if button != null:
        button.disabled = not enabled
        if not enabled and reason != "":
            button.tooltip_text = reason


func get_enabled_buttons() -> Array[bool]:
    var result: Array[bool] = []
    for i in range(MenuId.size()):
        var button: Button = _button_grid.get_child(i) as Button
        result.append(button != null and not button.disabled)
    return result


func refresh_availability(sim: SimulationCore) -> void:
    # Update button states based on simulation state
    # Mission button disabled when diseased
    if sim != null and sim.is_mission_available() == false:
        enable_button(MenuId.MISSION, false, "Missões indisponíveis (doença)")
    else:
        enable_button(MenuId.MISSION, true, "")