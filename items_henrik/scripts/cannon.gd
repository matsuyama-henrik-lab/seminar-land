@tool
extends Area2D
# 大砲 / A cannon.
# プレイヤーが入ると、大砲の向きへ勢いよく発射します。
# When the player enters, it launches them in the direction the cannon points.
# 大砲のノードを回転させると発射方向が変わります（回転0で真上）。
# Rotate the Cannon node to aim (rotation 0 = straight up).
# ＠tool: エディタ上でも動き、発射の軌道を線でプレビュー表示します。
# @tool: also runs in the editor to draw a preview of the flight path.

## The player that gets launched. Assign it in the level (NodePath to ../player).
#@export var player: CharacterBody2D

var player: CharacterBody2D

## Launch speed in pixels/second, along the cannon's "up" direction.
## Rotate the Cannon node to aim; rotation 0 shoots straight up.
@export_range(0.0, 3000.0, 10.0, "or_greater") var launch_speed: float = 900.0:
	set(value):
		launch_speed = value
		queue_redraw()

## How far ahead of the cannon (along the aim) the player starts, so it sits
## on the drawn trajectory and out of the barrel instead of where it touched.
@export_range(0.0, 256.0, 1.0, "or_greater") var muzzle_offset: float = 64.0:
	set(value):
		muzzle_offset = value
		queue_redraw()

@export_group("Trajectory preview")
## Draw the predicted path while editing.
@export var show_in_editor: bool = true:
	set(value):
		show_in_editor = value
		queue_redraw()
## Also draw it while the game runs (handy for debugging).
@export var show_at_runtime: bool = false:
	set(value):
		show_at_runtime = value
		queue_redraw()
## How many seconds of flight to draw.

@export_range(0.0, 10.0, 0.01, "or_greater")  var preview_seconds: float = 2.0:
	set(value):
		preview_seconds = value
		queue_redraw()
@export var preview_color: Color = Color(1.0, 0.9, 0.2, 0.85)
## Second path drawn with flipped gravity (GRAVITY_SCALE * -1).
@export var preview_color_flipped: Color = Color(1.0, 0.3, 0.25, 0.85)

@onready var _sprite: AnimatedSprite2D = $Sprite2D
@onready var _fire_sprite: AnimatedSprite2D = $Sprite2D2
# Untyped on purpose: on web export the GPUParticles2D node is swapped for a
# CPUParticles2D before the level loads, so a static GPUParticles2D type here
# would fail to assign. restart()/emitting exist on both, so untyped is safe.
@onready var _particles = $GPUParticles2D

# Last gravity scale we drew with; NAN forces a redraw on the first frame.
#var _last_gravity_scale := NAN


func _ready() -> void:
	# Redraw automatically when the node is moved or rotated in the editor.
	set_notify_transform(true)
	queue_redraw()


#func _process(_delta: float) -> void:
	# In the editor, transform/property changes already trigger a redraw.
	# The player's GRAVITY_SCALE can change without notifying us, so poll it
	# (one float compare per frame) and redraw only when it actually changes.
	#if not Engine.is_editor_hint():
	#	return
	#var gs := _gravity_scale()
	#if gs != _last_gravity_scale:
	#	_last_gravity_scale = gs
	#	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


# --- Shooting -------------------------------------------------------------

## Unit vector of the cannon's aim in world space.
func aim_direction() -> Vector2:
	return Vector2.UP.rotated(global_rotation)


## World-space initial velocity the player will receive.
func launch_velocity() -> Vector2:
	return aim_direction() * launch_speed


## Where the player is placed at launch: on the trajectory, a bit up the barrel.
func muzzle_position() -> Vector2:
	return global_position + aim_direction() * muzzle_offset


# プレイヤーが入った → 大砲に装填して発射アニメを再生 / player entered → load and play the shoot animation
func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	player = body
		#body.process_mode = Node.PROCESS_MODE_DISABLED
	player.ignore_input = true
	player.visible = false
	player.global_position = muzzle_position()   # snap onto the trajectory
	_sprite.play("shoot")
			
			
			


# --- Trajectory preview ---------------------------------------------------

func _draw() -> void:
	var enabled := show_in_editor if Engine.is_editor_hint() else show_at_runtime
	if not enabled:
		return

	const gs = 1
	#var gs := _gravity_scale()
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


#func _gravity_scale() -> float:
#	if player:
#		return player.GRAVITY_SCALE
#	return 1.0


# 発射アニメが終わったら、実際にプレイヤーを飛ばす / when the shoot animation ends, actually launch the player
func _on_sprite_2d_animation_finished() -> void:
	if _sprite.animation == "shoot":
		_fire_sprite.play("fire")
		_sprite.play("default")
		_particles.restart()
		_particles.emitting = true
		player.launch(launch_velocity(),preview_seconds)   # ballistic launch (see player.gd)
		player.ignore_input  = false
		#player.process_mode = Node.PROCESS_MODE_INHERIT
		player.visible = true
			
