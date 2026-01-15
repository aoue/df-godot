extends Node2D


"""
Holds references to units in an encounter scene so the ai can look them up.
Also holds gamerules and stuff like that too.

"""

@export_group("UI")
@export var logLabel : Label

var rng = RandomNumberGenerator.new()

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

func add_unit(unitbody: UnitBody) -> void:
	if unitbody.unit.allegiance == 2:
		villains.append(unitbody)
	else:
		heroes.append(unitbody)

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
	
	# update cotargeting
	if unit_to_remove.unit.allegiance != 0:
		update_cotargeting(unit_to_remove.desired_unit_target, null)
	
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

func get_cotargeter_count(some_unitbody: UnitBody) -> int:
	# when asked about 'receiver_unit_id', gives the number of units targeting it.
	# -1 if you yourself are also targeting them.
	if some_unitbody:
		var unit_id: int = some_unitbody.unit.combat_id
		if unit_id not in cotargeting_dict:
			return 0
		return cotargeting_dict[unit_id]
	return 0

func get_closest_hostile_position(user_allegiance: int, my_combat_id: int, my_pos: Vector2) -> Vector2:
	var relevant_unit_list: Array[UnitBody]
	# {PLAYER, ALLY, ENEMY}
	if user_allegiance == 2:
		relevant_unit_list = heroes
	else:
		relevant_unit_list = villains
	return get_closest_unit_position(my_combat_id, my_pos, relevant_unit_list)

func get_closest_friendly_position(user_allegiance: int, my_combat_id: int, my_pos: Vector2) -> Vector2:
	# Return the min distance to any villain unit that is not this unit
	# (does not have the same combat_id)
	var relevant_unit_list: Array[UnitBody]
	# {PLAYER, ALLY, ENEMY}
	if user_allegiance == 2:
		relevant_unit_list = villains
	else:
		relevant_unit_list = heroes
	return get_closest_unit_position(my_combat_id, my_pos, relevant_unit_list)
	
func get_closest_unit_position(my_combat_id, my_pos: Vector2, relevant_unit_list: Array[UnitBody]) -> Vector2:
	var closest_position: Vector2 = Vector2.ZERO
	for check_unit in relevant_unit_list:
		if check_unit and my_combat_id != check_unit.unit.combat_id:
			var diff: float = (my_pos - check_unit.position).length()
			if closest_position == Vector2.ZERO or diff < (my_pos - closest_position).length():
				closest_position = check_unit.position
		
	return closest_position

""" Attack Permission Mechanic """
#func get_attack_permission_delay(attacker_combat_id: int, some_unitbody: UnitBody) -> int:
	## To stop enemy units from attacking the player literally all at once.
	## Coordinates attackers instead so they may attack in sequence but not all at once.
	## The delay is larger the more enemies are trying to attack the same unit.
	#if some_unitbody:
		#var unit_id: int = some_unitbody.unit.combat_id
		#if unit_id not in cotargeting_dict:
			#return 0
		#@warning_ignore("integer_division")
		##return cotargeting_dict[unit_id] * (Coeff.time_between_intention_update)
		### delay function: delay = sqrt(units cotargeting) * constant (more gradual growth)
		##return sqrt(cotargeting_dict[unit_id]) * Coeff.attack_delay_per_cotargeter
		### delay function: delay = (attacker's unit id) % (units cotargeting) * constant
		#return (attacker_combat_id % max(1, cotargeting_dict[unit_id])) * Coeff.attack_delay_per_cotargeter
	#return 0

func attack_ceded(actor_unitbody, target_unitbody) -> void:
	"""
	remove the unitbody with ceder's id from the list
		for all unitbodies that want to hit the target:
			find the closest
		finally, closest.quick_authorize_attack()
	"""
	#var actor_unit_id: int = actor_unitbody.unit.combat_id
	#for body in attackPermission_dict[target_unit_id]:
		#if actor_unit_id == body.unit.combat_id:
	var target_unit_id: int = target_unitbody.unit.combat_id
	if target_unit_id not in attackPermission_dict:
		return
	var relevant_unit_list = attackPermission_dict[target_unit_id]
	
	#print("pre:" + str(relevant_unit_list.size()))
	relevant_unit_list.erase(actor_unitbody)
	#print("post:" + str(relevant_unit_list.size()))

	# get the unit in the list that is closest to target_unitbody and give them attack permission
	var closest_position: Vector2 = Vector2.ZERO
	var saved_unit: UnitBody = null
	var target_pos: Vector2 = target_unitbody.position
	for check_unit in relevant_unit_list:
		if check_unit:
			var diff: float = (target_pos - check_unit.position).length()
			if closest_position == Vector2.ZERO or diff < (target_pos - closest_position).length():
				saved_unit = check_unit
				closest_position = check_unit.position
	
	if saved_unit:
		saved_unit.quick_authorize_attack()

func get_attack_permission(actor_unitbody: UnitBody, target_unitbody: UnitBody) -> bool:
	# Stop enemies from attacking a single target all at once. They have to take their turn, in a way.
	# Returns true if the asker is given permission to attack, and also updates the dictionary kvp with the current time.
	# Returns false if the asker is not given permission to attack. Does nothing.
	# (each dict entry[unit id] is tied to a time value. When enough time has passed, give permission to attack.)
	#print(attackPermission_dict)
	if target_unitbody:
		var target_unit_id: int = target_unitbody.unit.combat_id
		#var current_time: int = Time.get_ticks_msec()
		# trivial case: unit does not exist
		if target_unit_id not in attackPermission_dict:
			attackPermission_dict[target_unit_id] = []
			attackPermission_dict[target_unit_id].append(actor_unitbody)
			return true
		# normal case: unit exists; compare current time to recorded time of last attack permission given
		elif attackPermission_dict[target_unit_id].size() == 0:
			attackPermission_dict[target_unit_id].append(actor_unitbody)
			return true
		else:
			# then you have permission. Do update the attack permission dict before you go.
			if actor_unitbody not in attackPermission_dict[target_unit_id]:
				attackPermission_dict[target_unit_id].append(actor_unitbody)
			return false
	
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
