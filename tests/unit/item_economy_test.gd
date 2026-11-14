extends GdUnitTestSuite


func test_purchase_debits_credits_and_adds_item_without_advancing_calendar() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	var completed_periods: int = simulation.calendar.completed_periods

	# Act
	var result: Dictionary = simulation.buy_item("kit_ferramentas")

	# Assert
	assert_bool(result.get("success", false)).is_true()
	assert_int(simulation.economy.get_credits()).is_equal(175)
	assert_int(simulation.get_item_count("kit_ferramentas")).is_equal(1)
	assert_int(simulation.calendar.completed_periods).is_equal(completed_periods)


func test_catalog_prices_fit_within_the_annual_stipend() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	var total_catalog_cost: int = 0
	for item: ItemDef in simulation.item_shop_system.get_items():
		total_catalog_cost += item.cost

	# Assert
	assert_int(total_catalog_cost).is_equal(55)
	assert_bool(total_catalog_cost < EconomySystem.YEARLY_STIPEND).is_true()


func test_purchase_without_credits_leaves_state_unchanged() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	simulation.economy.credits = 9
	var inventory_before: Dictionary = simulation.inventory_counts.duplicate(true)
	var completed_periods: int = simulation.calendar.completed_periods

	# Act
	var result: Dictionary = simulation.buy_item("adesivo_recuperacao")

	# Assert
	assert_bool(result.get("success", true)).is_false()
	assert_str(result.get("error_key", "")).is_equal("ui.item_creditos_insuficientes_format")
	assert_int(simulation.economy.get_credits()).is_equal(9)
	assert_bool(simulation.inventory_counts == inventory_before).is_true()
	assert_int(simulation.calendar.completed_periods).is_equal(completed_periods)


func test_owned_equipment_cannot_be_purchased_twice() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	assert_bool(simulation.buy_item("kit_ferramentas").get("success", false)).is_true()
	assert_bool(simulation.equip_item("kit_ferramentas").get("success", false)).is_true()
	var credits_before: int = simulation.economy.get_credits()

	# Act
	var result: Dictionary = simulation.buy_item("kit_ferramentas")

	# Assert
	assert_bool(result.get("success", true)).is_false()
	assert_str(result.get("error_key", "")).is_equal("ui.item_ja_possuido")
	assert_int(simulation.economy.get_credits()).is_equal(credits_before)
	assert_str(simulation.get_equipped_item("hand")).is_equal("kit_ferramentas")


func test_inventory_limit_rejects_purchase_without_partial_transaction() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	for item_index: int in range(simulation.get_inventory_limit()):
		assert_bool(simulation.buy_item("adesivo_recuperacao").get("success", false)).is_true()
	var credits_before: int = simulation.economy.get_credits()
	var inventory_before: Dictionary = simulation.inventory_counts.duplicate(true)

	# Act
	var result: Dictionary = simulation.buy_item("adesivo_recuperacao")

	# Assert
	assert_bool(result.get("success", true)).is_false()
	assert_str(result.get("error_key", "")).is_equal("ui.item_inventario_cheio")
	assert_int(simulation.get_inventory_used_count()).is_equal(10)
	assert_int(simulation.economy.get_credits()).is_equal(credits_before)
	assert_bool(simulation.inventory_counts == inventory_before).is_true()


func test_recovery_consumable_reduces_stress_through_stats_system() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	assert_bool(simulation.buy_item("adesivo_recuperacao").get("success", false)).is_true()
	simulation.stats.set_stress(40)
	var completed_periods: int = simulation.calendar.completed_periods

	# Act
	var result: Dictionary = simulation.use_item("adesivo_recuperacao")

	# Assert
	assert_bool(result.get("success", false)).is_true()
	assert_int(simulation.stats.get_stress()).is_equal(25)
	assert_int(simulation.get_item_count("adesivo_recuperacao")).is_equal(0)
	assert_int(simulation.calendar.completed_periods).is_equal(completed_periods)


func test_recovery_consumable_clamps_at_zero_and_is_still_consumed() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	assert_bool(simulation.buy_item("adesivo_recuperacao").get("success", false)).is_true()
	simulation.stats.set_stress(8)

	# Act
	var result: Dictionary = simulation.use_item("adesivo_recuperacao")

	# Assert
	assert_bool(result.get("success", false)).is_true()
	assert_int(simulation.stats.get_stress()).is_equal(0)
	assert_int(simulation.get_item_count("adesivo_recuperacao")).is_equal(0)


func test_equipment_bonus_is_applied_and_removed_without_stat_residue() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	var strength_before: int = simulation.stats.get_stat("str")
	assert_bool(simulation.buy_item("kit_ferramentas").get("success", false)).is_true()
	assert_bool(simulation.buy_item("casaco_acolchoado").get("success", false)).is_true()

	# Act
	assert_bool(simulation.equip_item("kit_ferramentas").get("success", false)).is_true()
	assert_int(
		simulation.activities.get_mission_equipment_bonus("missao_fisica_ruinas")
	).is_equal(5)
	assert_bool(simulation.equip_item("casaco_acolchoado").get("success", false)).is_true()

	# Assert
	assert_int(
		simulation.activities.get_mission_equipment_bonus("missao_fisica_ruinas")
	).is_equal(10)
	assert_int(simulation.stats.get_stat("str")).is_equal(strength_before)
	assert_int(simulation.get_inventory_used_count()).is_equal(2)

	# Act — remove each equipped modifier
	assert_bool(simulation.unequip_item("hand").get("success", false)).is_true()
	assert_int(
		simulation.activities.get_mission_equipment_bonus("missao_fisica_ruinas")
	).is_equal(5)
	assert_bool(simulation.unequip_item("protection").get("success", false)).is_true()

	# Assert
	assert_int(
		simulation.activities.get_mission_equipment_bonus("missao_fisica_ruinas")
	).is_equal(0)
	assert_int(simulation.get_item_count("kit_ferramentas")).is_equal(1)
	assert_int(simulation.get_item_count("casaco_acolchoado")).is_equal(1)
	assert_int(simulation.get_inventory_used_count()).is_equal(2)
	assert_int(simulation.stats.get_stat("str")).is_equal(strength_before)


func test_equipment_and_inventory_persist_in_simulation_state() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	assert_bool(simulation.buy_item("kit_ferramentas").get("success", false)).is_true()
	assert_bool(simulation.buy_item("casaco_acolchoado").get("success", false)).is_true()
	assert_bool(simulation.buy_item("adesivo_recuperacao").get("success", false)).is_true()
	assert_bool(simulation.equip_item("kit_ferramentas").get("success", false)).is_true()
	assert_bool(simulation.equip_item("casaco_acolchoado").get("success", false)).is_true()
	var snapshot: Dictionary = simulation.get_state()
	var restored: SimulationCore = _new_simulation()

	# Act
	var loaded: bool = restored.load_state(snapshot)

	# Assert
	assert_bool(loaded).is_true()
	assert_str(restored.get_equipped_item("hand")).is_equal("kit_ferramentas")
	assert_str(restored.get_equipped_item("protection")).is_equal("casaco_acolchoado")
	assert_int(restored.get_item_count("adesivo_recuperacao")).is_equal(1)
	assert_int(restored.get_inventory_used_count()).is_equal(3)
	assert_int(
		restored.activities.get_mission_equipment_bonus("missao_fisica_ruinas")
	).is_equal(10)


func test_load_state_rejects_duplicate_unique_equipment() -> void:
	# Arrange
	var source: SimulationCore = _new_simulation()
	assert_bool(source.buy_item("kit_ferramentas").get("success", false)).is_true()
	assert_bool(source.equip_item("kit_ferramentas").get("success", false)).is_true()
	var duplicate_equipped_state: Dictionary = source.get_state()
	duplicate_equipped_state["inventory_counts"]["kit_ferramentas"] = 1
	var duplicate_inventory_state: Dictionary = source.get_state()
	duplicate_inventory_state["equipment_slots"]["hand"] = ""
	duplicate_inventory_state["activities"]["equipped_item_ids"] = []
	duplicate_inventory_state["inventory_counts"]["kit_ferramentas"] = 2
	var restored: SimulationCore = _new_simulation()
	var initial_state: Dictionary = restored.get_state()

	# Act
	var duplicate_equipped_loaded: bool = restored.load_state(duplicate_equipped_state)
	var duplicate_inventory_loaded: bool = restored.load_state(duplicate_inventory_state)

	# Assert
	assert_bool(duplicate_equipped_loaded).is_false()
	assert_bool(duplicate_inventory_loaded).is_false()
	assert_bool(restored.get_state() == initial_state).is_true()


func test_shops_list_all_items_with_placeholder_icons_and_descriptions() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	var assets: AssetResolver = auto_free(AssetResolver.new())
	add_child(assets)
	var screen: ItemManagementScreen = auto_free(ItemManagementScreen.new())
	screen.set_asset_resolver(assets)
	add_child(screen)

	# Act
	screen.open("shops", simulation)

	# Assert
	assert_int(screen._shop_tabs.get_child_count()).is_equal(3)
	for shop: Dictionary in simulation.get_item_shops():
		screen._on_shop_selected(str(shop.get("id", "")))
		assert_int(screen._items_list.get_child_count()).is_equal(1)
		var card: PanelContainer = screen._items_list.get_child(0) as PanelContainer
		var icon: TextureRect = card.find_child("Icon", true, false) as TextureRect
		var description: Label = card.find_child("Description", true, false) as Label
		assert_object(icon.texture).is_not_null()
		assert_str(description.text).is_not_empty()


func test_shop_feedback_explains_insufficient_credits() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	simulation.economy.credits = 0
	var assets: AssetResolver = auto_free(AssetResolver.new())
	add_child(assets)
	var screen: ItemManagementScreen = auto_free(ItemManagementScreen.new())
	screen.set_asset_resolver(assets)
	add_child(screen)
	screen.open("shops", simulation)
	var card: PanelContainer = screen._items_list.get_child(0) as PanelContainer
	var buy_button: Button = card.find_child("Action", true, false) as Button

	# Act
	buy_button.pressed.emit()

	# Assert
	assert_str(screen._feedback_label.text).contains("Créditos insuficientes")
	assert_int(simulation.economy.get_credits()).is_equal(0)
	assert_int(simulation.get_item_count("kit_ferramentas")).is_equal(0)


func test_city_and_equipment_menu_open_their_item_screens() -> void:
	# Arrange
	var simulation: SimulationCore = _new_simulation()
	var screen: MainScreen = auto_free(MainScreen.new())
	add_child(screen)
	screen.update_simulation(simulation)

	# Act
	screen._on_menu_pressed("cidade")

	# Assert
	var item_screen: ItemManagementScreen = screen._item_management_screen
	assert_bool(item_screen.visible).is_true()
	assert_str(item_screen._title_label.text).is_equal("Lojas")
	assert_int(item_screen._shop_tabs.get_child_count()).is_equal(3)

	# Act
	item_screen._on_close_pressed()
	screen._on_menu_pressed("equipamento")

	# Assert
	assert_bool(item_screen.visible).is_true()
	assert_str(item_screen._title_label.text).is_equal("Equipamento")
	assert_int(item_screen._equipment_rows.get_child_count()).is_equal(2)
	var empty_hand_label: Label = item_screen._equipment_rows.get_child(0).get_child(1) as Label
	assert_str(empty_hand_label.text).is_equal("Vazio")


func _new_simulation() -> SimulationCore:
	var simulation: SimulationCore = SimulationCore.new()
	assert_bool(simulation.initialize()).is_true()
	return simulation
