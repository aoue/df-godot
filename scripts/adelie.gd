extends UnitBody

"""
Its own special functions will have to cover its AI.

How the AI works:
	1. given ai preferences, select a target
	2. given that target, select an action
	3. given that action and target, calculate and set it up
	4. execute for the given duration

"""
@export_group("AI")
@export var nav: NavigationAgent2D
@export var delay_between_actions: float
@export var desired_distance_to_target: float
@export var desired_attackers_on_target: int

var action_timer: float = 1.0  # The time remaining on the current action. Will reselect an action when it expires.
var standoff_distance: float = 0.0

# dummy testing variables
var target_unit: UnitBody
var movement_target_position: Vector2 = Vector2(1000.0, 2500.0)
var attack_ready: bool = false  # will be true when the unit thinks it is in a position ready to attack

#func _ready():
	#super()
	##actor_setup.call_deferred()

""" Main Brain """
func ponder() -> void:
	decide_on_target()  # pick target
	decide_on_action()  # pick what to do about it
	pick_destination()  # set values that will lead to this execution
	
	# specific to the move itself
	action_timer = delay_between_actions * Coeff.ai_action_timer # Coeff.ai_action_timer  # i.e. move's duration
	standoff_distance = Coeff.standoff

""" Target Selection """
func decide_on_target() -> void:
	# Gets access to the list of allied units and decides who to target based on own AI.
	# Some factors under consideration are:
	# 1. [distance to target] compared to [desired_distance_to_target]
	# 2. [friendlies already attacking target] compared to [desired_attackers_on_target] 
	#	 (this information should be reported and updated to GameMother as it changes)
	
	# for now just choose to target the first unit in Heroes. Save a vector2D.
	var check_target: UnitBody
	for hero in GameMother.get_heroes():
		check_target = hero
		break
	target_unit = check_target

""" Action Selection """
func decide_on_action() -> void:
	# if target is close enough, then decide to attack (mark 'can_attack' as true)
	if not unit.can_attack:
		return
	
	var packed_move_in_consideration = unit.loadout.peek_next_move()
	var move_in_consideration = packed_move_in_consideration.instantiate()
	
	var abs_distance_to_target = abs(target_unit.position.distance_to(global_position))
	if abs_distance_to_target > move_in_consideration.get_min_range() and abs_distance_to_target < move_in_consideration.get_max_range():
		# in that case, permission to fire is granted.
		attack_ready = true
	
	move_in_consideration.queue_free()
	
	# and keep moving
	movement_target_position = target_unit.position

""" Action Calculation """
func pick_destination() -> void:
	if nav.is_navigation_finished():
		
		# note: maybe standoff should actually be relative to move, instead, eh?
		var adjusted_position: Vector2 = movement_target_position + (global_position.direction_to(movement_target_position) * Coeff.standoff)
		
		set_movement_target(adjusted_position)
	# otherwise, obviously pick something related to target and action

""" Physics Process Helpers """
func get_direction_input() -> Vector2:
	# update if nav is finished or action timer elapsed
	if nav.is_navigation_finished() or action_timer < 0.0:
		# probably do not immediately call destination, rather, start the whole selection idea.
		ponder()
	var current_agent_position: Vector2 = global_position
	return current_agent_position.direction_to(nav.get_next_path_position())
	
func get_boost_input(direction: Vector2) -> bool:
	return false
func get_attack_input() -> bool:
	# returns true if the unit is displaying intention to attack.
	# for now, let's just say yes.
	if attack_ready and unit.can_attack:
		attack_ready = false
		return true
	return false
func get_target_position() -> Vector2:
	# Returns the position that the unitBody is looking at
	# calculate the direction between self and 
	return nav.get_next_path_position()

""" Movement """
#func actor_setup():
	#await get_tree().physics_frame
	#set_movement_target(movement_target_position)
func set_movement_target(movement_target: Vector2):
	nav.target_position = movement_target
	
func _physics_process(delta):
	## basically, all the parent class functions are defined here, so physics_process will work as normal.
	## This is because it is only concerned with execution.
	#
	## think carefully about how this will integrate
	action_timer -= delta
	super(delta)
	
