shader_type canvas_item;
// 特定の色を透明にする（クロマキー）/ Makes one color transparent (chroma key).
// 絵の中のピンク（マゼンタ）に近い色を消して、背景を透けさせます。
// Erases pixels close to pink/magenta so the background shows through.
// これで、四角い画像から人物だけを切り抜けます。
// This cuts out just the character from a rectangular image.
uniform vec4 transparent_color : source_color = vec4(1.0,0.0,1.0,1.0);   // 透明にする色 / the color to erase

void fragment() {
	vec4 color = texture(TEXTURE,UV);
	// 消したい色との近さを測る / measure how close this pixel is to the erase color
	float d = max(max(abs(transparent_color.x-color.x),abs(transparent_color.y-color.y)),abs(transparent_color.z-color.z));

	// 近くて、かつ「ピンクっぽい」なら透明にする / if close and pinkish, make it transparent
	if ((d<0.7)&&(abs(color.x-color.z)<0.5) && (color.x>2.0*color.y))
		color.a = 0.0;
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
