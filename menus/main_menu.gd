extends Control
# メインメニュー / The main menu.
# タイトルと2つのボタン（スタート／ステージ選択）だけ。押されたら world に合図を送ります。
# Just a title and two buttons (Start / Select Level); it forwards presses to world as signals.
# Main menu: a title and two buttons. Layout lives in main_menu.tscn so it can be
# restyled in the editor; this script only forwards the button presses as signals
# that World listens to.
signal start_pressed
signal select_pressed

func _ready() -> void:
	# Show the project's display name as the title (set in Project Settings).
	$Content/Box/Title.text = ProjectSettings.get_setting("application/config/name", "GAME")
	$Content/Box/Start.pressed.connect(func(): start_pressed.emit())
	$Content/Box/Select.pressed.connect(func(): select_pressed.emit())
