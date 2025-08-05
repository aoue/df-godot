extends CharacterBody2D
class_name UnitBody

# References
@export var unit: Node
@export var character_anim: AnimatedSprite2D
@export var hp_bar: TextureProgressBar
@export var ring_indicator: Node2D

# Basic movement variables
@export var HP_max_coeff: float
@export var PW_max_coeff: float
@export var speed_coeff: float
@export var acceleration_coeff: float
var speed: float
var acceleration: float
var knockback: Vector2

# Boost variables
@export var boost_speed_mod: float = 2.5
@export var boost_full_duration: float = 0.2
@export var boost_full_cooldown: float = 1.5
var boost_acceleration: float
var boost_vector: Vector2
var boost_duration: float = 0.0
var boost_cooldown: float = 0.0

# Being hit variables
var hit_stun_duration: float = 0.0  # remaining stun duration on unit, depending on the move that hit them.
var hit_stun_shield: float = 0.0  # time after being stunned before you can be stunned again (to avoid stunlocking.)

# Moveset
#@export var move1: move

""" Setup """
func _ready() -> void:
	unit.refresh(HP_max_coeff, PW_max_coeff)
	hp_bar.max_value = unit.HP_max
	hp_bar.value = unit.HP_max
	speed = speed_coeff * Coeff.speed
	acceleration = acceleration_coeff * Coeff.acceleration
	boost_acceleration = 2.0 * Coeff.acceleration

""" Input """
func get_direction_input() -> Vector2:
	return Vector2.ZERO
	
func get_boost_input(direction: Vector2) -> bool:
	if boost_duration > 0.0:  # already boosting
		return true
		
	if Input.is_action_pressed('boost') and boost_cooldown <= 0.0 and direction.length() > 0:  # start boosting
		# Save current direction for our boost
		boost_vector = direction
		boost_duration = boost_full_duration
		boost_cooldown = boost_full_cooldown + boost_full_duration  # wow that's pretty smart (it was my idea)
		return true
	return false
	
func get_attack_input() -> bool:
	return false

func get_target_direction() -> Vector2:
	# Returns the vector that the unitBody wants to move towards
	return Vector2.ZERO
	
func get_mouse() -> Vector2:
	return Vector2.ZERO

""" Reacting """
func being_hit(proj_damage: int, proj_knockback: Vector2, stun: float) -> void:
	
	# Do damage and cause knockback
	unit.take_damage(proj_damage)
	knockback = proj_knockback
	
	# Affect sprite
	if stun > 0 and hit_stun_shield == 0:
		hit_stun_duration = stun
		hit_stun_shield = stun + Coeff.stun_shield_duration
	
	if unit.is_defeated():
		start_being_defeated()

func start_being_defeated() -> void:
	# does some stuff when the unit is defeated
	# probably has a dying animation and timer, then also leaves a body behind
	#queue_free()
	pass

func update_hp_bar(new_value: int, delta: float) -> void:
	# Graphical only; we don't check for death or anything like that here.
	if hp_bar.value > new_value:
		hp_bar.value -= Coeff.hp_bar_update_speed * delta
	elif hp_bar.value < new_value:
		hp_bar.value += Coeff.hp_bar_update_speed * delta

""" Running """
func set_anim(direction: Vector2) -> void:
	# Control CharacterAnim
	
	# Stunned?
	if hit_stun_duration > 0.0:
		character_anim.play("9_being_hit")
		return
	# if dead and death delay passed: play("9b_defeated")
	
	# Attacking?
	if unit.set_attack_anim:
		# Play the corresponding animation
		unit.set_attack_anim = false
		if unit.active_move.animation_type == 0:
			character_anim.play("6_melee")
		elif unit.active_move.animation_type == 1:
			character_anim.play("7_ranged")
		else:
			character_anim.play("8_special")
		return
	elif unit.attacking_duration_left > 0.0:
		# Don't play any other animation while ongoing
		return
	
	# React to movement input
	if direction.x > 0:
		character_anim.play("1_side_mov")
		character_anim.flip_h = false
	elif direction.x < 0:
		character_anim.play("1_side_mov")
		character_anim.flip_h = true
	elif direction.y > 0:
		character_anim.play("3_front_mov")
		character_anim.flip_h = false		
	elif direction.y < 0:
		character_anim.play("5_back_mov")
		character_anim.flip_h = false
	else:
		# Set the rest animation corresponding to the vector between yourself and the target location.
		# if x component is greater, then look to the side
		# if y component is greater, then look up/down
		var look_dir: Vector2 = (get_target_direction() - global_position).normalized()
		var x_power: float = look_dir.x
		var y_power: float = look_dir.y
		if abs(x_power) >= abs(y_power):
			character_anim.play("0_side_rest")
			if x_power > 0.0:
				character_anim.flip_h = false
			else:
				character_anim.flip_h = true
				
		else:
			if y_power >= 0:
				character_anim.play("2_front_rest")
				character_anim.flip_h = false
			else:
				character_anim.play("4_back_rest")
				character_anim.flip_h = false

func set_anim_plus(mouse_pos: Vector2, isAttacking: bool, isBoosting: bool) -> void:
	# To set animations supporting the unit, but not the character animations themselves.
	pass

func go_anim(delta: float, direction_input: Vector2, mouse_input: Vector2, attack_input: bool, boost_input: bool) -> void:
	set_anim(direction_input)
	set_anim_plus(mouse_input, attack_input, boost_input)
	update_hp_bar(unit.HP_cur, delta)
	
func go_move(direction_input: Vector2, speed_input: int, acceleration_input: float) -> void:
	if direction_input.length() > 0:
		velocity = velocity.lerp(direction_input * speed_input, acceleration_input)
	else:
		velocity = velocity.lerp(Vector2.ZERO, acceleration_input)	
	velocity += knockback
	move_and_slide()

func go_attack(is_attacking: bool, unit_pos: Vector2, ring_indicator_vector: Vector2) -> void:
	if is_attacking or unit.attacking_duration_left > 0.0:
		unit.use_active_move(unit_pos, ring_indicator_vector)

func adjust_ring_indicator(where: Vector2, delta: float):
	# Changes the position of the ring indicator.
	# For player, relative to mouse movement, speed can be affected by attacking state and move slowdown.
	# For enemy, moved with ai.
	var wanted_rotation_angle: float = position.angle_to_point(where)
	var current_rotation: float = ring_indicator.rotation
	var rotation_weight: float = delta * Coeff.rotation_speed
	if unit.attacking_duration_left > 0.0:
		rotation_weight *= unit.active_move.user_rotation_mod
	ring_indicator.rotation = rotate_toward(current_rotation, wanted_rotation_angle, rotation_weight)

func get_ring_indicator_vector() -> Vector2:
	var x_component = cos(ring_indicator.rotation)
	var y_component = sin(ring_indicator.rotation)
	return Vector2(x_component, y_component)

func pass_duration(delta : float) -> void:
	boost_duration = max(0, boost_duration - delta)
	boost_cooldown = max(0, boost_cooldown - delta)
	hit_stun_duration = max(0, hit_stun_duration - delta)
	hit_stun_shield = max(0, hit_stun_shield - delta)
	
	knockback = lerp(knockback, Vector2.ZERO, 0.1)

func _physics_process(delta: float) -> void:
	var direction: Vector2 = get_direction_input()
	var is_attacking: bool = get_attack_input()
	var mouse_pos: Vector2 = get_mouse()
	var is_boosting: bool = get_boost_input(direction)
	
	var acceleration_value = acceleration
	var speed_value = speed
	if is_boosting:
		acceleration_value = boost_acceleration
		speed_value *= boost_speed_mod
	if unit.attacking_duration_left > 0.0:
		speed_value *= unit.active_move.user_speed_mod
		
	adjust_ring_indicator(mouse_pos, delta)
	go_move(direction, speed_value, acceleration_value)
	go_attack(is_attacking, position, get_ring_indicator_vector())
	go_anim(delta, direction, mouse_pos, is_attacking, is_boosting)
	
	pass_duration(delta)
