extends Area2D

# Speed variables
var speed : int = 0
var direction : Vector2 = Vector2.ZERO

# Stats variables
var damage : int = 0

func setup(arg_position : Vector2, arg_direction : Vector2, look_direction : Vector2, arg_speed : int, arg_damage : int) -> void:
	# Record movement information
	position = arg_position
	direction = arg_direction
	look_at(look_direction)
	speed = arg_speed

	# Record stats information
	damage = arg_damage

func _on_body_entered(body) -> void:
	#print("something has entered the projectile's area2d. Its type is:")
	#print(typeof(body))  # 24: poolvector2array
	# https://docs.godotengine.org/en/3.2/classes/class_poolvector2array.html#class-poolvector2array
	
	# to add: makes the call that does damage to the target body here.
	# body.unit.get_hit(damage) or something like that
	
	queue_free()

# physics process: to move the bullet along its direction
func _process(delta : float) -> void:
	# Control movement
	position = position + (speed * direction * delta)

