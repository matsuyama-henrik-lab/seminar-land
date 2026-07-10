extends Area2D
# 重力ぎゃくてん（フル版）/ Gravity-flip item (full version).
# items/gravity_flip.gd の豪華版。回転アニメ付きで、同じグループの飾りも一緒に回します。
# A fancier version of items/gravity_flip.gd: adds a spin animation and rotates
# every decoration in the same group together.

@onready var sprite_2d: Sprite2D = $Sprite2D
var group_name: String = "flip_gravity"   # 一緒に回す仲間のグループ名 / group of nodes that spin together

func _ready() -> void:
	add_to_group(group_name)   # 自分もそのグループに入る / join that group


# プレイヤー(body)が触れたときに呼ばれる / called when the player touches it
func _on_body_entered(body: Node2D) -> void:
	body.GRAVITY_SCALE *= -1   # 重力の向きを反転 / reverse gravity
	body.JUMP_VELOCITY *= -1   # ジャンプの向きも反転 / jump the other way too
	body.scale.y *= -1         # 見た目を上下反転 / flip the sprite

	# 反転に合わせて「上」がどっちかを設定 / set which way is now "up"
	if sign(body.scale.y)>0:
		body.up_direction  = Vector2.UP
	else:
		body.up_direction  = Vector2.DOWN

	# グループ内のノードを 180 度くるっと回す / spin every node in the group by 180°
	var flips = get_tree().get_nodes_in_group(group_name)
	for flip in flips:
		var tween = create_tween()
		var start_rotation = 0 if (body.GRAVITY_SCALE < 0) else PI
		var end_rotation = start_rotation + PI
		tween.tween_method(func(val): flip.rotation = val, 
			start_rotation, 
			end_rotation, 0.1).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func(): flip.rotation = end_rotation) # Ensures it snaps to the exact final value
