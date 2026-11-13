class_name CharacterState
extends RefCounted

const STAT_STR: String = "str"
const STAT_INT: String = "int"
const STAT_CHA: String = "cha"
const STAT_REF: String = "ref"
const STAT_STA: String = "sta"
const STAT_ETH: String = "eth"

var stats: Dictionary = {}
var stress: int = 0
var credits: int = 0
var age: int = 12
var current_year: int = 1
var current_month: int = 1
var current_period: int = 1
var flags: Dictionary = {}
var reputations: Dictionary = {
	"fighter": 0,
	"social": 0,
	"hacker": 0
}
var equipment: Dictionary = {}
var inventory: Array[String] = []
var job_tasks_used_current_month: Dictionary = {}
var job_streaks: Dictionary = {}
var mission_count: int = 0
var tech_experiments: bool = false
var criminal_record: bool = false
var community_help: bool = false
var disappear_from_society: bool = false

func _init() -> void:
	stats = {STAT_STR: 15, STAT_INT: 15, STAT_CHA: 15, STAT_REF: 15, STAT_STA: 20, STAT_ETH: 50}
	job_tasks_used_current_month = {"reparo_leve": false, "entrega_assistida": false, "apoio_comunitario": false}
	job_streaks = {"reparo_leve": 0, "entrega_assistida": 0, "apoio_comunitario": 0}

func to_dict() -> Dictionary:
	return {
		"stats": stats.duplicate(),
		"stress": stress,
		"credits": credits,
		"age": age,
		"current_year": current_year,
		"current_month": current_month,
		"current_period": current_period,
		"flags": flags.duplicate(),
		"reputations": reputations.duplicate(),
		"equipment": equipment.duplicate(),
		"inventory": inventory.duplicate(),
		"job_tasks_used_current_month": job_tasks_used_current_month.duplicate(),
		"job_streaks": job_streaks.duplicate(),
		"mission_count": mission_count,
		"tech_experiments": tech_experiments,
		"criminal_record": criminal_record,
		"community_help": community_help,
		"disappear_from_society": disappear_from_society
	}

static func from_dict(data: Dictionary) -> CharacterState:
	var state = CharacterState.new()
	state.stats = data.get("stats", {})
	state.stress = data.get("stress", 0)
	state.credits = data.get("credits", 0)
	state.age = data.get("age", 12)
	state.current_year = data.get("current_year", 1)
	state.current_month = data.get("current_month", 1)
	state.current_period = data.get("current_period", 1)
	state.flags = data.get("flags", {})
	state.reputations = data.get("reputations", {"fighter": 0, "social": 0, "hacker": 0})
	state.equipment = data.get("equipment", {})
	state.inventory = data.get("inventory", [])
	state.job_tasks_used_current_month = data.get("job_tasks_used_current_month", {"reparo_leve": false, "entrega_assistida": false, "apoio_comunitario": false})
	state.job_streaks = data.get("job_streaks", {"reparo_leve": 0, "entrega_assistida": 0, "apoio_comunitario": 0})
	state.mission_count = data.get("mission_count", 0)
	state.tech_experiments = data.get("tech_experiments", false)
	state.criminal_record = data.get("criminal_record", false)
	state.community_help = data.get("community_help", false)
	state.disappear_from_society = data.get("disappear_from_society", false)
	return state