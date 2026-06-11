class_name PatternLibrary
extends RefCounted

const GROUND := 0
const OVERHEAD := 1
const WALL := 2
const MIN_CONSECUTIVE_WALL_ROW_SPACING := 8.0


static func all_patterns() -> Array[Dictionary]:
	# Add patterns with _pattern(id, tier, rows):
	# - id: unique descriptive name stored on spawned obstacles.
	# - tier: difficulty level when the pattern unlocks (0 = start, 1 = 250m, 2 = 650m).
	# - rows: ordered obstacle groups built with _row(offset, obstacles).
	# - offset: meters after the pattern's first row; offsets must increase.
	# - obstacles: entries built with _obstacle(lane, type).
	# - lane: 0 = left, 1 = center, 2 = right.
	# - type: GROUND requires jumping, OVERHEAD requires ducking, and WALL requires changing lanes.
	return [
		_pattern("single_wall_center", 0, [_row(0.0, [_obstacle(1, WALL)])]),
		_pattern("jump_left_center", 0, [_row(0.0, [_obstacle(0, GROUND), _obstacle(1, GROUND)])]),
		_pattern("jump_center_right", 0, [_row(0.0, [_obstacle(1, GROUND), _obstacle(2, GROUND)])]),
		_pattern("duck_left_center", 0, [_row(0.0, [_obstacle(0, OVERHEAD), _obstacle(1, OVERHEAD)])]),
		_pattern("duck_center_right", 0, [_row(0.0, [_obstacle(1, OVERHEAD), _obstacle(2, OVERHEAD)])]),
		_pattern("choose_left_then_center", 1, [
			_row(0.0, [_obstacle(1, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
		]),
		_pattern("choose_right_then_center", 1, [
			_row(0.0, [_obstacle(0, WALL), _obstacle(1, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
		]),
		_pattern("jump_then_lane", 1, [
			_row(0.0, [_obstacle(1, GROUND)]),
			_row(6.0, [_obstacle(0, WALL)]),
		]),
		_pattern("duck_then_lane", 1, [
			_row(0.0, [_obstacle(1, OVERHEAD)]),
			_row(5.0, [_obstacle(2, WALL)]),
		]),
		_pattern("alternating_walls", 1, [
			_row(0.0, [_obstacle(0, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(2, WALL)]),
		]),
		_pattern("left_center_right", 2, [
			_row(0.0, [_obstacle(1, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING * 2.0, [_obstacle(0, WALL), _obstacle(1, WALL)]),
		]),
		_pattern("right_center_left", 2, [
			_row(0.0, [_obstacle(0, WALL), _obstacle(1, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING * 2.0, [_obstacle(1, WALL), _obstacle(2, WALL)]),
		]),
		_pattern("jump_choice_duck", 2, [
			_row(0.0, [_obstacle(0, GROUND)]),
			_row(6.0, [_obstacle(2, WALL)]),
			_row(12.0, [_obstacle(1, OVERHEAD)]),
		]),
		_pattern("duck_choice_jump", 2, [
			_row(0.0, [_obstacle(2, OVERHEAD)]),
			_row(5.0, [_obstacle(0, WALL)]),
			_row(11.0, [_obstacle(1, GROUND)]),
		]),
		_pattern("mixed_openings", 2, [
			_row(0.0, [_obstacle(0, GROUND), _obstacle(2, WALL)]),
			_row(6.0, [_obstacle(1, OVERHEAD)]),
			_row(12.0, [_obstacle(0, WALL), _obstacle(2, GROUND)]),
		]),
	]


static func unlocked_patterns(max_tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pattern in all_patterns():
		if int(pattern["tier"]) <= max_tier:
			result.append(pattern)
	return result


static func _pattern(id: String, tier: int, rows: Array) -> Dictionary:
	return {"id": id, "tier": tier, "rows": rows}


static func _row(offset: float, obstacles: Array) -> Dictionary:
	return {"offset": offset, "obstacles": obstacles}


static func _obstacle(lane: int, type: int) -> Dictionary:
	return {"lane": lane, "type": type}
