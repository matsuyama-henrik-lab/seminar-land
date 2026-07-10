@tool
extends Area2D
# 大砲 / A cannon.
# プレイヤーが入ると、大砲の向きへ勢いよく発射します。
# When the player enters, it launches them in the direction the cannon points.
# 大砲のノードを回転させると発射方向が変わります（回転0で真上）。
# Rotate the Cannon node to aim (rotation 0 = straight up).
# ＠tool: エディタ上でも動き、発射の軌道を線でプレビュー表示します。
# @tool: also runs in the editor to draw a preview of the flight path.

# 発射されるプレイヤー。ぶつかった相手を自動でおぼえます。
# The player that gets launched (remembered automatically on contact).
var player: CharacterBody2D

## 発射の速さ（ピクセル/秒）。大砲の「上」向きに飛ばします。
## 大砲ノードを回すと向きが変わります（回転0で真上）。
## Launch speed (px/s) along the cannon's "up". Rotate the node to aim (0 = up).
@export_range(0.0, 3000.0, 10.0, "or_greater") var launch_speed: float = 900.0:
	set(value):
		launch_speed = value
		queue_redraw()

## プレイヤーを砲口から少し前に出す距離。ぶつかった場所ではなく、
## 描かれた軌道の上（砲身の外）からスタートさせます。
## How far ahead of the barrel the player starts, so it sits on the drawn path.
@export_range(0.0, 256.0, 1.0, "or_greater") var muzzle_offset: float = 64.0:
	set(value):
		muzzle_offset = value
		queue_redraw()

@export_group("Trajectory preview")
## 編集中に、飛んでいく予想ライン（軌道）を表示します。
## Draw the predicted flight path while editing.
@export var show_in_editor: bool = true:
	set(value):
		show_in_editor = value
		queue_redraw()
## ゲーム中にも軌道を表示します（動作確認に便利）。
## Also draw it while the game runs (handy for debugging).
@export var show_at_runtime: bool = false:
	set(value):
		show_at_runtime = value
		queue_redraw()
## 軌道を何秒ぶん描くか。
## How many seconds of flight to draw.
@export_range(0.0, 10.0, 0.01, "or_greater")  var preview_seconds: float = 2.0:
	set(value):
		preview_seconds = value
		queue_redraw()
## 軌道ラインの色。
## Colour of the trajectory line.
@export var preview_color: Color = Color(1.0, 0.9, 0.2, 0.85)
## 重力が反転しているとき（GRAVITY_SCALE × -1）に描くもう1本の色。
## Second path drawn with flipped gravity (GRAVITY_SCALE * -1).
@export var preview_color_flipped: Color = Color(1.0, 0.3, 0.25, 0.85)

@onready var _sprite: AnimatedSprite2D = $Sprite2D
@onready var _fire_sprite: AnimatedSprite2D = $Sprite2D2
# 型をあえて書いていません（Web版では GPUParticles2D が CPUParticles2D に
# 差し替わるため）。どちらも restart()/emitting を持つので型なしで安全です。
# Untyped on purpose: on web export the GPUParticles2D node is swapped for a
# CPUParticles2D before the level loads, so a static GPUParticles2D type here
# would fail to assign. restart()/emitting exist on both, so untyped is safe.
@onready var _particles = $GPUParticles2D


func _ready() -> void:
	# エディタで大砲を動かす・回すたびに軌道を描き直す / redraw when moved or rotated in the editor
	set_notify_transform(true)
	queue_redraw()



func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


# --- 発射のしくみ / Shooting ------------------------------------------------
# ここから下は大砲の内部の計算です。ふつうは変更しません。
# The rest of the file is the cannon's internal maths — you normally don't edit it.

## 大砲が狙っている向き（長さ1のベクトル）/ the cannon's aim as a unit vector.
func aim_direction() -> Vector2:
	return Vector2.UP.rotated(global_rotation)


## プレイヤーに与える最初の速度 / the initial velocity the player receives.
func launch_velocity() -> Vector2:
	return aim_direction() * launch_speed


## 発射時にプレイヤーを置く位置（砲身の少し先）/ where the player starts, up the barrel.
func muzzle_position() -> Vector2:
	return global_position + aim_direction() * muzzle_offset


# プレイヤーが入った → 大砲に装填して発射アニメを再生 / player entered → load and play the shoot animation
func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	player = body
	player.ignore_input = true                    # 操作を一時とめる / freeze player input
	player.visible = false                        # 発射アニメの間は隠す / hide during the shoot anim
	player.global_position = muzzle_position()    # 軌道の上にそろえる / snap onto the trajectory
	_sprite.play("shoot")


# --- 軌道プレビュー / Trajectory preview -------------------------------------
# エディタ上で飛ぶ道すじを線で描くための部分。ゲームの動きには影響しません。
# Draws the flight path as a line in the editor; does not affect gameplay.

func _draw() -> void:
	var enabled := show_in_editor if Engine.is_editor_hint() else show_at_runtime
	if not enabled:
		return

	const gs = 1
	# Normal gravity, then flipped gravity (as if GRAVITY_SCALE *= -1).
	_draw_path(_simulate_path(-gs), preview_color_flipped)
	_draw_path(_simulate_path(gs), preview_color)


func _draw_path(points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 2:
		draw_polyline(points, color, 2.0, true)
	# End marker where the player would be after preview_seconds.
	if not points.is_empty():
		draw_circle(points[points.size() - 1], 6.0, color)


## Reproduces the player's fixed-step Euler integration, so the drawn path
## matches the real flight exactly (velocity is updated, then position).
func _simulate_path(gravity_scale: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var step := 1.0 / float(Engine.get_physics_ticks_per_second())
	var gravity := _gravity_vector() * gravity_scale
	var vel := launch_velocity()
	var pos := muzzle_position()   # start where the player is actually placed
	var t := 0.0
	while t < preview_seconds:
		pts.append(to_local(pos))   # draw in the cannon's local space
		vel += gravity * step
		pos += vel * step
		t += step
	return pts


func _gravity_vector() -> Vector2:
	var mag: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	var dir: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector", Vector2.DOWN)
	return dir * mag


# 発射アニメが終わったら、実際にプレイヤーを飛ばす / when the shoot animation ends, actually launch the player
func _on_sprite_2d_animation_finished() -> void:
	if _sprite.animation == "shoot":
		_fire_sprite.play("fire")
		_sprite.play("default")
		_particles.restart()
		_particles.emitting = true
		player.launch(launch_velocity(),preview_seconds)   # ballistic launch (see player.gd)
		player.ignore_input  = false
		player.visible = true
