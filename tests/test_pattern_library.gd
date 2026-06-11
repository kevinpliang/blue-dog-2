extends RefCounted

const PatternLibrary = preload("res://game/pattern_library.gd")

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
	return failures


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
