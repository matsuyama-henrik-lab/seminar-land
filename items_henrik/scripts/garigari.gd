extends Area2D
# ガリガリ（回転のこぎり）/ A spinning saw-blade hazard.
# ゆっくり回っていて、プレイヤーが近づくと高速回転＆火花。触れるとゲームオーバー。
# Spins slowly; speeds up and sparks when the player is near. Touching it ends the game.
# Untyped: World may swap this for a CPUParticles2D in web builds (see world.gd).
@onready var sparks = $GPUParticles2D
@onready var blade: Sprite2D = $blade
var rotation_speed : float = 1     # 回転の速さ / how fast it spins
var original_scale : Vector2       # 元の大きさ / the blade's normal size


var group_name: String = "flip_gravity"   # 重力反転で一緒に回るグループ / group that flips with gravity
var direction = 1                  # 回る向き（+1 / -1）/ spin direction (+1 / -1)


# 最初の1回だけ呼ばれる / called once when it enters the scene
func _ready() -> void:
	original_scale = blade.scale
	add_to_group(group_name)


# 毎フレーム呼ばれる。delta は前フレームからの経過時間。
# Called every frame; 'delta' is the time since the last frame.
func _process(delta: float) -> void:
	blade.rotation += direction * rotation_speed * delta   # 刃を回す / rotate the blade


# 刃がプレイヤーに触れた → ゲームオーバー / the blade touched the player → game over
func _on_body_entered(body: Node2D) -> void:
	body.died.emit()


# プレイヤーが近くのエリアに入った → 高速回転＆火花 / player entered the nearby area → spin fast + spark
func _on_area_2d_body_entered(body: Node2D) -> void:
		rotation_speed = 20
		blade.scale = original_scale * 1.25
		sparks.emitting = true
		sparks.restart()


# プレイヤーが離れた → 元に戻して逆回転 / player left → calm down and reverse spin
func _on_area_2d_body_exited(body: Node2D) -> void:
		rotation_speed = 1
		blade.scale = original_scale
		direction *= -1
		
