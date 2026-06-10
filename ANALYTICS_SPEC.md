# Analytics Spec

Reward Loop Seed logs local-only JSONL events. There are no network calls and no analytics SDK.

## Log Location

Runtime events are written to:

`user://reward_loop_seed_events.jsonl`

In Godot, `user://` resolves to the project user data directory for the current platform.

## Events Logged

- `session_started`
- `first_reward_collected`
- `reward_collected`
- `first_upgrade_offered`
- `upgrade_selected`
- `free_chest_earned`
- `free_chest_opened`
- `session_ended`
- `restart_clicked`

## Shared Event Fields

- `event`
- `session_id`
- `timestamp`
- `time_since_session_start`
- `player_level`
- `reward_count`
- `upgrade_count`

## Context Fields

- `selected_upgrade` on upgrade selection.
- `chest_reward` on free chest open.
- `session_duration` on session end.
- `end_reason` on session end.

## Metrics That Matter

- Time to first reward.
- Time to first upgrade.
- Time to first free chest.
- Session duration.
- Restart clicked.
- Upgrade choice frequency.
- Chest open frequency.
- Quit, fail, or win reason.

These metrics are for manual prototype judgment only. They are not sent anywhere.
