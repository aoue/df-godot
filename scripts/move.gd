extends Node2D
class_name Move

# Holds information used to create the projectiles resulting from the move's use.
# Used in loadouts from unit.gd
enum Move_Spawn_Type {FIRED, ON_RING, SUMMON}
enum Move_Anim_Type {MELEE, RANGED, SPECIAL}
enum Accuracy_Labels {NONE, SLIM, MINOR, MODERATE, MAJOR, SPRAY}
enum Recoil_Moments {NA, ON_FIRE, ON_HIT}

# Usage 
@export_group("Usage Variables") 
@export var fire_table : Array[float]
@export var accuracy_deviation_label : Accuracy_Labels
@export var move_speed_add_duration : float
@export var move_speed_add : float  # negate this value to move backwards
@export var user_speed_mod : float
@export var user_rotation_mod : float
@export var move_prep_duration : float
@export var move_duration : float
@export var summon_duration : float

@export_group("Recoil Variables") 
@export var recoil_moment : Recoil_Moments
@export var recoil_knockback : float

@export_group("Animation Variables") 
@export var spawn_type : Move_Spawn_Type
@export var animation_type : Move_Anim_Type  # the name of the animation which will be fired on use.

# Projectile Setup Information (all these are relative to the values set in coeff.gd, remember.)
@export_group("Projectile Variables") 
@export var proj_spawn_offset : float
@export var proj_speed : float
@export var proj_damage : float
@export var proj_knockback : float
@export var proj_stun : float
@export var proj_lifetime : float
@export var proj_passthrough : bool
@export var proj_despawn_on_obstacle_hit : bool
@export var proj_scene : PackedScene

var accuracy_table = {
	0: 0,
	1: 0.05,
	2: 0.075,
	3: 0.2,
	4: 0.5,
	5: 0.75
}

func spawn_projectiles(proj_spawn_loc : Vector2, direction : Vector2, knockback_direction : Vector2, allegiance: int, priority: int, user: Unit):
	# return projectiles according to the move's specs.
	var proj : Object = proj_scene.instantiate()
	
	# modify 'direction' with accuracy noise
	var accuracy_deviation = accuracy_table[accuracy_deviation_label]
	var misaccuracy_vector: Vector2 = Vector2(randf_range(-accuracy_deviation/2, accuracy_deviation/2), randf_range(-accuracy_deviation/2, accuracy_deviation/2))
	#print("direction_vector   = " + str(direction))
	#print("misaccuracy_vector = " + str(misaccuracy_vector))
	#print("post vector        = " + str((direction + misaccuracy_vector).normalized()))
	#print("===")
	
	proj.setup(proj_spawn_loc, (direction + misaccuracy_vector).normalized(), knockback_direction, proj_speed, proj_damage, proj_knockback, proj_stun, proj_lifetime, proj_passthrough, proj_despawn_on_obstacle_hit, priority, allegiance, user)
	
	return proj
