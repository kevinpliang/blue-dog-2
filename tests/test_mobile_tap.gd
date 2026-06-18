extends SceneTree

var _main: Node
var _frames := 0
var _pending_exit_code := -1
var _pending_exit_frames := 0


func _init() -> void:
	_main = preload("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	if _pending_exit_code >= 0:
		_pending_exit_frames -= 1
		if _pending_exit_frames <= 0:
			quit(_pending_exit_code)
		return true

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
			_finish(0)
		return true
	return false


func _finish(exit_code: int) -> void:
	if _main != null:
		if _main._music_player != null:
			_main._music_player.stop()
			_main._music_player.stream = null
		root.remove_child(_main)
		_main.free()
		_main = null
	_pending_exit_code = exit_code
	_pending_exit_frames = 6


func _send_mobile_touch(pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = get_root().get_visible_rect().size * 0.5
	event.pressed = pressed
	_main._input(event)
