extends RefCounted
class_name AudioResolver

const AUDIO_ROOT: String = "res://assets/audio"
const PLACEHOLDER_ROOT: String = "res://assets/placeholders/audio"
const SAMPLE_RATE: int = 22050
const TONE_DURATION: float = 0.09
const VALID_CATEGORIES: Array[StringName] = [&"ui", &"music"]

var _generated_streams: Dictionary = {}
var _id_regex: RegEx = RegEx.new()


func _init() -> void:
	var regex_error: Error = _id_regex.compile("^[a-z0-9_]+$")
	if regex_error != OK:
		push_error("AudioResolver could not compile its asset ID validation pattern.")


func get_stream(id: StringName, category: StringName) -> AudioStream:
	var asset_id: String = str(id)
	var category_name: String = str(category)
	if not VALID_CATEGORIES.has(category):
		push_error("Unsupported audio category '%s' for asset '%s'." % [category_name, asset_id])
		return null
	if asset_id.is_empty() or _id_regex.search(asset_id) == null:
		push_error("Invalid audio asset ID '%s'." % asset_id)
		return null

	for root: String in [AUDIO_ROOT, PLACEHOLDER_ROOT]:
		var path: String = root.path_join(category_name).path_join("%s.wav" % asset_id)
		if not ResourceLoader.exists(path):
			continue
		var loaded: Resource = ResourceLoader.load(path)
		var stream: AudioStream = loaded as AudioStream
		if stream == null:
			push_error("Audio asset '%s' is not a valid AudioStream." % path)
			return null
		return stream

	if asset_id == "ui_confirm":
		if not _generated_streams.has(asset_id):
			_generated_streams[asset_id] = _create_tone(false)
		return _generated_streams[asset_id] as AudioStream
	if asset_id == "bgm_title":
		if not _generated_streams.has(asset_id):
			_generated_streams[asset_id] = _create_tone(true)
		return _generated_streams[asset_id] as AudioStream
	push_warning("No audio asset or placeholder found for '%s/%s'; using silence." % [
		category_name,
		asset_id
	])
	return null


func _create_tone(looping: bool) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var duration: float = 2.0 if looping else TONE_DURATION
	var sample_count: int = roundi(float(SAMPLE_RATE) * duration)
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(sample_count * 2)
	for index: int in sample_count:
		var time: float = float(index) / float(SAMPLE_RATE)
		var fade: float = 1.0 - float(index) / float(sample_count) if not looping else 1.0
		var wave: float = sin(TAU * 660.0 * time)
		if looping:
			wave = (
				sin(TAU * 220.0 * time)
				+ sin(TAU * 277.0 * time)
				+ sin(TAU * 330.0 * time)
			) / 3.0
		var value: float = wave * fade * 0.18
		samples.encode_s16(index * 2, roundi(value * 32767.0))
	stream.data = samples
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
	return stream
