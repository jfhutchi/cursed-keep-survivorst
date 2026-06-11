# Claude Fable 5 Handoff

This file is for the next short Claude Fable 5 session. Read this before making changes.

## Current State

- The repo has been rebuilt into `Cursed Keep Survivors`, a Godot 4.6 dark-fantasy bullet-heaven prototype.
- Main scene: `res://scenes/Main.tscn`.
- Core gameplay exists: menu, start flow, player movement/dash, auto weapons, waves, XP, level-up upgrades, pickups, boss, victory/game-over screens, save data, debug overlay, generated SVG art, and procedural audio.
- Data currently includes 18 weapons, 100+ upgrades, 8 synergies, 7+ enemy types plus boss, and 10 waves.
- Automated tests were restored/replaced under `res://tests/`.

## Hard Constraints

- Do not modify `addons/godot_ai/`.
- Do not delete or alter Godot AI/MCP/addon tooling.
- Before finalizing, confirm `git diff --name-only -- addons/godot_ai` is empty.
- Do not run a broad destructive rebuild. The game already exists; improve it incrementally.
- Preserve the current test suites unless replacing them with stronger equivalent coverage.

## Recent Verification

Godot MCP test runner passed:

- `project_compile_smoke`: main scene and key runtime scripts load.
- `game_data_integrity`: weapon data, icons, audio cues, upgrade references, enemy scenes/sprites, wave references, and upgrade offer filtering.
- Last full MCP test pass: 6 passed, 0 failed.

Runtime smoke also passed:

- Main menu launched.
- `BEGIN THE VIGIL` started a run.
- `GameWorld`, `Player`, enemies, projectiles, HUD, and wave UI appeared.
- No game-log errors were observed during the smoke run.

The local shell did not have `godot` on PATH, so do not claim headless CLI validation unless you run it yourself.

## Known Gaps Against FABLE_5_PROMPT.md

The largest unfinished prompt items are documentation and visual polish:

- `docs/GAME_DESIGN.md` is missing.
- `docs/TECHNICAL_ARCHITECTURE.md` is missing.
- `docs/ART_PIPELINE.md` is missing.
- `docs/REBUILD_NOTES.md` is missing.
- `docs/MANUAL_TEST_CHECKLIST.md` is missing.
- `docs/WEB_EXPORT_GITHUB_PAGES.md` is missing.
- `assets/generated/ART_PIPELINE.md` is missing.
- `export_presets.cfg` is missing.
- `README.md` is better than before but still lacks full current limitations, next steps, and explicit Godot AI/addon preservation detail.
- Graphics are coherent prototype quality, not final-art quality. The highest-value art pass is player/enemy silhouettes, arena detail, combat effects, UI polish, and contrast/readability.

Completed since this handoff was created:

- `docs/PRESERVED_AGENT_TOOLING.md` now documents the preserved `addons/godot_ai/` folder, the `_mcp_game_helper` autoload, and the enabled Godot AI plugin setting.

## Suggested Four-Minute Priority

If usage time is very limited, do not attempt a major implementation. Pick one:

1. Create the missing documentation files as concise, accurate repo docs.
2. Write a focused visual-polish plan with specific files/assets to improve next.
3. Improve README completeness with limitations, next steps, and tooling preservation.
4. Inspect one art surface, then make one small, targeted graphics improvement.

## Best Next Prompt

Use a narrow prompt, not the full rebuild prompt:

```text
Read docs/CLAUDE_FABLE_5_HANDOFF.md first. Do not modify addons/godot_ai or any MCP/tooling files. Do not perform a destructive rebuild. Work only on the highest-value missing FABLE_5_PROMPT.md gap that can be completed safely in this short session, then run the Godot MCP tests if available and report exactly what changed.
```
