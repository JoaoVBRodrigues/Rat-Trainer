class_name MissionDef
extends RefCounted

var id: String = ""
var type: String = ""
var name: String = ""
var stat_id: String = ""
var minimum_attribute: int = 0
var required_equipment: Array[String] = []
var difficulty: int = 0
var stress: int = 0
var success_effects: Dictionary = {}

static func from_dict(data: Dictionary) -> MissionDef:
	var mission = MissionDef.new()
	mission.id = data.get("id", "")
	mission.type = data.get("type", "")
	mission.name = data.get("name", "")
	mission.stat_id = data.get("stat_test", "")
	mission.minimum_attribute = int(data.get("minimum_attribute", 0))
	var equipment: Variant = data.get("required_equipment", [])
	if equipment is Array:
		for item_id: Variant in equipment:
			if item_id is String:
				mission.required_equipment.append(item_id)
	mission.difficulty = int(data.get("difficulty", 0))
	mission.stress = int(data.get("stress", 0))
	mission.success_effects = data.get("success_effects", {})
	return mission
