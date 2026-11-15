extends RefCounted
class_name SimulationCore

const DEFAULT_CALENDAR_PATH: String = "res://assets/data/calendar.json"
const DEFAULT_ACTIVITIES_PATH: String = "res://assets/data/activities.json"
const DEFAULT_MISSIONS_PATH: String = "res://assets/data/missions.json"
const DEFAULT_MONSTERS_PATH: String = "res://assets/data/monsters.json"
const DEFAULT_ENCOUNTER_RULES_PATH: String = "res://assets/data/encounter_rules.json"
const DEFAULT_EVENTS_PATH: String = "res://assets/data/events.json"
const DEFAULT_ITEMS_PATH: String = "res://assets/data/items.json"
const DEFAULT_SHOPS_PATH: String = "res://assets/data/shops.json"

var calendar: CalendarSystem
var stats: StatsSystem
var economy: EconomySystem
var activities: ActivitySystem
var item_shop_system: ItemShopSystem
var events: EventSystem = EventSystem.new()
var completed_events: Array[String] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_event: Dictionary = {}  # Event waiting for player choice
var _pending_encounter: Dictionary = {}  # Encounter waiting for player choice
var _pending_encounter_result: PeriodResult
var inventory_counts: Dictionary = {}
var equipment_slots: Dictionary = {"hand": "", "protection": ""}
var _last_random_event_check_turn: int = -1
var tech_experiments: bool = false
var criminal_record: bool = false
var community_help: bool = false
var disappear_from_society: bool = false
var _missions_technical_completed: int = 0
var _calendar_config_path: String = DEFAULT_CALENDAR_PATH
var _activities_path: String = DEFAULT_ACTIVITIES_PATH
var _missions_path: String = DEFAULT_MISSIONS_PATH
var _monsters_path: String = DEFAULT_MONSTERS_PATH
var _encounter_rules_path: String = DEFAULT_ENCOUNTER_RULES_PATH
var _events_path: String = DEFAULT_EVENTS_PATH
var _items_path: String = DEFAULT_ITEMS_PATH
var _shops_path: String = DEFAULT_SHOPS_PATH


func initialize(
	calendar_config_path: String = DEFAULT_CALENDAR_PATH,
	activities_path: String = DEFAULT_ACTIVITIES_PATH,
	missions_path: String = DEFAULT_MISSIONS_PATH,
	events_path: String = DEFAULT_EVENTS_PATH,
	monsters_path: String = DEFAULT_MONSTERS_PATH,
	encounter_rules_path: String = DEFAULT_ENCOUNTER_RULES_PATH,
	items_path: String = DEFAULT_ITEMS_PATH,
	shops_path: String = DEFAULT_SHOPS_PATH
) -> bool:
	_calendar_config_path = calendar_config_path
	_activities_path = activities_path
	_missions_path = missions_path
	_monsters_path = monsters_path
	_encounter_rules_path = encounter_rules_path
	_events_path = events_path
	_items_path = items_path
	_shops_path = shops_path
	calendar = CalendarSystem.new()
	stats = StatsSystem.new()
	economy = EconomySystem.new()
	activities = ActivitySystem.new()
	item_shop_system = ItemShopSystem.new()
	events = EventSystem.new()
	if not calendar.initialize_from_config(_calendar_config_path):
		return false
	stats.initialize()
	economy.start_new_game(calendar.years)
	activities.rng = rng
	events.rng = rng
	if not activities.load_activities(_activities_path):
		return false
	if not activities.load_missions(_missions_path):
		return false
	if not activities.load_monsters(_monsters_path):
		return false
	if not activities.load_encounter_rules(_encounter_rules_path):
		return false
	if not item_shop_system.load_data(_items_path, _shops_path):
		return false
	if not events.load_events(_events_path):
		return false
	start_new_game()
	return true


func start_new_game() -> void:
	calendar.start_new_game()
	stats.initialize()
	economy.start_new_game(calendar.years)
	activities.reset()
	inventory_counts.clear()
	equipment_slots = {"hand": "", "protection": ""}
	_pending_event.clear()
	_pending_encounter.clear()
	_pending_encounter_result = null
	completed_events.clear()
	_last_random_event_check_turn = -1
	_reset_campaign_flags()
	_credit_stipend_if_due()


func set_seed(seed_value: int) -> void:
	rng.seed = seed_value
	if activities != null:
		activities.rng = rng
	if events != null:
		events.rng = rng


func advance_period(choice: String, period_seed: int = 0) -> PeriodResult:
	var result: PeriodResult = PeriodResult.new()
	if not _systems_are_initialized():
		result.error_message = "SimulationCore must be initialized before advancing."
		return result
	if calendar.is_campaign_complete():
		result.error_message = "Campaign already completed."
		return result
	if not _pending_encounter.is_empty():
		result.error_message = "An encounter is pending; resolve it before advancing."
		return result
	if period_seed != 0:
		rng.seed = period_seed

	# Check for pending event resolution
	if not _pending_event.is_empty():
		return _resolve_pending_event(choice)

	# Check for fixed event
	var year: int = calendar.get_year()
	var month: int = calendar.get_month()
	var period: int = calendar.get_period()
	var fixed_event: Dictionary = events.get_fixed_event_for_date(year, month, period)
	var is_fixed_event_period: bool = (
		month in EventSystem.FIXED_EVENT_MONTHS
		and period == EventSystem.FIXED_EVENT_PERIOD
	)

	if not fixed_event.is_empty() and not completed_events.has(fixed_event.get("id", "")):
		events.record_random_check_skipped(
			"fixed event %s has priority at year %d, month %d, period %d"
			% [str(fixed_event.get("id", "")), year, month, period]
		)
		# Set up pending event for player choice
		_pending_event = fixed_event
		result.is_event_pending = true
		result.event_id = fixed_event.get("id", "")
		result.event_name = fixed_event.get("name", "")
		result.event_description = fixed_event.get("description", "")
		result.event_options = fixed_event.get("options", [])
		return result

	# Check once per non-fixed period, including when a later choice is invalid.
	if is_fixed_event_period:
		events.record_random_check_skipped(
			"year %d, month %d, period %d is reserved for fixed events"
			% [year, month, period]
		)
	elif _last_random_event_check_turn != calendar.get_turn_number():
		_last_random_event_check_turn = calendar.get_turn_number()
		var max_attr: int = max(
			stats.get_stat("int"),
			max(stats.get_stat("cha"), stats.get_stat("ref"))
		)
		var random_event: Dictionary = events.roll_random_event(max_attr)
		if not random_event.is_empty():
			_pending_event = random_event
			result.is_event_pending = true
			result.event_id = random_event.get("id", "")
			result.event_name = random_event.get("name", "")
			result.event_description = random_event.get("description", "")
			result.event_options = random_event.get("options", [])
			return result
	else:
		events.record_random_check_skipped(
			"the current period was already checked"
		)

	var parsed_choice: Dictionary = _parse_choice(choice)
	if parsed_choice.has("error"):
		result.error_message = str(parsed_choice["error"])
		return result

	if parsed_choice["type"] == "mission" and stats.is_mission_blocked_by_disease():
		result.error_message = "Missions are unavailable while diseased."
		return result

	var activity_result: Dictionary = _resolve_activity(parsed_choice)
	if activity_result.has("error"):
		result.error_message = str(activity_result["error"])
		return result

	var cost: int = int(activity_result.get("cost", 0))
	if not economy.can_afford(cost):
		result.error_message = "Cannot afford activity."
		return result

	result.pre_period_state = get_state()
	result.period = calendar.get_turn_number()
	result.year = calendar.get_year()
	result.month = calendar.get_month()
	result.period_num = calendar.get_period()
	result.age = calendar.get_age()
	result.is_diseased_before = stats.is_diseased
	result.activity_type = int(activity_result["activity_type"])
	result.activity_id = str(activity_result["activity_id"])
	result.activity_level = int(activity_result.get("level", 1))
	result.success_chance = int(activity_result.get("success_chance", 0))
	result.mission_success = bool(activity_result.get("success", false))

	if bool(activity_result.get("encounter_pending", false)):
		_pending_encounter = {
			"encounter_monster_id": str(activity_result.get("encounter_monster_id", "")),
			"encounter_monster_name": str(activity_result.get("encounter_monster_name", "")),
			"encounter_monster_description": str(
				activity_result.get("encounter_monster_description", "")
			),
			"mission_id": result.activity_id,
			"encounter_difficulty": int(activity_result.get("encounter_difficulty", 0)),
			"encounter_stress": int(activity_result.get("encounter_stress", 0)),
			"encounter_effects": activity_result.get("encounter_effects", {}).duplicate(true)
		}
		result.is_encounter_pending = true
		result.encounter_monster_id = _pending_encounter["encounter_monster_id"]
		result.encounter_monster_name = _pending_encounter["encounter_monster_name"]
		result.encounter_description = _pending_encounter["encounter_monster_description"]
		_pending_encounter_result = result
		return result

	if cost > 0:
		economy.pay(cost)
		result.credits_change -= cost

	var income: int = int(activity_result.get("income", 0))
	if income > 0:
		economy.receive_income(income)
		result.credits_change += income

	_apply_activity_effects(parsed_choice, activity_result, result)

	_complete_period(result)
	return result


func _complete_period(result: PeriodResult) -> void:
	if calendar.is_month_end():
		var month_result: Dictionary = activities.close_month()
		result.month_end_processed = true
		result.streaks_incremented = month_result["streaks_incremented"]
		result.promotion_unlocked = not month_result["promotions"].is_empty()
	stats.check_and_update_disease()
	result.is_diseased_after = stats.is_diseased
	calendar.advance_period()
	var next_year_stipend: int = _credit_stipend_if_due()
	if next_year_stipend > 0:
		result.year_stipend_given = true
		result.credits_change += next_year_stipend
	result.completed = true
	result.is_encounter_pending = false
	result.post_period_state = get_state()


func _resolve_pending_event(option_id: String) -> PeriodResult:
	var result: PeriodResult = PeriodResult.new()

	if not _pending_event.is_empty():
		var event_id: String = _pending_event.get("id", "")
		var options: Array = _pending_event.get("options", [])

		# Find the selected option
		var selected_option: Dictionary = {}
		for option: Dictionary in options:
			if option.get("id", "") == option_id:
				selected_option = option
				break

		if selected_option.is_empty():
			result.error_message = "Invalid event option '%s' for event '%s'." % [option_id, event_id]
			return result

		var event_resolution: Dictionary = _get_event_resolution(selected_option)
		if event_resolution.has("error"):
			result.error_message = str(event_resolution["error"])
			return result
		var resolved_effects: Dictionary = event_resolution["effects"]
		var event_item_id: String = str(resolved_effects.get("item", ""))
		if not event_item_id.is_empty() and item_shop_system.get_item(event_item_id) == null:
			result.error_message = "Event '%s' references unknown item '%s'." % [
				event_id, event_item_id
			]
			return result

		# Mark event as completed
		if not event_id.is_empty():
			completed_events.append(event_id)

		# Build result
		result.pre_period_state = get_state()
		result.period = calendar.get_turn_number()
		result.year = calendar.get_year()
		result.month = calendar.get_month()
		result.period_num = calendar.get_period()
		result.age = calendar.get_age()
		result.is_diseased_before = stats.is_diseased
		result.activity_type = PeriodResult.ActivityType.EVENT
		result.event_id = event_id
		result.event_name = str(_pending_event.get("name", ""))
		result.event_description = str(_pending_event.get("description", ""))
		result.event_outcome = str(event_resolution.get("outcome", ""))
		result.activity_id = "event_%s" % event_id
		result.activity_level = 1
		result.completed = true

		# Apply effects
		var effects: Dictionary = event_resolution["effects"]

		# Credits
		var income: int = int(effects.get("credits", 0))
		if income > 0:
			economy.receive_income(income)
			result.credits_change += income

		# Stats
		for stat_id: String in ["str", "int", "cha", "ref", "sta"]:
			var delta: int = int(effects.get(stat_id, 0))
			if delta != 0:
				var actual_delta: int = stats.add_stat(stat_id, delta)
				if actual_delta != 0:
					result.stat_changes[stat_id] = actual_delta

		# Ethics (special handling - uses eth key)
		var eth_delta: int = int(effects.get("eth", 0))
		if eth_delta != 0:
			var actual_delta: int = stats.add_ethics(eth_delta)
			if actual_delta != 0:
				result.stat_changes["eth"] = actual_delta

		# Stress
		var stress_delta: int = int(effects.get("stress", 0))
		result.stress_change = stats.add_stress(stress_delta)
		result.stress_final = stats.get_stress()

		if not event_item_id.is_empty():
			if _try_add_item(event_item_id):
				result.items_gained.append(event_item_id)
			else:
				result.inventory_warning_key = "ui.item_loot_nao_guardado"

		# Reputation (handle both short and long keys)
		var reputation_keys: Dictionary = {
			"fighter_rep": "fighter",
			"social_rep": "social",
			"hacker_rep": "hacker"
		}
		for effect_key: String in reputation_keys:
			var delta: int = int(effects.get(effect_key, 0))
			if delta != 0:
				var rep_id: String = str(reputation_keys[effect_key])
				var actual_delta: int = stats.add_reputation(rep_id, delta)
				if actual_delta != 0:
					result.rep_gained[rep_id] = actual_delta

		# Flags
		for key: String in effects:
			if effects[key] is bool and effects[key]:
				_set_campaign_flag(key, true)
				result.flags_set[key] = true

		# Month end processing
		if calendar.is_month_end():
			var month_result: Dictionary = activities.close_month()
			result.month_end_processed = true
			result.streaks_incremented = month_result["streaks_incremented"]
			result.promotion_unlocked = not month_result["promotions"].is_empty()

		stats.check_and_update_disease()
		result.is_diseased_after = stats.is_diseased
		calendar.advance_period()

		post_event_actions()

		var next_year_stipend: int = _credit_stipend_if_due()
		if next_year_stipend > 0:
			result.year_stipend_given = true
			result.credits_change += next_year_stipend

		result.completed = true
		result.post_period_state = get_state()
		_pending_event = {}
		return result

	result.error_message = "No pending event."
	return result


func _get_event_resolution(selected_option: Dictionary) -> Dictionary:
	var effects_data: Variant = selected_option.get("effects", {})
	var requirements: Variant = selected_option.get("requirements", {})
	if not effects_data is Dictionary or not requirements is Dictionary:
		return {"error": "Event option has malformed effects or requirements."}

	var effects: Dictionary = effects_data.duplicate(true)
	var stat_requirements: Variant = requirements.get("stats", {})
	if not stat_requirements is Dictionary:
		return {"error": "Event option has malformed stat requirements."}
	if stat_requirements.is_empty():
		return {"effects": effects, "outcome": ""}

	var requirements_met: bool = true
	for stat_id: Variant in stat_requirements:
		var minimum: Variant = stat_requirements[stat_id]
		if (
			typeof(stat_id) != TYPE_STRING
			or (typeof(minimum) != TYPE_INT and typeof(minimum) != TYPE_FLOAT)
			or not stats.get_base_stats().has(str(stat_id))
		):
			return {"error": "Event option has an invalid stat requirement."}
		if stats.get_stat(str(stat_id)) < int(minimum):
			requirements_met = false

	var outcome_key: String = "success_effects" if requirements_met else "failure_effects"
	var outcome_effects: Variant = selected_option.get(outcome_key, {})
	if not outcome_effects is Dictionary:
		return {"error": "Event option has malformed %s." % outcome_key}
	effects.merge(outcome_effects, true)
	return {
		"effects": effects,
		"outcome": "success" if requirements_met else "failure"
	}


func post_event_actions() -> void:
	pass  # Override in subclasses for additional logic (e.g., inventory management)


func _set_campaign_flag(flag_id: String, value: bool) -> void:
	match flag_id:
		"community_help":
			community_help = value
		"criminal_record":
			criminal_record = value
		"disappear_from_society":
			disappear_from_society = value
		"tech_experiments":
			tech_experiments = value


func _event_flag_granted(flag_id: String) -> void:
	pass  # Override in subclasses for side effects


func get_state() -> Dictionary:
	if not _systems_are_initialized() or not _pending_encounter.is_empty():
		return {}
	return {
		"calendar": calendar.get_calendar_state().to_dict(),
		"stats": stats.get_state(),
		"economy": economy.get_state(),
		"activities": activities.get_state(),
		"events": events.get_state(),
		"completed_events": completed_events.duplicate(),
		"random_event_check_turn": _last_random_event_check_turn,
		"tech_experiments": tech_experiments,
		"criminal_record": criminal_record,
		"community_help": community_help,
		"disappear_from_society": disappear_from_society,
		"missions_technical_completed": _missions_technical_completed,
		"inventory_counts": inventory_counts.duplicate(true),
		"equipment_slots": equipment_slots.duplicate(true)
	}


func load_state(state: Dictionary) -> bool:
	if not _systems_are_initialized() or not _pending_encounter.is_empty():
		return false
	var saved_calendar: Variant = state.get("calendar")
	var saved_stats: Variant = state.get("stats")
	var saved_economy: Variant = state.get("economy")
	var saved_activities: Variant = state.get("activities", {})
	var saved_events: Variant = state.get("events", {})
	var saved_inventory: Variant = state.get("inventory_counts", {})
	var saved_equipment: Variant = state.get("equipment_slots")
	var saved_random_event_check_turn: Variant = state.get("random_event_check_turn", -1)
	if not saved_calendar is Dictionary or not saved_stats is Dictionary:
		return false
	if not saved_economy is Dictionary or not saved_activities is Dictionary:
		return false
	if not saved_inventory is Dictionary:
		return false
	var item_shop_copy: ItemShopSystem = ItemShopSystem.new()
	if not item_shop_copy.load_data(_items_path, _shops_path):
		return false
	var loaded_inventory: Dictionary = {}
	for item_id: Variant in saved_inventory:
		var count: Variant = saved_inventory[item_id]
		if (
			not item_id is String
			or item_shop_copy.get_item(str(item_id)) == null
			or not count is int
			or count < 0
		):
			return false
		if count > 0:
			loaded_inventory[item_id] = count
	var loaded_equipment: Dictionary = _load_equipment_slots(
		saved_equipment, saved_activities, item_shop_copy
	)
	if loaded_equipment.is_empty():
		return false
	var loaded_equipped_ids: Array[String] = _equipment_ids_from_slots(loaded_equipment)
	for item_id: Variant in loaded_inventory:
		var item: ItemDef = item_shop_copy.get_item(str(item_id))
		if item.category != "consumable" and (
			int(loaded_inventory[item_id]) > 1 or loaded_equipped_ids.has(str(item_id))
		):
			return false
	var loaded_item_total: int = _count_inventory_items(loaded_inventory)
	for slot: String in ["hand", "protection"]:
		if not str(loaded_equipment.get(slot, "")).is_empty():
			loaded_item_total += 1
	if loaded_item_total > item_shop_copy.inventory_limit:
		return false
	if not saved_random_event_check_turn is int or saved_random_event_check_turn < -1:
		return false

	var calendar_copy: CalendarSystem = CalendarSystem.new()
	if not calendar_copy.initialize_from_config(_calendar_config_path):
		return false
	var stats_copy: StatsSystem = StatsSystem.new()
	stats_copy.initialize()
	var economy_copy: EconomySystem = EconomySystem.new()
	economy_copy.start_new_game(calendar_copy.years)
	var activities_copy: ActivitySystem = ActivitySystem.new()
	if not activities_copy.load_activities(_activities_path):
		return false
	if not activities_copy.load_missions(_missions_path):
		return false
	if not activities_copy.load_monsters(_monsters_path):
		return false
	if not activities_copy.load_encounter_rules(_encounter_rules_path):
		return false
	var saved_equipped_ids: Variant = saved_activities.get("equipped_item_ids", [])
	if not _same_string_ids(saved_equipped_ids, loaded_equipped_ids):
		return false
	if not calendar_copy.load_state(saved_calendar):
		return false
	if not stats_copy.load_state(saved_stats):
		return false
	if not economy_copy.load_state(saved_economy):
		return false
	if not activities_copy.load_state(saved_activities):
		return false

	calendar = calendar_copy
	stats = stats_copy
	economy = economy_copy
	activities = activities_copy
	item_shop_system = item_shop_copy
	inventory_counts = loaded_inventory
	equipment_slots = loaded_equipment
	_last_random_event_check_turn = saved_random_event_check_turn
	activities.rng = rng
	events.rng = rng
	events.load_state(saved_events)

	var saved_completed: Variant = state.get("completed_events", [])
	if saved_completed is Array:
		completed_events = []
		for id in saved_completed:
			if id is String and not completed_events.has(id):
				completed_events.append(id)

	tech_experiments = bool(state.get("tech_experiments", false))
	criminal_record = bool(state.get("criminal_record", false))
	community_help = bool(state.get("community_help", false))
	disappear_from_society = bool(state.get("disappear_from_society", false))
	var mission_count: Variant = state.get("missions_technical_completed", 0)
	if not mission_count is int or mission_count < 0:
		return false
	_missions_technical_completed = mission_count
	_credit_stipend_if_due()
	return true


func set_equipped_item_ids(item_ids: Array[String]) -> bool:
	if not _systems_are_initialized():
		return false
	var next_slots: Dictionary = {"hand": "", "protection": ""}
	for item_id: String in item_ids:
		var item: ItemDef = item_shop_system.get_item(item_id)
		if item == null or item.slot not in ["hand", "protection"]:
			return false
		if not str(next_slots[item.slot]).is_empty():
			return false
		if get_item_count(item_id) <= 0 and not _equipment_ids_from_slots(equipment_slots).has(item_id):
			return false
		next_slots[item.slot] = item_id

	var next_inventory: Dictionary = inventory_counts.duplicate(true)
	for slot: String in ["hand", "protection"]:
		var previous_id: String = str(equipment_slots.get(slot, ""))
		var next_id: String = str(next_slots[slot])
		if previous_id == next_id:
			continue
		if not previous_id.is_empty():
			next_inventory[previous_id] = get_item_count(previous_id) + 1
		if not next_id.is_empty():
			var count: int = int(next_inventory.get(next_id, 0))
			if count <= 0:
				return false
			next_inventory[next_id] = count - 1
			if int(next_inventory[next_id]) == 0:
				next_inventory.erase(next_id)
	var next_ids: Array[String] = _equipment_ids_from_slots(next_slots)
	if not activities.set_equipped_item_ids(next_ids):
		return false
	equipment_slots = next_slots
	inventory_counts = next_inventory
	return true


func get_equipped_item_ids() -> Array[String]:
	return _equipment_ids_from_slots(equipment_slots)


func get_item_count(item_id: String) -> int:
	return int(inventory_counts.get(item_id, 0))


func get_item(item_id: String) -> ItemDef:
	return item_shop_system.get_item(item_id) if item_shop_system != null else null


func get_item_shops() -> Array[Dictionary]:
	return item_shop_system.get_shops() if item_shop_system != null else []


func get_shop_item_ids(shop_id: String) -> Array[String]:
	var shop: Dictionary = item_shop_system.get_shop(shop_id) if item_shop_system != null else {}
	var raw_items: Variant = shop.get("items", [])
	var item_ids: Array[String] = []
	if raw_items is Array:
		for item_id: Variant in raw_items:
			if item_id is String:
				item_ids.append(item_id)
	return item_ids


func get_inventory_used_count() -> int:
	var total: int = _count_inventory_items(inventory_counts)
	for slot: String in ["hand", "protection"]:
		if not str(equipment_slots.get(slot, "")).is_empty():
			total += 1
	return total


func get_inventory_limit() -> int:
	return item_shop_system.inventory_limit if item_shop_system != null else 0


func get_equipped_item(slot: String) -> String:
	if slot not in ["hand", "protection"]:
		push_error("Unknown equipment slot '%s'." % slot)
		return ""
	return str(equipment_slots.get(slot, ""))


func buy_item(item_id: String) -> Dictionary:
	if not _systems_are_initialized():
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	var item: ItemDef = item_shop_system.get_item(item_id)
	if item == null:
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	var shop: Dictionary = item_shop_system.get_shop(item.shop_type)
	if not get_shop_item_ids(item.shop_type).has(item_id):
		return {"success": false, "error_key": "ui.item_nao_disponivel"}
	if not item.requirements.is_empty():
		return {"success": false, "error_key": "ui.item_requisito_nao_atendido"}
	if item.category != "consumable" and _owns_item(item_id):
		return {"success": false, "error_key": "ui.item_ja_possuido"}
	if get_inventory_used_count() >= get_inventory_limit():
		return {
			"success": false,
			"error_key": "ui.item_inventario_cheio",
			"limit": get_inventory_limit()
		}
	if not economy.can_afford(item.cost):
		return {
			"success": false,
			"error_key": "ui.item_creditos_insuficientes_format",
			"available": economy.get_credits(),
			"cost": item.cost
		}
	if not economy.pay(item.cost):
		push_error("Item purchase could not debit its validated price.")
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	inventory_counts[item_id] = get_item_count(item_id) + 1
	return {
		"success": true,
		"error_key": "",
		"item_id": item_id,
		"cost": item.cost,
		"credits": economy.get_credits(),
		"shop_id": str(shop.get("id", ""))
	}


func use_item(item_id: String) -> Dictionary:
	if not _systems_are_initialized():
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	var item: ItemDef = item_shop_system.get_item(item_id)
	if item == null:
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	if item.category != "consumable":
		return {"success": false, "error_key": "ui.item_nao_utilizavel"}
	if get_item_count(item_id) <= 0:
		return {"success": false, "error_key": "ui.item_nao_possuido"}
	var effect_type: String = str(item.effect_data.get("type", ""))
	var effect_value: Variant = item.effect_data.get("value")
	if (
		effect_type != "stress_recovery"
		or not _is_number(effect_value)
		or int(effect_value) <= 0
		or float(effect_value) != float(int(effect_value))
	):
		push_error("Consumable '%s' has invalid recovery data." % item_id)
		return {"success": false, "error_key": "ui.item_nao_utilizavel"}
	var stress_change: int = stats.add_stress(-int(effect_value))
	stats.check_and_update_disease()
	_decrement_item_count(item_id)
	return {
		"success": true,
		"error_key": "",
		"item_id": item_id,
		"stress_change": stress_change,
		"stress": stats.get_stress()
	}


func equip_item(item_id: String) -> Dictionary:
	if not _systems_are_initialized():
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	var item: ItemDef = item_shop_system.get_item(item_id)
	if item == null:
		return {"success": false, "error_key": "ui.item_nao_encontrado"}
	if item.slot not in ["hand", "protection"]:
		return {"success": false, "error_key": "ui.item_nao_equipavel"}
	if get_item_count(item_id) <= 0:
		return {"success": false, "error_key": "ui.item_nao_possuido"}
	if get_equipped_item(item.slot) == item_id:
		return {"success": false, "error_key": "ui.item_ja_equipado"}

	var next_slots: Dictionary = equipment_slots.duplicate(true)
	var previous_item_id: String = str(next_slots[item.slot])
	next_slots[item.slot] = item_id
	var next_inventory: Dictionary = inventory_counts.duplicate(true)
	var incoming_count: int = int(next_inventory.get(item_id, 0)) - 1
	if incoming_count > 0:
		next_inventory[item_id] = incoming_count
	else:
		next_inventory.erase(item_id)
	if not previous_item_id.is_empty():
		next_inventory[previous_item_id] = int(next_inventory.get(previous_item_id, 0)) + 1
	if not activities.set_equipped_item_ids(_equipment_ids_from_slots(next_slots)):
		return {"success": false, "error_key": "ui.item_nao_equipavel"}
	equipment_slots = next_slots
	inventory_counts = next_inventory
	return {
		"success": true,
		"error_key": "",
		"item_id": item_id,
		"previous_item_id": previous_item_id,
		"slot": item.slot
	}


func unequip_item(slot: String) -> Dictionary:
	if not _systems_are_initialized() or slot not in ["hand", "protection"]:
		return {"success": false, "error_key": "ui.item_slot_ja_vazio"}
	var item_id: String = str(equipment_slots.get(slot, ""))
	if item_id.is_empty():
		return {"success": false, "error_key": "ui.item_slot_ja_vazio"}
	var next_slots: Dictionary = equipment_slots.duplicate(true)
	next_slots[slot] = ""
	if not activities.set_equipped_item_ids(_equipment_ids_from_slots(next_slots)):
		return {"success": false, "error_key": "ui.item_nao_equipavel"}
	equipment_slots = next_slots
	inventory_counts[item_id] = get_item_count(item_id) + 1
	return {"success": true, "error_key": "", "item_id": item_id, "slot": slot}


func _owns_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0 or get_equipped_item_ids().has(item_id)


func _try_add_item(item_id: String) -> bool:
	if item_shop_system == null or item_shop_system.get_item(item_id) == null:
		return false
	if get_inventory_used_count() >= get_inventory_limit():
		return false
	inventory_counts[item_id] = get_item_count(item_id) + 1
	return true


func _decrement_item_count(item_id: String) -> void:
	var next_count: int = get_item_count(item_id) - 1
	if next_count > 0:
		inventory_counts[item_id] = next_count
	else:
		inventory_counts.erase(item_id)


func _count_inventory_items(items: Dictionary) -> int:
	var total: int = 0
	for item_id: Variant in items:
		total += int(items[item_id])
	return total


func _equipment_ids_from_slots(slots: Dictionary) -> Array[String]:
	var item_ids: Array[String] = []
	for slot: String in ["hand", "protection"]:
		var item_id: String = str(slots.get(slot, ""))
		if not item_id.is_empty():
			item_ids.append(item_id)
	return item_ids


func _load_equipment_slots(
	saved_equipment: Variant,
	saved_activities: Dictionary,
	item_system: ItemShopSystem
) -> Dictionary:
	var slots: Dictionary = {"hand": "", "protection": ""}
	if saved_equipment is Dictionary:
		for slot: String in ["hand", "protection"]:
			var item_id: Variant = saved_equipment.get(slot, "")
			if not item_id is String:
				return {}
			if str(item_id).is_empty():
				continue
			var item: ItemDef = item_system.get_item(str(item_id))
			if item == null or item.slot != slot:
				return {}
			slots[slot] = str(item_id)
		for slot: Variant in saved_equipment:
			if not ["hand", "protection"].has(str(slot)):
				return {}
		return slots

	var legacy_ids: Variant = saved_activities.get("equipped_item_ids", [])
	if not legacy_ids is Array:
		return {}
	for item_id: Variant in legacy_ids:
		if not item_id is String:
			return {}
		var item: ItemDef = item_system.get_item(str(item_id))
		if item == null or item.slot not in ["hand", "protection"]:
			return {}
		if not str(slots[item.slot]).is_empty():
			return {}
		slots[item.slot] = item.id
	return slots


func _same_string_ids(saved_ids: Variant, expected_ids: Array[String]) -> bool:
	if not saved_ids is Array or saved_ids.size() != expected_ids.size():
		return false
	for item_id: Variant in saved_ids:
		if not item_id is String or not expected_ids.has(item_id):
			return false
	return true


func is_campaign_complete() -> bool:
	return calendar != null and calendar.is_campaign_complete()


func get_age() -> int:
	return calendar.get_age() if calendar != null else 12


func get_remaining_periods() -> int:
	return calendar.get_remaining_periods() if calendar != null else 0


func get_available_activities() -> Dictionary:
	if not _systems_are_initialized():
		return {"study": [], "work": [], "mission": [], "leisure": []}
	var available_missions: Array[String] = []
	if not stats.is_mission_blocked_by_disease():
		available_missions = activities.get_available_missions()
	return {
		"study": activities.get_available_courses(),
		"work": activities.get_available_tasks(),
		"mission": available_missions,
		"leisure": activities.get_available_leisure()
	}


func is_mission_available() -> bool:
	return _systems_are_initialized() and not stats.is_mission_blocked_by_disease()


func get_mission_availability_error(mission_id: String) -> String:
	if not _systems_are_initialized():
		return "SimulationCore must be initialized before checking missions."
	if stats.is_mission_blocked_by_disease():
		return "Missions are unavailable while diseased."
	return activities.get_mission_availability_error(mission_id, stats.get_base_stats())


func _credit_stipend_if_due() -> int:
	if not _systems_are_initialized() or not calendar.is_new_year_period():
		return 0
	var stipend_status: Dictionary = economy.get_stipend_status(calendar.get_year())
	if not bool(stipend_status["eligible"]):
		return 0

	var stipend: int = economy.start_year(calendar.get_year())
	if stipend <= 0:
		return 0
	if not economy.receive_income(stipend):
		push_error("Could not credit the yearly stipend for year %d." % calendar.get_year())
		return 0
	return stipend


func get_upcoming_fixed_event() -> Dictionary:
	var year: int = calendar.get_year()
	var month: int = calendar.get_month()
	var period: int = calendar.get_period()
	return events.get_fixed_event_for_date(year, month, period)


func roll_for_random_event() -> Dictionary:
	var max_attr: int = max(
		stats.get_stat("int"),
		max(stats.get_stat("cha"), stats.get_stat("ref"))
	)
	return events.roll_random_event(max_attr)


func get_completed_events() -> Array[String]:
	return completed_events.duplicate()


func is_event_completed(event_id: String) -> bool:
	return completed_events.has(event_id)


func get_pending_event() -> Dictionary:
	return _pending_event.duplicate()


func has_pending_event() -> bool:
	return not _pending_event.is_empty()


func get_pending_encounter() -> Dictionary:
	if _pending_encounter.is_empty():
		return {}
	return _pending_encounter.duplicate(true)


func has_pending_encounter() -> bool:
	return not _pending_encounter.is_empty()


## Finalizes one original period as specified in design/gdd/auto-combat.md.
func resolve_pending_encounter(option: int) -> PeriodResult:
	if _pending_encounter.is_empty() or _pending_encounter_result == null:
		var error_result: PeriodResult = PeriodResult.new()
		error_result.error_message = "No pending encounter."
		return error_result

	var monster_id: String = str(_pending_encounter.get("encounter_monster_id", ""))
	var encounter_result: Dictionary = activities.resolve_encounter(
		option, monster_id, stats.get_base_stats()
	)
	if encounter_result.has("error"):
		return _encounter_resolution_error(str(encounter_result["error"]))
	if (
		not encounter_result.get("success") is bool
		or not encounter_result.get("success_chance") is int
		or not encounter_result.get("stress_delta") is int
		or not encounter_result.get("success_effects") is Dictionary
	):
		return _encounter_resolution_error("Encounter resolution returned malformed data.")

	var succeeded: bool = bool(encounter_result["success"])
	var effects: Dictionary = encounter_result["success_effects"]
	if succeeded and not _mission_effects_are_valid(effects):
		return _encounter_resolution_error("Encounter rewards are malformed.")

	var result: PeriodResult = _pending_encounter_result
	result.mission_success = succeeded
	result.success_chance = int(encounter_result["success_chance"])
	result.stress_change = stats.add_stress(int(encounter_result["stress_delta"]))
	result.stress_final = stats.get_stress()
	result.encounter_description = str(
		_pending_encounter.get("encounter_monster_description", "")
	)
	if succeeded:
		_apply_mission_effects(effects, result)
		var item_id: String = activities.roll_encounter_item_drop(option)
		if not item_id.is_empty():
			if _try_add_item(item_id):
				result.items_gained.append(item_id)
			else:
				result.inventory_warning_key = "ui.item_loot_nao_guardado"
	else:
		result.encounter_orac_returned = true
		result.encounter_description = activities.get_orac_return_description()

	_pending_encounter.clear()
	_complete_period(result)
	_pending_encounter_result = null
	return result


func _encounter_resolution_error(message: String) -> PeriodResult:
	var error_result: PeriodResult = PeriodResult.new()
	if _pending_encounter_result != null:
		error_result.period = _pending_encounter_result.period
		error_result.year = _pending_encounter_result.year
		error_result.month = _pending_encounter_result.month
		error_result.period_num = _pending_encounter_result.period_num
		error_result.age = _pending_encounter_result.age
		error_result.activity_type = _pending_encounter_result.activity_type
		error_result.activity_id = _pending_encounter_result.activity_id
		error_result.encounter_monster_id = _pending_encounter_result.encounter_monster_id
		error_result.encounter_monster_name = _pending_encounter_result.encounter_monster_name
	error_result.is_encounter_pending = not _pending_encounter.is_empty()
	error_result.error_message = message
	return error_result


func _mission_effects_are_valid(effects: Dictionary) -> bool:
	var numeric_keys: Array[String] = [
		"credits", "str", "int", "cha", "ref", "sta", "eth",
		"fighter_rep", "social_rep", "hacker_rep", "missoes_tecnicas_concluidas"
	]
	for key: String in numeric_keys:
		if effects.has(key) and not _is_number(effects[key]):
			return false
	for flag_id: String in [
		"community_help", "criminal_record", "disappear_from_society", "tech_experiments"
	]:
		if effects.has(flag_id) and not effects[flag_id] is bool:
			return false
	return true


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _parse_choice(choice: String) -> Dictionary:
	var separator: int = choice.find("_")
	if separator <= 0 or separator == choice.length() - 1:
		return {"error": "Invalid choice '%s'; expected type_ID[_lN][_experiment]." % choice}
	var activity_type: String = choice.substr(0, separator)
	var activity_id: String = choice.substr(separator + 1)
	var experiment: bool = false
	if activity_id.ends_with("_experiment"):
		experiment = true
		activity_id = activity_id.trim_suffix("_experiment")

	var requested_level: int = 0
	var level_marker: int = activity_id.rfind("_l")
	if level_marker >= 0 and level_marker + 3 == activity_id.length():
		var level_text: String = activity_id.substr(level_marker + 2, 1)
		if level_text.is_valid_int():
			requested_level = int(level_text)
			activity_id = activity_id.substr(0, level_marker)

	if activity_type not in ["study", "work", "mission", "leisure"]:
		return {"error": "Unknown activity type '%s'." % activity_type}
	if activity_id.is_empty():
		return {"error": "Activity ID cannot be empty."}
	return {
		"type": activity_type,
		"id": activity_id,
		"level": requested_level,
		"experiment": experiment
	}


func _resolve_activity(parsed_choice: Dictionary) -> Dictionary:
	var activity_type: String = str(parsed_choice["type"])
	var activity_id: String = str(parsed_choice["id"])
	var requested_level: int = int(parsed_choice["level"])
	if activity_type == "study":
		var course: Dictionary = activities.get_course(activity_id)
		if course.is_empty():
			return {"error": "Unknown study course '%s'." % activity_id}
		var level: int = requested_level if requested_level > 0 else activities.get_course_level(activity_id)
		if level > activities.get_course_level(activity_id):
			return {"error": "Study level %d is locked for '%s'." % [level, activity_id]}
		return activities.execute_study(activity_id, level)
	if activity_type == "work":
		var task: Dictionary = activities.get_course(activity_id)
		if task.is_empty():
			return {"error": "Unknown work task '%s'." % activity_id}
		var level: int = activities.get_job_level(activity_id)
		if requested_level > 0 and requested_level != level:
			return {"error": "Work task '%s' is currently level %d." % [activity_id, level]}
		return activities.execute_work(activity_id, level)
	if activity_type == "mission":
		if not activities.get_mission(activity_id).is_empty():
			return activities.resolve_mission(activity_id, stats.get_base_stats())
		return {"error": "Unknown mission '%s'." % activity_id}
	return activities.execute_leisure(activity_id)


func _apply_activity_effects(
	parsed_choice: Dictionary, activity_result: Dictionary, result: PeriodResult
) -> void:
	var activity_type: String = str(parsed_choice["type"])
	var activity_id: String = str(activity_result["activity_id"])
	var stat_gains: Variant = activity_result.get("stat_gains", {})
	if stat_gains is Dictionary:
		for stat_id: String in stat_gains:
			var actual_delta: int = stats.add_stat(stat_id, int(stat_gains[stat_id]))
			if actual_delta != 0:
				result.stat_changes[stat_id] = actual_delta

	var requested_stress: int = int(activity_result.get("stress_delta", 0))
	result.stress_change = stats.add_stress(requested_stress)
	result.stress_final = stats.get_stress()

	if activity_type == "study":
		var xp_awarded: int = activities.add_course_xp(
			activity_id, int(activity_result.get("xp_gain", ActivitySystem.XP_PER_SESSION))
		)
		result.xp_gained[activity_id] = xp_awarded
		if bool(parsed_choice["experiment"]) and activity_id == "curso_tecnologia":
			tech_experiments = true
			result.flags_set["tech_experiments"] = true
	elif activity_type == "work":
		activities.mark_task_used(activity_id)
	elif activity_type == "mission":
		var effects: Dictionary = activity_result.get("success_effects", {})
		if bool(activity_result.get("success", false)):
			_apply_mission_effects(effects, result)
			if bool(parsed_choice["experiment"]) and activity_id == "missao_tecnica":
				tech_experiments = true
				result.flags_set["tech_experiments"] = true


func _apply_mission_effects(effects: Dictionary, result: PeriodResult) -> void:
	var credits: int = int(effects.get("credits", 0))
	if credits > 0 and economy.receive_income(credits):
		result.credits_change += credits
	for stat_id: String in ["str", "int", "cha", "ref", "sta"]:
		var delta: int = int(effects.get(stat_id, 0))
		if delta != 0:
			var actual_delta: int = stats.add_stat(stat_id, delta)
			if actual_delta != 0:
				result.stat_changes[stat_id] = int(result.stat_changes.get(stat_id, 0)) + actual_delta
	var eth_delta: int = int(effects.get("eth", 0))
	if eth_delta != 0:
		result.eth_change = stats.add_ethics(eth_delta)
	var reputation_keys: Dictionary = {
		"fighter_rep": "fighter",
		"social_rep": "social",
		"hacker_rep": "hacker"
	}
	for effect_key: String in reputation_keys:
		var delta: int = int(effects.get(effect_key, 0))
		if delta != 0:
			var reputation_id: String = str(reputation_keys[effect_key])
			var actual_delta: int = stats.add_reputation(reputation_id, delta)
			if actual_delta != 0:
				result.rep_gained[reputation_id] = actual_delta
	var technical_mission_delta: int = int(effects.get("missoes_tecnicas_concluidas", 0))
	if technical_mission_delta > 0:
		_missions_technical_completed += technical_mission_delta
		activities.add_technical_mission_count(technical_mission_delta)
		result.mission_count += technical_mission_delta
	for flag_id: String in ["community_help", "criminal_record", "disappear_from_society", "tech_experiments"]:
		if bool(effects.get(flag_id, false)):
			_set_campaign_flag(flag_id, true)
			result.flags_set[flag_id] = true


func _systems_are_initialized() -> bool:
	return (
		calendar != null
		and stats != null
		and economy != null
		and activities != null
		and item_shop_system != null
		and events != null
	)


func _reset_campaign_flags() -> void:
	tech_experiments = false
	criminal_record = false
	community_help = false
	disappear_from_society = false
	_missions_technical_completed = 0
	_pending_event = {}


# Returns a dictionary with the current state relevant for ending evaluation.
# Used by EndingEvaluator and balance-run tools.
func get_ending_state() -> Dictionary:
	if not _systems_are_initialized() or not _pending_encounter.is_empty():
		return {}
	var stats_state: Dictionary = stats.get_state()
	return {
		"stats": stats_state.get("stats", {}),
		"reputations": stats_state.get("reputations", {"hacker": 0, "social": 0, "fighter": 0}),
		"tech_experiments": tech_experiments,
		"criminal_record": criminal_record,
		"community_help": community_help,
		"disappear_from_society": disappear_from_society,
		"missions_technical_completed": _missions_technical_completed
	}