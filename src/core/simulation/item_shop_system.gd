extends RefCounted
class_name ItemShopSystem

const DEFAULT_ITEMS_PATH: String = "res://assets/data/items.json"
const DEFAULT_SHOPS_PATH: String = "res://assets/data/shops.json"
const SUPPORTED_SCHEMA_VERSION: int = 1

var items_by_id: Dictionary = {}
var shops_by_id: Dictionary = {}
var shop_ids: Array[String] = []
var inventory_limit: int = 0


func load_data(
	items_path: String = DEFAULT_ITEMS_PATH,
	shops_path: String = DEFAULT_SHOPS_PATH
) -> bool:
	var item_data: Dictionary = _read_json_object(items_path, "items")
	var shops_data: Dictionary = _read_json_object(shops_path, "shops")
	if item_data.is_empty() or shops_data.is_empty():
		return false
	if not _has_supported_schema(item_data, items_path):
		return false
	if not _has_supported_schema(shops_data, shops_path):
		return false

	var item_records: Variant = item_data.get("items")
	var shop_records: Variant = shops_data.get("shops")
	var saved_limit: Variant = shops_data.get("inventory_limit")
	if not item_records is Array or not shop_records is Array:
		push_error("Item and shop catalogs must contain arrays.")
		return false
	if not _is_positive_integer(saved_limit):
		push_error("%s: inventory_limit must be a positive integer." % shops_path)
		return false

	var next_items: Dictionary = {}
	for item_record: Variant in item_records:
		if not item_record is Dictionary:
			push_error("%s: each item must be an object." % items_path)
			return false
		var item: ItemDef = ItemDef.from_dict(item_record)
		if item.id.is_empty() or next_items.has(item.id):
			push_error("%s: item IDs must be present and unique." % items_path)
			return false
		next_items[item.id] = item

	var next_shops: Dictionary = {}
	var next_shop_ids: Array[String] = []
	for shop_record: Variant in shop_records:
		if not shop_record is Dictionary:
			push_error("%s: each shop must be an object." % shops_path)
			return false
		var shop_id: String = str(shop_record.get("id", ""))
		if shop_id.is_empty() or next_shops.has(shop_id):
			push_error("%s: shop IDs must be present and unique." % shops_path)
			return false
		next_shops[shop_id] = shop_record.duplicate(true)
		next_shop_ids.append(shop_id)

	items_by_id = next_items
	shops_by_id = next_shops
	shop_ids = next_shop_ids
	inventory_limit = int(saved_limit)
	return true


func get_item(item_id: String) -> ItemDef:
	return items_by_id.get(item_id) as ItemDef


func get_items() -> Array[ItemDef]:
	var result: Array[ItemDef] = []
	for item_id: String in items_by_id:
		result.append(items_by_id[item_id] as ItemDef)
	return result


func get_shop(shop_id: String) -> Dictionary:
	var shop: Variant = shops_by_id.get(shop_id, {})
	return shop.duplicate(true) if shop is Dictionary else {}


func get_shops() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for shop_id: String in shop_ids:
		result.append(get_shop(shop_id))
	return result


func _read_json_object(path: String, required_key: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Data file does not exist: %s." % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open data file '%s'." % path)
		return {}
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Invalid JSON in '%s' at line %d: %s."
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not parsed.has(required_key):
		push_error("Data file '%s' must contain '%s'." % [path, required_key])
		return {}
	return parsed


func _has_supported_schema(data: Dictionary, path: String) -> bool:
	if int(data.get("schema_version", 0)) != SUPPORTED_SCHEMA_VERSION:
		push_error("Data file '%s' uses an unsupported schema version." % path)
		return false
	return true


func _is_positive_integer(value: Variant) -> bool:
	return (
		(value is int or value is float)
		and value > 0
		and float(value) == floorf(float(value))
	)
