extends Area2D
# 火の玉 / A fireball hazard.
# 定期的に飛び出しては落ちて、また飛び出す。触れるとゲームオーバー。
# Leaps up, falls back, waits, and leaps again. Touching it ends the game.
# Untyped: World may swap this for a CPUParticles2D in web builds (see world.gd).
@onready var smoke = $smoke

@onready var icon_fireball: Sprite2D = $IconFireball
@export var bounce_velocity : float = -1000   # 飛び出す速さ（マイナス＝上）/ leap speed (minus = up)
@export var delay : float = 2                 # 次に飛び出すまでの待ち時間 / pause before the next leap

var velocity: Vector2 = Vector2.ZERO
var wait_time : float = 0            # 残りの待ち時間 / seconds left to wait
var start_position : Vector2        # 元の位置（飛び出す原点）/ home position it leaps from

func _ready() -> void:
	start_position = position

func _physics_process(delta: float) -> void:
	
	# 待ち時間中は何もしない / while waiting, do nothing
	if wait_time>0:

		wait_time -= delta
		return
	elif not smoke.emitting:
		smoke.emitting = true   # 飛んでいる間は煙を出す / emit smoke while flying
		#smoke.restart()
	
	var gravity_direction = - sign(bounce_velocity)	# 落ちる向き / which way is "down"

	# 元の位置まで戻ってきたら着地：止めて待つ / back at home → land, then pause
	if gravity_direction * position.y > gravity_direction * start_position.y:
		wait_time = delay
		velocity.y = bounce_velocity
		position.y = start_position.y
		smoke.emitting = false
		icon_fireball.flip_v = (velocity.y > 0)
		
		return
	else:
		velocity.y += gravity_direction * get_gravity() * delta   # 重力で加速 / accelerate with gravity

	position +=  velocity * delta
	
	
	
	icon_fireball.flip_v = (velocity.y > 0)   # 落ちるときは絵を上下反転 / flip sprite while falling


# プレイヤーに触れた → ゲームオーバー / touched the player → game over
func _on_body_entered(body: Node2D) -> void:
	body.died.emit()
