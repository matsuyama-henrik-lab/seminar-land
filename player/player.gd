extends CharacterBody2D
# プレイヤー / The player character.
# 左右で移動、スペース（ui_accept）でジャンプします。
# Move left/right, jump with space (ui_accept).
# ★ アイテム（追加要素）は、この下の SPEED / JUMP_VELOCITY / GRAVITY_SCALE や
#    scale、died / level_complete の合図を通してプレイヤーに触れます。
#    このスクリプトを書き変えなくても、アイテム側から性能を変えられます。
# ★ Items (add-ins) touch the player only through the exports below
#    (SPEED / JUMP_VELOCITY / GRAVITY_SCALE / scale) and the signals
#    (died / level_complete), so an item can change the player WITHOUT
#    editing this script.

@onready var camera: Camera2D = $Camera

@export var SPEED = 300.0          # 横の移動速度
@export var JUMP_VELOCITY = -500.0  # ジャンプの速さ（マイナスが上方向）
@export var GRAVITY_SCALE = 1.0    # 重力の強さ（1.0 が標準）


signal died
signal level_complete


	

@onready var animation = $animation

# 大砲などで発射された直後は、空中で横入力・減速を無視して弾道を保つ。
# While true, keep the launch velocity: no air control, no horizontal damping.
var launched := false
var ignore_input := false

# カメラのズーム用トゥイーン。同時に2つ走ると値が競合してガタつくので使い回す。
# The single zoom tween; keeping one reference avoids two tweens fighting over camera.zoom.
var _zoom_tween: Tween

func _zoom_to(val): camera.zoom = Vector2(val, val)

## Called by the cannon: give the player a velocity and enter ballistic flight.
func launch(v: Vector2, duration:float) -> void:
	velocity = v
	launched = true
	animation.play("fall")
	animation.flip_h = v.x < 0
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()   # stop any running zoom (e.g. the intro) first
	_zoom_tween = create_tween()
	#var v_mag = v.length()/1000
	# ズームアウト → ズームイン（1 → 0.5 → 1）を1周。
	var zoom_level = clamp(1.0/duration,0.3,0.8)
	_zoom_tween.tween_method(_zoom_to, 1.0, zoom_level, 0.5).set_trans(Tween.TRANS_SINE)
	_zoom_tween.tween_interval(clamp(duration-0.5-1.0,0,10))
	_zoom_tween.tween_method(_zoom_to, zoom_level, 1.0, 1.0).set_trans(Tween.TRANS_SINE)

func _ready() -> void:
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_method(_zoom_to, 0.1, 1.0, 4.0).set_ease(Tween.EASE_OUT)

# 毎フレームの物理更新：移動・ジャンプ・重力 / physics update each frame: move, jump, gravity
func _physics_process(delta: float) -> void:
	if ignore_input:   # 大砲の発射アニメ中などは操作を止める / freeze input (e.g. during cannon launch)
		return

	if not launched:
		# 空中なら重力で下（GRAVITY_SCALE で強さや向きが変わる）/ apply gravity while airborne
		if not is_on_floor():
			velocity += get_gravity() * GRAVITY_SCALE * delta



		# 左キー=-1 / 入力なし=0 / 右キー=1 / left=-1, none=0, right=1
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			animation.flip_h = direction < 0   # 進む向きに絵を反転 / face the way we move
			if is_on_floor() and velocity.y >= 0:
				animation.play("walk")
			elif velocity.y > 0:
				animation.play("fall")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)   # 入力なし→ゆっくり停止 / no input → slow to a stop
			if is_on_floor() and velocity.y >= 0:
				animation.play("idle")
	else:
		# 発射中は横操作せず弾道だけ（重力の向きは GRAVITY_SCALE の符号で）/ launched: ballistic only
		velocity += get_gravity() * sign(GRAVITY_SCALE) * delta
	#elif (direction and velocity.y>0):
#		velocity.x = direction * SPEED
#		animation.flip_h = direction < 0
		

	# 地面にいるときだけジャンプできる / can only jump while on the floor
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animation.play("jump")

	move_and_slide()

	# 発射後、地面・壁・天井のどれかにぶつかったら操作を取り戻す。
	# End the launch on ANY environment contact (floor, wall or ceiling).
	if launched and get_slide_collision_count() > 0:
		launched = false

	# 画面の下に落ちた（または上に飛びすぎた）ら死ぬ / fell off the bottom (or shot too high) → die
	if position.y>0 or position.y<-10000:
		died.emit()


# ─────────────────────────────────────────────────────────────────────────
# ★ 練習問題（任意）/ OPTIONAL EXERCISE
#   これは上の _physics_process とほぼ同じですが、一部が穴あき（Q3・Q4）です。
#   関数名の末尾に「__」が付いているので、今は使われていません。
#   遊んでみたい人は：この関数を「_physics_process」に、上の本物を
#   「_physics_process_real」などに名前を変えて、Q3・Q4 の "???"／false を
#   A〜H の正しい選択肢に直してみましょう。
#   This is almost the same as _physics_process above, but with blanks (Q3, Q4).
#   The trailing "__" means it is NOT used right now. To try it: rename this to
#   "_physics_process" (and rename the real one), then replace the "???"/false
#   in Q3 and Q4 with the correct choice from A–H.
# ─────────────────────────────────────────────────────────────────────────
func _physics_process__(delta: float) -> void:
	# 選択肢 / All choices, use these names as your answers:
	var A = is_on_floor()       # 地面にいる？       (on the ground)
	var B = not is_on_floor()   # 空中にいる？       (in the air)
	var C = true
	var D = false
	var E = "idle"              # 止まっている       (standing still)
	var F = "walk"              # 歩いている         (walking)
	var G = "jump"              # ジャンプ中         (jumping)
	var H = "fall"              # 落下中             (falling)

	# ── Q1: 重力はどのときに働く？ ──────────────────────
	#   A = is_on_floor()    B = not is_on_floor()
	#   C = true             D = false
	#var Q1 = is_on_floor()     # ← false を A/B/C/D に変えよう
	#var Q1 : bool = is_on_floor()     # ← false を A/B/C/D に変えよう
	# ────────────────────────────────────────────────────
	#if not Q1:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# direction は -1（左キー）、0（入力なし）、1（右キー）
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:   # direction が -1 か 1 のとき（0 は false 扱い）
		velocity.x = direction * SPEED
		animation.flip_h = direction < 0
		if is_on_floor() and velocity.y >= 0:
			animation.play("walk")
		elif velocity.y > 0:
			animation.play("fall")
	else:
		# direction が 0 → 入力なし → velocity.x をゆっくり 0 に近づける（減速・停止）
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and velocity.y >= 0:
			# ── Q3: 入力がなく、地面で止まっているときのアニメは？ ──
			#   E = "idle"  止まっている   F = "walk"  歩いている
			#   G = "jump"  ジャンプ中     H = "fall"  落下中
			var Q3 : String = "???"   # ← "???" を E/F/G/H に変えよう
			# ──────────────────────────────────────────────────────
			animation.play(Q3)

	# ── Q4: ジャンプできるのはどのとき？ ────────────────
	#   A = is_on_floor()    B = not is_on_floor()
	#   C = true             D = false
	var Q4 : bool = false   # ← false を A/B/C/D に変えよう
	# ────────────────────────────────────────────────────
	if Input.is_action_just_pressed("ui_accept") and Q4:
		velocity.y = JUMP_VELOCITY
		animation.play("jump")

	move_and_slide()
	
	
	if position.y>0:
		died.emit()
