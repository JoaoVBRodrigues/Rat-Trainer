extends Control
class_name Main

const TITLE_SCENE: PackedScene = preload("res://src/scenes/TitleScreen.tscn")
const CHARACTER_CREATION_SCENE: PackedScene = preload(
	"res://src/scenes/CharacterCreationScreen.tscn"
)
const OPTIONS_SCENE: PackedScene = preload("res://src/scenes/OptionsScreen.tscn")
const SAVE_SLOT_SCENE: PackedScene = preload("res://src/scenes/SaveSlotScreen.tscn")
const THEME_PATH: String = "res://src/ui/UITheme.tres"

var _title_screen: TitleScreen
var _character_creation: CharacterCreationScreen
var _options_screen: OptionsScreen
var _save_slot_screen: SaveSlotScreen
var _gallery_screen: EndingGallery
var _main_screen: MainScreen
var _return_to_game_after_options: bool = false
var _gallery_return_to_game: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shared_theme: Theme = load(THEME_PATH) as Theme
	if shared_theme == null:
		push_error("Could not load UI theme: %s." % THEME_PATH)
		return
	theme = shared_theme
	UIThemeResource.apply_runtime_assets(shared_theme, get_node("/root/Assets") as AssetResolver)
	_show_title()
	var settings: Dictionary = Data.get_settings()
	if not settings.is_empty():
		AudioManager.apply_settings(settings)
	_apply_ui_settings(settings)


func _show_title() -> void:
	_hide_screens()
	if _title_screen == null:
		_title_screen = TITLE_SCENE.instantiate() as TitleScreen
		_title_screen.new_game_requested.connect(_open_character_creation)
		_title_screen.continue_requested.connect(_continue_campaign)
		_title_screen.options_requested.connect(_open_options.bind(false))
		_title_screen.gallery_requested.connect(_open_gallery.bind(false))
		_title_screen.quit_requested.connect(_on_quit_requested)
		add_child(_title_screen)
	_title_screen.refresh_saves()
	_title_screen.visible = true


func _open_character_creation() -> void:
	_hide_screens()
	if _character_creation == null:
		_character_creation = CHARACTER_CREATION_SCENE.instantiate() as CharacterCreationScreen
		_character_creation.create_requested.connect(_create_campaign)
		_character_creation.cancel_requested.connect(_show_title)
		add_child(_character_creation)
	_character_creation.visible = true


func _create_campaign(character_name: String, guardian_name: String) -> void:
	if not Game.start_new_game(character_name, guardian_name):
		push_error("Could not start the new campaign.")
		return
	_show_campaign(false)


func _continue_campaign(save_id: String) -> void:
	if not Game.load_save_id(save_id):
		return
	_show_campaign(true)


func _show_campaign(resume: bool) -> void:
	_hide_screens()
	if _main_screen == null:
		_main_screen = MainScreen.new()
		_main_screen.name = "MainScreen"
		_main_screen.return_to_title_requested.connect(_return_campaign_to_title)
		_main_screen.destination_requested.connect(_on_game_destination_requested)
		_main_screen.save_requested.connect(_open_save_slots)
		add_child(_main_screen)
	var character: Dictionary = Data.get_current_data().get("character", {})
	_main_screen.update_simulation(Game.simulation, character)
	_main_screen.visible = true
	if resume:
		_main_screen.resume_saved_flow()


func _open_save_slots() -> void:
	_hide_screens()
	if _save_slot_screen == null:
		_save_slot_screen = SAVE_SLOT_SCENE.instantiate() as SaveSlotScreen
		_save_slot_screen.save_requested.connect(_save_manual_slot)
		_save_slot_screen.cancel_requested.connect(_return_from_save_slots)
		add_child(_save_slot_screen)
	var data_manager: DataManager = get_node_or_null("/root/Data") as DataManager
	if data_manager == null:
		push_error("Cannot show save slots because DataManager is unavailable.")
		return
	_save_slot_screen.open_slots(data_manager.get_save_slots())


func _save_manual_slot(slot: int) -> void:
	if not Game.save_game(slot):
		return
	_return_from_save_slots()


func _return_from_save_slots() -> void:
	if _save_slot_screen != null:
		_save_slot_screen.visible = false
	if _main_screen != null:
		_main_screen.visible = true


func _open_options(return_to_game: bool) -> void:
	_return_to_game_after_options = return_to_game
	_hide_screens()
	if _options_screen == null:
		_options_screen = OPTIONS_SCENE.instantiate() as OptionsScreen
		_options_screen.settings_changed.connect(_save_options)
		_options_screen.back_requested.connect(_close_options)
		add_child(_options_screen)
	var settings: Dictionary = Data.get_settings()
	if settings.is_empty() or not _options_screen.load_settings(settings):
		push_error("Could not load game options.")
		return
	_options_screen.visible = true


func _save_options(settings: Dictionary) -> void:
	if not Data.save_settings(settings):
		return
	AudioManager.apply_settings(settings)
	_apply_ui_settings(settings)


func _apply_ui_settings(settings: Dictionary) -> void:
	if settings.is_empty():
		return
	var text_scale: Variant = settings.get("text_scale", 100)
	var animation_speed: Variant = settings.get("animation_speed", 100)
	if not text_scale is int or not animation_speed is int:
		push_error("Cannot apply invalid text or animation settings.")
		return
	if theme != null:
		theme.default_base_scale = float(text_scale) / 100.0
	for node: Node in find_children("*", "", true, false):
		if node is AnimationPlayer:
			(node as AnimationPlayer).speed_scale = float(animation_speed) / 100.0


func _close_options() -> void:
	if _options_screen != null:
		_options_screen.visible = false
	if _return_to_game_after_options:
		if _main_screen != null:
			_main_screen.visible = true
	else:
		_show_title()


func _open_gallery(return_to_game: bool) -> void:
	_gallery_return_to_game = return_to_game
	_hide_screens()
	if _gallery_screen == null:
		_gallery_screen = EndingGallery.new()
		_gallery_screen.name = "EndingGallery"
		_gallery_screen.gallery_finished.connect(_close_gallery)
		add_child(_gallery_screen)
	var ending_ids: Array[String] = []
	for raw_id: Variant in EndingGallery.ENDING_NAME_KEYS.keys():
		ending_ids.append(str(raw_id))
	_gallery_screen.open_gallery(ending_ids, Data.get_unlocked_endings())


func _close_gallery() -> void:
	if _gallery_screen != null:
		_gallery_screen.visible = false
	if _gallery_return_to_game and _main_screen != null:
		_main_screen.visible = true
	else:
		_show_title()


func _on_game_destination_requested(destination: String) -> void:
	if destination == "opcoes":
		_open_options(true)
	elif destination == "galeria_finais":
		_open_gallery(true)


func _on_quit_requested() -> void:
	Game.quit_game()


func _return_campaign_to_title() -> void:
	if Game.simulation != null and not Game.autosave_completed_period(false):
		push_error("Could not save before returning to the title screen.")
		return
	Game.return_to_title()
	_show_title()


func _hide_screens() -> void:
	for screen: Control in [
		_title_screen,
		_character_creation,
		_options_screen,
		_save_slot_screen,
		_gallery_screen,
		_main_screen
	]:
		if screen != null:
			screen.visible = false
