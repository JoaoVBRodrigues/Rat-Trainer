extends Control
class_name ActivityResult

# Result screen showing gains/losses, contextual scene/illustration
# Displays credit changes, stat changes, reputation gains

signal continue_pressed

@export var show_detailed: bool = true

# Node references
@onready var _title_label: Label = $"Header/TitleLabel"
@onready var _result_icon: TextureRect = $"ResultIcon"
@onready var _summary_label: Label = $"Summary/SummaryLabel"
@onready var _changes_container: VBoxContainer = $"ChangesContainer"
@onready var _continue_button: Button = $"Footer/ContinueButton"


func _ready() -> void:
    _setup_event_listeners()


func _setup_event_listeners() -> void:
    if _continue_button != null:
        _continue_button.pressed.connect(_on_continue_pressed)


func display_result(result: Dictionary) -> void:
    # Display the result of an activity
    # result should contain: credits_change, stat_changes, rep_gained, stress_change
    if _title_label != null:
        _title_label.text = _get_result_title(result)
    if _result_icon != null:
        _result_icon.texture = _get_result_icon(result)
    if _summary_label != null:
        _summary_label.text = _get_result_summary(result)
    _build_changes_list(result)


func _get_result_title(result: Dictionary) -> String:
    # Determine title based on success/failure
    if result.get("mission_success", false):
        return "Missão Concluída!"
    if result.get("completed", true):
        return "Atividade Concluída"
    return "Falha"


func _get_result_icon(result: Dictionary) -> Texture2D:
    # Return appropriate icon based on result
    return Assets.get_texture(&"icon_success", &"ui")


func _get_result_summary(result: Dictionary) -> String:
    # Generate summary text
    if result.get("mission_success", false):
        return "A missão foi bem-sucedida!"
    if result.get("completed", true):
        return "Atividade concluída com sucesso."
    return "A atividade não foi concluída."


func _build_changes_list(result: Dictionary) -> void:
    # Build the list of stat/credit changes
    if _changes_container == null:
        return
    _changes_container.clear()

    # Credits change
    var credits_delta: int = result.get("credits_change", 0)
    if credits_delta != 0:
        _add_change_row("Créditos", credits_delta)

    # Stat changes
    var stat_changes: Dictionary = result.get("stat_changes", {})
    for stat_id in stat_changes:
        _add_change_row(STAT_NAMES.get(stat_id, stat_id), int(stat_changes[stat_id]))

    # Reputation gains
    var rep_gained: Dictionary = result.get("rep_gained", {})
    for rep_id in rep_gained:
        _add_change_row(REP_NAMES.get(rep_id, rep_id), int(rep_gained[rep_id]))


func _add_change_row(label: String, delta: int) -> void:
    var hbox: HBoxContainer = HBoxContainer.new()

    var name: Label = Label.new()
    name.text = label
    name.custom_fonts/font = null

    var change: Label = Label.new()
    change.text = _format_delta(delta)
    change.custom_colors/font_color = Color(0.45, 0.85, 0.45, 1) if delta > 0 else Color(0.94, 0.4, 0.4, 1)

    hbox.add_child(name)
    hbox.add_child(change)
    _changes_container.add_child(hbox)


func _format_delta(delta: int) -> String:
    if delta > 0:
        return "+" + str(delta)
    if delta < 0:
        return str(delta)
    return "0"


func _on_continue_pressed() -> void:
    emit_signal("continue_pressed")


# Constants
const STAT_NAMES: Dictionary = {
    "str": "Força",
    "int": "Inteligência",
    "cha": "Carisma",
    "ref": "Refinamento",
    "sta": "Resistência",
    "eth": "Ética"
}

const REP_NAMES: Dictionary = {
    "fighter": "Lutador",
    "social": "Social",
    "hacker": "Hacker"
}