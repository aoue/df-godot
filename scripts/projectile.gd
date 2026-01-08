extends Area2D

@export var projectile_sprite : Sprite2D
@export var projectile_collider : CollisionShape2D
@export var damage_label : PackedScene

# Stats variables (will be set by move)
var direction: Vector2 = Vector2.ZERO
var attack_priority: int = 0
var speed: int = 0
var damage: int = 0
var knockback: Vector2 = Vector2.ZERO
var stun: float = 0
var lifetime: float = 0
var passthrough: bool = false
var despawn_on_obstacle_hit: bool = true
var damage_colour: Color

# State Variables
var user: Unit
var hit_something : bool = false
var hit_set : Array

# Collisions
func setup(arg_position: Vector2, arg_direction: Vector2, arg_knockback_direction : Vector2, arg_speed: float, arg_damage: float, arg_knockback: float, arg_stun: float, arg_lifetime: float, arg_passthrough: bool, arg_despawn_on_obstacle_hit: bool, arg_priority: int, arg_allegiance: int, arg_user: Unit) -> void:
	# Record movement information
	position = arg_position
	direction = arg_direction
	look_at(arg_position + arg_direction)
	
	# set collision information based on allegiance
	# 2 is enemy
	if arg_allegiance == 2:
		set_collision_mask_value(17, true)
	else:
		set_collision_mask_value(9, true)
	
	attack_priority = arg_priority
	
	# Record stats information
	speed = arg_speed * Coeff.speed
	damage = arg_damage * Coeff.damage
	knockback = arg_knockback_direction * arg_knockback * Coeff.knockback
	stun = arg_stun * Coeff.hit_stun_duration
	lifetime = arg_lifetime
	passthrough = arg_passthrough
	despawn_on_obstacle_hit = arg_despawn_on_obstacle_hit
	user = arg_user
	hit_set = Array()
	
	# allegiance is used twofold:
	#	1. to set the projectile's colour
	#	2. to set its collision settings (i.e. don't collides with friendlies)
	damage_colour = Coeff.attack_colour_dict[arg_allegiance]
	projectile_sprite.self_modulate = damage_colour

func flip_direction() -> void:
	direction = -direction

func _on_body_entered(_body) -> void:
	# This should trigger when hitting a border or obstacle, because those have bodies. (units have areas)
	# So on collision, betray and destroy yourself.
	if despawn_on_obstacle_hit:
		lifetime = 0.0

func is_hit_invalid(reporter) -> bool:
	# no double hit
	if reporter.get_unit_id() in hit_set:
		return true
	# not if dead
	if reporter.bodyChief.defeated:
		return true
	# miss if target is in boost shield
	if reporter.bodyChief.boost_shield > 0.0:
		return true
	# miss if:
	#	- the enemy is currently using an on-ring move move
	#	- we are currently using an on-ring move
	#	- we have lower attack priority
	if reporter.bodyChief.unit.active_move and reporter.bodyChief.unit.active_move.spawn_type == 1:
		if user.active_move and user.active_move.spawn_type == 1:
			#if reporter.bodyChief.unit.attack_priority > attack_priority:
			if reporter.bodyChief.unit.attack_priority < attack_priority:
				return true
	return false


func _on_area_entered(_area) -> void:
	# When the projectile enters another body, it tells all the other bodies that it hit them. 
	# Then, having no more reason to exist, it destroys itself.
	
	# check if the attack has been canceled (e.g., the unit was hit-stunned and wants to cancel its stuff.)
	if user.cancel_attack:
		queue_free()
		return
	
	hit_something = true
	
	# Let the target know they've been hit (we trust them to handle this on their end.)
	var overlapping_areas = get_overlapping_areas()
	for reporter in overlapping_areas:
		if is_hit_invalid(reporter):
			continue
		
		#print("struck one person with user id = " + str(reporter.get_unit_id()))
		hit_set.append(reporter.get_unit_id())
		
		reporter.you_have_been_hit(damage, knockback, stun)
		GameMother.log_hit(damage, user.combat_id, reporter.get_unit_id())
		
		# create/show damage number
		var floating_damage_text = damage_label.instantiate()
		var display_bias: Vector2 = (Vector2.ZERO - direction).normalized()
		floating_damage_text.display("-" + str(damage), damage_colour, display_bias)
		reporter.add_child(floating_damage_text)
		
		
		# report hit and hit recoil if applicable
		user.report_hit(reporter.global_position)
		
	
	# Hide bullet and collider (unless passthrough)
	if not passthrough:
		lifetime = min(lifetime, 0.5)
		#projectile_collider.hide()
		#projectile_sprite.hide()
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
	
	
func _process(delta: float) -> void:
	# Check to despawn (lifetime)
	lifetime -= delta
	if (user and user.cancel_attack) or lifetime <= 0.0:
		queue_free()
	
	# Control movement
	if hit_something:
		position = position + (speed * Coeff.damage_text_slowdown * direction * delta)
		#if not passthrough:
			#queue_free()
		
	if not hit_something or passthrough:
		position = position + (speed * direction * delta)
	
