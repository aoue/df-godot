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
var can_attack : bool = true
var can_attack_cooldown : float = 0.0

# Loadouts and moves
# (will have a link to a move, which has both:
# - a link to its projectile type 
# - a function that specifies the usage and spawning of projectiles)
@export var proj_scene : PackedScene

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
func use_move1(unit_pos : Vector2, mouse_pos : Vector2):
	# hard-coded for now; will eventually use the move in the slot
	if can_attack == false:
		return
	can_attack = false
	can_attack_cooldown = 1.0
	
	# create instance of projectile
	var proj : Object = proj_scene.instantiate()
	
	# find its spawn location (between player and mouse), offset
	var mouse_direction : Vector2 = (mouse_pos - unit_pos).normalized()
	var proj_spawn_loc : Vector2 = unit_pos + (mouse_direction * 175 * 4)
	
	# fill in its values 
	# (these are all relative to values set in coeff.gd, making large balance changes simple to do)
	var dmg_temp: float = 0.1
	var speed_temp: float = 2.5
	var knockback_temp: float = 1
	var stun_temp: float = 0.5
	
	proj.setup(proj_spawn_loc, mouse_direction, speed_temp, dmg_temp, knockback_temp, stun_temp)
	
	# instantiate it into the scene
	add_child(proj)

func _process(delta):
	# manage attack cooldown
	can_attack_cooldown -= delta
	if can_attack_cooldown < 0.0:
		can_attack = true
