extends CharacterBody2D

# Speed variable
var speed : int = 500
var friction : float = 0.1
var acceleration : float = 0.4

# Boost variables
var boost_vector : Vector2
var boost_duration : float = 0.0
var boost_cooldown : float = 0.0

var boost_speed_mod : int = 2
var boost_turning_mod : float = 1.0
var boost_full_duration : float = 0.75
var boost_full_cooldown : float = 2.0

# Input Functions
func get_direction_input() -> Vector2:
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

func set_animation(direction : Vector2, isAttacking : bool, isBoosting : bool) -> void:
	# Control CharacterAnim
	if direction.x > 0:
		$CharacterAnim.play("right")
	elif direction.x < 0:
		$CharacterAnim.play("left")
	elif direction.y != 0:
		$CharacterAnim.play("vertical")
	else:
		$CharacterAnim.play("still")
	
	# Control BoostAnim
	if isBoosting:
		$CharacterAnim/BoostAnim.play("boost")
		$CharacterAnim/BoostAnim.show()
	else:
		$CharacterAnim/BoostAnim.hide()
	
	# Control WeaponAnim
	if isAttacking:
		pass

func _physics_process(delta : float) -> void:
	var direction : Vector2 = get_direction_input()
	var start_boost : bool = get_boost_input(direction)
	var start_attack : bool = get_attack_input()
	
	# If we are boosting, then we move mostly according to boost_vector
	boost_duration -= delta
	boost_cooldown -= delta
	if boost_duration > 0.0:
		direction = (boost_vector * boost_speed_mod) + (direction * boost_turning_mod)

	# Control movement
	if direction.length() > 0:
		velocity = velocity.lerp(direction * speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		
	# Set anim
	set_animation(direction, start_attack, start_boost)
	
	move_and_slide()
