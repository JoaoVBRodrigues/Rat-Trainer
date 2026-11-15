extends Node

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

var _resolver: AudioResolver = AudioResolver.new()
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = str(MUSIC_BUS)
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	_sfx_player.bus = str(SFX_BUS)
	add_child(_sfx_player)
	_music_player.stream = _resolver.get_stream(&"bgm_title", &"music")
	if _music_player.stream != null:
		_music_player.play()
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("ui_audio_requested"):
		event_bus.ui_audio_requested.connect(_on_audio_requested)


func apply_settings(settings: Dictionary) -> bool:
	var music_volume: Variant = settings.get("music_volume", null)
	var sfx_volume: Variant = settings.get("sfx_volume", null)
	if (
		not music_volume is int
		or music_volume < 0
		or music_volume > 100
		or not sfx_volume is int
		or sfx_volume < 0
		or sfx_volume > 100
	):
		push_error("Cannot apply invalid audio settings.")
		return false
	var music_index: int = AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_index: int = AudioServer.get_bus_index(SFX_BUS)
	if music_index < 0 or sfx_index < 0:
		push_error("Music or SFX audio bus is unavailable.")
		return false
	AudioServer.set_bus_volume_db(music_index, _volume_to_db(music_volume))
	AudioServer.set_bus_mute(music_index, music_volume == 0)
	AudioServer.set_bus_volume_db(sfx_index, _volume_to_db(sfx_volume))
	AudioServer.set_bus_mute(sfx_index, sfx_volume == 0)
	return true


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var bus_index: int = AudioServer.get_bus_count()
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _volume_to_db(volume: int) -> float:
	if volume == 0:
		return -80.0
	return linear_to_db(float(volume) / 100.0)


func _on_audio_requested(event_id: String) -> void:
	if event_id != "ui_confirm":
		push_error("Unknown audio event '%s'." % event_id)
		return
	if _sfx_player == null:
		push_error("SFX player is unavailable.")
		return
	_sfx_player.stream = _resolver.get_stream(&"ui_confirm", &"ui")
	if _sfx_player.stream != null:
		_sfx_player.play()
