extends Node3D

const Simulation = preload("res://game/runner_simulation.gd")
const InputInterpreter = preload("res://game/input_interpreter.gd")
const FeedbackController = preload("res://game/feedback_controller.gd")
const PerformanceMonitor = preload("res://game/performance_monitor.gd")
const LimitsScript = preload("res://game/runtime_limits.gd")
const TUNING = preload("res://game/default_runner_tuning.tres")
const DISTANCE_FADE_SHADER = preload("res://game/shaders/distance_fade.gdshader")
const SAVE_PATH := "user://dog_run.cfg"
const MAX_OBSTACLE_NODES := LimitsScript.MAX_OBSTACLE_NODES
const OBSTACLE_OPACITY := 0.4

var simulation = Simulation.new()
var input_interpreter = InputInterpreter.new()
var performance_monitor = PerformanceMonitor.new()
var high_score := 0
var _app_paused := false
var _pointer_start := Vector2.ZERO
var _pointer_tracking := false
var _obstacle_nodes := {}
var _obstacle_pool: Array[MeshInstance3D] = []

var _player: MeshInstance3D
var _player_light: OmniLight3D
var _camera: Camera3D
var _feedback: FeedbackController
var _score_label: Label
var _high_score_label: Label
var _multiplier_label: Label
var _overlay_label: Label
var _run_summary_label: Label
var _restart_fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_world()
	_feedback = FeedbackController.new()
	_feedback.name = "FeedbackController"
	add_child(_feedback)
	_feedback.setup(_camera)
	_build_hud()
	_load_high_score()
	_update_hud()


func _process(delta: float) -> void:
	if _app_paused:
		return

	_handle_keyboard()
	var previous_state: int = simulation.state
	advance_simulation(delta)
	_feedback.handle_events(simulation.drain_events(), _player.position)
	if previous_state != simulation.state and simulation.state == Simulation.RunState.GAME_OVER:
		_finish_run()

	_update_player(delta)
	_sync_obstacles()
	_update_hud()
	performance_monitor.sample(delta, _obstacle_nodes.size())
	var report := performance_monitor.take_report()
	if not report.is_empty() and OS.is_debug_build() and DisplayServer.get_name() != "headless":
		print("DogRun perf: avg=%.1fms worst=%.1fms slow=%d obstacles=%d" % [
			report["average_ms"],
			report["worst_ms"],
			report["slow_frames"],
			report["obstacles"],
		])


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_start = event.position
			_pointer_tracking = true
		elif _pointer_tracking:
			_pointer_tracking = false
			_handle_pointer_release(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_start = event.position
			_pointer_tracking = true
		elif _pointer_tracking:
			_pointer_tracking = false
			_handle_pointer_release(event.position)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			set_app_paused(true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			set_app_paused(false)


func set_app_paused(value: bool) -> void:
	_app_paused = value
	if _feedback != null:
		_feedback.set_feedback_paused(value)


func advance_simulation(delta: float) -> void:
	if not _app_paused:
		simulation.step(delta)


func _handle_pointer_release(end_position: Vector2) -> void:
	var command: int = input_interpreter.interpret(
		_pointer_start,
		end_position,
		get_viewport().get_visible_rect().size
	)
	match command:
		InputInterpreter.Command.TAP:
			_handle_tap()
		InputInterpreter.Command.LEFT:
			simulation.change_lane(-1)
		InputInterpreter.Command.RIGHT:
			simulation.change_lane(1)
		InputInterpreter.Command.JUMP:
			simulation.jump()
		InputInterpreter.Command.DUCK:
			simulation.duck()


func _handle_tap() -> void:
	if simulation.state == Simulation.RunState.READY or simulation.state == Simulation.RunState.GAME_OVER:
		simulation.start(int(Time.get_ticks_usec()))
		_play_restart_fade()


func _handle_keyboard() -> void:
	if Input.is_action_just_pressed("ui_left"):
		simulation.change_lane(-1)
	if Input.is_action_just_pressed("ui_right"):
		simulation.change_lane(1)
	if Input.is_action_just_pressed("ui_up"):
		simulation.jump()
	if Input.is_action_just_pressed("ui_down"):
		simulation.duck()
	if Input.is_action_just_pressed("ui_accept"):
		_handle_tap()


func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.48, 0.55)
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.light_color = Color(0.8, 0.9, 1.0)
	light.light_energy = 1.5
	light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	light.shadow_enabled = false
	add_child(light)

	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 5.7, 10.0)
	_camera.fov = 64.0
	_camera.current = true
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.8, -13.0), Vector3.UP)

	_add_fading_box(
		"Track",
		Vector3(8.6, 0.2, 220.0),
		Vector3(0.0, -0.12, -105.0),
		Color(0.035, 0.045, 0.065)
	)
	_add_fading_box("LaneDividerLeft", Vector3(0.07, 0.035, 220.0), Vector3(-1.2, 0.01, -105.0), Color(0.0, 0.9, 1.0))
	_add_fading_box("LaneDividerRight", Vector3(0.07, 0.035, 220.0), Vector3(1.2, 0.01, -105.0), Color(0.0, 0.9, 1.0))
	_add_fading_box("TrackEdgeLeft", Vector3(0.12, 0.12, 220.0), Vector3(-4.25, 0.02, -105.0), Color(0.0, 0.55, 0.7))
	_add_fading_box("TrackEdgeRight", Vector3(0.12, 0.12, 220.0), Vector3(4.25, 0.02, -105.0), Color(0.0, 0.55, 0.7))

	_player = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.75
	sphere.height = 1.5
	sphere.radial_segments = 20
	sphere.rings = 12
	_player.mesh = sphere
	_player.material_override = _make_material(Color.WHITE)
	_player.position = Vector3(0.0, 0.75, 0.0)
	add_child(_player)

	_player_light = OmniLight3D.new()
	_player_light.name = "PlayerLight"
	_player_light.light_color = Color(0.0, 0.82, 1.0)
	_player_light.light_energy = 1.15
	_player_light.omni_range = 7.0
	_player_light.omni_attenuation = 1.6
	_player_light.shadow_enabled = false
	_player_light.position = Vector3(0.0, 1.2, 1.0)
	add_child(_player_light)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_restart_fade = ColorRect.new()
	_restart_fade.name = "RestartFade"
	_restart_fade.color = Color.BLACK
	_restart_fade.modulate.a = 0.0
	_restart_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_restart_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(_restart_fade)

	var safe_area := MarginContainer.new()
	safe_area.name = "HudSafeArea"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_safe_area_margins(safe_area)
	canvas.add_child(safe_area)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_child(root)

	_score_label = Label.new()
	_score_label.offset_left = 24.0
	_score_label.offset_top = 20.0
	_score_label.offset_right = 300.0
	_score_label.offset_bottom = 80.0
	_style_label(_score_label, 30)
	root.add_child(_score_label)

	_high_score_label = Label.new()
	_high_score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_high_score_label.offset_left = -320.0
	_high_score_label.offset_top = 20.0
	_high_score_label.offset_right = -24.0
	_high_score_label.offset_bottom = 80.0
	_high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_high_score_label, 30)
	root.add_child(_high_score_label)

	_multiplier_label = Label.new()
	_multiplier_label.name = "MultiplierLabel"
	_multiplier_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_multiplier_label.offset_top = 60.0
	_multiplier_label.offset_bottom = 110.0
	_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_multiplier_label, 28)
	root.add_child(_multiplier_label)

	_overlay_label = Label.new()
	_overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	_overlay_label.offset_left = -300.0
	_overlay_label.offset_top = -90.0
	_overlay_label.offset_right = 300.0
	_overlay_label.offset_bottom = 90.0
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_overlay_label, 42)
	root.add_child(_overlay_label)

	_run_summary_label = Label.new()
	_run_summary_label.name = "RunSummaryLabel"
	_run_summary_label.set_anchors_preset(Control.PRESET_CENTER)
	_run_summary_label.offset_left = -300.0
	_run_summary_label.offset_top = -180.0
	_run_summary_label.offset_right = 300.0
	_run_summary_label.offset_bottom = 220.0
	_run_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_run_summary_label, 34)
	root.add_child(_run_summary_label)

func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _add_box(size: Vector3, position: Vector3, color: Color, emission := false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.material_override = _make_material(color, emission)
	add_child(mesh_instance)
	return mesh_instance


func _add_fading_box(node_name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	var material := ShaderMaterial.new()
	box.size = size
	material.shader = DISTANCE_FADE_SHADER
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("fade_start", TUNING.track_fade_start)
	material.set_shader_parameter("fade_end", TUNING.track_fade_end)
	mesh_instance.name = node_name
	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance


func _apply_safe_area_margins(container: MarginContainer) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_rect := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	var left := 24
	var top := 20
	var right := 24
	var bottom := 20
	if OS.has_feature("mobile") and safe_rect.size.x > 0 and safe_rect.size.y > 0 and screen_size.x > 0 and screen_size.y > 0:
		var scale := Vector2(viewport_size.x / screen_size.x, viewport_size.y / screen_size.y)
		left = maxi(left, int(safe_rect.position.x * scale.x))
		top = maxi(top, int(safe_rect.position.y * scale.y))
		right = maxi(right, int((screen_size.x - safe_rect.end.x) * scale.x))
		bottom = maxi(bottom, int((screen_size.y - safe_rect.end.y) * scale.y))
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)


func _make_material(color: Color, emission := false, opacity := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, opacity)
	material.roughness = 0.75
	if opacity < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.4
	return material


func _update_player(delta: float) -> void:
	_player.position.x = simulation.current_x
	_player.position.y = 0.75 + simulation.player_y
	_player_light.position = Vector3(_player.position.x, _player.position.y + 0.45, 1.0)

	if simulation.state == Simulation.RunState.IMPACT:
		_player.scale = Vector3.ONE * 1.15
	elif simulation.duck_time > 0.0:
		_player.scale = Vector3(1.0, 0.55, 1.0)
		_player.position.y = 0.43
	else:
		_player.scale = Vector3.ONE

	if simulation.state == Simulation.RunState.RUNNING:
		_player.rotate_x(-simulation.speed * delta / 0.75)


func _sync_obstacles() -> void:
	var active_ids := {}
	for obstacle in simulation.obstacles:
		var obstacle_id: int = obstacle["id"]
		var obstacle_type: int = obstacle["type"]
		active_ids[obstacle_id] = true

		var mesh_instance: MeshInstance3D
		if _obstacle_nodes.has(obstacle_id):
			mesh_instance = _obstacle_nodes[obstacle_id]
		else:
			mesh_instance = _acquire_obstacle()
			if mesh_instance == null:
				continue
			_obstacle_nodes[obstacle_id] = mesh_instance

		if not mesh_instance.has_meta("obstacle_type") or int(mesh_instance.get_meta("obstacle_type")) != obstacle_type:
			_configure_obstacle(mesh_instance, obstacle_type)
		mesh_instance.position = Vector3(
			simulation.lane_x(int(obstacle["lane"])),
			_obstacle_y(obstacle_type),
			float(obstacle["z"])
		)
		mesh_instance.visible = true

	for obstacle_id in _obstacle_nodes.keys():
		if active_ids.has(obstacle_id):
			continue
		var mesh_instance: MeshInstance3D = _obstacle_nodes[obstacle_id]
		_obstacle_nodes.erase(obstacle_id)
		mesh_instance.visible = false
		_obstacle_pool.append(mesh_instance)


func _acquire_obstacle() -> MeshInstance3D:
	if not _obstacle_pool.is_empty():
		return _obstacle_pool.pop_back()
	if _obstacle_nodes.size() + _obstacle_pool.size() >= MAX_OBSTACLE_NODES:
		return null
	var mesh_instance := MeshInstance3D.new()
	add_child(mesh_instance)
	return mesh_instance


func _configure_obstacle(mesh_instance: MeshInstance3D, obstacle_type: int) -> void:
	var box := BoxMesh.new()
	match obstacle_type:
		Simulation.ObstacleType.GROUND_BLOCK:
			box.size = Vector3(1.65, 1.55, 1.1)
			mesh_instance.material_override = _make_material(Color(1.0, 0.38, 0.08), true, OBSTACLE_OPACITY)
		Simulation.ObstacleType.OVERHEAD_BAR:
			box.size = Vector3(1.9, 0.5, 1.1)
			mesh_instance.material_override = _make_material(Color(0.85, 0.15, 1.0), true, OBSTACLE_OPACITY)
		Simulation.ObstacleType.WALL:
			box.size = Vector3(1.9, 3.2, 0.85)
			mesh_instance.material_override = _make_material(Color(1.0, 0.08, 0.38), true, OBSTACLE_OPACITY)
	mesh_instance.mesh = box
	mesh_instance.set_meta("obstacle_type", obstacle_type)


func _obstacle_y(obstacle_type: int) -> float:
	match obstacle_type:
		Simulation.ObstacleType.GROUND_BLOCK:
			return 0.775
		Simulation.ObstacleType.OVERHEAD_BAR:
			return 1.75
		Simulation.ObstacleType.WALL:
			return 1.6
	return 0.0


func _update_hud() -> void:
	_score_label.text = "SCORE  %d" % simulation.score()
	_high_score_label.text = "BEST  %d" % high_score
	_multiplier_label.text = "x%d" % simulation.multiplier
	_multiplier_label.visible = simulation.state == Simulation.RunState.RUNNING and simulation.multiplier > 1
	_run_summary_label.visible = false

	match simulation.state:
		Simulation.RunState.READY:
			_overlay_label.text = "DOG RUN\nTap to Start"
			_overlay_label.visible = true
		Simulation.RunState.GAME_OVER:
			_overlay_label.visible = false
			_run_summary_label.text = "GAME OVER\n\nDistance  %dm\nPeak  x%d\nNear Misses  %d\nScore  %d\n\nTap to Restart" % [
				simulation.distance_score(),
				simulation.peak_multiplier,
				simulation.near_miss_count,
				simulation.final_score(),
			]
			_run_summary_label.visible = true
		_:
			_overlay_label.visible = false


func _finish_run() -> void:
	var updated := Simulation.updated_high_score(high_score, simulation.score())
	if updated == high_score:
		return
	high_score = updated
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)


func _load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = int(config.get_value("scores", "high_score", 0))


func _play_restart_fade() -> void:
	if _restart_fade == null:
		return
	_restart_fade.modulate.a = 0.85
	var tween := create_tween()
	tween.tween_property(_restart_fade, "modulate:a", 0.0, 0.18)
