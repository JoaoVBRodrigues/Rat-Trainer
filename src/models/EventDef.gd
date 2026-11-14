class_name EventDef
extends RefCounted

var id: String = ""
var year: int = 0
var month: int = 0
var period: int = 0
var type: String = "fixed"
var name: String = ""
var description: String = ""
var options: Array = []
var conditions: Dictionary = {}

static func from_dict(data: Dictionary) -> EventDef:
	var event = EventDef.new()
	event.id = data.get("id", "")
	event.year = int(data.get("year", 1))
	event.month = int(data.get("month", 1))
	event.period = int(data.get("period", 3))
	event.type = data.get("type", "fixed")
	event.name = data.get("name", "")
	event.description = data.get("description", "")
	event.options = data.get("options", [])
	event.conditions = data.get("conditions", {})
	return event