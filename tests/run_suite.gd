extends SceneTree


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("Expected a test suite path.")
		quit(1)
		return
	var suite = load(arguments[0]).new()
	var failures: Array[String] = suite.run_all()
	for failure in failures:
		push_error(failure)
	quit(failures.size())
