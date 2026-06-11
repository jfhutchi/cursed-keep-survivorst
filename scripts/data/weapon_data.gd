class_name WeaponData
extends RefCounted
## Data-driven weapon definitions for all 18 weapons.
##
## Field reference:
##   id / name / desc      - identity and flavor (all original)
##   icon                  - generated SVG icon path
##   category              - projectile | orbit | area | ground | chain |
##                           defensive | summon | melee | control
##   targeting             - one of the targeting modes in WeaponManager
##   color                 - hex color used by projectiles/effects/UI accents
##   base                  - tunable stats; WeaponManager reads these through
##                           weapon mods + player multipliers
##   max_active            - per-weapon safety cap on live objects
##
## A weapon is *implemented* by a matching fire routine in WeaponManager
## (match on id). The validator cross-checks this list against icons,
## upgrades, and the implemented-id list.

const STARTER_WEAPON := "soul_bolt"
const DEFAULT_WEAPON_CAP := 6
const ABSOLUTE_WEAPON_CAP := 8

const WEAPONS: Dictionary = {
	"soul_bolt": {
		"id": "soul_bolt",
		"name": "Soul Bolt",
		"desc": "A fast blue-white shard of your own soul, hurled at the nearest horror.",
		"icon": "res://assets/generated/weapons/soul_bolt.svg",
		"category": "projectile",
		"targeting": "nearest_enemy",
		"color": "7fd4ff",
		"base": {"cooldown": 1.05, "damage": 14.0, "range": 430.0, "speed": 640.0, "count": 1, "pierce": 0, "size": 1.0, "soulburst": 0},
		"max_active": 40,
	},
	"rune_knives": {
		"id": "rune_knives",
		"name": "Rune Knives",
		"desc": "Spectral daggers fan outward in a rotating spiral, shredding close swarms.",
		"icon": "res://assets/generated/weapons/rune_knives.svg",
		"category": "projectile",
		"targeting": "radial_from_player",
		"color": "c08bff",
		"base": {"cooldown": 2.5, "damage": 9.0, "count": 6, "speed": 520.0, "range": 320.0, "bleed": 0.0, "size": 1.0, "returning": 0},
		"max_active": 48,
	},
	"orbiting_relics": {
		"id": "orbiting_relics",
		"name": "Orbiting Relics",
		"desc": "Ancient ward-stones circle you, grinding anything that comes close.",
		"icon": "res://assets/generated/weapons/orbiting_relics.svg",
		"category": "orbit",
		"targeting": "around_player",
		"color": "ffd76a",
		"base": {"cooldown": 0.0, "damage": 11.0, "count": 2, "radius": 90.0, "orbit_speed": 2.6, "size": 1.0, "hit_interval": 0.4, "pulse": 0},
		"max_active": 8,
	},
	"cursed_flame": {
		"id": "cursed_flame",
		"name": "Cursed Flame",
		"desc": "A cone of violet-green keepfire that clings and burns.",
		"icon": "res://assets/generated/weapons/cursed_flame.svg",
		"category": "area",
		"targeting": "densest_cluster",
		"color": "9dff6e",
		"base": {"cooldown": 3.1, "damage": 10.0, "cone_deg": 55.0, "length": 250.0, "burn_dps": 6.0, "burn_dur": 2.5, "linger": 0},
		"max_active": 6,
	},
	"bone_spikes": {
		"id": "bone_spikes",
		"name": "Bone Spikes",
		"desc": "The keep's dead erupt from the floor where a sigil warns.",
		"icon": "res://assets/generated/weapons/bone_spikes.svg",
		"category": "ground",
		"targeting": "ground_near_enemy",
		"color": "e8e0cf",
		"base": {"cooldown": 3.4, "damage": 28.0, "radius": 85.0, "delay": 0.75, "count": 1, "slow": 0.0, "second": 0},
		"max_active": 8,
	},
	"chain_hex": {
		"id": "chain_hex",
		"name": "Chain Hex",
		"desc": "A jagged hex-arc leaps from skull to skull through the crowd.",
		"icon": "res://assets/generated/weapons/chain_hex.svg",
		"category": "chain",
		"targeting": "nearest_enemy",
		"color": "7dffb8",
		"base": {"cooldown": 2.4, "damage": 13.0, "chains": 3, "chain_range": 180.0, "range": 500.0, "slow": 0.2, "slow_dur": 1.0, "fork": 0.0},
		"max_active": 10,
	},
	"sanctified_nova": {
		"id": "sanctified_nova",
		"name": "Sanctified Nova",
		"desc": "What remains of the keep's blessing detonates outward in a golden ring.",
		"icon": "res://assets/generated/weapons/sanctified_nova.svg",
		"category": "area",
		"targeting": "radial_from_player",
		"color": "ffe9a0",
		"base": {"cooldown": 4.2, "damage": 18.0, "radius": 140.0, "knockback": 180.0, "double": 0, "heal_chance": 0.0},
		"max_active": 4,
	},
	"blood_scythe": {
		"id": "blood_scythe",
		"name": "Blood Scythe",
		"desc": "A crimson reaping arc sweeps around you, drinking what it cuts.",
		"icon": "res://assets/generated/weapons/blood_scythe.svg",
		"category": "melee",
		"targeting": "forward_or_movement_direction",
		"color": "ff5d6c",
		"base": {"cooldown": 2.7, "damage": 21.0, "arc_deg": 200.0, "radius": 125.0, "sweeps": 1, "lifesteal": 0.0, "bleed": 0.0},
		"max_active": 4,
	},
	"grave_bell": {
		"id": "grave_bell",
		"name": "Grave Bell",
		"desc": "A funeral toll rolls outward in rings that stagger the dead.",
		"icon": "res://assets/generated/weapons/grave_bell.svg",
		"category": "area",
		"targeting": "radial_from_player",
		"color": "a8c4d8",
		"base": {"cooldown": 4.4, "damage": 12.0, "rings": 1, "radius": 180.0, "slow": 0.35, "slow_dur": 1.4, "stun_chance": 0.0},
		"max_active": 6,
	},
	"thorn_sigil": {
		"id": "thorn_sigil",
		"name": "Thorn Sigil",
		"desc": "Cursed brambles grow from inked sigils, tearing at all who cross.",
		"icon": "res://assets/generated/weapons/thorn_sigil.svg",
		"category": "ground",
		"targeting": "ground_near_enemy",
		"color": "4fb56a",
		"base": {"cooldown": 3.7, "damage": 6.0, "tick": 0.45, "radius": 65.0, "duration": 5.0, "count": 1, "slow": 0.15, "spread": 0},
		"max_active": 7,
	},
	"phantom_bow": {
		"id": "phantom_bow",
		"name": "Phantom Bow",
		"desc": "A ghostly archer looses heavy spectral arrows at the strongest foe.",
		"icon": "res://assets/generated/weapons/phantom_bow.svg",
		"category": "projectile",
		"targeting": "highest_health_enemy",
		"color": "d8f4ff",
		"base": {"cooldown": 2.3, "damage": 34.0, "speed": 920.0, "pierce": 3, "range": 660.0, "crit_bonus": 0.15, "count": 1, "split": 0},
		"max_active": 12,
	},
	"plague_lantern": {
		"id": "plague_lantern",
		"name": "Plague Lantern",
		"desc": "A leaking lantern births drifting clouds of green rot.",
		"icon": "res://assets/generated/weapons/plague_lantern.svg",
		"category": "area",
		"targeting": "densest_cluster",
		"color": "8ce05a",
		"base": {"cooldown": 4.0, "dps": 9.0, "radius": 100.0, "duration": 3.5, "count": 1, "stacks": 1, "vuln": 0.0},
		"max_active": 5,
	},
	"iron_maiden": {
		"id": "iron_maiden",
		"name": "Iron Maiden",
		"desc": "A cage of cursed iron snaps shut around you and bites back.",
		"icon": "res://assets/generated/weapons/iron_maiden.svg",
		"category": "defensive",
		"targeting": "defensive_reactive",
		"color": "ff8c6b",
		"base": {"cooldown": 6.0, "damage": 16.0, "radius": 100.0, "duration": 2.4, "dr": 0.15, "retaliation": 1.0, "emergency": 0},
		"max_active": 2,
	},
	"astral_tome": {
		"id": "astral_tome",
		"name": "Astral Tome",
		"desc": "A floating grimoire reads itself aloud, casting whatever it finds.",
		"icon": "res://assets/generated/weapons/astral_tome.svg",
		"category": "summon",
		"targeting": "companion_autonomous",
		"color": "b8a4ff",
		"base": {"cooldown": 0.0, "cast_cd": 1.5, "damage": 12.0, "range": 440.0, "count": 1, "variety": 1, "empowered": 0.0},
		"max_active": 3,
	},
	"moon_chakram": {
		"id": "moon_chakram",
		"name": "Moon Chakram",
		"desc": "Silver crescents fly out and curve home, cutting coming and going.",
		"icon": "res://assets/generated/weapons/moon_chakram.svg",
		"category": "projectile",
		"targeting": "forward_or_movement_direction",
		"color": "e6f0ff",
		"base": {"cooldown": 2.0, "damage": 15.0, "speed": 540.0, "count": 1, "distance": 280.0, "size": 1.0, "return_speed": 1.0},
		"max_active": 10,
	},
	"death_mark": {
		"id": "death_mark",
		"name": "Death Mark",
		"desc": "Brands the doomed with a rune. The marked take more, and die loudly.",
		"icon": "res://assets/generated/weapons/death_mark.svg",
		"category": "control",
		"targeting": "random_enemy",
		"color": "ff9add",
		"base": {"cooldown": 5.0, "marks": 3, "vuln": 0.25, "duration": 4.0, "explode": 0, "explode_damage": 30.0, "spread": 0.0, "execute": 0.0},
		"max_active": 12,
	},
	"storm_censer": {
		"id": "storm_censer",
		"name": "Storm Censer",
		"desc": "A swinging censer of stormglass calls violet lightning onto the horde.",
		"icon": "res://assets/generated/weapons/storm_censer.svg",
		"category": "ground",
		"targeting": "random_enemy",
		"color": "9fd0ff",
		"base": {"cooldown": 3.0, "damage": 24.0, "strikes": 2, "radius": 70.0, "delay": 0.45, "shock_dur": 0.0, "double": 0.0},
		"max_active": 8,
	},
	"saints_hammer": {
		"id": "saints_hammer",
		"name": "Saint's Hammer",
		"desc": "A vast spectral hammer falls where the horde is thickest.",
		"icon": "res://assets/generated/weapons/saints_hammer.svg",
		"category": "ground",
		"targeting": "densest_cluster",
		"color": "ffd28f",
		"base": {"cooldown": 5.5, "damage": 55.0, "radius": 150.0, "delay": 0.9, "knockback": 280.0, "stun": 0.0, "second": 0, "crack": 0},
		"max_active": 3,
	},
}


static func get_weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, {})


static func all_ids() -> Array:
	return WEAPONS.keys()
