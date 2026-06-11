class_name EnemyData
extends RefCounted
## Enemy definitions. Each id maps to a scene in res://scenes/enemies/ and is
## configured by these stats. Elite variants are derived at spawn time using
## the ELITE block. Per-wave HP scaling is applied by the WaveDirector.

const ELITE := {
	"hp_mult": 2.8,
	"speed_mult": 1.1,
	"scale_mult": 1.35,
	"xp_mult": 4.0,
	"score_mult": 4.0,
	"damage_mult": 1.4,
}

## behavior: chase | wraith | ranged | charger
## radius: collision radius in px. xp: shards dropped worth. dps applies on contact.
const ENEMIES: Dictionary = {
	"bone_crawler": {
		"id": "bone_crawler",
		"name": "Bone Crawler",
		"desc": "Skittering knots of fused bone. The keep's smallest hunger.",
		"scene": "res://scenes/enemies/BoneCrawler.tscn",
		"sprite": "res://assets/generated/enemies/bone_crawler.svg",
		"behavior": "chase",
		"hp": 18.0, "speed": 95.0, "damage": 8.0,
		"xp": 1, "score": 10, "radius": 14.0, "scale": 1.0,
		"tint": "d8d2c0",
	},
	"bone_fragment": {
		"id": "bone_fragment",
		"name": "Bone Fragment",
		"desc": "Splinters of a Grave Splitter, still hungry.",
		"scene": "res://scenes/enemies/BoneCrawler.tscn",
		"sprite": "res://assets/generated/enemies/bone_crawler.svg",
		"behavior": "chase",
		"hp": 8.0, "speed": 135.0, "damage": 5.0,
		"xp": 1, "score": 5, "radius": 9.0, "scale": 0.62,
		"tint": "b8b2a0",
		"no_elite": true,
	},
	"starved_ghoul": {
		"id": "starved_ghoul",
		"name": "Starved Ghoul",
		"desc": "Fast, thin, and many. They run in packs and never tire.",
		"scene": "res://scenes/enemies/StarvedGhoul.tscn",
		"sprite": "res://assets/generated/enemies/starved_ghoul.svg",
		"behavior": "chase",
		"hp": 14.0, "speed": 168.0, "damage": 6.0,
		"xp": 1, "score": 12, "radius": 12.0, "scale": 1.0,
		"tint": "9fae8e",
	},
	"wraith": {
		"id": "wraith",
		"name": "Wraith",
		"desc": "A torn shadow that drifts sideways through the world.",
		"scene": "res://scenes/enemies/Wraith.tscn",
		"sprite": "res://assets/generated/enemies/wraith.svg",
		"behavior": "wraith",
		"hp": 26.0, "speed": 112.0, "damage": 9.0,
		"xp": 2, "score": 18, "radius": 14.0, "scale": 1.0,
		"tint": "a8b8e8",
		"alpha": 0.72,
	},
	"plague_brute": {
		"id": "plague_brute",
		"name": "Plague Brute",
		"desc": "A swollen mass of rot. Slow, but it ends what it touches.",
		"scene": "res://scenes/enemies/PlagueBrute.tscn",
		"sprite": "res://assets/generated/enemies/plague_brute.svg",
		"behavior": "chase",
		"hp": 120.0, "speed": 55.0, "damage": 18.0,
		"xp": 4, "score": 35, "radius": 24.0, "scale": 1.25,
		"tint": "9ec46a",
	},
	"cult_hexer": {
		"id": "cult_hexer",
		"name": "Cult Hexer",
		"desc": "Keeps its distance and lobs slow coils of curse-light.",
		"scene": "res://scenes/enemies/CultHexer.tscn",
		"sprite": "res://assets/generated/enemies/cult_hexer.svg",
		"behavior": "ranged",
		"hp": 40.0, "speed": 85.0, "damage": 7.0,
		"proj_damage": 11.0, "proj_speed": 230.0, "fire_cooldown": 2.8, "preferred_range": 300.0,
		"xp": 3, "score": 30, "radius": 14.0, "scale": 1.0,
		"tint": "c89aff",
	},
	"grave_splitter": {
		"id": "grave_splitter",
		"name": "Grave Splitter",
		"desc": "A shambling ossuary. Breaking it only makes more of it.",
		"scene": "res://scenes/enemies/GraveSplitter.tscn",
		"sprite": "res://assets/generated/enemies/grave_splitter.svg",
		"behavior": "chase",
		"hp": 70.0, "speed": 78.0, "damage": 10.0,
		"xp": 3, "score": 28, "radius": 18.0, "scale": 1.1,
		"tint": "cfc4a8",
		"splits_into": "bone_fragment", "split_count": 3,
	},
	"hollow_knight": {
		"id": "hollow_knight",
		"name": "Hollow Knight",
		"desc": "Empty armor that remembers war. Winds up, then runs you down.",
		"scene": "res://scenes/enemies/HollowKnight.tscn",
		"sprite": "res://assets/generated/enemies/hollow_knight.svg",
		"behavior": "charger",
		"hp": 220.0, "speed": 72.0, "damage": 22.0,
		"charge_speed": 430.0, "windup": 0.8, "charge_time": 0.6, "charge_cooldown": 3.5,
		"xp": 6, "score": 60, "radius": 20.0, "scale": 1.2,
		"tint": "8a93a8",
	},
}

const BOSS := {
	"id": "cursed_castellan",
	"name": "The Cursed Castellan",
	"title": "Heart of the Keep",
	"desc": "The keep's will, wearing the armor of its last lord.",
	"scene": "res://scenes/enemies/CursedCastellan.tscn",
	"sprite": "res://assets/generated/enemies/cursed_castellan.svg",
	"hp": 4200.0, "speed": 62.0, "damage": 25.0,
	"xp": 0, "score": 1500, "radius": 46.0, "scale": 1.0,
	"tint": "caa8ff",
	"enrage_threshold": 0.35,
}


static func get_enemy(id: String) -> Dictionary:
	return ENEMIES.get(id, {})


static func all_ids() -> Array:
	return ENEMIES.keys()
