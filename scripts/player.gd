extends CharacterBody2D

# References
@export var character_anim : AnimatedSprite2D
@export var weapon_pivot : Node
@export var weapon_anim : AnimatedSprite2D
@export var boost_anim : AnimatedSprite2D
@export var unit : Node
@export var hp_bar : TextureProgressBar

# Speed variables
var speed : int = 500
var friction : float = 0.1
var acceleration : float = 0.4

# Boost variables
var boost_vector : Vector2
var boost_duration : float = 0.0
var boost_cooldown : float = 0.0
var boost_speed_mod : float = 3.0
var boost_acceleration_mod : float = 2.0
var boost_turning_mod : float = 0.75
var boost_full_duration : float = 0.35
var boost_full_cooldown : float = 1.5

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
	
func get_boost_input(direction: Vector2) -> bool:
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


# Manage State
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
	weapon_pivot.look_at(mouse_pos)
	if isAttacking:
		weapon_anim.stop()
		weapon_anim.rotation_degrees += 30
	else:
		weapon_anim.rotation_degrees = -45
		weapon_anim.play("idle")

func being_attacked(damage : int) -> void:
	# When you are attacked, you do a few things:
	# - register the hit
	# - update your state
	# - die, if applicable
	unit.take_hit(damage)
	#update_hp_bar(unit.HP_cur)
	
	if unit.is_defeated():
		start_being_defeated()

func start_being_defeated() -> void:
	# does some stuff when the unit is defeated
	# probably has a dying animation and timer, then also leaves a body behind
	pass

func update_hp_bar(new_value : int, delta : float) -> void:
	# Graphical only; we don't check for death or anything like that here.
	# Called when the unit takes damage.
	if hp_bar.value < new_value:
		hp_bar.value += new_value * delta
	elif hp_bar.value > new_value:
		hp_bar.value -= new_value * delta

# Running
func _physics_process(delta: float) -> void:
	# calls entity's process function
	var direction: Vector2 = get_direction_input()
	var mouse_pos: Vector2 = get_mouse()
	var is_attacking: bool = get_attack_input()
	var is_boosting: bool = get_boost_input(direction)
	
	boost_duration -= delta
	boost_cooldown -= delta
	var modded_accel: float = acceleration
	if boost_duration > 0.0:
		direction = (boost_vector * boost_speed_mod) + (direction * boost_turning_mod)
		modded_accel = acceleration * boost_acceleration_mod
	
	go_move(delta, direction, speed, modded_accel, friction)
	go_attack(delta, is_attacking, mouse_pos)
	go_anim(delta, direction, mouse_pos, is_attacking, is_boosting)

func go_move(delta: float, direction_input: Vector2, speed_input: int, accel_input: float, friction_input: float) -> void:
	if direction_input.length() > 0:
		velocity = velocity.lerp(direction_input * speed_input, accel_input)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction_input)	
	move_and_slide()

func go_attack(delta : float, attack_input: bool, mouse_input: Vector2) -> void:
	if attack_input:
		unit.use_move1(position, mouse_input)

func go_anim(delta : float, direction_input : Vector2, mouse_input: Vector2, attack_input: bool, boost_input: bool) -> void:
	#character_anim.sprite_frames
	set_animation(direction_input, mouse_input, attack_input, boost_input)
	update_hp_bar(unit.HP_cur, delta)






	
