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
#var thirds : Array[UnitBody]  # opponents of all
var attack_priority_counter: int = 0
var cotargeting_dict = {}  # records targeting info, 'id being targeted': count
var attackPermission_dict = {}  # records active attacking info, 'id being targeted': time since last attack on them

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

""" Assisting AI Decision-Making Functions """
func assign_attack_priority() -> int:
	attack_priority_counter += 1
	return attack_priority_counter

func free_unit(flag: int, unit_to_remove: UnitBody) -> void:
	# Given 'flag' and 'id_to_free', erases the given unit from memory.
	# {PLAYER, ALLY, ENEMY}
	if flag == 2:
		villains.erase(unit_to_remove)
	else:
		heroes.erase(unit_to_remove)

func update_cotargeting(old_unitbody: UnitBody, new_unitbody: UnitBody) -> void:
	# remove a targeting occurrence
	if old_unitbody:
		var old_unit_id: int = old_unitbody.unit.combat_id
		if old_unit_id in cotargeting_dict:
			cotargeting_dict[old_unit_id] -= 1
		else:
			cotargeting_dict[old_unit_id] = 0

	# add an targeting occurrence
	if new_unitbody:
		var new_unit_id: int = new_unitbody.unit.combat_id
		if new_unit_id in cotargeting_dict:
			cotargeting_dict[new_unit_id] += 1
		else:
			cotargeting_dict[new_unit_id] = 1
	#print(cotargeting_dict)

func get_cotargeter_count(some_unitbody: UnitBody) -> int:
	# when asked about 'receiver_unit_id', gives the number of units targeting it.
	# -1 if you yourself are also targeting them.
	if some_unitbody:
		var unit_id: int = some_unitbody.unit.combat_id
		if unit_id not in cotargeting_dict:
			return 0
		return cotargeting_dict[unit_id]
	return 0

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

""" Attack Permission Mechanic """
func get_attack_permission(some_unitbody: UnitBody) -> bool:
	# Stop enemies from attacking a single target all at once. They have to take their turn, in a way.
	# Returns true if the asker is given permission to attack, and also updates the dictionary kvp with the current time.
	# Returns false if the asker is not given permission to attack. Does nothing.
	# (each dict entry[unit id] is tied to a time value. When enough time has passed, give permission to attack.)
	#print(attackPermission_dict)
	if some_unitbody:
		var unit_id: int = some_unitbody.unit.combat_id
		var current_time: int = Time.get_ticks_msec()
		# trivial case: unit does not exist
		if unit_id not in attackPermission_dict:
			attackPermission_dict[unit_id] = current_time + Coeff.attack_permission_timer
			return true
		# normal case: unit exists; compare current time to recorded time of last attack permission given
		elif current_time > attackPermission_dict[unit_id]:
			# then you have permission. Do update the attack permission dict before you go.
			attackPermission_dict[unit_id] = current_time + Coeff.attack_permission_timer
			return true
				
	return false

""" UI Functions """
func log_hit(_damage: int, _user_id: int, _target_id: int) -> void:
	#logLabel.text = "A hit was scored!"
	return

""" Encounter Getters """
func get_opponents(user_allegiance: int) -> Array[UnitBody]:
	# {PLAYER, ALLY, ENEMY}
	if user_allegiance == 2:
		return heroes
	return villains
