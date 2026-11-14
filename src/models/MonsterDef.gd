class_name MonsterDef
extends RefCounted

var id: String = ""
var name: String = ""
var description: String = ""
var type: String = ""
var difficulty: int = 0
var mission_id: String = ""

static func from_dict(data: Dictionary) -> MonsterDef:
	var monster = MonsterDef.new()
	monster.id = data.get("id", "")
	monster.name = data.get("name", "")
	monster.description = data.get("description", "")
	monster.type = data.get("type", "")
	monster.difficulty = int(data.get("difficulty", 0))
	monster.mission_id = data.get("mission_id", "")
	return monster