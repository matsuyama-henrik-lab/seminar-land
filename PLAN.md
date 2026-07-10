# Public Repo + Tutorial — Work Plan / 作業計画

Plan for turning this 基礎セミナー game into a **public, beginner-friendly GitHub repo**
with bilingual (EN + 日本語) code comments and a tutorial homepage.

このゲーム（基礎セミナー用）を、初心者向けの **公開 GitHub リポジトリ** にするための計画です。
コードには英語＋日本語の短いコメントを付け、チュートリアルのホームページを用意します。

---

## Scope / 対象

**Ships (公開する):**
- Core game: `world.gd` / `world.tscn`, `player/`, `goal/`, `menus/`, `global/`, `other/`
- `items_henrik/` — ready-made items (spring, cannon, bee, key, …)
- `tilemaps_henrik/` — tilesets incl. lava
- `items/` — the simple beginner **coding examples** (speed item, gravity flip)
- `level_empty.tscn` — the ステージ template (already contains a player + flag)
- A few demo ステージ (`level_cannon`, `level_title`, `level_end`)

**Excluded (公開しない — student content):**
- `items_students/`
- `player_students/`
- `Levels/`
- `export_presets.cfg` (may hold keystore credentials — keep in `.gitignore`)

---

## Architecture note / 設計メモ

Every item is an **add-in**: a self-contained `Area2D` that reacts to the player in
`_on_body_entered(body)`, touching the player only through its **exported variables**
(`SPEED`, `JUMP_VELOCITY`, `GRAVITY_SCALE`, `scale`) and **signals** (`died`,
`level_complete`). Items never edit `world.gd` or `player.gd`.

すべてのアイテムは「アドイン」方式。`world.gd` や `player.gd` を書き換えずに、
プレイヤーの公開変数とシグナルだけを通して動きます。

---

## Phase 1 — Bilingual code comments / コメント付け

Add **brief** EN + 日本語 comments to all non-student `.gd` (21) and `.gdshader` (6).
Match the existing `player.gd` style: short English line + short Japanese line.

- `items/` examples get slightly **fuller, step-by-step** comments (they are the teaching
  material) and mention easy near-zero-code tweaks: change `SPEED`, `JUMP_VELOCITY`,
  `GRAVITY_SCALE`, or `scale` (mini / giant).
- `player.gd`: **keep** `_physics_process__` (the Q1–Q4 quiz version) with a comment saying
  it's an optional exercise not run by the game; **remove** the unused `_physics_process_OLD`.
- ⚠️ Godot rewrites `.tscn` on save and strips comments — **do not** put comments in scenes.
  Document scenes in the tutorial instead.

## Phase 2 — Clean public copy / 公開用コピー

Copy the project to a clean folder, delete the 3 student dirs, and fix `world.tscn`'s
`levels` array (it currently references student levels) to ship only the demo ステージ.
Verify it opens and runs in Godot 4.6.

## Phase 3 — Tutorial homepage / チュートリアル

- Root `README.md`: bilingual (EN + 日本語) quick-start, links into `docs/`.
- `docs/` GitHub Pages tutorial: **Japanese only**, for super beginners. Teaches:
  install Godot 4.6 → copy `level_empty.tscn` to make your own ステージ →
  build it with `items_henrik/` + `tilemaps_henrik/` assets →
  (optional) write a simple add-in item like the ones in `items/` →
  register the ステージ in the level list. Include a "what each folder is" map.

---

*ステージ = the word we use for "level" in the tutorial.*
