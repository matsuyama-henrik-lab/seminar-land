# Web / PWA export: auto-update setup

This folder exists **only for documentation and version control**. Nothing here is
used by the game at runtime. It stores the source of a small JavaScript snippet
that makes the exported **Web build and installed PWA update themselves** to the
newest version.

## Why this folder exists

The snippet is applied through the Godot Web export preset's **"Head Include"**
field, which is stored in `export_presets.cfg`. That file is **gitignored** in
this project (it can hold machine-specific data such as Android keystore
credentials, and the Godot editor rewrites it). Because it is not in git, the
update snippet would be lost on a fresh clone or another machine.

So we keep the real source here, [`godot_pwa_update.js`](godot_pwa_update.js),
tracked in git, plus these instructions for re-applying it anywhere.

## What problem it solves

Godot's PWA service worker (`index.service.worker.js`) is **cache-first**: once a
browser or installed PWA has cached the game, it keeps serving that cached copy,
even after you deploy a newer build. Players would be stuck on the old version
until they manually clear the cache.

## How it works

Godot's own service worker already contains the update machinery. It listens for
messages from the page and, on the message `'update'`, does:

```js
self.skipWaiting()
    .then(() => self.clients.claim())
    .then(() => self.clients.matchAll())
    .then((all) => all.forEach((c) => c.navigate(c.url))); // reloads every tab
```

Godot also bumps the worker's `CACHE_VERSION` on every export, so the browser
detects a new worker automatically.

Our snippet just connects those two facts:

1. It hooks Godot's **existing** service-worker registration (it does **not**
   register its own; Godot does that during `startGame()`).
2. When it sees that a newer worker has finished downloading, it posts the
   `'update'` message, which triggers the skip-waiting + reload above.
3. It also calls `registration.update()` on an interval, because browsers
   otherwise only check for a new worker on a full page navigation, so a long
   play session would never notice a fresh deploy.

### Behaviour summary

- **Online web build:** on load the cached (old) version starts, then within a
  moment the new version is detected, downloaded, and the tab auto-reloads onto
  it. First-ever visit loads straight from the network (no reload).
- **Installed PWA, offline:** runs from cache as normal; the update checks fail
  silently (`.catch`), so no error. It updates once the network is back and a
  newer build exists.
- Updates only happen when you have actually **re-exported and deployed** a new
  build (that is what changes `CACHE_VERSION`).

## How to apply it (do this once per machine / after a fresh clone)

You only need to do this if `export_presets.cfg` on that machine does **not**
already contain the snippet in its Web preset's Head Include.

> **Gotcha:** the Head Include must never contain a literal closing script-tag
> sequence, not even inside a JS comment or string. The HTML parser ends the
> `<script>` block at the first one it sees, dumping the rest of the code onto
> the page as visible text and stopping it from running. `godot_pwa_update.js`
> is written to avoid this; keep it that way if you edit it.

### Option A: Godot editor (recommended, easiest)

1. Open the project in Godot.
2. **Project → Export…**
3. Select the **Web** preset (create one with the "Add…" button if it does not
   exist yet: Web platform).
4. Open the **Resources / Options** and find **HTML → Head Include**.
5. Paste the entire contents of [`godot_pwa_update.js`](godot_pwa_update.js)
   **wrapped in a script tag**:

   ```html
   <script>
   ... paste the full godot_pwa_update.js contents here ...
   </script>
   ```
6. Close the dialog. Godot saves this into `export_presets.cfg` automatically.

> **Use Option A whenever the Godot editor is open.** If you edit
> `export_presets.cfg` by hand while Godot is running, the editor will overwrite
> your change (it re-saves the file from its in-memory state), and the Head
> Include ends up empty again. Option B below is only safe with the editor
> **closed**.

### Option B: edit `export_presets.cfg` directly (editor must be closed)

Under the Web preset (the `[preset.N.options]` block whose preset has
`platform="Web"`), set `html/head_include` to the `<script>…</script>` block.
In this `.cfg` format the value is a normal double-quoted string that may span
multiple lines with literal newlines, e.g.:

```
html/head_include="<script>
... full godot_pwa_update.js contents ...
</script>
"
```

Note: keep the JavaScript using **single quotes only** (as the source does) so it
never contains a `"` that would prematurely end the `.cfg` string.

## After applying

- **Re-export** the Web build (Project → Export → Web → Export Project). This is
  what actually writes the `<script>` into `web/index.html` and bumps the service
  worker's `CACHE_VERSION`.
- **Deploy the whole export folder** (index.html, index.js, index.wasm,
  index.pck, index.service.worker.js, icons, etc.) to your host. Both the online
  version and installed PWAs will then auto-update to future deploys.

## Options you can tweak (in `godot_pwa_update.js`, then re-apply)

- `AUTO_RELOAD`: `true` (default) reloads the page automatically when an update
  is ready. Set to `false` to only `console.log` instead, so you can show your
  own "new version available" prompt / button and trigger the reload on click.
- `UPDATE_CHECK_INTERVAL`: how often (ms) to poll the server for a new build
  during a session. Default is 60 000 (1 minute).

## If you change the snippet

Edit [`godot_pwa_update.js`](godot_pwa_update.js) here (this is the tracked copy),
then re-apply it via Option A or B above and re-export. Keeping this file in sync
is what lets the setup be reproduced on any machine.
