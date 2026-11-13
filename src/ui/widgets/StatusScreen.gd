extends Control
class_name StatusScreen

# Expanded status screen showing all 4 blocks with numeric values
# All values shown 0-100 with progress bars and labels

@export var show_detailed: bool = true

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

# Node references
@onready var _attributes_grid: GridContainer = $"AttributesGrid"
@onready var _combat_panel: VBoxContainer = $"CombatPanel"
@onready var _reputation_grid: GridContainer = $"ReputationGrid"
@onready var _skills_panel: VBoxContainer = $"SkillsPanel"
@onready var _stress_bar: ProgressBar = $"StressDisplay/StressBar"


func _ready() -> void:
    _build_attributes_section()
    _build_reputation_section()


func update_from_simulator(sim: SimulationCore) -> void:
    if sim == null:
        return
    _update_attributes(sim)
    _update_stress(sim)
    _update_reputation(sim)
    _update_skills(sim)


func _update_attributes(sim: SimulationCore) -> void:
    for stat_id in STAT_IDS:
        var value: int = sim.stats.get_stat(stat_id)
        var bar: ProgressBar = _attributes_grid.get_node_or_null(stat_id + "Bar")
        var label: Label = _attributes_grid.get_node_or_null(stat_id + "Label")
        if bar != null:
            bar.value = value
        if label != null:
            label.text = str(value)


func _update_stress(sim: SimulationCore) -> void:
    if _stress_bar != null:
        _stress_bar.value = sim.stats.stress
        _stress_bar.modulate = _get_stress_color(sim.stats.stress)


func _update_reputation(sim: SimulationCore) -> void:
    var fighter_label: Label = _reputation_grid.get_node_or_null("FighterLabel")
    var social_label: Label = _reputation_grid.get_node_or_null("SocialLabel")
    var hacker_label: Label = _reputation_grid.get_node_or_null("HackerLabel")

    if fighter_label != null:
        fighter_label.text = str(sim.stats.get_reputation("fighter"))
    if social_label != null:
        social_label.text = str(sim.stats.get_reputation("social"))
    if hacker_label != null:
        hacker_label.text = str(sim.stats.get_reputation("hacker"))


func _update_skills(sim: SimulationCore) -> void:
    # Display course levels from XP tracking
    pass


func _get_stress_color(stress: int) -> Color:
    if stress < 30:
        return Color(0.45, 0.85, 0.45)  # Green
    if stress < 60:
        return Color(0.93, 0.65, 0.43)  # Orange
    return Color(0.94, 0.4, 0.4)  # Red


func _build_attributes_section() -> void:
    if _attributes_grid == null:
        return
    for stat_id in STAT_IDS:
        var hbox: HBoxContainer = HBoxContainer.new()
        hbox.name = stat_id + "Container"

        var icon: TextureRect = TextureRect.new()
        icon.name = "Icon"
        icon.texture = Assets.get_texture("icon_stat_" + stat_id, &"icons")
        icon.expand = true
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.custom_minimum_size = Vector2(32, 32)

        var name: Label = Label.new()
        name.name = "Name"
        name.text = STAT_NAMES.get(stat_id, stat_id)
        name.custom_fonts/font = null  # Will use theme font

        var bar: ProgressBar = ProgressBar.new()
        bar.name = stat_id + "Bar"
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.min_value = 0
        bar.max_value = 100

        var value: Label = Label.new()
        value.name = stat_id + "Label"
        value.custom_minimum_size = Vector2(30, 0)

        hbox.add_child(icon)
        hbox.add_child(name)
        hbox.add_child(bar)
        hbox.add_child(value)
        _attributes_grid.add_child(hbox)


func _build_reputation_section() -> void:
    if _reputation_grid == null:
        return
    var reputations: Array = [
        {"id": "fighter", "name": "Lutador", "color": Color(0.85, 0.44, 0.21)},
        {"id": "social", "name": "Social", "color": Color(0.93, 0.65, 0.43)},
        {"id": "hacker", "name": "Hacker", "color": Color(0.53, 0.78, 0.91)}
    ]

    for rep in reputations:
        var hbox: HBoxContainer = HBoxContainer.new()
        hbox.name = rep["id"] + "Container"

        var name: Label = Label.new()
        name.name = "Name"
        name.text = rep["name"]

        var bar: ProgressBar = ProgressBar.new()
        bar.name = rep["id"] + "Bar"
        bar.min_value = 0
        bar.max_value = 100
        bar.custom_colors/fg_color = rep["color"]

        var value: Label = Label.new()
        value.name = rep["id"] + "Label"
        value.custom_minimum_size = Vector2(30, 0)

        hbox.add_child(name)
        hbox.add_child(bar)
        hbox.add_child(value)
        _reputation_grid.add_child(hbox)