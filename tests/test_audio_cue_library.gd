extends RefCounted

const AudioCueLibrary = preload("res://game/audio_cue_library.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	var library = AudioCueLibrary.new()
	for cue_name in ["jumped", "landed", "lane_changed", "near_miss", "collision", "coin_collected"]:
		var cue: AudioStreamWAV = library.cue(cue_name)
		expect_true(cue != null, "%s cue exists" % cue_name)
		expect_true(cue.data.size() > 0, "%s cue has samples" % cue_name)
		expect_true(cue.mix_rate == 22050, "%s cue uses mobile-friendly sample rate" % cue_name)
	return failures


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
