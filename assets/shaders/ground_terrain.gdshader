shader_type spatial;

uniform sampler2D ground_texture : source_color, filter_nearest, repeat_enable;
uniform vec3 grass_tint : source_color = vec3(0.4, 0.6, 0.3);
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
uniform float grass_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float blend_softness : hint_range(0.0, 0.5) = 0.1;

// Hash function for noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	// Sample texture with tiling
	vec4 tex_color = texture(ground_texture, UV * 20.0);

	// Generate noise for grass/dirt distribution
	float n = noise(UV * noise_scale * 10.0);

	// Smooth blend between dirt and grass
	float grass_mix = smoothstep(grass_threshold - blend_softness,
	                              grass_threshold + blend_softness, n);

	// Apply green tint for grass areas
	vec3 grass_color = tex_color.rgb * grass_tint * 1.8;
	vec3 final_color = mix(tex_color.rgb, grass_color, grass_mix);

	ALBEDO = final_color;
	ROUGHNESS = 0.9;
}
