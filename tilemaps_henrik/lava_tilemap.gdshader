shader_type canvas_item;
// 溶岩（ようがん）タイルの見た目 / The look of a lava tile.
// タイルの表面にゆらゆら揺れる波を描き、オレンジ色に光らせます。
// Draws a wavy, glowing orange surface on the lava tile.
// upside_down: 天井の溶岩用に上下をひっくり返す / flip vertically for ceiling lava
// centerblock: 波なしの真っ赤な塊（内部用）/ a solid red block with no wave (for insides)
uniform bool upside_down = false;
uniform bool centerblock = false;
// Width (in pixels) of a single tile inside the atlas. The atlas may now be
// wider than one tile (e.g. 256x128 = two 128px tiles), so the wave must
// repeat per tile, not per whole texture.
uniform float tile_px = 128.0;


void fragment() {
    // 1. Get the texture size in pixels (e.g. 64.0, 128.0)
    vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	if (centerblock)
	{
		vec3 col = vec3(0.9, 0.18, 0.0);
		COLOR = vec4(col, 1.0);
	}else
	{
	    // 2. UV is normalised over the WHOLE atlas, so figure out where we are
	    // inside the current tile (in pixels). The -0.5 keeps the loop aligned to
	    // pixel centres, same as before.
	    float pixel_index = UV.x * tex_size.x - 0.5;   // pixel index across the atlas
	    float local_x     = mod(pixel_index, tile_px); // pixel index inside this tile

	    // 3. Map to 0..1 across one tile and force loop wrapping using fract
	    float world_x = fract(local_x / (tile_px - 1.0));
	    
	    // 4. Calculate your clean, periodic wave
		
		const float wave_height_1 = 0.01;
		const float wave_height_2 = 0.05;
		const float wave_height_3 = 0.03;
		const float wave_speed_fact = 4.0;
		
		float wave = sin(world_x * 2.0 * PI + TIME * wave_speed_fact * 0.1) * wave_height_1
				   + sin(world_x * 4.0 * PI - TIME * wave_speed_fact * 0.25+0.25) * wave_height_2
				   - sin(world_x * 2.0 * PI + TIME * wave_speed_fact * 1.0-14.032) * wave_height_3;
	    
	    float depth = - wave - (wave_height_1+wave_height_2+wave_height_3)-0.01;
		depth = upside_down ? (1.0 - UV.y + depth) : (UV.y + depth);
		

	    if (depth <= 0.0) {
	        COLOR = vec4(0.0);
	    } else {
	        vec3 col = vec3(0.9, 0.18, 0.0);
	        // Orange glow at the surface that fades into the lava body
	        float surface_fade = smoothstep(0.0, 1.0, depth);
	        col = mix(vec3(1.0, 0.45, 0.0), col, surface_fade);

	        COLOR = vec4(col, 1.0);
	    }
	}
}