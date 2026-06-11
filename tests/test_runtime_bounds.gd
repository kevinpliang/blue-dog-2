extends RefCounted

const FeedbackController = preload("res://game/feedback_controller.gd")
const LimitsScript = preload("res://game/runtime_limits.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	expect_equal(LimitsScript.MAX_OBSTACLE_NODES, 48, "obstacle visual pool has a hard cap")
	expect_equal(FeedbackController.IMPACT_POOL_SIZE, 4, "particle pool has a hard cap")
	expect_equal(FeedbackController.AUDIO_POOL_SIZE, 8, "audio pool has a hard cap")
	return failures
func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
