extends Node
## Global signal bus for Cursed Keep Survivors.
## Autoloaded as GameEvents. Systems communicate through these signals
## instead of holding direct references to each other.

# Run lifecycle
signal run_started
signal game_over(run_stats: Dictionary)
signal victory(run_stats: Dictionary)

# Waves / director
signal wave_started(wave_index: int, wave_name: String)

# Player
signal player_hurt(amount: float, hp: float, max_hp: float)
signal player_healed(amount: float)
signal player_died
signal player_dashed
signal xp_gained(amount: float, total: float, needed: float)
signal level_up(new_level: int)
signal player_stats_changed

# Enemies / boss
signal enemy_killed(enemy: Node2D, source_id: String)
signal boss_spawned(boss: Node2D)
signal boss_health_changed(hp: float, max_hp: float)
signal boss_defeated

# Upgrades / weapons
signal upgrade_chosen(upgrade: Dictionary)
signal weapon_unlocked(weapon_id: String)
signal weapon_leveled(weapon_id: String, level: int)

# Scoring / feedback
signal score_changed(score: int)
signal screen_shake_requested(strength: float)
signal hit_stop_requested(duration: float)
