shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform float fade_start = 70.0;
uniform float fade_end = 145.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float distance_from_player = max(0.0, -world_position.z);
	float visibility = 1.0 - smoothstep(fade_start, fade_end, distance_from_player);
	ALBEDO = base_color.rgb * visibility;
}
