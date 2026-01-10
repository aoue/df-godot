extends UnitBody

"""
The AI unit controller.
"""

enum Intention {SLEEP, ADVANCE, RETREAT, ATTACK}

@export_group("AI")
@export var nav: NavigationAgent2D

""" Saved variables for brain """
## Behaviour constants
var my_intention : Intention  # records the current intention of the unit
var last_action_timestamp : int = 0  # records the time (in ms) since the unit last acted
var time_between_updates : int = 1000  # for updating during the same intention (in ms)
var last_update_timestamp : int = 0  # records the time (in ms) since the last update

## Navigation
var desired_unit_target : UnitBody = null
var desired_movement_location : Vector2 = Vector2.ZERO
var desired_distance_from_allies : int = 2000

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

	# otherwise, chooses intention here.
	my_intention = Intention.ADVANCE

func execute_intention() -> void:
	# Based on the current intention, does the stuff to help us keep executing it properly.
	if not time_to_update():
		return
	if not move_loaded:
		load_move_stats()
	
	if my_intention == Intention.ADVANCE:
		start_advance()

""" ADVANCE Intention Functions """
func start_advance() -> void:
	# Based on the situation, chooses where the unit wants to walk to and look at.
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
	
	# only update if position is different enough than our own. No back and forth stuff.
	var new_desired_movement_location: Vector2 = desired_unit_target.position + ally_offset_vector
	desired_movement_location = new_desired_movement_location

""" Helpers """
func too_close_to_ally() -> bool:
	var closest_friendly_position: Vector2 = GameMother.get_closest_friendly_position(unit.allegiance, unit.combat_id, position)
	if closest_friendly_position != Vector2.ZERO:
		var closest_friendly_distance = position.distance_to(closest_friendly_position)
		if closest_friendly_distance < desired_distance_from_allies / 2.0:  # only half here so they can settle.
			return true
	
	return false

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
	if current_time > last_action_timestamp + Coeff.time_between_actions:
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

""" Supers """
func end_combo_ai() -> void:
	# pure virtual
	move_loaded = false

func get_direction_input() -> Vector2:
	# Returns the vector that the unitBody wants to move in
	var current_agent_position: Vector2 = position
	if current_agent_position.distance_to(desired_movement_location) < standoff_distance:
		return Vector2.ZERO
	# else
	return current_agent_position.direction_to(nav.get_next_path_position())	

func get_target_position() -> Vector2:
	# Returns the vector that the unitBody wants to look at
	if desired_unit_target and my_intention == Intention.ATTACK:  # if you're attacking, look em in the eye
		return desired_unit_target.position
	else:  # otherwise, look where you're going
		return nav.get_next_path_position()
	
func get_attack_input() -> bool:
	return false

func get_boost_input(_direction: Vector2) -> bool:
	return false

func _physics_process(delta):
	update_intention()
	execute_intention()
	set_nav_movement_target()
	
	super(delta)
	
