@tool
extends Node2D
# 半径ギズモ（エディタ専用の飾り）/ Radius gizmo — an editor-only helper.
# 当たり判定の円を、エディタ上で見えるように描くだけの道具。ゲーム中は何もしません。
# Just draws the collision circle so you can see it while editing. Does nothing at runtime.

## Editor-only helper that visualizes a CollisionShape2D in the editor
## WITHOUT stealing mouse clicks.
##
## A CollisionShape2D reports its full shape as its "edit rect", so it grabs
## every click inside that area in the 2D editor. Content drawn here via
## _draw() does NOT add to the edit rect, so the circle is visible but not
## clickable. Hide the real CollisionShape2D (visible = false) and drop one
## of these next to it.
##
## Has no effect at runtime: it only draws while the editor is open.

## 円を描いて見せたい当たり判定（CollisionShape2D）。半径と位置は自動で読み取ります。
## The shape to visualize. Its radius (and position) are read automatically.
@export var collision_shape: CollisionShape2D:
	set(value):
		collision_shape = value
		queue_redraw()

## オンのとき、下の fill_color ではなく当たり判定自身の debug_color を使います。
## When true, match the shape's own debug_color instead of fill_color below.
@export var use_debug_color: bool = true

## use_debug_color がオフのときに使う色。/ Used when use_debug_color is false.
@export var fill_color: Color = Color(0.596, 0.538, 0.218, 0.42)

## 塗りの上にくっきりした輪郭線を描きます。/ Draw a crisp outline on top of the fill.
@export var draw_outline: bool = true


func _ready():
	if not Engine.is_editor_hint():
		if collision_shape != null and collision_shape.shape != null:
			collision_shape.visible = true
			

func _process(_delta: float) -> void:
	# Track live changes to the shape's radius/position while editing.
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if collision_shape == null or collision_shape.shape == null:
		return

	var shape := collision_shape.shape
	var center := to_local(collision_shape.global_position)
	var color := collision_shape.debug_color if use_debug_color else fill_color

	if shape is CircleShape2D:
		var r: float = shape.radius
		draw_circle(center, r, color)
		if draw_outline:
			draw_arc(center, r, 0.0, TAU, 64, Color(color, 1.0), 1.0)
