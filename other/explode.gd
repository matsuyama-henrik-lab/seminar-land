extends CPUParticles2D
# 爆発エフェクト / The explosion effect.
# プレイヤーが死んだ場所に出て、パーティクルが終わると自分で消えます。
# Spawns where the player died; removes itself once its particles finish.
@onready var world: Node2D = $"."

signal explosion_finished   # 爆発が終わった合図（world がステージを作り直す）/ told to world → it reloads the level

func _ready() -> void:
	emitting = true   # 出現と同時にパーティクルを噴き出す / start emitting immediately


# パーティクルが出終わったら合図して消える / when particles finish: signal, then remove self
func _on_finished() -> void:
	explosion_finished.emit()
	queue_free()
