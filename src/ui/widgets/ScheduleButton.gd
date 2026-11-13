extends Button
class_name ScheduleButton

# Primary SCHEDULE button that opens activity selection or event choices
# Large prominent button for primary game action

signal schedule_requested

@export var show_event_indicator: bool = true

# Node references
@onready var _icon: TextureRect = $"Icon"
@onready var _label: Label = $"Label"


func _ready() -> void:
    _setup_button()


func _setup_button() -> void:
    focus_mode = Control.FOCUS_ALL
    if _label != null:
        _label.text = "AGENDAR"
    if _icon != null:
        _icon.texture = Assets.get_texture(&"icon_schedule", &"ui")


func set_has_event(has_event: bool) -> void:
    # Visual indicator for current period event
    pass


func set_action_available(available: bool, reason: String = "") -> void:
    disabled = not available
    if not available and reason != "":
        tooltip_text = reason


func get_action_text() -> String:
    # Returns the action description based on current game state
    return "Selecionar atividade"


func _pressed() -> void:
    emit_signal("schedule_requested")