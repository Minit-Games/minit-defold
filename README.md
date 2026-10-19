# Minit Games Defold SDK

Lets [Defold](https://defold.com/) creators publish a game to the Minit
platform. A Defold game exported to **HTML5** runs as a normal web page inside
the Minit host, so it talks to the host-injected `window.minit` runtime
**directly** — via Defold's built-in [`html5.run`](https://defold.com/ref/stable/html5/)
Lua→JS bridge. No bundler, no npm dependency, no CDN fetch. The Unity and
PlayCanvas SDKs work the same way: the Lua API surface maps 1:1 to the
`window.minit` contract, so host behaviour is identical across engines.

- Starting a new game: begin from the starter template
  [`Minit-Games/minit-template-defold`](https://github.com/Minit-Games/minit-template-defold),
  which already lists this SDK as a dependency.
- A complete reference game:
  [`Minit-Games/minit-sample-defold`](https://github.com/Minit-Games/minit-sample-defold).

## Install

Add the SDK to your own Defold game as a **library dependency** — the idiomatic
Defold path, no file copying. In your `game.project`, under `[project]
dependencies`, add the tag-pinned archive URL, then run **Project → Fetch
Libraries** in the editor:

```
[project]
dependencies = https://github.com/Minit-Games/minit-defold/archive/refs/tags/v1.17.0.zip
```

A tag URL pins that release; `.../archive/refs/heads/master.zip` tracks the
latest released commit on `master` instead (it can change under you) — prefer the
tag. After fetching, `minit/` appears as a read-only library folder and
`require("minit.minit")` resolves.

To package your game for upload:

1. In `game.project`, set `[html5] htmlfile = /minit/minit.html` (the Minit
   host shell with the audio repair). Minit Studio recognises the Defold facade
   through this shell's `generator` meta, so always use (and keep current) `minit/minit.html`.
2. Package with **Project → Minit: Package for Upload**. It writes
   `dist/<title>.zip`, ready to upload at [minit.studio](https://minit.studio).
   It fails, writing no ZIP, when the game breaks one of the platform's upload limits.
3. Your own `THIRD-PARTY-NOTICES.txt` (project root) is optional and gets
   appended to the Defold, third-party and SDK notices in the ZIP.

If your project has an `editor/` folder from an earlier Minit template, delete
it — otherwise the menu item appears twice.
If your `THIRD-PARTY-NOTICES.txt` came from an earlier Minit template, remove its
Defold and Minit SDK sections — the packager now adds them.

**Fallback (no editor / offline):** copy `minit/minit.lua` straight into your
project at `minit/minit.lua` — the same file is downloadable from the
[Defold guide](https://minit.studio/docs/defold) on minit.studio.
Also copy [`minit/minit.html`](https://github.com/Minit-Games/minit-defold/blob/v1.17.0/minit/minit.html)
from the release tag to `minit/minit.html` in your project for the shell.
Without the dependency there is no menu item or packager — bundle manually.

## Texture compression

- The SDK ships a texture profile, `minit/minit.texture_profiles`. Opt in from
  `game.project`:

  ```
  [graphics]
  texture_profiles = /minit/minit.texture_profiles
  ```

- Rules, first match wins:
  - atlases under any `uncompressed/` folder (`/**/uncompressed/**`) stay
    uncompressed RGBA — the rule matches the `.atlas` file's path, not the
    paths of the images in it;
  - everything else is BasisU, preset `BASISU_HIGHEST`, no mipmaps.
- The packager always asks for texture compression, but Defold only follows the
  project's own profile: with `texture_profiles` unset (or set to
  `/builtins/graphics/default.texture_profiles`) textures stay uncompressed.
- The package result says which applied: `Textures: compressed as set in <path>.`
  or `Textures: uncompressed (no texture profile in game.project).`
- Opting out:
  - whole game: leave `texture_profiles` unset;
  - single atlases: put the `.atlas` file under an `uncompressed/` folder, e.g.
    pixel art or UI that must stay pixel-exact (BasisU is lossy).
- To customise the rules, copy the profile into your project and point
  `texture_profiles` at your copy.

## What the packager checks

**Project → Minit: Package for Upload** builds nothing while any check before
the build fails, and writes no ZIP while any later check fails. Every failure
and note is listed in the result dialog and the editor Console.

- **Title** (Project Settings → Title): set, renamed from the template default,
  at most 50 characters, at least one letter or digit.
- **`meta.json`**:
  - present, valid JSON, a top-level object;
  - `schemaVersion` and `resultSorting` set; `resultSorting` is one of
    `highestScore`, `lowestScore`, `fastestTime`, `slowestTime`;
  - a non-string `title` fails; a string `title` gets a note and is replaced
    by the Project Settings title, which is also added when there is none;
  - no text still starting with `TODO`;
  - `controls` + `logic` + `description` together at most 2500 characters
    (a note when close or when any is missing);
  - `config`: at most 25 entries, each with a unique non-reserved key, a valid
    `valueType` and a matching default, description at most 100 characters;
  - every config key a script reads with `get_config_value` is declared, and
    every declared key is read.
- **Scripts**: fails when no script calls or references `minit.report_result`
  (outside comments and strings); notes when none does for `minit.loading_done`.
- **Bundle**:
  - the Minit shell (`minit/minit.html`) with its audio repair;
  - no thread-support (pthread) wasm;
  - no web storage (`localStorage` / `sessionStorage`) in `index.html`;
  - `index.html` at most 10 MB, at most 2000 files, at most 300 MB uncompressed.
- **ZIP**: over 50 MB fails and the ZIP is deleted; over the recommended 5 MB
  gets a note.

## Layout

| Path | What it is |
|---|---|
| `minit/minit.lua` | **The SDK facade.** Everything under `minit/` is shared with consumers (`[library] include_dirs = minit`). |
| `minit/minit.html` | **Minit host shell** for HTML5 builds — full-viewport canvas, Defold chrome stripped, the host's audio repaired. |
| `minit/editor/minit.editor_script` | Adds **Project → Minit: Package for Upload** to the editor. |
| `minit/editor/minit_package.lua` | The packager behind that menu item: checks `meta.json` and the title, bundles a release HTML5 build, checks it, zips it to `dist/<title>.zip`. |
| `minit/minit.texture_profiles` | Opt-in texture profile — see [Texture compression](#texture-compression). |
| `minit/NOTICES.txt` | Licence notices for Defold, the third-party components in its HTML5 release builds, and the SDK; the packager puts them (plus the game's own `THIRD-PARTY-NOTICES.txt`, if any) in the ZIP. |
| `example/` | The library's own test game; not shared with consumers and not a starting point — use the template or sample above. |
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

-- Run the first-play tutorial only when this returns true.
if minit.should_show_tutorial() then start_tutorial() end

-- Is the game visible to the player right now?
local visible = minit.is_viewable()

-- Get called when viewability changes (e.g. pause when scrolled away); keep the
-- returned function and call it to unsubscribe, e.g. in final().
local unsubscribe = minit.on_viewable_change(function(viewable)
    paused = not viewable
end)

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
call from anywhere, except `on_viewable_change` (see below).
On a desktop build `should_show_tutorial()` and `is_viewable()` return `true` and
`on_viewable_change` never fires; an HTML5 build without the host follows
`document.visibilityState`.

### Contract details (identical to `@minit-games/sdk`)

- **`report_result`**'s `score` is seconds (fractions allowed), never milliseconds,
  when the game's `resultSorting` is `"fastestTime"` / `"slowestTime"`.
- **`report_result`** takes `user_data` as a bare string; how it goes on the
  wire is an SDK-internal detail.
- **`report_result`** warns when `flavor_text` is over 64 characters (counted
  like a JS string, so an emoji counts 2) — the platform cuts it to 64 — and
  when called more than once, since the host ignores repeat calls. Warnings go
  to the browser console (`console.warn`) in HTML5 builds, else to `print`.
- **`get_config_value`** returns `default` when the key is absent; the reserved
  key `"userData"` always returns `default` so it never bleeds into config.
  Declare the game's config keys in your build's `meta.json` `config` array —
  see [The meta.json file](https://minit.studio/docs/declaring-config-values).
- **`get_user_data`** returns host-injected `window.minit.userData` when present,
  else the `?userData` URL param, else `nil`. Returns `""` (empty string,
  distinct from `nil`) if the stored value is the empty string.
- **`should_show_tutorial`** resolves in order: `?tutorial=1|true` → show,
  `?tutorial=0|false` → hide, host `window.minit.hasPlayedGame === true` → hide,
  else show. Off-web it returns `true`.
- **`is_viewable`** uses the host's `window.minit.isViewable()` when present, else
  `document.visibilityState === "visible"`; it re-reads on every call. Off-web
  it returns `true`.
- **`on_viewable_change`** listens to the host's `viewableChange` event when the
  host has `isViewable`, `addEventListener` and `removeEventListener`, else to
  `visibilitychange`. Lua polls the latest value every 0.25 s, so a change
  arrives up to ~250 ms late. Each subscriber starts from the value at subscribe
  time and is called only when it changes; subscribing the same function twice
  is a no-op that returns the same unsubscribe, and unsubscribing twice is safe.
  A subscriber error is logged and doesn't stop the others.
- **`on_viewable_change`** must be called from a script (`.script` /
  `.gui_script`) callback: the poll runs on a Defold
  [`timer`](https://defold.com/ref/timer/), which belongs to the script that
  subscribed most recently and dies with it. Subscribe from a script that lives
  as long as the subscription, and unsubscribe in its `final()`. If that script
  is deleted first, polling stops until the next `on_viewable_change` call. The
  timer stops itself within one poll after the last unsubscribe.

## Building for upload

Use **Project → Minit: Package for Upload** (see [Install](#install)): it makes
the release HTML5 build, runs the [checks](#what-the-packager-checks) and writes
`dist/<title>.zip`.
