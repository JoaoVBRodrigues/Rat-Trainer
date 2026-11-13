extends Control
class_name ProfileScreen

# Profile screen with expanded character info and full stats panel

signal closed
signal credits_changed

# Node references
@onready var _background_overlay: ColorRect = $BackgroundOverlay
@onready var _profile_window: PanelContainer = $ProfileWindow
@onready var _character_image: TextureRect = $VBoxContainer/CharacterInfo/VisualContainer/CharacterImage
@onready var _name_label: Label = $VBoxContainer/CharacterInfo/NameLabel
@onready var _age_label: Label = $VBoxContainer/CharacterInfo/AgeLabel
@onready var _credits_label: Label = $VBoxContainer/CharacterInfo/CreditsLabel
@onready var _stats_panel: StatsPanel = $VBoxContainer/StatsPanel


func _ready() -> void:
    _setup_event_listeners()


func _setup_event_listeners() -> void:
    if _background_overlay != null:
        _background_overlaygui_input = _on_background_gui_input


func _on_background_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        close()


func show_profile(sim: SimulationCore) -> void:
    visible = true
    if sim == null:
        return
    _name_label.text = "Nyx"
    _age_label.text = str(sim.calendar.age) + " anos"
    _credits_label.text = str(sim.economy.credits) + " Cr"
    if _character_image != null:
        _character_image.texture = Assets.get_texture(&"char_rat_idle", &"characters")
    _stats_panel.update_from_simulator(sim)


func close() -> void:
    visible = false
    emit_signal("closed")


func update_credits(credits: int) -> void:
    if _credits_label != null:
        _credits_label.text = str(credits) + " Cr"
    emit_signal("credits_changed", credits)