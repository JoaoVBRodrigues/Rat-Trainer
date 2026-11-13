class_name EndingDef
extends RefCounted

var id: String = ""
var name: String = ""
var description: String = ""
var conditions: Dictionary = {}

static func from_dict(data: Dictionary) -> EndingDef:
	var ending = EndingDef.new()
	ending.id = data.get("id", "")
	ending.name = data.get("name", "")
	ending.description = data.get("description", "")
	ending.conditions = data.get("conditions", {})
	return ending