# docs/images — 画像の置き場所

チュートリアルやアイテムページで使う画像は、このフォルダに入れます。
（GitHub Pages は `docs/` の中のファイルだけを配信するので、画像も必ず
`docs/images/` に置いてください。`items_henrik/imgs/` など外のフォルダを
参照すると、公開サイトでは表示されません。）

## フォルダ分け

- `docs/images/` … チュートリアル本文（`index.md`）用のスクリーンショット。
- `docs/images/items/` … アイテムの見た目アイコン・使用例のスクリーンショット。

## 画像の入れ方（Markdown）

```markdown
![せつめい](images/foo.png)          <!-- docs/index.md から -->
![せつめい](../images/items/foo.png) <!-- docs/items/*.md から -->
```

大きさを変えたいときは HTML の `<img>` を使います。

```html
<img src="../images/items/spring.svg" width="96">
```

## スクリーンショットの命名（おすすめ）

各アイテムページには、次の名前のスクリーンショットを追加できる
コメント欄をあらかじめ用意してあります（コメントを外すと表示されます）。

- `items/spring_screenshot.png`, `items/cannon_screenshot.png` … など
  （`items/<アイテム名>_screenshot.png`）

PNG または JPG がおすすめです。横幅 800〜1200px くらいにしておくと、
サイトでもきれいに表示され、ファイルサイズも重くなりません。
