extends TileMapLayer
# 溶岩（ため）のタイルマップ / The lava tilemap.
# 溶岩タイルは触れると死ぬ床です。置いた各タイルに自動で当たり判定を付けます。
# Lava tiles are deadly floor; this adds a collision area to each tile you paint.

func _ready() -> void:
	# 描かれた溶岩タイル1つ1つに当たり判定エリアを作る / build a hit area for every painted tile
	for cell in get_used_cells():
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 6  # プレイヤーの層に合わせる / matches player collision_layer (layers 2 and 3)

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(tile_set.tile_size)   # タイルと同じ大きさ / same size as one tile
		shape.shape = rect

		area.add_child(shape)
		add_child(area)
		area.position = map_to_local(cell)
		area.body_entered.connect(_on_body_entered)

# プレイヤーが溶岩に触れた → 死ぬ / player touched lava → die
func _on_body_entered(body: Node2D) -> void:
	if body.has_signal("died"):
		body.died.emit()
