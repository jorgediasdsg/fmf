shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;
// Cor chapada com bandas de luz (toon) + luz de borda (rim).

uniform vec4 albedo : source_color = vec4(1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.55;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);

void fragment() {
	ALBEDO = albedo.rgb;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = ndl > 0.3 ? 1.0 : (ndl > -0.05 ? 0.68 : 0.46);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * band / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	DIFFUSE_LIGHT += rim_color.rgb * rim * rim_strength * ATTENUATION * 0.3;
}
