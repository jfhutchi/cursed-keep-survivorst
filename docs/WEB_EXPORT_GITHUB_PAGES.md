# Web Export & GitHub Pages

Status: **exported and browser-tested locally; not yet deployed to Pages.**

Verified in a Chromium-based browser against a local static server
(`python -m http.server` over `build/web/`):

- Boots to the main menu (Quit button correctly hidden on web).
- Full gameplay runs: movement, auto-fire, enemies, damage numbers, XP
  shards, HUD, wave banner.
- Save data persists across page reloads (IndexedDB-backed `user://`).
- Non-threaded build — no COOP/COEP headers were needed.

Known cosmetic issue: the boot console logs
"Failed to instantiate an autoload … addons/godot_ai/runtime/game_helper.gd".
The Godot AI editor plugin's runtime helper is editor-only (it references
`EditorInterface`) and is excluded from the export via the preset's
`exclude_filter`, but its autoload entry in `project.godot` must stay for the
editor tooling. The error is harmless and the game continues normally.
Removing it would require modifying the preserved `addons/godot_ai/` plugin
or its autoload contract, which this repo intentionally does not do.

## Godot Version

- Project authored against **Godot 4.6.3-stable**. Use the matching export
  templates (Editor → Manage Export Templates) before exporting.
- The local editor is the mono build, but the project is **pure GDScript** —
  export with the standard (non-.NET) Web template. C# is not used anywhere.

## Why the project is web-compatible

- Renderer is `gl_compatibility` (WebGL2-friendly) — set in `project.godot`.
- All audio is `AudioStreamWAV` buffers synthesized at startup; no streaming
  formats, no microphone, no `AudioStreamGenerator` real-time pull.
- Save data uses `user://` JSON, which maps to browser IndexedDB on Web.
- No threads are spawned by game code, so the **non-threaded** web variant
  works (no SharedArrayBuffer / cross-origin-isolation headers needed —
  important because GitHub Pages cannot send COOP/COEP headers).
- The Quit button is hidden on Web (`OS.has_feature("web")`).

## Export Preset

`export_presets.cfg` contains a single "Web" preset:

- `variant/thread_support=false` — runs on plain static hosting (GitHub
  Pages) without special headers. If you flip this on, you must host with
  COOP/COEP headers (not possible on vanilla GitHub Pages).
- `exclude_filter="addons/godot_ai/*, tests/*"` — the editor-only MCP plugin
  and the test suites are not shipped in the pck (see Known cosmetic issue
  above).
- `export_path="build/web/index.html"` — `build/` is git-ignored territory;
  create the folder before exporting from the dialog, or export via CLI:

```powershell
godot --headless --path . --export-release "Web" build/web/index.html
```

## GitHub Pages Deployment (automated)

`.github/workflows/deploy-pages.yml` builds and deploys on every push to
`master` (and via manual *Run workflow*):

1. Downloads + caches the Godot ${GODOT_VERSION} Linux editor and export
   templates (~1.3 GB, cached after the first run).
2. Runs the headless import scan, then the project validator
   (`scripts/tools/validate_project.gd`) — a failing validation blocks the
   deploy.
3. Exports the "Web" preset to `build/web/` and sanity-checks the artifacts.
4. Publishes `build/web/` with `actions/deploy-pages`.

**One-time setup**: in the repo's *Settings → Pages*
(<https://github.com/jfhutchi/cursed-keep-survivorst/settings/pages>), set
**Source** to **"GitHub Actions"** (the workflow cannot enable this itself).
After the first successful run the game is served at:

**<https://jfhutchi.github.io/cursed-keep-survivorst/>**

Manual fallback: export to `build/web/` locally as above and copy its
contents to a `gh-pages` branch. GitHub Pages serves correct `.wasm` MIME
types; no extra config is needed for the non-threaded build. First load is
~38 MB of wasm+pck; subsequent loads are cached.

## Known Limitations / Caveats

- Tested locally in one Chromium browser; other browsers/devices and the
  actual GitHub Pages deployment are still pending. Audio autoplay
  policies mean the music drone starts only after the first input/click in
  most browsers (menu interaction satisfies this).
- Performance on weak machines is the main risk in waves 9–10 (hundreds of
  draw-based entities). The F3 overlay works in web builds for profiling.
- `OS.has_feature("web")` paths are minimal; fullscreen/touch controls for
  mobile browsers are future work (input map already includes gamepad).
- Boot splash/loading bar uses Godot defaults.
