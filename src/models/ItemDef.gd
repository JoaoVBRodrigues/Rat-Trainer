class_name ItemDef
extends RefCounted

var id: String = ""
var name: String = ""
var category: String = ""
var shop_type: String = ""
var cost: int = 0
var effect: String = ""
var requirements: Dictionary = {}

static func from_dict(data: Dictionary) -> ItemDef:
	var item = ItemDef.new()
	item.id = data.get("id", "")
	item.name = data.get("name", "")
	item.category = data.get("category", "")
	item.shop_type = data.get("shop_type", "")
	item.cost = int(data.get("cost", 0))
	item.effect = data.get("effect", "")
	item.requirements = data.get("requirements", {})
	return item