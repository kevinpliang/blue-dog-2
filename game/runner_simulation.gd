class_name RunnerSimulation
extends RefCounted

const PatternLibrary = preload("res://game/pattern_library.gd")
const ReachabilityValidator = preload("res://game/reachability_validator.gd")
const TUNING = preload("res://game/default_runner_tuning.tres")

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
const COIN_COLLECTION_Z_RADIUS := 0.85
const COIN_COLLECTION_X_RADIUS := 0.75
const COIN_COLLECTION_HEIGHT_RADIUS := 0.55
const COIN_REMOVAL_Z := 6.0

var state: RunState = RunState.READY
var target_lane := 1
var current_x := 0.0
var player_y := 0.0
var vertical_velocity := 0.0
var duck_time := 0.0
var duck_cooldown_time := 0.0
var air_duck_time := 0.0
var air_duck_landing_roll := false
var jump_buffer_time := 0.0
var duck_buffer_time := 0.0
var impact_time := 0.0
var speed := START_SPEED
var distance := 0.0
var clear_streak := 0
var multiplier := 1
var peak_multiplier := 1
var near_miss_count := 0
var clear_bonus := 0
var near_miss_bonus := 0
var run_coin_count := 0
var obstacles: Array[Dictionary] = []
var coins: Array[Dictionary] = []
var next_spawn_z := -28.0

var _rng := RandomNumberGenerator.new()
var _validator = ReachabilityValidator.new()
var _events: Array[Dictionary] = []
var _next_obstacle_id := 1
var _next_coin_id := 1
var _next_row_id := 1


func start(seed_value: int) -> void:
	state = RunState.RUNNING
	target_lane = 1
	current_x = 0.0
	player_y = 0.0
	vertical_velocity = 0.0
	duck_time = 0.0
	duck_cooldown_time = 0.0
	air_duck_time = 0.0
	air_duck_landing_roll = false
	jump_buffer_time = 0.0
	duck_buffer_time = 0.0
	impact_time = 0.0
	speed = TUNING.start_speed
	distance = 0.0
	clear_streak = 0
	multiplier = 1
	peak_multiplier = 1
	near_miss_count = 0
	clear_bonus = 0
	near_miss_bonus = 0
	run_coin_count = 0
	_events.clear()
	obstacles.clear()
	coins.clear()
	next_spawn_z = -28.0
	_next_obstacle_id = 1
	_next_coin_id = 1
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

	speed = minf(TUNING.max_speed, speed + TUNING.speed_acceleration * delta)
	var travel := speed * delta
	distance += travel
	current_x = move_toward(current_x, lane_x(target_lane), TUNING.lane_change_speed * delta)
	var was_grounded := is_grounded()
	var was_air_ducking := is_air_ducking()
	_update_vertical_motion(delta)
	var landed := not was_grounded and is_grounded()
	if landed:
		_emit_event("landed")
	duck_time = maxf(0.0, duck_time - delta)
	if duck_time <= 0.0:
		air_duck_landing_roll = false
	duck_cooldown_time = maxf(0.0, duck_cooldown_time - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	duck_buffer_time = maxf(0.0, duck_buffer_time - delta)
	_apply_input_buffers()
	if landed and was_air_ducking:
		_start_duck(true)

	for obstacle in obstacles:
		obstacle["z"] = float(obstacle["z"]) + travel
	for coin in coins:
		coin["z"] = float(coin["z"]) + travel
	next_spawn_z += travel
	_fill_obstacle_field()

	if _has_collision():
		state = RunState.IMPACT
		impact_time = IMPACT_DURATION
		_emit_event("collision")
		return

	_collect_coins()
	_mark_passed_obstacles()
	for index in range(obstacles.size() - 1, -1, -1):
		if float(obstacles[index]["z"]) > 6.0:
			obstacles.remove_at(index)
	for index in range(coins.size() - 1, -1, -1):
		if bool(coins[index].get("collected", false)) or float(coins[index]["z"]) > COIN_REMOVAL_Z:
			coins.remove_at(index)


func change_lane(direction: int) -> void:
	if state != RunState.RUNNING:
		return
	var previous_lane := target_lane
	target_lane = clampi(target_lane + signi(direction), 0, 2)
	if target_lane != previous_lane:
		_emit_event("lane_changed")


func jump() -> void:
	if state != RunState.RUNNING:
		return
	if is_air_ducking() or air_duck_landing_roll:
		return
	if not is_grounded():
		jump_buffer_time = TUNING.input_buffer_duration
		return
	_start_jump()


func _start_jump() -> void:
	duck_time = 0.0
	air_duck_landing_roll = false
	jump_buffer_time = 0.0
	vertical_velocity = TUNING.jump_velocity
	_emit_event("jumped")


func duck() -> void:
	if state != RunState.RUNNING or is_air_ducking() or duck_time > 0.0:
		return
	if not is_grounded():
		_start_air_duck()
		return
	if duck_cooldown_time > 0.0:
		duck_buffer_time = TUNING.input_buffer_duration
		return
	_start_duck()


func _start_air_duck() -> void:
	jump_buffer_time = 0.0
	duck_buffer_time = 0.0
	air_duck_time = maxf(TUNING.air_duck_dive_duration, 0.001)
	_emit_event("air_duck_started")


func _start_duck(from_air_duck := false) -> void:
	duck_buffer_time = 0.0
	duck_time = TUNING.duck_duration
	duck_cooldown_time = TUNING.duck_duration + TUNING.duck_cooldown
	air_duck_landing_roll = from_air_duck
	_emit_event("ducked")


func is_air_ducking() -> bool:
	return air_duck_time > 0.0


func is_ducking() -> bool:
	return is_air_ducking() or duck_time > 0.0


func is_grounded() -> bool:
	return player_y <= 0.001 and vertical_velocity <= 0.001


func score() -> int:
	return final_score()


func distance_score() -> int:
	return int(floor(distance))


func final_score() -> int:
	return distance_score() + clear_bonus + near_miss_bonus


func multiplier_for_streak(streak: int) -> int:
	if streak >= 30:
		return 4
	if streak >= 15:
		return 3
	if streak >= 5:
		return 2
	return 1


func record_obstacle_clear(obstacle_id: int) -> void:
	clear_streak += 1
	multiplier = multiplier_for_streak(clear_streak)
	peak_multiplier = maxi(peak_multiplier, multiplier)
	clear_bonus += 10 * multiplier
	_events.append({"type": "obstacle_cleared", "obstacle_id": obstacle_id})


func record_near_miss(obstacle_id: int) -> void:
	near_miss_count += 1
	near_miss_bonus += 25
	_events.append({"type": "near_miss", "obstacle_id": obstacle_id})


func drain_events() -> Array[Dictionary]:
	var result := _events.duplicate(true)
	_events.clear()
	return result


func lane_x(lane: int) -> float:
	return (lane - 1) * LANE_WIDTH


func difficulty_tier_at_distance(value: float) -> int:
	if value >= TUNING.tier_two_unlock_distance:
		return 2
	if value >= TUNING.tier_one_unlock_distance:
		return 1
	return 0


static func updated_high_score(high_score: int, run_score: int) -> int:
	return maxi(high_score, run_score)


func _update_vertical_motion(delta: float) -> void:
	if is_air_ducking():
		var remaining := maxf(air_duck_time, 0.001)
		player_y = move_toward(player_y, 0.0, player_y * delta / remaining)
		air_duck_time = maxf(0.0, air_duck_time - delta)
		if air_duck_time <= 0.0 or player_y <= 0.001:
			player_y = 0.0
			vertical_velocity = 0.0
			air_duck_time = 0.0
		return

	if is_grounded():
		player_y = 0.0
		vertical_velocity = 0.0
		return

	vertical_velocity -= TUNING.gravity * delta
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
				"passed": false,
			})
			_next_obstacle_id += 1
		_next_row_id += 1
	for pattern_coin in pattern.get("coins", []):
		var coin_offset := float(pattern_coin["offset"])
		last_offset = maxf(last_offset, coin_offset)
		coins.append({
			"id": _next_coin_id,
			"pattern_id": pattern["id"],
			"lane": pattern_coin["lane"],
			"height": pattern_coin["height"],
			"z": z_position - coin_offset,
			"collected": false,
		})
		_next_coin_id += 1
	next_spawn_z = z_position - last_offset - _row_spacing()


func _row_spacing() -> float:
	var normal_spacing := maxf(
		TUNING.minimum_pattern_spacing,
		TUNING.normal_pattern_spacing_base - speed * TUNING.normal_pattern_spacing_speed_factor
	)
	var early_ratio := clampf(
		distance / maxf(TUNING.early_spacing_end_distance, 0.001),
		0.0,
		1.0
	)
	return lerpf(TUNING.early_pattern_spacing, normal_spacing, early_ratio)


func _collect_coins() -> void:
	for coin in coins:
		if bool(coin.get("collected", false)):
			continue
		if absf(float(coin["z"])) > COIN_COLLECTION_Z_RADIUS:
			continue
		if absf(current_x - lane_x(int(coin["lane"]))) > COIN_COLLECTION_X_RADIUS:
			continue
		if absf(player_y - float(coin["height"])) > COIN_COLLECTION_HEIGHT_RADIUS:
			continue
		coin["collected"] = true
		run_coin_count += 1
		_events.append({"type": "coin_collected", "coin_id": int(coin["id"])})


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
				if not is_ducking():
					return true
			ObstacleType.WALL:
				return true
	return false


func _mark_passed_obstacles() -> void:
	for obstacle in obstacles:
		if bool(obstacle.get("passed", false)) or float(obstacle["z"]) <= 0.9:
			continue
		obstacle["passed"] = true
		record_obstacle_clear(int(obstacle["id"]))
		if absf(current_x - lane_x(int(obstacle["lane"]))) <= 0.9:
			record_near_miss(int(obstacle["id"]))


func _emit_event(type: String) -> void:
	_events.append({"type": type})
