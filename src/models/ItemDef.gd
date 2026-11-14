class_name ItemDef
extends RefCounted

var id: String = ""
var name: String = ""
var name_key: String = ""
var description_key: String = ""
var effect_key: String = ""
var icon: StringName = &"item_generic"
var category: String = ""
var slot: String = ""
var shop_type: String = ""
var cost: int = 0
var effect: String = ""
var effect_data: Dictionary = {}
var requirements: Dictionary = {}

static func from_dict(data: Dictionary) -> ItemDef:
	var item: ItemDef = ItemDef.new()
	item.id = str(data.get("id", ""))
	item.name = str(data.get("name", ""))
	item.name_key = str(data.get("name_key", ""))
	item.description_key = str(data.get("description_key", ""))
	item.effect_key = str(data.get("effect_key", ""))
	item.icon = StringName(str(data.get("icon", "item_generic")))
	item.category = str(data.get("category", ""))
	item.slot = str(data.get("slot", ""))
	item.shop_type = str(data.get("shop_type", ""))
	item.cost = int(data.get("cost", 0))
	item.effect = str(data.get("effect", ""))
	var item_effect_data: Variant = data.get("effect_data", {})
	if item_effect_data is Dictionary:
		item.effect_data = item_effect_data.duplicate(true)
	var item_requirements: Variant = data.get("requirements", {})
	if item_requirements is Dictionary:
		item.requirements = item_requirements.duplicate(true)
	return item