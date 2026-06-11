extends Node

var owned: Dictionary = {}
var weapon_cap := 6


func owned_count() -> int:
	return owned.size()
