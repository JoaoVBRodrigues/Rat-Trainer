extends Node2D

const ASSET_REFRESH_INTERVAL: float = 0.5
const BACKGROUND_ID: StringName = &"bg_bedroom_day"
const CHARACTER_ID: StringName = &"char_rat_idle"

@onready var _background: Sprite2D = $Background as Sprite2D
@onready var _character: Sprite2D = $Character as Sprite2D

var _refresh_elapsed: float = 0.0


func _ready() -> void:
	_refresh_preview_assets()


func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed < ASSET_REFRESH_INTERVAL:
		return
	_refresh_elapsed = 0.0
	_refresh_preview_assets()


func _refresh_preview_assets() -> void:
	_background.texture = Assets.get_texture(BACKGROUND_ID, &"backgrounds")
	_character.texture = Assets.get_texture(CHARACTER_ID, &"characters")