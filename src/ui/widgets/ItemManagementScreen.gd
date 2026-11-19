extends Control
class_name ItemManagementScreen

signal closed
signal credits_changed

const EQUIPMENT_SLOTS: Array[String] = ["hand", "protection"]
const SLOT_NAME_KEYS: Dictionary = {
	"hand": "ui.item_slot_hand",
	"protection": "ui.item_slot_protection"
}

var _simulation: SimulationCore
var _assets: AssetResolver
var _mode: String = "shops"
var _selected_shop_id: String = ""
var _title_label: Label
var _credits_label: Label
var _close_button: Button
var _shop_tabs: HBoxContainer
var _shop_description: Label
var _equipment_rows: VBoxContainer
var _items_list: VBoxContainer
var _inventory_label: Label
var _feedback_label: Label
var _shop_artwork: TextureRect


func _ready() -> void:
	_build_ui()


func set_asset_resolver(assets: AssetResolver) -> void:
	_assets = assets


func open(mode: String, simulation: SimulationCore) -> void:
	if mode not in ["shops", "equipment"]:
		push_error("Unknown item management screen mode '%s'." % mode)
		return
	_mode = mode
	_simulation = simulation
	if is_node_ready():
		_feedback_label.text = ""
	if _mode == "shops" and _selected_shop_id.is_empty() and simulation != null:
		var shops: Array[Dictionary] = simulation.get_item_shops()
		if not shops.is_empty():
			_selected_shop_id = str(shops[0].get("id", ""))
	visible = true
	_refresh()
	if is_node_ready():
		_close_button.grab_focus()


func update_simulation(simulation: SimulationCore) -> void:
	_simulation = simulation
	if visible:
		_refresh()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_mode = Control.FOCUS_ALL
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.055, 0.075, 0.13, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ItemManagementPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = -16.0
	add_child(panel)
	UIThemeResource.frame_panel(panel, 40.0)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "Content"
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.name = "Header"
	layout.add_child(header)
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_credits_label = Label.new()
	_credits_label.name = "Credits"
	_credits_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_credits_label)
	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = Localization.text("ui.voltar")
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.pressed.connect(_on_close_pressed)
	header.add_child(_close_button)
	_shop_artwork = ArtPresentation.artwork(layout, &"bg_workshop", Vector2(0, 150), "ShopArtwork")

	_shop_tabs = HBoxContainer.new()
	_shop_tabs.name = "ShopTabs"
	_shop_tabs.add_theme_constant_override("separation", 8)
	layout.add_child(_shop_tabs)
	_shop_description = Label.new()
	_shop_description.name = "ShopDescription"
	_shop_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_shop_description)

	_equipment_rows = VBoxContainer.new()
	_equipment_rows.name = "EquipmentSlots"
	layout.add_child(_equipment_rows)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	_items_list = VBoxContainer.new()
	_items_list.name = "ItemsList"
	_items_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_items_list)

	_inventory_label = Label.new()
	_inventory_label.name = "InventoryCapacity"
	layout.add_child(_inventory_label)
	_feedback_label = Label.new()
	_feedback_label.name = "Feedback"
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_feedback_label)


func _refresh() -> void:
	if not is_node_ready():
		return
	for child: Node in _shop_tabs.get_children():
		_shop_tabs.remove_child(child)
		child.queue_free()
	for child: Node in _equipment_rows.get_children():
		_equipment_rows.remove_child(child)
		child.queue_free()
	for child: Node in _items_list.get_children():
		_items_list.remove_child(child)
		child.queue_free()
	if _simulation == null:
		_title_label.text = Localization.text("ui.sem_campanha")
		_credits_label.text = ""
		_shop_description.text = ""
		_inventory_label.text = ""
		return

	_credits_label.text = Localization.format(
		"ui.creditos_format", {"value": _simulation.economy.get_credits()}
	)
	_inventory_label.text = Localization.format(
		"ui.inventario_limite_format",
		{"used": _simulation.get_inventory_used_count(), "limit": _simulation.get_inventory_limit()}
	)
	_shop_tabs.visible = _mode == "shops"
	_shop_artwork.visible = _mode == "shops"
	_shop_description.visible = _mode == "shops"
	_equipment_rows.visible = _mode == "equipment"
	if _mode == "shops":
		_title_label.text = Localization.text("ui.lojas")
		_build_shop_tabs()
		_build_shop_stock()
	else:
		_title_label.text = Localization.text("ui.equipamento")
		_shop_description.text = ""
		_build_equipment_slots()
		_build_equipment_items()


func _build_shop_tabs() -> void:
	var art_ids: Dictionary = {"workshop": &"bg_workshop", "general": &"bg_market", "clinic": &"bg_clinic"}
	_shop_artwork.texture = _assets.get_texture(art_ids.get(_selected_shop_id, &"bg_market"), &"backgrounds")
	var shops: Array[Dictionary] = _simulation.get_item_shops()
	for shop: Dictionary in shops:
		var shop_id: String = str(shop.get("id", ""))
		var button: Button = Button.new()
		button.name = "Shop_%s" % shop_id
		button.text = Localization.text(str(shop.get("name_key", "")))
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = shop_id == _selected_shop_id
		button.pressed.connect(_on_shop_selected.bind(shop_id))
		_shop_tabs.add_child(button)

	var selected_shop: Dictionary = _simulation.item_shop_system.get_shop(_selected_shop_id)
	_shop_description.text = Localization.text(str(selected_shop.get("description_key", "")))


func _build_shop_stock() -> void:
	for item_id: String in _simulation.get_shop_item_ids(_selected_shop_id):
		var item: ItemDef = _simulation.get_item(item_id)
		if item != null:
			_add_item_card(item, true)


func _build_equipment_slots() -> void:
	for slot: String in EQUIPMENT_SLOTS:
		var item_id: String = _simulation.get_equipped_item(slot)
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "EquipmentSlot_%s" % slot
		var slot_label: Label = Label.new()
		slot_label.text = Localization.text(str(SLOT_NAME_KEYS[slot]))
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slot_label)
		var item_label: Label = Label.new()
		item_label.name = "EquippedItem"
		var equipped_item: ItemDef = (
			_simulation.get_item(item_id) if not item_id.is_empty() else null
		)
		item_label.text = (
			Localization.text(equipped_item.name_key)
			if equipped_item != null
			else Localization.text("ui.item_slot_vazio")
		)
		row.add_child(item_label)
		var remove_button: Button = Button.new()
		remove_button.name = "Unequip_%s" % slot
		remove_button.text = Localization.text("ui.desequipar")
		remove_button.focus_mode = Control.FOCUS_ALL
		remove_button.disabled = item_id.is_empty()
		remove_button.pressed.connect(_on_item_action.bind("", "unequip", slot))
		row.add_child(remove_button)
		_equipment_rows.add_child(row)


func _build_equipment_items() -> void:
	for item: ItemDef in _simulation.item_shop_system.get_items():
		_add_item_card(item, false)


func _add_item_card(item: ItemDef, in_shop: bool) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.name = "Item_%s" % item.id
	card.custom_minimum_size.y = 112.0
	_items_list.add_child(card)
	UIThemeResource.frame_panel(card, 40.0)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(72.0, 72.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _assets != null:
		icon.texture = _assets.get_texture(item.icon, &"items")
	row.add_child(icon)

	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var name_label: Label = Label.new()
	name_label.name = "ItemName"
	name_label.text = Localization.text(item.name_key)
	details.add_child(name_label)
	var description: Label = Label.new()
	description.name = "Description"
	description.text = Localization.text(item.description_key)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)
	var effect: Label = Label.new()
	effect.name = "Effect"
	effect.text = Localization.text(item.effect_key)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(effect)
	var info: Label = Label.new()
	info.name = "PriceOrCount"
	if in_shop:
		info.text = "%s · %s" % [
			Localization.format("ui.creditos_format", {"value": item.cost}),
			Localization.text("ui.sem_requisitos")
		]
	else:
		info.text = Localization.format(
			"ui.item_quantidade_format", {"count": _simulation.get_item_count(item.id)}
		)
	details.add_child(info)

	var action_button: Button = Button.new()
	action_button.name = "Action"
	action_button.custom_minimum_size = Vector2(104.0, 44.0)
	action_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_button.focus_mode = Control.FOCUS_ALL
	if in_shop:
		action_button.text = Localization.text("ui.comprar")
		action_button.pressed.connect(_on_item_action.bind(item.id, "buy", ""))
	else:
		var equipped_slot: String = item.slot
		var equipped: bool = (
			equipped_slot in EQUIPMENT_SLOTS
			and _simulation.get_equipped_item(equipped_slot) == item.id
		)
		if item.category == "consumable":
			action_button.text = Localization.text("ui.usar")
			action_button.disabled = _simulation.get_item_count(item.id) <= 0
			action_button.pressed.connect(_on_item_action.bind(item.id, "use", ""))
		elif equipped:
			action_button.text = Localization.text("ui.desequipar")
			action_button.pressed.connect(
				_on_item_action.bind("", "unequip", equipped_slot)
			)
		else:
			action_button.text = Localization.text("ui.equipar")
			action_button.disabled = _simulation.get_item_count(item.id) <= 0
			action_button.pressed.connect(_on_item_action.bind(item.id, "equip", ""))
	row.add_child(action_button)


func _on_shop_selected(shop_id: String) -> void:
	_selected_shop_id = shop_id
	_feedback_label.text = ""
	_refresh()


func _on_item_action(item_id: String, action: String, slot: String) -> void:
	var result: Dictionary
	match action:
		"buy":
			result = _simulation.buy_item(item_id)
		"use":
			result = _simulation.use_item(item_id)
		"equip":
			result = _simulation.equip_item(item_id)
		"unequip":
			result = _simulation.unequip_item(slot)
		_:
			push_error("Unknown item action '%s'." % action)
			return
	if bool(result.get("success", false)):
		_feedback_label.text = _success_message(action, result)
	else:
		var error_key: String = str(result.get("error_key", "ui.item_nao_encontrado"))
		_feedback_label.text = (
			Localization.format(error_key, result)
			if error_key.ends_with("_format")
			else Localization.text(error_key).format(result)
		)
	_refresh()
	if action == "buy" or action == "use":
		credits_changed.emit()
func _success_message(action: String, result: Dictionary) -> String:
	var item: ItemDef = _simulation.get_item(str(result.get("item_id", "")))
	var item_name: String = Localization.text(item.name_key) if item != null else ""
	match action:
		"buy":
			return Localization.format("ui.item_compra_sucesso", {"item": item_name})
		"use":
			return Localization.format(
				"ui.item_usado_format",
				{"item": item_name, "stress": int(result.get("stress", 0))}
			)
		"equip":
			return Localization.format("ui.item_equipado_format", {"item": item_name})
		"unequip":
			return Localization.format("ui.item_desequipado_format", {"item": item_name})
	return ""


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
