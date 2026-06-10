# Reward Loop Seed

Reward Loop Seed is an ugly playable Godot prototype for answering one question: after a short run, do you want to press restart?

This is not a full game. It is one crude reward-loop seed with movement, automatic attacks, enemy pressure, reward pickups, upgrades, one earned free chest reveal, a result screen, and local-only event logging.

## How To Run

1. Open this folder in Godot 4.4 or newer.
2. Run the project with F5.
3. Godot boots `res://scenes/main.tscn`.

The current editor version used during implementation was Godot 4.6.3.

## Controls

- Move with WASD or arrow keys.
- Attacks are automatic against the nearest target in range.
- Choose an upgrade by clicking one of the three buttons.
- Open the earned free chest when it appears.
- Use the result screen buttons to restart or quit.

## Current Gameplay Loop

1. Move around the arena and avoid chasers.
2. Automatic blasts defeat basic and elite targets.
3. Defeated targets drop spark pickups.
4. Pickups fill the progress meter.
5. Filling the meter offers three real upgrade choices.
6. Surviving or scoring enough earns one free chest reveal.
7. The run ends on defeat or after three minutes.
8. The result screen shows run stats and an immediate restart button.

## Intentional Placeholders

- All art is simple code-created shapes and labels.
- There are no external asset packs.
- There is no sound yet.
- There is no mobile UI yet, but the loop uses simple movement and automatic attacks for later one-thumb adaptation.
- There is no monetization, no ads, no premium currency, and no paid randomized reward system.
