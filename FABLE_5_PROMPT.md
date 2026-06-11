You are Claude Code running Claude Fable 5.

You are working inside the GitHub repository:

cursed-keep-survivorst

Your mission is to rebuild this repository into a complete, playable, polished Godot 4 bullet-heaven / survivor-like game from scratch.

The game should be called:

"Cursed Keep Survivors"

This is a serious autonomous coding benchmark and game development task.

You are allowed to overwrite the existing game implementation, scenes, scripts, placeholder assets, menus, and gameplay systems as needed.

However, you must preserve the Godot AI / MCP / agent tooling already present in the repository.

============================================================
CRITICAL PRESERVATION RULES
===========================

Before changing files, inspect the repository structure.

You may delete, replace, or rewrite incomplete game code.

You may overwrite old scenes, scripts, UI, project settings, placeholder assets, and gameplay files if that is the cleanest route.

But you must NOT delete or break:

* .git/
* .github/ unless you are intentionally improving workflows
* Godot AI addons
* MCP addons
* editor plugins
* agent-related configuration
* existing addon folders
* Godot plugin registration needed by Godot AI
* any folder clearly named addon, addons, godot-ai, mcp, agent, ai, claude, codex, or similar
* any local instructions files for agents unless updating them carefully
* README sections that describe agent setup unless you preserve or improve them
* asset licenses or attribution files if any exist

Specifically:

1. Inspect addons/.
2. Identify which addons are related to Godot AI, MCP, Claude, Codex, or agent workflows.
3. Preserve those folders exactly unless a change is absolutely necessary.
4. If project.godot has addon/plugin enablement entries, preserve those entries.
5. If you need to rewrite project.godot, carry forward addon/plugin settings.
6. Do not remove Godot AI panels, scripts, plugin.cfg files, or editor plugin files.
7. Do not remove MCP configuration files.
8. Do not remove local development documentation related to AI tools.
9. Do not delete asset licenses or attribution files if any exist.
10. If uncertain whether a file supports Godot AI/MCP tooling, keep it.

Create a document:

docs/PRESERVED_AGENT_TOOLING.md

In that document, list:

* All addon/tooling folders you found
* Which ones you preserved
* Any project.godot plugin settings you preserved
* Any files you intentionally modified
* Any uncertainty

============================================================
PRIMARY GOAL
============

Create a complete Godot 4 bullet-heaven game inspired by:

* Vampire Survivors
* Brotato
* Halls of Torment
* XP Hero
* top-down arena survival games

But make everything original.

Do not copy copyrighted game names, characters, maps, music, art, icons, UI, upgrade names, enemy designs, or exact mechanics.

This should become an original dark fantasy action-survival game.

The player explores and survives inside a cursed castle keep while waves of monsters attack. The player gains XP, levels up, selects upgrades, unlocks weapons, survives escalating waves, and fights a final boss.

The result must be playable in Godot.

Primary target:

* Godot 4.4+ desktop

Secondary target:

* Godot Web export / GitHub Pages compatibility where practical

Long-term target:

* Steam and mobile-friendly architecture

============================================================
GAME IDENTITY
=============

Game title:

Cursed Keep Survivors

Genre:

Top-down 2D bullet-heaven / survivor-like arena action game.

Core fantasy:

You are the last wardkeeper trapped inside a cursed fortress. The keep is alive. Every chamber breathes corruption. Every wave of monsters is another attempt by the castle to absorb your soul. You survive by collecting soul shards, awakening relic weapons, and breaking the curse before the castle heart fully manifests.

Tone:

* Gothic
* Dark fantasy
* Haunted castle
* Arcane magic
* Cursed relics
* Necromantic enemies
* Readable action
* Punchy arcade feel
* Polished prototype, not graybox

The game should feel like:

* movement-focused survival
* automatic weapons
* escalating enemy density
* satisfying XP collection
* meaningful upgrades
* readable danger zones
* fast restart loop
* lots of visual/audio feedback
* a real foundation for a commercial survivor-like game

============================================================
IMPORTANT DESIGN DIRECTION
==========================

This is NOT primarily a manual click-to-shoot twin-stick shooter.

This IS a bullet-heaven / survivor-like.

Primary control mode:

* Weapons fire automatically.
* Player focuses on movement, positioning, dodging, dashing, collecting XP, and choosing upgrades.
* Mouse aiming may exist as an optional override, but normal play should not require constant clicking.
* Controller/mobile support should be considered architecturally, even if not fully implemented.

Player controls:

* WASD / Arrow keys: move
* Space: dash
* Esc: pause
* Mouse: optional aim influence / UI interaction
* 1 / 2 / 3: choose level-up upgrade card
* F3: debug overlay toggle

============================================================
TECHNICAL REQUIREMENTS
======================

Use Godot 4.4+ APIs only.

Do not use Godot 3 patterns.

If using CharacterBody2D:

* Use the built-in velocity property.
* Call move_and_slide() with no arguments.
* Do not use old KinematicBody2D APIs.

Preferred implementation:

* 2D top-down game
* CharacterBody2D for player
* Area2D or CharacterBody2D for enemies depending on need
* Node2D-based world
* CanvasLayer HUD
* Resource-driven weapon/enemy/upgrade definitions where practical
* Procedural/generated original artwork and animations
* No copyrighted asset dependency
* No external paid assets required to run

You may use:

* Godot built-in nodes
* GDScript
* Godot resources
* Godot shaders
* AnimationPlayer
* AnimatedSprite2D
* Sprite2D
* Polygon2D
* Line2D
* GPUParticles2D / CPUParticles2D
* TileMapLayer if appropriate
* AudioStreamGenerator or generated placeholder audio if practical
* SVG assets generated directly in the repo
* Procedural textures generated by script
* Simple generated sprite sheets if practical

Do not require external art downloads.

Do not rely on CraftPix assets for this version.

The instruction is for Claude Fable 5 to generate the art and animation assets itself.

============================================================
DESTRUCTIVE REBUILD INSTRUCTIONS
================================

Because I explicitly want a from-scratch remake, you may replace the existing game implementation.

Recommended process:

1. Inspect current repo.
2. Run git status.
3. Identify Godot AI/MCP/plugin/addon files to preserve.
4. Identify current game files that are safe to replace.
5. Create a short rebuild note.
6. Rebuild the game cleanly.
7. Preserve agent tooling.
8. Run validation.
9. Report exactly what changed.

Create:

docs/REBUILD_NOTES.md

Include:

* What existed before
* What was overwritten
* What was preserved
* Why the rebuild approach was chosen
* Any files intentionally left untouched
* Any risks or uncertainty

Do not ask for clarification.

Make reasonable decisions.

If uncertain whether something is part of Godot AI/MCP/plugin tooling, preserve it.

============================================================
ARTWORK REQUIREMENTS
====================

You must generate all game artwork yourself inside the repository.

Do not leave the game with only Godot default icons, colored rectangles, or unstyled capsules.

Use a coherent original art direction:

"Gothic neon dark fantasy"

Visual language:

* black stone
* cursed purple flames
* green necromancy
* gold relic highlights
* blood-red danger telegraphs
* blue-white soul shards
* ruined castle floors
* broken sigils
* floating dust
* magical projectiles
* readable enemy silhouettes

Generate original artwork for:

1. Player character

   * Top-down readable wardkeeper / cursed knight / relic mage
   * Idle animation
   * Run animation
   * Dash effect
   * Hurt flash
   * Death animation or collapse effect

2. Enemies

   * Bone Crawler
   * Starved Ghoul
   * Wraith
   * Plague Brute
   * Cult Hexer
   * Grave Splitter
   * Hollow Knight
   * Elite variants
   * Boss: The Cursed Castellan / Heart of the Keep

3. Weapons / attacks

   * Soul Bolt
   * Rune Knives
   * Orbiting Relics
   * Cursed Flame
   * Bone Spikes
   * Chain Hex
   * Sanctified Nova
   * Blood Scythe
   * Grave Bell
   * Thorn Sigil
   * Phantom Bow
   * Plague Lantern
   * Iron Maiden
   * Astral Tome
   * Moon Chakram
   * Death Mark
   * Stretch weapons if implemented

4. Pickups

   * XP soul shards
   * Health pickup
   * Magnet pickup if implemented
   * Gold/score shard optional

5. Environment

   * Castle floor tiles
   * Cracked stone
   * Cursed sigils
   * Pillars or ruins
   * Torch/fire accents
   * Arena boundary
   * Boss arena markings

6. UI

   * Main menu background
   * Upgrade cards
   * Icons for weapons/upgrades
   * HP bar style
   * XP bar style
   * Boss health bar
   * Pause/game over/victory panels

7. Effects

   * Hit sparks
   * Death bursts
   * Soul pickup swirl
   * Level-up flash
   * Curse fog
   * Dash trail
   * Projectile trails
   * Boss warning telegraphs

Acceptable generated art methods:

* Hand-authored SVG files
* Godot GradientTexture2D resources
* Procedural texture generation
* Polygon2D shapes
* Line2D effects
* Particle systems
* ShaderMaterial effects
* Animated scenes made from layered sprites/shapes
* Generated sprite sheets if practical

The art must be original and stored in the project.

Recommended folders:

res://assets/generated/
res://assets/generated/characters/
res://assets/generated/enemies/
res://assets/generated/weapons/
res://assets/generated/ui/
res://assets/generated/environment/
res://assets/generated/effects/
res://assets/generated/icons/
res://assets/generated/audio/

Add:

res://assets/generated/ART_PIPELINE.md

Explain:

* How the art was generated
* What files were created
* How animations are built
* What is procedural versus authored
* How to add new art later

============================================================
ANIMATION REQUIREMENTS
======================

You must create actual animations, not just static sprites.

Implement animations for:

Player:

* idle
* run
* dash
* hurt
* death or defeat effect

Enemies:

* idle/move for each major enemy type
* attack animation for ranged/caster enemies
* death animation or dissolve effect
* elite visual variation

Boss:

* idle
* summon
* radial burst
* charge/telegraph
* damage phase
* death

Weapons/effects:

* projectile movement visual
* projectile impact
* orbiting relic animation
* flame/rune pulse
* XP orb bob/pulse
* pickup magnet movement
* level-up burst
* boss warning effect

Use one or more of:

* AnimationPlayer
* AnimatedSprite2D
* Tween
* shader animation
* particles
* procedural frame animation
* sprite frame resources

Do not claim animation is complete if objects are static.

============================================================
AUDIO REQUIREMENTS
==================

Generate or implement simple original audio feedback.

Do not download copyrighted sounds.

Use one of these approaches:

* Godot AudioStreamGenerator
* Simple generated WAV files
* Minimal procedural tones
* Built-in synthesized effects if possible

Add sounds for:

* player attack
* enemy hit
* enemy death
* XP pickup
* level-up
* dash
* player hurt
* boss spawn
* boss attack
* game over
* victory

Audio can be simple, but it must exist and be triggered.

If full generated audio is not possible in the environment, create the audio system with clear placeholders and document the limitation honestly.

============================================================
CORE GAMEPLAY REQUIREMENTS
==========================

The final game must include:

1. Main Menu

   * Title
   * Start button
   * Controls
   * High score
   * Credits/attribution note saying art is generated/original

2. Gameplay

   * Player movement
   * Dash
   * Auto-firing weapons
   * Enemy waves
   * XP pickups
   * Level-up upgrade choices
   * Health/damage/death
   * Score
   * Timer
   * Boss fight
   * Victory condition
   * Game over condition
   * Restart without closing the game

3. Pause Menu

   * Resume
   * Restart
   * Main menu

4. HUD

   * HP bar
   * XP bar
   * Level
   * Wave
   * Timer
   * Score
   * Current weapons
   * Dash cooldown indicator
   * Boss health bar when boss is active

5. Level-up Screen

   * 3 upgrade cards
   * Upgrade name
   * Upgrade icon
   * Description
   * Rarity or type
   * Click selection
   * Keyboard selection with 1/2/3

6. Game Over Screen

   * Score
   * Time survived
   * Waves survived
   * Restart
   * Main menu

7. Victory Screen

   * Score
   * Time survived
   * Boss defeated message
   * Restart
   * Main menu

============================================================
PLAYER DESIGN
=============

Player fantasy:

The Wardkeeper

A cursed guardian who uses relic weapons to survive the haunted keep.

Stats:

* max_health
* health
* move_speed
* dash_speed
* dash_duration
* dash_cooldown
* armor
* pickup_radius
* xp_multiplier
* damage_multiplier
* cooldown_multiplier
* projectile_multiplier
* area_multiplier
* duration_multiplier
* crit_chance
* crit_multiplier
* luck

Player mechanics:

* Smooth 8-direction movement
* Dash with short invulnerability or damage reduction
* Damage flash
* Knockback resistance
* Pickup magnet radius
* Level progression
* Upgrade application
* Death state

============================================================
WEAPON REQUIREMENTS
===================

Implement at least 16 weapons.

Target count:

* Minimum: 16 fully implemented weapons
* Stretch goal: 20 weapons if time allows
* Every weapon must be original, visually distinct, and mechanically meaningful
* Do not create 16 weapons that all behave like simple projectile clones

Weapons should be data-driven where practical.

Each weapon should have:

* id
* display name
* description
* icon
* unlock state
* cooldown
* damage
* range
* targeting behavior
* scaling behavior
* visual effect
* animation/effect scene
* upgrade hooks
* audio cue
* performance notes if it can create many objects

Weapon categories:

1. Projectile weapons
2. Orbiting weapons
3. Area-control weapons
4. Delayed ground attacks
5. Beam/chain weapons
6. Defensive/reactive weapons
7. Summon/relic weapons
8. Cursed tradeoff weapons

The player should start with one weapon:

* Soul Bolt

The rest should be unlockable through level-up upgrades, cursed relic choices, or wave milestones.

============================================================
REQUIRED WEAPON LIST
====================

Implement these 16 weapons at minimum:

1. Soul Bolt
   Type: auto-target projectile
   Fantasy: A fast blue-white soul projectile.
   Behavior:

   * Auto-targets nearest enemy within range
   * Fires a fast projectile
   * Can pierce with upgrades
   * Reliable starter weapon
	 Upgrade hooks:
   * damage
   * cooldown
   * projectile count
   * pierce
   * projectile speed
   * soul explosion on kill

2. Rune Knives
   Type: rotating directional projectiles
   Fantasy: Spectral rune daggers orbit briefly then launch outward.
   Behavior:

   * Fires multiple knives in rotating directions
   * Good against close swarms
   * Moderate cooldown
	 Upgrade hooks:
   * knife count
   * spin speed
   * duration
   * damage
   * bleed chance
   * return-to-player behavior

3. Orbiting Relics
   Type: orbit weapon
   Fantasy: Ancient relic stones circle the player.
   Behavior:

   * Relics orbit player and damage enemies on contact
   * Persistent close-range defense
	 Upgrade hooks:
   * relic count
   * orbit radius
   * orbit speed
   * damage
   * pulse damage
   * relic size

4. Cursed Flame
   Type: cone / wave attack
   Fantasy: Purple-green cursed fire erupts from the player.
   Behavior:

   * Periodically emits a flame cone toward the nearest enemy cluster
   * Applies burn damage over time
   * Strong against groups
	 Upgrade hooks:
   * cone width
   * flame length
   * burn damage
   * burn duration
   * cooldown
   * lingering flame patches

5. Bone Spikes
   Type: delayed ground attack
   Fantasy: Bone spikes burst from cursed stone.
   Behavior:

   * Targets enemies near the player
   * Shows a warning sigil
   * After a short delay, spikes erupt and damage enemies
   * High damage but avoid instant unavoidable hits
	 Upgrade hooks:
   * spike count
   * spike radius
   * delay reduction
   * damage
   * second eruption
   * impale slow

6. Chain Hex
   Type: chaining attack
   Fantasy: A cursed lightning/hex bolt jumps between enemies.
   Behavior:

   * Hits one target then chains to nearby enemies
   * Great against clustered enemies
   * Lower single-target damage
	 Upgrade hooks:
   * chain count
   * chain range
   * damage
   * cooldown
   * hex slow
   * chance to fork

7. Sanctified Nova
   Type: radial burst
   Fantasy: A holy relic pulse blasts outward.
   Behavior:

   * Periodic radial explosion centered on player
   * Defensive panic-clearing weapon
   * Short range at first
	 Upgrade hooks:
   * radius
   * damage
   * cooldown
   * knockback
   * double pulse
   * heal-on-hit chance

8. Blood Scythe
   Type: sweeping arc melee/range hybrid
   Fantasy: A spectral red scythe sweeps around the player.
   Behavior:

   * Creates a wide rotating slash arc
   * Strong close-range area damage
   * Can lifesteal with upgrades
	 Upgrade hooks:
   * arc size
   * sweep speed
   * damage
   * cooldown
   * lifesteal
   * double sweep

9. Grave Bell
   Type: pulsing aura weapon
   Fantasy: A haunted bell toll damages enemies in rings.
   Behavior:

   * Emits expanding sound rings
   * Damage falls off by distance if easy to implement
   * Can briefly stun or slow enemies
	 Upgrade hooks:
   * ring count
   * radius
   * cooldown
   * damage
   * slow strength
   * stun chance

10. Thorn Sigil
	Type: trap / area denial
	Fantasy: A cursed plant-like sigil grows thorns from the floor.
	Behavior:

* Places damaging sigils around the arena
* Enemies walking over them take damage
* Great for kiting paths
  Upgrade hooks:
* trap count
* trap duration
* trap radius
* damage per tick
* slow
* spreading thorns

11. Phantom Bow
	Type: precision projectile
	Fantasy: A ghostly archer fires spectral arrows.
	Behavior:

* Fires slower but high-damage arrows
* Prioritizes high-health or elite enemies
* Can pierce lines of enemies
  Upgrade hooks:
* damage
* cooldown
* pierce
* crit chance
* elite targeting
* split arrow

12. Plague Lantern
	Type: poison cloud / damage over time
	Fantasy: A lantern leaks green plague mist.
	Behavior:

* Creates drifting poison clouds near enemy clusters
* Applies poison damage over time
* Strong against slow groups
  Upgrade hooks:
* cloud size
* cloud duration
* poison damage
* poison stacking
* cooldown
* enemy vulnerability debuff

13. Iron Maiden
	Type: defensive reactive weapon
	Fantasy: A cursed iron barrier retaliates when the player is hit or surrounded.
	Behavior:

* Periodically summons spikes/barrier around player
* Can trigger stronger retaliation after player takes damage
* Defensive weapon, not always active
  Upgrade hooks:
* retaliation damage
* shield duration
* cooldown
* thorns damage
* damage reduction
* emergency trigger at low HP

14. Astral Tome
	Type: summon / autonomous caster
	Fantasy: A floating spellbook casts random minor spells.
	Behavior:

* Summons a floating tome companion
* Tome auto-casts bolts, mini-novas, or curses
* Should feel like a companion weapon
  Upgrade hooks:
* tome count
* cast speed
* spell damage
* spell variety
* range
* chance for empowered cast

15. Moon Chakram
	Type: returning projectile
	Fantasy: Crescent blades launch outward and return.
	Behavior:

* Throws crescent projectiles that travel out and return to the player
* Damages enemies both ways
* Rewards movement
  Upgrade hooks:
* chakram count
* travel distance
* return speed
* damage
* size
* orbit briefly before return

16. Death Mark
	Type: curse/debuff execution weapon
	Fantasy: Marks enemies with a death rune.
	Behavior:

* Periodically marks several enemies
* Marked enemies take increased damage
* If a marked enemy dies, it explodes or spreads the mark
  Upgrade hooks:
* mark count
* vulnerability amount
* mark duration
* death explosion
* spread chance
* execute low-health enemies

============================================================
STRETCH WEAPONS
===============

If the minimum 16 weapons are implemented and the game remains stable, add up to 4 stretch weapons:

17. Storm Censer
	Type: random lightning zones
	Fantasy: A swinging incense censer calls cursed storm strikes.
	Behavior:

* Lightning strikes random enemies or dense enemy clusters
* Shows brief warning flash before impact
  Upgrade hooks:
* strike count
* strike radius
* damage
* cooldown
* shock duration
* double strike chance

18. Mirror Shield
	Type: projectile reflection / defensive orbit
	Fantasy: Haunted mirror shards orbit and reflect attacks.
	Behavior:

* Orbiting mirror shards block or reduce enemy projectiles
* Shards can shatter into damaging fragments
  Upgrade hooks:
* shard count
* block cooldown
* fragment damage
* orbit speed
* recharge speed
* reflected curse bolts

19. Black Hole Reliquary
	Type: pull / control weapon
	Fantasy: A forbidden relic creates gravity wells.
	Behavior:

* Creates a small cursed singularity
* Pulls enemies inward
* Deals ticking damage
* Must be balanced to avoid trivializing the game
  Upgrade hooks:
* pull strength
* radius
* duration
* damage tick rate
* cooldown
* explosion on collapse

20. Saint's Hammer
	Type: heavy delayed strike
	Fantasy: A spectral hammer slams cursed ground.
	Behavior:

* Targets a high-density enemy area
* Shows a large warning circle
* Slams after delay for high damage and knockback
  Upgrade hooks:
* damage
* radius
* cooldown
* stun
* second hammer
* cracked-ground lingering damage

============================================================
WEAPON UNLOCK RULES
===================

The player starts with:

* Soul Bolt

Unlockable weapons should appear as level-up choices.

Rules:

* Do not offer an unlock upgrade for a weapon already unlocked.
* Do not offer weapon-specific upgrades for locked weapons unless the upgrade also unlocks that weapon.
* Avoid unlocking too many weapons too early.
* Keep the player build readable.
* Limit active weapons if needed for balance/performance.

Suggested active weapon cap:

* Default maximum active weapons: 6
* Upgrade or cursed relic may increase this to 7 or 8
* Passive stat upgrades should continue appearing after weapon cap is reached

When the player reaches the active weapon cap:

* Hide normal weapon unlock upgrades
* Continue offering stat upgrades
* Continue offering upgrades for already unlocked weapons
* Optionally offer rare "replace weapon" choices if implemented

============================================================
WEAPON TARGETING REQUIREMENTS
=============================

Different weapons should use different targeting logic.

Implement at least these targeting modes:

1. nearest_enemy
2. highest_health_enemy
3. random_enemy
4. densest_cluster
5. radial_from_player
6. forward_or_movement_direction
7. around_player
8. ground_near_enemy
9. defensive_reactive
10. companion_autonomous

Do not run expensive targeting logic every frame for every weapon.

Use cooldowns, cached target scans, or targeting intervals.

Example:

* Soul Bolt scans every shot.
* Chain Hex scans when fired.
* Orbiting Relics do not need target scans.
* Plague Lantern scans every cooldown.
* Astral Tome scans on cast.
* Thorn Sigil chooses positions periodically.

============================================================
WEAPON VISUAL REQUIREMENTS
==========================

Every weapon must have a distinct visual identity.

Minimum visual difference:

* Unique icon
* Unique projectile/effect color
* Unique effect shape
* Unique animation or particle behavior

Examples:

* Soul Bolt: blue-white projectile trail
* Rune Knives: rotating purple knife glyphs
* Orbiting Relics: gold/stone orbiting icons
* Cursed Flame: green-purple cone flame
* Bone Spikes: bone-white eruption from red warning sigil
* Chain Hex: jagged green lightning lines
* Sanctified Nova: gold radial ring
* Blood Scythe: red crescent slash
* Grave Bell: gray-blue sound rings
* Thorn Sigil: black-green thorn patch
* Phantom Bow: pale arrow streak
* Plague Lantern: drifting green cloud
* Iron Maiden: red-black spike barrier
* Astral Tome: floating book companion with cast glyphs
* Moon Chakram: silver crescent returning projectile
* Death Mark: skull/rune mark above enemies

============================================================
WEAPON AUDIO REQUIREMENTS
=========================

Every weapon should trigger at least one unique or semi-unique audio cue.

The audio can be procedurally generated, simple, or reused with variation, but it should not feel identical for all weapons.

Examples:

* Soul Bolt: soft arcane pop
* Rune Knives: sharp metallic whisper
* Orbiting Relics: low rotating hum
* Cursed Flame: flame burst
* Bone Spikes: bone crack
* Chain Hex: electric snap
* Sanctified Nova: bell-like pulse
* Blood Scythe: heavy slash
* Grave Bell: low bell toll
* Thorn Sigil: vine crackle
* Phantom Bow: ghost arrow release
* Plague Lantern: bubbling hiss
* Iron Maiden: metal slam
* Astral Tome: page flip / magic cast
* Moon Chakram: spinning blade shimmer
* Death Mark: cursed whisper/stamp

============================================================
WEAPON IMPLEMENTATION QUALITY BAR
=================================

A weapon counts as implemented only if:

1. It can be unlocked or is available by design.
2. It has a visible icon or generated UI art.
3. It has a real gameplay effect.
4. It can damage enemies or meaningfully affect survival.
5. It has distinct visuals.
6. It has at least basic audio feedback.
7. It has at least 2 upgrades or scaling hooks.
8. It does not cause obvious errors when used.
9. It is represented in the HUD or weapon summary.
10. It is included in validation data.

Do not count a weapon as implemented if it only exists as a name in a data file.

============================================================
ENEMY REQUIREMENTS
==================

Implement at least 7 enemy types.

Each enemy should have:

* id
* display name
* health
* speed
* damage
* score value
* XP value
* collision radius
* behavior
* visual scene/art
* animation
* death effect

Enemies:

1. Bone Crawler

   * Basic chaser
   * Low health
   * Common early enemy

2. Starved Ghoul

   * Fast chaser
   * Low health
   * Attacks in groups

3. Wraith

   * Semi-transparent ghost
   * Moves through obstacles if obstacles exist
   * Slightly erratic movement

4. Plague Brute

   * Slow
   * High health
   * High contact damage

5. Cult Hexer

   * Ranged caster
   * Keeps distance
   * Fires slow curse projectiles

6. Grave Splitter

   * Medium enemy
   * Splits into smaller crawlers on death

7. Hollow Knight

   * Elite melee enemy
   * Charges after wind-up
   * Appears in later waves

Elite variants:

* Increased health
* Increased size
* Different glow color
* More XP
* More score

============================================================
BOSS REQUIREMENTS
=================

Final boss:

The Cursed Castellan

Alternative title:

Heart of the Keep

The boss should appear in the final wave.

Boss requirements:

* Large visible sprite/scene
* Boss intro warning
* Boss health bar
* Multiple phases or attack patterns
* Can summon minions
* Can fire radial projectile bursts
* Has telegraphed danger zones
* Has a charge/slam/beam-style attack
* Can be damaged and killed
* On death, triggers victory
* Has unique death animation/effect
* Has unique boss audio cue

Boss attacks:

1. Summon minions
2. Radial curse burst
3. Ground sigil explosions
4. Charging sweep or line attack
5. Enrage below 35% HP

============================================================
WAVE DIRECTOR
=============

Implement a wave/survival director.

Target full run length:

* 8 to 12 minutes

For prototype:

* Make the full run testable in 6 to 8 minutes if needed.

Requirements:

* At least 10 waves
* Difficulty increases over time
* Enemy spawn composition changes
* New enemy types introduced gradually
* Elite enemies appear after early waves
* Boss appears at final wave
* Brief wave announcement
* Spawn enemies around edge of arena, not directly on player
* Avoid impossible early difficulty

Example pacing:

Wave 1:

* Bone Crawlers only

Wave 2:

* Bone Crawlers + Ghouls

Wave 3:

* More density

Wave 4:

* Wraiths introduced

Wave 5:

* Plague Brutes introduced

Wave 6:

* Cult Hexers introduced

Wave 7:

* Grave Splitters introduced

Wave 8:

* Hollow Knights introduced

Wave 9:

* Elite-heavy mixed wave

Wave 10:

* Boss + minions

============================================================
UPGRADE SYSTEM
==============

Implement at least 75 upgrades.

Upgrade system must be data-driven.

Each upgrade should have:

* id
* display name
* description
* rarity
* icon
* effect function or stat modifications
* tags
* prerequisites if needed
* weapon_id if weapon-specific
* compatibility rules if needed

Rarities:

* common
* uncommon
* rare
* epic
* cursed

Upgrade categories:

1. Global stat upgrades
2. Weapon unlock upgrades
3. Weapon-specific upgrades
4. Synergy upgrades
5. Cursed tradeoff upgrades
6. Defensive upgrades
7. Economy/progression upgrades

Minimum upgrade counts:

* At least 15 global stat/passive upgrades
* At least 15 weapon unlock upgrades or weapon acquisition upgrades
* At least 40 weapon-specific upgrades
* At least 5 cursed tradeoff upgrades

Each implemented weapon should have at least 2 weapon-specific upgrades.

Starter/core weapons should have 4+ upgrades each.

The level-up screen should randomly offer 3 valid upgrades.

Avoid offering unlock upgrades for already unlocked weapons.

Avoid offering weapon-specific upgrades for locked weapons unless intentionally designed as an unlock-plus-upgrade.

Avoid offering upgrades that cannot apply yet.

============================================================
GLOBAL UPGRADE EXAMPLES
=======================

Implement global upgrades such as:

1. +15% move speed
2. +20 max health
3. Heal 30 HP
4. +15% armor
5. +25% pickup radius
6. +20% XP gain
7. -15% weapon cooldown
8. +20% damage
9. +10% crit chance
10. +50% crit damage
11. +15% area size
12. +15% projectile speed
13. +1 dash charge if architecture supports it
14. -20% dash cooldown
15. +15% weapon duration
16. +10% luck
17. +20% score gain
18. +10% knockback
19. +10% enemy drop chance if drops exist
20. +1 active weapon cap as rare/epic if balanced

============================================================
WEAPON-SPECIFIC UPGRADE DISTRIBUTION
====================================

Recommended upgrade distribution:

Soul Bolt:

* damage up
* cooldown down
* pierce
* extra projectile
* soul burst on kill

Rune Knives:

* unlock
* knife count up
* spin duration up
* bleed chance
* returning knives

Orbiting Relics:

* unlock
* add relic
* orbit radius up
* pulse damage
* faster orbit

Cursed Flame:

* unlock
* flame width up
* burn damage up
* lingering flame
* cooldown down

Bone Spikes:

* unlock
* spike count up
* delay down
* impale slow
* double eruption

Chain Hex:

* unlock
* extra jumps
* fork chance
* shock slow
* cooldown down

Sanctified Nova:

* unlock
* radius up
* knockback up
* double pulse
* heal on hit

Blood Scythe:

* unlock
* arc size up
* lifesteal
* double sweep
* bleed

Grave Bell:

* unlock
* ring count up
* slow/stun
* radius up
* cooldown down

Thorn Sigil:

* unlock
* trap count up
* trap duration up
* spreading thorns
* stronger slow

Phantom Bow:

* unlock
* crit chance up
* elite targeting
* split arrow
* pierce up

Plague Lantern:

* unlock
* cloud size up
* poison stacks
* vulnerability debuff
* cloud duration up

Iron Maiden:

* unlock
* retaliation damage up
* emergency shield
* shard explosion
* damage reduction

Astral Tome:

* unlock
* tome count up
* cast speed up
* empowered casts
* spell variety

Moon Chakram:

* unlock
* chakram count up
* travel distance up
* returning damage up
* size up

Death Mark:

* unlock
* mark count up
* spread mark
* execute threshold
* death explosion

============================================================
CURSED TRADEOFF UPGRADE EXAMPLES
================================

Implement at least 5 cursed tradeoff upgrades.

Examples:

1. Blood Pact

   * +50% damage
   * -20 max health

2. Greedy Soul

   * +35% XP gain
   * enemies move 10% faster

3. Unstable Relic

   * +2 projectiles
   * +20% weapon cooldown

4. Death's Favor

   * revive once with 40% HP
   * reduce max HP by 15 afterward

5. Hollow Speed

   * +30% move speed
   * -10 armor or +10% incoming damage

6. Glass Saint

   * +35% crit chance
   * -25% max health

7. Overcharged Sigils

   * +40% area size
   * boss and elites gain +15% health

============================================================
WEAPON SYNERGY REQUIREMENTS
===========================

Add at least 8 synergy upgrades if time allows.

Synergy upgrades should require specific weapon combinations.

Examples:

1. Soulfire Covenant
   Requires: Soul Bolt + Cursed Flame
   Effect: Soul Bolt ignites enemies.

2. Relic Storm
   Requires: Orbiting Relics + Chain Hex
   Effect: Relics periodically zap nearby enemies.

3. Grave Harvest
   Requires: Blood Scythe + Death Mark
   Effect: Killing marked enemies heals a small amount.

4. Plague Thorns
   Requires: Plague Lantern + Thorn Sigil
   Effect: Thorn traps apply poison.

5. Moonlit Blades
   Requires: Moon Chakram + Rune Knives
   Effect: Returning chakrams spawn small rune knives.

6. Bell of Judgment
   Requires: Grave Bell + Sanctified Nova
   Effect: Nova triggers an extra bell ring.

7. Iron Reliquary
   Requires: Iron Maiden + Orbiting Relics
   Effect: Relics temporarily harden into shields after dash.

8. Astral Execution
   Requires: Astral Tome + Death Mark
   Effect: Tome prioritizes marked enemies and deals bonus damage.

If synergy upgrades are not implemented in the first pass, create the architecture so they can be added cleanly and document them as next steps.

============================================================
PROGRESSION / SAVE SYSTEM
=========================

Implement local save data.

Use Godot user:// save file.

Save:

* high score
* fastest victory time if applicable
* total runs
* total enemies defeated
* best wave reached
* settings if implemented

Do not require online services.

============================================================
SCENE STRUCTURE
===============

Create a clean Godot scene structure.

Suggested:

res://scenes/Main.tscn
res://scenes/ui/MainMenu.tscn
res://scenes/ui/HUD.tscn
res://scenes/ui/PauseMenu.tscn
res://scenes/ui/LevelUpScreen.tscn
res://scenes/ui/GameOverScreen.tscn
res://scenes/ui/VictoryScreen.tscn

res://scenes/game/GameWorld.tscn
res://scenes/player/Player.tscn

res://scenes/enemies/BoneCrawler.tscn
res://scenes/enemies/StarvedGhoul.tscn
res://scenes/enemies/Wraith.tscn
res://scenes/enemies/PlagueBrute.tscn
res://scenes/enemies/CultHexer.tscn
res://scenes/enemies/GraveSplitter.tscn
res://scenes/enemies/HollowKnight.tscn
res://scenes/enemies/CursedCastellan.tscn

res://scenes/projectiles/
res://scenes/weapons/
res://scenes/pickups/XPOrb.tscn
res://scenes/effects/

res://scripts/core/
res://scripts/game/
res://scripts/player/
res://scripts/enemies/
res://scripts/weapons/
res://scripts/upgrades/
res://scripts/ui/
res://scripts/save/
res://scripts/tools/

res://resources/
res://resources/weapons/
res://resources/enemies/
res://resources/upgrades/

res://assets/generated/

You may choose a better structure, but keep it clean and consistent.

============================================================
AUTOLOADS / SINGLETONS
======================

Use autoloads only where helpful.

Suggested autoloads:

* GameEvents
* SaveSystem
* AudioManager
* GameData

Do not create unnecessary singletons.

If you add autoloads, update project.godot carefully while preserving existing Godot AI/plugin settings.

============================================================
RESOURCE-DRIVEN DESIGN
======================

Prefer Resource classes for data.

Examples:

* WeaponDefinition.gd
* EnemyDefinition.gd
* UpgradeDefinition.gd
* WaveDefinition.gd

But do not over-engineer.

A working clean data table in GDScript is acceptable if Resource creation would slow development too much.

The important part is that weapons, enemies, upgrades, and waves are easy to extend.

============================================================
PERFORMANCE REQUIREMENTS
========================

Bullet-heaven games can create many objects.

Use performance-conscious patterns:

* Object pooling for projectiles
* Object pooling for XP orbs
* Object pooling for hit effects if practical
* Avoid expensive per-frame allocations
* Avoid unnecessary get_tree().get_nodes_in_group calls every frame
* Use groups carefully
* Use squared distance checks where useful
* Use timers or tick intervals for expensive targeting logic
* Keep enemy targeting efficient
* Avoid spawning too many unique scenes in one frame
* Degrade particle counts if FPS drops
* Cap active projectiles/effects per weapon where needed

Target:

* Smooth gameplay with dozens to hundreds of enemies/projectiles on screen

With 16+ weapons, performance matters.

Use:

* projectile pooling
* effect pooling where practical
* capped active projectile counts
* capped lingering area effects
* tick-based damage for clouds/traps
* targeting intervals
* distance-squared checks
* group registries or manager arrays instead of expensive scene searches every frame

Add weapon-specific safety caps.

Examples:

* Maximum active Soul Bolts
* Maximum Rune Knives
* Maximum Bone Spike warning zones
* Maximum Plague Clouds
* Maximum Thorn Sigils
* Maximum Chain Hex jumps
* Maximum companion casts per second

The game should remain stable even if the player has 6+ active weapons.

============================================================
DEBUG OVERLAY REQUIREMENTS
==========================

Add F3 debug overlay.

Display:

* FPS
* Current state
* Wave
* Enemy count
* Projectile count
* XP orb count
* Effect count if tracked
* Player level
* Player HP
* Current weapons
* Active weapon cap
* Spawn budget/intensity
* Build/version label if available

The overlay can be simple but must work.

============================================================
GAME FEEL / POLISH REQUIREMENTS
===============================

Prioritize feel.

Must include:

* Camera smoothing
* Hit stop or micro pause on big hits if practical
* Screenshake on large attacks/boss hits
* Enemy hurt flash
* Player hurt flash
* Knockback
* XP magnet effect
* Level-up burst
* Dash trail
* Projectile trails
* Death particles
* Boss spawn warning
* Boss attack telegraphs
* Clear readable UI
* Responsive input
* Fast restart loop

The first 60 seconds should already be fun.

============================================================
GODOT WEB / GITHUB PAGES REQUIREMENTS
=====================================

The project should remain compatible with a future Godot Web export.

Do not rely on native-only features unless optional.

Add documentation:

docs/WEB_EXPORT_GITHUB_PAGES.md

Include:

* Godot version used/expected
* Export preset notes
* Web export caveats
* GitHub Pages deployment notes
* Whether threaded web export is enabled or avoided
* Where exported files should go if deploying manually
* Any known limitations

If export_presets.cfg already exists, preserve or improve it.

If not, create a reasonable export_presets.cfg only if you are confident it will not break local development.

Do not pretend GitHub Pages deployment was tested unless you actually tested it.

============================================================
VALIDATION REQUIREMENTS
=======================

Before final response, run whatever validation is available.

Try these, depending on environment:

* godot --headless --path . --quit
* godot4 --headless --path . --quit
* godot --headless --path . --script res://scripts/tools/validate_project.gd
* godot4 --headless --path . --script res://scripts/tools/validate_project.gd

Create:

res://scripts/tools/validate_project.gd

The validation script should check:

* Main scene exists
* Required scenes exist
* Required generated asset folders exist
* Upgrade IDs are unique
* Weapon IDs are unique
* Weapon display names are unique
* Enemy IDs are unique
* Wave definitions reference valid enemies
* At least 16 weapon definitions exist
* Starter weapon exists
* Every weapon has an icon path or generated icon scene
* Every weapon has an implementation script or behavior id
* Every unlock upgrade references a valid weapon
* Every weapon-specific upgrade references a valid weapon
* No weapon-specific upgrade references a nonexistent id
* Active weapon cap is defined
* At least 75 upgrade definitions exist
* Unlock upgrades are not offered for already unlocked weapons
* Save system path is valid
* Basic Resource/data definitions load without errors
* Boss/wave logic does not require a weapon that may not exist

Validation should fail clearly if:

* fewer than 16 weapons are implemented
* fewer than 75 upgrades are implemented
* required scenes are missing
* required IDs are duplicated
* project data cannot load

If the Godot binary is not available, do not fake validation.

Say exactly:

* Which commands you attempted
* Which commands failed
* Why they failed
* What static checks you performed instead

============================================================
MANUAL TEST CHECKLIST
=====================

Create:

docs/MANUAL_TEST_CHECKLIST.md

Include checklist items:

* Project opens in Godot
* Godot AI addon/plugin still present
* Main menu loads
* Start button works
* Player spawns
* Player moves
* Dash works
* Auto weapons fire
* Soul Bolt works
* At least 10 weapons are usable in normal gameplay
* At least 16 weapon definitions exist
* At least 75 upgrade definitions exist
* Enemies spawn
* Enemies chase player
* Ranged enemies attack
* Player takes damage
* Enemies take damage
* Enemies die
* XP orbs drop
* XP orbs magnet to player
* Player levels up
* Upgrade screen appears
* Upgrade choices apply real effects
* New weapons can unlock
* Weapon-specific upgrades work
* Waves progress
* Boss spawns
* Boss attacks
* Boss can be damaged
* Boss can be defeated
* Victory screen appears
* Game over appears when player dies
* Restart works
* Pause works
* High score saves
* Debug overlay works
* Art assets load
* Animations play
* Audio triggers
* Web export notes exist

In the final response, report what you could verify.

============================================================
DOCUMENTATION REQUIREMENTS
==========================

Create/update while preserving or improving any existing README sections that describe agent setup, Godot AI/MCP tooling, addon/plugin usage, local development workflow, asset licenses, or attribution:

README.md

Include:

* Game overview
* Controls
* How to run in Godot
* How to validate
* Project structure
* Art generation note
* Godot AI/addon preservation note
* Current limitations
* Next steps

docs/GAME_DESIGN.md

Include:

* Core loop
* Player
* Weapons
* Weapon list
* Weapon unlocks
* Weapon upgrade system
* Enemies
* Boss
* Upgrades
* Waves
* Save/progression
* Balancing notes

docs/TECHNICAL_ARCHITECTURE.md

Include:

* Scene architecture
* Script architecture
* Autoloads
* Weapon system
* Enemy system
* Upgrade system
* Wave director
* Object pooling
* Save system
* UI flow
* Debug overlay
* Performance considerations for 16+ weapons

docs/ART_PIPELINE.md

Include or link to:

* How generated art was created
* Asset folders
* Animation approach
* UI icon approach
* How to extend art later

docs/PRESERVED_AGENT_TOOLING.md

As described above.

docs/REBUILD_NOTES.md

As described above.

docs/MANUAL_TEST_CHECKLIST.md

As described above.

docs/WEB_EXPORT_GITHUB_PAGES.md

As described above.

============================================================
QUALITY BAR
===========

Do not stop at a skeleton.

Do not make only menus.

Do not make only data files.

Do not make only art.

Do not make only docs.

The final result must be a playable game.

Minimum playable vertical slice:

* Main menu
* Player movement
* Dash
* Auto weapon firing
* At least 16 weapon definitions
* At least 10 weapons fully usable in normal gameplay
* At least 16 weapons implemented in code/data before final completion
* Enemy spawns
* Enemy damage/death
* XP pickup
* Level-up choice
* At least 75 upgrades
* At least several waves
* Boss or boss-like final encounter
* Game over
* Victory
* Restart

If time/scope becomes too large, reduce in this order:

Reduce first:

1. Stretch weapons 17-20
2. Synergy upgrades
3. Number of unique animations per weapon
4. Weapon-specific audio uniqueness
5. Number of weapon-specific upgrades beyond 2 each
6. Number of enemy types
7. Boss complexity
8. UI polish
9. Documentation depth

Do not sacrifice:

1. Godot AI/addon preservation
2. Project opening in Godot
3. Player movement
4. Auto weapon firing
5. At least 16 weapon definitions
6. At least 10 clearly usable weapons
7. Enemy spawning
8. Collision/damage
9. XP/level-up
10. Wave progression
11. Game over/restart

============================================================
BENCHMARK REPORT
================

At the end, provide a benchmark-style final report.

Include:

1. Summary of what you built
2. Files/folders created
3. Files/folders overwritten
4. Godot AI/MCP/addon files preserved
5. Commands run
6. Validation results
7. What is playable
8. What is incomplete
9. Known bugs or risks
10. Recommended next steps

Also score yourself honestly from 0 to 5:

* Godot project integrity: X/5
* Agent tooling preservation: X/5
* Gameplay completeness: X/5
* Bullet-heaven feel: X/5
* Weapon system depth: X/5
* Upgrade system depth: X/5
* Art generation quality: X/5
* Animation quality: X/5
* Audio feedback: X/5
* UI polish: X/5
* Code organization: X/5
* Performance readiness: X/5
* Web export readiness: X/5
* Documentation quality: X/5
* Honesty of final report: X/5

Then answer:

* Is this playable now? yes/no
* Does the project open in Godot? yes/no/unknown
* Were Godot AI addons preserved? yes/no/unknown
* Are at least 16 weapons implemented? yes/no
* Are at least 75 upgrades implemented? yes/no
* Is this GitHub Pages ready? yes/no/unknown
* Is this commercially polished yet? yes/no
* What is the single most important next improvement?

============================================================
FINAL INSTRUCTION
=================

Begin by inspecting the repository.

Do not ask for clarification.

Make reasonable decisions.

Preserve Godot AI/MCP/addon tooling.

Overwrite the existing game as needed.

Generate original artwork and animations inside the repo.

Build a playable Godot 4 bullet-heaven game.

Implement at least 16 weapons.

Implement at least 75 upgrades.

Validate honestly.

Now begin.
