extends Node

# Holds information used to create the projectiles resulting from the move's use.
# Used in loadouts from unit.gd
enum Move_Spawn_Type {FIRED, ON_RING, SUMMON}
enum Move_Anim_Type {MELEE, RANGED, SPECIAL}

# Usage Statistics
@export var fire_table : Array[float]
@export var slow_mod : float
@export var move_duration : float
@export var spawn_type : Move_Spawn_Type
@export var animation_type : Move_Anim_Type  # the name of the animation which will be fired on use.

# Projectile Statistics (all these are relative to the values set in coeff.gd, remember.)
@export var proj_speed : float
@export var proj_damage : float
@export var proj_knockback : float
@export var proj_stun : float
@export var proj_scene : PackedScene

# Animations


func spawn_projectiles(mouse_direction : Vector2, proj_spawn_loc : Vector2):
	# return projectiles according to the move's specs.
	#
	# just a single projectile is good enough for now
	var proj : Object = proj_scene.instantiate()
	# fill in its values 
	# (these are all relative to values set in coeff.gd, making large balance changes simple to do)
	#var dmg_temp: float = 0.1
	#var speed_temp: float = 2.5
	#var knockback_temp: float = 1
	#var stun_temp: float = 0.5
	
	proj.setup(proj_spawn_loc, mouse_direction, proj_speed, proj_damage, proj_knockback, proj_stun)
	
	return proj
