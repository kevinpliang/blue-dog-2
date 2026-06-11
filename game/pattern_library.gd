class_name PatternLibrary
extends RefCounted

const GROUND := 0
const OVERHEAD := 1
const WALL := 2
const MIN_CONSECUTIVE_WALL_ROW_SPACING := 8.0


static func all_patterns() -> Array[Dictionary]:
	return [
		_pattern("single_ground_left", 0, [_row(0.0, [_obstacle(0, GROUND)])]),
		_pattern("single_ground_center", 0, [_row(0.0, [_obstacle(1, GROUND)])]),
		_pattern("single_overhead_right", 0, [_row(0.0, [_obstacle(2, OVERHEAD)])]),
		_pattern("single_wall_center", 0, [_row(0.0, [_obstacle(1, WALL)])]),
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
