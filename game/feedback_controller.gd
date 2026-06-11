class_name FeedbackController
extends Node3D

const AudioCueLibrary = preload("res://game/audio_cue_library.gd")
const TUNING = preload("res://game/default_runner_tuning.tres")

const IMPACT_POOL_SIZE := 4
const AUDIO_POOL_SIZE := 8
const SHAKE_DURATION := 0.18
const SHAKE_STRENGTH := 0.12
const HAPTICS_ENABLED := true
const AUDIO_ENABLED := true

var shake_time := 0.0

var _camera: Camera3D
var _camera_base_position := Vector3.ZERO
var _particles: Array[GPUParticles3D] = []
var _audio_players: Array[AudioStreamPlayer] = []
var _particle_index := 0
var _audio_index := 0
var _audio_library = AudioCueLibrary.new()


func _ready() -> void:
	prepare()


func _process(delta: float) -> void:
	if _camera == null:
		return
	shake_time = maxf(0.0, shake_time - delta)
	if shake_time > 0.0:
		var strength := TUNING.shake_strength * shake_time / TUNING.shake_duration
		_camera.position = _camera_base_position + Vector3(
			sin(shake_time * 93.0) * strength,
			cos(shake_time * 77.0) * strength,
			0.0
		)
	else:
		_camera.position = _camera_base_position


func prepare() -> void:
	while _particles.size() < IMPACT_POOL_SIZE:
		var particles := GPUParticles3D.new()
		particles.one_shot = true
		particles.emitting = false
		particles.amount = 18
		particles.lifetime = 0.35
		var process_material := ParticleProcessMaterial.new()
		process_material.direction = Vector3(0.0, 1.0, 0.0)
		process_material.spread = 70.0
		process_material.initial_velocity_min = 2.0
		process_material.initial_velocity_max = 5.0
		process_material.gravity = Vector3(0.0, -8.0, 0.0)
		process_material.color = Color(0.0, 0.85, 1.0)
		particles.process_material = process_material
		var particle_mesh := BoxMesh.new()
		particle_mesh.size = Vector3.ONE * 0.08
		particles.draw_pass_1 = particle_mesh
		add_child(particles)
		_particles.append(particles)

	while _audio_players.size() < AUDIO_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		_audio_players.append(player)


func setup(camera: Camera3D) -> void:
	_camera = camera
	_camera_base_position = camera.position


func handle_events(events: Array[Dictionary], player_position: Vector3) -> void:
	for event in events:
		var type: String = event["type"]
		match type:
			"collision":
				shake_time = TUNING.shake_duration
				_spawn_impact(player_position)
				_vibrate(90)
			"near_miss":
				_vibrate(20)
		_play_cue(type)


func set_feedback_paused(value: bool) -> void:
	if value:
		for player in _audio_players:
			player.stop()


func particle_pool_size() -> int:
	return _particles.size()


func audio_pool_size() -> int:
	return _audio_players.size()


func particles_are_idle() -> bool:
	for particles in _particles:
		if particles.emitting:
			return false
	return true


func _spawn_impact(position: Vector3) -> void:
	if _particles.is_empty():
		return
	var particles := _particles[_particle_index]
	_particle_index = (_particle_index + 1) % _particles.size()
	particles.position = position
	if is_inside_tree():
		particles.restart()


func _play_cue(type: String) -> void:
	if not TUNING.audio_enabled or _audio_players.is_empty():
		return
	var cue := _audio_library.cue(type)
	if cue == null:
		return
	var player := _audio_players[_audio_index]
	_audio_index = (_audio_index + 1) % _audio_players.size()
	player.stream = cue
	if is_inside_tree():
		player.play()


func _vibrate(milliseconds: int) -> void:
	if TUNING.haptics_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)
