# 基礎セミナーランド / Foundation Seminar Land

A tiny, beginner-friendly 2D platformer made with **Godot**, used in a
university *foundation seminar* (基礎セミナー). It is designed so that a complete
beginner can build their own stage (ステージ) and, if they like, write their first
few lines of code — **without ever editing the engine code** (`world.gd` /
`player.gd`).

**Godot** で作った、小さな初心者向け 2D プラットフォーマーです。大学の
**基礎セミナー**で使っています。プログラミングが初めての人でも、自分の
**ステージ**を作り、さらにやりたければ数行のコードが書けるように作られています。
エンジン側のコード（`world.gd` / `player.gd`）は**さわらなくて大丈夫**です。

> ✅ **Tested with Godot 4.6** / **動作確認バージョン：Godot 4.6**

---

## 📖 Tutorial / チュートリアル

日本語のステップ・バイ・ステップのチュートリアルはこちら（超入門）：

**→ [`docs/` チュートリアル](docs/index.md)**

（GitHub Pages で公開する場合は `Settings → Pages → Source: main / docs`。
Once published, it is served from `https://<user>.github.io/<repo>/`.）

---

## 🚀 Quick start / クイックスタート

1. **Install Godot** — download the editor from <https://godotengine.org/download>
   (see the tested version above). （Godot のエディタをダウンロードします。）
2. **Open the project** — start Godot, click *Import*, and choose the
   `project.godot` file in this folder.
   （Godot を起動し *Import* からこのフォルダの `project.godot` を開きます。）
3. **Play** — press **F5** (or the ▶ button). Use ← → to move and **Space** to jump.
   （**F5** で実行。← → で移動、**スペース**でジャンプ。）
4. **Make your own stage** — copy `level_empty.tscn`, then register it in the
   `levels` list on `world.tscn`. See the tutorial for details.
   （`level_empty.tscn` をコピーして自分のステージを作り、`world.tscn` の
   `levels` に登録します。詳しくはチュートリアルへ。）

---

## 🗺️ What each folder is / フォルダ地図

| Folder / ファイル | What it is / 中身 |
| --- | --- |
| `world.gd` / `world.tscn` | The game shell: menus, level list, buttons. ゲーム本体（メニュー・ステージ一覧）。**Usually you don't edit this.** |
| `player/` | The player character (`player.gd`, sprites). プレイヤー。 |
| `goal/` | The goal flag (`flag.tscn`). ゴールの旗。 |
| `level_empty.tscn` | **The stage template** — already has a player + flag. コピー元のステージ。 |
| `level_cannon.tscn`, `level_title.tscn`, `level_end.tscn` | Demo stages. お手本のステージ。 |
| `items/` | **Beginner coding examples** — simple add-in items. かんたんな自作アイテムの例。 |
| `items_henrik/` | Ready-made items (spring, cannon, bee, key, saw, …). 完成品のアイテム集。 |
| `tilemaps_henrik/`, `tilemap_imgs/` | Tilesets for building ground (incl. lava). 地面を描くタイルセット。 |
| `menus/`, `global/`, `other/`, `goal/` | Supporting scenes & scripts. 補助的な部品。 |

---

## 🧩 How items work (the "add-in" idea) / アイテムの仕組み

Every item is a **self-contained `Area2D`** that reacts to the player in
`_on_body_entered(body)`. It touches the player *only* through the player's
exported variables and signals — so items never edit `player.gd` or `world.gd`:

すべてのアイテムは独立した **`Area2D`** で、`_on_body_entered(body)` の中で
プレイヤーに反応します。プレイヤーの**公開変数**と**シグナル**だけを通して
触れるので、`player.gd` や `world.gd` を書き換える必要はありません。

- Exported variables / 公開変数: `SPEED`, `JUMP_VELOCITY`, `GRAVITY_SCALE`, `scale`
- Signals / シグナル: `died`, `level_complete`

```gdscript
extends Area2D
@export var SPEED_BONUS = 150.0

func _on_body_entered(body: Node2D) -> void:
    body.SPEED += SPEED_BONUS   # make the player faster / 速くする
    queue_free()                # one-time use / 使い切り
```

See `items/item_speed.gd` and `items/gravity_flip.gd` for the fully-commented
examples. （くわしい例は `items/` の中にあります。）

---

## 📝 License / ライセンス

Copyright © 2026 Henrik Skibbe (Matsuyama University / 松山大学).

Except where noted below, this project — the game code, art, tilemaps and
documentation — is licensed under the
**[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)**
(**CC BY-NC-SA 4.0**) license. See the [`LICENSE`](LICENSE) file for the full text.

In short — あなたは次のことができます：

- ✅ **Share / 共有**：コピー・再配布できます。
- ✅ **Adapt / 改変**：改造・翻案できます（授業や学習にどうぞ）。

… under these terms / ただし次の条件を守ってください：

- 🏷️ **Attribution / 表示**：作者（上記）とライセンスを明記してください。
- 🚫 **NonCommercial / 非営利**：商用利用はできません。
- 🔁 **ShareAlike / 継承**：改変して配布する場合は、同じ CC BY-NC-SA 4.0 で
  公開してください。

> ⚠️ This is a *source-available*, **non-open-source** license: it deliberately
> forbids commercial use, so it is not an OSI "open source" license.

**Third-party components / 同梱の第三者コンポーネント（上記の対象外）:**

- Font: **Noto Sans JP** — SIL Open Font License (see [`OFL.txt`](OFL.txt)).
  Remains under the OFL; not relicensed by the above.
- The **Godot Engine** itself is not included here and is under its own MIT license.
