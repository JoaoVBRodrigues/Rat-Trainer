class_name ArtPresentation
extends RefCounted

## Visual selection only. Does not change simulation state or consume randomness.
const ACTIVITIES: Dictionary = {
	"curso_tecnologia": "scene_study_tech",
	"curso_comunicacao": "scene_study_etiquette",
	"curso_artes": "bg_school",
	"trabalho_reparo_leve": "scene_work_mechanic",
	"trabalho_entrega_assistida": "scene_work_courier",
	"trabalho_apoio_comunitario": "scene_work_clerk",
	"lazer_descanso": "scene_rest_home",
	"lazer_passeio_comunitario": "scene_leisure_park",
	"missao_fisica_ruinas": "bg_mission_factory",
	"missao_fisica_drones": "bg_mission_rooftop",
	"missao_fisica_infiltracao": "bg_mission_subway",
	"missao_tecnica": "bg_workshop",
	"missao_comunitaria": "bg_market"
}
const EVENTS: Dictionary = {
	"e01": "bg_market", "e02": "cg_festival_drones", "e03": "bg_workshop",
	"e04": "cg_festival_parkour", "e05": "bg_workshop", "e06": "cg_festival_drones",
	"e07": "bg_market", "e08": "bg_street_night", "e09": "cg_festival_hacking",
	"e10": "cg_chase", "e11": "bg_corp_lobby", "e12": "bg_ending",
	"r01": "cg_merchant", "r02": "scene_leisure_park", "r03": "bg_workshop"
}

static func character_id(simulation: SimulationCore) -> StringName:
	if simulation == null:
		return &"char_rat_idle"
	var age: int = clampi(simulation.get_age(), 12, 15)
	var state: String = ""
	if simulation.stats.is_diseased:
		state = "_sick"
	elif simulation.stats.get_stress() >= simulation.stats.get_disease_threshold() / 2:
		state = "_tired"
	return StringName("char_rat_casual_a_age%d%s" % [age, state])

static func activity_id(result: PeriodResult) -> StringName:
	if result.activity_type == PeriodResult.ActivityType.EVENT:
		return event_id(result.event_id)
	if result.activity_type == PeriodResult.ActivityType.MISSION and not result.mission_success:
		return &"cg_defeat_carried"
	return StringName(ACTIVITIES.get(result.activity_id, "bg_workshop"))

static func event_id(id: String) -> StringName:
	return StringName(EVENTS.get(id, "bg_market"))

static func artwork(parent: Node, id: StringName, minimum: Vector2, node_name: String = "Artwork") -> TextureRect:
	var view: TextureRect = TextureRect.new()
	view.name = node_name
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.custom_minimum_size = minimum
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
	var resolver: AssetResolver = parent.get_node_or_null("/root/Assets") as AssetResolver
	if resolver != null:
		view.texture = resolver.get_texture(id, &"backgrounds")
	return view
