extends RefCounted

const PerformanceMonitor = preload("res://game/performance_monitor.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	var monitor = PerformanceMonitor.new()
	for index in range(60):
		monitor.sample(1.0 / 60.0, 12)
	var report := monitor.take_report()
	expect_true(not report.is_empty(), "performance monitor creates one-second reports")
	expect_true(float(report["average_ms"]) > 0.0, "report includes average frame time")
	expect_equal(report["obstacles"], 12, "report includes obstacle count")
	return failures


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
