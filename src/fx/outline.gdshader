shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
// Contorno preto por casco invertido: infla os vértices pela normal
// e desenha só as faces de trás.

uniform float thickness = 0.03;
uniform vec4 outline_color : source_color = vec4(0.07, 0.06, 0.1, 1.0);

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
