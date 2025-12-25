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
var attack_priority_counter: int = 0

""" Encounter Setup Functions """
func setup_UI() -> void:
	pass
	#logLabel.text = "testing ui text"

func add_hero(unit: UnitBody) -> void:
	heroes.append(unit)
	#add_child(unit)
	
func add_villain(unit: UnitBody) -> void:
	villains.append(unit)
	#add_child(unit)

func assign_combat_ids() -> void:
	# given all the heroes and villains, assigns unique combat ids to all of them.
	# necessary so we don't hit the same unit more than once with a single attack.
	var id_value: int = 0
	for hero in heroes:
		hero.unit.combat_id = id_value
		id_value += 1
	for villain in villains:
		villain.unit.combat_id = id_value
		id_value += 1

""" Managing Functions """
func assign_attack_priority() -> int:
	attack_priority_counter += 1
	return attack_priority_counter

func accept_targeting(active_unit_id: int, receiver_unit_id: int):
	# receives and records information to represent that
	# unit 'active_unit_id' is targeting 'receiver_unit_id'
	pass
	
func tell_about_targeting(receiver_unit_id: int):
	# when asked about 'receiver_unit_id', gives the number of units targeting it.
	# -1 if you yourself are also targeting them.
	pass

func get_closest_friendly_position(user_allegiance: int, my_combat_id: int, my_pos: Vector2) -> Vector2:
	# Return the min distance to any villain unit that is not this unit
	# (does not have the same combat_id)
	var relevant_unit_list
	# {PLAYER, ALLY, ENEMY}
	if user_allegiance == 2:
		relevant_unit_list = heroes
	else:
		relevant_unit_list = villains
	
	var closest_position: Vector2 = Vector2.ZERO
	for check_unit in relevant_unit_list:
		if check_unit and my_combat_id != check_unit.unit.combat_id:
			var diff: float = (my_pos - check_unit.position).length()
			if closest_position == Vector2.ZERO or diff < (my_pos - closest_position).length():
				closest_position = check_unit.position
		
	return closest_position

""" UI Functions """
func log_hit(damage: int, user_id: int, target_id: int) -> void:
	#logLabel.text = "A hit was scored!"
	return

""" Encounter Getters """
func get_opponents(user_allegiance: int) -> Array[UnitBody]:
	# {PLAYER, ALLY, ENEMY}
	if user_allegiance == 2:
		return heroes
	return villains
