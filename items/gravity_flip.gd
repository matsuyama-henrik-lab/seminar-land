extends Area2D
# 重力ぎゃくてん アイテム / A "gravity-flip" item.
# プレイヤーが触れると、上と下が入れかわります（天井を歩く！）。
# When the player touches it, up and down swap over (walk on the ceiling!).
#
# ★ これも「アドイン」/ Also an add-in:
#   Area2D + body_entered だけ。world.gd / player.gd はさわりません。
#   Just an Area2D + body_entered. No changes to world.gd / player.gd.


# プレイヤー(body)が範囲に入ってきたときに呼ばれる関数。
# Called when a body (the player) enters this Area2D.
func _on_body_entered(body: Node2D) -> void:
	body.GRAVITY_SCALE *= -1   # 重力の向きを反転 / reverse the direction of gravity
	body.JUMP_VELOCITY *= -1   # ジャンプの向きも反転 / jump the other way too
	body.scale.y *= -1         # 見た目を上下反転 / flip the sprite upside-down

	# 反転の向きに合わせて「上」がどっちかを設定する。
	# Tell the player which way is now "up" so it lands correctly.
	if sign(body.scale.y) > 0:
		body.up_direction = Vector2.UP     # ふつう / normal
	else:
		body.up_direction = Vector2.DOWN   # さかさま / upside-down

# ★ かんたんな改造アイデア / Easy tweaks:
#   ・queue_free() を追加すれば「一度きり」に / add queue_free() to make it one-time use
#   ・body.scale だけ変えると、重力そのままで見た目だけ変えられる
#     change only body.scale to resize the player without touching gravity
