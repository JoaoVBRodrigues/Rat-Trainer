extends RefCounted
class_name ShopDef

var id: String = ""
var name_key: String = ""
var description_key: String = ""
var items: Array[String] = []


static func from_dict(data: Dictionary) -> ShopDef:
	var shop: ShopDef = ShopDef.new()
	shop.id = str(data.get("id", ""))
	shop.name_key = str(data.get("name_key", ""))
	shop.description_key = str(data.get("description_key", ""))
	var item_ids: Variant = data.get("items", [])
	if item_ids is Array:
		for item_id: Variant in item_ids:
			if item_id is String:
				shop.items.append(item_id)
	return shop
