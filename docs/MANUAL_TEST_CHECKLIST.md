# Manual Test Checklist

Run through this list in the editor (F5) before calling a build good.
Automated coverage (MCP suites + headless validator) is noted where it
already guards an item.

## Project / Tooling

- [ ] Project opens in Godot 4.6.x with no script errors *(auto: compile smoke)*
- [ ] Godot AI addon still present and enabled (MCP dock visible, port 8000)
- [ ] `git diff --name-only -- addons/godot_ai` is empty

## Menu / Flow

- [ ] Main menu loads with emblem, background, high-score line
- [ ] CONTROLS panel opens and closes
- [ ] START (`BEGIN THE VIGIL`) launches a run
- [ ] Esc pauses; Resume / Restart / Main Menu all work
- [ ] Restart works from pause, game over, and victory without quitting

## Player

- [ ] Player spawns centered with idle animation
- [ ] WASD / arrows / left stick move in 8 directions
- [ ] Space dashes: stretch + ghost trail, i-frames, HUD arc refills
- [ ] Taking damage flashes red, shakes screen, grants brief invulnerability
- [ ] Death plays collapse, then Game Over screen appears

## Weapons

- [ ] Soul Bolt auto-fires at the nearest enemy from run start
- [ ] At least 10 different weapons usable in one long run (unlock via level-ups)
- [ ] 18 weapon definitions exist *(auto: data integrity / validator)*
- [ ] Each fired weapon has distinct visuals and a distinct sound
- [ ] Orbiting Relics and Astral Tome persist and act on their own
- [ ] Iron Maiden cage triggers on cooldown and retaliates when hit
- [ ] Telegraphed weapons (Bone Spikes, Storm Censer, Saint's Hammer) show
      warnings before damage

## Enemies

- [ ] Enemies spawn off-screen on a ring, never on the player
- [ ] Crawlers/ghouls chase; wraiths drift erratically and are translucent
- [ ] Cult Hexers keep distance and fire purple orbs that hurt the player
- [ ] Grave Splitters split into fragments on death
- [ ] Hollow Knights telegraph (red lane) then charge
- [ ] Elites are larger with a gold ring and sometimes drop pickups
- [ ] Enemies flash on hit, show damage numbers, die with burst + dissolve

## XP / Upgrades

- [ ] Soul shards drop, magnetize inside pickup radius, fill the top bar
- [ ] Level-up pauses the game and shows 3 cards (icon, name, rarity, desc)
- [ ] Mouse click and 1/2/3 both select
- [ ] Chosen upgrades visibly apply (stats, new weapons, weapon levels)
- [ ] No unlock card for an owned weapon; no weapon card for a locked weapon
      *(auto: offer rules test)*
- [ ] 112 upgrades defined *(auto: data integrity / validator)*
- [ ] Multi-level pickups re-open the card screen back-to-back

## Controller / Touch

- [ ] Menus navigable with arrows/stick; Enter/A activates focused button
- [ ] Focus ring visibly moves between buttons and level-up cards
- [ ] Restart from Game Over via Enter alone works
- [ ] On a touch device: left-half drag moves, bottom-right button dashes

## Waves / Boss

- [ ] Wave banner announces each of the 10 waves; HUD shows wave name
- [ ] Composition changes per the wave table; elites from wave 3
- [ ] Wave 10: boss warning, Castellan spawns, boss HP bar appears
- [ ] Boss bursts, summons, sigils, and charge sweep all telegraph and hurt
- [ ] Boss enrages below 35 % (red, faster)
- [ ] Killing the boss triggers hit-stop, collapse, Victory screen

## Persistence / Misc

- [ ] High score / best wave / fastest victory persist across restarts
      (`user://cursed_keep_save.json`)
- [ ] F3 debug overlay shows FPS, counts, weapons, spawn budget
- [ ] Music drone plays from boot; SFX volume reasonable
- [ ] FPS stays smooth in wave 9–10 with a 6-weapon build (watch F3)
- [ ] Web export notes exist (`docs/WEB_EXPORT_GITHUB_PAGES.md`)
