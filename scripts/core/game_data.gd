extends Node
## Central data access + global tuning. Autoloaded as GameData.
## Wraps the static data tables and holds arena/tuning constants used by
## several systems. Run-scoped state lives in GameWorld, not here.

const WeaponDataT := preload("res://scripts/data/weapon_data.gd")
const EnemyDataT := preload("res://scripts/data/enemy_data.gd")
const UpgradeDataT := preload("res://scripts/data/upgrade_data.gd")
const WaveDataT := preload("res://scripts/data/wave_data.gd")

# --- Arena ---------------------------------------------------------------
const ARENA_HALF := Vector2(1200, 780)   # playable half-extents around origin
const SPAWN_RING := Vector2(700, 900)    # min/max spawn distance from player

# --- Global performance caps --------------------------------------------
const MAX_PROJECTILES := 220
const MAX_ENEMY_PROJECTILES := 90
const MAX_XP_ORBS := 320
const MAX_ZONES := 36
const MAX_FX := 90
const MAX_FLOATING_TEXT := 48

var weapons: Dictionary = WeaponDataT.WEAPONS
var enemies: Dictionary = EnemyDataT.ENEMIES
var boss: Dictionary = EnemyDataT.BOSS
var upgrades: Array = UpgradeDataT.UPGRADES
var waves: Array = WaveDataT.WAVES


func weapon(id: String) -> Dictionary:
	return weapons.get(id, {})


func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


func weapon_color(id: String) -> Color:
	var def: Dictionary = weapons.get(id, {})
	return Color(str(def.get("color", "ffffff")))


func rarity_color(rarity: String) -> Color:
	return Color(str(UpgradeDataT.RARITY_COLORS.get(rarity, "ffffff")))


## XP required to go from `level` to `level + 1`.
## Tuned so the first two level-ups land inside the opening minute (the
## first 60 seconds should already be fun) while late levels still stretch.
func xp_to_next(level: int) -> float:
	return roundf(6.0 + level * 4.0 + pow(level, 1.55))
