shader_type canvas_item;

uniform vec4 mixed_color: source_color;
uniform float alpha: hint_range(0.0, 1.0) = 1.0;
uniform float amount: hint_range(0.0, 1.0) = 0.5;

// void vertex() {
// 	// Called for every vertex the material is visible on.
// }

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, mixed_color.rgb, amount);
	COLOR.a *= alpha;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
