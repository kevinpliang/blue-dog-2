extends RefCounted

const TUNING = preload("res://game/default_runner_tuning.tres")

var failures: Array[String] = []


func run_all() -> Array[String]:
	expect_equal(TUNING.duck_duration, 0.4, "tuning preserves duck duration")
	expect_equal(TUNING.duck_cooldown, 0.05, "tuning preserves duck cooldown")
	expect_property_equal(TUNING, "air_duck_dive_duration", 0.1, "airborne duck dive stays brief")
	expect_equal(TUNING.start_speed, 12.0, "tuning preserves start speed")
	expect_equal(TUNING.max_speed, 28.0, "tuning preserves max speed")
	expect_property_positive(TUNING, "early_pattern_spacing", "early pattern spacing is tunable")
	expect_property_positive(TUNING, "early_spacing_end_distance", "early spacing end distance is tunable")
	expect_property_positive(TUNING, "normal_pattern_spacing_base", "normal pattern spacing base is tunable")
	expect_property_equal(TUNING, "normal_pattern_spacing_speed_factor", 0.25, "normal spacing preserves speed scaling")
	expect_property_equal(TUNING, "minimum_pattern_spacing", 16.0, "pattern spacing preserves its minimum")
	expect_property_positive(TUNING, "tier_one_unlock_distance", "tier one unlock distance is tunable")
	expect_property_positive(TUNING, "tier_two_unlock_distance", "tier two unlock distance is tunable")
	expect_true(TUNING.tier_two_unlock_distance > TUNING.tier_one_unlock_distance, "tier two unlocks after tier one")
	expect_equal(TUNING.input_buffer_duration, 0.12, "tuning preserves input buffer")
	expect_equal(TUNING.swipe_width_ratio, 50.0 / 720.0, "tuning preserves swipe threshold")
	expect_equal(TUNING.obstacle_fade_start, 52.0, "obstacle fade begins beyond gameplay distance")
	expect_equal(TUNING.obstacle_fade_end, 72.0, "obstacle fade hides the spawn boundary")
	expect_property_equal(TUNING, "camera_fov", 58.0, "camera uses moderate FOV zoom")
	expect_property_equal(TUNING, "visual_action_plane_z", 2.0, "visual action plane sits closer to camera")
	expect_property_equal(TUNING, "lane_lean_max_degrees", 12.0, "lane lean stays subtle")
	expect_property_equal(TUNING, "lane_lean_smoothing", 12.0, "lane lean responds smoothly")
	expect_property_equal(TUNING, "jump_stretch_horizontal", 0.88, "jump stretch narrows the player")
	expect_property_equal(TUNING, "jump_stretch_vertical", 1.15, "jump stretch lengthens the player")
	expect_property_equal(TUNING, "landing_squash_horizontal", 1.12, "landing pulse widens the player")
	expect_property_equal(TUNING, "landing_squash_vertical", 0.82, "landing pulse shortens the player")
	expect_property_equal(TUNING, "landing_pulse_duration", 0.16, "landing pulse stays brief")
	expect_property_missing(TUNING, "speed_trail_min_amount_ratio", "speed trail amount tuning is removed")
	expect_property_missing(TUNING, "speed_trail_max_amount_ratio", "speed trail amount tuning is removed")
	expect_property_missing(TUNING, "speed_trail_min_velocity", "speed trail velocity tuning is removed")
	expect_property_missing(TUNING, "speed_trail_max_velocity", "speed trail velocity tuning is removed")
	return failures


func expect_property_equal(resource: Resource, property_name: String, expected: float, message: String) -> void:
	var actual: Variant = resource.get(property_name)
	if actual == null:
		failures.append("%s: missing property %s" % [message, property_name])
		return
	expect_equal(actual, expected, message)


func expect_property_positive(resource: Resource, property_name: String, message: String) -> void:
	var actual: Variant = resource.get(property_name)
	if actual == null or float(actual) <= 0.0:
		failures.append("%s: expected positive property %s, got %s" % [message, property_name, actual])


func expect_property_missing(resource: Resource, property_name: String, message: String) -> void:
	for property in resource.get_property_list():
		if property["name"] == property_name:
			failures.append("%s: unexpected property %s" % [message, property_name])
			return


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if not is_equal_approx(float(actual), float(expected)):
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
