# Art Pipeline

The canonical art pipeline documentation lives next to the assets:

**[`assets/generated/ART_PIPELINE.md`](../assets/generated/ART_PIPELINE.md)**

Summary:

- 55 hand-authored original SVGs (player, 8 enemies + boss, 18 weapon icons,
  20 stat icons, environment set, UI emblem + menu background) in the
  "gothic neon dark fantasy" palette.
- Everything else is procedural: arena decoration, projectile/zone/FX
  visuals drawn in `_draw`, glow textures from `GradientTexture2D`, particles.
- All animation is procedural/tween-based (run bob, dash stretch, hurt
  flash, death dissolve, boss phases) — no sprite sheets required.
- All audio is synthesized at startup in `scripts/core/audio_manager.gd`;
  the repo contains zero audio files.
- No external, downloaded, or licensed assets are used anywhere.

See the linked file for the full folder map, animation details, and
instructions for adding new art.
