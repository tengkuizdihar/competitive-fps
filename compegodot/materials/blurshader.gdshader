shader_type canvas_item;

uniform float blur_intensity;

void fragment() {
	COLOR.rgb = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_intensity).rgb;
}
