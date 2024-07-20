extends CharacterBody2D

# References
@export var character_anim : AnimatedSprite2D
@export var weapon_pivot : Node
@export var weapon_anim : AnimatedSprite2D
@export var boost_anim : AnimatedSprite2D

# Speed variable
var speed : int = 500
var friction : float = 0.1
var acceleration : float = 0.4

# Boost variables
var boost_vector : Vector2
var boost_duration : float = 0.0
var boost_cooldown : float = 0.0

var boost_speed_mod : int = 4
var boost_turning_mod : float = 1.0
var boost_full_duration : float = 0.75
var boost_full_cooldown : float = 2.0

# Input Functions
func get_direction_input() -> Vector2:
	var input = Vector2()
	if Input.is_action_pressed('right'):
		input.x += 1
	if Input.is_action_pressed('left'):
		input.x -= 1
	if Input.is_action_pressed('down'):
		input.y += 1
	if Input.is_action_pressed('up'):
		input.y -= 1
	return input.normalized()
func get_boost_input(direction : Vector2) -> bool:
	if boost_duration > 0.0:
		return true
	if boost_cooldown <= 0.0 and boost_duration <= 0.0 and direction.length() > 0 and Input.is_action_pressed('boost'):
		# Save current direction for our boost
		boost_vector = direction
		boost_duration = boost_full_duration
		boost_cooldown = boost_full_cooldown + boost_full_duration  # presets cooldown
		return true
	return false
func get_attack_input() -> bool:
	if Input.is_action_pressed('attack0') or Input.is_action_pressed('attack1') or Input.is_action_pressed('attack2'):
		return true
	return false
func get_mouse() -> Vector2:
	# Returns the vector between the player location and the mouse location
	return get_global_mouse_position()

# Manage Animation
func set_animation(direction : Vector2, mouse_pos : Vector2, isAttacking : bool, isBoosting : bool) -> void:
	# Control CharacterAnim
	if direction.x > 0:
		character_anim.play("right")
	elif direction.x < 0:
		character_anim.play("left")
	elif direction.y != 0:
		character_anim.play("vertical")
	else:
		character_anim.play("still")
	
	# Control BoostAnim
	if isBoosting:
		boost_anim.play("boost")
		boost_anim.show()
	else:
		boost_anim.hide()
	
	# Control WeaponAnim
	if isAttacking:
		weapon_anim.stop()
		weapon_anim.rotation_degrees += 30
	else:
		weapon_anim.rotation_degrees = -45
		weapon_pivot.look_at(mouse_pos)
		weapon_anim.play("idle")
		
# Running
func _physics_process(delta : float) -> void:
	var direction : Vector2 = get_direction_input()
	var mouse_pos : Vector2 = get_mouse()
	var is_attacking : bool = get_attack_input()
	var is_boosting : bool = get_boost_input(direction)
	
	# attack direction = mouse_pos - player pos (<-- need function for global player pos)
	
	# Set anim
	set_animation(direction, mouse_pos, is_attacking, is_boosting)
	
	# If we are boosting, then we move mostly according to boost_vector
	boost_duration -= delta
	boost_cooldown -= delta
	if boost_duration > 0.0:
		#direction = (boost_vector * boost_speed_mod) + (direction * boost_turning_mod)
		direction = (direction * boost_speed_mod)

	# Control movement
	if direction.length() > 0:
		velocity = velocity.lerp(direction * speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	
	move_and_slide()
