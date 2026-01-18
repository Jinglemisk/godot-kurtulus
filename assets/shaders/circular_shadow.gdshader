shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.4);
uniform float falloff : hint_range(0.1, 3.0) = 1.5;

void fragment() {
	// Calculate distance from center (UV is 0-1, center is 0.5)
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center) * 2.0; // 0 at center, 1 at edge

	// Discard pixels outside the circle
	if (dist > 1.0) {
		discard;
	}

	// Smooth circular falloff
	float alpha = 1.0 - smoothstep(0.0, 1.0, pow(dist, falloff));

	ALBEDO = shadow_color.rgb;
	ALPHA = shadow_color.a * alpha;
}
