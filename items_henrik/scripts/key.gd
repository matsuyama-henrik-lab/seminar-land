extends Area2D
# カギ / A collectible key.
# ふわふわ浮いていて、集めるとゴール（旗）が開きます。数は key_counter が数えます。
# Floats gently; collecting keys unlocks the goal flag. key_counter tallies them.

const KEY_COUNTER = preload("uid://bt200msgjcbxp")   # カギの個数カウンター / the key-counter scene
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var start_position : Vector2
var start_scale : Vector2
var elapsed : float = 0.0           # 浮遊アニメ用の時間 / timer for the hover animation
const key_group = "keys"            # 全てのカギを入れるグループ / group holding every key
signal key_found                    # 取られたときに出す合図 / emitted when this key is collected

func _ready() -> void:
	elapsed = randf_range(0,100)     # 浮き方をバラバラにする / stagger the hover so keys aren't in sync
	start_position = global_position
	start_scale = scale
	var keys = get_tree().get_nodes_in_group(key_group)
	add_to_group(key_group)
	# ステージで最初のカギだけがカウンターを1つ作る / the first key in the level spawns one counter
	if len(keys)==0:
		var key_counter = KEY_COUNTER.instantiate()
		get_parent().add_child.call_deferred(key_counter)


# 取られたときの演出：上に飛んで回転しながら小さくなる / collect effect: fly up, spin, shrink
func collected_animation(val):
	position.y -= val*250.0
	rotation = val*PI*4
	scale = start_scale * (1-val)


# プレイヤーが触れた → カギを取る / player touched it → collect the key
func _on_body_entered(body: Node2D) -> void:
	collision_shape_2d.set_deferred("disabled", true)   # 二重取得を防ぐ / prevent collecting twice
	key_found.emit()                                    # カウンターに知らせる / tell the counter
	var tween = create_tween()
	tween.tween_method(collected_animation,
		0.0,
		1.0, 1).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): queue_free())          # 演出後に消す / remove after the effect


func _process(delta: float) -> void:
	elapsed += delta
	# 開始位置のまわりでゆっくり上下に浮く / gently hover up and down around the start position
	global_position.y = start_position.y - (1+sin(elapsed * 3.0)) * 15.0
