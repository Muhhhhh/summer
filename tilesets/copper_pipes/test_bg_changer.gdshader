shader_type canvas_item;

uniform vec4 background_color: source_color;
uniform float margin = 2.0;

void vertex() {
	// Called for every vertex the material is visible on. 30,34,40,1
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if((COLOR.r + COLOR.g + COLOR.b) < ((30.0 + 34.0 + 40.0 + margin) / 255.0)) {
		COLOR.rgb = background_color.rgb;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
