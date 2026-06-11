extends RefCounted

const Simulation = preload("res://game/runner_simulation.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	test_lane_changes_chain_and_stop_at_edges()
	test_jump_and_duck_rules()
	test_duck_has_a_cooldown()
	test_duck_timing_remains_intentional()
	test_early_jump_runs_on_landing()
	test_early_duck_runs_after_cooldown()
	test_speed_caps_and_score_tracks_distance()
	test_seeded_generation_is_deterministic_and_fair()
	test_difficulty_tiers_unlock_by_distance()
	test_generation_uses_curated_patterns()
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
	expect_equal(jumping.duck_time, 0.0, "duck is ignored while airborne")

	var ducking = Simulation.new()
	ducking.start(3)
	ducking.duck()
	expect_true(ducking.duck_time > 0.0, "duck starts while grounded")
	ducking.step(0.7)
	expect_equal(ducking.duck_time, 0.0, "duck ends automatically")


func test_duck_has_a_cooldown() -> void:
	var simulation = Simulation.new()
	simulation.start(31)
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0

	simulation.duck()
	simulation.step(simulation.DUCK_DURATION + 0.01)
	simulation.duck()
	expect_equal(simulation.duck_time, 0.0, "duck cannot restart during cooldown")

	simulation.step(simulation.DUCK_COOLDOWN + 0.01)
	simulation.duck()
	expect_true(simulation.duck_time > 0.0, "duck can restart after cooldown")


func test_duck_timing_remains_intentional() -> void:
	expect_equal(Simulation.DUCK_DURATION, 0.3, "duck duration remains intentional")
	expect_equal(Simulation.DUCK_COOLDOWN, 0.05, "duck cooldown remains intentional")


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
	simulation.step(Simulation.DUCK_DURATION)
	simulation.duck()
	simulation.step(Simulation.DUCK_COOLDOWN + 0.01)
	expect_true(simulation.duck_time > 0.0, "buffered duck runs after cooldown")


func test_speed_caps_and_score_tracks_distance() -> void:
	var simulation = Simulation.new()
	simulation.start(4)
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0

	for index in range(60):
		simulation.step(1.0)

	expect_equal(simulation.speed, simulation.MAX_SPEED, "speed stops at its cap")
	expect_equal(simulation.score(), int(floor(simulation.distance)), "score is whole meters")


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
	expect_equal(simulation.difficulty_tier_at_distance(250.0), 1, "middle distance unlocks tier one")
	expect_equal(simulation.difficulty_tier_at_distance(650.0), 2, "long distance unlocks tier two")


func test_generation_uses_curated_patterns() -> void:
	var simulation = Simulation.new()
	simulation.start(81)
	for obstacle in simulation.obstacles:
		expect_true(obstacle.has("pattern_id"), "generated obstacles identify their curated pattern")


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


func clear_obstacles(simulation: RefCounted) -> void:
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0
