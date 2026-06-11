extends SceneTree

const MainScript = preload("res://game/main.gd")

var _main: Node
var _frames := 0


func _init() -> void:
	_main = preload("res://game/main.tscn").instantiate()
	root.add_child(_main)
	_main.simulation.start(12345)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 8:
		return false

	if _main.simulation.state != _main.simulation.RunState.RUNNING:
		push_error("Main scene did not keep an active run alive.")
		quit(1)
	elif _main._obstacle_nodes.is_empty():
		push_error("Main scene did not render active simulation obstacles.")
		quit(1)
	elif _main.find_child("PlayerLight", true, false) == null:
		push_error("Main scene does not include a soft player light.")
		quit(1)
	elif not _obstacles_use_distance_fade():
		push_error("Active obstacle materials do not use the tuned distance fade.")
		quit(1)
	elif not _track_uses_distance_fade():
		push_error("Track visuals do not use the distance fade shader.")
		quit(1)
	elif not _track_extends_behind_camera():
		push_error("Track visuals do not extend behind the camera.")
		quit(1)
	elif not _uses_adaptive_fullscreen_layout():
		push_error("Main scene does not use adaptive full-screen layout.")
		quit(1)
	elif _main.find_child("HudSafeArea", true, false) == null:
		push_error("Main scene does not include a HUD safe-area container.")
		quit(1)
	elif _main.find_child("FeedbackController", true, false) == null:
		push_error("Main scene does not include feedback.")
		quit(1)
	elif _main.find_child("RestartFade", true, false) == null:
		push_error("Main scene does not include restart transition.")
		quit(1)
	elif _main.find_child("MultiplierLabel", true, false) == null:
		push_error("Main scene does not include live multiplier HUD.")
		quit(1)
	elif _main.find_child("RunSummaryLabel", true, false) == null:
		push_error("Main scene does not include game-over summary.")
		quit(1)
	else:
		print("Dog Run active scene smoke test passed.")
		quit(0)
	return true


func _obstacles_use_distance_fade() -> bool:
	for obstacle_node in _main._obstacle_nodes.values():
		if not obstacle_node.material_override is ShaderMaterial:
			return false
		var material: ShaderMaterial = obstacle_node.material_override
		if material.shader == null or material.shader.resource_path != "res://game/shaders/obstacle_distance_fade.gdshader":
			return false
		var base_color: Color = material.get_shader_parameter("base_color")
		if not is_equal_approx(base_color.a, MainScript.OBSTACLE_OPACITY):
			return false
		if not is_equal_approx(float(material.get_shader_parameter("fade_start")), MainScript.TUNING.obstacle_fade_start):
			return false
		if not is_equal_approx(float(material.get_shader_parameter("fade_end")), MainScript.TUNING.obstacle_fade_end):
			return false
	return true


func _track_uses_distance_fade() -> bool:
	for node_name in ["Track", "LaneDividerLeft", "LaneDividerRight", "TrackEdgeLeft", "TrackEdgeRight"]:
		var node: MeshInstance3D = _main.find_child(node_name, true, false)
		if node == null or not node.material_override is ShaderMaterial:
			return false
		var material: ShaderMaterial = node.material_override
		if material.shader == null or material.shader.resource_path != "res://game/shaders/distance_fade.gdshader":
			return false
	return true


func _track_extends_behind_camera() -> bool:
	for node_name in ["Track", "LaneDividerLeft", "LaneDividerRight", "TrackEdgeLeft", "TrackEdgeRight"]:
		var node: MeshInstance3D = _main.find_child(node_name, true, false)
		if node == null or not node.mesh is BoxMesh:
			return false
		var box: BoxMesh = node.mesh
		var near_edge := node.position.z + box.size.z * 0.5
		if near_edge <= _main._camera.position.z:
			return false
	return true


func _uses_adaptive_fullscreen_layout() -> bool:
	if ProjectSettings.get_setting("display/window/stretch/aspect", "") != "expand":
		return false
	if _main._camera.keep_aspect != Camera3D.KEEP_WIDTH:
		return false
	if not is_zero_approx(_main._score_label.offset_top):
		return false
	if not is_zero_approx(_main._high_score_label.offset_top):
		return false
	return true
