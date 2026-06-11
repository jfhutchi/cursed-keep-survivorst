class_name WaveData
extends RefCounted
## Wave director script for the full run (~7-9 minutes + boss fight).
##
## Field reference:
##   name          - announced on screen
##   duration      - seconds before the next wave starts (boss wave: until won)
##   interval      - [start, end] seconds between spawns (lerped over the wave)
##   max_alive     - soft cap on living enemies during this wave
##   comp          - enemy id -> spawn weight
##   elite_chance  - chance any spawn is promoted to elite
##   hp_mult       - enemy HP multiplier for spawns during this wave
##   boss          - true on the final wave: spawns The Cursed Castellan

const WAVES: Array = [
	{
		"name": "The Gate Stirs",
		"duration": 40.0, "interval": [1.45, 0.95], "max_alive": 26,
		"comp": {"bone_crawler": 1.0},
		"elite_chance": 0.0, "hp_mult": 1.0,
	},
	{
		"name": "Hunger in the Halls",
		"duration": 42.0, "interval": [1.15, 0.75], "max_alive": 45,
		"comp": {"bone_crawler": 0.65, "starved_ghoul": 0.35},
		"elite_chance": 0.0, "hp_mult": 1.05,
	},
	{
		"name": "The Swarm Below",
		"duration": 44.0, "interval": [0.9, 0.55], "max_alive": 75,
		"comp": {"bone_crawler": 0.5, "starved_ghoul": 0.5},
		"elite_chance": 0.02, "hp_mult": 1.15,
	},
	{
		"name": "Veil of Wraiths",
		"duration": 44.0, "interval": [0.85, 0.5], "max_alive": 85,
		"comp": {"bone_crawler": 0.4, "starved_ghoul": 0.35, "wraith": 0.25},
		"elite_chance": 0.04, "hp_mult": 1.3,
	},
	{
		"name": "Rot Walks the Halls",
		"duration": 46.0, "interval": [0.8, 0.5], "max_alive": 95,
		"comp": {"bone_crawler": 0.32, "starved_ghoul": 0.31, "wraith": 0.22, "plague_brute": 0.15},
		"elite_chance": 0.05, "hp_mult": 1.5,
	},
	{
		"name": "Hexfire",
		"duration": 46.0, "interval": [0.75, 0.45], "max_alive": 105,
		"comp": {"bone_crawler": 0.25, "starved_ghoul": 0.27, "wraith": 0.18, "plague_brute": 0.14, "cult_hexer": 0.16},
		"elite_chance": 0.06, "hp_mult": 1.75,
	},
	{
		"name": "Splitting Graves",
		"duration": 48.0, "interval": [0.7, 0.42], "max_alive": 110,
		"comp": {"starved_ghoul": 0.3, "wraith": 0.17, "plague_brute": 0.13, "cult_hexer": 0.15, "grave_splitter": 0.25},
		"elite_chance": 0.08, "hp_mult": 2.05,
	},
	{
		"name": "The Hollow March",
		"duration": 48.0, "interval": [0.65, 0.4], "max_alive": 120,
		"comp": {"starved_ghoul": 0.26, "wraith": 0.18, "plague_brute": 0.14, "cult_hexer": 0.14, "grave_splitter": 0.18, "hollow_knight": 0.10},
		"elite_chance": 0.10, "hp_mult": 2.4,
	},
	{
		"name": "Court of Elites",
		"duration": 50.0, "interval": [0.55, 0.34], "max_alive": 135,
		"comp": {"starved_ghoul": 0.22, "wraith": 0.2, "plague_brute": 0.16, "cult_hexer": 0.14, "grave_splitter": 0.16, "hollow_knight": 0.12},
		"elite_chance": 0.18, "hp_mult": 2.85,
	},
	{
		"name": "Heart of the Keep",
		"duration": 9999.0, "interval": [2.2, 1.6], "max_alive": 30,
		"comp": {"bone_crawler": 0.4, "starved_ghoul": 0.35, "wraith": 0.25},
		"elite_chance": 0.06, "hp_mult": 2.6,
		"boss": true,
	},
]


static func wave_count() -> int:
	return WAVES.size()


static func get_wave(index: int) -> Dictionary:
	return WAVES[clampi(index, 0, WAVES.size() - 1)]
