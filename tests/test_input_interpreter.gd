extends RefCounted

const InputInterpreter = preload("res://game/input_interpreter.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	test_short_pointer_release_is_tap()
	test_threshold_scales_with_viewport_width()
	test_dominant_axis_selects_direction()
	return failures


func test_short_pointer_release_is_tap() -> void:
	var input = InputInterpreter.new()
	expect_equal(input.interpret(Vector2.ZERO, Vector2(20, 10), Vector2(720, 1280)), InputInterpreter.Command.TAP, "short release is a tap")


func test_threshold_scales_with_viewport_width() -> void:
	var input = InputInterpreter.new()
	expect_equal(input.interpret(Vector2.ZERO, Vector2(60, 0), Vector2(720, 1280)), InputInterpreter.Command.RIGHT, "swipe clears phone threshold")
	expect_equal(input.interpret(Vector2.ZERO, Vector2(60, 0), Vector2(1440, 2560)), InputInterpreter.Command.TAP, "same distance stays a tap on wider viewport")


func test_dominant_axis_selects_direction() -> void:
	var input = InputInterpreter.new()
	expect_equal(input.interpret(Vector2.ZERO, Vector2(-80, 30), Vector2(720, 1280)), InputInterpreter.Command.LEFT, "horizontal swipe goes left")
	expect_equal(input.interpret(Vector2.ZERO, Vector2(20, -100), Vector2(720, 1280)), InputInterpreter.Command.JUMP, "vertical swipe goes up")
	expect_equal(input.interpret(Vector2.ZERO, Vector2(20, 100), Vector2(720, 1280)), InputInterpreter.Command.DUCK, "vertical swipe goes down")


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
