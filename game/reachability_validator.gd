class_name ReachabilityValidator
extends RefCounted

const LANE_WIDTH := 2.4
const LANE_CHANGE_SPEED := 16.0
const JUMP_RECOVERY := 0.8
const DUCK_RECOVERY := 0.35


func is_reachable(pattern: Dictionary, speed: float, start_lanes: Array = [0, 1, 2]) -> bool:
	var states: Array[Dictionary] = []
	for lane in start_lanes:
		states.append({"lane": int(lane), "recovery": 0.0})

	var previous_offset := 0.0
	for row in pattern["rows"]:
		var offset: float = row["offset"]
		var travel_time := maxf(0.0, (offset - previous_offset) / speed)
		var lane_reach := int(floor(travel_time * LANE_CHANGE_SPEED / LANE_WIDTH))
		var next_states: Array[Dictionary] = []

		for state in states:
			var recovery := maxf(0.0, float(state["recovery"]) - travel_time)
			for lane in range(3):
				if abs(lane - int(state["lane"])) > lane_reach:
					continue
				var obstacle_type := _obstacle_type_at_lane(row, lane)
				if obstacle_type == -1:
					_append_unique(next_states, lane, recovery)
				elif obstacle_type == 0 and recovery <= 0.0:
					_append_unique(next_states, lane, JUMP_RECOVERY)
				elif obstacle_type == 1 and recovery <= 0.0:
					_append_unique(next_states, lane, DUCK_RECOVERY)

		if next_states.is_empty():
			return false
		states = next_states
		previous_offset = offset
	return true


func _obstacle_type_at_lane(row: Dictionary, lane: int) -> int:
	for obstacle in row["obstacles"]:
		if int(obstacle["lane"]) == lane:
			return int(obstacle["type"])
	return -1


func _append_unique(states: Array[Dictionary], lane: int, recovery: float) -> void:
	for state in states:
		if int(state["lane"]) == lane and is_equal_approx(float(state["recovery"]), recovery):
			return
	states.append({"lane": lane, "recovery": recovery})
