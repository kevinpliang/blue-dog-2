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
	elif not _uses_moderate_lower_third_framing():
		push_error("Main scene does not use the tuned moderate lower-third framing.")
		quit(1)
	elif not _uses_textured_rolling_player():
		push_error("Main scene does not map the supplied texture onto the rolling player.")
		quit(1)
	elif not _uses_movement_feedback():
		push_error("Main scene does not include tuned player movement feedback.")
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
		_main._feedback.set_feedback_paused(true)
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


func _uses_moderate_lower_third_framing() -> bool:
	if not is_equal_approx(_main._camera.fov, MainScript.TUNING.camera_fov):
		return false
	if not is_equal_approx(_main._player_visual_pivot.position.z, MainScript.TUNING.visual_action_plane_z):
		return false
	if not is_equal_approx(_main._player_light.position.z, MainScript.TUNING.visual_action_plane_z):
		return false

	var checked_obstacle := false
	for obstacle in _main.simulation.obstacles:
		var obstacle_id: int = obstacle["id"]
		if not _main._obstacle_nodes.has(obstacle_id):
			continue
		checked_obstacle = true
		var obstacle_node: MeshInstance3D = _main._obstacle_nodes[obstacle_id]
		if not is_equal_approx(obstacle_node.position.z - float(obstacle["z"]), MainScript.TUNING.visual_action_plane_z):
			return false
	return checked_obstacle


func _uses_textured_rolling_player() -> bool:
	if not _main._player.material_override is StandardMaterial3D:
		return false
	var material: StandardMaterial3D = _main._player.material_override
	if material.albedo_texture == null or material.albedo_texture.resource_path != "res://assets/player/white.png":
		return false
	if material.texture_repeat:
		return false
	if not material.uv1_scale.is_equal_approx(Vector3(4.0, 1.0, 1.0)):
		return false
	if not material.uv1_offset.is_equal_approx(Vector3(-1.5, 0.0, 0.0)):
		return false
	var roll_angle: Variant = _main.get("_player_roll_angle")
	return roll_angle is float and not is_zero_approx(float(roll_angle))


func _uses_movement_feedback() -> bool:
	var pivot: Node3D = _main.find_child("PlayerVisualPivot", true, false)
	if pivot == null or _main.find_child("PlayerSpeedTrail", true, false) != null:
		return false
	if not _main.has_method("_handle_player_feedback_events"):
		return false

	_main.simulation.change_lane(1)
	_main.advance_simulation(0.05)
	_main._update_player(0.05)
	if is_zero_approx(pivot.rotation.z):
		return false

	_main.simulation.player_y = 0.5
	_main.simulation.vertical_velocity = MainScript.TUNING.jump_velocity
	_main._update_player(0.01)
	if pivot.scale.y <= 1.0 or pivot.scale.x >= 1.0:
		return false

	_main._handle_player_feedback_events([{"type": "landed"}])
	if _main._landing_pulse_time <= 0.0:
		return false
	_main.simulation.player_y = 0.0
	_main.simulation.vertical_velocity = 0.0
	_main._update_player(MainScript.TUNING.landing_pulse_duration * 0.5)
	if pivot.scale.x <= 1.0 or pivot.scale.y >= 1.0:
		return false

	var before_duck_roll: Variant = _main.get("_player_roll_angle")
	if not before_duck_roll is float:
		return false
	_main.simulation.duck()
	if _main.simulation.duck_time <= 0.0:
		return false
	_main._update_player(0.05)
	var after_duck_roll: float = float(_main.get("_player_roll_angle"))
	if is_equal_approx(after_duck_roll, float(before_duck_roll)):
		return false
	var expected_basis := Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, after_duck_roll)
	return _main._player.basis.is_equal_approx(expected_basis)
