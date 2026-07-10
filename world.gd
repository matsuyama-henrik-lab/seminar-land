extends Node2D
# ゲーム全体の司令塔 / The game manager.
# メニューの表示、ステージの読み込みと切り替え、背景の溶岩、タッチ操作をまとめて管理します。
# Handles the menus, loading/switching stages, the lava background, and touch controls.
# ★ 自分のステージを追加するには、このスクリプトではなく、下の levels 配列に
#    シーンを足すだけでOK（インスペクターから）。ここは基本さわりません。
# ★ To add your own stage you do NOT edit this script — just add your scene to the
#    `levels` array below (via the Inspector). You normally never touch this file.
# （以下の英語コメントは仕組みの詳しい説明です。/ The English notes below explain the internals.）

@export var levels: Array[PackedScene] = []
# Levels hidden from the single-level "Select Level" list (e.g. level_end.tscn).
# They still play in sequence mode. Matched by scene path, so an excluded level
# stays hidden even if it appears several times in `levels`. Add more via the Inspector.
@export var exclude_from_level_select: Array[PackedScene] = []
# Optional level shown running behind the menus as a live backdrop. Its player
# (if any) is frozen and ignores input, and no gameplay signals are wired up, so
# it just animates and never reacts to the user. Leave empty for a plain menu.
@export var background_scene: PackedScene = null
const EXPLODE = preload("uid://cn4wyiff3syyq")
const LAVA_SHADER = preload("res://lava_background.gdshader")

var current_level_index: int = 0
var _current_level: Node = null
var _background_level: Node = null  # decorative level running behind the menus
var _swapping: bool = false  # guards against re-entrant reloads (e.g. repeated died.emit())
var _lava_material: ShaderMaterial
var _lava_rect: ColorRect

# When true, finishing a level returns to the menu instead of advancing (set by
# the "Select Level" flow); when false the game plays through `levels` in order.
var _single_level: bool = false
# The menus are editable scenes instanced under MenuLayer in world.tscn. World
# only fills the level list, reacts to their signals, and toggles visibility.
# Touch-to-mouse emulation is off (so the multitouch game controls work), which
# means the menu's Control buttons don't get touch on their own — we hit-test
# them by hand in _handle_menu_touch, just like the on-screen game buttons.
@onready var _main_menu: Control = $MenuLayer/MainMenu
@onready var _level_select: Control = $MenuLayer/LevelSelect

# Manual touch state for the menus (see comment above). Tracks the finger that
# is choosing a menu button so a tap fires it but a drag scrolls instead.
var _menu_touch_index = null
var _menu_touch_button: Button = null
var _menu_touch_start := Vector2.ZERO
var _cached_level_scroll: ScrollContainer = null

func _ready() -> void:
	_setup_lava_background()
	_setup_buttons()
	_setup_web_fullscreen()
	_connect_menus()
	# Start on the menu instead of jumping straight into the first level.
	_show_main_menu()

# Maps each on-screen button to the input action it drives.
var _touch_buttons := {}
# Tracks which action each active pointer (finger index, or "mouse") is holding,
# so we can support several buttons held at once and release correctly.
var _active_pointers := {}

func _setup_buttons() -> void:
	_touch_buttons = {
		$CanvasLayer/HBoxContainer/left: "ui_left",
		$CanvasLayer/HBoxContainer/right: "ui_right",
		$CanvasLayer/HBoxContainer2/up: "ui_accept",
	}
	for btn in _touch_buttons:
		# Buttons must never hold keyboard focus (ui_accept also activates a
		# focused button), and we hit-test pointers ourselves for true
		# multitouch, so the buttons shouldn't consume pointer events — a
		# Control only tracks one pointer, which is exactly the limitation
		# that stops two buttons being held at once.
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The on-screen menu button is hit-tested by hand too (touch emulation is off),
	# so it also mustn't take focus or consume pointer events.
	$CanvasLayer/HBoxContainer3/menu.focus_mode = Control.FOCUS_NONE
	$CanvasLayer/HBoxContainer3/menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Hidden until the first touch; a device that's actually being touched
	# reveals them, while mouse/keyboard play never does.
	$CanvasLayer/HBoxContainer.hide()
	$CanvasLayer/HBoxContainer2.hide()
	$CanvasLayer/HBoxContainer3.hide()

func _setup_web_fullscreen() -> void:
	# Browsers only enter fullscreen from inside a real user-gesture event.
	# Going through Godot's _input() loses that "user activation", so instead we
	# attach a one-shot native 'touchend' listener that calls requestFullscreen()
	# in the genuine gesture context on the first real touch. We deliberately do
	# NOT listen for 'mousedown', so a desktop browser mouse click never forces
	# fullscreen.
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(function() {
			var canvas = document.getElementById('canvas') || document.querySelector('canvas');
			if (!canvas) return;
			function goFullscreen() {
				var req = canvas.requestFullscreen || canvas.webkitRequestFullscreen
					|| canvas.mozRequestFullScreen || canvas.msRequestFullscreen;
				if (req) req.call(canvas);
				window.removeEventListener('touchend', goFullscreen);
			}
			window.addEventListener('touchend', goFullscreen, { once: true });
		})();
	""", true)

# -----------------------------------------------------------------------------
# Menu: a main menu (Start / Select Level) and a level-select list, both editable
# scenes under MenuLayer. World connects to their signals and feeds the level list.
# -----------------------------------------------------------------------------
func _connect_menus() -> void:
	_main_menu.start_pressed.connect(_on_start_pressed)
	_main_menu.select_pressed.connect(_on_select_pressed)
	_level_select.level_chosen.connect(_on_level_pressed)
	_level_select.back_pressed.connect(_show_main_menu)

# Builds the level-select entries from `levels`, skipping excluded scenes. Each
# entry is { "index": position in `levels`, "label": "N. Title" }.
func _level_entries() -> Array:
	var entries: Array = []
	var number := 0  # 1-based position in the playable list (excluded levels skipped)
	for i in range(levels.size()):
		var scene := levels[i]
		if scene == null or _is_excluded(scene):
			continue
		number += 1
		entries.append({ "index": i, "label": "%d. %s" % [number, _level_title(scene)] })
	return entries

func _is_excluded(scene: PackedScene) -> bool:
	for ex in exclude_from_level_select:
		if ex != null and ex.resource_path == scene.resource_path:
			return true
	return false

# The label for a level: its StageTitle node's text if it has one, else the
# scene's file name. Instantiates the scene detached (so no _ready/_enter_tree
# runs) purely to read the title, then frees it.
func _level_title(scene: PackedScene) -> String:
	var inst := scene.instantiate()
	var title := ""
	var node := _find_title_node(inst)
	if node:
		title = node.stage_title
	inst.free()
	if title.strip_edges() == "":
		title = scene.resource_path.get_file().get_basename()
	return title

func _find_title_node(node: Node) -> SingleInstanceTitleNode:
	if node is SingleInstanceTitleNode:
		return node
	for child in node.get_children():
		var found := _find_title_node(child)
		if found:
			return found
	return null

func _on_start_pressed() -> void:
	_single_level = false
	_hide_menu()
	_load_level(0)

func _on_select_pressed() -> void:
	_level_select.populate(_level_entries())
	_main_menu.hide()
	_level_select.show()

func _on_level_pressed(index: int) -> void:
	_single_level = true
	_hide_menu()
	_load_level(index)

func _hide_menu() -> void:
	_main_menu.hide()
	_level_select.hide()

func _show_main_menu() -> void:
	# Also used to come back after finishing: drop any running level and reset the
	# swap guard so the next Start/level tap loads cleanly.
	if _current_level:
		_current_level.free()
		_current_level = null
	_swapping = false
	# The on-screen touch controls belong to gameplay; hide them behind the menu.
	$CanvasLayer/HBoxContainer.hide()
	$CanvasLayer/HBoxContainer2.hide()
	$CanvasLayer/HBoxContainer3.hide()
	
	_lava_material.set_shader_parameter("sky_ends", 600)
	_level_select.hide()
	_main_menu.show()
	_show_background()

# The optional decorative level behind the menus. Its player is frozen
# (ignore_input) and no gameplay signals are connected, so it just animates and
# never reacts to the user. No-op if no background_scene is assigned or one is
# already running (so switching main <-> level-select doesn't reload it).
func _show_background() -> void:
	if background_scene == null or _background_level != null:
		return
	
	_background_level = background_scene.instantiate()
	if OS.has_feature("web"):
		WebParticles.convert(_background_level)
	add_child(_background_level)
	var player = _background_level.find_child("player", true, false)
	if player:
		player.ignore_input = true

func _free_background() -> void:
	if _background_level:
		_background_level.free()
		_background_level = null

func _menu_visible() -> bool:
	return _main_menu.visible or _level_select.visible

# The level list lives inside a ScrollContainer in the LevelSelect scene. Found
# and cached lazily so we don't hard-code the scene's internal node path.
func _level_scroll() -> ScrollContainer:
	if _cached_level_scroll == null or not is_instance_valid(_cached_level_scroll):
		for n in _level_select.find_children("*", "ScrollContainer", true, false):
			_cached_level_scroll = n
			break
	return _cached_level_scroll

# The visible menu button under `pos`, or null. Buttons in the level list are
# clipped to their ScrollContainer's viewport: one scrolled out of view still
# has a global rect (which can sit under another button), so only its visible
# part counts.
func _menu_button_at(pos: Vector2) -> Button:
	var scroll := _level_scroll()
	for btn in $MenuLayer.find_children("*", "Button", true, false):
		if not btn.is_visible_in_tree() or btn.disabled:
			continue
		var rect: Rect2 = btn.get_global_rect()
		if scroll and scroll.is_ancestor_of(btn):
			rect = rect.intersection(scroll.get_global_rect())
		if rect.has_point(pos):
			return btn as Button
	return null

# Emulation is off, so menu Control buttons don't get touch. We hit-test them
# here: press remembers the button under the finger, release fires it only if
# the finger is still on the same button, and a drag scrolls the level list
# (and cancels the pending tap once it has moved).
func _handle_menu_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_menu_touch_index = event.index
			_menu_touch_start = event.position
			_menu_touch_button = _menu_button_at(event.position)
		elif event.index == _menu_touch_index:
			var btn := _menu_button_at(event.position)
			if btn != null and btn == _menu_touch_button:
				btn.pressed.emit()
			_menu_touch_index = null
			_menu_touch_button = null
	elif event is InputEventScreenDrag and event.index == _menu_touch_index:
		if _level_select.visible:
			var scroll := _level_scroll()
			if scroll:
				scroll.scroll_vertical -= int(event.relative.y)
		# Once the finger has moved, treat it as a scroll, not a tap.
		if event.position.distance_to(_menu_touch_start) > 24.0:
			_menu_touch_button = null

func _button_action_at(pos: Vector2) -> String:
	for btn in _touch_buttons:
		# Skip hidden buttons: while the D-pad is unrevealed (e.g. on desktop) its
		# containers are hidden and never laid out, so their buttons share a stale
		# overlapping rect. Hit-testing those made clicks land on whichever button
		# comes first in iteration (left/up shadowing right), so only match when
		# the button is actually visible and laid out on screen.
		if btn.is_visible_in_tree() and btn.get_global_rect().has_point(pos):
			return _touch_buttons[btn]
	return ""

func _pointer_press(id, action: String) -> void:
	# If this pointer slid from one button onto another, drop the old one first.
	if _active_pointers.has(id) and _active_pointers[id] != action:
		_pointer_release(id)
	if not _active_pointers.has(id):
		_active_pointers[id] = action
		Input.action_press(action)
		# Reflect the press visually on the Button.
		for btn in _touch_buttons:
			if _touch_buttons[btn] == action:
				btn.button_pressed = true

func _pointer_release(id) -> void:
	if not _active_pointers.has(id):
		return
	var action: String = _active_pointers[id]
	_active_pointers.erase(id)
	# Only release the action if no other finger is still holding the button.
	if not _active_pointers.values().has(action):
		Input.action_release(action)
		for btn in _touch_buttons:
			if _touch_buttons[btn] == action:
				btn.button_pressed = false

func _input(event: InputEvent) -> void:
	# ESC (ui_cancel): return to the main menu from a level or the level list.
	if event.is_action_pressed("ui_cancel"):
		if (_current_level and not _menu_visible()) or _level_select.visible:
			_show_main_menu()
			get_viewport().set_input_as_handled()
		return

	# While a menu is up, drive its buttons from touch ourselves (emulation is
	# off, so the menu's Control buttons don't receive touch on their own) and
	# don't reveal or run the on-screen game controls. On desktop the buttons
	# still get real mouse clicks natively, so this is only the touch path.
	if _menu_visible():
		_handle_menu_touch(event)
		return

	if _touch_buttons.is_empty():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			# First touch on this device: reveal the controls. The buttons were
			# unlaid-out while hidden, so this tap only shows them; play starts
			# from the next tap once they have a real on-screen rect.
			if not $CanvasLayer/HBoxContainer.visible:
				$CanvasLayer/HBoxContainer.show()
				$CanvasLayer/HBoxContainer2.show()
				$CanvasLayer/HBoxContainer3.show()
				return
			# The on-screen menu button mimics ESC: back to the main menu.
			if $CanvasLayer/HBoxContainer3/menu.get_global_rect().has_point(event.position):
				_show_main_menu()
				return
			var action := _button_action_at(event.position)
			if action != "":
				_pointer_press(event.index, action)
		else:
			_pointer_release(event.index)
	elif event is InputEventScreenDrag:
		# A finger may slide off/onto a button while held.
		var action := _button_action_at(event.position)
		if action != "":
			_pointer_press(event.index, action)
		else:
			_pointer_release(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Desktop testing path (single pointer).
		if event.pressed:
			var action := _button_action_at(event.position)
			if action != "":
				_pointer_press("mouse", action)
		else:
			_pointer_release("mouse")

func _setup_lava_background() -> void:
	var layer := CanvasLayer.new()
	#layer.layer = -10
	layer.layer = 10
	add_child(layer)
	_lava_rect = ColorRect.new()
	_lava_rect.color = Color.TRANSPARENT
	# The rect fills the screen on a top CanvasLayer; without this it would
	# swallow every mouse click before the on-screen buttons could get it.
	_lava_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lava_material = ShaderMaterial.new()
	_lava_material.shader = LAVA_SHADER
	_lava_rect.material = _lava_material
	layer.add_child(_lava_rect)

func _process(_delta: float) -> void:
	var vp_size := get_viewport_rect().size
	_lava_rect.size = vp_size
	var camera := get_viewport().get_camera_2d()
	if camera:
		# Use the smoothing-aware screen center, not global_position. With
		# position_smoothing_enabled the frame is rendered from the smoothed
		# camera transform, but global_position is the (instant) target — feeding
		# that here makes the lava lead the world while the camera catches up.
		# get_screen_center_position() reflects what is actually on screen
		# (smoothing, drag, limits), so the lava tracks the world exactly.
		var cam_center := camera.get_screen_center_position()
		_lava_material.set_shader_parameter("camera_y", cam_center.y)
		_lava_material.set_shader_parameter("camera_x", cam_center.x)
		# The camera zoom shrinks the visible world span to viewport_size / zoom.
		# The shader maps UVs to world space using viewport_size, so feed it the
		# zoom-corrected span; otherwise the lava drifts when zoom != 1.
		vp_size = vp_size / camera.zoom
	_lava_material.set_shader_parameter("viewport_size", vp_size)

func next_level() -> void:
	# Guard first: level_complete can fire more than once before the swap runs.
	if _swapping:
		return
	_swapping = true
	# Single-level mode, or the end of a full playthrough, returns to the menu
	# instead of advancing. Deferred so we don't free the level while its own
	# `level_complete` signal is still being emitted.
	if _single_level or current_level_index + 1 >= levels.size():
		_show_main_menu.call_deferred()
		return
	current_level_index += 1
	_do_swap.call_deferred()

func explode():
	# A single death usually emits `died` more than once (the fall check AND an
	# enemy/lava Area2D overlapping the same body). Only the first one may start
	# the death sequence; the rest are ignored until the new level is loaded.
	if _swapping:
		return
	_swapping = true
	var player = _current_level.find_child("player", true, false)
	if player:
		player.visible = false
		player.set_physics_process(false)
		# Stop enemy/lava Area2Ds from still detecting the dead body. Deferred
		# because we're inside a physics callback (the `died` signal). The
		# _swapping guard above already makes extra `died` emits harmless; this
		# just prevents them from firing in the first place.
		player.set_deferred("collision_layer", 0)
		player.set_deferred("collision_mask", 0)
		var explode = EXPLODE.instantiate()
		explode.position = player.position
		# Deferred so the swap runs at a safe idle moment, not inside the
		# explosion's finished callback.
		explode.explosion_finished.connect(_do_swap, CONNECT_DEFERRED)
		add_child(explode)
	else:
		_do_swap.call_deferred()

func reload_level() -> void:
	if _swapping:
		return
	_swapping = true
	_do_swap.call_deferred()

func _load_level(index: int) -> void:
	# Entry point for the initial load from _ready().
	if _swapping:
		return
	_swapping = true
	current_level_index = index
	_do_swap.call_deferred()

func _do_swap() -> void:
	# A real level is starting; drop the decorative background so it isn't running
	# (and its camera fighting the real player's) behind actual gameplay.
	_free_background()
	if _current_level:
		_current_level.free()  # immediate, so the old level can't overlap the new one for a frame
		_current_level = null
	if levels.is_empty():
		push_warning("World: no levels assigned")
		_swapping = false
		return
	_current_level = levels[current_level_index].instantiate()
	# Some mobile browsers can't run GPUParticles2D (no compute support), so swap
	# them for CPUParticles2D before the level is shown. Done while detached from
	# the tree so the GPU nodes never get a chance to render a broken frame.
	if OS.has_feature("web"):
		WebParticles.convert(_current_level)
	add_child(_current_level)

	var player = _current_level.find_child("player", true, false)
	if player:
		player.died.connect(explode)
		player.level_complete.connect(next_level)
	_swapping = false
	_lava_material.set_shader_parameter("sky_ends", 9900.0)
