extends Node
class_name GameManager

signal game_started
signal game_saved
signal game_loaded
signal game_over(ending_type: String)
signal state_changed(previous_state: int, new_state: int)
signal campaign_return_requested

enum GameState {
	BOOT,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	TRANSITION,
	GAME_OVER
}

var current_state: GameState = GameState.BOOT
var simulation: SimulationCore


func _ready() -> void:
	transition_to(GameState.MAIN_MENU)


func start_new_game(character_name: String = "Nyx Volt", guardian_name: String = "ORAC") -> bool:
	var new_simulation: SimulationCore = SimulationCore.new()
	if not new_simulation.initialize():
		push_error("Could not initialize a new campaign simulation.")
		return false

	Data.initialize_new_save(character_name, guardian_name)
	var saved_character: Dictionary = Data.get_current_data().get("character", {})
	new_simulation.character_name = str(saved_character.get("name", "Nyx Volt"))
	simulation = new_simulation
	if not _capture_simulation_state():
		return false
	if not Data.save_autosave():
		return false
	transition_to(GameState.PLAYING)
	game_started.emit()
	return true


func save_game(slot: int) -> bool:
	if not _capture_simulation_state():
		return false
	var saved: bool = Data.save_current(slot)
	if saved:
		game_saved.emit()
		EventBus.game_saved.emit()
	return saved


func load_game(slot: int) -> bool:
	if not Data.load_slot(slot):
		return false
	return _restore_loaded_campaign()


func load_save_id(save_id: String) -> bool:
	if not Data.load_save_id(save_id):
		return false
	return _restore_loaded_campaign()


func autosave_completed_period(month_ended: bool) -> bool:
	if not _capture_simulation_state():
		return false
	if not Data.save_autosave():
		return false
	if month_ended and not Data.save_monthly_snapshot():
		return false
	return true


func save_checkpoint(flow_state: Dictionary, month_ended: bool) -> bool:
	if not _capture_simulation_state():
		return false
	if not Data.set_flow_state(flow_state):
		return false
	return autosave_completed_period(month_ended)


func return_to_title() -> void:
	transition_to(GameState.MAIN_MENU)
	campaign_return_requested.emit()


func _restore_loaded_campaign() -> bool:
	var save_data: Dictionary = Data.get_current_data()
	var simulation_state: Variant = save_data.get("simulation", {})
	var restored: SimulationCore = SimulationCore.new()
	if not restored.initialize():
		push_error("Could not initialize simulation while loading a campaign.")
		return false

	if simulation_state is Dictionary and not simulation_state.is_empty():
		var hydrated_state: Dictionary = simulation_state.duplicate(true)
		var saved_calendar: Variant = hydrated_state.get("calendar", {})
		var saved_progress: Variant = save_data.get("progress", {})
		var saved_rng_state: Variant = save_data.get("rng_state", null)
		if not saved_calendar is Dictionary or not saved_progress is Dictionary:
			push_error("Saved campaign is missing its calendar or progress data.")
			return false
		var turns_completed: Variant = saved_progress.get("turns_completed", null)
		if not turns_completed is int or not saved_rng_state is int:
			push_error("Saved campaign has invalid calendar or RNG data.")
			return false
		saved_calendar["completed_periods"] = turns_completed
		hydrated_state["calendar"] = saved_calendar
		hydrated_state["rng_state"] = saved_rng_state
		if not restored.load_state(hydrated_state):
			push_error("Saved simulation state is invalid; the save file was left unchanged.")
			return false
	else:
		if not _restore_legacy_campaign(restored, save_data):
			push_error("Legacy save could not be restored; the save file was left unchanged.")
			return false

	var character_value: Variant = save_data.get("character", {})
	if character_value is Dictionary:
		restored.character_name = str(character_value.get("name", "Nyx Volt"))
	simulation = restored
	if not _capture_simulation_state():
		return false
	transition_to(GameState.PLAYING)
	game_loaded.emit()
	EventBus.game_loaded.emit()
	return true


func _restore_legacy_campaign(restored: SimulationCore, save_data: Dictionary) -> bool:
	var character_value: Variant = save_data.get("character", {})
	var progress_value: Variant = save_data.get("progress", {})
	if not character_value is Dictionary or not progress_value is Dictionary:
		return false
	var character: Dictionary = character_value
	var progress: Dictionary = progress_value
	var state: Dictionary = restored.get_state()
	var calendar: Dictionary = state.get("calendar", {})
	var turns: int = int(progress.get("turns_completed", 0))
	if turns < 0 or turns > 108:
		return false
	calendar["completed_periods"] = turns
	state["calendar"] = calendar

	var stats_state: Dictionary = state.get("stats", {})
	var old_stats: Variant = character.get("stats", {})
	if old_stats is Dictionary:
		var stats: Dictionary = stats_state.get("stats", {})
		var stat_keys: Dictionary = {
			"STR": "str", "INT": "int", "CHA": "cha",
			"REF": "ref", "STA": "sta", "ETH": "eth"
		}
		for old_key: String in stat_keys:
			if old_stats.has(old_key):
				stats[str(stat_keys[old_key])] = old_stats[old_key]
		stats_state["stats"] = stats
	stats_state["stress"] = character.get("stress", 0)
	var old_reputations: Variant = character.get(
		"reputation", save_data.get("reputation", {})
	)
	if old_reputations is Dictionary:
		var reputations: Dictionary = stats_state.get("reputations", {})
		var reputation_keys: Dictionary = {
			"fighter": ["fighter", "FighterRep"],
			"social": ["social", "SocialRep"],
			"hacker": ["hacker", "HackerRep"]
		}
		for reputation_id: String in reputation_keys:
			for key: String in reputation_keys[reputation_id]:
				if old_reputations.has(key):
					reputations[reputation_id] = old_reputations[key]
					break
		stats_state["reputations"] = reputations
	state["stats"] = stats_state

	var economy: Dictionary = state.get("economy", {})
	economy["credits"] = character.get("credits", 200)
	var current_year: int = mini(turns / 36 + 1, 3)
	economy["current_year"] = current_year
	var stipends: Array = economy.get("years_stipend_given", [])
	for index: int in stipends.size():
		stipends[index] = index < current_year
	economy["years_stipend_given"] = stipends
	state["economy"] = economy

	var flags: Variant = character.get("flags", save_data.get("flags", {}))
	if flags is Dictionary:
		for flag_id: String in [
			"tech_experiments", "criminal_record", "community_help", "disappear_from_society"
		]:
			state[flag_id] = bool(flags.get(flag_id, false))

	var old_events: Variant = save_data.get("events", {})
	var legacy_completed_events: Variant = []
	if old_events is Dictionary:
		legacy_completed_events = old_events.get("completed", [])
	var completed_events: Variant = progress.get(
		"completed_fixed_event_ids", legacy_completed_events
	)
	if completed_events is Array:
		state["completed_events"] = completed_events.duplicate()
	return restored.load_state(state)


func _capture_simulation_state() -> bool:
	if simulation == null:
		push_error("Cannot save because there is no active simulation.")
		return false
	var character_value: Variant = Data.get_current_data().get("character", {})
	if character_value is Dictionary:
		var character: Dictionary = character_value
		character["name"] = simulation.character_name
		character["age"] = simulation.get_age()
		character["credits"] = simulation.economy.get_credits()
		character["stats"] = {
			"STR": simulation.stats.get_stat("str"),
			"INT": simulation.stats.get_stat("int"),
			"CHA": simulation.stats.get_stat("cha"),
			"REF": simulation.stats.get_stat("ref"),
			"STA": simulation.stats.get_stat("sta"),
			"ETH": simulation.stats.get_stat("eth")
		}
		character["stress"] = simulation.stats.get_stress()
		character["reputation"] = {
			"fighter": simulation.stats.get_reputation("fighter"),
			"social": simulation.stats.get_reputation("social"),
			"hacker": simulation.stats.get_reputation("hacker")
		}
		character["flags"] = {
			"community_help": simulation.community_help,
			"criminal_record": simulation.criminal_record,
			"tech_experiments": simulation.tech_experiments,
			"disappear_from_society": simulation.disappear_from_society
		}
		var inventory_items: Array[Dictionary] = []
		for item_id: Variant in simulation.inventory_counts:
			inventory_items.append({
				"id": str(item_id),
				"count": int(simulation.inventory_counts[item_id])
			})
		character["inventory"] = {
			"items": inventory_items,
			"equipped_hand": _optional_item_id(simulation.equipment_slots.get("hand", "")),
			"equipped_protection": _optional_item_id(
				simulation.equipment_slots.get("protection", "")
			)
		}
		Data.set_data(_with_character_data(Data.get_current_data(), character))
	return Data.set_simulation_state(simulation.get_state())


func _optional_item_id(item_id: Variant) -> Variant:
	var item_id_string: String = str(item_id)
	return item_id_string if not item_id_string.is_empty() else null


func _with_character_data(save_data: Dictionary, character: Dictionary) -> Dictionary:
	var result: Dictionary = save_data.duplicate(true)
	result["character"] = character.duplicate(true)
	return result


func transition_to(new_state: GameState) -> void:
	if current_state == new_state:
		return
	var previous_state: GameState = current_state
	current_state = new_state
	state_changed.emit(previous_state, new_state)


func quit_game() -> void:
	EventBus.game_quit.emit()
	get_tree().quit()


func is_transitioning() -> bool:
	return current_state == GameState.TRANSITION