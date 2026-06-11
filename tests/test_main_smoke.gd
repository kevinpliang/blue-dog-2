extends SceneTree

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
	elif not _obstacles_emit_color():
		push_error("Active obstacle materials do not emit their colors.")
		quit(1)
	elif not _obstacles_are_slightly_transparent():
		push_error("Active obstacle materials are not slightly transparent.")
		quit(1)
	elif not _track_uses_distance_fade():
		push_error("Track visuals do not use the distance fade shader.")
		quit(1)
	elif _main.find_child("HudSafeArea", true, false) == null:
		push_error("Main scene does not include a HUD safe-area container.")
		quit(1)
	else:
		print("Dog Run active scene smoke test passed.")
		quit(0)
	return true


func _obstacles_emit_color() -> bool:
	for obstacle_node in _main._obstacle_nodes.values():
		var material: StandardMaterial3D = obstacle_node.material_override
		if material == null or not material.emission_enabled:
			return false
	return true


func _obstacles_are_slightly_transparent() -> bool:
	for obstacle_node in _main._obstacle_nodes.values():
		var material: StandardMaterial3D = obstacle_node.material_override
		if material == null or material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			return false
		if not is_equal_approx(material.albedo_color.a, 0.88):
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
