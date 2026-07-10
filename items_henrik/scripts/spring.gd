extends Area2D
# バネ（ジャンプ台）/ A spring (bounce pad).
# プレイヤーが乗ると、上に高くはね上げます。
# When the player steps on it, launch them high into the air.

@export var LAUNCH_VELOCITY = -900.0   # はね上げる速さ（マイナス＝上）/ launch speed (minus = up)
@onready var animation: AnimatedSprite2D = $animation


# プレイヤー(body)が乗ったときに呼ばれる / called when the player touches the spring
func _on_body_entered(body: Node2D) -> void:
	body.velocity.y = LAUNCH_VELOCITY   # プレイヤーを上へ飛ばす / send the player upward
	body.animation.play("jump")         # プレイヤーをジャンプ姿勢に / player's jump pose
	animation.play("jump")              # バネのアニメを再生 / play the spring animation
