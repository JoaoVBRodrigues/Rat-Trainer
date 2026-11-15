extends Node

signal turn_started(period: int, month: int, year: int)
signal turn_completed
signal day_changed(day: int)

signal activity_started(activity_type: String, activity_data: Dictionary)
signal activity_completed(success: bool, result: Dictionary)
signal activity_cancelled

signal combat_started(enemy_count: int)
signal combat_round(round: int, damage: int)
signal combat_ended(victory: bool, rewards: Dictionary)

signal credits_changed(new_amount: int, change: int)
signal shop_opened(shop_type: String)
signal item_purchased(item_id: String, cost: int)
signal item_sold(item_id: String, gain: int)

signal stat_changed(stat: String, old_value: int, new_value: int)
signal stress_changed(old_value: int, new_value: int)
signal health_changed(old_value: int, new_value: int)

signal reputation_changed(type: String, old_value: int, new_value: int)

signal game_loaded
signal game_saved
signal game_quit

signal ui_opened(screen_name: String)
signal ui_closed(screen_name: String)
signal ui_audio_requested(event_id: String)