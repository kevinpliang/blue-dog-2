extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var suites := [
		preload("res://tests/test_runner_simulation.gd").new(),
		preload("res://tests/test_input_interpreter.gd").new(),
		preload("res://tests/test_pattern_library.gd").new(),
		preload("res://tests/test_reachability_validator.gd").new(),
		preload("res://tests/test_audio_cue_library.gd").new(),
		preload("res://tests/test_feedback_controller.gd").new(),
		preload("res://tests/test_runner_tuning.gd").new(),
		preload("res://tests/test_performance_monitor.gd").new(),
		preload("res://tests/test_lifecycle.gd").new(),
		preload("res://tests/test_runtime_bounds.gd").new(),
	]
	for suite in suites:
		failures.append_array(suite.run_all())

	if failures.is_empty():
		print("Dog Run simulation tests passed.")
	else:
		for failure in failures:
			push_error(failure)

	quit(failures.size())
