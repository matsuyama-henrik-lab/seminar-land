extends CanvasLayer
class_name TouchKeyButton
# 画面上のタッチボタン / An on-screen touch button.
# スマホ・タブレットで、キーボードのキーを押した「ふり」をするボタンです。
# On phones/tablets, this button pretends a keyboard key was pressed.
# プレイヤーのスクリプトを変えずに、タッチ操作を追加できます。
# Lets you add touch controls without changing the player script.

# Reusable on-screen touch button that emulates a physical keyboard key.
#
# Drop one instance per key into any level to give touch players a control that
# a keyboard-only player script already reads (e.g. student 04's run = SHIFT,
# fire = V). Unlike world.gd's built-in D-pad -- which injects named input
# *actions* -- this injects a real InputEventKey via Input.parse_input_event(),
# so it drives scripts that poll Input.is_key_pressed(KEY_*) or read
# event.keycode directly, with NO change to their player script.
#
# It hit-tests raw touch events itself (like world.gd) instead of relying on a
# GUI Button, so several of these can be held at once together with the D-pad
# (a plain Control only tracks one pointer, which is what stops two buttons
# being held at once). Hidden until the first touch, so desktop keyboard play
# never shows it.

## Text shown on the button.
@export var button_label: String = "RUN":
	set(v):
		button_label = v
		if is_node_ready() and _button:
			_button.text = v

## The keyboard key this button emulates (KEY_SHIFT, KEY_V, ...). Set it to the
## key the level's player script actually reads.
@export var emulated_key: Key = KEY_SHIFT

## Button size in pixels.
@export var button_size: Vector2 = Vector2(120, 120):
	set(v):
		button_size = v
		if is_node_ready():
			_apply_layout()

## Top-left of the button measured from the screen's bottom-right corner
## (negative values inset it from the edge). Give each instance a different
## value so multiple buttons don't overlap.
@export var offset_from_bottom_right: Vector2 = Vector2(-140, -280):
	set(v):
		offset_from_bottom_right = v
		if is_node_ready():
			_apply_layout()

## Show immediately instead of waiting for the first touch (handy for desktop
## testing, or devices where you always want it visible).
@export var always_visible: bool = false

var _button: Button
# Pointer ids (touch index, or "mouse") currently pressing this button. The key
# is held while this is non-empty, so several fingers on the button behave.
var _held := {}
var _revealed := false

func _ready() -> void:
	layer = 12  # above the lava (10) and the D-pad (11), below the menu (20)
	_button = Button.new()
	_button.text = button_label
	_button.focus_mode = Control.FOCUS_NONE
	# We hit-test pointers ourselves for multitouch, so the Button must not
	# consume input or self-trigger -- it is purely the visual.
	_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_theme_font_size_override("font_size", 30)
	add_child(_button)
	_apply_layout()
	visible = always_visible
	_revealed = always_visible

func _apply_layout() -> void:
	if not _button:
		return
	_button.anchor_left = 1.0
	_button.anchor_top = 1.0
	_button.anchor_right = 1.0
	_button.anchor_bottom = 1.0
	_button.offset_left = offset_from_bottom_right.x
	_button.offset_top = offset_from_bottom_right.y
	_button.offset_right = offset_from_bottom_right.x + button_size.x
	_button.offset_bottom = offset_from_bottom_right.y + button_size.y

func _rect() -> Rect2:
	return _button.get_global_rect()

func _emit_key(pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = emulated_key
	ev.physical_keycode = emulated_key
	ev.pressed = pressed
	# Reflect the matching modifier flag so scripts that read it stay consistent.
	match emulated_key:
		KEY_SHIFT:
			ev.shift_pressed = pressed
		KEY_CTRL:
			ev.ctrl_pressed = pressed
		KEY_ALT:
			ev.alt_pressed = pressed
		KEY_META:
			ev.meta_pressed = pressed
	Input.parse_input_event(ev)

func _press(id) -> void:
	if _held.has(id):
		return
	var was_empty := _held.is_empty()
	_held[id] = true
	if was_empty:
		_emit_key(true)
		_button.button_pressed = true

func _release(id) -> void:
	if not _held.has(id):
		return
	_held.erase(id)
	if _held.is_empty():
		_emit_key(false)
		_button.button_pressed = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not _revealed and event.pressed:
			# First touch anywhere only reveals the control; play starts next tap
			# (matches world.gd's D-pad reveal).
			_revealed = true
			visible = true
			return
		if not visible:
			return
		if event.pressed:
			if _rect().has_point(event.position):
				_press(event.index)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if not visible:
			return
		# A finger may slide off or onto the button while held.
		if _rect().has_point(event.position):
			_press(event.index)
		else:
			_release(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Desktop testing path (single pointer); only once revealed/visible.
		if not visible:
			return
		if event.pressed and _rect().has_point(event.position):
			_press("mouse")
		else:
			_release("mouse")

func _exit_tree() -> void:
	# Don't leave an emulated key stuck down if we're removed mid-press
	# (e.g. the level unloads while the button is held).
	if not _held.is_empty():
		_held.clear()
		_emit_key(false)
