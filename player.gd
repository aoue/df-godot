extends CharacterBody2D

var speed = 500
var friction = 0.1
var acceleration = 0.4

#func _ready():
	## Start animator
	#$anim.play("still")

func get_input():
	# look_at(get_global_mouse_position())
	var input = Vector2()
	if Input.is_action_pressed('right'):
		input.x += 1
	if Input.is_action_pressed('left'):
		input.x -= 1
	if Input.is_action_pressed('down'):
		input.y += 1
	if Input.is_action_pressed('up'):
		input.y -= 1
	
	return input

func set_animation(direction : Vector2) -> void:
	if direction.x > 0:
		$anim.play("right")
	elif direction.x < 0:
		$anim.play("left")
	elif direction.y != 0:
		$anim.play("vertical")
	else:
		$anim.play("still")

func _physics_process(delta : float) -> void:
	var direction = get_input()
	
	# Set anim
	set_animation(direction)

	# Set movement
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * speed, acceleration)	
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	
	move_and_slide()
