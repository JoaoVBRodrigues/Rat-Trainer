extends Control
class_name CharacterCard

# Character card displaying name, age, credits, and status panel
# Uses Assets.get_texture for all visual elements

signal status_requested  # Emitted when Status button clicked

@export_multiline var character_name: String = "Nyx"
@export var icon_size: int = 48

# Cached asset references
var _texture_loader: AssetResolver = null

# Node references
@onready var _name_label: Label = $"NameLabel"
@onready var _age_label: Label = $"AgeLabel"
@onready var _credits_label: Label = $"CreditsLabel"
@onready var _character_icon: TextureRect = $"Icon"
@onready var _status_button: Button = $"StatusButton"
@onready var _inventory_button: Button = $"InventoryButton"
@onready var _stats_panel: StatsPanel = $"StatsPanel"


func _ready() -> void:
    _texture_loader = Assets
    _setup_event_listeners()
    _update_display()


func _setup_event_listeners() -> void:
    if _status_button != null:
        _status_button.pressed.connect(_on_status_button_pressed)
    if _inventory_button != null:
        _inventory_button.pressed.connect(_on_inventory_button_pressed)


func update_from_simulator(sim: SimulationCore) -> void:
    if sim == null:
        return
    character_name = "Nyx"  # Default name
    _age_label.text = str(sim.calendar.age) + " anos"
    _credits_label.text = str(sim.economy.credits) + " Cr"
    _stats_panel.update_from_simulator(sim)
    _update_character_visual()


func _update_character_visual() -> void:
    if _character_icon != null and _texture_loader != null:
        _character_icon.texture = _texture_loader.get_texture(&"char_rat_idle", &"characters")


func _update_display() -> void:
    if _name_label != null:
        _name_label.text = character_name
    if _age_label != null:
        _age_label.text = "12 anos"  # Default, updated from simulator
    if _credits_label != null:
        _credits_label.text = "200 Cr"  # Starting credits


func refresh_credits(credits: int) -> void:
    if _credits_label != null:
        _credits_label.text = str(credits) + " Cr"


func _on_status_button_pressed() -> void:
    emit_signal("status_requested")


func _on_inventory_button_pressed() -> void:
    # TODO: Implement inventory system
    pass