extends CanvasLayer
class_name SingleInstanceTitleNode
# ステージ名の表示 / Shows the stage title.
# ステージ開始時にタイトルをふわっと出して、少ししたら消えます。
# Fades the stage title in at the start, holds, then fades it out.
# 1つのステージに1個だけ（同じものが2つあると重複を自動で消します）。
# Only one per stage — a duplicate removes itself automatically.

@onready var label: Label = $Control/Node2D/Label

@export var stage_title : String = "ステージ名"   # ここに表示したい名前を入れる / type the title to show here

var t : float = 0;        # 演出の進み具合 / animation progress
var state = 0             # 0:出る 1:待つ 2:消える / 0:appear 1:hold 2:disappear
var duration = 1

# 最初の1回だけ呼ばれる / called once when it enters the scene
func _ready() -> void:
	label.material.set_shader_parameter("t", 1)
	t = 1
	state = 0
	duration = 1
	label.text = stage_title

func _enter_tree() -> void:
	# Find all active nodes of this specific class type
	var duplicates: Array[Node] = get_tree().get_nodes_in_group(&"single_instance_title_nodes")
	
	if duplicates.size() > 0:
		push_warning("Only one instance of %s is allowed! Removing duplicate." % name)
		queue_free() # Safely remove the duplicate from memory
	else:
		# Register this first valid instance into the tracking group
		add_to_group(&"single_instance_title_nodes")
		

func _process(delta: float) -> void:
	
	if t>0:
			t -= delta/duration
			if state == 0:
				label.material.set_shader_parameter("t", clamp(t,0,1))
			elif state == 2:
				label.material.set_shader_parameter("t", clamp(1-t,0,1))
	else:	
		t = 1 
		state += 1
		duration = 1
		if state == 1:
			duration = 2
		
			
	
	if state >2:
		queue_free()
	
	
	
		
			
	
	
	
