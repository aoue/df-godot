extends Node

# Holds information used to create the projectiles resulting from the move's use.
# Used in loadouts from unit.gd
enum Move_Spawn_Type {FIRED, ON_RING, SUMMON}
enum Move_Anim_Type {MELEE, RANGED, SPECIAL}

# Usage Statistics
@export var fire_table : Array[float]
@export var accuracy_deviation : float
@export var user_speed_mod : float
@export var user_rotation_mod : float
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


func spawn_projectiles(proj_spawn_loc : Vector2, direction : Vector2):
	# return projectiles according to the move's specs.
	var proj : Object = proj_scene.instantiate()
	
	# modify 'direction' with accuracy noise
	# so we have 'direction', which is a normalized vector2
	# we generate a new vector 2 using 'spawn_accuracy', where x, y = rand(0.0, 1 - spawn_accuracy)
	# then we combine the two vector2s
	var misaccuracy_vector: Vector2 = randi_range(-1, 1) * Vector2(randf_range(0.0, accuracy_deviation), randf_range(0.0, accuracy_deviation))
	#print("calculated misaccuracy vector: " + str(misaccuracy_vector))
	
	proj.setup(proj_spawn_loc, direction + misaccuracy_vector, proj_speed, proj_damage, proj_knockback, proj_stun)
	
	return proj
