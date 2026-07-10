extends Node
# カギのカウンター / The key counter.
# 集めた数「◯/◯」を画面に表示し、全部そろったらゴール（旗）を出現させます。
# Shows "found/total" on screen and reveals the goal flag once every key is collected.
@onready var label: Label = $CanvasLayer/HBoxContainer/Label

const key_group = "keys"
var all_keys : int = 0       # ステージ内のカギの総数 / total keys in the level
var keys_found : int = 0     # 集めた数 / how many collected so far
var all_exits: Array[Node]   # ゴール（旗）の一覧 / the goal flags to unlock


func _ready() -> void:
	await get_tree().process_frame   # 全てのカギ・旗が用意されるまで1フレーム待つ / wait one frame so all keys/flags exist

	# 最初はゴールを隠して無効化 / start with the goals hidden and disabled
	all_exits = get_tree().get_nodes_in_group("flag")
	for exit in all_exits:
		exit.visible = false
		exit.process_mode = Node.PROCESS_MODE_DISABLED

	# 各カギの「取られた」合図を found() につなぐ / connect each key's "collected" signal to found()
	var keys = get_tree().get_nodes_in_group(key_group)
	for key in keys:
		key.key_found.connect(found)

	all_keys = len(keys)
	keys_found = 0

	label.text = str(keys_found)+ "/"+str(all_keys)


# カギが1つ取られるたびに呼ばれる / called each time a key is collected
func found():
	keys_found += 1
	label.text = str(keys_found)+ "/"+str(all_keys)

	# 全部そろったらゴールを出す / all collected → reveal the goals
	if keys_found == all_keys:
		for exit in all_exits:
			exit.visible = true
			exit.process_mode = Node.PROCESS_MODE_INHERIT
