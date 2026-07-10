shader_type canvas_item;
// 敵（てき）の点滅（てんめつ）効果 / The enemy's flashing effect.
// hit_player が true の間、敵が赤くチカチカ点滅します（当たり判定中の合図）。
// While hit_player is true the enemy flashes red (a hit indicator).
uniform bool hit_player = false;   // スクリプトから true/false を切り替える / toggled from the script


void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (hit_player)
	{
		// 緑と青を弱め、赤を強めて赤い点滅にする / dim green+blue, boost red → red flash
		color.gb *= (1.0+cos(10.0*TIME))/2.0;
		color.r += (1.0+cos(10.0*TIME))/2.0;
	}
	COLOR = color;
}
