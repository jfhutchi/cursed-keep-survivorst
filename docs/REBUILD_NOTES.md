# Rebuild Notes

Record of the FABLE_5_PROMPT.md rebuild: what existed, what was replaced,
what was preserved, and why.

## What Existed Before

The repo held **"Reward Loop Seed"** — a deliberately ugly single-scene
prototype (one arena, code-drawn rectangles, automatic blasts, spark pickups,
a free-chest reveal, local event logging) plus its design documents
(`ANALYTICS_SPEC.md`, `DESIGN_GOALS.md`, `ETHICAL_MONETIZATION_GUARDRAILS.md`,
`PROTOTYPE_SCORECARD.md`) and one test file. Alongside it:
`addons/godot_ai/` (the Godot AI / MCP editor plugin) and its license file.

## What Was Overwritten / Removed

- `scenes/main.tscn` → replaced by the new `scenes/Main.tscn` flow scene
  (same path on Windows's case-insensitive filesystem; git shows a modify).
- `scripts/enemy.gd`, `scripts/floating_text.gd`, `scripts/main.gd`,
  `scripts/player.gd`, `scripts/reward_event_logger.gd`,
  `scripts/reward_loop_rules.gd`, `scripts/reward_pickup.gd` — deleted.
- `tests/test_reward_loop_core.gd` — deleted; replaced by new MCP test
  suites (`test_project_compile_smoke.gd`, `test_game_data_integrity.gd`).
- The four old prototype design docs — deleted (they described the previous
  game's analytics/monetization scope, not this game).
- `project.godot` — rewritten: new name, main scene, autoloads, input map,
  display/stretch settings, `gl_compatibility` renderer. **All pre-existing
  plugin entries were carried forward** (see below).
- `README.md` — rewritten for Cursed Keep Survivors.

## What Was Preserved (untouched)

- `addons/godot_ai/` — entire plugin, byte-for-byte
  (`git diff --name-only -- addons/godot_ai` is empty).
- `project.godot` entries the plugin needs:
  `_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"` autoload
  and `editor_plugins/enabled=PackedStringArray("res://addons/godot_ai/plugin.cfg")`.
- `godot-ai-LICENSE.txt`.
- `.git/`, `.gitattributes`, `.gitignore`, `icon.svg`.
- `[dotnet]` and `[physics]` (Jolt) sections of `project.godot`, kept to
  avoid disturbing the existing editor setup.

Details in [`PRESERVED_AGENT_TOOLING.md`](PRESERVED_AGENT_TOOLING.md).

## Why a Destructive Rebuild

The prompt explicitly requested a from-scratch remake into a different game
(bullet-heaven survivor vs. reward-loop probe). The old prototype shared no
reusable architecture — single scene, no pooling, no data layer — so carrying
it forward would have cost more than rebuilding. The only assets worth
keeping were the agent tooling and repo plumbing, which were preserved
exactly.

## What Was Built

~30 GDScript files (autoloads, data tables, world/pooling/grid, weapon
manager with 18 behaviors, enemies/boss, UI screens), 24 scene files, 55
original SVGs, a runtime audio synthesizer, two MCP test suites, and a
headless validator. See `TECHNICAL_ARCHITECTURE.md` and `GAME_DESIGN.md`.

## Intentionally Left Untouched

- `addons/godot_ai/` and anything it references.
- `FABLE_5_PROMPT.md` (the task brief itself, untracked).
- `.vscode/` local editor configuration.

## Risks / Uncertainty

- `scenes/main.tscn` vs `scenes/Main.tscn` casing: harmless on Windows; on a
  case-sensitive filesystem the file exists once under the case stored in
  git. The project setting points at `res://scenes/Main.tscn`.
- The mono (.NET) editor build is used locally, but the project is pure
  GDScript; the `[dotnet]` section is inert.
- Headless CLI validation depends on a local Godot binary that is not on
  PATH on every machine; the MCP test runner inside the editor is the
  primary verification path (last full pass: 6/6).
- Balance numbers are first-pass; see Balancing Notes in `GAME_DESIGN.md`.
