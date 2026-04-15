shader_type canvas_item;

uniform float scanline_density : hint_range(50.0, 300.0) = 120.0;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.08;
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.18;
uniform float flicker : hint_range(0.0, 0.05) = 0.012;

void fragment() {
	// Scrolling scanlines
	float line = mod(UV.y * scanline_density + TIME * scroll_speed * scanline_density, 1.0);
	float scanline_mask = 1.0 - smoothstep(0.4, 0.6, line) * scanline_strength;

	// Subtle random flicker
	float f = 1.0 - flicker * fract(sin(TIME * 73.1) * 4375.5);

	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - scanline_mask) * f * 0.18);
}
