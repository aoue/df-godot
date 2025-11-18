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
@export var desired_distance_to_target: float
@export var desired_attackers_on_target: int

var action_timer: float = 0.0  # The time remaining on the current action. Will reselect an action when it expires.

# dummy testing variables
var movement_target_position: Vector2 = Vector2(1000.0, 2500.0)

func _ready():
	super()
	actor_setup.call_deferred()

""" Main Brain """
func ponder() -> void:
	decide_on_target()  # pick target
	decide_on_action()  # pick what to do about it
	pick_destination()  # set values that will lead to this execution

""" Target Selection """
func decide_on_target() -> void:
	# Gets access to the list of allied units and decides who to target based on own AI.
	# Some factors under consideration are:
	# 1. [distance to target] compared to [desired_distance_to_target]
	# 2. [friendlies already attacking target] compared to [desired_attackers_on_target]
	# 3. []
	pass

""" Action Selection """
func decide_on_action() -> void:
	pass

""" Action Calculation """
func pick_destination() -> void:
	if nav.is_navigation_finished():
		set_movement_target(Vector2.ZERO)
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
	return false
func get_target_position() -> Vector2:
	# Returns the position that the unitBody is looking at
	# calculate the direction between self and 
	return nav.get_next_path_position()

""" Movement """
func actor_setup():
	await get_tree().physics_frame
	set_movement_target(movement_target_position)
func set_movement_target(movement_target: Vector2):
	nav.target_position = movement_target
	
#func _physics_process(delta):
	## basically, all the parent class functions are defined here, so physics_process will work as normal.
	## This is because it is only concerned with execution.
	#
	## think carefully about how this will integrate
	#super(delta)
