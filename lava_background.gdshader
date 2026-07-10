shader_type canvas_item;
// 背景の溶岩と空 / The background lava and sky.
// 画面いっぱいに広がる背景です。下は波打つオレンジの溶岩の海、
// うんと上まで登ると雲、さらに上は真っ白な「宇宙」になります。
// A full-screen backdrop: a wavy orange lava sea below, clouds far above,
// and pure white "space" higher still. world.gd feeds it the camera position.
// （下の英語コメントは各計算の詳しい説明です。/ English notes below explain each step.）

uniform float camera_y = 0.0;
uniform float camera_x = 0.0;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform float y_offset = -64.0;
uniform float sky_ends = 9900.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.0 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float world_y = camera_y + (UV.y - 0.5) * viewport_size.y;
	float world_x = camera_x + (UV.x - 0.5) * viewport_size.x;

	// Wavy surface boundary in world space
	

	
	if (world_y< -sky_ends) {
		// Height above the sky boundary: 0 at the edge, grows as we go up.
		float height = -world_y - sky_ends;

		// Drifting cloud noise in world space (stretched horizontally so the
		// puffs read as clouds rather than blobs).
		vec2 cloud_uv = vec2(world_x * 0.004 + TIME * 0.03, world_y * 0.008 - TIME * 0.01);
		float clouds = fbm(cloud_uv);
		// Sharpen the noise into puffy cloud shapes.
		clouds = smoothstep(0.35, 0.85, clouds);

		// Near the boundary: wispy clouds fading in from transparent.
		float surface_fade = smoothstep(0.0, 120.0, height);
		// The higher we go, the more the clouds merge into solid white ("space").
		float toward_white = smoothstep(0.0, 500.0, height);

		float cloud_amount = mix(clouds, 1.0, toward_white);
		float alpha = cloud_amount * surface_fade;

		COLOR = vec4(1.0, 1.0, 1.0, alpha);
	}else
	{
		float wave = sin(world_x * 0.02 + TIME * 2.0) * 14.0
			   + sin(world_x * 0.05 - TIME * 1.3) * 7.0
			   + sin(world_x * 0.11 + TIME * 0.8) * 4.0
			   + sin(-world_x * 0.01 + TIME * 0.2) * 12.0
			   + sin(-world_x * 0.001 + TIME * 0.1) * 15.0
			 ;
			  

		float depth = world_y - wave - y_offset;
	
		if (depth <= 0.0) {
				COLOR = vec4(0.0);
		} else {
			vec3 col = vec3(0.9,0.18,0.0);
			// Orange glow at the surface that fades into the lava body
			float surface_fade = smoothstep(0.0, 50.0, depth);
			col = mix(vec3(1.0, 0.45, 0.0), col, surface_fade);

			COLOR = vec4(col, 1.0);
		}
	}
}
