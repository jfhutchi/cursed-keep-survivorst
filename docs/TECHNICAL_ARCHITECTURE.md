# Cursed Keep Survivors — Technical Architecture

Godot 4.6 (GDScript only, no C#). Renderer: `gl_compatibility` for desktop +
future Web export. No physics bodies are used for combat — all hit detection
is squared-distance math against a spatial hash grid.

## Scene Architecture

```
scenes/Main.tscn            Node + main.gd — flow controller, owns UI screens
├── (GameWorld instance)    created per run from scenes/game/GameWorld.tscn
├── MainMenu.tscn           CanvasLayer screens, all UI built in code
├── HUD.tscn                (ui_theme.gd provides shared styling)
├── PauseMenu.tscn
├── LevelUpScreen.tscn
├── GameOverScreen.tscn     result_screen.gd, victory_mode=false
├── VictoryScreen.tscn      result_screen.gd, victory_mode=true
└── DebugOverlay.tscn       F3 overlay

GameWorld (game_world.gd)
├── Arena                   procedural environment (arena.gd)
├── zone_layer (z -5)       pooled ground effects
├── orb_layer  (z -3)       pooled XP orbs + pickups
├── entity_layer (z 0)      y-sorted: Player, enemies, boss, orbiters
├── proj_layer (z 5)        pooled projectiles
├── fx_layer   (z 8)        pooled draw-based effects
├── text_layer (z 10)       pooled floating combat text
├── CameraRig               Camera2D smoothing + trauma shake
├── WeaponManager
├── UpgradeSystem
└── WaveDirector
```

Per-enemy scenes (`scenes/enemies/*.tscn`) are thin: root Node2D with
`enemy.gd` + a Sprite2D pointing at the generated SVG. The boss has its own
script (`boss.gd`) but implements the same combat interface as `enemy.gd`
(`take_damage`, `apply_burn/poison/bleed/slow/stun/mark`, `alive`, `marked`)
so every weapon works against it unchanged.

## Autoloads

| Autoload | File | Role |
|---|---|---|
| `_mcp_game_helper` | `addons/godot_ai/runtime/game_helper.gd` | **Godot AI tooling — preserved, do not touch** |
| `GameEvents` | `scripts/core/game_events.gd` | global signal bus; systems never hold cross-references |
| `SaveSystem` | `scripts/core/save_system.gd` | JSON persistence in `user://` |
| `AudioManager` | `scripts/core/audio_manager.gd` | synthesizes every SFX + music loop at startup |
| `GameData` | `scripts/core/game_data.gd` | wraps static data tables, arena constants, perf caps |

## Data Layer (`scripts/data/`)

Plain GDScript const tables (chosen over `Resource` files for diffability and
zero load ceremony — the prompt explicitly allows this):

- `weapon_data.gd` — 18 weapons: base stats, targeting mode, color, icon,
  per-weapon `max_active` cap.
- `enemy_data.gd` — 8 enemy defs + ELITE modifiers + BOSS block.
- `upgrade_data.gd` — 108 upgrades with rarity weights/colors.
- `wave_data.gd` — 10 waves: duration, interval lerp, max-alive, composition.

Adding a weapon = one dict entry + one `_fire_*` routine + an entry in
`WeaponManager.IMPLEMENTED` + an icon SVG + an audio entry. Tests fail if any
piece is missing.

## Weapon System

`weapon_manager.gd` owns `owned: {id: {level, cd, mods}}`.

- **Effective stats**: `wstat(id, key)` = (base + upgrade adds) × upgrade
  mults × routed player multiplier (damage_mult for damage keys, area_mult
  for radii, etc.). Upgrades therefore never touch weapon code.
- **Firing**: cooldown countdown per weapon; a failed fire (no target) retries
  in 0.3 s instead of burning a full cooldown.
- **Persistent weapons** (Orbiting Relics, Astral Tome) are `Orbiter` nodes
  updated every frame instead of cooldown-fired; Iron Maiden spawns a
  temporary `maiden` orbiter cage.
- **Scheduled follow-ups** (nova echo, second sweep, bell ring trains) go
  through a `_pending` list — no SceneTreeTimers in the hot path.
- **Synergies** are flags in `world.synergies`, checked at the relevant hook
  (e.g. Soulfire Covenant adds burn params to Soul Bolt projectiles; Grave
  Harvest heals on marked kills via the `enemy_killed` signal).

## Enemy System

Enemies are pooled per-type and **ticked by GameWorld** (manager loop), not by
per-node `_process`. Behaviors: chase, wraith (sinusoidal drift), ranged
(approach/strafe/retreat + projectile), charger (windup telegraph → charge →
recover). Separation uses the grid at ~6 Hz per enemy, capped at 6 neighbor
checks. Status effects tick on a shared 0.45 s DoT clock.

## Damage Pipeline

`GameWorld.deal_damage(enemy, base, source, opts)` rolls crits
(player crit_chance + weapon crit_bonus), then `enemy.take_damage` applies
mark/poison vulnerability, knockback (scaled by knockback resistance), hurt
flash, damage numbers, and death. Death routes through
`GameWorld.on_enemy_died`: score, XP shards, elite drops, splitter splits,
death FX/dissolve, `enemy_killed` signal, pool release.

## Object Pooling

`scripts/core/object_pool.gd` — nodes stay in-tree, hidden, processing off
(`_pool_activate` / `_pool_deactivate`). Pooled: projectiles (one pool for
friendly + hostile), zones, FX, XP orbs, pickups, floating text, and each
enemy type. Caps live in `GameData` (220 projectiles, 90 hostile, 320 orbs,
36 zones, 90 FX, 48 texts) plus per-weapon `max_active` tracked by source
counters. XP orbs over cap merge their value into the nearest live orb.

## Spatial Grid

96 px cell dictionary rebuilt once per physics frame from live enemies.
All queries (`query_enemies`, `nearest_enemy`, `highest_health_enemy`,
`densest_cluster_pos`, separation, projectile hits, zone ticks) go through
it. Densest-cluster sampling checks ≤14 random candidates.

## Wave Director

Timer-driven: lerps spawn interval across each wave, respects max-alive,
weighted composition roll, elite roll, ring spawn placement. Boss wave spawns
the Castellan once and only ends via `boss_defeated`.

## Input

Keyboard (WASD/arrows), gamepad (left stick + buttons via the input map),
and touch. `TouchControls` (`scripts/ui/touch_controls.gd`) is a CanvasLayer
created by Main: it auto-enables only when a touchscreen exists, provides a
floating virtual joystick (left half) read by the Player as a movement
fallback, and a dash button that presses the real "dash" action. All menu
buttons and level-up cards are focusable with visible focus rings; screens
grab focus on open, so the whole flow is playable on controller/keyboard
alone (Enter/ui_accept activates, 1/2/3 still hotkey the cards).

## UI Flow

`main.gd` state machine: MENU → PLAYING ⇄ PAUSED / LEVEL_UP → GAME_OVER /
VICTORY. Pausing uses `get_tree().paused`; screens are
`PROCESS_MODE_ALWAYS`, the world is pausable. Level-ups queue (multi-level
pickups re-open the card screen). Restart frees the GameWorld and instantiates
a fresh one — sub-second loop. All widgets are built in code on a shared
StyleBoxFlat language (`ui_theme.gd`); rarity colors come from
`UpgradeData.RARITY_COLORS`.

## Debug Overlay

F3 (`debug_overlay.gd`): FPS, state, wave, enemy/projectile/orb/zone/FX
counts, player level/HP, owned weapons with levels vs cap, spawn budget, and
version label. Updates at 5 Hz.

## Game Feel

Camera smoothing + trauma shake (`camera_rig.gd`), hit-stop via
`Engine.time_scale` (boss death, hammer slams), hurt flashes, knockback,
dash ghost trail, XP magnet swirl, level-up burst, telegraphs for every
delayed hit (bone spikes, hammer, storm strikes, boss sigils, charges).

## Save System

JSON at `user://cursed_keep_save.json`, schema-defaulted on load (missing
keys backfilled), records merged through `SaveSystem.record_run` which
returns "new record" flags for the result screens.

## Performance Considerations (16+ weapons)

- No per-frame `get_nodes_in_group` anywhere; registries + grid only.
- Targeting only on fire; zones/clouds damage on tick intervals.
- Draw-based FX (single `_draw` per pooled node) instead of per-particle
  nodes; trails are 6-point ring buffers.
- Audio throttle: identical SFX within 45 ms are dropped.
- All caps above keep a 6–8 weapon endgame build bounded regardless of
  upgrade stacking.

## Testing

- `tests/test_project_compile_smoke.gd` — main scene + runtime scripts load.
- `tests/test_game_data_integrity.gd` — weapon/upgrade/enemy/wave cross-refs,
  icons, audio cues, offer-rule filtering (uses `tests/fakes/`).
- `scripts/tools/validate_project.gd` — standalone headless validator
  (`godot --headless --path . --script res://scripts/tools/validate_project.gd`)
  duplicating the data checks plus scene/folder existence for CI use.
