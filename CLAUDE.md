# CLAUDE.md — minit-defold

Minit Games SDK + sample for the Defold engine (public repo `Minit-Games/minit-defold`), letting Defold creators publish a game to the Minit platform. Full maintainer reference — the `window.minit` contract, shared engine-facade pattern, distribution/release philosophy, and per-engine gotchas — lives in the consolidated SDK-maintenance doc: https://github.com/Minit-Games/minit-root/blob/develop/docs/sdk-maintenance.md

## Release process

Defold libraries are consumed as **source** — there is **no build/publish
pipeline** (unlike `minit-sdk`'s npm publish). A release is just a tag + GitHub
Release:

1. From `develop`, bump `[project] version` in `game.project`, commit.
2. Fast-forward `develop` → `master` (`git merge --ff-only develop`).
3. Tag `v<x.y.z>` on `master` and push the tag; cut a GitHub Release.
4. The tag's archive URL (`https://github.com/Minit-Games/minit-defold/archive/refs/tags/v<x.y.z>.zip`) is the creator-facing dependency URL.
