extends Area2D

@export var projectile_sprite : Sprite2D
@export var projectile_collider : CollisionShape2D
@export var damage_label : Label

# Stats variables
var speed : int = 0
var direction : Vector2 = Vector2.ZERO
var damage : int = 0

# State Variables
var hit_something : bool = false
var expire_delay : float = 1.0

# Collisions
func setup(arg_position : Vector2, arg_direction : Vector2, arg_speed : int, arg_damage : int) -> void:
	# Record movement information
	position = arg_position
	direction = arg_direction
	look_at(arg_position + arg_direction)
	
	speed = arg_speed

	# Record stats information
	damage = arg_damage
func _on_body_entered(_body) -> void:
	# When the projectile enters another body, it tells all the other bodies that it hit them. 
	# Then, having no more reason to exist, it destroys itself.
	
	# Handle hit
	#if hit_something:
		#return
	var overlapping_bodies = get_overlapping_bodies() 
	for hit_body in overlapping_bodies:
		print(hit_body)
		hit_body.being_attacked(damage)
	
	# Hide bullet and collider
	projectile_collider.hide()
	projectile_sprite.hide()
	
	# Show damage number
	hit_something = true
	damage_label.text = "-" + str(damage)
	direction = random_on_unit_sphere()

# Helpers
func random_on_unit_sphere() -> Vector2:
	return Vector2(randfn(0, 1), randfn(0, 1)).normalized()
#func _ready() -> void:
	## temp function to setup testing in encounter scene
	##return
	#var dummy_direction = Vector2(1.0, 0.0)
	#setup(position, dummy_direction, get_global_mouse_position(), 1500, 200)

func _process(delta : float) -> void:
	# Control movement
	damage_label.rotation = -rotation  # hehe
	if hit_something:
		position = position + (speed / 100 * direction * delta)
		expire_delay -= delta
		if expire_delay <= 0.0:
			queue_free()
	else:
		position = position + (speed * direction * delta)
	



	
	
	
	
	
