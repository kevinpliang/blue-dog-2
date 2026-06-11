shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform float emission_energy = 1.4;
uniform float fade_start = 52.0;
uniform float fade_end = 72.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float distance_from_player = max(0.0, -world_position.z);
	float visibility = 1.0 - smoothstep(fade_start, fade_end, distance_from_player);
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.75;
	EMISSION = base_color.rgb * emission_energy;
	ALPHA = base_color.a * visibility;
}
