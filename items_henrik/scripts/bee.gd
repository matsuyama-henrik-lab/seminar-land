extends Area2D
# ハチの敵 / A bee enemy.
# プレイヤーが近づくと追いかけてきて、ぶつかるとゲームオーバー。
# Chases the player when they come near; touching it ends the game.
@onready var bee: Area2D = $Bee
@onready var bee_animation: AnimatedSprite2D = $Bee/bee_animation

var velocity: Vector2 = Vector2.ZERO
var player = null                 # 追いかける相手（いなければ null）/ who to chase (null if none)
var target_position : Vector2     # ハチが目指す位置 / where the bee is heading

@export var attack_speed : float = 1    # 追いかける速さ / how fast it chases
@export var attack_update : float = 2   # 狙いを更新する速さ / how quickly it re-aims

var group_name: String = "flip_gravity"   # 重力反転で一緒に回るグループ / group that flips with gravity

var noise : Vector2   # ふらふら漂うためのランダムな揺れ / random wobble for idle drifting

func _ready() -> void:
	target_position = global_position
	target_position = bee.global_position
	bee.add_to_group(group_name)


func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		# プレイヤーがいる → その方へ狙いを寄せる / player in range → aim toward them
		target_position = target_position.move_toward(player.global_position, delta*50*attack_update)
	else:
		# いない → ランダムにふらふら漂う / no player → drift around randomly
		noise = noise.move_toward(Vector2(randf_range(-25,25),randf_range(-25,25)),delta*10)
		target_position = global_position + noise
	# 狙いの位置へ少しずつ移動 / move a little toward the aim each frame
	bee.global_position = bee.global_position.move_toward(target_position,delta*100*attack_speed)


# プレイヤーが範囲に入った → 追いかけ開始 / player entered range → start chasing
func _on_body_entered(body: Node2D) -> void:
	player = body
	target_position = body.global_position
	bee_animation.material.set_shader_parameter("hit_player", true)   # 怒りの色に / turn "angry"


# プレイヤーが範囲から出た → 追いかけ終了 / player left range → stop chasing
func _on_body_exited(body: Node2D) -> void:
	player = null
	bee_animation.material.set_shader_parameter("hit_player", false)


# ハチ本体がプレイヤーに当たった → ゲームオーバー / the bee itself hit the player → game over
func _on_bee_body_entered(body: Node2D) -> void:
	body.died.emit()
