extends RefCounted

const PatternLibrary = preload("res://game/pattern_library.gd")
const Validator = preload("res://game/reachability_validator.gd")
const REQUIRED_CONSECUTIVE_WALL_ROW_SPACING := 8.0
const NEW_PATTERN_TIERS := {
	"jump_wall_duck_gate": 1,
	"duck_wall_jump_gate": 1,
	"jump_gate_then_left": 1,
	"duck_gate_then_right": 1,
	"jump_then_duck_gate": 2,
	"duck_then_jump_gate": 2,
	"weave_left_center_jump": 2,
	"weave_right_center_duck": 2,
}

var failures: Array[String] = []


func run_all() -> Array[String]:
	var ids := {}
	var tier_counts := {0: 0, 1: 0, 2: 0}
	for pattern in PatternLibrary.all_patterns():
		expect_true(not ids.has(pattern["id"]), "pattern ids are unique")
		ids[pattern["id"]] = true
		var tier: int = pattern["tier"]
		expect_true(tier_counts.has(tier), "pattern tier is valid")
		tier_counts[tier] += 1
		var previous_offset := -1.0
		for row in pattern["rows"]:
			expect_true(float(row["offset"]) > previous_offset, "pattern row offsets ascend")
			previous_offset = row["offset"]
			for obstacle in row["obstacles"]:
				expect_true(int(obstacle["lane"]) in [0, 1, 2], "pattern obstacle lane is valid")
	expect_true(tier_counts[0] >= 4, "tier zero has introduction patterns")
	expect_true(tier_counts[1] >= 5, "tier one has choice patterns")
	expect_true(tier_counts[2] >= 5, "tier two has mixed patterns")
	test_consecutive_wall_rows_have_reaction_space()
	test_balanced_expansion_patterns()
	return failures


func test_consecutive_wall_rows_have_reaction_space() -> void:
	for pattern in PatternLibrary.all_patterns():
		var rows: Array = pattern["rows"]
		for index in range(1, rows.size()):
			var previous_row: Dictionary = rows[index - 1]
			var current_row: Dictionary = rows[index]
			if not row_contains_wall(previous_row) or not row_contains_wall(current_row):
				continue
			var spacing := float(current_row["offset"]) - float(previous_row["offset"])
			expect_true(
				spacing >= REQUIRED_CONSECUTIVE_WALL_ROW_SPACING,
				"pattern %s leaves at least %.1fm between consecutive wall rows" % [
					pattern["id"],
					REQUIRED_CONSECUTIVE_WALL_ROW_SPACING,
				]
			)


func row_contains_wall(row: Dictionary) -> bool:
	for obstacle in row["obstacles"]:
		if int(obstacle["type"]) == PatternLibrary.WALL:
			return true
	return false


func test_balanced_expansion_patterns() -> void:
	var patterns_by_id := {}
	for pattern in PatternLibrary.all_patterns():
		patterns_by_id[pattern["id"]] = pattern

	var validator = Validator.new()
	for pattern_id in NEW_PATTERN_TIERS:
		expect_true(patterns_by_id.has(pattern_id), "balanced expansion includes %s" % pattern_id)
		if not patterns_by_id.has(pattern_id):
			continue
		var pattern: Dictionary = patterns_by_id[pattern_id]
		expect_true(int(pattern["tier"]) == NEW_PATTERN_TIERS[pattern_id], "%s unlocks at the intended tier" % pattern_id)
		expect_true(validator.is_reachable(pattern, 24.0), "%s remains reachable at maximum speed" % pattern_id)

	if patterns_by_id.has("jump_then_duck_gate"):
		expect_true(
			float(patterns_by_id["jump_then_duck_gate"]["rows"][1]["offset"]) >= 20.0,
			"jump then duck allows time to land"
		)
	if patterns_by_id.has("duck_then_jump_gate"):
		expect_true(
			float(patterns_by_id["duck_then_jump_gate"]["rows"][1]["offset"]) >= 9.0,
			"duck then jump allows duck recovery"
		)


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
