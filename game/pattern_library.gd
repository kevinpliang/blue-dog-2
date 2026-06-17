class_name PatternLibrary
extends RefCounted

const GROUND := 0
const OVERHEAD := 1
const WALL := 2
const COIN_GROUND_HEIGHT := 0.0
const COIN_JUMP_HEIGHT := 2
const MIN_CONSECUTIVE_WALL_ROW_SPACING := 8.0
const MIN_JUMP_TO_DUCK_SPACING := 20.0
const MIN_DUCK_TO_JUMP_SPACING := 9.0


static func all_patterns() -> Array[Dictionary]:
	# Add patterns with _pattern(id, tier, rows, coins):
	# - id: unique descriptive name stored on spawned obstacles and coins.
	# - tier: difficulty level when the pattern unlocks; tier distances live in RunnerTuning.
	# - rows: ordered obstacle groups built with _row(offset, obstacles).
	# - coins: optional placements built with _coin(...) or _coin_line(...).
	# - offset: meters after the pattern's first row; row offsets must increase.
	# - lane: 0 = left, 1 = center, 2 = right.
	# - type: GROUND requires jumping, OVERHEAD requires ducking, and WALL requires changing lanes.
	# - height: player vertical offset required to collect the coin.
	# - count/spacing: number of coins in a line and meters between them.
	return [
		_pattern("single_wall_center", 0, [
			_row(0.0, [_obstacle(1, WALL)]),
		], _coin_line(1.5, 0, COIN_GROUND_HEIGHT, 4, 6)),
		_pattern("jump_left_center", 0, [_row(0.0, [_obstacle(0, GROUND), _obstacle(1, GROUND)])], [
			_coin(0.0, 0, COIN_JUMP_HEIGHT),
		]),
		_pattern("jump_center_right", 0, [_row(0.0, [_obstacle(1, GROUND), _obstacle(2, GROUND)])], [
			_coin(0.0, 2, COIN_JUMP_HEIGHT),
		]),
		_pattern("duck_left_center", 0, [_row(0.0, [_obstacle(0, OVERHEAD), _obstacle(1, OVERHEAD)])], [
			_coin(0.0, 0, COIN_GROUND_HEIGHT),
		]),
		_pattern("duck_center_right", 0, [_row(0.0, [_obstacle(1, OVERHEAD), _obstacle(2, OVERHEAD)])], [
			_coin(0.0, 2, COIN_GROUND_HEIGHT),
		]),
		_pattern("choose_left_then_center", 1, [
			_row(0.0, [_obstacle(1, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
		], [
			_coin(1.2, 0, COIN_GROUND_HEIGHT),
			_coin(7.2, 1, COIN_GROUND_HEIGHT),
			_coin(13.2, 1, COIN_GROUND_HEIGHT),
			_coin(19.2, 1, COIN_GROUND_HEIGHT),
		]),
		_pattern("choose_right_then_center", 1, [
			_row(0.0, [_obstacle(0, WALL), _obstacle(1, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
		], [
			_coin(1.2, 2, COIN_GROUND_HEIGHT),
			_coin(7.2, 1, COIN_GROUND_HEIGHT),
			_coin(13.2, 1, COIN_GROUND_HEIGHT),
			_coin(19.2, 1, COIN_GROUND_HEIGHT),
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
		], _coin_line(1.4, 1, COIN_GROUND_HEIGHT, 5, 6)),
		_pattern("jump_wall_duck_gate", 1, [
			_row(0.0, [_obstacle(0, GROUND), _obstacle(1, WALL), _obstacle(2, OVERHEAD)]),
		]),
		_pattern("duck_wall_jump_gate", 1, [
			_row(0.0, [_obstacle(0, OVERHEAD), _obstacle(1, WALL), _obstacle(2, GROUND)]),
		]),
		_pattern("jump_gate_then_left", 1, [
			_row(0.0, [_obstacle(0, GROUND), _obstacle(1, GROUND), _obstacle(2, GROUND)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(1, WALL), _obstacle(2, WALL)]),
		]),
		_pattern("duck_gate_then_right", 1, [
			_row(0.0, [_obstacle(0, OVERHEAD), _obstacle(1, OVERHEAD), _obstacle(2, OVERHEAD)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(1, WALL)]),
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
		_pattern("jump_then_duck_gate", 2, [
			_row(0.0, [_obstacle(0, GROUND), _obstacle(1, GROUND), _obstacle(2, GROUND)]),
			_row(MIN_JUMP_TO_DUCK_SPACING, [_obstacle(0, OVERHEAD), _obstacle(1, OVERHEAD), _obstacle(2, OVERHEAD)]),
		]),
		_pattern("duck_then_jump_gate", 2, [
			_row(0.0, [_obstacle(0, OVERHEAD), _obstacle(1, OVERHEAD), _obstacle(2, OVERHEAD)]),
			_row(MIN_DUCK_TO_JUMP_SPACING, [_obstacle(0, GROUND), _obstacle(1, GROUND), _obstacle(2, GROUND)]),
		]),
		_pattern("weave_left_center_jump", 2, [
			_row(0.0, [_obstacle(1, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING * 2.0, [_obstacle(0, GROUND), _obstacle(1, GROUND), _obstacle(2, GROUND)]),
		]),
		_pattern("weave_right_center_duck", 2, [
			_row(0.0, [_obstacle(0, WALL), _obstacle(1, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING, [_obstacle(0, WALL), _obstacle(2, WALL)]),
			_row(MIN_CONSECUTIVE_WALL_ROW_SPACING * 2.0, [_obstacle(0, OVERHEAD), _obstacle(1, OVERHEAD), _obstacle(2, OVERHEAD)]),
		]),
	]


static func unlocked_patterns(max_tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pattern in all_patterns():
		if int(pattern["tier"]) <= max_tier:
			result.append(pattern)
	return result


static func _pattern(id: String, tier: int, rows: Array, coins: Array = []) -> Dictionary:
	return {"id": id, "tier": tier, "rows": rows, "coins": coins}


static func _row(offset: float, obstacles: Array) -> Dictionary:
	return {"offset": offset, "obstacles": obstacles}


static func _coin(offset: float, lane: int, height: float) -> Dictionary:
	return {"offset": offset, "lane": lane, "height": height}


static func _coin_line(start_offset: float, lane: int, height: float, count: int, spacing: float) -> Array[Dictionary]:
	var coins: Array[Dictionary] = []
	for index in range(count):
		coins.append(_coin(start_offset + spacing * index, lane, height))
	return coins


static func _obstacle(lane: int, type: int) -> Dictionary:
	return {"lane": lane, "type": type}
