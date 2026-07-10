shader_type canvas_item;
// カギをゆらゆら揺らす効果 / Makes the key wobble.
// 絵を左右にサインカーブで少しずらして、旗（はた）のように揺れて見せます。
// Shifts the picture left/right with a sine wave so it sways like a banner.

void fragment() {
	// 上下の位置と時間で横ずれの量を決める / horizontal shift depends on TIME and vertical position
	vec2 uv = UV - vec2(0.5,0.5);
	uv.x += cos((TIME+uv.y)*2.0)*0.05;   // 揺れの大きさ（0.05）/ sway amount (0.05)
	uv += vec2(0.5,0.5);
	vec4 color = texture(TEXTURE, uv);
	
	COLOR = color;
	
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
