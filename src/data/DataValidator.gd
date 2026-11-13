class_name DataValidator
extends RefCounted

const STAT_IDS: Array[String] = ["str", "int", "cha", "ref", "sta", "eth"]
const REPUTATION_IDS: Array[String] = ["fighter", "social", "hacker"]


static func validate_all(data: DataLoader) -> Array[String]:
	var errors: Array[String] = []
	if data.schema_version != DataLoader.SUPPORTED_SCHEMA_VERSION:
		errors.append(
			"schema_version: unsupported version %d; expected %d."
			% [data.schema_version, DataLoader.SUPPORTED_SCHEMA_VERSION]
		)

	errors.append_array(validate_unique_ids(data.stats, "stats"))
	errors.append_array(validate_unique_ids(data.activities, "activities"))
	errors.append_array(validate_unique_ids(data.items, "items"))
	errors.append_array(validate_unique_ids(data.events + data.random_events, "events"))
	errors.append_array(validate_unique_ids(data.endings, "endings"))
	errors.append_array(validate_unique_ids(data.missions, "missions"))
	errors.append_array(validate_stats_ranges(data.stats))
	errors.append_array(validate_calendar_structure(data.calendar))
	errors.append_array(validate_activity_gains(data.activities))
	errors.append_array(validate_events(data.events, data.random_events, data.items))
	errors.append_array(validate_endings(data.endings))
	errors.append_array(validate_missions(data.missions))
	return errors


static func validate_unique_ids(items: Array, type_name: String) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for index in items.size():
		var id: String = _item_id(items[index])
		if id.is_empty():
			errors.append("%s[%d]: missing or empty ID." % [type_name, index])
		elif seen.has(id):
			errors.append("%s: duplicate ID '%s'." % [type_name, id])
		else:
			seen[id] = true
	return errors


static func validate_stats_ranges(stats: Array) -> Array[String]:
	var errors: Array[String] = []
	var found_ids: Dictionary = {}
	for index in stats.size():
		var stat: Variant = stats[index]
		if not stat is Dictionary:
			errors.append("stats[%d]: expected an object." % index)
			continue

		var id: String = str(stat.get("id", ""))
		if id.is_empty():
			errors.append("stats[%d]: missing or empty ID." % index)
			continue
		found_ids[id] = true

		var minimum: Variant = stat.get("min")
		var maximum: Variant = stat.get("max")
		var starting: Variant = stat.get("start")
		if not _is_number(minimum) or not _is_number(maximum) or not _is_number(starting):
			errors.append("stats[%s]: min, max and start must be numeric." % id)
			continue
		if minimum > maximum:
			errors.append("stats[%s]: min is greater than max." % id)
		if starting < minimum or starting > maximum:
			errors.append("stats[%s]: start is outside [%s, %s]." % [id, minimum, maximum])

	for id in STAT_IDS:
		if not found_ids.has(id):
			errors.append("stats: missing required attribute '%s'." % id)
	return errors


static func validate_calendar_structure(calendar: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["years", "months", "periods"]:
		if not calendar.has(key) or not _is_number(calendar.get(key)):
			errors.append("calendar: missing or non-numeric '%s'." % key)
	if errors.is_empty():
		if int(calendar["years"]) != 3:
			errors.append("calendar: expected 3 years, got %s." % calendar["years"])
		if int(calendar["months"]) != 12:
			errors.append("calendar: expected 12 months, got %s." % calendar["months"])
		if int(calendar["periods"]) != 3:
			errors.append("calendar: expected 3 periods per month, got %s." % calendar["periods"])
	return errors


static func validate_activity_gains(activities: Array) -> Array[String]:
	var errors: Array[String] = []
	for activity in activities:
		if not activity is ActivityDef:
			errors.append("activities: expected ActivityDef records.")
			continue
		if activity.id.is_empty():
			continue
		if activity.type == "study":
			for level in ["l1", "l2", "l3"]:
				var level_gains: Variant = activity.gains.get(level)
				if not level_gains is Dictionary:
					errors.append("activities: '%s' gains.%s must be an object." % [activity.id, level])
					continue
				if level_gains.is_empty():
					errors.append("activities: '%s' gains.%s cannot be empty." % [activity.id, level])
				for stat_id in level_gains:
					if not STAT_IDS.has(str(stat_id)):
						errors.append(
							"activities: '%s' gains.%s references unknown stat '%s'."
							% [activity.id, level, stat_id]
						)
					elif not _is_number(level_gains[stat_id]):
						errors.append(
							"activities: '%s' gains.%s.%s must be numeric."
							% [activity.id, level, stat_id]
						)
		if activity.type == "work":
			if activity.gains.is_empty():
				errors.append("activities: work '%s' has no gains." % activity.id)
			if activity.income_l1 <= 0 or activity.income_l2 <= 0:
				errors.append("activities: work '%s' must define both salary levels." % activity.id)
	return errors


static func validate_events(
	events: Array, random_events: Array, items: Array
) -> Array[String]:
	var errors: Array[String] = []
	var item_ids: Dictionary = {}
	for item in items:
		item_ids[_item_id(item)] = true

	for event in events + random_events:
		if not event is EventDef:
			errors.append("events: expected EventDef records.")
			continue
		if event.id.is_empty():
			continue
		if event.options.size() < 2:
			errors.append("events: '%s' must have at least two options." % event.id)
		if events.has(event):
			if event.year < 1 or event.year > 3 or not [3, 6, 9, 12].has(event.month) or event.period != 3:
				errors.append("events: '%s' is outside the fixed event schedule." % event.id)
		for option_index in event.options.size():
			var option: Variant = event.options[option_index]
			if not option is Dictionary:
				errors.append("events: '%s' option %d must be an object." % [event.id, option_index])
				continue
			var effects: Variant = option.get("effects", {})
			if not effects is Dictionary:
				errors.append("events: '%s' option %d effects must be an object." % [event.id, option_index])
				continue
			var item_id: String = str(effects.get("item", ""))
			if not item_id.is_empty() and not item_ids.has(item_id):
				errors.append("events: '%s' references unknown item '%s'." % [event.id, item_id])

	if events.size() != 12:
		errors.append("events: expected 12 fixed events, got %d." % events.size())
	if random_events.size() != 3:
		errors.append("random_events: expected 3 encounters, got %d." % random_events.size())
	return errors


static func validate_endings(endings: Array) -> Array[String]:
	var errors: Array[String] = []
	if endings.size() != 15:
		errors.append("endings: expected 15 endings, got %d." % endings.size())
	for ending in endings:
		if not ending is EndingDef:
			errors.append("endings: expected EndingDef records.")
			continue
		for condition_name in ending.conditions:
			var value: Variant = ending.conditions[condition_name]
			if condition_name in [
				"str_min", "str_max", "int_min", "int_max", "cha_min", "cha_max",
				"ref_min", "ref_max", "sta_min", "sta_max", "eth_min", "eth_max",
				"fighter_rep_min", "fighter_rep_max", "social_rep_min", "social_rep_max",
				"hacker_rep_min", "hacker_rep_max", "hacker_rep_lt"
			]:
				if not _is_number(value) or value < 0 or value > 100:
					errors.append(
						"endings: '%s' has out-of-range condition '%s'." % [ending.id, condition_name]
					)
			elif condition_name in [
				"missoes_tecnicas_concluidas_min", "missoes_tecnicas_concluidas_lt"
			]:
				if not _is_number(value) or value < 0:
					errors.append(
						"endings: '%s' has invalid counter condition '%s'." % [ending.id, condition_name]
					)
	return errors


static func validate_missions(missions: Array) -> Array[String]:
	var errors: Array[String] = []
	if missions.size() != 3:
		errors.append("missions: expected 3 mission types, got %d." % missions.size())
	for mission in missions:
		if not mission is MissionDef:
			errors.append("missions: expected MissionDef records.")
			continue
		if mission.stat_id not in STAT_IDS:
			errors.append("missions: '%s' references unknown stat '%s'." % [mission.id, mission.stat_id])
		if mission.stress < 0 or mission.stress > 100:
			errors.append("missions: '%s' has stress outside 0-100." % mission.id)
		if mission.success_effects.is_empty():
			errors.append("missions: '%s' has no success effects." % mission.id)
	return errors


static func _item_id(item: Variant) -> String:
	if item is Dictionary:
		return str(item.get("id", ""))
	if item is Object:
		return str(item.get("id"))
	return ""


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
