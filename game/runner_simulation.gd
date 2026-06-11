class_name RunnerSimulation
extends RefCounted

const PatternLibrary = preload("res://game/pattern_library.gd")
const ReachabilityValidator = preload("res://game/reachability_validator.gd")

enum RunState { READY, RUNNING, IMPACT, GAME_OVER }
enum ObstacleType { GROUND_BLOCK, OVERHEAD_BAR, WALL }

const LANE_WIDTH := 2.4
const START_SPEED := 12.0
const MAX_SPEED := 24.0
const SPEED_ACCELERATION := 0.35
const LANE_CHANGE_SPEED := 16.0
const JUMP_VELOCITY := 9.5
const GRAVITY := 24.0
const DUCK_DURATION := 0.3
const DUCK_COOLDOWN := 0.05
const INPUT_BUFFER_DURATION := 0.12
const IMPACT_DURATION := 0.3
const SPAWN_LIMIT_Z := -80.0
const TIER_ONE_DISTANCE := 250.0
const TIER_TWO_DISTANCE := 650.0

var state: RunState = RunState.READY
var target_lane := 1
var current_x := 0.0
var player_y := 0.0
var vertical_velocity := 0.0
var duck_time := 0.0
var duck_cooldown_time := 0.0
var jump_buffer_time := 0.0
var duck_buffer_time := 0.0
var impact_time := 0.0
var speed := START_SPEED
var distance := 0.0
var obstacles: Array[Dictionary] = []
var next_spawn_z := -28.0

var _rng := RandomNumberGenerator.new()
var _validator = ReachabilityValidator.new()
var _next_obstacle_id := 1
var _next_row_id := 1


func start(seed_value: int) -> void:
	state = RunState.RUNNING
	target_lane = 1
	current_x = 0.0
	player_y = 0.0
	vertical_velocity = 0.0
	duck_time = 0.0
	duck_cooldown_time = 0.0
	jump_buffer_time = 0.0
	duck_buffer_time = 0.0
	impact_time = 0.0
	speed = START_SPEED
	distance = 0.0
	obstacles.clear()
	next_spawn_z = -28.0
	_next_obstacle_id = 1
	_next_row_id = 1
	_rng.seed = seed_value
	_fill_obstacle_field()


func step(delta: float) -> void:
	if state == RunState.IMPACT:
		impact_time = maxf(0.0, impact_time - delta)
		if impact_time <= 0.0:
			state = RunState.GAME_OVER
		return

	if state != RunState.RUNNING:
		return

	speed = minf(MAX_SPEED, speed + SPEED_ACCELERATION * delta)
	var travel := speed * delta
	distance += travel
	current_x = move_toward(current_x, lane_x(target_lane), LANE_CHANGE_SPEED * delta)
	_update_vertical_motion(delta)
	duck_time = maxf(0.0, duck_time - delta)
	duck_cooldown_time = maxf(0.0, duck_cooldown_time - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	duck_buffer_time = maxf(0.0, duck_buffer_time - delta)
	_apply_input_buffers()

	for obstacle in obstacles:
		obstacle["z"] = float(obstacle["z"]) + travel
	next_spawn_z += travel
	_fill_obstacle_field()

	if _has_collision():
		state = RunState.IMPACT
		impact_time = IMPACT_DURATION
		return

	for index in range(obstacles.size() - 1, -1, -1):
		if float(obstacles[index]["z"]) > 6.0:
			obstacles.remove_at(index)


func change_lane(direction: int) -> void:
	if state != RunState.RUNNING:
		return
	target_lane = clampi(target_lane + signi(direction), 0, 2)


func jump() -> void:
	if state != RunState.RUNNING:
		return
	if not is_grounded():
		jump_buffer_time = INPUT_BUFFER_DURATION
		return
	_start_jump()


func _start_jump() -> void:
	duck_time = 0.0
	jump_buffer_time = 0.0
	vertical_velocity = JUMP_VELOCITY


func duck() -> void:
	if state != RunState.RUNNING:
		return
	if not is_grounded() or duck_cooldown_time > 0.0:
		duck_buffer_time = INPUT_BUFFER_DURATION
		return
	_start_duck()


func _start_duck() -> void:
	duck_buffer_time = 0.0
	duck_time = DUCK_DURATION
	duck_cooldown_time = DUCK_DURATION + DUCK_COOLDOWN


func is_grounded() -> bool:
	return player_y <= 0.001 and vertical_velocity <= 0.001


func score() -> int:
	return int(floor(distance))


func lane_x(lane: int) -> float:
	return (lane - 1) * LANE_WIDTH


func difficulty_tier_at_distance(value: float) -> int:
	if value >= TIER_TWO_DISTANCE:
		return 2
	if value >= TIER_ONE_DISTANCE:
		return 1
	return 0


static func updated_high_score(high_score: int, run_score: int) -> int:
	return maxi(high_score, run_score)


func _update_vertical_motion(delta: float) -> void:
	if is_grounded():
		player_y = 0.0
		vertical_velocity = 0.0
		return

	vertical_velocity -= GRAVITY * delta
	player_y += vertical_velocity * delta
	if player_y <= 0.0:
		player_y = 0.0
		vertical_velocity = 0.0


func _apply_input_buffers() -> void:
	if jump_buffer_time > 0.0 and is_grounded():
		_start_jump()
	elif duck_buffer_time > 0.0 and is_grounded() and duck_cooldown_time <= 0.0:
		_start_duck()


func _fill_obstacle_field() -> void:
	while next_spawn_z > SPAWN_LIMIT_Z:
		_spawn_next_pattern(next_spawn_z)


func _spawn_next_pattern(z_position: float) -> void:
	var candidates := PatternLibrary.unlocked_patterns(difficulty_tier_at_distance(distance))
	var pattern: Dictionary = candidates[_rng.randi_range(0, candidates.size() - 1)]
	for index in range(candidates.size()):
		if _validator.is_reachable(pattern, speed):
			break
		pattern = candidates[(index + 1) % candidates.size()]

	var last_offset := 0.0
	for row in pattern["rows"]:
		last_offset = float(row["offset"])
		for pattern_obstacle in row["obstacles"]:
			obstacles.append({
				"id": _next_obstacle_id,
				"row_id": _next_row_id,
				"pattern_id": pattern["id"],
				"lane": pattern_obstacle["lane"],
				"type": pattern_obstacle["type"],
				"z": z_position - last_offset,
			})
			_next_obstacle_id += 1
		_next_row_id += 1
	next_spawn_z = z_position - last_offset - _row_spacing()


func _row_spacing() -> float:
	return maxf(9.0, 15.0 - speed * 0.25)


func _has_collision() -> bool:
	for obstacle in obstacles:
		if absf(float(obstacle["z"])) > 0.85:
			continue
		if absf(current_x - lane_x(int(obstacle["lane"]))) > 0.72:
			continue

		match int(obstacle["type"]):
			ObstacleType.GROUND_BLOCK:
				if player_y < 1.0:
					return true
			ObstacleType.OVERHEAD_BAR:
				if duck_time <= 0.0:
					return true
			ObstacleType.WALL:
				return true
	return false
