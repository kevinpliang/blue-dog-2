extends RefCounted

const MainScene = preload("res://game/main.tscn")

var failures: Array[String] = []


func run_all() -> Array[String]:
	var main = MainScene.instantiate()
	main.simulation.start(91)
	main.simulation.obstacles.clear()
	main.simulation.next_spawn_z = -10000.0
	main.set_app_paused(true)
	main.advance_simulation(1.0)
	expect_equal(main.simulation.distance, 0.0, "paused main does not advance simulation")
	main.set_app_paused(false)
	main.advance_simulation(1.0)
	expect_true(main.simulation.distance > 0.0, "resumed main advances simulation")
	main.free()
	return failures


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
