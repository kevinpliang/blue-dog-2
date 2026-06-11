class_name DogRunPerformanceMonitor
extends RefCounted

const TARGET_FRAME_TIME := 1.0 / 60.0

var _elapsed := 0.0
var _total_frame_time := 0.0
var _worst_frame_time := 0.0
var _frame_count := 0
var _slow_frames := 0
var _last_obstacle_count := 0
var _report := {}


func sample(delta: float, obstacle_count: int) -> void:
	_elapsed += delta
	_total_frame_time += delta
	_worst_frame_time = maxf(_worst_frame_time, delta)
	_frame_count += 1
	_slow_frames += 1 if delta > TARGET_FRAME_TIME * 1.1 else 0
	_last_obstacle_count = obstacle_count
	if _elapsed >= 1.0:
		_report = {
			"average_ms": _total_frame_time / _frame_count * 1000.0,
			"worst_ms": _worst_frame_time * 1000.0,
			"slow_frames": _slow_frames,
			"obstacles": _last_obstacle_count,
		}
		_elapsed = 0.0
		_total_frame_time = 0.0
		_worst_frame_time = 0.0
		_frame_count = 0
		_slow_frames = 0


func take_report() -> Dictionary:
	var result := _report
	_report = {}
	return result
