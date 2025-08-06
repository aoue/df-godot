extends Area2D

@export var projectile_sprite : Sprite2D
@export var projectile_collider : CollisionShape2D
@export var damage_label : PackedScene

# Stats variables (will be set by move)
var direction: Vector2 = Vector2.ZERO
var speed: int = 0
var damage: int = 0
var knockback: Vector2 = Vector2.ZERO
var stun: float = 0
var lifetime: float = 0
var passthrough: bool = false
var damage_colour: Color

# State Variables
var hit_something : bool = false
var expire_delay : float = 1.0

# Collisions
func setup(arg_position: Vector2, arg_direction: Vector2, arg_speed: float, arg_damage: float, arg_knockback: float, arg_stun: float, arg_lifetime: float, arg_passthrough: bool, allegiance: int) -> void:
	# Record movement information
	position = arg_position
	direction = arg_direction
	look_at(arg_position + arg_direction)
	
	# Record stats information
	speed = arg_speed * Coeff.speed
	damage = arg_damage * Coeff.damage
	knockback = arg_direction * arg_knockback * Coeff.knockback
	stun = arg_stun * Coeff.hit_stun_duration
	lifetime = arg_lifetime
	passthrough = arg_passthrough
	
	# allegiance is used twofold:
	#	1. to set the projectile's colour
	#	2. to set its collision settings (i.e. don't collides with friendlies)
	damage_colour = Coeff.attack_colour_dict[allegiance]
	projectile_sprite.self_modulate = damage_colour
	# set collision parameters: 
	
func _on_body_entered(_body) -> void:
	# When the projectile enters another body, it tells all the other bodies that it hit them. 
	# Then, having no more reason to exist, it destroys itself.
	
	# Let the target know they've been hit (we trust them to handle this on their end.)
	var overlapping_bodies = get_overlapping_bodies() 
	for hit_body in overlapping_bodies:
		hit_body.being_hit(damage, knockback, stun)
	
	# Hide bullet and collider (unless passthrough)
	if not passthrough:
		projectile_collider.hide()
		projectile_sprite.hide()
		monitoring = false
		monitorable = false
	
	# Show damage number
	hit_something = true
	
	var floating_damage_text = damage_label.instantiate()
	#floating_damage_text.position = global_position
	floating_damage_text.position = position
	floating_damage_text.rotation = -rotation
	floating_damage_text.text = "-" + str(damage)
	floating_damage_text.self_modulate = damage_colour
	floating_damage_text.lifetime = 0.5
	add_sibling(floating_damage_text)
	#add_child(floating_damage_text)
	
func _process(delta: float) -> void:
	# Check to despawn (lifetime)
	lifetime -= delta
	if not hit_something and lifetime < 0.0:
		queue_free()
	
	# Control movement
	if hit_something:
		position = position + (speed * Coeff.damage_text_slowdown * direction * delta)
		if not passthrough:
			queue_free()
		
	if not hit_something or passthrough:
		position = position + (speed * direction * delta)
	



	
	
	
	
	
