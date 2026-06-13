# Cursed Keep Survivors — Complete Bullet-Heaven Game Plan (v1.0 target)

Goal: take the existing prototype (one character, one stage, one ambient drone, no meta-progression)
to a **complete, end-to-end bullet-heaven game** at the level of Halls of Torment / Army of Ruin:
meta-progression, multiple characters and stages, weapon ascensions, achievements/codex, a full
synthesized music suite with a real mastering chain, and a Blender-based pre-rendered sprite
pipeline for all entities (the Halls of Torment look) — with **every asset authored in-repo**
(committed bpy build/render scripts for 3D-rendered sprites, hand-written SVG XML for UI/icons,
GDScript audio synthesis; no external packs, models, fonts, or samples).

How to execute: phases are designed to run **consecutively in fresh chat contexts** (e.g. via
`/claude-mem:do`). Each phase is self-contained: it lists what to build, exact copy-from patterns
(file:line as of 2026-06-12 — **re-grep if drifted**), a verification checklist, and anti-pattern
guards. Do not start a phase until the previous phase's checklist passed. Commit at least once per
phase.

---

## GLOBAL RULES (apply to every phase)

1. **Never modify `addons/godot_ai/`.** Before finalizing any phase run:
   `git diff --name-only -- addons/godot_ai` → must be empty. Keep the `_mcp_game_helper` autoload
   and `editor_plugins` entry in `project.godot`, and `godot-ai-LICENSE.txt`. (docs/CLAUDE_FABLE_5_HANDOFF.md, docs/PRESERVED_AGENT_TOOLING.md)
2. **Preserve the web audio fix**: `[audio] general/default_playback_type.web=1` in `project.godot`
   (Chrome freeze fix, commit 153a9df). Never remove it.
3. **Web export has `variant/thread_support=false`** (export_presets.cfg). NEVER use
   `Thread.new()` for anything that must run on web. Long work = chunked coroutines with
   `await get_tree().process_frame`.
4. **Tests pin content counts.** `tests/test_game_data_integrity.gd:21` asserts weapons == 18
   exactly. When a phase adds content, **update the assertion in the same commit, deliberately**,
   and extend the test to cover the new content class. Counts are a feature, not an obstacle.
5. **Verification per phase**: run both MCP suites (`project_compile_smoke`,
   `game_data_integrity`) via godot-ai `test_run` when the editor is open, plus
   `godot --headless --path . --script res://scripts/tools/validate_project.gd` (exit 0) when a
   Godot binary is on PATH. Extend `validate_project.gd` whenever a new data table is added.
6. **UI is code-built**, no editor-designed .tscn UIs. New screens copy `scripts/ui/pause_menu.gd`
   (simple) or `scripts/ui/level_up_screen.gd` (card grid) and use `UiTheme` helpers
   (`scripts/ui/ui_theme.gd:16-93`). Every interactive element needs keyboard/controller focus
   (UiTheme.make_button already wires focus + hover/click audio).
7. **All art is authored in-repo, two pipelines**: entities/props = pre-rendered sprite sheets
   produced by committed Blender scripts under `scripts/blender/` (Phase 3; final assets MUST be
   reproducible headless — Blender MCP sessions are for iteration, committed scripts are the
   source of truth); UI/icons/flat decals = hand-authored SVG XML under `assets/generated/`
   following existing conventions (64×64 weapon tiles with the `rect rx=10 fill="#141022"
   stroke="#43395f"` frame, 48×48 icon tiles). All audio = GDScript synthesis. No downloaded
   assets, fonts, samples, or models.
8. **Anti-pattern: inventing APIs.** Before using any engine class/method not already used in this
   repo, verify it exists: `ClassDB.class_exists("AudioEffectHardLimiter")`,
   `ClassDB.class_has_method(...)`, or check in-editor docs. Known traps listed per phase.
9. **Performance caps are law**: `GameData` constants (`MAX_PROJECTILES 220`,
   `MAX_ENEMY_PROJECTILES 90`, `MAX_XP_ORBS 320`, `MAX_ZONES 36`, `MAX_FX 90`,
   `MAX_FLOATING_TEXT 48`) and per-weapon `max_active`. New systems must pool
   (`scripts/core/object_pool.gd`) and respect caps. F3 overlay shows live counts.
10. **Save schema is merge-on-load** (`save_system.gd:27-40` backfills missing keys), so adding
    keys is always safe; removing/renaming keys is not — never rename existing keys.

---

## PHASE 0 — CURRENT STATE & ALLOWED APIs (reference; no work)

Consolidated from four discovery reports (sources: full reads of `scripts/core/*`,
`scripts/game/*`, `scripts/weapons/weapon_manager.gd`, `scripts/upgrades/upgrade_system.gd`,
`scripts/player/player.gd`, `scripts/enemies/*`, `scripts/data/*`, `scripts/ui/*`, `tests/*`,
`scripts/tools/validate_project.gd`, `.github/workflows/deploy-pages.yml`, `export_presets.cfg`,
all docs/*.md).

### What exists (do not rebuild)
- **Core loop**: 18 weapons (data: `scripts/data/weapon_data.gd`, fire routines:
  `scripts/weapons/weapon_manager.gd` `_fire_<id>()` dispatch), 8 enemies + boss
  (`scripts/data/enemy_data.gd`, `scripts/enemies/enemy.gd` behaviors chase/wraith/ranged/charger,
  `scripts/enemies/boss.gd` 3-phase Castellan), 112 upgrades in 6 kinds
  (stat/unlock/weapon/cursed/synergy/special, `scripts/data/upgrade_data.gd`), 12 synergies,
  7 cursed tradeoffs (level≥5 gate), 10 waves (`scripts/data/wave_data.gd`).
- **Engine services**: signal bus `scripts/core/game_events.gd:12-42`; pooling
  `scripts/core/object_pool.gd` (`acquire/release`, `_pool_activate/_pool_deactivate`); spatial
  grid + queries `scripts/game/game_world.gd:138-250` (`query_enemies`, `nearest_enemy`,
  `densest_cluster_pos`, …); damage pipeline `game_world.gd:256` (`deal_damage(enemy, dmg, source,
  opts)`); spawners `spawn_enemy/spawn_boss/spawn_projectile/spawn_zone/spawn_fx/spawn_xp_orb/
  spawn_pickup` (`game_world.gd:285-477`).
- **Player**: `scripts/player/player.gd` — `BASE_STATS` (20 keys incl. `damage_mult`,
  `cooldown_mult`, `area_mult`, `luck`, `projectile_bonus`, `regen`), `apply_stat_mods(mods)`
  (player.gd:241, mods = `{stat: {add/mult}}`), `gain_xp`, `heal`, `take_damage`, revive charges.
- **Weapons**: `weapon_manager.gd` — `owned{id:{level,cd,mods}}`, `unlock_weapon(id)` (:52),
  `add_mod(id,key,op)` (:62), `wstat(id,key)` effective-stat routing (:79-104),
  `start_run()` (:44) unlocks `WeaponData.STARTER_WEAPON` ("soul_bolt", weapon_data.gd:20),
  caps `DEFAULT_WEAPON_CAP=6` / `ABSOLUTE_WEAPON_CAP=8`.
- **Upgrades**: `upgrade_system.gd` — `roll_choices(3)` (:19, rarity weights × luck),
  `_is_valid` filter (:48-73), `apply(upgrade)` (:84-106).
- **Waves**: `wave_director.gd` — `start()`, `update(delta)`, schema
  `{name,duration,interval:[a,b],max_alive,comp:{id:weight},elite_chance,hp_mult,boss}`.
- **Flow**: `scripts/game/main.gd` state machine MENU→PLAYING→LEVEL_UP→GAME_OVER/VICTORY;
  `start_run()` (:81), `to_menu()` (:111), level-up pause (:142), records via
  `SaveSystem.record_run(stats)` on death (:170) / victory (:186).
- **Save**: `scripts/core/save_system.gd` — `user://cursed_keep_save.json`; keys: high_score,
  fastest_victory_time, total_runs, total_kills, best_wave, victories, sfx_volume, music_volume.
  `load_save()/save()/record_run(stats)->record flags`. Web = IndexedDB automatically.
- **Audio**: `scripts/core/audio_manager.gd` — ALL routed to `&"Master"` (no custom buses);
  16-voice player pool; `play(id, volume_db_offset, pitch_jitter)` (:137),
  `play_weapon(weapon_id)` (:161 → "w_"+id); 22 event SFX + 18 weapon SFX defined as synth-param
  dicts (:29-79); `_synth()` engine (:177-271): 22050 Hz mono 16-bit, sine pair + detune +
  partials + sub + shimmer + filtered noise + tanh drive + 2-comb echo + 1-pole LP;
  `_build_music_loop()` (:278-362): single 19.2 s ambient drone (A1 bed, bell tolls, sparse minor
  notes, drips, comb reverb), `LOOP_FORWARD`. Helpers `_mix_bell()` (:365), `_synth_note()` (:393).
  Music toggle only (`is_music_enabled/set_music_enabled`); `sfx_volume` save key is **unused**.
- **Art**: 137 SVG files in `assets/generated/{characters,enemies,weapons,icons,effects,
  environment,ui}`; import: CompressedTexture2D, svg/scale=1.0. Procedural draws: projectile
  kinds ×7 (`projectile.gd:183-226`), zone kinds ×7 (`zone.gd:192-325`), FX kinds ×13
  (`fx.gd:88-184`), arena decoration (`arena.gd`, incl. `_radial_glow_texture()` :246-257).
  Animation = procedural only (player.gd:134-157, enemy.gd:306-326); no AnimationPlayer, no
  sprite sheets.
- **UI**: main_menu / hud / level_up_screen / pause_menu / result_screen / debug_overlay /
  touch_controls, all CanvasLayer + code-built via `ui_theme.gd` palette (GOLD/PARCHMENT/BLOOD/
  SOUL/PANEL_BG).
- **Tests/CI**: `tests/test_project_compile_smoke.gd`, `tests/test_game_data_integrity.gd`
  (McpTestSuite, run via godot-ai `test_run`); `scripts/tools/validate_project.gd` (headless,
  exit-code gate in CI); `.github/workflows/deploy-pages.yml` (Godot 4.6.3, validate → export web
  → deploy Pages from master/fable5_test).
- **3D tooling (machine setup, 2026-06-12)**: the official Blender MCP (blender.org Lab) is
  installed and verified — Blender 5.1.1 at `C:\Program Files\Blender Foundation\Blender 5.1\`,
  extension `bl_ext.lab_blender_org.mcp` auto-starts a bridge on localhost:9876 (requires
  Blender's System ▸ Network ▸ "Allow Online Access" to stay enabled); Claude Code launches the
  MCP server via `uvx --from git+https://projects.blender.org/lab/blender_mcp.git@v1.0.0#subdirectory=mcp blender-mcp`.
  Tools: `execute_blender_code`, scene/object summaries, viewport screenshots and renders,
  Python API doc search. Headless renders (`blender --background --python <script> -- <args>`)
  need neither the addon nor online access.

### What is ABSENT (confirmed by discovery; this plan builds it)
- No meta-progression of any kind (no currency, no permanent upgrades, no unlock persistence).
- One playable character, hardcoded; one stage, hardcoded; one boss.
- One ambient music loop; no menu/combat/boss music, no stingers, no buses, no mastering, no
  ducking; `sfx_volume` unwired; no settings screen (music on/off only).
- No achievements, codex/bestiary, endless mode, difficulty tiers, reroll/banish, chests, gold,
  weapon ascensions/evolutions.

### Known API traps (verified)
- `tests/test_game_data_integrity.gd:21` → weapons must equal 18 until deliberately changed.
- `WeaponData.STARTER_WEAPON` is a const consumed by `weapon_manager.start_run()` (:44-45) and
  `validate_project.gd:126` — character system must parameterize, not reassign.
- `main.gd:63-67` mutes **bus 0** on focus loss — adding buses keeps Master as index 0; verify
  mute still applies globally after bus work.
- Godot cannot encode OGG at runtime. Generated audio = `AudioStreamWAV` (any `mix_rate`,
  `stereo=true` supported). Do not invent OGG writers.
- `AudioEffectLimiter` is deprecated in 4.x; use `AudioEffectHardLimiter` if
  `ClassDB.class_exists()` confirms, else fall back.

---

## PHASE 1 — AUDIO ENGINE: BUSES, MASTERING CHAIN, MUSIC DIRECTOR

**Why first**: every later phase registers cues into this system; user priority is
high-production audio.

### What to implement
1. **Bus architecture** (new file `scripts/core/audio_buses.gd`, called from
   `AudioManager._ready()` before players are created):
   - Create buses via `AudioServer.add_bus()` / `set_bus_name()` / `set_bus_send()`:
     `Music`, `SFX`, `UI` — all sending to `Master`.
   - Effects via `AudioServer.add_bus_effect(bus_idx, effect)`:
     - Master: `AudioEffectCompressor` (gentle glue: ratio ~3, threshold ~ -12 dB) then
       `AudioEffectHardLimiter` (verify with `ClassDB.class_exists("AudioEffectHardLimiter")`;
       fallback `AudioEffectLimiter`). Ceiling ~ -1 dB.
     - SFX: `AudioEffectCompressor` (tame spikes), `AudioEffectReverb` (room_size ~0.45,
       wet ~0.12 — the synth already bakes per-sound echo; keep wet LOW).
     - Music: no effects initially (headroom managed in render).
   - Re-route players: in `audio_manager.gd:101` set weapon/combat players `bus=&"SFX"`; UI cues
     (ui_click/ui_hover) via a dedicated small pool on `&"UI"`; `_music_player.bus=&"Music"`
     (:106).
   - **Wire `sfx_volume`** (save key exists, unused): `apply_volumes()` (:114) sets Music bus
     volume from `music_volume` and SFX+UI bus volume from `sfx_volume` via
     `AudioServer.set_bus_volume_db(idx, linear_to_db(v))`. Keep per-player offsets.
   - **Scripted ducking** (no sidechain API risk): AudioManager tracks SFX plays/sec; when
     heavy (e.g. >8 plays in 0.5 s) lerp Music bus −3.5 dB, recover over ~0.8 s. Optional
     upgrade: `AudioEffectCompressor.sidechain` on Music bus — ONLY if the property is confirmed
     in-editor.
2. **MusicDirector autoload** (new `scripts/core/music_director.gd`, register in `project.godot`
   after AudioManager):
   - API: `play_state(state: StringName)` with states `menu`, `combat_calm`, `combat_tense`,
     `combat_frenzy`, `boss`, plus `stinger(name)` for `victory`/`defeat`.
   - Two `AudioStreamPlayer`s on Music bus for crossfades (~1.8 s equal-power fade).
   - State hookups: Main `to_menu()`/`start_run()` (main.gd:81,111); wave thresholds via
     `GameEvents.wave_started` (waves 1-4 calm, 5-8 tense, 9 frenzy); `boss_spawned` → boss;
     `victory`/`game_over` → stingers. Copy signal-connection style from `hud.gd:136-142`.
   - **Fallback rule**: until a track is rendered, keep playing the existing drone loop
     (`_build_music_loop()` result). The game must sound complete at every moment.
3. **Chunked music renderer** (new `scripts/core/music_synth.gd`):
   - Pure-function synthesis into `PackedFloat32Array`, **time-sliced**: a coroutine renders N
     samples per frame within a ~6 ms budget, `await get_tree().process_frame` between chunks
     (web-safe; NO Thread).
   - Target format: **32000 Hz, stereo, 16-bit** `AudioStreamWAV` (`stereo=true`,
     `mix_rate=32000`, `LOOP_FORWARD`, loop_end=frames). First task: measure GDScript
     samples/sec on desktop and log it; if a full track render exceeds ~25 s of background time,
     drop to 24000 Hz stereo (decision recorded in code comment).
   - **Caching**: serialize rendered PCM (`StreamPeerBuffer` → `FileAccess`) to
     `user://music_cache_v<N>.bin` keyed by a synth-version int + track id; load instantly on
     later boots. Bump N whenever composition changes.
4. **Compose 5 tracks + 2 stingers** (all in `music_synth.gd`; reuse/extend the proven helpers —
   copy `_mix_bell()` audio_manager.gd:365-384 and `_synth_note()` :393-436 into the new module):
   - Musical identity: D minor / A minor modal, ~72 BPM doom-y pulse. Layers available to the
     composer: drone bed (detuned saw/sine pairs), low pulse "taiko" (sine thump + noise click),
     funeral bell, choir-ish pad (stacked detuned sines w/ slow attack), lead motif
     (soft-square `_synth_note` voice), arpeggio harp (short plucks), risers (filtered noise
     sweeps).
   - `menu` 36 s loop: drone + bell + sparse motif (current drone DNA, richer).
   - `combat_calm` / `combat_tense` / `combat_frenzy`: **three full-mix variants of the same
     48 s, same-key composition** (crossfaded by MusicDirector — NOT synced stems; avoids
     drift risk). Each adds layers/percussion density.
   - `boss` 40 s loop: half-time heavy pulse, bell every bar, dissonant motif.
   - `victory` / `defeat` stingers ~8 s one-shots.
   - Mastering inside render: per-layer gain staging, soft-knee tanh on the bus sum, gentle
     high-shelf, comb-pair reverb (copy pattern audio_manager.gd:337-343), normalize to peak
     0.85, ~0.5 s loop-boundary crossfade baked in so loops are click-free.
5. **Render order**: boot = SFX (unchanged) + existing drone (instant) → background-render
   menu → swap in → combat_calm → tense → frenzy → boss → stingers → write cache.

### Verification checklist
- [ ] `project_compile_smoke` + `game_data_integrity` suites pass; validator exit 0.
- [ ] In-editor: AudioServer has Master/Music/SFX/UI; Master keeps index 0; focus-loss mute
      (main.gd:63-67) still silences everything.
- [ ] Menu→run→wave 5→wave 9→boss→victory plays distinct music with audible crossfades; defeat
      stinger on death; no clicks at loop points (listen 2 full loops).
- [ ] Second boot loads music from cache (log line) with no re-render.
- [ ] Web export boots without freeze; music starts after first input (autoplay policy);
      `default_playback_type.web=1` untouched.
- [ ] F3 shows stable FPS during background rendering (budget respected).

### Anti-pattern guards
- No `Thread.new()`; no OGG encoding; no `AudioStreamGenerator` for music (stream playback type
  on web is forced — pre-rendered WAV only).
- Do not raise SFX reverb wet above ~0.15 (sounds already bake echo).
- Do not delete `_build_music_loop()` — it is the fallback and proof-of-life.

---

## PHASE 2 — META-PROGRESSION: GRAVE MARKS, THE SANCTUM, LEVEL-UP QoL

### What to implement
1. **Currency "Grave Marks"**: elites drop a gold-coin pickup (extend
   `game_world.gd:on_enemy_died` :312 where elite health/magnet drops roll; extend
   `pickup.gd` kinds — copy `spawn_pickup(pos, kind)` pattern game_world.gd:458), boss drops a
   pile; end-of-run payout `floor(score/400) + 12*waves_cleared + 60*victory`. Show marks
   earned on result screens (`result_screen.gd:70-93`).
2. **Save keys** (extend defaults dict `save_system.gd:10-20`; merge-on-load makes this safe):
   `grave_marks:0`, `meta_upgrades:{}` (id→rank), `lifetime_marks:0`.
3. **MetaData table** (new `scripts/data/meta_data.gd`, const like upgrade_data): ~14 permanent
   upgrades, each `{id, name, desc, icon, max_rank, cost(rank) base*1.6^rank, stats per rank}`
   mapping onto existing `BASE_STATS` keys via `apply_stat_mods` — e.g. vitality (+10 max_health/
   rank ×5), power (+4% damage_mult ×5), alacrity (−3% cooldown_mult ×5), reach (+5% area_mult),
   haste (+4% move_speed), fortune (+3 luck), greed (+10% marks gain), insight (+5% xp_mult),
   bulwark (+2 armor), mending (+0.3 regen), second_wind (revive charge ×1),
   scholar (+1 reroll charge ×3), censor (+1 banish charge ×3), swift_start (start at level 2/3).
4. **MetaSystem autoload** (new `scripts/core/meta_system.gd`): `rank(id)`, `can_buy(id)`,
   `buy(id)` (deduct, save), `apply_to_run(player, weapon_manager, upgrade_system)` — called in
   `game_world.gd:_ready()` right after player creation; reroll/banish charges handed to
   UpgradeSystem.
5. **Sanctum shop screen** (new `scripts/ui/sanctum_screen.gd` + scene): card grid copying
   `level_up_screen.gd:55-106` card builder; rank pips, cost, marks balance; entered from main
   menu button "THE SANCTUM" (copy button wiring `main_menu.gd:46-50`). Purchase SFX (register
   new cue in `audio_manager.gd:29-79`, copy an entry like :61).
6. **Level-up QoL**: add REROLL and BANISH buttons to `level_up_screen.gd` (charges from meta;
   banish removes upgrade id from this run's pool — add an `banished:{}` dict checked in
   `upgrade_system.gd:_is_valid` :48; reroll calls `roll_choices(3)` again). Keyboard: R / B.
   Also add SKIP (+small heal) always available.
7. **New SFX cues**: `coin_pickup`, `marks_payout`, `meta_purchase`, `reroll`, `banish`
   (entries in the SFX dict, synth params tuned per Phase-1 chain).
8. **Icons**: `assets/generated/icons/` — coin, sanctum sigil, reroll, banish + 14 meta icons
   (48×48 tile frame convention).

### Verification checklist
- [ ] Suites + validator pass; extend `validate_project.gd` to validate MetaData (ids unique,
      icons exist, stats keys ∈ BASE_STATS — copy its upgrade checks pattern).
- [ ] Extend `game_data_integrity`: meta table validity; banish actually filters; reroll
      consumes charge.
- [ ] Manual: earn marks in a run → buy vitality → next run starts with higher max HP (F3 +
      HUD HP confirm); marks/purchases persist across restart.
- [ ] Web: marks persist in IndexedDB (refresh browser, balance intact).

### Anti-pattern guards
- Meta effects flow ONLY through `apply_stat_mods` / weapon_manager / upgrade_system charges —
  no parallel stat code paths.
- Never write save keys outside SaveSystem; never rename existing keys.
- Sanctum prices must be earnable: first 3 purchases reachable within ~2 average runs.

---

## PHASE 3 — BLENDER PRE-RENDER SPRITE PIPELINE (entities go 3D-rendered)

**Why here**: this is how Halls of Torment gets its look — 3D models pre-rendered to 2D sprite
sheets. The pipeline must exist BEFORE characters (Phase 4) and stages (Phase 5) so their entity
art is authored through it once, not drawn as SVG and discarded later. Tooling is already set up
(see Phase 0 "3D tooling"): use Blender MCP interactively to iterate on a model, then bake the
result into committed scripts — **a final asset that can't be regenerated headless doesn't exist**.

### What to implement
1. **`scripts/blender/` toolkit** (all committed, pure bpy, deterministic — fixed seeds, no
   wall-clock randomness):
   - `studio.py` — shared render studio builder: orthographic camera pitched ~50°, 8 yaw stops
     (45° steps), 3-point light rig (warm key, cool fill, rim for silhouette readability), EEVEE
     with fixed sample count, transparent film, frame-size presets (96px entities / 160px bosses
     / 64px pickups).
   - `palette.py` — shared material library matching the game's hex palette (parchment, gold,
     soul-blue `7fd4ff`, blood, curse-purple) so all entities read as one art style.
   - `entities/<id>.py` — one builder per entity producing mesh + simple armature with a 4-frame
     walk action (procedural blockout: skin/mirror/subsurf modifiers, then decimate; no sculpting
     dependence).
   - `render_sprites.py` — headless entry point:
     `blender --background --python scripts/blender/render_sprites.py -- --entity <id> | --all`.
     Renders idle (1) + walk (4) frames × 8 directions, packs ONE sheet PNG per entity
     (rows = direction, cols = frame) into `assets/generated/prerendered/<id>.png` + a
     `<id>.json` manifest `{frame_w, frame_h, dirs, frames, anchor}`.
2. **Godot integration**:
   - New `scripts/game/sheet_sprite.gd` helper: given sheet + manifest, sets `Sprite2D`
     `region_rect` from (direction, frame). Facing = 8-way snap of velocity; frame clock driven
     by the existing `_phase` accumulators so the procedural bob/squash in `_animate()`
     (player.gd:134-157, enemy.gd:306-326) layers on top unchanged.
   - Migration flag, not big-bang: entity/character defs gain optional
     `"sheet": "res://assets/generated/prerendered/<id>.png"`; when absent the existing SVG
     `"sprite"` path is used. The game stays shippable at every commit.
3. **Convert the existing roster as proof**: wardkeeper + all 8 enemies + Cursed Castellan
   (160px, extra cast-pose row). Iterate looks via Blender MCP (`execute_blender_code`,
   viewport screenshot/thumbnail tools), bake into `entities/*.py`, render, wire flags.
4. **Budgets** (record actuals in the commit message): frame 96×96 (boss 160), per-sheet PNG
   ≤ ~1.5 MB, total repo growth this phase ≤ ~15 MB. CI does NOT need Blender — rendered PNGs
   are committed; note this in `docs/ART_PIPELINE.md`.
5. **Validator/tests**: extend `validate_project.gd` — every def with `sheet` has PNG + JSON and
   manifest dims divide the sheet dims; extend `game_data_integrity` to assert the converted
   roster (≥10 sheets).

### Verification checklist
- [ ] Suites + validator pass with the new sheet checks.
- [ ] `render_sprites.py --all` regenerates every sheet from a clean checkout, headless, with
      Blender GUI closed (no MCP dependency).
- [ ] In-game: converted entities animate with 8-way facing; collision feels identical (defs'
      `radius`/`scale` untouched); F3 shows no FPS change at wave 9 (region swap is free).
- [ ] Before/after screenshot per entity committed to the PR description.

### Anti-pattern guards
- Never hand-edit a rendered PNG or leave a change only in a Blender MCP session / .blend file —
  regenerate from the committed script or it didn't happen.
- Don't delete an entity's SVG until its sheet ships (the `sheet` flag is the migration switch).
- Fit renders to the existing collision tuning — never change enemy def `radius`/`scale` to fit
  a render.
- Sprite anchor matches current Sprite2D centering; don't introduce per-entity offsets in code.
- Headless render args go after a standalone `--`; don't pass them before it (Blender eats them).

---

## PHASE 4 — PLAYABLE CHARACTERS (5)

### What to implement
1. **CharacterData table** (new `scripts/data/character_data.gd`): 5 entries
   `{id, name, title, desc, sprite, portrait, starting_weapon, stat_mods (apply_stat_mods
   format), passive {id, desc} , unlock {kind, value, desc}}`:
   - `wardkeeper` (default, soul_bolt, balanced) — unlocked.
   - `gravedigger` (blood_scythe; +20% max HP, −10% move; passive: +1 HP on kill chance) —
     unlock: 500 total kills.
   - `pale_archer` (phantom_bow; +15% proj speed, −20% max HP; passive: +10% crit) — unlock:
     reach wave 7.
   - `ember_witch` (cursed_flame; +15% area, slower dash; passive: burns linger +1 s) — unlock:
     win once.
   - `relic_warden` (orbiting_relics; +10 armor, −10% damage; passive: +1 projectile_bonus) —
     unlock: buy 5 Sanctum ranks.
   Passives implement via stat_mods where possible; bespoke ones get explicit hooks (e.g.
   gravedigger heal-on-kill listens to `GameEvents.enemy_killed` in player.gd — copy signal
   pattern from hud.gd:136-142).
2. **Parameterize the starter weapon**: change `weapon_manager.start_run()`
   (weapon_manager.gd:44-45) to `start_run(starting_weapon: String = WeaponData.STARTER_WEAPON)`;
   GameWorld passes the selected character's weapon. Update `validate_project.gd:126` expectation
   to validate every character's `starting_weapon` exists.
3. **Character select screen** (new `scripts/ui/character_select.gd`): card row (copy
   level_up_screen card builder), portrait, stats summary, locked cards show unlock condition;
   selection stored in save (`selected_character`); reached from main menu before run (BEGIN THE
   VIGIL → select → start). Save keys: `unlocked_characters:["wardkeeper"]`,
   `selected_character:"wardkeeper"`.
4. **Apply at run start**: in `game_world.gd:_ready()` after MetaSystem: look up character,
   `player.apply_stat_mods(char.stat_mods)`, set sprite texture
   (`player.gd:53` `$Sprite`), pass starter to `weapon_manager.start_run(...)`.
5. **Unlock evaluation**: MetaSystem (or new ProgressSystem) checks unlock conditions on
   `record_run` + relevant events; toast "CHARACTER UNLOCKED" (simple CanvasLayer banner —
   copy HUD wave-banner pattern hud.gd:113-119). SFX cue `char_unlock`.
6. **Art (via the Phase-3 pipeline)**: 4 new entity builder scripts in
   `scripts/blender/entities/` + rendered sheets, and 5 placeholder portraits (~128px busts
   rendered from the same models with the shared studio lighting; polished in Phase 8) —
   palette-consistent (parchment/gold/soul-blue accents per character identity).

### Verification checklist
- [ ] Suites + validator pass; new integrity checks: 5 characters, sprites/portraits exist,
      starting weapons valid, stat_mod keys ∈ BASE_STATS, unlock kinds known.
- [ ] Each character starts with its weapon (HUD loadout row confirms), stat mods visible
      (F3/HP bar), passive observably fires.
- [ ] Locked → fulfill condition → unlock toast → persists after restart.
- [ ] Controller-only navigation through select screen works (focus ring).

### Anti-pattern guards
- Do NOT reassign `WeaponData.STARTER_WEAPON`; the const stays as the default.
- Character stat mods go through `apply_stat_mods` — never mutate `BASE_STATS`.
- Test fakes (`tests/fakes/fake_weapon_manager.gd`) may need the new `start_run` signature —
  update them, don't bypass.

---

## PHASE 5 — STAGES & BOSSES (3 stages, 3 bosses)

### What to implement
1. **Restructure waves per stage**: `wave_data.gd` becomes
   `const STAGES := {"cursed_keep": [ ...existing 10 waves... ], "drowned_crypts": [...],
   "blighted_garden": [...]}` + `static func get_stage_waves(stage_id)`. Keep a
   `const WAVES := STAGES["cursed_keep"]` alias so existing references compile during migration;
   update `wave_director.gd` `start(stage_id)` / `current_wave()` to read the stage table.
   Update tests/validator in the same commit (each stage: ≥10 waves, exactly 1 boss wave).
2. **StageData table** (new `scripts/data/stage_data.gd`): `{id, name, tagline, desc, boss_id,
   palette {floor, wall, trim, fog, torch}, props {tile_a, tile_b, crack, sigil, pillar, torch},
   ambient {fog_density, dust}, music_tint {root_offset, brightness}, unlock {kind, value},
   icon/banner art path}`.
3. **Parameterize Arena** (`scripts/game/arena.gd`): replace hardcoded colors/prop paths with
   StageData lookups (floor ColorRect color, wall colors, torch glow color via
   `_radial_glow_texture()` :246-257, fog gradient color, prop SVG paths). Default = cursed_keep
   (zero visual change for stage 1 — verify by eye).
4. **Two new stages**:
   - **The Drowned Crypts** (teal/green water palette): new enemies `drowned_thrall` (chase,
     slow+tanky), `tide_caller` (ranged, slowing shots — extend hostile projectile params),
     `crypt_leech` (fast, lifesteal contact). Boss **The Drowned Abbot**.
   - **The Blighted Garden** (rot-green/amber): new enemies `spore_shambler` (splits into
     spore_mites), `thorn_stalker` (charger), `rot_priest` (ranged buffer — heals nearby, new
     small behavior). Boss **The Gardener of Graves**.
   New enemy recipe per discovery (enemy_data entry + scene copying `scenes/enemies/
   BoneCrawler.tscn` 12-line pattern + pre-rendered sheet via the Phase-3 pipeline + wave comp
   entries + behavior dispatch in `enemy.gd:_behavior_move` if new). ~7 new enemy builder
   scripts in `scripts/blender/entities/`; recolor variants = `palette.py` material swaps,
   re-rendered (cheap).
5. **Boss generalization**: `enemy_data.gd` `BOSS` → `const BOSSES := {"cursed_castellan":
   {...existing...}, "drowned_abbot": {...}, "gardener_of_graves": {...}}` (keep `BOSS` alias to
   castellan during migration). New boss scripts extend `boss.gd` overriding the phase-attack
   dispatch (Abbot: drowning zones + radial bursts + summon thralls; Gardener: thorn-trap rings +
   charge + spore minions — reuse `spawn_zone` kinds `sigil`/`trap`/`cloud` and
   `spawn_enemy_projectile`). `game_world.spawn_boss()` (:299) takes the stage's `boss_id`.
   `GameData` exposes `boss_def(id)`.
6. **Stage select screen** (new `scripts/ui/stage_select.gd`): banner cards (stage art SVG
   ~480×220), unlock conditions (stage 2: win stage 1; stage 3: win stage 2), per-stage personal
   bests (new save keys `stage_records:{}`). Flow: BEGIN THE VIGIL → character select → stage
   select → run. Save: `unlocked_stages`, `selected_stage`.
7. **Per-stage music tint**: MusicDirector passes StageData.music_tint to renderer (root
   transpose ±2 semitones, brightness = LP cutoff scale); re-render combat set on stage switch
   (cache per stage id; render during stage select/menu with the Phase-1 fallback rule).
8. **Per-stage records on result screens** + `record_run` extension (per-stage best wave/score —
   new nested save key, merge-safe).
9. **Environment art**: 2 new prop sets — flat decals (floor a/b, crack, sigil) hand-authored
   SVG; dimensional props (pillar, torch variants) rendered via the Phase-3 pipeline —
   + 2 stage banners, hand-authored SVG.

### Verification checklist
- [ ] Suites + validator extended: stages table valid (palette/prop/boss refs exist), every
      stage wave table valid, every boss def has scene+sprite, new enemies fully wired.
      Update count assertions deliberately (enemies ≥ 14, waves per stage).
- [ ] Stage 1 looks/plays IDENTICAL to before parameterization (screenshot compare).
- [ ] Full clear of each new stage in-editor (use F3; debug a fast-kill cheat behind
      `OS.is_debug_build()` if needed for testing only).
- [ ] Each boss: 3 phases observable, enrage, defeat → victory screen + per-stage record saved.
- [ ] Web export: all 3 stages playable, FPS acceptable wave 9.

### Anti-pattern guards
- Keep migration aliases (`WAVES`, `BOSS`) until all references are updated in the same phase,
  then remove the aliases + fix tests in one commit.
- New enemy behaviors go in the existing `enemy.gd` dispatch — no per-enemy script forks except
  bosses.
- Respect spawn caps: new stage waves must keep `max_alive ≤ 135` (current proven ceiling).

---

## PHASE 6 — CONTENT DEPTH: ASCENSIONS, CHESTS/PICKUPS, ENDLESS, CURSE TIERS

### What to implement
1. **Weapon Ascensions** (one per weapon, 18 total): add `"ascension"` block to each weapon def
   in `weapon_data.gd`: `{name, desc, icon, requires_level: 8, requires_other: optional
   weapon/synergy id, wmods {…}, behavior: optional flag}`. WeaponManager: on `add_mod` reaching
   level ≥ 8 (+ condition), weapon enters ascended state (`owned[id]["ascended"]=true`), applies
   wmods, swaps cue to `wa_<id>` if defined, recolors projectiles (pass tint through existing
   `color` param). 6 bespoke behavior flags implemented in fire routines (e.g. soul_bolt →
   "Soulstorm" volley homing; grave_bell → echo toll; saints_hammer → triple drop — copy each
   weapon's own `_fire_*` and extend); remaining 12 = big stat jumps + visual upgrade.
   **Ascension ceremony**: full-screen flash + new FX kind + cue `ascension`; offered as a
   special card on level-up when eligible (extend `roll_choices` to inject it — copy the
   special-kind handling in `upgrade_system.gd:84-106`).
2. **Chests**: elites ≥ wave 5 drop chance, boss always; chest pickup → pause-less ceremony
   panel granting 1/3/5 weighted random owned-weapon upgrades (reuse upgrade pool filtered to
   kind=="weapon" for owned weapons). New pickup kind + art + cues (`chest_drop`, `chest_open`,
   `chest_jackpot`).
3. **New pickups**: `bomb` (clears hostile projectiles + 250 area damage via
   `area_damage` game_world.gd:268), `frost` (global 3 s slow — iterate `enemies_alive`,
   `apply_slow(0.45, 3.0)` enemy.gd:238-269 pattern), rare drops + coin from Phase 2. Pickup art
   is procedural-first (pickup.gd already draws procedurally — extend its draw for new kinds);
   Phase 8 replaces them with 64px pre-rendered sprites.
4. **Endless Vigil**: on victory, button "CONTINUE THE VIGIL" → endless scaling: waves cycle the
   stage's waves 7-9 with `hp_mult *= 1.18` per cycle, `elite_chance` +0.02 (cap 0.5), interval
   floor 0.3; boss respawns every 5 cycles with +60% HP. Track `endless_minutes` per-stage best.
   `run_stats()` gains `endless: bool`.
5. **Curse Tiers (difficulty)**: stage select exposes tiers 0-5 after first win on that stage:
   per tier +12% enemy hp/speed/damage (`world.enemy_mods` pattern — multiply at spawn like
   `upgrade_system.gd` enemy_mods :89-92) and +20% marks payout per tier. Save per-stage best
   tier cleared.
6. **HUD additions**: combo kill counter (kills within 1.5 s window, juicy count-up), endless
   cycle indicator, curse tier badge.

### Verification checklist
- [ ] Suites + validator: every weapon has a valid ascension block (icon exists, wmods keys ∈
      base, requires refs valid); chest/bomb/frost pickups wired; tier math covered by a unit
      check (tier 3 spawn hp == base*hp_mult*1.12^3).
- [ ] Manual: ascend soul_bolt and 2 others — card appears at level 8, ceremony plays, DPS
      visibly jumps, projectile visuals change.
- [ ] Endless reaches cycle 2+ without errors; caps hold (F3 counts ≤ limits).
- [ ] Curse tier 5 run is hard but boots fine on web.

### Anti-pattern guards
- Ascended fire routines must respect `max_active` and global caps — no uncapped projectile
  storms (the per-source counter `_source_counts` in game_world.gd:362-394 is the law).
- Chest ceremony must not double-pause with level-up flow (Main state machine owns pausing —
  route through Main like LevelUpScreen does, main.gd:142-156).
- Don't add new save keys outside SaveSystem defaults.

---

## PHASE 7 — ACHIEVEMENTS, UNLOCK QUESTS, CODEX

### What to implement
1. **AchievementData table** (new `scripts/data/achievement_data.gd`): ~28 entries
   `{id, name, desc, icon, condition {kind, value, …}, reward {kind: none|character|cosmetic
   hint, …}}`. Condition kinds: total_kills, kills_with_weapon, reach_wave_stage, win_stage,
   win_character, win_curse_tier, ascend_weapon, no_hit_wave, level_reached, marks_lifetime,
   endless_minutes, chests_opened, synergies_in_run.
2. **ProgressSystem autoload** (new `scripts/core/progress_system.gd`): counters fed by existing
   signals (`enemy_killed` has `source_id` for weapon attribution; `wave_started`;
   `player_hurt` for no-hit tracking; `upgrade_chosen`; run end via `record_run` wrapper).
   Persist counters dict + `achievements:{id:true}` in save. Character/stage unlock conditions
   from Phases 3-4 migrate INTO this system (single source of truth).
3. **Toast UI**: queue-based banner (copy HUD wave banner hud.gd:113-119), cue
   `achievement_toast`.
4. **Achievements screen** (grid, locked/unlocked, progress fractions) from main menu.
5. **Codex screen** (4 tabs): Bestiary (enemies seen — record on first spawn of each id into
   save `codex_seen.enemies`), Armory (weapons used + ascensions), Relics (upgrades taken ever),
   Records (lifetime stats from save). Tab UI: button row + panel swap (copy pause_menu
   structure; reuse data tables for entries; locked entries show "???" silhouette via modulate).
6. **Icons**: 28 achievement SVGs (48×48 frame) + codex tab icons.

### Verification checklist
- [ ] Suites + validator: achievement table valid (unique ids, icons exist, condition kinds
      known, rewards reference real content); codex_seen recording covered by integrity test
      (spawn enemy → seen).
- [ ] Trigger 3 achievement types live (kill count, wave reach, win) — toast + persist.
- [ ] Character unlock conditions still work, now via ProgressSystem (regression check).
- [ ] Controller navigation through both screens.

### Anti-pattern guards
- ProgressSystem only LISTENS to existing GameEvents — do not add gameplay-side calls into it
  (keeps gameplay decoupled).
- Counters update at most once per event; no per-frame save() calls (save on run end + on
  unlock only).

---

## PHASE 8 — ART POLISH PASS (animation breadth + world dressing)

### What to implement (3D renders via the Phase-3 pipeline; SVG only for UI/icons/flat decals)
1. **Animation breadth**: new sheet rows via the pipeline — attack/cast rows for ranged enemies
   and all 3 bosses, a 1-frame hit-flinch row, dash pose for player characters. Extend the
   manifest schema (`rows: {walk, cast, ...}`) and `sheet_sprite.gd` row selection.
2. **Boss phase visuals**: per-phase material variants rendered as separate rows (crown ignites
   at enrage etc.) + bigger death sequence (multi-burst FX choreography using existing fx kinds).
3. **Catch-up + pickups**: any entity still on SVG fallback gets its model (grep defs for missing
   `sheet` keys); chest/coin/bomb/frost pickups rendered at 64px with a sparkle frame each.
4. **Stage props pass**: dimensional props (statues, bones, wells, roots, gate pieces) rendered
   via the pipeline, 6-10 per stage with baked drop shadows; flat decals (cracks, sigils) stay
   SVG; arena scatter code already supports lists (arena.gd).
5. **Portraits**: ~256px character busts rendered from the Phase-4 models with studio lighting
   (select screen + codex), replacing any placeholder portraits.
6. **UI art (SVG)**: redrawn emblem, per-stage menu backgrounds (1280×720), sanctum/codex header
   crests, upgrade-card corner filigree (StyleBox stays; filigree = small SVG corner sprites).
7. **VFX pass**: 3 new FX kinds where impact is weak (`crit_flash`, `ascend_burst`,
   `chest_sparkle`) copying fx.gd kind pattern (:135-141); projectile draw upgrades (brighter
   cores, longer trails for ascended).
8. **Consistency audit**: every icon/sheet referenced by every data table exists (validator
   covers existence; eyeball a contact sheet — load all icons + sheets into a debug grid scene
   behind `OS.is_debug_build()`).

### Verification checklist
- [ ] Validator + suites pass (sheet/manifest + icon checks across all content).
- [ ] `render_sprites.py --all` still regenerates everything from a clean checkout.
- [ ] Editor screenshot set: menu, each stage arena, each boss (each phase), level-up cards,
      sanctum, codex — visually coherent, no missing-texture squares, no SVG-fallback entities
      left unintentionally.
- [ ] Web bundle size delta recorded; total prerendered art within the ~30 MB project budget.

### Anti-pattern guards
- All Phase-3 guards still apply (regenerable-or-it-doesn't-exist, no radius changes, anchors).
- Never change viewBox dimensions of remaining SVGs (icons/decals are layout-tuned).
- No raster embeds, no external fonts, no `<image>` tags in SVGs (ThorVG renders vectors only —
  embedded rasters bloat and may not render).

---

## PHASE 9 — SFX PRODUCTION PASS (high-production audio, part 2)

### What to implement
1. **Re-render all SFX at 32000 Hz** (match music): change `SAMPLE_RATE` in audio_manager.gd
   (:18) — re-tune `lp`/`nlp` params upward where sounds relied on the old 11 kHz ceiling
   (brighter shimmer/sparkle now possible). A/B every cue.
2. **Variant round-robin**: for the ~10 highest-traffic cues (enemy_hit, enemy_death, xp_pickup,
   w_soul_bolt, coin_pickup, …) define 3 param-jittered variants pre-rendered at boot; `play()`
   cycles them (kills machine-gun monotony beyond pitch jitter).
3. **Loudness pass**: compute per-cue RMS at render; normalize categories to targets
   (UI −20 dBFS, weapons −16, impacts −14, boss/stingers −12) instead of hand-tuned `vol` —
   keep per-play `volume_db_offset` for art direction.
4. **Layered hero cues**: rebuild 6 marquee sounds as 2-3 layer composites (transient click +
   body + tail), e.g. saints_hammer (sub thump + stone crack noise + bell tail), boss_death
   (downsweep + choir pad gust + debris noise), chest_open (latch click + harp gliss + shimmer).
   The `_synth()` engine already supports all needed layers — sum multiple `_synth_params`
   renders into one buffer (new small helper `_synth_layered(list)`).
5. **Coverage audit**: every game event has a cue — new ones from Phases 2-7 (`coin_pickup`,
   `marks_payout`, `meta_purchase`, `reroll`, `banish`, `char_unlock`, `stage_select`,
   `chest_*`, `ascension`, `achievement_toast`, `boss_phase`, `frost`, `bomb`, per-boss spawn
   variants `boss_spawn_<id>`). Integrity test enumerates required cue ids vs SFX dict (extend
   the existing `w_<id>` audio check in test_game_data_integrity.gd:19-40 pattern).
6. **Ducking + mix verify**: tune Phase-1 ducking thresholds against frenzy gameplay; confirm
   limiter never slams (log gain reduction in debug overlay while testing, then remove the log).
7. **Startup budget check**: measure boot synth time desktop + web; if > ~2.5 s on web, move
   variant rendering into the Phase-1 chunked background path.

### Verification checklist
- [ ] Suites + validator green; cue-coverage test passes.
- [ ] 10-minute frenzy session: no clipping/pumping artifacts, music audible under fire, duck
      recovery smooth.
- [ ] Boot time web ≤ baseline + 1 s.
- [ ] A/B note in commit message: list cues materially improved.

### Anti-pattern guards
- Keep the 45 ms repeat throttle (audio_manager.gd:89) — variants don't replace it.
- Don't exceed 16-voice pool without measuring; raise only with evidence.

---

## PHASE 10 — SETTINGS, UX & GAME-FEEL POLISH

### What to implement
1. **Settings screen** (menu + pause entry): Music slider, SFX slider (wire to Phase-1 buses;
   keys `music_volume`/`sfx_volume` already persist), Screen-shake intensity slider
   (scale `screen_shake_requested` consumer in camera_rig), Damage numbers toggle
   (gate `show_damage_number` game_world.gd:274), Reduced-flash mode (cap flash/modulate
   intensities), Show-timer toggle, Fullscreen toggle (desktop only:
   `DisplayServer.window_set_mode`; hide on web like the quit button main_menu.gd:64).
   New save keys with defaults.
2. **How-to-play screen**: replaces/extends the controls panel (main_menu.gd:92-115) with paged
   genre primer (move/dash, XP, upgrades incl. reroll/banish, ascensions, curses, marks/sanctum).
3. **Juice pass**: pickup magnet trails, level-up shockwave already exists — add screen-edge
   danger vignette pulse at low HP, gold sparkle on coin pickup, chest open slow-zoom (camera
   punch via existing CameraRig), kill-combo pitch ramp on xp_pickup cue (pass pitch offset
   through `play()`), boss intro letterbox banner with title card (boss def has `title`).
4. **Pause menu upgrade**: show current build (owned weapons + levels + taken upgrades grid —
   read `weapon_manager.owned`, `upgrade_system.taken`).
5. **Result screen upgrade**: per-run breakdown (damage by weapon — accumulate per-source in
   `deal_damage`; marks earned; achievements progressed this run).
6. **Accessibility audit**: every screen controller-navigable; focus order sane; text ≥ 14 px.

### Verification checklist
- [ ] Suites + validator green; settings persist across restart and web refresh.
- [ ] SFX slider at 0 silences weapons but music continues (bus separation proof).
- [ ] Reduced-flash mode verified on hexer casts + boss enrage (worst flashers).
- [ ] Pad-only full session: menu → sanctum → select → run → pause → result → menu.

### Anti-pattern guards
- Settings reads happen at apply-time, not per-frame dictionary lookups in hot paths (cache
  values into locals on `player_stats_changed`-style notifications or screen-shake consumer).
- Don't bypass Main's state machine for new screens (pausing rules live there, main.gd:142-200).

---

## PHASE 11 — BALANCE & PERFORMANCE

### What to implement
1. **Balance doc** `docs/BALANCE.md`: DPS budget per wave (enemy HP × spawn rate vs expected
   player DPS at that minute), per-stage tuning tables, curse-tier multipliers, meta cost curve,
   marks income per run table. Then tune: stage 2/3 wave tables, ascension power (target:
   +60-90% weapon DPS), chest weights, endless ramp.
2. **Scripted balance probes** (extend integrity suite, pure-data math — no gameplay sim):
   e.g. wave N total HP budget within band; xp curve vs upgrade count at wave 9 (≈ level 18-22);
   sanctum total cost vs ~25 average runs.
3. **Stress test**: debug key (debug build only) spawns 250 enemies + max projectiles; record
   FPS desktop + web (Chrome/Firefox) on the F3 overlay. Fix hotspots only with evidence
   (typical suspects: per-frame `query_enemies` radius creep from area_mult stacking, FX volume).
4. **Memory check web**: music cache + 3 stages of art; confirm load and heap acceptable
   (devtools snapshot ~< 400 MB).
5. **Playtest checklist update**: rewrite `docs/MANUAL_TEST_CHECKLIST.md` to cover all new
   systems (sanctum, characters, stages, ascensions, achievements, settings, endless, tiers).

### Verification checklist
- [ ] Balance probes green in integrity suite.
- [ ] Stress scene ≥ 55 FPS desktop, ≥ 30 FPS web mid-tier laptop.
- [ ] One full victory per stage at tier 0 + one tier 3 win on stage 1, by actually playing
      (or assisted by debug damage toggle — note which in the commit).
- [ ] Wave 9 frenzy: all caps respected (F3 counts).

### Anti-pattern guards
- No balance changes without updating `docs/BALANCE.md` (single source of tuning truth).
- No optimization without an F3/profiler measurement before AND after.

---

## PHASE 12 — RELEASE & FINAL VERIFICATION (final phase)

### What to implement
1. **Docs refresh**: README (features, controls, screenshots refs), `docs/GAME_DESIGN.md`
   (characters/stages/ascensions/meta/achievements sections), `docs/TECHNICAL_ARCHITECTURE.md`
   (buses, MusicDirector, MetaSystem, ProgressSystem, StageData), `docs/ART_PIPELINE.md`
   (Blender pre-render pipeline + sheet manifests, music renderer, caching). Remove stale "Current Limitations" items that
   are now done; keep honest ones.
2. **Version**: `project.godot` `config/version="1.0.0"`.
3. **Full verification protocol** (in order):
   - [ ] `git diff --name-only -- addons/godot_ai` → empty.
   - [ ] Both MCP suites pass (godot-ai `test_run`), zero warnings treated as errors triaged.
   - [ ] `godot --headless --path . --script res://scripts/tools/validate_project.gd` → exit 0.
   - [ ] Anti-pattern greps: `Thread.new(` in scripts/ (web paths) → none outside debug-guarded
         code; `AudioStreamOggVorbis` writes → none; `default_playback_type.web=1` still present;
         `STARTER_WEAPON =` assignments → only the const; `save_system.data[` writes outside
         core systems → none.
   - [ ] Fresh-profile run (delete `user://cursed_keep_save.json` + music cache): first-boot
         experience clean (drone fallback → menu theme swap, no errors in log via godot-ai
         `logs_read`).
   - [ ] Web export locally; manual checklist pass on Chrome + Firefox (focus: audio start after
         input, IndexedDB persistence, stage 3 perf).
4. **Deploy**: merge to `master` → `.github/workflows/deploy-pages.yml` runs (validator gates
   it) → verify https://jfhutchi.github.io/cursed-keep-survivorst/ plays a full stage-1 run.
5. **Tag** `v1.0.0` with changelog summarizing the 12 phases.

---

## PHASE SIZING NOTE
Phases 1, 3, 5, 6, 8 are the largest (each a full session). If a session runs long, the designed
split points are: Phase 1 (engine+menu music | combat/boss music), Phase 3 (studio+pipeline+player
| enemy roster + boss), Phase 5 (stage framework + crypts | garden + bosses), Phase 6 (ascensions
| pickups+endless+tiers), Phase 8 (animation breadth | environment + UI polish).
