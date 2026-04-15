shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_density : hint_range(100.0, 400.0) = 200.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25;
uniform float curvature : hint_range(0.0, 0.2) = 0.04; 
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float flicker_speed : hint_range(0.0, 10.0) = 3.0; 
uniform float flicker_strength : hint_range(0.0, 0.1) = 0.02;

void fragment() { 
	vec2 uv = SCREEN_UV; // Use SCREEN_UV for screen-space effects

	// CRT curvature math
	vec2 curved_uv = uv * 2.0 - 1.0;
	vec2 offset = curved_uv.yx * curved_uv.yx * curvature; 
	curved_uv += curved_uv * offset;
	curved_uv = curved_uv * 0.5 + 0.5;

	// Check if the current UV is within the visible screen bounds
	if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) { 
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Sample texture with curved UV
		vec4 color = texture(SCREEN_TEXTURE, curved_uv); 

		// Scanlines
		float scanline = sin(curved_uv.y * scanline_density) * 0.5 + 0.5;
		color.rgb -= scanline * scanline_strength;

		// Vignette
		vec2 vig_uv = curved_uv * (1.0 - curved_uv.yx);
		float vignette = vig_uv.x * vig_uv.y * 15.0; 
		vignette = pow(vignette, vignette_strength);
		color.rgb *= vignette;

		// Subtle flicker
		float flicker = 1.0 - flicker_strength * sin(TIME * flicker_speed * 17.3);
		color.rgb *= flicker; 

		// Green tint — cold terminal feel
		color.rgb *= vec3(0.85, 1.0, 0.85);

		COLOR = color;
	}
}