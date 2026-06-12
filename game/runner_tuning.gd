class_name RunnerTuning
extends Resource

@export var duck_duration := 0.3
@export var duck_cooldown := 0.05
@export var air_duck_dive_duration := 0.12
@export var start_speed := 12.0
@export var max_speed := 24.0
@export var speed_acceleration := 0.35
@export var lane_change_speed := 32.0
@export var jump_velocity := 9.5
@export var gravity := 24.0
@export var input_buffer_duration := 0.12
@export var swipe_width_ratio := 50.0 / 720.0
@export var track_fade_start := 70.0
@export var track_fade_end := 145.0
@export var obstacle_fade_start := 52.0
@export var obstacle_fade_end := 72.0
@export var camera_fov := 58.0
@export var visual_action_plane_z := 2.0
@export var player_spin_start_rate := 5.0
@export var player_spin_max_rate := 9.0
@export var lane_lean_max_degrees := 12.0
@export var lane_lean_smoothing := 12.0
@export var jump_stretch_horizontal := 0.88
@export var jump_stretch_vertical := 1.15
@export var landing_squash_horizontal := 1.12
@export var landing_squash_vertical := 0.82
@export var landing_pulse_duration := 0.16
@export var shake_duration := 0.18
@export var shake_strength := 0.12
@export var audio_enabled := true
@export var haptics_enabled := true
