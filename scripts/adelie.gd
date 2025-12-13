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
@export var delay_between_actions: float  # Changes how quick to respond the enemy is, very influential variable.
@export var desired_attackers_on_target: int
@export var desire_to_distance_from_allies: float

# AI_Move variables that determine how the unit acts while it tries to use the loaded action.
var hold_timer: float = 0.0  # The time remaining on the current action. Will reselect an action when it expires.
var cooldown_timer: float = 0.0  # The time remaining on the current action. Will reselect an action when it expires.
var standoff_distance: float = 0.0
var min_range: float = 0.0
var max_range: float = 0.0

# dummy testing variables
var target_unit: UnitBody
var movement_target_position: Vector2  # where the unit wants to move to
var attack_ready: bool = false  # will be true when the unit thinks it is in a position ready to attack
var action_timer: float = 0.0  # will be true when the unit thinks it is in a position ready to attack
var attack_cooldown_timer: float = 1.0
var in_stun: bool = false

#func _ready():
	#super()
	##ponder.call_deferred()

""" Main Brain """
func ponder() -> void:
	# AI units follow a pseudo loadout system just like the player does.
	# 1. Read in the attributes of the loadout's move.
	# 2. Based on that move's attributes, decide how to move.
	# 3. Finally, if you're in an appropriate position to use the move, do so.
	read_in_move_ai_parameters()  # read in ai attributes based on the loaded move
	decide_on_target()  # pick positon to move too based on read-in ai target
	pick_destination()  # move closer to your desires
	decide_to_attack()  # pick if you are in a position you can attack in

func read_in_move_ai_parameters() -> void:
	# Given the current loadout's current move, set unit's ai parameters.
	var packed_loaded_move = unit.loadout.peek_next_move()
	var loaded_move = packed_loaded_move.instantiate()
	
	hold_timer = loaded_move.get_move_timer()
	cooldown_timer = loaded_move.get_cooldown_timer()
	standoff_distance = loaded_move.get_standoff_distance()
	min_range = loaded_move.get_min_range()
	max_range = loaded_move.get_max_range()
	
	loaded_move.queue_free()

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
func decide_to_attack() -> void:
	# if target is close enough, then decide to attack (mark 'can_attack' as true)
	if not unit.can_attack or attack_cooldown_timer > 0.0:
		return
	
	# also, do not attack if we are not looking within like 30 degrees of the target
	var vector_from_unit_to_target = global_position.direction_to(target_unit.position)
	var own_direction_vector = get_ring_indicator_vector()
	if not vector_from_unit_to_target.dot(own_direction_vector) > 0:  # you must be facing the target as well
		return
	
	var abs_distance_to_target = abs(target_unit.position.distance_to(global_position))
	if abs_distance_to_target > min_range and abs_distance_to_target < max_range:
		# signal that navigation should be updated with the target's precise position
		pick_dest_helper()
		# and permission to fire is granted.
		attack_ready = true
		action_timer = hold_timer  # move duration time
		attack_cooldown_timer = cooldown_timer 

""" Action Calculation """
func pick_dest_helper() -> void:
	movement_target_position = target_unit.position
	
	# adjust position for swarming
	# impact is proportional to closeness; the closer they are, the more we care.
	var closest_villain_mag: float = 0.0
	var direction_away: Vector2 = Vector2.ZERO
	var direction_away_rotated: Vector2 = Vector2.ZERO
	var closest_villain_position: Vector2 = GameMother.get_closest_villain_position(unit.combat_id, position)
	if closest_villain_position != Vector2.ZERO:
		closest_villain_mag = (global_position - closest_villain_position).length() * desire_to_distance_from_allies * Coeff.distance_from_allies_mod
		direction_away = global_position.direction_to(closest_villain_position)
		# rotate by 90
		direction_away_rotated = direction_away.rotated(PI/2)
	
	# calculate position with respect to target's position, move standoff, and closeness to allies
	var adjusted_position: Vector2 = movement_target_position + (global_position.direction_to(movement_target_position) * standoff_distance) + (direction_away_rotated * closest_villain_mag)
	action_timer = delay_between_actions * Coeff.ai_action_timer
	set_movement_target(adjusted_position)
	
func pick_destination() -> void:
	if nav.is_navigation_finished() or action_timer < 0.0:
		pick_dest_helper()

""" Helpers """
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
	# Returns the position that the unitBody wants to look at.
	# if capable of attacking a target, then look at it.
	# if incapable, then look in the direction you're moving.
	var abs_distance_to_target = abs(target_unit.position.distance_to(global_position))
	if abs_distance_to_target > min_range and abs_distance_to_target < max_range:
		return target_unit.position
	else:
		return nav.get_next_path_position()

func being_hit_ai() -> void:
	in_stun = true

""" Movement """
func set_movement_target(movement_target: Vector2):
	nav.target_position = movement_target
	#nav.target_desired_distance = standoff_distance
	
func _physics_process(delta):
	## basically, all the parent class functions are defined here, so physics_process will work as normal.
	## This is because it is only concerned with execution.
	#return
	if hit_stun_duration <= 0.0:
		attack_cooldown_timer -= delta
		action_timer -= delta
		if in_stun:
			in_stun = false
			attack_cooldown_timer = delay_between_actions

	super(delta)
	
