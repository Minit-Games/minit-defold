# Minit Games Defold SDK + sample

Lets [Defold](https://defold.com/) creators publish a game to the Minit
platform. A Defold game exported to **HTML5** runs as a normal web page inside
the Minit host, so it talks to the host-injected `window.minit` runtime
**directly** — via Defold's built-in [`html5.run`](https://defold.com/ref/stable/html5/)
Lua→JS bridge. No bundler, no npm dependency, no CDN fetch. This is the same
design decision the [Unity SDK](../minit-unity/) and
[PlayCanvas SDK](../minit-playcanvas/) made: the Lua API surface maps 1:1 to the
`window.minit` contract, so host behaviour is identical across engines.

> **Status.** Published as the public repo
> [`Minit-Games/minit-defold`](https://github.com/Minit-Games/minit-defold)
> (latest release `v0.2.0`) — a facade module plus a tiny playable sample game.
> Built and bundled end-to-end with Defold 1.13.0's headless builder (`bob`); the
> `window.minit` bridge snippets were validated against a mock host.

## Install

Add the SDK to your own Defold game as a **library dependency** — the idiomatic
Defold path, no file copying. In your `game.project`, under `[project]
dependencies`, add the tag-pinned archive URL, then run **Project → Fetch
Libraries** in the editor:

```
[project]
dependencies = https://github.com/Minit-Games/minit-defold/archive/refs/tags/v0.2.0.zip
```

A tag URL pins that release; `.../archive/refs/heads/master.zip` tracks the
latest released commit on `master` instead (it can change under you) — prefer the
tag. After fetching, `minit/` appears as a read-only library folder and
`require("minit.minit")` resolves.

To package your game for upload:

1. In `game.project`, set `[html5] htmlfile = /minit/minit.html` (the Minit
   host shell with the audio repair).
2. Package with **Project → Minit: Package for Upload**. It writes
   `dist/<title>.zip`, ready to upload at [minit.studio](https://minit.studio).
3. Your own `THIRD-PARTY-NOTICES.txt` (project root) is optional and gets
   appended to the Defold, third-party and SDK notices in the ZIP.

If your project has an `editor/` folder from an earlier Minit template, delete
it — otherwise the menu item appears twice.

**Fallback (no editor / offline):** copy `minit/minit.lua` straight into your
project at `minit/minit.lua` — the same file is downloadable from the
`tool-defold` KB article in the Minit creator console.

## Layout

| Path | What it is |
|---|---|
| `minit/minit.lua` | **The SDK facade.** Everything under `minit/` is shared with consumers (`[library] include_dirs = minit`). |
| `minit/minit.html` | **Minit host shell** for HTML5 builds — full-viewport canvas, Defold chrome stripped, the host's audio repaired. |
| `minit/editor/minit.editor_script` | Adds **Project → Minit: Package for Upload** to the editor. |
| `minit/editor/minit_package.lua` | The packager behind that menu item: checks `meta.json` and the title, bundles a release HTML5 build, checks it, zips it to `dist/<title>.zip`. |
| `minit/NOTICES.txt` | Licence notices for Defold 1.13.1, the third-party components in its HTML5 release builds, and the SDK; the packager puts them (plus the game's own `THIRD-PARTY-NOTICES.txt`, if any) in the ZIP. |
| `example/main/main.gui_script` | Sample "tap race" game logic — uses every facade call end-to-end. |
| `example/main/main.gui`, `example/main/main.go`, `example/main/main.collection`, `example/main/main.font` | Sample scene wiring + a large-baked font. |
| `example/input/game.input_binding` | Maps mouse-click / touch to the `touch` action. |
| `game.project` | Project config; bootstraps `example/`, points HTML5 builds at `/minit/minit.html`, declares the `[library]` share. |

## API

The facade mirrors the Unity / PlayCanvas SDKs 1:1 (idiomatic Lua `snake_case`):

```lua
local minit = require("minit.minit")

-- Signal the host the game is ready to be revealed (host hides the game until this fires).
minit.loading_done()

-- Read a config value from URL query params. "userData" is a reserved key.
local difficulty = minit.get_config_value("difficulty", "normal")

-- Read this player's persisted userData slot (string | nil).
local saved = minit.get_user_data()

-- Submit the final result — call exactly once at game end. Higher score = better.
-- Time-based games (meta.json resultSorting fastestTime/slowestTime): pass SECONDS,
-- not ms — e.g. report_result(elapsed_seconds), fractions allowed.
minit.report_result(1234, {
    flavor_text = "Cleared the last wave with 1 HP left",
    user_data = "5",   -- optional; omit to leave the stored slot unchanged. "" is a valid write.
})
```

Outside the Minit host — a **desktop build**, or an HTML5 build opened without
the host injecting `window.minit` — every call degrades gracefully: writes
become a `print`, and reads fall back to URL query params (`?difficulty=hard`,
`?userData=5`), exactly like the Unity SDK falls back to `Debug.Log`. Safe to
call from anywhere.

### Contract details (identical to `@minit-games/sdk`)

- **`report_result`**'s `score` is seconds (fractions allowed), never milliseconds,
  when the game's `resultSorting` is `"fastestTime"` / `"slowestTime"`.
- **`report_result`** wraps `user_data` into `{ value: "<string>" }` on the wire
  to match `UserDataPatchSchema` in `@minit/shared/zod`. Games pass a bare
  string; the wrapping is an SDK-internal detail.
- **`get_config_value`** returns `default` when the key is absent; the reserved
  key `"userData"` always returns `default` so it never bleeds into config.
  Declare the game's config keys in your build's `meta.json` `config` array —
  see [The meta.json file](https://minit.studio/docs/declaring-config-values).
- **`get_user_data`** returns host-injected `window.minit.userData` when present,
  else the `?userData` URL param, else `nil`. Returns `""` (empty string,
  distinct from `nil`) if the stored value is the empty string.

## The sample game

A 10-second "tap race": tap/click as fast as you can, score = tap count. It
demonstrates the full lifecycle —

- `init` reads `difficulty` (config) and the previous best (userData), then calls
  `loading_done()`.
- `difficulty` (`easy` / `normal` / `hard`) adjusts the clock — proves config
  reaches gameplay.
- On time-up it calls `report_result(score, { flavor_text, user_data })`,
  persisting the new best back into the single userData slot.

## Building a Minit-ready HTML5 bundle

Defold builds HTML5 headlessly with `bob` (the JAR bundled in every Defold
install — no separate download). From this directory:

```bash
# Adjust paths to your Defold install. On this machine bob lives inside the editor JAR.
JAR="…/Defold/packages/defold-<sha>.jar"
JAVA="…/Defold/packages/jdk-25+36/bin/java.exe"   # or any JDK 17+

"$JAVA" -cp "$JAR" com.dynamo.bob.Bob \
  --platform wasm-web --architectures wasm-web \
  --variant release --archive \
  --bundle-output dist-web \
  build bundle
```

The bundle lands in `dist-web/Minit Defold Sample/` — `index.html` (from
`minit.html`), `dmloader.js`, the `.wasm` + its loader `.js`, and an `archive/`
folder. **Zip the *contents* of that folder** (so `index.html` is at the ZIP
root) and upload to the Minit creator console.

Notes:
- **`--platform wasm-web`** is the HTML5 platform in Defold 1.13 (the old
  `js-web` asm.js target is gone).
- **Canvas fill — `[html5] scale_mode = stretch` is required.** The Minit host
  mounts games in a `width/height: 100%` iframe of an **arbitrary-aspect**
  container. Defold's default `downscale_fit` pins the canvas at the design
  resolution (720×1280) and centers it with margins on any larger surface — the
  game looks tiny/mis-fit. `stretch` makes Defold's loader size the canvas to the
  full iframe (`innerWidth × innerHeight`) on every resize, so it always fills.
  Because the sample is a GUI (background node `ADJUST_MODE_STRETCH`, text nodes
  `ADJUST_MODE_FIT` + center pivot), content stays centered and undistorted at
  any aspect. Note `scale_mode` is a **string** enum
  (`downscale_fit`/`fit`/`stretch`/`no_scale`) — a numeric value is silently
  ignored and emits *no* resize logic at all.
- **`--architectures wasm-web`** ships a *single* non-pthread wasm. Without it,
  bob also emits a `*_pthread.wasm` that the loader prefers when
  `SharedArrayBuffer` is available — and SAB requires the page be served with
  cross-origin-isolation headers (`COOP: same-origin` + `COEP: require-corp`).
  Pinning to the single arch sidesteps that host requirement. See open questions.
- **`--variant release`** strips the debug console/profiler.
- In the GUI editor the same output comes from **Project → Bundle → HTML5**.

## Open questions

Mirrors the same open items the PlayCanvas prototype flagged, plus Defold
specifics surfaced while building this:

- **Minit-ready ZIP contract.** Confirm the host accepts the Defold bundle shape
  (`index.html` + `dmloader.js` + `.wasm`/`.js` + `archive/`) as-is, and whether
  any file must be stripped/renamed. `minit.html` already removes the Defold
  loader chrome, the "Made with Defold" link, and the running-from-file warning,
  and fills the viewport — verify it against the host's canvas requirements
  (compare with the Unity WebGL template).
- **`SharedArrayBuffer` / cross-origin isolation.** Decide whether the host
  serves games with COOP/COEP headers. If yes, we can ship the faster pthread
  wasm (drop `--architectures`); if no, the single-arch build above is required.
- **Canvas scaling — resolved to `stretch`.** `game.project` uses
  `[html5] scale_mode = stretch` so the canvas fills the host's arbitrary-aspect
  iframe (see the build note above). Open item: whether a real game with
  non-GUI content wants `fit` (letterbox, preserves aspect) instead — a per-game
  choice, not a platform default.
- **Distribution — resolved.** Shipped as a Defold
  [library dependency](https://defold.com/manuals/libraries/) (the tag archive
  URL added under `[project] dependencies` — see [Install](#install) above), with
  the vendored `minit.lua` download as a no-editor fallback.
