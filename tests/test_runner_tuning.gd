extends RefCounted

const TUNING = preload("res://game/default_runner_tuning.tres")

var failures: Array[String] = []


func run_all() -> Array[String]:
	expect_equal(TUNING.duck_duration, 0.3, "tuning preserves duck duration")
	expect_equal(TUNING.duck_cooldown, 0.05, "tuning preserves duck cooldown")
	expect_equal(TUNING.start_speed, 12.0, "tuning preserves start speed")
	expect_equal(TUNING.max_speed, 24.0, "tuning preserves max speed")
	expect_equal(TUNING.input_buffer_duration, 0.12, "tuning preserves input buffer")
	expect_equal(TUNING.swipe_width_ratio, 50.0 / 720.0, "tuning preserves swipe threshold")
	expect_equal(TUNING.obstacle_fade_start, 52.0, "obstacle fade begins beyond gameplay distance")
	expect_equal(TUNING.obstacle_fade_end, 72.0, "obstacle fade hides the spawn boundary")
	expect_property_equal(TUNING, "camera_fov", 58.0, "camera uses moderate FOV zoom")
	expect_property_equal(TUNING, "visual_action_plane_z", 2.0, "visual action plane sits closer to camera")
	return failures


func expect_property_equal(resource: Resource, property_name: String, expected: float, message: String) -> void:
	var actual: Variant = resource.get(property_name)
	if actual == null:
		failures.append("%s: missing property %s" % [message, property_name])
		return
	expect_equal(actual, expected, message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if not is_equal_approx(float(actual), float(expected)):
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
