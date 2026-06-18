extends SceneTree

const MainScript = preload("res://game/main.gd")
const Simulation = preload("res://game/runner_simulation.gd")
const PatternLibrary = preload("res://game/pattern_library.gd")
const Validator = preload("res://game/reachability_validator.gd")

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
	elif not _uses_character_selection_menu():
		push_error("Main scene does not include the character selection menu.")
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
	elif not _allows_jump_after_air_duck_roll():
		push_error("Airborne duck landing roll cannot be jump-cancelled.")
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
	elif not _uses_more_interesting_patterns():
		push_error("Pattern library does not include the new non-air-duck pattern batch.")
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
	var coin_label: Label = _main.find_child("CoinLabel", true, false)
	var settings_button: Button = _main.find_child("SettingsButton", true, false)
	if score_stack == null or coin_label == null or settings_button == null:
		return false
	var text_top := MainScript.HUD_EDGE_MARGIN + MainScript.HUD_TEXT_TOP_ADJUSTMENT
	if not is_equal_approx(score_stack.offset_top, text_top):
		return false
	if not is_equal_approx(score_stack.offset_right, -MainScript.HUD_EDGE_MARGIN):
		return false
	if not is_equal_approx(coin_label.offset_left, MainScript.HUD_EDGE_MARGIN):
		return false
	if not is_equal_approx(coin_label.offset_top, text_top + MainScript.COIN_LABEL_TOP_OFFSET):
		return false
	if not is_equal_approx(settings_button.offset_top, MainScript.HUD_EDGE_MARGIN):
		return false
	if not is_equal_approx(settings_button.offset_right, -MainScript.HUD_EDGE_MARGIN):
		return false
	return true


func _uses_refreshed_hud() -> bool:
	var score_stack: VBoxContainer = _main.find_child("ScoreStack", true, false)
	var score_label: Label = _main.find_child("ScoreLabel", true, false)
	var multiplier_label: Label = _main.find_child("MultiplierLabel", true, false)
	var coin_label: Label = _main.find_child("CoinLabel", true, false)
	var summary: VBoxContainer = _main.find_child("RunSummary", true, false)
	var summary_grid: GridContainer = _main.find_child("RunSummaryGrid", true, false)
	var new_high_score_label: Label = _main.find_child("NewHighScoreLabel", true, false)
	var high_score_value: Label = _main.find_child("SummaryHighScoreValue", true, false)
	var near_misses_value: Label = _main.find_child("SummaryNearMissesValue", true, false)
	if score_stack == null or score_label == null or multiplier_label == null or coin_label == null:
		return false
	if summary == null or summary_grid == null or new_high_score_label == null or high_score_value == null:
		return false
	if near_misses_value != null:
		return false
	if not score_stack.visible or summary.visible or summary_grid.columns != 2:
		return false
	if score_label.text.begins_with("SCORE") or not multiplier_label.visible:
		return false
	if score_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		return false
	if multiplier_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		return false
	if coin_label.get_theme_font_size("font_size") != MainScript.COIN_LABEL_FONT_SIZE:
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
	_main._total_coins = 123
	_main._update_hud()
	if coin_label.text != "$123":
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
	_main._sound_enabled = true
	_main._sound_volume = 1.0
	_main._apply_sound_settings()
	_main._sync_settings_controls()
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


func _uses_character_selection_menu() -> bool:
	var button: Button = _main.find_child("CharacterButton", true, false)
	var settings_button: Button = _main.find_child("SettingsButton", true, false)
	var panel: Control = _main.find_child("CharacterPanel", true, false)
	var blocker: Control = _main.find_child("CharacterModalBlocker", true, false)
	var grid: GridContainer = _main.find_child("CharacterGrid", true, false)
	var card: Button = _main.find_child("CharacterCardDog", true, false)
	var bear_card: Button = _main.find_child("CharacterCardBear", true, false)
	var bear_cost_label: Label = _main.find_child("CharacterCostBearLabel", true, false)
	var bear_locked_preview: Control = _main.find_child("CharacterLockedBearPreview", true, false)
	var bear_locked_pivot: Node3D = _main.find_child("CharacterLockedBearPivot", true, false)
	var bear_locked_sphere: MeshInstance3D = _main.find_child("CharacterLockedBearSphere", true, false)
	var bear_preview_sphere: MeshInstance3D = _main.find_child("CharacterPreviewBearSphere", true, false)
	var bear_status_label: Label = _main.find_child("CharacterStatusBearLabel", true, false)
	var close_button: Button = _main.find_child("CloseCharacterButton", true, false)
	var selected_label: Label = _main.find_child("CharacterSelectedLabel", true, false)
	var preview_container: SubViewportContainer = _main.find_child("CharacterPreviewDogContainer", true, false)
	var preview_pivot: Node3D = _main.find_child("CharacterPreviewDogPivot", true, false)
	var preview_sphere: MeshInstance3D = _main.find_child("CharacterPreviewDogSphere", true, false)
	var preview_camera: Camera3D = _main.find_child("CharacterPreviewDogCamera", true, false)
	var preview_viewport: SubViewport = _main.find_child("CharacterPreviewDogViewport", true, false)
	if button == null or settings_button == null or panel == null or blocker == null or grid == null:
		return false
	if card == null or close_button == null or selected_label == null or preview_pivot == null:
		return false
	if bear_card == null or bear_cost_label == null or bear_locked_preview == null:
		push_error("Character selector is missing the locked Bear card, cost label, or locked preview.")
		return false
	if bear_locked_pivot == null or bear_locked_sphere == null:
		push_error("Locked Bear card should show a spinning black sphere preview.")
		return false
	if bear_preview_sphere == null or bear_status_label == null:
		push_error("Character selector is missing the Bear preview sphere or status label.")
		return false
	if preview_container == null or preview_sphere == null or preview_camera == null or preview_viewport == null:
		return false
	if button.icon == null or button.icon.resource_path != "res://assets/icons/pets.svg":
		return false
	if button.size.x < MainScript.SETTINGS_BUTTON_SIZE or button.size.y < MainScript.SETTINGS_BUTTON_SIZE:
		return false
	if not is_equal_approx(button.offset_top, MainScript.CHARACTER_BUTTON_TOP_MARGIN):
		return false
	if button.offset_top <= settings_button.offset_top:
		return false
	if button.get_theme_constant("icon_max_width") != int(MainScript.SETTINGS_ICON_MAX_WIDTH):
		return false
	if card.custom_minimum_size != MainScript.CHARACTER_CARD_SIZE:
		return false
	if bear_card.custom_minimum_size != MainScript.CHARACTER_CARD_SIZE:
		push_error("Bear card does not use the tuned character card size.")
		return false
	if preview_container.custom_minimum_size != MainScript.CHARACTER_PREVIEW_SIZE:
		return false
	if not preview_viewport.own_world_3d:
		return false
	if not preview_sphere.mesh is SphereMesh:
		return false
	var preview_mesh: SphereMesh = preview_sphere.mesh
	if not is_equal_approx(preview_mesh.radius, MainScript.CHARACTER_PREVIEW_SPHERE_RADIUS):
		return false
	if not is_equal_approx(preview_camera.position.z, MainScript.CHARACTER_PREVIEW_CAMERA_Z):
		return false
	if not is_equal_approx(preview_camera.fov, MainScript.CHARACTER_PREVIEW_CAMERA_FOV):
		return false
	if grid.columns < 2:
		return false
	if grid.size_flags_horizontal != Control.SIZE_SHRINK_BEGIN:
		return false
	if not preview_sphere.material_override is StandardMaterial3D:
		return false
	var material: StandardMaterial3D = preview_sphere.material_override
	if material.albedo_texture == null or material.albedo_texture.resource_path != "res://assets/player/white.png":
		return false
	if not bear_preview_sphere.material_override is StandardMaterial3D:
		push_error("Bear preview sphere does not use a StandardMaterial3D.")
		return false
	var bear_material: StandardMaterial3D = bear_preview_sphere.material_override
	if bear_material.albedo_texture == null or bear_material.albedo_texture.resource_path != "res://assets/player/bear.png":
		push_error("Bear preview sphere does not use the Bear texture.")
		return false
	if not bear_locked_sphere.mesh is SphereMesh:
		push_error("Locked Bear preview should use a sphere mesh.")
		return false
	if not bear_locked_sphere.material_override is StandardMaterial3D:
		push_error("Locked Bear preview sphere does not use a StandardMaterial3D.")
		return false
	var locked_material: StandardMaterial3D = bear_locked_sphere.material_override
	if locked_material.albedo_texture != null:
		push_error("Locked Bear preview sphere should not show the Bear texture.")
		return false
	if locked_material.albedo_color.r > 0.02 or locked_material.albedo_color.g > 0.02 or locked_material.albedo_color.b > 0.02:
		push_error("Locked Bear preview sphere should be black.")
		return false
	if bear_cost_label.text != "$500":
		push_error("Bear locked card does not show the $500 unlock cost.")
		return false

	var character_save_path := "user://dog_run_characters_smoke.cfg"
	var character_absolute_path := ProjectSettings.globalize_path(character_save_path)
	DirAccess.remove_absolute(character_absolute_path)
	_main._save_path = character_save_path
	_main._selected_character_id = "dog"
	_main._unlocked_character_ids = {"dog": true}
	_main._total_coins = 499
	_main._sync_character_controls()
	_main.simulation.state = _main.simulation.RunState.READY
	_main._update_hud()
	if not button.visible or panel.visible or blocker.visible:
		DirAccess.remove_absolute(character_absolute_path)
		return false

	_main._open_character_selection()
	if not panel.visible or not blocker.visible:
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if _main.find_child("SettingsPanel", true, false).visible:
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if selected_label.text != "SELECTED":
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if bear_status_label.visible or not bear_cost_label.visible or not bear_locked_preview.visible:
		push_error("Locked Bear card should show cost/locked preview and hide status.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if grid.get_child_count() < 2 or grid.get_child(0) != card or grid.get_child(1) != bear_card:
		push_error("Dog and Bear cards should occupy the first two grid slots in order.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	var card_rect := card.get_global_rect()
	var selected_rect := selected_label.get_global_rect()
	if selected_rect.end.y > card_rect.end.y - 4.0:
		DirAccess.remove_absolute(character_absolute_path)
		return false
	var close_bottom_gap := panel.get_global_rect().end.y - close_button.get_global_rect().end.y
	if close_bottom_gap > 64.0:
		DirAccess.remove_absolute(character_absolute_path)
		return false
	var rotation_before := preview_pivot.rotation.y
	var locked_rotation_before := bear_locked_pivot.rotation.y
	_main._update_character_previews(0.1)
	if is_equal_approx(preview_pivot.rotation.y, rotation_before):
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if is_equal_approx(bear_locked_pivot.rotation.y, locked_rotation_before):
		push_error("Locked Bear preview sphere should spin while the selector is open.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	_main._select_character("bear")
	if _main.get("_selected_character_id") != "dog" or _main._total_coins != 499:
		push_error("Locked Bear should not select or spend coins when the player cannot afford it.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	_main._total_coins = 500
	_main._select_character("bear")
	if _main.get("_selected_character_id") != "bear" or _main._total_coins != 0:
		push_error("Affordable Bear should unlock, select, and deduct $500.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if bear_cost_label.visible or bear_locked_preview.visible or not bear_status_label.visible:
		push_error("Unlocked Bear card should hide cost/locked preview and show status.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if bear_status_label.text != "SELECTED":
		DirAccess.remove_absolute(character_absolute_path)
		return false
	if not _main._player.material_override is StandardMaterial3D:
		DirAccess.remove_absolute(character_absolute_path)
		return false
	var selected_material: StandardMaterial3D = _main._player.material_override
	if selected_material.albedo_texture == null or selected_material.albedo_texture.resource_path != "res://assets/player/bear.png":
		push_error("Selecting Bear should apply the Bear texture to the player.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	_main._save_progress()
	_main._selected_character_id = "dog"
	_main._unlocked_character_ids = {"dog": true}
	_main._total_coins = 123
	_main._load_progress()
	if _main.get("_selected_character_id") != "bear" or _main._total_coins != 0:
		push_error("Bear unlock and selection should persist across progress load.")
		DirAccess.remove_absolute(character_absolute_path)
		return false
	_main._select_character("dog")
	if _main.get("_selected_character_id") != "dog":
		DirAccess.remove_absolute(character_absolute_path)
		return false
	_main._close_character_selection()

	_main.simulation.state = _main.simulation.RunState.RUNNING
	_main._update_hud()
	if button.visible or panel.visible or blocker.visible:
		DirAccess.remove_absolute(character_absolute_path)
		return false

	_main.simulation.state = _main.simulation.RunState.GAME_OVER
	_main._update_hud()
	var visible_on_game_over := button.visible and not panel.visible and not blocker.visible
	_main.simulation.state = _main.simulation.RunState.RUNNING
	_main._update_hud()
	DirAccess.remove_absolute(character_absolute_path)
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


func _allows_jump_after_air_duck_roll() -> bool:
	var simulation = Simulation.new()
	simulation.start(3501)
	simulation.obstacles.clear()
	simulation.next_spawn_z = -10000.0

	simulation.jump()
	simulation.duck()
	simulation.step(simulation.TUNING.air_duck_dive_duration + 0.001)
	if simulation.duck_time <= 0.0:
		return false

	simulation.jump()
	return simulation.vertical_velocity > 0.0 and simulation.duck_time == 0.0 and not simulation.air_duck_landing_roll


func _uses_more_interesting_patterns() -> bool:
	var expected_tiers := {
		"left_choice_then_jump_gate": 1,
		"right_choice_then_duck_gate": 1,
		"center_slalom_jump_gate": 2,
		"center_slalom_duck_gate": 2,
		"jump_gate_lane_duck_gate": 2,
		"duck_gate_lane_jump_gate": 2,
	}
	var patterns_by_id := {}
	var validator = Validator.new()
	for pattern in PatternLibrary.all_patterns():
		patterns_by_id[pattern["id"]] = pattern
	for pattern_id in expected_tiers:
		if not patterns_by_id.has(pattern_id):
			return false
		if int(patterns_by_id[pattern_id]["tier"]) != expected_tiers[pattern_id]:
			return false
		if not validator.is_reachable(patterns_by_id[pattern_id], 24.0):
			return false
	var jump_duck: Dictionary = patterns_by_id["jump_gate_lane_duck_gate"]
	if float(jump_duck["rows"][2]["offset"]) < PatternLibrary.MIN_JUMP_TO_DUCK_SPACING:
		return false
	var duck_jump: Dictionary = patterns_by_id["duck_gate_lane_jump_gate"]
	return float(duck_jump["rows"][2]["offset"]) >= PatternLibrary.MIN_DUCK_TO_JUMP_SPACING


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
