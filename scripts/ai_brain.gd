extends UnitBody

"""
The AI unit controller.
"""

enum Intention {SLEEP, ADVANCE, RETREAT, ATTACK}
@export var nav: NavigationAgent2D

@export_group("AI")
@export var allowed_to_boost: bool
@export var allowed_to_pick_off: bool
@export var allowed_to_actively_dodge: bool
@export var allowed_to_target_swap: bool
@export var allowed_to_know_enemy_permission: bool

""" Saved variables for brain """
## Behaviour constants
var my_intention : Intention = Intention.SLEEP  # records the current intention of the unit
var last_action_timestamp : int = 0  # records the time (in ms) since the unit last acted
var time_between_updates : int = 10  # for updating during the same intention (in ms)
var last_update_timestamp : int = 0  # records the time (in ms) since the last update

## Navigation
var desired_unit_target : UnitBody = null
var desired_movement_location : Vector2 = Vector2.ZERO
var desired_distance_from_allies : int = 3000

var recalculate_random_offset : bool = false  # to not constantly recalculate random elements. Once per intention is fine.
var saved_random_offset: float = 0.0
var already_chosen_target: bool = false  # to not constantly osciallate between targets

var want_to_boost: bool = false
var want_to_attack: bool = false
var obtained_attack_permission: bool = false
var attack_permission_delay: int = 0
var getting_beat: bool = false
var cornered: bool = false

## Loaded Move Records
var move_loaded: bool = false
var standoff_distance: float = 0.0
var min_range: float = 0.0
var max_range: float = 0.0


""" Brain """
func _ready() -> void:
	super()

func update_intention() -> void:
	# Updates/maintains the unit's current intention.
	# If no intention is set, sets one.
		
	# If it isn't time to act again yet, trivially keep the same intention.
	if not time_to_act():
		return
	
	# Reset once-per-intention variables
	GameMother.attack_ceded(self, desired_unit_target, obtained_attack_permission)
	recalculate_random_offset = true
	already_chosen_target = false
	want_to_boost = false
	want_to_attack = false
	getting_beat = false
	cornered = false
	obtained_attack_permission = false
	attack_permission_delay = 0
	
	#my_intention = Intention.RETREAT
	#return
				
	# Choose intention here based on situation.
	if unit.output_exceeding_limit() and feeling_threatened():
		my_intention = Intention.RETREAT
		#print("i INTEND to retreat haha")
	elif feel_like_attacking():
		my_intention = Intention.ATTACK
	else:  # idk, maybe advance permission
		my_intention = Intention.ADVANCE
	
func execute_intention() -> void:
	# Based on the current intention, does the stuff to help us keep executing it properly.
	
	#if unit.allegiance == 1:
		#print("desired_movement_location = " + str(desired_movement_location))
		#print("desired_movement_location = " + str(desired_unit_target.position))
	
	if not time_to_update():
		return
	if not move_loaded:
		load_move_stats()
	
	# Based on the situation, chooses where the unit wants to walk to and look at.
	if my_intention == Intention.SLEEP:
		start_sleep()
	elif my_intention == Intention.RETREAT:
		start_retreat()
	elif my_intention == Intention.ATTACK:
		start_attack()
	elif my_intention == Intention.ADVANCE:
		start_advance()
	
	# Boost works incidentally to other intentions as an add on.
	want_to_boost = feel_like_boosting()

func feel_like_boosting() -> bool:
	# Returns true if the unit wants to boost
	if not allowed_to_boost or my_intention == Intention.ATTACK:
		return false
	
	if allowed_to_actively_dodge and getting_beat:
		# maybe add a little delay before it though?
		return true
	
	# -if your destination is too close, permission denied.
	var dist_to_destination: float = position.distance_to(desired_movement_location)
	if dist_to_destination < Coeff.boost_min_distance_to_trigger:
		return false

	
	
	# -if it hasn't been long enough in this intention, denied.
	var current_time: int = Time.get_ticks_msec()
	var time_since_intention_switch: int = current_time - last_action_timestamp
	if time_since_intention_switch < Coeff.time_before_boost_permitted:
		return false
	
	return true
	
func feel_like_attacking() -> bool:
	## Return true to give the unit the go ahead to attack. Basically, you need:
	# -have attack permission
	if not desired_unit_target:
		choose_target()
		if not desired_unit_target:
			return false
	
	var dist_to_target: float = position.distance_to(desired_unit_target.position)
	if not (dist_to_target > min_range and dist_to_target < max_range):
		return false
		
	## boolean attack permission method
	# further, you must have attack permission (reset on combo end)
	obtained_attack_permission = GameMother.get_attack_permission(self, desired_unit_target)
	if not obtained_attack_permission:
		return false
	
	return true

""" Coordination and Reaction Functions """
func quick_authorize_attack() -> void:
	## Called from gamemother to immediately authorize this guy's attack (with a slight delay though)
	#print("quick_authorize_attack() called")
	#if my_intention != Intention.RETREAT:
	my_intention = Intention.ATTACK
	obtained_attack_permission = true
	last_action_timestamp = Time.get_ticks_msec()
	attack_permission_delay = Time.get_ticks_msec() + Coeff.attack_permission_timer
	
	choose_target()
	
func quick_cede_attack() -> void:
	## Informs gamemother that we no longer need to use attack permission.
	# And thus gamemother can give it to someone else.
	#print("quick_cede_attack() called")
	move_loaded = false
	want_to_attack = false
	
	# retreat and update your action right away!
	my_intention = Intention.RETREAT
	#last_action_timestamp = Time.get_ticks_msec() - Coeff.time_between_intention_update
	last_update_timestamp = Time.get_ticks_msec() - Coeff.time_between_intention_update  
	
	if desired_unit_target:
		GameMother.attack_ceded(self, desired_unit_target, obtained_attack_permission)
	obtained_attack_permission = false

""" Execution Functions """

func start_sleep() -> void:
	if recalculate_random_offset:
		var random_walk: Vector2 = Vector2.ZERO
		var random_direction: float = calculate_random_offset_rotation(2*PI)
		var sleep_walk_distance: float = 1500.0
		random_walk = Vector2(sleep_walk_distance, 0.0).rotated(random_direction)
		desired_movement_location = position + random_walk

func start_advance() -> void:
	# For advance, they want to follow the action.
	# This means follow their chosen target by a certain distance.
	
	## 1. Decide where the action is
	choose_target()
	if not desired_unit_target:
		return
	
	## 2. Add offset to unit to find desired location
	# a. standoff offset
	# b. ally offset
	var ally_offset_vector: Vector2 = Vector2.ZERO
	if too_close_to_ally():
		ally_offset_vector = calculate_ally_offset_vector()
		if unit.allegiance == 1:
			ally_offset_vector = ally_offset_vector / 2
	
	# update target position
	desired_movement_location = desired_unit_target.position + ally_offset_vector

func start_retreat() -> void:
	# For retreat, they want to create space from the closest unit.
	# This means pick a spot away from the closest target and also some randomness.
	
	if cornered:
		# commit to escaping the corner for at least like 200 ms
		#if not GameMother.is_cornered(position):
		return
	
	# take the direction to the closest hostile, flip it around
	# then multiply by a magnitude of 1000 or whatever
	var closest_hostile_position: Vector2 = GameMother.get_closest_hostile_position(unit.allegiance, unit.combat_id, position)
	if closest_hostile_position == Vector2.ZERO:
		return
	
	var retreat_direction: Vector2 = closest_hostile_position.direction_to(position) * -1
	
	# apply randomness to retreat direction
	retreat_direction *= standoff_distance
	if GameMother.is_cornered(position):
		retreat_direction *= -1
		cornered = true
		# commit to trying to escape the corner for the next __ ms
		# if Time.get_ticks_msec() > last_action_timestamp + Coeff.time_between_intention_update:
		# 2000 > 1000 + 2000: you will act in 1000 ms
		# now i want to set it to act in 200 ms from now. I want:
		# last_action_timestamp + Coeff.time_between_intention_update = 2200
		last_action_timestamp = 500 + Time.get_ticks_msec() - Coeff.time_between_intention_update
	else:
		var retreat_direction_offset: float = calculate_random_offset_rotation(PI / 4)
		retreat_direction = retreat_direction.rotated(retreat_direction_offset)
		
	# update target position
	desired_movement_location = position + (retreat_direction * 2.5)
	#print(desired_movement_location)

func start_attack() -> void:
	# the 'advance' intention got us into a starting spot.
	# now, all we have to down is dive the opponent.
	# set the destination to be right on their face, and look straight at them.
	#	^actually, add another field to accompany 'standoff', 'execution_standoff'
	#	this one tells us how close you want to be during execution itself.
	if not desired_unit_target or Time.get_ticks_msec() < attack_permission_delay:
		start_sleep()
		return
	want_to_attack = true
	# add in standoff too
	# 1. find vector from target to you
	# 2. normalize it
	# 3. multiply by standoff
	# 4. that is your desired movement location, tada
	var standoff_vector: Vector2 = (desired_unit_target.position - position).normalized() * get_standoff_helper()
	desired_movement_location = desired_unit_target.position - standoff_vector
	#print("raw target position = " + str(desired_unit_target.position))
	#print("with standoff it is = " + str(desired_movement_location))
		
	# check that you will be able to properly hit the target
	var dist_to_target: float = position.distance_to(desired_unit_target.position)
	if (dist_to_target < max_range):
		want_to_attack = true
	else:
		want_to_attack = false
		
	# check that the angle is right
	# do not attack if we are not looking within _ degrees of the target
	var vector_from_unit_to_target = global_position.direction_to(desired_unit_target.position)
	var own_direction_vector = get_ring_indicator_vector()
	var angle_from_self_to_target = vector_from_unit_to_target.dot(own_direction_vector)
	
	# if not in combo, much stricter angle requirement
	var angle_req: float = 0.99  # (angle IS NOT narrower than [very narrow])
	if unit.in_combo:
		angle_req = 0.7
	if want_to_attack and angle_from_self_to_target < angle_req:  
		want_to_attack = false
		
	
func feeling_threatened() -> bool:
	# basically, if someone is within a certain distance from you
	var closest_hostile_position: Vector2 = GameMother.get_closest_hostile_position(unit.allegiance, unit.combat_id, position)
	#if closest_hostile_position.distance_to(position) < Coeff.feel_threatened_at_distance:
	if closest_hostile_position.distance_to(position) < standoff_distance:
		return true
	return false

""" Helpers """
func too_close_to_ally() -> bool:
	var closest_friendly_position: Vector2 = GameMother.get_closest_friendly_position(unit.allegiance, unit.combat_id, position)
	if closest_friendly_position != Vector2.ZERO:
		var closest_friendly_distance = position.distance_to(closest_friendly_position)
		if closest_friendly_distance < desired_distance_from_allies / 2.0:  # only half here so they can settle.
			return true
	
	return false

func calculate_random_offset_rotation(range_value: float) -> float:
	if recalculate_random_offset:
		recalculate_random_offset = false
		var ran: float = GameMother.rng.randf_range(-range_value/2.0, range_value/2.0)
		saved_random_offset = ran
	return saved_random_offset

func calculate_ally_offset_vector() -> Vector2:
	var closest_friendly_mag: float = 0.0
	var direction_away: Vector2 = Vector2.ZERO
	var direction_away_rotated: Vector2 = Vector2.ZERO
	var closest_friendly_position: Vector2 = GameMother.get_closest_friendly_position(unit.allegiance, unit.combat_id, position)
	if closest_friendly_position != Vector2.ZERO:
		closest_friendly_mag = (position - closest_friendly_position).length() * desired_distance_from_allies
		#closest_friendly_mag = desired_distance_from_allies
		direction_away = global_position.direction_to(closest_friendly_position)
		# rotate by a random value in range PI/4 to 3 PI/4 (45 degrees to 135 degrees)
		#var random_rotation: float = GameMother.rng.randf_range(PI/4, 3 * PI/4)
		#direction_away_rotated = direction_away.rotated(random_rotation)
		direction_away_rotated = direction_away.rotated(PI/2)
	
	# calculate position with respect to target's position, move standoff, and closeness to allies
	var spacing_vector: Vector2 = (direction_away_rotated * closest_friendly_mag)
	#print(str(spacing_vector))
	return spacing_vector

func choose_target() -> void:
	# Chooses the most appealing unit target on the map, favouring:
	#	- low geographical distance to them
	#	- low number of other units targeting them
	if already_chosen_target and desired_unit_target != null:
		return
	already_chosen_target = true
	var check_target_score: float = 0.0
	var check_target: UnitBody = null
	for opp in GameMother.get_opponents(unit.allegiance):
		if opp.defeated:
			continue
		# score based on proximity to target (closer is a higher score)
		var dist_score: float = 1 / position.distance_to(opp.position)

		# score based on the number of other units already targeting target
		var cotargeter_count: int = GameMother.get_cotargeter_count(opp)
		if opp == desired_unit_target:  # if you yourself are targeting them, subtract 1.
			cotargeter_count -= 1
		var cotargeter_score: float = (1.0 / max(cotargeter_count, 1))
		
		# score based on how supported the enemy is (more isolated being better)
		var pick_off_score: float = 0.0
		if allowed_to_pick_off:
			pick_off_score = GameMother.get_average_friendly_distance(opp)
			
		var counterattack_score: float = 0.0
		if allowed_to_know_enemy_permission:
			var well_are_they: bool = GameMother.is_opp_holding_permission_on_me(unit.combat_id, opp)
			if well_are_they:
				counterattack_score = 1000.0

		#print("relative scores are dist | cotargeter: " + str(dist_score) + " | " + str(cotargeter_score))
		var temp_score: float = (1000 * dist_score) + (cotargeter_score) + (pick_off_score / 2500) + (counterattack_score * 50)
		if temp_score > check_target_score:
			check_target_score = temp_score
			check_target = opp
	
	#if not check_target:
		#return
	GameMother.update_cotargeting(desired_unit_target, check_target)
	desired_unit_target = check_target

func time_to_act() -> bool:
	# prevent units from interrupting themselves in the middle of executing a combo
	if unit.in_combo:
		return false
	
	var current_time: int = Time.get_ticks_msec()
	if current_time > last_action_timestamp + Coeff.time_between_intention_update:
		last_action_timestamp = current_time
		return true
	return false

func time_to_update() -> bool:
	var current_time: int = Time.get_ticks_msec()
	if current_time > last_update_timestamp + time_between_updates: 
		last_update_timestamp = current_time
		return true
	return false

func set_nav_movement_target() -> void:
	nav.target_position = desired_movement_location

func load_move_stats() -> void:
	var packed_loaded_move = unit.loadout.peek_next_move()
	var loaded_move = packed_loaded_move.instantiate()
	
	#hold_timer = loaded_move.get_move_timer()
	#cooldown_timer = loaded_move.get_cooldown_timer()
	standoff_distance = loaded_move.get_standoff_distance()
	min_range = loaded_move.get_min_range()
	max_range = loaded_move.get_max_range()
	loaded_move.queue_free()
	move_loaded = true

func get_standoff_helper() -> float:
	if my_intention == Intention.SLEEP:
		return 100.0
	if my_intention == Intention.ADVANCE or my_intention == Intention.ATTACK:
		return standoff_distance
	elif my_intention == Intention.RETREAT:
		return standoff_distance / 2
	return 0.0

func validate_target() -> void:
	if desired_unit_target and not desired_unit_target.defeated and is_instance_valid(desired_unit_target):
		return
	desired_unit_target = null

""" Supers """
func report_hit_ai() -> void:
	# you hit, so start prepping for the next move
	load_move_stats()
	#if allowed_to_target_swap:
		#already_chosen_target = false
		#choose_target()

func being_hit_ai() -> void:
	getting_beat = true
	quick_cede_attack()

func end_combo_ai() -> void:
	quick_cede_attack()

func get_direction_input() -> Vector2:
	# Returns the vector that the unitBody wants to move in	
	var current_agent_position: Vector2 = position
	# if you are close enough that you are within standoff distance, don't move any more.
	if my_intention == Intention.ADVANCE and current_agent_position.distance_to(desired_movement_location) < get_standoff_helper():
		# you are in range now, so convert intention to attack
		if feel_like_attacking():
			my_intention = Intention.ATTACK
		else:
			my_intention = Intention.SLEEP
		return Vector2.ZERO
	
	# otherwise, just move where you like.
	return current_agent_position.direction_to(nav.get_next_path_position())

func get_target_position() -> Vector2:
	# Returns the vector that the unitBody wants to look at
	if desired_unit_target and (my_intention == Intention.ATTACK or unit.in_combo):  # if you're attacking, look em in the eye
		return desired_unit_target.position
	else:  # otherwise, look where you're going
		return nav.get_next_path_position()
	
func get_attack_input() -> bool:
	#return false  # for testing, uncomment for peaceful guys.
	
	if want_to_attack and desired_unit_target:
		if allowed_to_target_swap:
			already_chosen_target = false
			choose_target()
		return true
	return false

func get_boost_input(direction: Vector2) -> bool:
	if boost_duration > 0.0:  # already boosting
		return true
	# want to boost and able to
	if want_to_boost and boost_cooldown <= 0.0 and direction.length() > 0:  # start boosting
		go_boost(direction)
		return true
	return false

func _physics_process(delta):
	if not defeated:
		validate_target()
		update_intention()
		execute_intention()
		set_nav_movement_target()
	
	super(delta)
	
