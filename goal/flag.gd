extends Area2D
# ゴールの旗 / The goal flag.
# プレイヤーが触れると「ステージクリア」の合図を出し、次のステージへ進みます。
# When the player touches it, it signals "level complete" and the game advances.
# ステージには必ず1つ置きましょう（level_empty には最初から入っています）。
# Put one in every stage (level_empty already has one).


# プレイヤーが旗に触れた → クリアの合図を送る / player reached the flag → emit level complete
func _on_body_entered(body: Node2D) -> void:
	# call_deferred: 触れた瞬間の物理処理中に安全に呼ぶため / defer so it fires at a safe moment
	body.level_complete.emit.call_deferred()
