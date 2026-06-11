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
	return failures


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
