# アイテム図鑑（`items_henrik/`）

すぐに使える**完成品のアイテム**の一覧です。名前をクリックすると、
詳しい使い方のページが開きます。

置き方はどれも同じで、FileSystem から `.tscn` をステージの
**キャンバスにドラッグ＆ドロップ**するだけです。
詳しくは [チュートリアル 5章](../index.md#5-アイテムやタイルで組み立てる) を見てください。

| 見た目 | 名前 | どんなアイテム？ |
| --- | --- | --- |
| <img src="../images/items/spring.svg" width="48"> | [ばね（spring）](spring.md) | 乗ると高くジャンプする足場。 |
| <img src="../images/items/cannon.svg" width="48"> | [大砲（cannon）](cannon.md) | プレイヤーを向いた方向へ発射する。 |
| <img src="../images/items/bee.svg" width="48"> | [ハチ（bee）](bee.md) | プレイヤーを追いかける動く敵。 |
| <img src="../images/items/fireball.svg" width="48"> | [火の玉（fireball）](fireball.md) | 上下にはねる危険なタマ。 |
| <img src="../images/items/garigari.svg" width="48"> | [ノコギリ（garigari）](garigari.md) | 近づくと速く回る危険なノコギリ。 |
| <img src="../images/items/key.svg" width="48"> | [カギ（key）](key.md) | 集めるしかけに使えるアイテム。 |
| <img src="../images/items/platform.svg" width="48"> | [足場（platform）](platform.md) | まっすぐ立つ足場（スクリプトなし）。 |
| <img src="../images/items/gravity_flip.png" width="48"> | [重力逆転（gravity_flip）](gravity_flip.md) | 触ると重力が上下ぎゃくになる。 |
| <img src="../images/items/timeout.svg" width="48"> | [時間制限（timeout）](timeout.md) | 制限時間。0 になるとミス。 |
| 🏷️ | [ステージ名（stage_title）](stage_title.md) | ステージの名前を表示する。 |

---

> 💡 **アイテムの共通ルール**：どのアイテムも独立した部品で、
> `player.gd` や `world.gd` を**書き変えません**。プレイヤーの
> 公開変数（`SPEED` / `JUMP_VELOCITY` / `GRAVITY_SCALE` / `scale`）と
> シグナル（`died` / `level_complete`）だけを通してはたらきます。
> 自作アイテムの作り方は [チュートリアル 6章](../index.md#6応用簡単なアイテムを自作する)、
> くわしい手順は [アイテムを一から自作する](../making-items.md) へ。

[← チュートリアルへ戻る](../index.md)
