extends SceneTree

var _main: Node
var _frames := 0


func _init() -> void:
	_main = preload("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		_send_mobile_touch(true)
		_send_mobile_touch(false)
	elif _frames >= 6:
		if _main.simulation.state != _main.simulation.RunState.RUNNING:
			push_error("Mobile tap did not start the run.")
			quit(1)
		else:
			print("Dog Run mobile tap test passed.")
			quit(0)
		return true
	return false


func _send_mobile_touch(pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = get_root().get_visible_rect().size * 0.5
	event.pressed = pressed
	_main._input(event)
