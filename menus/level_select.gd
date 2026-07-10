extends Control
# ステージ選択メニュー / The level-select menu.
# world から渡されたステージ一覧をボタンとして並べ、選ばれた番号を合図で返します。
# Lists the stages world hands it as buttons and reports the chosen one back as a signal.
# Level-selection menu. The list of levels is filled at runtime by World via
# populate(), because levels are configured on the World node and can grow.
# One level_button.tscn is instanced per entry. Layout/styling live in the scenes.
signal level_chosen(index: int)
signal back_pressed
# Emitted by the optional "順番にプレイ" (play-all) button, shown only when the
# menu is populated with show_play_all = true (the tutorial list). World then
# runs the whole source array in sequence, like the Start button.
signal play_all_pressed

const LEVEL_BUTTON := preload("res://menus/level_button.tscn")

@onready var _list: VBoxContainer = $Content/Box/Scroll/List

func _ready() -> void:
	$Content/Box/Back.pressed.connect(func(): back_pressed.emit())
	$Content/Box/PlayAll.pressed.connect(func(): play_all_pressed.emit())

# entries: Array of dictionaries { "index": int, "label": String }.
# "index" is the position in the source level array; "label" is the button text.
# `title` overrides the heading (e.g. "チュートリアル") so the same scene can serve
# both the stage list and the tutorial list; "" keeps the scene's own title.
# `show_play_all` reveals the "順番にプレイ" button (tutorial list only).
func populate(entries: Array, title: String = "", show_play_all: bool = false) -> void:
	if title != "":
		$Content/Box/Title.text = title
	$Content/Box/PlayAll.visible = show_play_all
	for child in _list.get_children():
		child.queue_free()
	for entry in entries:
		var btn: Button = LEVEL_BUTTON.instantiate()
		btn.text = entry["label"]
		btn.pressed.connect(_on_level_button.bind(entry["index"]))
		_list.add_child(btn)

func _on_level_button(index: int) -> void:
	level_chosen.emit(index)
