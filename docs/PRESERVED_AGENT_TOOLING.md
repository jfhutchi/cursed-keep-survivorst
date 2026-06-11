# Preserved Agent Tooling

This repository includes Godot AI/MCP tooling that must be preserved while improving the game.

## Tooling Folders Found

- `addons/godot_ai/` - Godot AI editor plugin, MCP bridge, runtime helper, handlers, clients, and utility scripts.

## Preserved Folders

- `addons/godot_ai/` is preserved and should remain unchanged by game-feature work.

## Project Settings Preserved

`project.godot` keeps the Godot AI runtime helper autoload:

```ini
_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"
```

`project.godot` keeps the Godot AI editor plugin enabled:

```ini
enabled=PackedStringArray("res://addons/godot_ai/plugin.cfg")
```

## Files Intentionally Modified

No Godot AI/MCP/addon files are intentionally modified as part of the game rebuild or follow-up cleanup.

Before handing work off, verify this command prints no files:

```powershell
git diff --name-only -- addons/godot_ai
```

## Uncertainty

No additional agent-tooling folders were found outside `addons/godot_ai/` during the latest handoff check. If a future session discovers new folders clearly related to MCP, Codex, Claude, agent workflows, or editor plugins, preserve them unless the user explicitly approves a targeted change.
