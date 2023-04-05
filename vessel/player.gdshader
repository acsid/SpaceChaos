shader_type spatial;

uniform vec4 color : source_color = vec4(0.4,0.2,0.5,1);

void fragment() {
	ALBEDO = color.rgb;
}
