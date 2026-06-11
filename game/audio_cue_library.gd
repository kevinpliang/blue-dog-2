class_name AudioCueLibrary
extends RefCounted

const MIX_RATE := 22050

var _cues := {}


func _init() -> void:
	_cues = {
		"jumped": _tone(520.0, 0.10, 0.22),
		"landed": _tone(150.0, 0.08, 0.18),
		"lane_changed": _tone(320.0, 0.06, 0.12),
		"near_miss": _tone(760.0, 0.12, 0.18),
		"collision": _tone(90.0, 0.30, 0.35),
	}


func cue(name: String) -> AudioStreamWAV:
	return _cues.get(name)


func _tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var fade := 1.0 - float(index) / sample_count
		var wave := sin(TAU * frequency * float(index) / MIX_RATE)
		var sample := int(clampf(wave * fade * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(index * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
