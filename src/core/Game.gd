extends Node

signal game_started
signal game_saved
signal game_loaded
signal game_over(ending_type: String)
signal state_changed(previous_state: int, new_state: int)

enum GameState {
	BOOT,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	TRANSITION,
	GAME_OVER
}

var current_state: GameState = GameState.BOOT


func _ready() -> void:
	transition_to(GameState.MAIN_MENU)


func start_new_game() -> void:
	Data.initialize_new_save()
	transition_to(GameState.PLAYING)
	game_started.emit()


func save_game(slot: int) -> bool:
	var saved: bool = Data.save_current(slot)
	if saved:
		game_saved.emit()
		EventBus.game_saved.emit()
	return saved


func load_game(slot: int) -> bool:
	if not Data.load_slot(slot):
		return false
	transition_to(GameState.PLAYING)
	game_loaded.emit()
	EventBus.game_loaded.emit()
	return true


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