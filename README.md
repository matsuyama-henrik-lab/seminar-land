# Seminar Land

A tiny, beginner-friendly 2D platformer made with **Godot** (a free game-making
tool), used in a university *foundation seminar* (基礎セミナー). It is designed so
that a complete beginner can build their own stage (ステージ) just by placing
ready-made parts, **without writing any difficult code**. With a little code they
can also make their own items, using the included examples; and since Godot's
language is a lot like Python, it is a gentle first step into programming. Anyone
comfortable with code can extend the game almost without limit.

**Godot**（ゲームを作る無料のソフト）で作った、小さな初心者向け 2D
プラットフォーマーです。大学の**基礎セミナー**で使っています。プログラミングが
初めての人でも、**難しいコードを書かなくても**、用意された部品を並べるだけで
自分の**ステージ**が作れます。さらに、少しコードを書けば、見本を参考に
**自分だけの部品（アイテム）**を作ることもできます。Godot の言語は Python に
よく似ているので、プログラミングに挑戦したい人にもぴったりです。自信がある人は、
ゲームを好きなだけ拡張していけます。

> ✅ **Tested with Godot 4.6** / **動作確認バージョン：Godot 4.6**

---

## 📖 Tutorial / チュートリアル

日本語のステップ・バイ・ステップのチュートリアルはこちら（超入門）：

**→ [`docs/` チュートリアル](docs/index.md)**

> **Note:** This tutorial is a *complementary* resource, not an exhaustive,
> end-to-end guide. It grew out of a real 基礎セミナー (four 90-minute units) where
> students built a Godot stage, made their own items, and drew the item graphics
> in Microsoft Paint (drawing is not covered here). Some steps may need a
> teacher's guidance or the help of an AI assistant, and it is meant to let
> students keep building after the class ends.
>
> （このチュートリアルは、すべてを網羅する完全な手引きではなく、授業の**補助教材**
> です。実際の**基礎セミナー**（90分×4回）で Godot のステージを作り、アイテムを自作
> し、その絵を Microsoft ペイントで描いた経験をもとにしています（絵の描き方は
> 扱っていません）。場面によっては先生や AI（コーディング支援）の助けが必要です。
> 授業のあとも自分で作り続けられるように用意しています。）

（GitHub Pages で公開する場合は `Settings → Pages → Source: main / docs`。
Once published, it is served from `https://<user>.github.io/<repo>/`.）

---

## 🚀 Quick start / クイックスタート

1. **Install Godot**: download the editor from <https://godotengine.org/download>
   (see the tested version above). （Godot のエディタをダウンロードします。）
2. **Open the project**: start Godot, click *Import*, and choose the
   `project.godot` file in this folder.
   （Godot を起動し *Import* からこのフォルダの `project.godot` を開きます。）
3. **Play**: press **F5** (or the ▶ button). Use ← → to move and **Space** to jump.
   （**F5** で実行。← → で移動、**スペース**でジャンプ。）
4. **Make your own stage**: copy `level_empty.tscn`, then register it in the
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
| `level_empty.tscn` | **The stage template**: already has a player + flag. コピー元のステージ。 |
| `level_cannon.tscn`, `level_title.tscn`, `level_end.tscn` | Demo stages. お手本のステージ。 |
| `items/` | **Beginner coding examples**: simple add-in items. かんたんな自作アイテムの例。 |
| `items_henrik/` | Ready-made items (spring, cannon, bee, key, saw, …). 完成品のアイテム集。 |
| `tilemaps_henrik/`, `tilemap_imgs/` | Tilesets for building ground (incl. lava). 地面を描くタイルセット。 |
| `menus/`, `global/`, `other/`, `goal/` | Supporting scenes & scripts. 補助的な部品。 |

---

## 🧩 How items work (the "add-in" idea) / アイテムの仕組み

Every item is a **self-contained `Area2D`** that reacts to the player in
`_on_body_entered(body)`. It touches the player *only* through the player's
exported variables and signals, so items never edit `player.gd` or `world.gd`:

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

## 🤖 AI assistance / AI（コーディング支援）について

The game, including its design, mechanics and art, is by the author above, who
wrote the gameplay code (including the ready-made items such as the spring,
cannon, bee, saw, key and gravity-flip) and reviewed and tested all of the code.
Part of the code was written with the help of an AI coding assistant
(**Anthropic's Claude**, via *Claude Code*). The author provided the structure
and directed the work, and the assistant wrote much of the detailed
implementation inside `world.gd` (around that structure), the on-screen touch
keyboard (`items_henrik/scripts/touch_key_button.gd`), and much of the bilingual
in-code documentation.

このゲームの設計・仕組み・アートは、上記の作者によるものです。作者自身がゲームの
コード（バネ・大砲・ハチ・のこぎり・カギ・重力反転などの完成品アイテムを含む）を
書き、すべてのコードをレビューして動作を確認しています。コードの一部は、AIコー
ディング支援ツール（**Anthropic の Claude**／*Claude Code*）の助けを借りて書きました。
作者が骨組みを用意して方針を決め、`world.gd` の細かい実装の多く、画面上のタッチ
キーボード（`items_henrik/scripts/touch_key_button.gd`）、日英併記のコード内ドキュ
メントの多くを、このツールが担当しました。

> Knowing how to code still matters. It is what lets you design the structure,
> direct an assistant, and judge and fix what it produces. AI is a tool, not a
> substitute for understanding.
> （コードが書ける・読めることは今も大切です。骨組みを設計し、AIに指示を出し、
> 出てきたコードを見極めて直せるのは、その力があるからこそです。AIは道具であって、
> 「理解していること」の代わりにはなりません。）

---

## 📝 License / ライセンス

Copyright © 2026 Henrik Skibbe (Matsuyama University / 松山大学).

Except where noted below, this project (the game code, art, tilemaps and
documentation) is licensed under the
**[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)**
(**CC BY-NC-SA 4.0**) license. See the [`LICENSE`](LICENSE) file for the full text.

In short, あなたは次のことができます：

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

- Font: **Noto Sans JP** (SIL Open Font License, see [`OFL.txt`](OFL.txt)).
  Remains under the OFL; not relicensed by the above.
- The **Godot Engine** itself is not included here and is under its own MIT license.
