extends RefCounted

const Simulation = preload("res://game/runner_simulation.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	test_lane_changes_chain_and_stop_at_edges()
	test_jump_and_duck_rules()
	test_airborne_duck_dives_and_transitions_to_roll()
	test_airborne_duck_uses_duck_collision_rules()
	test_airborne_duck_blocks_jump_during_dive_but_landing_roll_can_jump()
	test_duck_has_a_cooldown()
	test_duck_timing_remains_intentional()
	test_early_jump_runs_on_landing()
	test_early_duck_runs_after_cooldown()
	test_speed_caps_and_score_tracks_distance()
	test_pattern_spacing_eases_into_normal_frequency()
	test_seeded_generation_is_deterministic_and_fair()
	test_difficulty_tiers_unlock_by_distance()
	test_generation_uses_curated_patterns()
	test_gameplay_events_drain_once()
	test_multiplier_and_final_score()
	test_collision_uses_interpolated_player_position()
	test_high_score_only_increases()
	return failures


func test_lane_changes_chain_and_stop_at_edges() -> void:
	var simulation = Simulation.new()
	simulation.start(1)

	simulation.change_lane(-1)
	simulation.change_lane(-1)
	simulation.change_lane(-1)
	expect_equal(simulation.target_lane, 0, "lane changes stop at the left edge")

	simulation.change_lane(1)
	simulation.change_lane(1)
	expect_equal(simulation.target_lane, 2, "lane changes can chain before interpolation finishes")


func test_jump_and_duck_rules() -> void:
	var jumping = Simulation.new()
	jumping.start(2)
	jumping.jump()
	expect_true(not jumping.is_grounded(), "jump leaves the ground")
	jumping.duck()
	expect_true(jumping.is_air_ducking(), "duck starts a fast dive while airborne")
	expect_true(jumping.is_ducking(), "airborne duck immediately activates duck collision")

	var ducking = Simulation.new()
	ducking.start(3)
	ducking.duck()
	expect_true(ducking.duck_time > 0.0, "duck starts while grounded")
	ducking.step(0.7)
	expect_equal(ducking.duck_time, 0.0, "duck ends automatically")


func test_airborne_duck_dives_and_transitions_to_roll() -> void:
	var simulation = Simulation.new()
	simulation.start(34)
	clear_obstacles(simulation)
	simulation.jump()
	simulation.step(0.1)
	var starting_height: float = simulation.player_y

	simulation.duck()
	var events := simulation.drain_events()
	expect_true(simulation.is_air_ducking(), "airborne duck starts a dive")
	expect_true(simulation.is_ducking(), "dive protects against overhead bars immediately")
	expect_true(has_event(events, "air_duck_started"), "airborne duck emits its start event")

	simulation.step(simulation.TUNING.air_duck_dive_duration * 0.5)
	expect_true(simulation.player_y < starting_height and simulation.player_y > 0.0, "dive descends smoothly before landing")

	simulation.step(simulation.TUNING.air_duck_dive_duration * 0.5 + 0.001)
	expect_true(simulation.is_grounded(), "dive reaches the ground in the tuned duration")
	expect_true(not simulation.is_air_ducking(), "airborne dive ends on landing")
	expect_true(simulation.duck_time > 0.0, "landing begins the normal ground roll")


func test_airborne_duck_uses_duck_collision_rules() -> void:
	var overhead = Simulation.new()
	overhead.start(36)
	clear_obstacles(overhead)
	overhead.player_y = 0.5
	overhead.vertical_velocity = 1.0
	overhead.duck()
	overhead.obstacles.append({
		"id": 900,
		"row_id": 900,
		"lane": overhead.target_lane,
		"type": Simulation.ObstacleType.OVERHEAD_BAR,
		"z": -0.1,
	})
	overhead.step(0.01)
	expect_equal(overhead.state, Simulation.RunState.RUNNING, "airborne duck clears an overhead bar immediately")

	var ground = Simulation.new()
	ground.start(37)
	clear_obstacles(ground)
	ground.player_y = 0.5
	ground.vertical_velocity = 1.0
	ground.duck()
	ground.obstacles.append({
		"id": 901,
		"row_id": 901,
		"lane": ground.target_lane,
		"type": Simulation.ObstacleType.GROUND_BLOCK,
		"z": -0.1,
	})
	ground.step(0.01)
	expect_equal(ground.state, Simulation.RunState.IMPACT, "airborne duck still collides with a low ground block")


func test_airborne_duck_blocks_jump_during_dive_but_landing_roll_can_jump() -> void:
	var simulation = Simulation.new()
	simulation.start(35)
	clear_obstacles(simulation)
	simulation.jump()
	simulation.duck()
	var dive_time: float = simulation.air_duck_time

	simulation.jump()
	simulation.duck()
	simulation.change_lane(1)
	expect_equal(simulation.jump_buffer_time, 0.0, "jump is not buffered during the dive")
	expect_equal(simulation.air_duck_time, dive_time, "repeated duck does not restart the dive")
	expect_equal(simulation.target_lane, 2, "lane changes remain available during the dive")

	simulation.step(simulation.TUNING.air_duck_dive_duration + 0.001)
	expect_true(simulation.duck_time > 0.0, "airborne duck landing starts a roll")
	simulation.jump()
	expect_equal(simulation.jump_buffer_time, 0.0, "jump is not buffered during the landing roll")
	expect_true(simulation.vertical_velocity > 0.0, "landing roll can be jump-cancelled like an ordinary duck")
	expect_equal(simulation.duck_time, 0.0, "jump cancels the landing roll")
	expect_true(not simulation.air_duck_landing_roll, "jump clears the landing roll flag")

	var grounded_duck = Simulation.new()
	grounded_duck.start(38)
	clear_obstacles(grounded_duck)
	grounded_duck.duck()
	grounded_duck.jump()
	expect_true(not grounded_duck.is_grounded(), "ordinary ground duck retains its existing jump cancel")


func test_duck_has_a_cooldown() -> void:
	var simulation = Simulation.new()
	simulation.start(31)
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0

	simulation.duck()
	simulation.step(simulation.TUNING.duck_duration + 0.01)
	simulation.duck()
	expect_equal(simulation.duck_time, 0.0, "duck cannot restart during cooldown")

	simulation.step(simulation.TUNING.duck_cooldown + 0.01)
	simulation.duck()
	expect_true(simulation.duck_time > 0.0, "duck can restart after cooldown")


func test_duck_timing_remains_intentional() -> void:
	expect_equal(Simulation.TUNING.duck_duration, 0.4, "duck duration remains intentional")
	expect_equal(Simulation.TUNING.duck_cooldown, 0.05, "duck cooldown remains intentional")


func test_early_jump_runs_on_landing() -> void:
	var simulation = Simulation.new()
	simulation.start(32)
	clear_obstacles(simulation)
	simulation.player_y = 0.04
	simulation.vertical_velocity = -1.0
	simulation.jump()
	simulation.step(0.1)
	expect_true(simulation.vertical_velocity > 0.0, "buffered jump runs on landing")


func test_early_duck_runs_after_cooldown() -> void:
	var simulation = Simulation.new()
	simulation.start(33)
	clear_obstacles(simulation)
	simulation.duck()
	simulation.step(simulation.TUNING.duck_duration)
	simulation.duck()
	simulation.step(simulation.TUNING.duck_cooldown + 0.01)
	expect_true(simulation.duck_time > 0.0, "buffered duck runs after cooldown")


func test_speed_caps_and_score_tracks_distance() -> void:
	var simulation = Simulation.new()
	simulation.start(4)
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0

	for index in range(60):
		simulation.step(1.0)

	expect_equal(simulation.speed, simulation.TUNING.max_speed, "speed stops at its cap")
	expect_equal(simulation.score(), int(floor(simulation.distance)), "score is whole meters")


func test_pattern_spacing_eases_into_normal_frequency() -> void:
	var simulation = Simulation.new()
	simulation.speed = simulation.TUNING.start_speed

	simulation.distance = 0.0
	expect_float_equal(simulation._row_spacing(), simulation.TUNING.early_pattern_spacing, "run starts with tuned wider pattern spacing")

	simulation.distance = simulation.TUNING.early_spacing_end_distance * 0.5
	var start_speed_spacing := maxf(
		simulation.TUNING.minimum_pattern_spacing,
		simulation.TUNING.normal_pattern_spacing_base - simulation.speed * simulation.TUNING.normal_pattern_spacing_speed_factor
	)
	expect_float_equal(
		simulation._row_spacing(),
		lerpf(simulation.TUNING.early_pattern_spacing, start_speed_spacing, 0.5),
		"early pattern spacing transitions smoothly"
	)

	simulation.distance = simulation.TUNING.early_spacing_end_distance
	expect_float_equal(simulation._row_spacing(), start_speed_spacing, "spacing end distance uses normal speed-based spacing")

	simulation.distance = simulation.TUNING.early_spacing_end_distance * 2.0
	simulation.speed = simulation.TUNING.max_speed
	var max_speed_spacing := maxf(
		simulation.TUNING.minimum_pattern_spacing,
		simulation.TUNING.normal_pattern_spacing_base - simulation.speed * simulation.TUNING.normal_pattern_spacing_speed_factor
	)
	expect_float_equal(simulation._row_spacing(), max_speed_spacing, "normal spacing preserves its tuned minimum")


func test_seeded_generation_is_deterministic_and_fair() -> void:
	var first = Simulation.new()
	var second = Simulation.new()
	first.start(77)
	second.start(77)

	expect_equal(first.obstacles, second.obstacles, "same seed creates the same obstacle rows")

	var row_lanes := {}
	for obstacle in first.obstacles:
		var row_id: int = obstacle["row_id"]
		if not row_lanes.has(row_id):
			row_lanes[row_id] = {}
		row_lanes[row_id][obstacle["lane"]] = true

	for row_id in row_lanes:
		expect_true(row_lanes[row_id].size() < 3, "row %s leaves an open lane" % row_id)


func test_difficulty_tiers_unlock_by_distance() -> void:
	var simulation = Simulation.new()
	expect_equal(simulation.difficulty_tier_at_distance(0.0), 0, "run starts at tier zero")
	expect_equal(simulation.difficulty_tier_at_distance(simulation.TUNING.tier_one_unlock_distance - 0.01), 0, "tier zero lasts until the tuned tier one distance")
	expect_equal(simulation.difficulty_tier_at_distance(simulation.TUNING.tier_one_unlock_distance), 1, "tuned middle distance unlocks tier one")
	expect_equal(simulation.difficulty_tier_at_distance(simulation.TUNING.tier_two_unlock_distance), 2, "tuned long distance unlocks tier two")


func test_generation_uses_curated_patterns() -> void:
	var simulation = Simulation.new()
	simulation.start(81)
	for obstacle in simulation.obstacles:
		expect_true(obstacle.has("pattern_id"), "generated obstacles identify their curated pattern")


func test_gameplay_events_drain_once() -> void:
	var simulation = Simulation.new()
	simulation.start(82)
	clear_obstacles(simulation)
	simulation.change_lane(1)
	simulation.jump()
	var events: Array[Dictionary] = simulation.drain_events()
	expect_true(has_event(events, "lane_changed"), "lane change emits an event")
	expect_true(has_event(events, "jumped"), "jump emits an event")
	expect_equal(simulation.drain_events().size(), 0, "events drain only once")


func test_multiplier_and_final_score() -> void:
	var simulation = Simulation.new()
	simulation.start(83)
	clear_obstacles(simulation)
	expect_equal(simulation.multiplier_for_streak(0), 1, "run starts at x1")
	expect_equal(simulation.multiplier_for_streak(5), 2, "five clears reaches x2")
	expect_equal(simulation.multiplier_for_streak(15), 3, "fifteen clears reaches x3")
	expect_equal(simulation.multiplier_for_streak(30), 4, "thirty clears reaches cap")
	for index in range(5):
		simulation.record_obstacle_clear(index)
	simulation.record_near_miss(99)
	expect_equal(simulation.multiplier, 2, "clear streak updates multiplier")
	expect_equal(simulation.near_miss_count, 1, "near misses are counted")
	expect_equal(simulation.final_score(), simulation.distance_score() + 85, "final score includes clear and near-miss bonuses")


func test_collision_uses_interpolated_player_position() -> void:
	var simulation = Simulation.new()
	simulation.start(5)
	simulation.obstacles.clear()
	simulation.obstacles.append({
		"id": 900,
		"row_id": 900,
		"lane": 1,
		"type": Simulation.ObstacleType.WALL,
		"z": -0.1,
	})
	simulation.next_spawn_z = -10000.0
	simulation.change_lane(1)
	simulation.step(0.01)

	expect_equal(simulation.state, Simulation.RunState.IMPACT, "collision follows current x, not target lane")


func test_high_score_only_increases() -> void:
	expect_equal(Simulation.updated_high_score(12, 9), 12, "lower score does not replace high score")
	expect_equal(Simulation.updated_high_score(12, 18), 18, "higher score replaces high score")


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


func expect_float_equal(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


func clear_obstacles(simulation: RefCounted) -> void:
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0


func has_event(events: Array[Dictionary], type: String) -> bool:
	for event in events:
		if event["type"] == type:
			return true
	return false
