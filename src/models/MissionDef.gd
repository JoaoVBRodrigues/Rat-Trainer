class_name MissionDef
extends RefCounted

var id: String = ""
var type: String = ""
var name: String = ""
var stat_id: String = ""
var stress: int = 0
var success_effects: Dictionary = {}

static func from_dict(data: Dictionary) -> MissionDef:
	var mission = MissionDef.new()
	mission.id = data.get("id", "")
	mission.type = data.get("type", "")
	mission.name = data.get("name", "")
	mission.stat_id = data.get("stat_test", "")
	mission.stress = int(data.get("stress", 0))
	mission.success_effects = data.get("success_effects", {})
	return mission
