extends UnitBody

"""
The AI unit controller.
"""

enum Intention {SLEEP, ADVANCE, RETREAT, ATTACK}

@export_group("AI")
@export var nav: NavigationAgent2D

""" Saved variables for brain """
## Behaviour constants
var my_intention : Intention = Intention.SLEEP  # records the current intention of the unit
var last_action_timestamp : int = 0  # records the time (in ms) since the unit last acted
var time_between_updates : int = 10  # for updating during the same intention (in ms)
var last_update_timestamp : int = 0  # records the time (in ms) since the last update

## Navigation
var desired_unit_target : UnitBody = null
var desired_movement_location : Vector2 = Vector2.ZERO
var desired_distance_from_allies : int = 2000

var recalculate_random_offset : bool = false  # to not constantly recalculate random elements. Once per intention is fine.
var saved_random_offset: float = 0.0

var want_to_boost: bool = false

## Loaded Move Records
var move_loaded: bool = false
var standoff_distance: float = 0.0
var min_range: float = 0.0
var max_range: float = 0.0


""" Brain """
func update_intention() -> void:
	# Updates/maintains the unit's current intention.
	# If no intention is set, sets one.
		
	# If it isn't time to act again yet, trivially keep the same intention.
	if not time_to_act():
		return
	
	# Reset once-per-intention variables
	recalculate_random_offset = true
	want_to_boost = false
		
	# Choose intention here based on situation.
	if unit.output_exceeding_limit() and feeling_threatened():
		my_intention = Intention.RETREAT
	 #elif you are able to attack:
		#my_intention = Intention.ATTACK
	else:
		my_intention = Intention.ADVANCE
	# my_intention = Intention.SLEEP

func execute_intention() -> void:
	# Based on the current intention, does the stuff to help us keep executing it properly.
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
		#start_attack()
		pass
	elif my_intention == Intention.ADVANCE:
		start_advance()
	
	# Boost works incidentally to other intentions as an add on.
	feel_like_boosting()
	

func feel_like_boosting() -> void:
	# Returns true if the unit wants to boost
	# -they have somewhere they want to go which is pretty far away
	# -not in boost cooldown
	# -hasn't been too soon since you just switched to this intention
	#if all these conditions are met, then set 'want_to_boost' to true
	pass
	

""" Execution Functions """

func start_sleep() -> void:
	var random_walk: Vector2 = Vector2.ZERO
	if recalculate_random_offset:
		var random_direction = calculate_random_offset_rotation(2*PI)
		random_walk = Vector2(1000.0, 0.0).rotated(random_direction)
	
	desired_movement_location = position + random_walk

func start_advance() -> void:
	# For advance, they want to follow the action.
	# This means follow their chosen target by a certain distance.
	
	## 1. Decide where the action is
	choose_target()
	
	## 2. Add offset to unit to find desired location
	# a. standoff offset
	# b. ally offset
	var ally_offset_vector: Vector2 = Vector2.ZERO
	if too_close_to_ally():
		ally_offset_vector = calculate_ally_offset_vector()
	
	# update target position
	desired_movement_location = desired_unit_target.position + ally_offset_vector

func start_retreat() -> void:
	# For retreat, they want to create space from the closest unit.
	# This means pick a spot away from the closest target and also some randomness.
	
	
	# take the direction to the closest hostile, flip it around
	# then multiply by a magnitude of 1000 or whatever
	var closest_hostile_position: Vector2 = GameMother.get_closest_hostile_position(unit.allegiance, unit.combat_id, position)
	var retreat_direction: Vector2 = position.direction_to(closest_hostile_position) * -1
	
	# apply randomness to retreat direction
	var retreat_direction_offset: float = calculate_random_offset_rotation(PI)
	retreat_direction = retreat_direction.rotated(retreat_direction_offset)
	retreat_direction *= standoff_distance
		
	# update target position
	desired_movement_location = position + retreat_direction

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
		direction_away = global_position.direction_to(closest_friendly_position)
		# rotate by 90
		direction_away_rotated = direction_away.rotated(PI/2)
	
	# calculate position with respect to target's position, move standoff, and closeness to allies
	var spacing_vector: Vector2 = (direction_away_rotated * closest_friendly_mag)
	return spacing_vector

func choose_target() -> void:
	# Chooses the most appealing unit target on the map, favouring:
	#	- low geographical distance to them
	#	- low number of other units targeting them
	var check_target_score: float = 0.0
	var check_target: UnitBody = null
	for opp in GameMother.get_opponents(unit.allegiance):
		if opp.defeated:
			continue
		# score based on proximity to target (closer is a higher score)
		var dist_score: float = 1 / position.distance_to(opp.position)

		# score based on the number of other units already targeting target
		var cotargeter_count: int = GameMother.get_cotargeter_count(opp)
		#if opp == desired_unit_target:  # if you yourself are targeting them, subtract 1.
			#cotargeter_count -= 1
		var cotargeter_score: float = (1.0 / max(cotargeter_count, 1))

		#print("relative scores are dist | cotargeter: " + str(dist_score) + " | " + str(cotargeter_score))
		var temp_score: float = (1000 * dist_score) + (cotargeter_score)
		if temp_score > check_target_score:
			check_target_score = temp_score
			check_target = opp
		
	GameMother.update_cotargeting(desired_unit_target, check_target)
	desired_unit_target = check_target

func time_to_act() -> bool:
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
	if my_intention == Intention.ADVANCE:
		return standoff_distance
	elif my_intention == Intention.RETREAT:
		return standoff_distance / 2
	return 0.0

""" Supers """
func end_combo_ai() -> void:
	# pure virtual
	move_loaded = false

func get_direction_input() -> Vector2:
	# Returns the vector that the unitBody wants to move in
	var current_agent_position: Vector2 = position
	# if you are close enough that you are within standoff distance, don't move any more.
	if current_agent_position.distance_to(desired_movement_location) < get_standoff_helper():
		return Vector2.ZERO
	# otherwise, just move where you like.
	return current_agent_position.direction_to(nav.get_next_path_position())	

func get_target_position() -> Vector2:
	# Returns the vector that the unitBody wants to look at
	if desired_unit_target and my_intention == Intention.ATTACK:  # if you're attacking, look em in the eye
		return desired_unit_target.position
	else:  # otherwise, look where you're going
		return nav.get_next_path_position()
	
func get_attack_input() -> bool:
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
	update_intention()
	execute_intention()
	set_nav_movement_target()
	
	super(delta)
	
