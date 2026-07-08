# CLAUDE.md — minit-defold

Minit Games SDK + sample for the [Defold](https://defold.com/) engine. Public
repo: `Minit-Games/minit-defold`. Lets Defold creators publish a game to the
Minit platform.

A Defold game exported to **HTML5** runs as a normal web page inside the Minit
host, so it talks to the host-injected `window.minit` runtime directly via
Defold's `html5.run` Lua→JS bridge — no bundler, no npm dependency, no CDN
fetch. The Lua API surface maps 1:1 to the same `window.minit` contract used by
the [Unity](../minit-unity/) and [PlayCanvas](../minit-playcanvas/) SDKs, so host
behaviour is identical across engines.

## Repo layout

| Path | What it is | Shared with consumers? |
|------|------------|------------------------|
| `minit/minit.lua` | **The SDK facade** — the only thing creators consume. | ✅ yes (`[library] include_dirs = minit`) |
| `example/` | Sample "tap race" game (`main/`, `input/`, `minit.html`) — example + build test. | ❌ no |
| `game.project` | Project config; bootstraps `example/`, declares the library share via `[library]`. | ❌ (settings never leak; only `include_dirs` folders do) |
| `README.md` | Creator-facing facade API, build steps, Minit-ready ZIP contract. | ❌ |

This repo is both the **library** and its **example**: `[library] include_dirs`
exposes only `minit/`, so a consumer who adds this repo as a dependency gets
`minit/minit.lua` (resolving `require("minit.minit")`) and nothing else — the
sample game under `example/` stays private to the repo. The facade lives at the
repo root (`minit/`), not inside `example/`, precisely so it is shared while the
example is not.

## Distribution — Defold library dependency

The idiomatic Defold path (creators use the desktop editor, so no copy-paste
needed). A creator adds a ZIP-archive URL under `[project] dependencies` in their
own `game.project`, then runs **Project → Fetch Libraries**:

```
https://github.com/Minit-Games/minit-defold/archive/refs/tags/v<x.y.z>.zip
```

Pointing at a **tag** pins the version; `.../archive/main.zip` tracks latest.
After fetch, `minit/` appears read-only in their project and
`require("minit.minit")` works.

A direct `minit.lua` download (vendored into `minit-web` at
`public/static/defold/minit.lua`, linked from the `tool-defold` KB article)
remains as a no-editor fallback — keep it re-synced to this repo's `minit/minit.lua`.

## Building the sample (HTML5)

Defold builds HTML5 headlessly with `bob` (bundled in every Defold install — no
separate download). Platform target is **`wasm-web`** in Defold 1.13 (`js-web`
asm.js is gone):

```bash
JAR="…/Defold/packages/defold-<sha>.jar"
JAVA="…/Defold/packages/jdk-*/bin/java"      # or any JDK 17+
"$JAVA" -cp "$JAR" com.dynamo.bob.Bob \
  --platform wasm-web --architectures wasm-web \
  --variant release --archive --bundle-output dist-web \
  build bundle
```

`--architectures wasm-web` ships a single non-pthread wasm, avoiding the
`SharedArrayBuffer` / COOP-COEP requirement. In the GUI editor: **Project →
Bundle → HTML5**. Full build/scaling/packaging notes: [`README.md`](./README.md).

**Minit host requirements baked into the sample:** `[html5] scale_mode = stretch`
(fills the host's arbitrary-aspect iframe — it's a *string* enum, a numeric value
silently emits no resize logic), `high_dpi = 1`, and a custom font baked large
(`example/main/main.font`, size 48 — the builtin `default.font` is size 14 and
renders crisp-but-tiny on high-DPI phones).

## Release process

Defold libraries are consumed as **source** — there is **no build/publish
pipeline** (unlike `minit-sdk`'s npm publish). A release is just a tag + GitHub
Release:

1. From `develop`, bump `[project] version` in `game.project`, commit.
2. Fast-forward `develop` → `master` (see Branch flow).
3. Tag `v<x.y.z>` on `master` and push the tag; cut a GitHub Release.
4. The tag's archive URL is the creator-facing dependency URL (above).

## Branch flow

Same long-lived **develop + master** pattern as the other Minit sub-repos (see
the root `minit-root/CLAUDE.md`):

- `develop` — default branch; feature branches PR into it (squash merge).
- `master` — mirrors the currently-released state; updated by fast-forwarding
  `develop` → `master` (`git merge --ff-only develop`), never a squash/merge-commit.

Branch naming: `feature/DROP-<n>-<slug>` / `fix/DROP-<n>-<slug>`.
