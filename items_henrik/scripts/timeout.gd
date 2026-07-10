extends Node
class_name SingleInstanceTimerNode
# 制限時間タイマー / A countdown time limit.
# 残り秒数を画面に表示し、0になるとプレイヤーが死にます（ステージに緊張感を出す追加要素）。
# Shows the remaining seconds on screen; when it hits 0 the player dies.
# 1つのステージに1個だけ（重複は自動で消えます）。
# Only one per stage — a duplicate removes itself automatically.

@export var time_limit: float = 30.0   # 制限時間（秒）/ time limit in seconds
@onready var timer: Timer = $Timer
@onready var label: Label = $CanvasLayer/Label



func _enter_tree() -> void:
	# Find all active nodes of this specific class type
	var duplicates: Array[Node] = get_tree().get_nodes_in_group(&"single_instance_timer_nodes")
	
	if duplicates.size() > 0:
		push_warning("Only one instance of %s is allowed! Removing duplicate." % name)
		queue_free() # Safely remove the duplicate from memory
	else:
		# Register this first valid instance into the tracking group
		add_to_group(&"single_instance_timer_nodes")


func _ready() -> void:
	timer.wait_time = time_limit
	timer.start()

func _process(_delta: float) -> void:
	label.text = str(int(ceil(timer.time_left)))   # 残り秒数を更新 / update the remaining seconds

# 時間切れ → 全プレイヤーに「死んだ」合図を送る / time is up → tell every player it died
func _on_timer_timeout() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		player.died.emit()
