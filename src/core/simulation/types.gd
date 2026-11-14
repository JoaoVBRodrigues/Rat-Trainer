extends RefCounted
class_name PeriodResult

enum ActivityType { NONE, STUDY, WORK, MISSION, LEISURE, EVENT }
enum EncounterOption { FIGHT, TALK, FLEE, HIDE }

var period: int = 0
var year: int = 1
var month: int = 1
var period_num: int = 1
var age: int = 12
var activity_type: ActivityType = ActivityType.NONE

# Event-related fields
var is_event_pending: bool = false
var event_id: String = ""
var event_name: String = ""
var event_description: String = ""
var event_options: Array = []
var event_outcome: String = ""

# Encounter-related fields (physical missions only)
var is_encounter_pending: bool = false
var encounter_id: String = ""
var encounter_options: Array = []
var encounter_monster_name: String = ""
var encounter_monster_id: String = ""
var encounter_description: String = ""
var encounter_orac_returned: bool = false
var items_gained: Array[String] = []
var activity_id: String = ""
var activity_level: int = 1
var completed: bool = false
var credits_change: int = 0
var stat_changes: Dictionary = {}
var stress_change: int = 0
var stress_final: int = 0
var is_diseased_before: bool = false
var is_diseased_after: bool = false
var xp_gained: Dictionary = {}
var rep_gained: Dictionary = {}
var flags_set: Dictionary = {}
var promotion_unlocked: bool = false
var streaks_incremented: Dictionary = {}
var year_stipend_given: bool = false
var mission_count: int = 0
var mission_success: bool = false
var success_chance: int = 0
var eth_change: int = 0
var month_end_processed: bool = false
var error_message: String = ""
var pre_period_state: Dictionary = {}
var post_period_state: Dictionary = {}
