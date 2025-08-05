extends Node

# Holds all the stat information for a unit. 
# Things like HP, PW, Loadouts, allegiance,
# All attack/damage stat-related information needs to be retrieved and modified here.
# But not movement-related things.

# Basic statistics
var HP_max : int
var HP_cur : int
var PW_max : int
var PW_cur : int

# Attack variables
var attacking_duration_left : float = 0.0
var projectile_counter : int = 0
var can_attack : bool = true
var can_attack_cooldown : float = 0.0
var set_attack_anim : bool = false

# Loadouts and moves
# (will have a link to a move, which has both:
# - a link to its projectile type 
# - a function that specifies the usage and spawning of projectiles)
@export var move1 : PackedScene
var active_move : Object

func refresh(HP_max_coeff: float, PW_max_coeff: float):
	# sets the unit's stats to their initial state
	HP_max = HP_max_coeff * Coeff.hp
	HP_cur = HP_max
	PW_max = PW_max_coeff * Coeff.hp
	PW_cur = PW_max

# Being Attacked
func take_damage(damage : int) -> void:
	HP_cur = clamp(HP_cur - damage, 0, HP_max)

func is_defeated() -> bool:
	if HP_cur == 0:
		return true
	return false

# Attacking
func use_active_move(unit_pos : Vector2, ring_indicator_vector : Vector2):
	# If we are not attacking but are eligible too, then we switch the active move and start it.
	# If we are already in the middle of using a move, then we check against fire times and call fire() if appropriate
	if attacking_duration_left > 0.0:
		# check against active move's fire times
		if projectile_counter < len(active_move.fire_table) and attacking_duration_left <= active_move.move_duration * active_move.fire_table[projectile_counter]:
			projectile_counter += 1
			fire(unit_pos, ring_indicator_vector)
		return
	if can_attack == false:
		return
	
	# enter 'new active move' state
	active_move = move1.instantiate()  # will map depending on which move was selected
	set_attack_anim = true
	attacking_duration_left = active_move.move_duration
	projectile_counter = 0
	can_attack = false
	can_attack_cooldown = attacking_duration_left + 1.0

func fire(unit_pos : Vector2, ring_indicator_vector : Vector2):
	# find its spawn location (between player and mouse), offset
	# Note: 650 is the ring indicator offset.
	var spawn_direction : Vector2 = ((unit_pos + 650 * ring_indicator_vector) - unit_pos).normalized()  
	var proj_spawn_loc : Vector2 = unit_pos + (spawn_direction * 650)
	
	# instantiate projectile into the scene
	var proj : Object = active_move.spawn_projectiles(proj_spawn_loc, spawn_direction)
	add_child(proj)

func _process(delta):
	# manage attack cooldown
	if attacking_duration_left > 0.0:
		attacking_duration_left = max(0, attacking_duration_left - delta)
		# check attack times in active_move and fire from there
		
		
	else:
		can_attack_cooldown = max(0, can_attack_cooldown - delta)
		if can_attack_cooldown == 0.0:
			can_attack = true

