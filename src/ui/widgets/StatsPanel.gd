extends Control
class_name StatsPanel

# Status panel with 4 blocks: Attributes, Combat, Reputation, Skills
# Displays values with progress bars, reads from CharacterState

@export var show_detailed: bool = false  # Expanded view with numeric labels

# Stat display configuration
const STAT_IDS: Array[String] = ["str", "int", "cha", "ref", "sta", "eth"]
const STAT_NAMES: Dictionary = {
    "str": "Força",
    "int": "Inteligência",
    "cha": "Carisma",
    "ref": "Refinamento",
    "sta": "Resistência",
    "eth": "Ética"
}

# Node references - to be connected in scene
@onready var _attributes_container: VBoxContainer = $"AttributesContainer"
@onready var _combat_panel: HBoxContainer = $"CombatPanel"
@onready var _reputation_panel: HBoxContainer = $"ReputationPanel"
@onready var _skills_panel: HBoxContainer = $"SkillsPanel"
@onready var _stress_bar: ProgressBar = $"StressDisplay/StressBar"


func _ready() -> void:
    setup_layout()


func setup_layout() -> void:
    _create_attributes_section()
    _create_combat_section()
    _create_reputation_section()
    _create_skills_section()


func update_from_simulator(sim: SimulationCore) -> void:
    if sim == null:
        return
    _update_attributes(sim)
    _update_combat(sim)
    _update_reputation(sim)
    _update_skills(sim)
    _update_stress(sim)


func _update_attributes(sim: SimulationCore) -> void:
    for stat_id in STAT_IDS:
        var value: int = sim.stats.get_stat(stat_id)
        var bar: ProgressBar = _attributes_container.get_node_or_null(stat_id + "Bar")
        var label: Label = _attributes_container.get_node_or_null(stat_id + "Label")
        if bar != null:
            bar.value = value
        if label != null:
            label.text = str(value)


func _update_combat(sim: SimulationCore) -> void:
    # Combat base chance - from mission difficulty
    var chance_label: Label = _combat_panel.get_node_or_null("ChanceLabel")
    var bonus_label: Label = _combat_panel.get_node_or_null("BonusLabel")
    if chance_label != null:
        chance_label.text = "95%"  # Base mission chance (placeholder)
    if bonus_label != null:
        bonus_label.text = "+0 Equipamento"


func _update_reputation(sim: SimulationCore) -> void:
    var fighter_label: Label = _reputation_panel.get_node_or_null("FighterLabel")
    var social_label: Label = _reputation_panel.get_node_or_null("SocialLabel")
    var hacker_label: Label = _reputation_panel.get_node_or_null("HackerLabel")

    if fighter_label != null:
        fighter_label.text = str(sim.stats.get_reputation("fighter"))
    if social_label != null:
        social_label.text = str(sim.stats.get_reputation("social"))
    if hacker_label != null:
        hacker_label.text = str(sim.stats.get_reputation("hacker"))


func _update_skills(sim: SimulationCore) -> void:
    # Display course levels and streaks
    pass  # To be implemented when skill tracking is available


func _update_stress(sim: SimulationCore) -> void:
    if _stress_bar != null:
        _stress_bar.value = sim.stats.stress
        _stress_bar.modulate = _get_stress_color(sim.stats.stress)


func _get_stress_color(stress: int) -> Color:
    if stress < 30:
        return Color(0.45, 0.85, 0.45)  # Green
    if stress < 60:
        return Color(0.93, 0.65, 0.43)  # Orange
    return Color(0.94, 0.4, 0.4)  # Red


func _create_attributes_section() -> void:
    # Create stat bars dynamically
    if _attributes_container == null:
        return
    for stat_id in STAT_IDS:
        var hbox: HBoxContainer = HBoxContainer.new()
        hbox.name = stat_id + "Container"

        var icon: TextureRect = TextureRect.new()
        icon.name = stat_id + "Icon"
        icon.texture = Assets.get_texture("icon_stat_" + stat_id, &"icons")
        icon.expand = true
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

        var bar: ProgressBar = ProgressBar.new()
        bar.name = stat_id + "Bar"
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.min_value = 0
        bar.max_value = 100

        var label: Label = Label.new()
        label.name = stat_id + "Label"
        label.custom_minimum_size = Vector2(30, 0)

        hbox.add_child(icon)
        hbox.add_child(bar)
        hbox.add_child(label)
        _attributes_container.add_child(hbox)


func _create_combat_section() -> void:
    # Combat info: base chance, equipment bonus
    pass


func _create_reputation_section() -> void:
    # Reputation: Fighter, Social, Hacker
    pass


func _create_skills_section() -> void:
    # Skills: course levels, streaks, mission counts
    pass