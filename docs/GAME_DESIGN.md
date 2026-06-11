# Cursed Keep Survivors — Game Design

Original dark-fantasy bullet-heaven survivor game. You are the last Wardkeeper
trapped inside a living fortress. The keep tries to absorb your soul with
escalating waves of monsters; you survive by collecting soul shards, awakening
relic weapons, and breaking the curse before the Heart of the Keep manifests.

All names, mechanics, art, and audio are original.

## Core Loop

1. Move, dodge, and dash — weapons fire automatically.
2. Enemies die, dropping blue-white **soul shards** (XP) and score.
3. Filling the soul bar levels you up: pick **1 of 3 upgrades** (mouse or 1/2/3).
4. Upgrades raise stats, awaken new weapons, deepen owned weapons, form
   synergies, or offer cursed tradeoffs.
5. Waves escalate every ~40–50 s; elites appear from wave 3 onward.
6. Wave 10 spawns **The Cursed Castellan**. Kill it → victory screen; die →
   game over. Either way, restart is one click.

A full run targets ~7–9 minutes plus the boss fight.

## Player — The Wardkeeper

Stats (see `scripts/player/player.gd`): max_health, move_speed, dash_speed,
dash_duration, dash_cooldown, armor (% damage reduction, can go negative),
pickup_radius, xp_mult, damage_mult, cooldown_mult, projectile_speed_mult,
area_mult, duration_mult, crit_chance, crit_mult, luck, score_mult,
knockback_mult, projectile_bonus, regen.

Mechanics:

- Smooth 8-direction movement (keyboard or analog stick).
- Dash (Space): brief burst with full invulnerability, ghost trail, cooldown
  shown as an arc in the HUD.
- 0.45 s invulnerability window after taking a hit.
- Pickup magnet radius pulls soul shards in.
- Death plays a collapse animation; **Death's Favor** (cursed upgrade) grants
  one revive at 40 % HP at the cost of 15 max HP.

## Weapons (18)

Defined in `scripts/data/weapon_data.gd`; behaviors in
`scripts/weapons/weapon_manager.gd` (the `IMPLEMENTED` list is enforced by
tests). The player starts with **Soul Bolt**; all others are awakened through
level-up unlock upgrades. Active weapon cap: **6**, raisable to 8 via the epic
*Wardkeeper's Vow*. Once at cap, unlock offers disappear; stat and
weapon-specific offers continue.

| Weapon | Category | Targeting | Identity |
|---|---|---|---|
| Soul Bolt | projectile | nearest enemy | fast blue-white starter bolt; pierce/split/soulburst hooks |
| Rune Knives | projectile | radial from player | rotating spiral of purple daggers; bleed; returning blades |
| Orbiting Relics | orbit | around player | gold ward-stones grind nearby enemies; pulse upgrade |
| Cursed Flame | area | densest cluster | green-violet cone, burn DoT, lingering patch |
| Bone Spikes | ground | ground near enemy | telegraphed sigil → bone eruption; double eruption |
| Chain Hex | chain | nearest enemy | green hex-arc jumps between enemies; forking; slow |
| Sanctified Nova | area | radial from player | golden ring blast; knockback; heal-on-hit; echo pulse |
| Blood Scythe | melee | facing direction | crimson sweep arc; lifesteal; second reverse sweep |
| Grave Bell | area | radial from player | expanding toll rings; slow; stun chance; extra rings |
| Thorn Sigil | ground | ground near enemy | bramble traps; tick damage + slow; reseeding |
| Phantom Bow | projectile | highest-health enemy | heavy piercing ghost arrows; bonus crit; split shot |
| Plague Lantern | area | densest cluster | drifting poison clouds; stacking DoT; vulnerability |
| Iron Maiden | defensive | reactive | spike cage with DR; retaliates when you are hit; low-HP trigger |
| Astral Tome | summon | companion autonomous | floating grimoire casting bolts/novas/curses; empowered casts |
| Moon Chakram | projectile | facing direction | silver crescents fly out and return, cutting both ways |
| Death Mark | control | random enemies | brands enemies (+25 % damage taken); death explosions; spreading |
| Storm Censer | ground | random enemies | telegraphed violet lightning strikes; double strikes |
| Saint's Hammer | ground | densest cluster | huge telegraphed slam; knockback; stun; cracked ground |

Every weapon has: generated SVG icon, unique projectile/effect color and
shape, a distinct synthesized audio cue (`w_<id>` in
`scripts/core/audio_manager.gd`), at least 2 weapon-specific upgrades
(Soul Bolt has 5), and a per-weapon `max_active` safety cap.

### Targeting modes

`nearest_enemy`, `highest_health_enemy`, `random_enemy`, `densest_cluster`,
`radial_from_player`, `forward_or_movement_direction`, `around_player`,
`ground_near_enemy`, `defensive_reactive`, `companion_autonomous`.
Scans run only when a weapon fires, never per-frame per-weapon.

## Enemies (7 types + fragments + boss)

Defined in `scripts/data/enemy_data.gd`; one configurable script
(`scripts/enemies/enemy.gd`) drives all behaviors.

| Enemy | Behavior | Role |
|---|---|---|
| Bone Crawler | chase | weak early swarm |
| Bone Fragment | chase | fast splinters from Grave Splitters |
| Starved Ghoul | chase (fast) | pack pressure |
| Wraith | erratic drift, semi-transparent | unpredictable flanker |
| Plague Brute | slow chase | high HP, high contact damage |
| Cult Hexer | ranged kiter | lobs slow curse orbs, keeps distance |
| Grave Splitter | chase | splits into 3 Bone Fragments on death |
| Hollow Knight | telegraphed charge | elite-tier lane threat from wave 8 |

**Elites** (any type except fragments): ×2.8 HP, ×1.35 size, ×1.4 damage,
×4 XP/score, gold ring glow, and a 30 %/12 % chance to drop a health vial /
soul magnet pickup.

Status effects all enemies support: burn, poison (+vulnerability), bleed,
slow, stun, Death Mark (vulnerability + explosion + spread).

## Boss — The Cursed Castellan (Heart of the Keep)

~4200 HP, spawns in wave 10 with a warning effect and its own HUD bar.

- **Phase 1 (100–70 %)**: radial curse bursts (10 shards), minion summons.
- **Phase 2 (70–35 %)**: adds ground sigil explosions around the player and a
  telegraphed charge sweep.
- **Phase 3 / Enrage (<35 %)**: red glow, +50 % speed, 40 % faster attack
  cycle, 16-shard bursts, 5 sigils.

It resists slows (40 % effect), is immune to stun, takes half mark
vulnerability, and is nearly immune to knockback. Death triggers a slow
collapse, a hit-stop + shake payoff, and the victory flow.

## Upgrades (112)

Defined in `scripts/data/upgrade_data.gd`. Rarities: common / uncommon /
rare / epic / cursed, with luck multiplying non-common weights.

- 20 global stat/special upgrades (speed, HP, heal, armor, magnet, XP,
  cooldown, damage, crit, area, dash, duration, luck, score, knockback,
  regen, +1 projectile, +1 weapon cap, …)
- 17 weapon unlocks (every weapon except Soul Bolt)
- 56 weapon-specific upgrades (5 for Soul Bolt, 3 per other weapon)
- 7 cursed tradeoffs (Blood Pact, Greedy Soul, Unstable Relic, Death's Favor,
  Hollow Speed, Glass Saint, Overcharged Sigils) — gated until player level 5
- 12 synergies requiring weapon pairs: Soulfire Covenant, Relic Storm, Grave
  Harvest, Plague Thorns, Moonlit Blades, Bell of Judgment, Iron Reliquary,
  Astral Execution, Hexfire Lattice (Chain Hex ignites), Stormcaller's Toll
  (Grave Bell calls lightning), Grave Tithe (expiring Thorn Sigils erupt into
  bone spikes), Maiden's Verdict (retaliation drops a small hammer)

Offer rules (enforced in `scripts/upgrades/upgrade_system.gd` and covered by
tests): no unlocks for owned weapons or past the weapon cap, no
weapon-specific upgrades for locked weapons, no synergies without both
weapons, stack limits per upgrade, *Soul Mend* pads the pool if it runs dry.

## Waves (10)

Defined in `scripts/data/wave_data.gd`. Each wave sets duration, spawn
interval (lerped across the wave), max-alive cap, composition weights, elite
chance, and an HP multiplier (1.0 → 2.85).

1. The Gate Stirs — crawlers only
2. Hunger in the Halls — + ghouls
3. The Swarm Below — density up, first elites
4. Veil of Wraiths — + wraiths
5. Rot Walks the Halls — + brutes
6. Hexfire — + hexers
7. Splitting Graves — + splitters
8. The Hollow March — + hollow knights
9. Court of Elites — 22 % elite chance, fastest spawns
10. Heart of the Keep — boss + minion trickle, ends on boss death

Spawns appear on a 700–900 px ring around the player, clamped inside the
arena, never on top of the player.

## Save / Progression

`user://cursed_keep_save.json` via the SaveSystem autoload: high score,
fastest victory time, total runs, total kills, best wave, victories, volume
settings. Local only; no online services.

## Balancing Notes

- XP curve is `6 + 4·L + L^1.55`, tuned (after live playtests) so the first
  level-up lands inside the opening minute. Base pickup radius is 130 and
  Soul Bolt's range is 430 so early kills drop shards the player will
  actually cross.
- Waves 1–2 were softened after playtesting (max-alive 26/45, slower
  intervals) — being netted by a full spawn ring in the first minute felt
  unfair. Wave 9 elite chance is 0.18.
- Soul Bolt alone comfortably clears waves 1–2; build power should roughly
  double by wave 5 to keep pace with the HP multiplier curve.
- Cursed upgrades intentionally break the budget (+50 % damage) but their
  downsides bite hardest in waves 8–10 (faster enemies, less HP).
- DoT sources (burn/poison/bleed) tick on a shared 0.45 s clock so stacked
  clouds don't multiply tick counts.
- Boss HP (~4200) assumes a mid build of 4–5 weapons; a strong build kills in
  ~60–90 s, a weak one needs 2–3 minutes (enrage makes stalling dangerous).
- Tunables intentionally live in data tables; rebalancing should rarely touch
  behavior code.
