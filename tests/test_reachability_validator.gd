extends RefCounted

const Validator = preload("res://game/reachability_validator.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	var validator = Validator.new()
	expect_true(validator.is_reachable(pattern([{ "offset": 0.0, "obstacles": [{"lane": 1, "type": 2}] }]), 12.0), "single open lanes are reachable")
	expect_true(validator.is_reachable(pattern([
		{"offset": 0.0, "obstacles": [{"lane": 1, "type": 2}, {"lane": 2, "type": 2}]},
		{"offset": 4.0, "obstacles": [{"lane": 0, "type": 2}, {"lane": 2, "type": 2}]},
	]), 12.0, [0]), "one-lane move with enough time is reachable")
	expect_true(not validator.is_reachable(pattern([
		{"offset": 0.0, "obstacles": [{"lane": 1, "type": 2}, {"lane": 2, "type": 2}]},
		{"offset": 1.0, "obstacles": [{"lane": 0, "type": 2}, {"lane": 1, "type": 2}]},
	]), 24.0, [0]), "two-lane move without enough time is rejected")
	expect_true(validator.is_reachable(pattern([{ "offset": 0.0, "obstacles": [{"lane": 0, "type": 0}] }]), 12.0, [0]), "ground block can be jumped")
	expect_true(validator.is_reachable(pattern([{ "offset": 0.0, "obstacles": [{"lane": 0, "type": 1}] }]), 12.0, [0]), "overhead bar can be ducked")
	return failures


func pattern(rows: Array) -> Dictionary:
	return {"id": "test", "tier": 0, "rows": rows}


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
