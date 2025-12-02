extends Node2D


"""
Holds references to units in an encounter scene so the ai can look them up.
Also holds gamerules and stuff like that too.

"""

@export_group("UI")
@export var logLabel : Label

""" Tracking during battle """
var heroes : Array[UnitBody] = []  # Anse and friends
var villains : Array[UnitBody] = []  # Opponents to Anse and friends
#var thirds : Array[UnitBody]  # enemies of all

""" Encounter Setup Functions """
func setup_UI() -> void:
	pass
	#logLabel.text = "testing ui text"

func add_hero(unit: UnitBody) -> void:
	heroes.append(unit)
	
func add_villain(unit: UnitBody) -> void:
	villains.append(unit)

func assign_combat_ids() -> void:
	# given all the heroes and villains, assigns unique combat ids to all of them.
	# necessary so we don't hit the same unit more than once with a single attack.
	var id_value: int = 0
	for hero in get_heroes():
		hero.unit.combat_id = id_value
		id_value += 1
	for villain in get_villains():
		villain.unit.combat_id = id_value
		id_value += 1

""" UI Functions """
func log_hit(damage: int, user_id: int, target_id: int) -> void:
	pass
	#logLabel.text = "A hit was scored!"

""" Encounter Getters """
func get_heroes() -> Array[UnitBody]:
	return heroes
func get_villains() -> Array[UnitBody]:
	return villains
