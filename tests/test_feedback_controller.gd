extends RefCounted

const FeedbackController = preload("res://game/feedback_controller.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	var controller = FeedbackController.new()
	controller.prepare()
	expect_equal(controller.particle_pool_size(), FeedbackController.IMPACT_POOL_SIZE, "particle pool is bounded")
	expect_equal(controller.audio_pool_size(), FeedbackController.AUDIO_POOL_SIZE, "audio pool is bounded")
	expect_true(controller.particles_are_idle(), "pooled impact particles start idle")
	controller.handle_events([{"type": "collision"}], Vector3.ZERO)
	expect_true(controller.shake_time > 0.0, "collision starts camera shake")
	controller.free()

	test_sound_settings_gate_and_scale_audio()
	return failures


func test_sound_settings_gate_and_scale_audio() -> void:
	var controller = FeedbackController.new()
	controller.prepare()

	controller.set_sound_settings(false, 1.0)
	controller.handle_events([{"type": "jumped"}], Vector3.ZERO)
	expect_true(controller.first_audio_stream_is_empty(), "disabled sound does not assign a cue stream")

	controller.set_sound_settings(true, 0.5)
	controller.handle_events([{"type": "jumped"}], Vector3.ZERO)
	expect_true(not controller.first_audio_stream_is_empty(), "enabled sound assigns a cue stream")
	expect_true(controller.first_audio_volume_db() < FeedbackController.BASE_AUDIO_VOLUME_DB, "volume below 100 percent lowers cue gain")

	var settings := controller.sound_settings()
	expect_true(bool(settings["enabled"]), "sound settings report enabled")
	expect_true(is_equal_approx(float(settings["volume"]), 0.5), "sound settings report clamped volume")
	controller.free()


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
