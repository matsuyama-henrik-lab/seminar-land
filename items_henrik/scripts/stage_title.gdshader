shader_type canvas_item;
// ステージ名の「消える」演出 / The stage-title dissolve effect.
// t を 0→1 に動かすと、文字がモザイク状に粗くなりながら薄くなって消えます。
// As t goes 0→1 the title turns blocky (pixelated) and fades away.
uniform float t : hint_range(0.1, 1.0) = 0.0;   // 0:くっきり 1:消える / 0:sharp 1:gone

void fragment() {
	vec2 uv = UV;
	float d = (1.0-t)*500.0;      // t が大きいほどマス目が粗くなる / bigger t = coarser blocks
	uv = (round(uv*d))/d;          // UVをマス目に丸めてモザイク化 / snap UV to a grid → pixelate

	vec4 color = texture(TEXTURE,uv);
	color.a *= 1.0 - t;            // t が大きいほど透明に / fade out as t grows
	COLOR = color;
}
