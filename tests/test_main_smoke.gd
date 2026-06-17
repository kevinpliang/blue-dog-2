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
	elif not _uses_refreshed_hud():
		push_error("Main scene does not use the refreshed Michroma HUD.")
		quit(1)
	elif not _uses_sound_settings_panel():
		push_error("Main scene does not include the sound settings panel.")
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
	elif not _uses_airborne_duck_visual():
		push_error("Main scene does not show the compact airborne duck roll.")
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
	elif _main.find_child("RunSummary", true, false) == null:
		push_error("Main scene does not include game-over summary.")
		quit(1)
	elif not _uses_first_launch_tutorial():
		push_error("Main scene does not show and persist the first-launch tutorial.")
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
	var score_stack: VBoxContainer = _main.find_child("ScoreStack", true, false)
	if score_stack == null or not is_zero_approx(score_stack.offset_top):
		return false
	return true


func _uses_refreshed_hud() -> bool:
	var score_stack: VBoxContainer = _main.find_child("ScoreStack", true, false)
	var score_label: Label = _main.find_child("ScoreLabel", true, false)
	var multiplier_label: Label = _main.find_child("MultiplierLabel", true, false)
	var summary: VBoxContainer = _main.find_child("RunSummary", true, false)
	var summary_grid: GridContainer = _main.find_child("RunSummaryGrid", true, false)
	var new_high_score_label: Label = _main.find_child("NewHighScoreLabel", true, false)
	var high_score_value: Label = _main.find_child("SummaryHighScoreValue", true, false)
	if score_stack == null or score_label == null or multiplier_label == null:
		return false
	if summary == null or summary_grid == null or new_high_score_label == null or high_score_value == null:
		return false
	if not score_stack.visible or summary.visible or summary_grid.columns != 2:
		return false
	if score_label.text.begins_with("SCORE") or not multiplier_label.visible:
		return false
	if score_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		return false
	if multiplier_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		return false
	var hud_font: FontFile = _main.get("_hud_font")
	if hud_font == null or hud_font.resource_path != "res://assets/fonts/Michroma-Regular.ttf":
		return false
	if hud_font.data.is_empty() or score_label.get_theme_font("font") != hud_font:
		return false
	for label in _main.find_children("*", "Label", true, false):
		if label.get_theme_font("font") != hud_font:
			return false
	if _main.find_child("HighScoreLabel", true, false) != null:
		return false

	var tutorial_save_path := "user://dog_run_hud_smoke.cfg"
	var absolute_path := ProjectSettings.globalize_path(tutorial_save_path)
	DirAccess.remove_absolute(absolute_path)
	_main._save_path = tutorial_save_path
	_main.high_score = 1
	_main.simulation.distance = 20.0
	_main.simulation.state = _main.simulation.RunState.GAME_OVER
	_main._finish_run()
	_main._update_hud()
	var uses_summary := not score_stack.visible
	uses_summary = uses_summary and summary.visible and new_high_score_label.visible
	uses_summary = uses_summary and new_high_score_label.text == "NEW HIGH SCORE"
	uses_summary = uses_summary and high_score_value.text == str(_main.high_score)
	_main.simulation.state = _main.simulation.RunState.RUNNING
	_main._update_hud()
	DirAccess.remove_absolute(absolute_path)
	return uses_summary


func _uses_sound_settings_panel() -> bool:
	var settings_save_path := "user://dog_run_settings_smoke.cfg"
	var absolute_path := ProjectSettings.globalize_path(settings_save_path)
	DirAccess.remove_absolute(absolute_path)
	_main._save_path = settings_save_path

	var button: Button = _main.find_child("SettingsButton", true, false)
	var panel: Control = _main.find_child("SettingsPanel", true, false)
	var blocker: Control = _main.find_child("SettingsModalBlocker", true, false)
	var toggle: Button = _main.find_child("SoundToggleButton", true, false)
	var slider: HSlider = _main.find_child("VolumeSlider", true, false)
	var close_button: Button = _main.find_child("CloseSettingsButton", true, false)
	var volume_value: Label = _main.find_child("VolumeValueLabel", true, false)
	if button == null or panel == null or blocker == null or toggle == null or slider == null or close_button == null or volume_value == null:
		DirAccess.remove_absolute(absolute_path)
		return false
	if button.icon == null or button.icon.resource_path != "res://assets/icons/settings.svg":
		DirAccess.remove_absolute(absolute_path)
		return false
	if button.size.x < MainScript.SETTINGS_BUTTON_SIZE or button.size.y < MainScript.SETTINGS_BUTTON_SIZE:
		DirAccess.remove_absolute(absolute_path)
		return false
	if button.get_theme_constant("icon_max_width") != int(MainScript.SETTINGS_ICON_MAX_WIDTH):
		DirAccess.remove_absolute(absolute_path)
		return false
	if MainScript.SETTINGS_BUTTON_SIZE - MainScript.SETTINGS_ICON_MAX_WIDTH < 48.0:
		DirAccess.remove_absolute(absolute_path)
		return false
	if not is_equal_approx(slider.min_value, 0.0) or not is_equal_approx(slider.max_value, 1.0):
		DirAccess.remove_absolute(absolute_path)
		return false

	_main.simulation.state = _main.simulation.RunState.READY
	_main._update_hud()
	if not button.visible or panel.visible or blocker.visible:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._open_settings()
	if not panel.visible or not blocker.visible:
		DirAccess.remove_absolute(absolute_path)
		return false
	var close_bottom_gap := panel.get_global_rect().end.y - close_button.get_global_rect().end.y
	if close_bottom_gap > 56.0:
		DirAccess.remove_absolute(absolute_path)
		return false
	_main._handle_tap()
	if _main.simulation.state != _main.simulation.RunState.READY:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._set_sound_enabled(false)
	_main._set_sound_volume(0.35)
	_main._save_progress()
	_main._set_sound_enabled(true)
	_main._set_sound_volume(1.0)
	_main._load_progress()
	if _main._sound_enabled or not is_equal_approx(_main._sound_volume, 0.35):
		DirAccess.remove_absolute(absolute_path)
		return false
	var feedback_settings: Dictionary = _main._feedback.sound_settings()
	if bool(feedback_settings["enabled"]) or not is_equal_approx(float(feedback_settings["volume"]), 0.35):
		DirAccess.remove_absolute(absolute_path)
		return false
	if toggle.text != "SOUND: OFF" or volume_value.text != "35%":
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._close_settings()
	_main.simulation.state = _main.simulation.RunState.RUNNING
	_main._update_hud()
	if button.visible or panel.visible or blocker.visible:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main.simulation.state = _main.simulation.RunState.GAME_OVER
	_main._update_hud()
	var visible_on_game_over := button.visible and not panel.visible and not blocker.visible
	_main.simulation.state = _main.simulation.RunState.RUNNING
	_main._update_hud()
	DirAccess.remove_absolute(absolute_path)
	return visible_on_game_over


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


func _uses_airborne_duck_visual() -> bool:
	var pivot: Node3D = _main.find_child("PlayerVisualPivot", true, false)
	if pivot == null:
		return false
	_main.simulation.player_y = 1.0
	_main.simulation.vertical_velocity = 1.0
	_main.simulation.air_duck_time = MainScript.TUNING.air_duck_dive_duration
	_main._update_player(0.01)
	var uses_compact_pose := pivot.scale.y < 1.0
	var stays_airborne := pivot.position.y > 0.75
	_main.simulation.player_y = 0.0
	_main.simulation.vertical_velocity = 0.0
	_main.simulation.air_duck_time = 0.0
	return uses_compact_pose and stays_airborne


func _uses_first_launch_tutorial() -> bool:
	var tutorial_save_path := "user://dog_run_tutorial_smoke.cfg"
	var absolute_path := ProjectSettings.globalize_path(tutorial_save_path)
	DirAccess.remove_absolute(absolute_path)
	_main._save_path = tutorial_save_path
	var start_title: Label = _main.find_child("StartTitleLabel", true, false)
	if start_title == null:
		return false
	_main._tutorial_completed = false
	_main.simulation.state = _main.simulation.RunState.READY
	_main._update_hud()
	if start_title.visible or _main._overlay_label.text != MainScript.FIRST_LAUNCH_TUTORIAL_TEXT:
		DirAccess.remove_absolute(absolute_path)
		return false
	if _main._overlay_label.get_theme_font_size("font_size") != 30:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._tutorial_completed = true
	_main._update_hud()
	if not start_title.visible or start_title.text != "DOG RUN":
		DirAccess.remove_absolute(absolute_path)
		return false
	if start_title.get_theme_font_size("font_size") != 72 or _main._overlay_label.text != "Tap to Start":
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._tutorial_completed = false
	_main._update_hud()
	_main._handle_tap()
	if not _main._tutorial_completed or _main.simulation.state != _main.simulation.RunState.RUNNING:
		DirAccess.remove_absolute(absolute_path)
		return false
	_main._update_hud()
	if start_title.visible or _main._overlay_label.visible:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main.simulation.state = _main.simulation.RunState.GAME_OVER
	_main._update_hud()
	if start_title.visible or _main._overlay_label.visible:
		DirAccess.remove_absolute(absolute_path)
		return false

	var config := ConfigFile.new()
	var persisted := config.load(tutorial_save_path) == OK
	persisted = persisted and bool(config.get_value("progress", "tutorial_completed", false))
	DirAccess.remove_absolute(absolute_path)
	return persisted
