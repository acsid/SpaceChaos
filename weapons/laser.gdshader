shader_type spatial;

uniform bool emit = true;

uniform vec4 color : source_color = vec4(0,1,0,1);

void fragment() {
	// Place fragment code here.
	if(emit) {
		EMISSION = color.rgb;
	}
	ALBEDO = color.rgb;
}
