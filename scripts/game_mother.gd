extends Node2D


"""
Holds references to units in an encounter scene so the ai can look them up.
Also holds gamerules and stuff like that too.

"""


""" Tracking during battle """
var heroes : Array[UnitBody] = []  # Anse and friends
var villains : Array[UnitBody] = []  # Opponents to Anse and friends
#var thirds : Array[UnitBody]  # enemies of all

""" Encounter Setup Functions """
func add_hero(unit: UnitBody) -> void:
	heroes.append(unit)
	
func add_villain(unit: UnitBody) -> void:
	villains.append(unit)
	
""" Encounter Getters """
func get_heroes() -> Array[UnitBody]:
	return heroes
func get_villains() -> Array[UnitBody]:
	return villains
