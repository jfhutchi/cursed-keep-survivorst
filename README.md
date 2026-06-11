# Cursed Keep Survivors

Cursed Keep Survivors is an original dark-fantasy bullet-heaven survival game built in Godot. You play as the last Wardkeeper inside a living fortress, surviving escalating waves, collecting soul shards, choosing upgrades, unlocking weapons, and fighting the Cursed Castellan.

The current project is a Godot 4.6 game with generated in-project SVG art, procedural animation, synthesized audio, persistent local save data, and a data-driven weapon/enemy/upgrade/wave model.

## How To Run

1. Open this folder in Godot 4.6.3 or a compatible Godot 4.6.x editor.
2. Run the project with F5.
3. Godot boots `res://scenes/Main.tscn`.
4. Select `BEGIN THE VIGIL` from the main menu.

Or play in the browser (deployed from `master` by GitHub Actions once Pages
is enabled): <https://jfhutchi.github.io/cursed-keep-survivorst/>

## Controls

- Move with WASD, arrow keys, or left stick.
- Dash with Space or gamepad face button 0.
- Weapons fire automatically.
- Choose level-up upgrades with 1 / 2 / 3 or mouse.
- Pause with Esc or gamepad select.
- Toggle the debug overlay with F3.

## Current Gameplay Loop

1. Start with Soul Bolt and survive inside the cursed keep arena.
2. Defeat enemies to collect soul shards and score.
3. Level up to choose upgrades, weapon unlocks, synergies, and cursed tradeoffs.
4. Build from an 18-weapon pool with weapon-specific upgrade paths.
5. Survive 10 waves, including elite pressure and the final boss wave.
6. Win by defeating The Cursed Castellan, or restart quickly after defeat.

## Project Structure

- `scenes/Main.tscn` - main flow controller scene.
- `scripts/game/` - run loop, world, projectiles, effects, and combat entities.
- `scripts/player/` - Wardkeeper movement, dash, XP, health, and stats.
- `scripts/weapons/` - weapon ownership, cooldowns, firing behavior, and synergies.
- `scripts/data/` - data tables for weapons, enemies, upgrades, and waves.
- `scripts/core/` - autoloads for game events, save data, audio, and global data access.
- `assets/generated/` - generated SVG characters, enemies, weapons, icons, environment, and UI art.
- `tests/` - Godot AI MCP test suites for compile and data-integrity coverage.

## Verification

The project includes two automated Godot test suites:

- `project_compile_smoke` verifies the configured main scene and key runtime scripts load without compile errors.
- `game_data_integrity` verifies weapon implementations/audio/icons, upgrade references, enemy scenes/sprites, wave compositions, and upgrade offer filtering.

If the Godot executable is available on PATH, the headless validator can also be run with:

```powershell
godot --headless --path . --script res://scripts/tools/validate_project.gd
```

## Assets And Dependencies

All game art and audio are generated in-project. There are no external asset packs, downloaded sound effects, ads, monetization hooks, or premium-currency systems in this repo. The 55 SVG sprites/icons are hand-authored originals; everything else (effects, glow textures, particles) is drawn procedurally, and every sound is synthesized at startup. See [`assets/generated/ART_PIPELINE.md`](assets/generated/ART_PIPELINE.md).

## Godot AI / Agent Tooling Preservation

This repo doubles as an AI-agent workspace. The following are intentionally preserved and must not be removed:

- `addons/godot_ai/` — the Godot AI / MCP editor plugin (entire folder, unmodified).
- The `_mcp_game_helper` autoload and the `editor_plugins` enablement entry in `project.godot`.
- `godot-ai-LICENSE.txt`.

Details and verification steps are in [`docs/PRESERVED_AGENT_TOOLING.md`](docs/PRESERVED_AGENT_TOOLING.md). When the editor is open, the plugin serves MCP on `127.0.0.1:8000`.

## Documentation

- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — core loop, player, all 18 weapons, enemies, boss, 108 upgrades, waves, balancing notes.
- [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md) — scenes, autoloads, weapon/enemy systems, pooling, spatial grid, performance.
- [`docs/ART_PIPELINE.md`](docs/ART_PIPELINE.md) — how the generated art and audio are made and extended.
- [`docs/MANUAL_TEST_CHECKLIST.md`](docs/MANUAL_TEST_CHECKLIST.md) — pre-release manual pass.
- [`docs/WEB_EXPORT_GITHUB_PAGES.md`](docs/WEB_EXPORT_GITHUB_PAGES.md) — web export preset and GitHub Pages notes.
- [`docs/REBUILD_NOTES.md`](docs/REBUILD_NOTES.md) — what the rebuild replaced and preserved.

## Current Limitations

- Art is coherent prototype quality, not final-art quality; entity drop shadows, arena banners/rubble, hostile-shot danger rings and a gameplay vignette exist, but sprite detail is still simple.
- Balance has had one live tuning pass (XP curve, waves 1–2, elites, boss HP, pickup radius); waves 5–10 still need human playtesting.
- Touch controls (virtual joystick + dash button) exist and auto-enable on touchscreens, but have not been tested on a physical device yet.
- Controller play works in menus (focus navigation + accept) and gameplay (stick/dash/pause); only mouse-style cursor UIs (tooltip hovers) are keyboard-blind.
- Music is a single ambient drone loop; no per-state music yet.

## Next Steps

1. Human playtest pass over waves 5–10 with `docs/MANUAL_TEST_CHECKLIST.md`.
2. Verify the Web build on more browsers/devices and deploy to GitHub Pages per `docs/WEB_EXPORT_GITHUB_PAGES.md`.
3. Touch-device test of the virtual joystick layout.
4. Meta-progression hooks (unlockable starting weapons) on top of `SaveSystem`.
5. Per-state music layers (menu / waves / boss) in the synthesizer.
