class_name EndingDef
extends RefCounted

var id: String = ""
var name: String = ""
var description: String = ""
var conditions: Dictionary = {}
var priority: int = 0
var is_default: bool = false

static func from_dict(data: Dictionary) -> EndingDef:
	var ending = EndingDef.new()
	ending.id = data.get("id", "")
	ending.name = data.get("name", "")
	ending.description = data.get("description", "")
	ending.conditions = data.get("conditions", {})
	ending.priority = int(data.get("priority", 0))
	ending.is_default = bool(data.get("is_default", false))
	return ending