class_name InputInterpreter
extends RefCounted

enum Command { TAP, LEFT, RIGHT, JUMP, DUCK }

const SWIPE_WIDTH_RATIO := 50.0 / 720.0


func interpret(start: Vector2, finish: Vector2, viewport_size: Vector2) -> Command:
	var swipe := finish - start
	var threshold := viewport_size.x * SWIPE_WIDTH_RATIO
	if swipe.length() < threshold:
		return Command.TAP
	if absf(swipe.x) > absf(swipe.y):
		return Command.RIGHT if swipe.x > 0.0 else Command.LEFT
	return Command.DUCK if swipe.y > 0.0 else Command.JUMP
