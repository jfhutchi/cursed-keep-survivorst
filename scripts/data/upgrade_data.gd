class_name UpgradeData
extends RefCounted
## Data-driven upgrade pool (108 upgrades).
##
## kind:
##   stat    - permanent player stat modification
##   unlock  - unlocks a weapon (never offered when already owned / at cap)
##   weapon  - weapon-specific mod (only offered when that weapon is owned)
##   cursed  - powerful upside with a real downside
##   synergy - requires two specific weapons; sets a synergy flag
##   special - bespoke effects (revive, weapon cap)
##
## stats:  player stat -> {"add": x} or {"mult": x}. "heal" is instant.
## wmods:  weapon base-stat key -> {"add": x} or {"mult": x}
## enemy_mods: run-wide enemy modifiers (cursed downsides)

const IC := "res://assets/generated/icons/"
const WI := "res://assets/generated/weapons/"

const RARITY_WEIGHTS := {"common": 100.0, "uncommon": 52.0, "rare": 22.0, "epic": 8.0, "cursed": 10.0}
const RARITY_COLORS := {"common": "b8c0cc", "uncommon": "7dd98a", "rare": "6fb7ff", "epic": "c98bff", "cursed": "ff6b81"}

const UPGRADES: Array = [
	# ===== GLOBAL STAT UPGRADES (20) =====================================
	{"id": "swift_boots", "name": "Swift Boots", "desc": "+15% move speed.", "rarity": "common", "kind": "stat", "icon": IC + "speed.svg", "max_stacks": 4, "stats": {"move_speed": {"mult": 1.15}}},
	{"id": "vital_core", "name": "Vital Core", "desc": "+20 max health and heal 20.", "rarity": "common", "kind": "stat", "icon": IC + "heart.svg", "max_stacks": 5, "stats": {"max_health": {"add": 20.0}, "heal": {"add": 20.0}}},
	{"id": "soul_mend", "name": "Soul Mend", "desc": "Heal 30 health.", "rarity": "common", "kind": "stat", "icon": IC + "heal.svg", "max_stacks": 99, "stats": {"heal": {"add": 30.0}}},
	{"id": "warded_plate", "name": "Warded Plate", "desc": "+6% damage reduction.", "rarity": "common", "kind": "stat", "icon": IC + "armor.svg", "max_stacks": 5, "stats": {"armor": {"add": 6.0}}},
	{"id": "reliquary_magnet", "name": "Reliquary Magnet", "desc": "+25% pickup radius.", "rarity": "common", "kind": "stat", "icon": IC + "magnet.svg", "max_stacks": 4, "stats": {"pickup_radius": {"mult": 1.25}}},
	{"id": "soul_siphon", "name": "Soul Siphon", "desc": "+20% soul shard XP.", "rarity": "common", "kind": "stat", "icon": IC + "xp.svg", "max_stacks": 4, "stats": {"xp_mult": {"mult": 1.2}}},
	{"id": "fleet_rituals", "name": "Fleet Rituals", "desc": "-10% weapon cooldowns.", "rarity": "uncommon", "kind": "stat", "icon": IC + "cooldown.svg", "max_stacks": 4, "stats": {"cooldown_mult": {"mult": 0.9}}},
	{"id": "keepers_wrath", "name": "Keeper's Wrath", "desc": "+20% damage.", "rarity": "uncommon", "kind": "stat", "icon": IC + "damage.svg", "max_stacks": 5, "stats": {"damage_mult": {"mult": 1.2}}},
	{"id": "deathseeker_eye", "name": "Deathseeker Eye", "desc": "+10% critical chance.", "rarity": "uncommon", "kind": "stat", "icon": IC + "crit.svg", "max_stacks": 4, "stats": {"crit_chance": {"add": 0.1}}},
	{"id": "executioners_edge", "name": "Executioner's Edge", "desc": "+50% critical damage.", "rarity": "rare", "kind": "stat", "icon": IC + "crit.svg", "max_stacks": 3, "stats": {"crit_mult": {"add": 0.5}}},
	{"id": "widened_wards", "name": "Widened Wards", "desc": "+15% area of effect.", "rarity": "uncommon", "kind": "stat", "icon": IC + "area.svg", "max_stacks": 4, "stats": {"area_mult": {"mult": 1.15}}},
	{"id": "arcane_haste", "name": "Arcane Haste", "desc": "+15% projectile speed.", "rarity": "common", "kind": "stat", "icon": IC + "bolt.svg", "max_stacks": 3, "stats": {"projectile_speed_mult": {"mult": 1.15}}},
	{"id": "phantom_step", "name": "Phantom Step", "desc": "-20% dash cooldown.", "rarity": "uncommon", "kind": "stat", "icon": IC + "feather.svg", "max_stacks": 3, "stats": {"dash_cooldown": {"mult": 0.8}}},
	{"id": "lingering_curse", "name": "Lingering Curse", "desc": "+15% effect duration.", "rarity": "common", "kind": "stat", "icon": IC + "duration.svg", "max_stacks": 3, "stats": {"duration_mult": {"mult": 1.15}}},
	{"id": "graverobbers_luck", "name": "Graverobber's Luck", "desc": "+15% luck. Rarer choices appear more often.", "rarity": "uncommon", "kind": "stat", "icon": IC + "luck.svg", "max_stacks": 4, "stats": {"luck": {"add": 0.15}}},
	{"id": "tollkeepers_greed", "name": "Tollkeeper's Greed", "desc": "+20% score gained.", "rarity": "common", "kind": "stat", "icon": IC + "score.svg", "max_stacks": 4, "stats": {"score_mult": {"mult": 1.2}}},
	{"id": "crushing_blows", "name": "Crushing Blows", "desc": "+15% knockback.", "rarity": "common", "kind": "stat", "icon": IC + "fist.svg", "max_stacks": 3, "stats": {"knockback_mult": {"mult": 1.15}}},
	{"id": "blood_memory", "name": "Blood Memory", "desc": "Regenerate 0.6 health per second.", "rarity": "rare", "kind": "stat", "icon": IC + "heal.svg", "max_stacks": 3, "stats": {"regen": {"add": 0.6}}},
	{"id": "split_focus", "name": "Split Focus", "desc": "+1 projectile for volley weapons.", "rarity": "epic", "kind": "stat", "icon": IC + "split.svg", "max_stacks": 2, "stats": {"projectile_bonus": {"add": 1.0}}},
	{"id": "wardkeepers_vow", "name": "Wardkeeper's Vow", "desc": "+1 maximum active weapon.", "rarity": "epic", "kind": "special", "icon": IC + "gem.svg", "max_stacks": 2, "special": "weapon_cap"},

	# ===== WEAPON UNLOCKS (17) ===========================================
	{"id": "unlock_rune_knives", "name": "Awaken: Rune Knives", "desc": "Spectral daggers fan out in rotating spirals.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "rune_knives.svg", "weapon": "rune_knives"},
	{"id": "unlock_orbiting_relics", "name": "Awaken: Orbiting Relics", "desc": "Ward-stones circle you, grinding the close-in dead.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "orbiting_relics.svg", "weapon": "orbiting_relics"},
	{"id": "unlock_cursed_flame", "name": "Awaken: Cursed Flame", "desc": "Cones of keepfire that cling and burn.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "cursed_flame.svg", "weapon": "cursed_flame"},
	{"id": "unlock_bone_spikes", "name": "Awaken: Bone Spikes", "desc": "Warned ground erupts into bone.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "bone_spikes.svg", "weapon": "bone_spikes"},
	{"id": "unlock_chain_hex", "name": "Awaken: Chain Hex", "desc": "A hex-arc that leaps between enemies.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "chain_hex.svg", "weapon": "chain_hex"},
	{"id": "unlock_sanctified_nova", "name": "Awaken: Sanctified Nova", "desc": "A golden ring blasts outward from you.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "sanctified_nova.svg", "weapon": "sanctified_nova"},
	{"id": "unlock_blood_scythe", "name": "Awaken: Blood Scythe", "desc": "A sweeping crimson arc around you.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "blood_scythe.svg", "weapon": "blood_scythe"},
	{"id": "unlock_grave_bell", "name": "Awaken: Grave Bell", "desc": "Tolling rings that slow the dead.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "grave_bell.svg", "weapon": "grave_bell"},
	{"id": "unlock_thorn_sigil", "name": "Awaken: Thorn Sigil", "desc": "Bramble traps that tear at crossing enemies.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "thorn_sigil.svg", "weapon": "thorn_sigil"},
	{"id": "unlock_phantom_bow", "name": "Awaken: Phantom Bow", "desc": "Heavy ghost arrows for the strongest foes.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "phantom_bow.svg", "weapon": "phantom_bow"},
	{"id": "unlock_plague_lantern", "name": "Awaken: Plague Lantern", "desc": "Drifting clouds of green rot.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "plague_lantern.svg", "weapon": "plague_lantern"},
	{"id": "unlock_iron_maiden", "name": "Awaken: Iron Maiden", "desc": "A retaliating cage of cursed iron.", "rarity": "rare", "kind": "unlock", "icon": WI + "iron_maiden.svg", "weapon": "iron_maiden"},
	{"id": "unlock_astral_tome", "name": "Awaken: Astral Tome", "desc": "A floating grimoire that casts on its own.", "rarity": "rare", "kind": "unlock", "icon": WI + "astral_tome.svg", "weapon": "astral_tome"},
	{"id": "unlock_moon_chakram", "name": "Awaken: Moon Chakram", "desc": "Silver crescents that fly out and curve home.", "rarity": "uncommon", "kind": "unlock", "icon": WI + "moon_chakram.svg", "weapon": "moon_chakram"},
	{"id": "unlock_death_mark", "name": "Awaken: Death Mark", "desc": "Brand the doomed; the marked take more.", "rarity": "rare", "kind": "unlock", "icon": WI + "death_mark.svg", "weapon": "death_mark"},
	{"id": "unlock_storm_censer", "name": "Awaken: Storm Censer", "desc": "Violet lightning called onto the horde.", "rarity": "rare", "kind": "unlock", "icon": WI + "storm_censer.svg", "weapon": "storm_censer"},
	{"id": "unlock_saints_hammer", "name": "Awaken: Saint's Hammer", "desc": "A vast hammer falls where the horde is thickest.", "rarity": "rare", "kind": "unlock", "icon": WI + "saints_hammer.svg", "weapon": "saints_hammer"},

	# ===== WEAPON-SPECIFIC: SOUL BOLT (5) ================================
	{"id": "sb_damage", "name": "Heavier Souls", "desc": "Soul Bolt: +35% damage.", "rarity": "common", "kind": "weapon", "icon": WI + "soul_bolt.svg", "weapon": "soul_bolt", "max_stacks": 3, "wmods": {"damage": {"mult": 1.35}}},
	{"id": "sb_cooldown", "name": "Quickened Souls", "desc": "Soul Bolt: -18% cooldown.", "rarity": "common", "kind": "weapon", "icon": WI + "soul_bolt.svg", "weapon": "soul_bolt", "max_stacks": 3, "wmods": {"cooldown": {"mult": 0.82}}},
	{"id": "sb_pierce", "name": "Piercing Souls", "desc": "Soul Bolt: +1 pierce.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "soul_bolt.svg", "weapon": "soul_bolt", "max_stacks": 3, "wmods": {"pierce": {"add": 1}}},
	{"id": "sb_split", "name": "Twin Souls", "desc": "Soul Bolt: +1 bolt per volley.", "rarity": "rare", "kind": "weapon", "icon": WI + "soul_bolt.svg", "weapon": "soul_bolt", "max_stacks": 2, "wmods": {"count": {"add": 1}}},
	{"id": "sb_soulburst", "name": "Soulburst", "desc": "Soul Bolt kills detonate in a small soul explosion.", "rarity": "rare", "kind": "weapon", "icon": WI + "soul_bolt.svg", "weapon": "soul_bolt", "max_stacks": 1, "wmods": {"soulburst": {"add": 1}}},

	# ===== WEAPON-SPECIFIC: OTHERS (3 each, 51 total) ====================
	{"id": "rk_count", "name": "Knife Chorus", "desc": "Rune Knives: +2 knives.", "rarity": "common", "kind": "weapon", "icon": WI + "rune_knives.svg", "weapon": "rune_knives", "max_stacks": 3, "wmods": {"count": {"add": 2}}},
	{"id": "rk_bleed", "name": "Carving Runes", "desc": "Rune Knives: hits bleed for 35% extra damage over time.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "rune_knives.svg", "weapon": "rune_knives", "max_stacks": 2, "wmods": {"bleed": {"add": 0.35}}},
	{"id": "rk_return", "name": "Faithful Blades", "desc": "Rune Knives: knives return to you, cutting twice.", "rarity": "rare", "kind": "weapon", "icon": WI + "rune_knives.svg", "weapon": "rune_knives", "max_stacks": 1, "wmods": {"returning": {"add": 1}}},

	{"id": "or_count", "name": "Another Relic", "desc": "Orbiting Relics: +1 relic.", "rarity": "common", "kind": "weapon", "icon": WI + "orbiting_relics.svg", "weapon": "orbiting_relics", "max_stacks": 4, "wmods": {"count": {"add": 1}}},
	{"id": "or_radius", "name": "Wider Orbit", "desc": "Orbiting Relics: +25% orbit radius.", "rarity": "common", "kind": "weapon", "icon": WI + "orbiting_relics.svg", "weapon": "orbiting_relics", "max_stacks": 3, "wmods": {"radius": {"mult": 1.25}}},
	{"id": "or_pulse", "name": "Relic Pulse", "desc": "Orbiting Relics: relics pulse arcane damage outward.", "rarity": "rare", "kind": "weapon", "icon": WI + "orbiting_relics.svg", "weapon": "orbiting_relics", "max_stacks": 1, "wmods": {"pulse": {"add": 1}}},

	{"id": "cf_width", "name": "Hungry Fire", "desc": "Cursed Flame: +30% cone width.", "rarity": "common", "kind": "weapon", "icon": WI + "cursed_flame.svg", "weapon": "cursed_flame", "max_stacks": 3, "wmods": {"cone_deg": {"mult": 1.3}}},
	{"id": "cf_burn", "name": "Deeper Burn", "desc": "Cursed Flame: +60% burn damage.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "cursed_flame.svg", "weapon": "cursed_flame", "max_stacks": 3, "wmods": {"burn_dps": {"mult": 1.6}}},
	{"id": "cf_linger", "name": "Keepfire Lingers", "desc": "Cursed Flame: leaves a burning patch behind.", "rarity": "rare", "kind": "weapon", "icon": WI + "cursed_flame.svg", "weapon": "cursed_flame", "max_stacks": 1, "wmods": {"linger": {"add": 1}}},

	{"id": "bs_count", "name": "Mass Grave", "desc": "Bone Spikes: +1 eruption per cast.", "rarity": "common", "kind": "weapon", "icon": WI + "bone_spikes.svg", "weapon": "bone_spikes", "max_stacks": 3, "wmods": {"count": {"add": 1}}},
	{"id": "bs_delay", "name": "Eager Dead", "desc": "Bone Spikes: -30% eruption delay.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "bone_spikes.svg", "weapon": "bone_spikes", "max_stacks": 2, "wmods": {"delay": {"mult": 0.7}}},
	{"id": "bs_second", "name": "Restless Grave", "desc": "Bone Spikes: each sigil erupts twice.", "rarity": "rare", "kind": "weapon", "icon": WI + "bone_spikes.svg", "weapon": "bone_spikes", "max_stacks": 1, "wmods": {"second": {"add": 1}}},

	{"id": "ch_chains", "name": "Longer Hex", "desc": "Chain Hex: +2 jumps.", "rarity": "common", "kind": "weapon", "icon": WI + "chain_hex.svg", "weapon": "chain_hex", "max_stacks": 3, "wmods": {"chains": {"add": 2}}},
	{"id": "ch_fork", "name": "Forked Hex", "desc": "Chain Hex: 30% chance each jump forks.", "rarity": "rare", "kind": "weapon", "icon": WI + "chain_hex.svg", "weapon": "chain_hex", "max_stacks": 2, "wmods": {"fork": {"add": 0.3}}},
	{"id": "ch_slow", "name": "Numbing Hex", "desc": "Chain Hex: stronger, longer slow.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "chain_hex.svg", "weapon": "chain_hex", "max_stacks": 2, "wmods": {"slow": {"add": 0.15}, "slow_dur": {"add": 0.5}}},

	{"id": "sn_radius", "name": "Greater Blessing", "desc": "Sanctified Nova: +25% radius.", "rarity": "common", "kind": "weapon", "icon": WI + "sanctified_nova.svg", "weapon": "sanctified_nova", "max_stacks": 3, "wmods": {"radius": {"mult": 1.25}}},
	{"id": "sn_double", "name": "Echoed Blessing", "desc": "Sanctified Nova: pulses a second time.", "rarity": "rare", "kind": "weapon", "icon": WI + "sanctified_nova.svg", "weapon": "sanctified_nova", "max_stacks": 1, "wmods": {"double": {"add": 1}}},
	{"id": "sn_heal", "name": "Merciful Light", "desc": "Sanctified Nova: 30% chance to heal 3 on hit.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "sanctified_nova.svg", "weapon": "sanctified_nova", "max_stacks": 2, "wmods": {"heal_chance": {"add": 0.3}}},

	{"id": "bsc_arc", "name": "Wider Reaping", "desc": "Blood Scythe: +25% sweep size.", "rarity": "common", "kind": "weapon", "icon": WI + "blood_scythe.svg", "weapon": "blood_scythe", "max_stacks": 3, "wmods": {"radius": {"mult": 1.25}}},
	{"id": "bsc_lifesteal", "name": "Red Harvest", "desc": "Blood Scythe: heal 8% of damage dealt.", "rarity": "rare", "kind": "weapon", "icon": WI + "blood_scythe.svg", "weapon": "blood_scythe", "max_stacks": 2, "wmods": {"lifesteal": {"add": 0.08}}},
	{"id": "bsc_double", "name": "Second Reaping", "desc": "Blood Scythe: +1 sweep.", "rarity": "rare", "kind": "weapon", "icon": WI + "blood_scythe.svg", "weapon": "blood_scythe", "max_stacks": 1, "wmods": {"sweeps": {"add": 1}}},

	{"id": "gb_rings", "name": "Second Toll", "desc": "Grave Bell: +1 ring.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "grave_bell.svg", "weapon": "grave_bell", "max_stacks": 2, "wmods": {"rings": {"add": 1}}},
	{"id": "gb_stun", "name": "Deafening Toll", "desc": "Grave Bell: 25% chance to stun.", "rarity": "rare", "kind": "weapon", "icon": WI + "grave_bell.svg", "weapon": "grave_bell", "max_stacks": 2, "wmods": {"stun_chance": {"add": 0.25}}},
	{"id": "gb_radius", "name": "Carrying Toll", "desc": "Grave Bell: +25% ring radius.", "rarity": "common", "kind": "weapon", "icon": WI + "grave_bell.svg", "weapon": "grave_bell", "max_stacks": 3, "wmods": {"radius": {"mult": 1.25}}},

	{"id": "ts_count", "name": "Overgrowth", "desc": "Thorn Sigil: +1 sigil per cast.", "rarity": "common", "kind": "weapon", "icon": WI + "thorn_sigil.svg", "weapon": "thorn_sigil", "max_stacks": 3, "wmods": {"count": {"add": 1}}},
	{"id": "ts_duration", "name": "Deep Roots", "desc": "Thorn Sigil: +40% duration.", "rarity": "common", "kind": "weapon", "icon": WI + "thorn_sigil.svg", "weapon": "thorn_sigil", "max_stacks": 3, "wmods": {"duration": {"mult": 1.4}}},
	{"id": "ts_spread", "name": "Creeping Thorns", "desc": "Thorn Sigil: dying sigils reseed nearby.", "rarity": "rare", "kind": "weapon", "icon": WI + "thorn_sigil.svg", "weapon": "thorn_sigil", "max_stacks": 1, "wmods": {"spread": {"add": 1}}},

	{"id": "pb_crit", "name": "Hunter's Eye", "desc": "Phantom Bow: +20% crit chance.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "phantom_bow.svg", "weapon": "phantom_bow", "max_stacks": 3, "wmods": {"crit_bonus": {"add": 0.2}}},
	{"id": "pb_split", "name": "Splintering Shot", "desc": "Phantom Bow: arrows split on first hit.", "rarity": "rare", "kind": "weapon", "icon": WI + "phantom_bow.svg", "weapon": "phantom_bow", "max_stacks": 1, "wmods": {"split": {"add": 1}}},
	{"id": "pb_pierce", "name": "Ghost Piercer", "desc": "Phantom Bow: +2 pierce.", "rarity": "common", "kind": "weapon", "icon": WI + "phantom_bow.svg", "weapon": "phantom_bow", "max_stacks": 3, "wmods": {"pierce": {"add": 2}}},

	{"id": "pl_size", "name": "Thicker Rot", "desc": "Plague Lantern: +30% cloud size.", "rarity": "common", "kind": "weapon", "icon": WI + "plague_lantern.svg", "weapon": "plague_lantern", "max_stacks": 3, "wmods": {"radius": {"mult": 1.3}}},
	{"id": "pl_vuln", "name": "Festering Rot", "desc": "Plague Lantern: poisoned enemies take +15% damage.", "rarity": "rare", "kind": "weapon", "icon": WI + "plague_lantern.svg", "weapon": "plague_lantern", "max_stacks": 2, "wmods": {"vuln": {"add": 0.15}}},
	{"id": "pl_duration", "name": "Slow Decay", "desc": "Plague Lantern: +40% cloud duration.", "rarity": "common", "kind": "weapon", "icon": WI + "plague_lantern.svg", "weapon": "plague_lantern", "max_stacks": 3, "wmods": {"duration": {"mult": 1.4}}},

	{"id": "im_retal", "name": "Sharpened Cage", "desc": "Iron Maiden: +60% retaliation damage.", "rarity": "common", "kind": "weapon", "icon": WI + "iron_maiden.svg", "weapon": "iron_maiden", "max_stacks": 3, "wmods": {"damage": {"mult": 1.6}}},
	{"id": "im_emergency", "name": "Last Rites", "desc": "Iron Maiden: also triggers when you drop below 30% health.", "rarity": "rare", "kind": "weapon", "icon": WI + "iron_maiden.svg", "weapon": "iron_maiden", "max_stacks": 1, "wmods": {"emergency": {"add": 1}}},
	{"id": "im_dr", "name": "Iron Faith", "desc": "Iron Maiden: +10% damage reduction while active.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "iron_maiden.svg", "weapon": "iron_maiden", "max_stacks": 2, "wmods": {"dr": {"add": 0.1}}},

	{"id": "at_count", "name": "Second Volume", "desc": "Astral Tome: +1 tome.", "rarity": "rare", "kind": "weapon", "icon": WI + "astral_tome.svg", "weapon": "astral_tome", "max_stacks": 2, "wmods": {"count": {"add": 1}}},
	{"id": "at_speed", "name": "Speed Reading", "desc": "Astral Tome: -25% cast time.", "rarity": "common", "kind": "weapon", "icon": WI + "astral_tome.svg", "weapon": "astral_tome", "max_stacks": 3, "wmods": {"cast_cd": {"mult": 0.75}}},
	{"id": "at_empower", "name": "Forbidden Appendix", "desc": "Astral Tome: 25% chance of an empowered cast.", "rarity": "rare", "kind": "weapon", "icon": WI + "astral_tome.svg", "weapon": "astral_tome", "max_stacks": 2, "wmods": {"empowered": {"add": 0.25}}},

	{"id": "mc_count", "name": "Twin Moons", "desc": "Moon Chakram: +1 chakram.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "moon_chakram.svg", "weapon": "moon_chakram", "max_stacks": 3, "wmods": {"count": {"add": 1}}},
	{"id": "mc_distance", "name": "Far Orbit", "desc": "Moon Chakram: +35% travel distance.", "rarity": "common", "kind": "weapon", "icon": WI + "moon_chakram.svg", "weapon": "moon_chakram", "max_stacks": 3, "wmods": {"distance": {"mult": 1.35}}},
	{"id": "mc_size", "name": "Full Moon", "desc": "Moon Chakram: +30% size.", "rarity": "common", "kind": "weapon", "icon": WI + "moon_chakram.svg", "weapon": "moon_chakram", "max_stacks": 3, "wmods": {"size": {"mult": 1.3}}},

	{"id": "dm_marks", "name": "Wider Doom", "desc": "Death Mark: +2 marks per cast.", "rarity": "common", "kind": "weapon", "icon": WI + "death_mark.svg", "weapon": "death_mark", "max_stacks": 3, "wmods": {"marks": {"add": 2}}},
	{"id": "dm_explode", "name": "Loud Endings", "desc": "Death Mark: marked enemies explode on death.", "rarity": "rare", "kind": "weapon", "icon": WI + "death_mark.svg", "weapon": "death_mark", "max_stacks": 1, "wmods": {"explode": {"add": 1}}},
	{"id": "dm_spread", "name": "Contagious Doom", "desc": "Death Mark: 35% chance the mark spreads on death.", "rarity": "rare", "kind": "weapon", "icon": WI + "death_mark.svg", "weapon": "death_mark", "max_stacks": 2, "wmods": {"spread": {"add": 0.35}}},

	{"id": "sc_strikes", "name": "Gathering Storm", "desc": "Storm Censer: +1 strike.", "rarity": "common", "kind": "weapon", "icon": WI + "storm_censer.svg", "weapon": "storm_censer", "max_stacks": 3, "wmods": {"strikes": {"add": 1}}},
	{"id": "sc_radius", "name": "Broad Thunder", "desc": "Storm Censer: +30% strike radius.", "rarity": "common", "kind": "weapon", "icon": WI + "storm_censer.svg", "weapon": "storm_censer", "max_stacks": 3, "wmods": {"radius": {"mult": 1.3}}},
	{"id": "sc_double", "name": "Twin Bolts", "desc": "Storm Censer: 30% chance each strike doubles.", "rarity": "rare", "kind": "weapon", "icon": WI + "storm_censer.svg", "weapon": "storm_censer", "max_stacks": 2, "wmods": {"double": {"add": 0.3}}},

	{"id": "sh_damage", "name": "Heavier Verdict", "desc": "Saint's Hammer: +40% damage.", "rarity": "common", "kind": "weapon", "icon": WI + "saints_hammer.svg", "weapon": "saints_hammer", "max_stacks": 3, "wmods": {"damage": {"mult": 1.4}}},
	{"id": "sh_stun", "name": "Stunning Verdict", "desc": "Saint's Hammer: survivors are stunned.", "rarity": "uncommon", "kind": "weapon", "icon": WI + "saints_hammer.svg", "weapon": "saints_hammer", "max_stacks": 2, "wmods": {"stun": {"add": 0.8}}},
	{"id": "sh_crack", "name": "Broken Ground", "desc": "Saint's Hammer: leaves cracked, damaging ground.", "rarity": "rare", "kind": "weapon", "icon": WI + "saints_hammer.svg", "weapon": "saints_hammer", "max_stacks": 1, "wmods": {"crack": {"add": 1}}},

	# ===== CURSED TRADEOFFS (7) ==========================================
	{"id": "blood_pact", "name": "Blood Pact", "desc": "+50% damage. -20 max health.", "rarity": "cursed", "kind": "cursed", "icon": IC + "skull.svg", "max_stacks": 2, "stats": {"damage_mult": {"mult": 1.5}, "max_health": {"add": -20.0}}},
	{"id": "greedy_soul", "name": "Greedy Soul", "desc": "+35% XP. Enemies move 10% faster.", "rarity": "cursed", "kind": "cursed", "icon": IC + "skull.svg", "max_stacks": 2, "stats": {"xp_mult": {"mult": 1.35}}, "enemy_mods": {"speed_mult": 1.1}},
	{"id": "unstable_relic", "name": "Unstable Relic", "desc": "+2 projectiles. +25% weapon cooldowns.", "rarity": "cursed", "kind": "cursed", "icon": IC + "skull.svg", "max_stacks": 1, "stats": {"projectile_bonus": {"add": 2.0}, "cooldown_mult": {"mult": 1.25}}},
	{"id": "deaths_favor", "name": "Death's Favor", "desc": "Revive once at 40% health. Lose 15 max health when it triggers.", "rarity": "cursed", "kind": "special", "icon": IC + "skull.svg", "max_stacks": 1, "special": "revive"},
	{"id": "hollow_speed", "name": "Hollow Speed", "desc": "+30% move speed. +10% damage taken.", "rarity": "cursed", "kind": "cursed", "icon": IC + "skull.svg", "max_stacks": 2, "stats": {"move_speed": {"mult": 1.3}, "armor": {"add": -10.0}}},
	{"id": "glass_saint", "name": "Glass Saint", "desc": "+35% crit chance. -25% max health.", "rarity": "cursed", "kind": "cursed", "icon": IC + "skull.svg", "max_stacks": 1, "stats": {"crit_chance": {"add": 0.35}, "max_health": {"mult": 0.75}}},
	{"id": "overcharged_sigils", "name": "Overcharged Sigils", "desc": "+40% area. Boss and elites gain +15% health.", "rarity": "cursed", "kind": "cursed", "icon": IC + "skull.svg", "max_stacks": 1, "stats": {"area_mult": {"mult": 1.4}}, "enemy_mods": {"elite_hp_mult": 1.15}},

	# ===== SYNERGIES (8) =================================================
	{"id": "soulfire_covenant", "name": "Soulfire Covenant", "desc": "Soul Bolt ignites enemies with cursed flame.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["soul_bolt", "cursed_flame"]},
	{"id": "relic_storm", "name": "Relic Storm", "desc": "Orbiting Relics periodically zap nearby enemies.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["orbiting_relics", "chain_hex"]},
	{"id": "grave_harvest", "name": "Grave Harvest", "desc": "Killing marked enemies heals you.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["blood_scythe", "death_mark"]},
	{"id": "plague_thorns", "name": "Plague Thorns", "desc": "Thorn Sigils also poison.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["plague_lantern", "thorn_sigil"]},
	{"id": "moonlit_blades", "name": "Moonlit Blades", "desc": "Returning chakrams release rune knives.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["moon_chakram", "rune_knives"]},
	{"id": "bell_of_judgment", "name": "Bell of Judgment", "desc": "Sanctified Nova also tolls the Grave Bell.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["grave_bell", "sanctified_nova"]},
	{"id": "iron_reliquary", "name": "Iron Reliquary", "desc": "After dashing, your relics harden and strike twice as hard.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["iron_maiden", "orbiting_relics"]},
	{"id": "astral_execution", "name": "Astral Execution", "desc": "The Tome hunts marked enemies for bonus damage.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["astral_tome", "death_mark"]},
	{"id": "hexfire_lattice", "name": "Hexfire Lattice", "desc": "Chain Hex ignites everything it jumps through.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["chain_hex", "cursed_flame"]},
	{"id": "stormcallers_toll", "name": "Stormcaller's Toll", "desc": "Grave Bell rings can call lightning onto a tolled enemy.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["grave_bell", "storm_censer"]},
	{"id": "grave_tithe", "name": "Grave Tithe", "desc": "Expiring Thorn Sigils erupt into bone spikes.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["thorn_sigil", "bone_spikes"]},
	{"id": "maidens_verdict", "name": "Maiden's Verdict", "desc": "Iron Maiden retaliation also drops a small Saint's Hammer.", "rarity": "rare", "kind": "synergy", "icon": IC + "link.svg", "requires": ["iron_maiden", "saints_hammer"]},
]


static func get_upgrade(id: String) -> Dictionary:
	for u: Dictionary in UPGRADES:
		if u["id"] == id:
			return u
	return {}


static func count() -> int:
	return UPGRADES.size()
