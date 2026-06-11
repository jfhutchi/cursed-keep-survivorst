# Generated Art Pipeline

Every visual asset in Cursed Keep Survivors is original and generated inside
this repository. There are no downloaded packs, no CraftPix assets, and no
copyrighted material. This document explains how the art is made and how to
extend it.

## Art Direction

**"Gothic neon dark fantasy"** — black stone (`#0b0716`–`#161221`), cursed
purple flames (`#8b5cf6`, `#d86bff`), necromantic greens (`#6ee77a`,
`#9dff6e`), gold relic highlights (`#d8b25a`, `#ffd76a`), blood-red danger
telegraphs (`#ff4a44`), and blue-white soul light (`#7fd4ff`). Enemy
silhouettes stay readable against the dark floor; danger is always
red-telegraphed.

## What Was Created (55 hand-authored SVGs)

| Folder | Contents |
|---|---|
| `characters/` | `wardkeeper.svg` — the player |
| `enemies/` | 8 sprites: bone_crawler, starved_ghoul, wraith, plague_brute, cult_hexer, grave_splitter, hollow_knight, cursed_castellan (boss) |
| `weapons/` | 18 weapon icons, one per weapon id, shared 64×64 tile language |
| `icons/` | 20 stat/upgrade glyphs (speed, heart, heal, armor, magnet, xp, cooldown, damage, crit, area, bolt, feather, duration, luck, score, fist, split, gem, skull, link) |
| `environment/` | floor_a, floor_b, floor_crack, floor_sigil, pillar, torch |
| `ui/` | `emblem.svg` (title crest), `menu_bg.svg` (1280×720 menu painting) |

Godot imports SVG natively (ThorVG), so these are regular `Texture2D`s.

## What Is Procedural (code-generated at runtime)

- **Arena** (`scripts/game/arena.gd`): scatters floor slabs/cracks/sigils,
  builds walls, pillars, flickering torch glows (GradientTexture2D radial
  sprites), drifting curse fog, and ambient dust (CPUParticles2D).
- **Projectiles** (`projectile.gd`): seven draw-kinds (bolt, knife, arrow,
  chakram, spark, orb, shard) drawn in `_draw` with glow + 6-point trails.
- **Zones** (`zone.gd`): telegraph sigils, bone eruptions, hammer slams,
  lightning strikes, poison clouds, thorn traps, cracked ground.
- **FX** (`fx.gd`): sweeps, novas, bell rings, flame cones, chain lightning,
  death bursts, dash ghosts, level-up bursts, warning lines, boss warnings.
- **Pickups/orbs** (`xp_orb.gd`, `pickup.gd`): drawn soul shards, health
  vials, magnet charms with bob/pulse animation.
- **Glow textures**: radial `GradientTexture2D` built in code (player glow,
  torch glows, fog).

## Animation Approach

No baked sprite sheets — animation is procedural and tween-based:

- **Player**: run bob + tilt + squash, idle breathing, dash stretch + ghost
  trail, hurt flash/blink, death collapse tween.
- **Enemies**: per-behavior bob/wobble, wraith alpha oscillation, charger
  windup squash + red flash, hurt flash, death burst + sprite dissolve ghost.
- **Boss**: hover bob, charge telegraph squash, enrage tint, collapse tween.
- **Effects**: time-parameterized `_draw` (each FX animates over a `t`
  0→1 lifetime).

## Audio (also generated)

`scripts/core/audio_manager.gd` synthesizes every sound at startup from a
parameter table (sine/square/noise mixes, pitch sweeps, decay envelopes, bell
partials): ~22 event sounds + one unique `w_<weapon_id>` cue per weapon + a
9.6 s detuned-drone music loop. No audio files exist in the repo at all.

## How To Add New Art

1. **New enemy/weapon icon**: copy an existing SVG in the right folder, keep
   the tile frame (`rect rx=10 fill #141022 stroke #43395f` for icons), swap
   the glyph and accent color, save — Godot auto-imports.
2. **New projectile look**: add a draw-kind branch in `projectile.gd::_draw`.
3. **New ground effect**: add a kind to `zone.gd` (telegraph + payload).
4. **New sound**: add one line to the `SFX` table in `audio_manager.gd`.
5. Keep accents inside the palette above so everything stays coherent.
