extends Area2D
# スピードアップ アイテム / A "speed-up" item.
# プレイヤーが触れると、走る速さが増えます。
# When the player touches it, their running speed increases.
#
# ★ 作り方のポイント / How this "add-in" item works:
#   ・Area2D を置いて、body_entered シグナルを下の関数につなぐだけ。
#     Just place an Area2D and connect its body_entered signal to the function below.
#   ・world.gd や player.gd は一切さわりません（「アドイン」方式）。
#     You never edit world.gd or player.gd (this is the "add-in" style).


@export var SPEED_BONUS = 150.0  # 速度に足す量 / how much speed to add


# プレイヤー(body)が範囲に入ってきたときに呼ばれる関数。
# Called when a body (the player) enters this Area2D.
func _on_body_entered(body: Node2D) -> void:
	body.SPEED += SPEED_BONUS   # プレイヤーの速さを増やす / make the player faster
	queue_free()                # アイテムを消す（使い切り）/ remove the item (one-time use)

# ★ かんたんな改造アイデア / Easy tweaks (almost no coding!):
#   ・SPEED_BONUS を変える → 速くなる量が変わる / change how much faster you get
#   ・body.SPEED を body.JUMP_VELOCITY にする → ジャンプ力アップ (マイナス方向に足す)
#     use body.JUMP_VELOCITY instead → a jump-power item (add a negative value)
#   ・body.GRAVITY_SCALE を変える → 重力が軽い／重いアイテム / lighter or heavier gravity
#   ・body.scale を変える → 小さく／大きくなるアイテム / shrink or grow the player
