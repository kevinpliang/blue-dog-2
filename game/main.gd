extends Node3D

const Simulation = preload("res://game/runner_simulation.gd")
const InputInterpreter = preload("res://game/input_interpreter.gd")
const FeedbackController = preload("res://game/feedback_controller.gd")
const PerformanceMonitor = preload("res://game/performance_monitor.gd")
const LimitsScript = preload("res://game/runtime_limits.gd")
const TUNING = preload("res://game/default_runner_tuning.tres")
const DISTANCE_FADE_SHADER = preload("res://game/shaders/distance_fade.gdshader")
const OBSTACLE_DISTANCE_FADE_SHADER = preload("res://game/shaders/obstacle_distance_fade.gdshader")
const PLAYER_TEXTURE = preload("res://assets/player/white.png")
const HUD_FONT: FontFile = preload("res://assets/fonts/Michroma-Regular.ttf")
const SETTINGS_ICON: Texture2D = preload("res://assets/icons/settings.svg")
const SAVE_PATH := "user://dog_run.cfg"
const FIRST_LAUNCH_TUTORIAL_TEXT := "SWIPE LEFT / RIGHT TO MOVE\nSWIPE UP TO JUMP\nSWIPE DOWN TO DUCK\n\nTap to Start"
const MAX_OBSTACLE_NODES := LimitsScript.MAX_OBSTACLE_NODES
const MAX_COIN_NODES := 128
const COIN_COLOR := Color(1.0, 0.78, 0.08)
const COIN_OPACITY := 0.68
const COIN_RADIUS := 0.42
const COIN_THICKNESS := 0.12
const COIN_ROTATION_SPEED := 2.4
const OBSTACLE_OPACITY := 0.4
const PLAYER_TEXTURE_UV_SCALE := Vector3(4.0, 1.0, 1.0)
const PLAYER_TEXTURE_UV_OFFSET := Vector3(-1.5, 0.0, 0.0)
const TRACK_LENGTH := 250.0
const TRACK_CENTER_Z := -90.0
const DEFAULT_SOUND_ENABLED := true
const DEFAULT_SOUND_VOLUME := 1.0
const HUD_EDGE_MARGIN := 0.0
const HUD_TEXT_TOP_ADJUSTMENT := -14.0
const SETTINGS_BUTTON_SIZE := 96.0
const SETTINGS_ICON_MAX_WIDTH := 64.0
const SETTINGS_BUTTON_TOP_MARGIN := HUD_EDGE_MARGIN
const SETTINGS_BUTTON_RIGHT_MARGIN := HUD_EDGE_MARGIN

var simulation = Simulation.new()
var input_interpreter = InputInterpreter.new()
var performance_monitor = PerformanceMonitor.new()
var high_score := 0
var _total_coins := 0
var _save_path := SAVE_PATH
var _tutorial_completed := false
var _sound_enabled := DEFAULT_SOUND_ENABLED
var _sound_volume := DEFAULT_SOUND_VOLUME
var _app_paused := false
var _pointer_start := Vector2.ZERO
var _pointer_tracking := false
var _obstacle_nodes := {}
var _obstacle_pool: Array[MeshInstance3D] = []
var _coin_nodes := {}
var _coin_pool: Array[MeshInstance3D] = []

var _player_visual_pivot: Node3D
var _player: MeshInstance3D
var _player_light: OmniLight3D
var _camera: Camera3D
var _feedback: FeedbackController
var _hud_font: FontFile
var _score_stack: VBoxContainer
var _score_label: Label
var _multiplier_label: Label
var _coin_label: Label
var _start_title_label: Label
var _overlay_label: Label
var _run_summary: VBoxContainer
var _new_high_score_label: Label
var _run_summary_values := {}
var _settings_button: Button
var _settings_modal_blocker: ColorRect
var _settings_panel: PanelContainer
var _sound_toggle_button: Button
var _volume_slider: HSlider
var _volume_value_label: Label
var _restart_fade: ColorRect
var _previous_player_x := 0.0
var _landing_pulse_time := 0.0
var _player_roll_angle := 0.0
var _new_high_score := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_world()
	_feedback = FeedbackController.new()
	_feedback.name = "FeedbackController"
	add_child(_feedback)
	_feedback.setup(_camera)
	_build_hud()
	_load_progress()
	_update_hud()


func _process(delta: float) -> void:
	if _app_paused:
		return

	_handle_keyboard()
	var previous_state: int = simulation.state
	advance_simulation(delta)
	var events := simulation.drain_events()
	_feedback.handle_events(events, _player_visual_pivot.position)
	_handle_player_feedback_events(events)
	_handle_coin_events(events)
	if previous_state != simulation.state and simulation.state == Simulation.RunState.GAME_OVER:
		_finish_run()

	_update_player(delta)
	_sync_obstacles()
	_sync_coins(delta)
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
	if _settings_open():
		return
	if _settings_button != null and _settings_button.visible and _settings_button.get_global_rect().has_point(end_position):
		_open_settings()
		return
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
	if _settings_open():
		return
	if simulation.state == Simulation.RunState.READY or simulation.state == Simulation.RunState.GAME_OVER:
		if simulation.state == Simulation.RunState.READY and not _tutorial_completed:
			_tutorial_completed = true
			_save_progress()
		_new_high_score = false
		simulation.start(int(Time.get_ticks_usec()))
		_previous_player_x = simulation.current_x
		_landing_pulse_time = 0.0
		_play_restart_fade()


func _open_settings() -> void:
	if _settings_panel == null or _settings_modal_blocker == null:
		return
	if simulation.state != Simulation.RunState.READY and simulation.state != Simulation.RunState.GAME_OVER:
		return
	_sync_settings_controls()
	_settings_modal_blocker.visible = true
	_settings_panel.visible = true


func _close_settings() -> void:
	if _settings_panel != null:
		_settings_panel.visible = false
	if _settings_modal_blocker != null:
		_settings_modal_blocker.visible = false


func _settings_open() -> bool:
	return _settings_panel != null and _settings_panel.visible


func _toggle_sound() -> void:
	_set_sound_enabled(not _sound_enabled)


func _set_sound_enabled(value: bool) -> void:
	_sound_enabled = value
	_apply_sound_settings()
	_sync_settings_controls()
	_save_progress()


func _set_sound_volume(value: float) -> void:
	_sound_volume = clampf(value, 0.0, 1.0)
	_apply_sound_settings()
	_sync_settings_controls()
	_save_progress()


func _apply_sound_settings() -> void:
	if _feedback != null:
		_feedback.set_sound_settings(_sound_enabled, _sound_volume)


func _sync_settings_controls() -> void:
	if _sound_toggle_button != null:
		_sound_toggle_button.text = "SOUND: ON" if _sound_enabled else "SOUND: OFF"
	if _volume_slider != null and not is_equal_approx(_volume_slider.value, _sound_volume):
		_volume_slider.set_value_no_signal(_sound_volume)
	if _volume_value_label != null:
		_volume_value_label.text = "%d%%" % roundi(_sound_volume * 100.0)


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
	_camera.fov = TUNING.camera_fov
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.current = true
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.8, -13.0), Vector3.UP)

	_add_fading_box(
		"Track",
		Vector3(8.6, 0.2, TRACK_LENGTH),
		Vector3(0.0, -0.12, TRACK_CENTER_Z),
		Color(0.035, 0.045, 0.065)
	)
	_add_fading_box("LaneDividerLeft", Vector3(0.07, 0.035, TRACK_LENGTH), Vector3(-1.2, 0.01, TRACK_CENTER_Z), Color(0.0, 0.9, 1.0))
	_add_fading_box("LaneDividerRight", Vector3(0.07, 0.035, TRACK_LENGTH), Vector3(1.2, 0.01, TRACK_CENTER_Z), Color(0.0, 0.9, 1.0))
	_add_fading_box("TrackEdgeLeft", Vector3(0.12, 0.12, TRACK_LENGTH), Vector3(-4.25, 0.02, TRACK_CENTER_Z), Color(0.0, 0.55, 0.7))
	_add_fading_box("TrackEdgeRight", Vector3(0.12, 0.12, TRACK_LENGTH), Vector3(4.25, 0.02, TRACK_CENTER_Z), Color(0.0, 0.55, 0.7))

	_player_visual_pivot = Node3D.new()
	_player_visual_pivot.name = "PlayerVisualPivot"
	_player_visual_pivot.position = Vector3(0.0, 0.75, TUNING.visual_action_plane_z)
	add_child(_player_visual_pivot)

	_player = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.75
	sphere.height = 1.5
	sphere.radial_segments = 20
	sphere.rings = 12
	_player.mesh = sphere
	_player.material_override = _make_player_material()
	_player.basis = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, _player_roll_angle)
	_player_visual_pivot.add_child(_player)

	_player_light = OmniLight3D.new()
	_player_light.name = "PlayerLight"
	_player_light.light_color = Color(0.0, 0.82, 1.0)
	_player_light.light_energy = 1.15
	_player_light.omni_range = 7.0
	_player_light.omni_attenuation = 1.6
	_player_light.shadow_enabled = false
	_player_light.position = Vector3(0.0, 1.2, TUNING.visual_action_plane_z)
	add_child(_player_light)


func _build_hud() -> void:
	_hud_font = HUD_FONT

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

	_score_stack = VBoxContainer.new()
	_score_stack.name = "ScoreStack"
	_score_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_score_stack.offset_left = -400.0
	_score_stack.offset_top = HUD_EDGE_MARGIN + HUD_TEXT_TOP_ADJUSTMENT
	_score_stack.offset_right = -HUD_EDGE_MARGIN
	_score_stack.offset_bottom = HUD_EDGE_MARGIN + HUD_TEXT_TOP_ADJUSTMENT + 150.0
	root.add_child(_score_stack)

	_coin_label = Label.new()
	_coin_label.name = "CoinLabel"
	_coin_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_coin_label.offset_left = HUD_EDGE_MARGIN
	_coin_label.offset_top = HUD_EDGE_MARGIN + HUD_TEXT_TOP_ADJUSTMENT + 20
	_coin_label.offset_right = HUD_EDGE_MARGIN + 420.0
	_coin_label.offset_bottom = HUD_EDGE_MARGIN + HUD_TEXT_TOP_ADJUSTMENT + 110.0
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_label(_coin_label, 32)
	_coin_label.add_theme_color_override("font_color", COIN_COLOR)
	root.add_child(_coin_label)

	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_score_label, 80)
	_score_stack.add_child(_score_label)

	_multiplier_label = Label.new()
	_multiplier_label.name = "MultiplierLabel"
	_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_multiplier_label, 32)
	_multiplier_label.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	_score_stack.add_child(_multiplier_label)

	_start_title_label = Label.new()
	_start_title_label.name = "StartTitleLabel"
	_start_title_label.text = "DOG RUN"
	_start_title_label.set_anchors_preset(Control.PRESET_CENTER)
	_start_title_label.offset_left = -300.0
	_start_title_label.offset_top = -110.0
	_start_title_label.offset_right = 300.0
	_start_title_label.offset_bottom = -30.0
	_start_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_start_title_label, 72)
	root.add_child(_start_title_label)

	_overlay_label = Label.new()
	_overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	_overlay_label.offset_left = -300.0
	_overlay_label.offset_top = -90.0
	_overlay_label.offset_right = 300.0
	_overlay_label.offset_bottom = 90.0
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_overlay_label, 30)
	root.add_child(_overlay_label)

	_run_summary = VBoxContainer.new()
	_run_summary.name = "RunSummary"
	_run_summary.set_anchors_preset(Control.PRESET_CENTER)
	_run_summary.offset_left = -320.0
	_run_summary.offset_top = -270.0
	_run_summary.offset_right = 320.0
	_run_summary.offset_bottom = 300.0
	_run_summary.add_theme_constant_override("separation", 18)
	root.add_child(_run_summary)

	_new_high_score_label = Label.new()
	_new_high_score_label.name = "NewHighScoreLabel"
	_new_high_score_label.text = "NEW HIGH SCORE"
	_new_high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_new_high_score_label, 38)
	_new_high_score_label.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	_run_summary.add_child(_new_high_score_label)

	var game_over_label := Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = "GAME OVER"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(game_over_label, 44)
	_run_summary.add_child(game_over_label)

	var summary_margin := MarginContainer.new()
	summary_margin.name = "RunSummaryMargin"
	summary_margin.add_theme_constant_override("margin_left", 48)
	summary_margin.add_theme_constant_override("margin_right", 48)
	_run_summary.add_child(summary_margin)

	var summary_grid := GridContainer.new()
	summary_grid.name = "RunSummaryGrid"
	summary_grid.columns = 2
	summary_grid.add_theme_constant_override("h_separation", 48)
	summary_grid.add_theme_constant_override("v_separation", 14)
	summary_margin.add_child(summary_grid)
	_add_summary_row(summary_grid, "distance", "DISTANCE")
	_add_summary_row(summary_grid, "peak_multiplier", "PEAK MULTIPLIER")
	_add_summary_row(summary_grid, "score", "SCORE")
	_add_summary_row(summary_grid, "high_score", "HIGH SCORE")

	var restart_label := Label.new()
	restart_label.name = "RestartLabel"
	restart_label.text = "Tap to Restart"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(restart_label, 28)
	_run_summary.add_child(restart_label)

	_build_settings_ui(root)


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_override("font", _hud_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _make_ui_box_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style


func _add_summary_row(grid: GridContainer, key: String, title_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(title, 28)
	grid.add_child(title)

	var value := Label.new()
	value.name = "Summary%sValue" % key.to_pascal_case()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(value, 28)
	grid.add_child(value)
	_run_summary_values[key] = value


func _build_settings_ui(root: Control) -> void:
	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_settings_button.offset_left = -(SETTINGS_BUTTON_RIGHT_MARGIN + SETTINGS_BUTTON_SIZE)
	_settings_button.offset_top = SETTINGS_BUTTON_TOP_MARGIN
	_settings_button.offset_right = -SETTINGS_BUTTON_RIGHT_MARGIN
	_settings_button.offset_bottom = SETTINGS_BUTTON_TOP_MARGIN + SETTINGS_BUTTON_SIZE
	_settings_button.custom_minimum_size = Vector2(SETTINGS_BUTTON_SIZE, SETTINGS_BUTTON_SIZE)
	_settings_button.icon = SETTINGS_ICON
	_settings_button.expand_icon = true
	_settings_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_button.focus_mode = Control.FOCUS_NONE
	_settings_button.add_theme_constant_override("icon_max_width", int(SETTINGS_ICON_MAX_WIDTH))
	_settings_button.add_theme_stylebox_override("normal", _make_ui_box_style(Color(0.0, 0.0, 0.0, 0.55), Color(0.0, 0.85, 1.0), 18))
	_settings_button.add_theme_stylebox_override("hover", _make_ui_box_style(Color(0.0, 0.18, 0.22, 0.72), Color(0.0, 0.95, 1.0), 18))
	_settings_button.add_theme_stylebox_override("pressed", _make_ui_box_style(Color(0.0, 0.35, 0.42, 0.85), Color.WHITE, 18))
	_settings_button.pressed.connect(_open_settings)
	root.add_child(_settings_button)

	_settings_modal_blocker = ColorRect.new()
	_settings_modal_blocker.name = "SettingsModalBlocker"
	_settings_modal_blocker.color = Color(0.0, 0.0, 0.0, 0.5)
	_settings_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_modal_blocker.visible = false
	root.add_child(_settings_modal_blocker)

	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -280.0
	_settings_panel.offset_top = -230.0
	_settings_panel.offset_right = 280.0
	_settings_panel.offset_bottom = 230.0
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_panel.visible = false
	_settings_panel.add_theme_stylebox_override("panel", _make_ui_box_style(Color(0.0, 0.02, 0.04, 0.92), Color(0.0, 0.85, 1.0), 28))
	root.add_child(_settings_panel)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	_settings_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 22)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	var title := Label.new()
	title.name = "SettingsTitleLabel"
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title, 36)
	stack.add_child(title)

	_sound_toggle_button = Button.new()
	_sound_toggle_button.name = "SoundToggleButton"
	_sound_toggle_button.focus_mode = Control.FOCUS_NONE
	_sound_toggle_button.add_theme_font_override("font", _hud_font)
	_sound_toggle_button.add_theme_font_size_override("font_size", 28)
	_sound_toggle_button.add_theme_color_override("font_color", Color.WHITE)
	_sound_toggle_button.add_theme_stylebox_override("normal", _make_ui_box_style(Color(0.0, 0.08, 0.12, 0.75), Color(0.0, 0.85, 1.0), 16))
	_sound_toggle_button.add_theme_stylebox_override("pressed", _make_ui_box_style(Color(0.0, 0.3, 0.35, 0.9), Color.WHITE, 16))
	_sound_toggle_button.pressed.connect(_toggle_sound)
	stack.add_child(_sound_toggle_button)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 18)
	stack.add_child(volume_row)

	var volume_label := Label.new()
	volume_label.text = "VOLUME"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(volume_label, 24)
	volume_row.add_child(volume_label)

	_volume_value_label = Label.new()
	_volume_value_label.name = "VolumeValueLabel"
	_volume_value_label.custom_minimum_size = Vector2(100.0, 0.0)
	_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_volume_value_label, 24)
	volume_row.add_child(_volume_value_label)

	_volume_slider = HSlider.new()
	_volume_slider.name = "VolumeSlider"
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.value_changed.connect(_set_sound_volume)
	stack.add_child(_volume_slider)

	var spacer := Control.new()
	spacer.name = "SettingsPanelSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(spacer)

	var close_button := Button.new()
	close_button.name = "CloseSettingsButton"
	close_button.text = "CLOSE"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_override("font", _hud_font)
	close_button.add_theme_font_size_override("font_size", 26)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_stylebox_override("normal", _make_ui_box_style(Color(0.0, 0.0, 0.0, 0.55), Color(0.0, 0.85, 1.0), 16))
	close_button.add_theme_stylebox_override("pressed", _make_ui_box_style(Color(0.0, 0.3, 0.35, 0.9), Color.WHITE, 16))
	close_button.pressed.connect(_close_settings)
	stack.add_child(close_button)

	_sync_settings_controls()


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


func _make_player_material() -> StandardMaterial3D:
	var material := _make_material(Color.WHITE)
	material.albedo_texture = PLAYER_TEXTURE
	material.texture_repeat = false
	material.uv1_scale = PLAYER_TEXTURE_UV_SCALE
	material.uv1_offset = PLAYER_TEXTURE_UV_OFFSET
	return material


func _make_obstacle_material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = OBSTACLE_DISTANCE_FADE_SHADER
	material.set_shader_parameter("base_color", Color(color, OBSTACLE_OPACITY))
	material.set_shader_parameter("fade_start", TUNING.obstacle_fade_start)
	material.set_shader_parameter("fade_end", TUNING.obstacle_fade_end)
	return material


func _make_coin_material() -> StandardMaterial3D:
	var material := _make_material(COIN_COLOR, true, COIN_OPACITY)
	material.roughness = 0.35
	return material


func _handle_player_feedback_events(events: Array) -> void:
	for event in events:
		if event["type"] == "landed":
			_landing_pulse_time = TUNING.landing_pulse_duration


func _handle_coin_events(events: Array) -> void:
	for event in events:
		if event["type"] != "coin_collected":
			continue
		_total_coins += 1
		_save_progress()


func _update_player(delta: float) -> void:
	var lateral_velocity: float = (simulation.current_x - _previous_player_x) / maxf(delta, 0.0001)
	_previous_player_x = simulation.current_x
	_landing_pulse_time = maxf(0.0, _landing_pulse_time - delta)

	_player_visual_pivot.position = Vector3(
		simulation.current_x,
		0.75 + simulation.player_y,
		TUNING.visual_action_plane_z
	)
	_player_light.position = Vector3(
		_player_visual_pivot.position.x,
		_player_visual_pivot.position.y + 0.45,
		TUNING.visual_action_plane_z
	)

	if simulation.state == Simulation.RunState.IMPACT:
		_player_visual_pivot.scale = Vector3.ONE * 1.15
	elif simulation.is_air_ducking():
		_player_visual_pivot.scale = Vector3(1.0, 0.55, 1.0)
	elif simulation.duck_time > 0.0:
		_player_visual_pivot.scale = Vector3(1.0, 0.55, 1.0)
		_player_visual_pivot.position.y = 0.43
	elif _landing_pulse_time > 0.0:
		var pulse_duration := maxf(TUNING.landing_pulse_duration, 0.001)
		var pulse := sin(_landing_pulse_time / pulse_duration * PI)
		_player_visual_pivot.scale = Vector3(
			lerpf(1.0, TUNING.landing_squash_horizontal, pulse),
			lerpf(1.0, TUNING.landing_squash_vertical, pulse),
			lerpf(1.0, TUNING.landing_squash_horizontal, pulse)
		)
	elif simulation.player_y > 0.0 and simulation.vertical_velocity > 0.0:
		var rise_ratio := clampf(simulation.vertical_velocity / TUNING.jump_velocity, 0.0, 1.0)
		_player_visual_pivot.scale = Vector3(
			lerpf(1.0, TUNING.jump_stretch_horizontal, rise_ratio),
			lerpf(1.0, TUNING.jump_stretch_vertical, rise_ratio),
			lerpf(1.0, TUNING.jump_stretch_horizontal, rise_ratio)
		)
	else:
		_player_visual_pivot.scale = Vector3.ONE

	var lean_target := -clampf(lateral_velocity / TUNING.lane_change_speed, -1.0, 1.0)
	lean_target *= deg_to_rad(TUNING.lane_lean_max_degrees)
	if simulation.state == Simulation.RunState.IMPACT:
		lean_target = 0.0
	var lean_weight := 1.0 - exp(-TUNING.lane_lean_smoothing * delta)
	_player_visual_pivot.rotation.z = lerp_angle(_player_visual_pivot.rotation.z, lean_target, lean_weight)

	if simulation.state == Simulation.RunState.RUNNING:
		var speed_ratio := inverse_lerp(TUNING.start_speed, TUNING.max_speed, simulation.speed)
		var spin_rate := lerpf(TUNING.player_spin_start_rate, TUNING.player_spin_max_rate, speed_ratio)
		_player_roll_angle = fposmod(_player_roll_angle + spin_rate * delta, TAU)
	_player.basis = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, _player_roll_angle)


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
			float(obstacle["z"]) + TUNING.visual_action_plane_z
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
			mesh_instance.material_override = _make_obstacle_material(Color(1.0, 0.38, 0.08))
		Simulation.ObstacleType.OVERHEAD_BAR:
			box.size = Vector3(1.9, 0.5, 1.1)
			mesh_instance.material_override = _make_obstacle_material(Color(0.85, 0.15, 1.0))
		Simulation.ObstacleType.WALL:
			box.size = Vector3(1.9, 3.2, 0.85)
			mesh_instance.material_override = _make_obstacle_material(Color(1.0, 0.08, 0.38))
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


func _sync_coins(delta: float) -> void:
	var active_ids := {}
	for coin in simulation.coins:
		if bool(coin.get("collected", false)):
			continue
		var coin_id: int = coin["id"]
		active_ids[coin_id] = true

		var mesh_instance: MeshInstance3D
		if _coin_nodes.has(coin_id):
			mesh_instance = _coin_nodes[coin_id]
		else:
			mesh_instance = _acquire_coin()
			if mesh_instance == null:
				continue
			_coin_nodes[coin_id] = mesh_instance

		mesh_instance.position = Vector3(
			simulation.lane_x(int(coin["lane"])),
			0.75 + float(coin["height"]),
			float(coin["z"]) + TUNING.visual_action_plane_z
		)
		mesh_instance.rotation.x = PI * 0.5
		mesh_instance.rotation.y = fposmod(mesh_instance.rotation.y + COIN_ROTATION_SPEED * delta, TAU)
		mesh_instance.visible = true

	for coin_id in _coin_nodes.keys():
		if active_ids.has(coin_id):
			continue
		var mesh_instance: MeshInstance3D = _coin_nodes[coin_id]
		_coin_nodes.erase(coin_id)
		mesh_instance.visible = false
		_coin_pool.append(mesh_instance)


func _acquire_coin() -> MeshInstance3D:
	if not _coin_pool.is_empty():
		return _coin_pool.pop_back()
	if _coin_nodes.size() + _coin_pool.size() >= MAX_COIN_NODES:
		return null
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Coin"
	_configure_coin(mesh_instance)
	add_child(mesh_instance)
	return mesh_instance


func _configure_coin(mesh_instance: MeshInstance3D) -> void:
	var coin_mesh := CylinderMesh.new()
	coin_mesh.top_radius = COIN_RADIUS
	coin_mesh.bottom_radius = COIN_RADIUS
	coin_mesh.height = COIN_THICKNESS
	coin_mesh.radial_segments = 32
	coin_mesh.rings = 1
	mesh_instance.mesh = coin_mesh
	mesh_instance.material_override = _make_coin_material()


func _update_hud() -> void:
	_score_label.text = str(simulation.score())
	_multiplier_label.text = "x%d" % simulation.multiplier
	_coin_label.text = "$%d" % _total_coins
	_coin_label.visible = (
		simulation.state == Simulation.RunState.READY
		or simulation.state == Simulation.RunState.RUNNING
		or simulation.state == Simulation.RunState.GAME_OVER
	)
	_score_stack.visible = simulation.state == Simulation.RunState.RUNNING
	_run_summary.visible = false
	_start_title_label.visible = false
	if _settings_button != null:
		_settings_button.visible = simulation.state == Simulation.RunState.READY or simulation.state == Simulation.RunState.GAME_OVER
	if simulation.state != Simulation.RunState.READY and simulation.state != Simulation.RunState.GAME_OVER:
		_close_settings()

	match simulation.state:
		Simulation.RunState.READY:
			_start_title_label.visible = _tutorial_completed
			_overlay_label.text = FIRST_LAUNCH_TUTORIAL_TEXT if not _tutorial_completed else "Tap to Start"
			_overlay_label.visible = true
		Simulation.RunState.GAME_OVER:
			_overlay_label.visible = false
			_new_high_score_label.visible = _new_high_score
			_run_summary_values["distance"].text = "%dm" % simulation.distance_score()
			_run_summary_values["peak_multiplier"].text = "x%d" % simulation.peak_multiplier
			_run_summary_values["score"].text = str(simulation.final_score())
			_run_summary_values["high_score"].text = str(high_score)
			_run_summary.visible = true
		_:
			_overlay_label.visible = false


func _finish_run() -> void:
	var updated := Simulation.updated_high_score(high_score, simulation.score())
	_new_high_score = updated > high_score
	if not _new_high_score:
		return
	high_score = updated
	_save_progress()


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.set_value("currency", "coins", _total_coins)
	config.set_value("progress", "tutorial_completed", _tutorial_completed)
	config.set_value("settings", "sound_enabled", _sound_enabled)
	config.set_value("settings", "sound_volume", _sound_volume)
	config.save(_save_path)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(_save_path) == OK:
		high_score = int(config.get_value("scores", "high_score", 0))
		_total_coins = int(config.get_value("currency", "coins", 0))
		_tutorial_completed = bool(config.get_value("progress", "tutorial_completed", false))
		_sound_enabled = bool(config.get_value("settings", "sound_enabled", DEFAULT_SOUND_ENABLED))
		_sound_volume = clampf(float(config.get_value("settings", "sound_volume", DEFAULT_SOUND_VOLUME)), 0.0, 1.0)
	_apply_sound_settings()
	_sync_settings_controls()


func _play_restart_fade() -> void:
	if _restart_fade == null:
		return
	_restart_fade.modulate.a = 0.85
	var tween := create_tween()
	tween.tween_property(_restart_fade, "modulate:a", 0.0, 0.18)
