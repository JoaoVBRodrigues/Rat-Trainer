extends Control
class_name ActivitySelection

# Activity selection screen showing category, activity, cost, gains, stress
# Shows before confirming a period choice

signal activity_selected(choice: String)
signal activity_cancelled

@export var show_detailed: bool = true

# Activity type configuration
const ACTIVITY_TYPES: Array[String] = ["study", "work", "mission", "leisure"]

# Node references
@onready var _categories_container: VBoxContainer = $"CategoriesContainer"
@onready var _close_button: Button = $"Header/CloseButton"


func _ready() -> void:
    _build_category_headers()
    _connect_events()


func _connect_events() -> void:
    if _close_button != null:
        _close_button.pressed.connect(_on_close_pressed)


func update_available_activities(available: Dictionary) -> void:
    # Update with available activities from simulation
    # available = { study: [], work: [], mission: [], leisure: [] }
    pass


func _build_category_headers() -> void:
    # Create headers for each activity category
    pass


func _on_close_pressed() -> void:
    emit_signal("activity_cancelled")