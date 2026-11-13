class_name ActivityDef
extends RefCounted

var id: String = ""
var type: String = ""
var name: String = ""
var description: String = ""
var stat_id: String = ""
var gains: Dictionary = {"l1": {}, "l2": {}, "l3": {}}
var cost_l1: int = 0
var cost_l2: int = 0
var cost_l3: int = 0
var stress: int = 0
var stress_reduction: int = 0
var income_l1: int = 0
var income_l2: int = 0
var stat_bonus: String = ""
var stat_gain: int = 0
var cha_gain: int = 0
var eth_gain: int = 0
var eth_loss: int = 0

func gain_for_level(level: int) -> Dictionary:
	match level:
		1:
			return gains.get("l1", {})
		2:
			return gains.get("l2", {})
		3:
			return gains.get("l3", {})
		_:
			return {}

func cost_for_level(level: int) -> int:
	match level:
		1:
			return cost_l1
		2:
			return cost_l2
		3:
			return cost_l3
		_:
			return 0

static func from_dict(data: Dictionary) -> ActivityDef:
	var activity := ActivityDef.new()
	activity.id = data.get("id", "")
	activity.type = data.get("type", "")
	activity.name = data.get("name", "")
	activity.description = data.get("description", "")
	activity.stat_id = data.get("stat_id", "")
	var parsed_gains: Variant = data.get("gains", {"l1": {}, "l2": {}, "l3": {}})
	if parsed_gains is Dictionary:
		activity.gains = parsed_gains
	activity.cost_l1 = int(data.get("cost_l1", 0))
	activity.cost_l2 = int(data.get("cost_l2", 0))
	activity.cost_l3 = int(data.get("cost_l3", 0))
	activity.stress = int(data.get("stress", 0))
	activity.stress_reduction = int(data.get("stress_reduction", 0))
	activity.income_l1 = int(data.get("income_l1", 0))
	activity.income_l2 = int(data.get("income_l2", 0))
	activity.stat_bonus = data.get("stat_bonus", "")
	activity.stat_gain = int(data.get("stat_gain", 0))
	activity.cha_gain = int(data.get("cha_gain", 0))
	activity.eth_gain = int(data.get("eth_gain", 0))
	activity.eth_loss = int(data.get("eth_loss", 0))
	return activity