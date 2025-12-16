extends CharacterBody2D
class_name UnitBody

# References
@export_group("Moving Pieces")
@export var unit: Node
@export var character_anim: AnimatedSprite2D
@export var hp_bar: TextureProgressBar
@export var timing_bar: TextureProgressBar
@export var ring: Node2D
@export var ring_indicator: Node2D
@export var summon_indicator: Node2D

@export_group("Labels")
@export var stat_labels : Node2D
@export var stun_label : Label
@export var utility_label : Label
@export var speed_label : Label

@export_group("Stat Coeffs")
# Basic movement variables
@export var HP_max_coeff: float
@export var PW_max_coeff: float
@export var speed_coeff: float
@export var acceleration_coeff: float
var speed: float
var acceleration: float
var knockback: Vector2

# Boost variables
var boost_shield: float = 0.0
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
	
	# Colour ring
	var unit_colour: Color = Coeff.attack_colour_dict[unit.allegiance]
	ring.self_modulate = unit_colour
	ring_indicator.self_modulate = unit_colour
	summon_indicator.self_modulate = unit_colour

""" Input """
func get_direction_input_helper() -> Vector2:
	if hit_stun_duration > 0.0:
		return Vector2.ZERO
	return get_direction_input()
	
func get_direction_input() -> Vector2:
	return Vector2.ZERO
	
func get_boost_input(direction: Vector2) -> bool:
	return false

func get_attack_input_helper() -> bool:
	if hit_stun_duration > 0.0:
		return false
	return get_attack_input()
func get_attack_input() -> bool:
	return false

func get_target_position() -> Vector2:
	# Returns the vector that the unitBody is looking at
	return Vector2.ZERO

""" Reacting """
func take_recoil(recoil_amount: Vector2):
	knockback += recoil_amount

func being_hit_ai() -> void:
	pass
	
func being_hit(proj_damage: int, break_damage: int, proj_knockback: Vector2, stun: float) -> void:
	# Do damage and cause knockback
	unit.take_damage(proj_damage, break_damage)
	knockback += proj_knockback
	
	# Give the unit's ai the chance to react to this.
	being_hit_ai()
	
	# Cancel any ongoing action
	# immediately cancel the unit's attack as well, if that is ongoing.
	unit.emergency_exit()
	
	# Stun
	if stun > 0 and stun > hit_stun_duration and hit_stun_shield <= 0:
		hit_stun_duration = stun
		hit_stun_shield = stun + Coeff.stun_shield_duration
	
	# Die
	if unit.is_defeated():
		start_being_defeated()

func start_being_defeated() -> void:
	# does some stuff when the unit is defeated
	# probably has a dying animation and timer, then also leaves a body behind
	#queue_free()
	pass

func get_delay_between_actions() -> float:
	return 0.0

func update_timing_bar(delta: float) -> void:
	# first: discover value we should be comparing:
	
	var new_value : float = 0
	var new_max_value : float = 1
	
	# case -1: we are stunned:
	if hit_stun_duration > 0.0:
		new_max_value = Coeff.hit_stun_duration
		new_value = hit_stun_duration
	# case 0: we are in summon
	elif unit.attacking_duration_left > 0.0 and unit.active_move.spawn_type == 2 and not unit.summon_period_over():
		# attacking_duration_left <= active_move.move_duration
		new_max_value = unit.active_move.summon_duration
		new_value = unit.attacking_duration_left - unit.active_move.move_duration
		
		#new_max_value = unit.active_move.summon_duration
		#new_value = (unit.active_move.move_duration + unit.active_move.summon_duration) - unit.attacking_duration_left
	## case 1: we are attacking; update attack thing
	elif unit.attacking_duration_left > 0.0:
		new_max_value = unit.active_move.move_duration
		new_value = unit.attacking_duration_left
	# case 2: in cooldown
	elif unit.can_attack_cooldown > 0.0:
		# for an ai unit, show delay between actions as well
		#var action_delay: float = 0.0
		var action_delay: float = get_delay_between_actions()
		new_max_value = Coeff.move_cooldown + action_delay
		new_value = unit.can_attack_cooldown + action_delay
	# case 3: switching loadouts
	elif unit.loadout_gate_time > 0.0:
		new_max_value = Coeff.loadout_cooldown
		new_value = unit.loadout_gate_time
	
	new_value *= 100
	new_max_value *= 100
	timing_bar.max_value = new_max_value
	
	if timing_bar.value > new_value:
		timing_bar.value -= Coeff.hp_bar_update_speed * delta
	elif timing_bar.value < new_value:
		timing_bar.value = new_value
		
func update_hp_bar(new_value: int, delta: float) -> void:
	# Graphical only; we don't check for death or anything like that here.
	if hp_bar.value == new_value:
		return
	if hp_bar.value > new_value:
		hp_bar.value -= Coeff.hp_bar_update_speed * delta
	elif hp_bar.value < new_value:
		hp_bar.value += Coeff.hp_bar_update_speed * delta

func update_labels(speed_value : float) -> void:
	stun_label.text = str(unit.stun_cur) + "%"
	#utility_label.text = "UTL--" + str(timing_bar.value)
	#speed_label.text = "SPD--" + str(speed_value)

""" Running """
func set_anim(direction: Vector2) -> void:
	# Control CharacterAnim
	
	# Stunned?
	if hit_stun_duration > 0.0:
		character_anim.play("9_being_hit")
		return
	# if dead and death delay passed: play("9b_defeated")
	
	# Attacking?
	if unit.set_attack_anim and unit.active_move:
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
		if unit.scored_hit and unit.active_move.animation_type == 0:
			character_anim.play("6b_melee_finisher")
		# Don't play any other animation while ongoing
		return
	
	# check x direction for flipping
	# Set the rest animation corresponding to the vector between yourself and the target location.
	# if x component is greater, then look to the side
	# if y component is greater, then look up/down
	var look_dir: Vector2 = (get_target_position() - global_position).normalized()
	var x_power: float = look_dir.x
	var y_power: float = look_dir.y
	if x_power > 0.0:
		character_anim.flip_h = false
	else:
		character_anim.flip_h = true
	
	# set anims according to direction vector.
	if direction == Vector2.ZERO:
		if abs(x_power) >= abs(y_power):
			character_anim.play("0_side_rest")
		else:
			if y_power >= 0:
				character_anim.play("2_front_rest")
			else:
				character_anim.play("4_back_rest")
	else:
		if abs(x_power) > abs(y_power):
			character_anim.play("1_side_mov")
		elif y_power > 0:
			character_anim.play("3_front_mov")
		elif y_power < 0:
			character_anim.play("5_back_mov")

func set_anim_plus(isBoosting: bool) -> void:
	# To set animations supporting the unit, but not the character animations themselves.
	pass

func go_anim(delta: float, direction_input: Vector2, boost_input: bool) -> void:
	set_anim(direction_input)
	set_anim_plus(boost_input)
	update_hp_bar(unit.HP_cur, delta)
	update_timing_bar(delta)
	
func go_move(direction_input: Vector2, speed_input: int, acceleration_input: float) -> void:
	if direction_input.length() > 0:
		velocity = velocity.lerp(direction_input * speed_input, acceleration_input)
	else:
		velocity = velocity.lerp(Vector2.ZERO, acceleration_input)
		
	# Sets recoil
	knockback = lerp(knockback, Vector2.ZERO, 0.1)
	unit.recoil = lerp(unit.recoil, Vector2.ZERO, 0.25)
		
	# unaffected by move slowdowns
	var speed_compensation_value : float = 1
	if speed < speed_input:
		speed_compensation_value = speed / speed_input
	velocity += (knockback * speed_compensation_value)
	velocity += (unit.recoil * speed_compensation_value)
	
	move_and_slide()

func go_attack(is_attacking: bool, unit_pos: Vector2, ring_indicator_vector: Vector2) -> void:
	if is_attacking or unit.attacking_duration_left > 0.0:
		if hit_stun_duration > 0.0:
			unit.early_exit()  # intterupt the attack and also cancel it so it does not resume after the stun has passed.
			return
		
		# force loadout switch?
		unit.update_loadout_status()
		
		# track summon type clicks
		# catch 1st click
		if is_attacking and unit.active_move and unit.summon_period_over():
			unit.summon_all_green = true
		unit.use_active_move(unit_pos, ring_indicator_vector, ring_indicator)

func is_backpedaling(move_direction: Vector2, face_direction: Vector2) -> bool:
	# Slows speed if the unit is backing up. Because that's not fun.
	# condition: if movement direction is not within 180 degrees of ring indicator direction
	# (could also make it proportional, if you want)
	var angle: float = abs((face_direction).angle_to(move_direction))
	# so, you are backpedaling if the angle is greater, i.e. the angle between the pointer and the movement vector is too large
	return angle > Coeff.full_speed_angle_gate

func adjust_indicators(where: Vector2, delta: float):
	# Changes the position of the ring indicator.
	# For player, relative to mouse movement, speed can be affected by attacking state and move slowdown.
	# For enemy, moved with ai.
	var wanted_rotation_angle: float = position.angle_to_point(where)
	var current_rotation: float = ring_indicator.rotation
	var rotation_weight: float = delta * Coeff.rotation_speed
	if unit.attacking_duration_left > 0.0 and not unit.summon_waiting_for_2nd_click():
		rotation_weight *= unit.active_move.user_rotation_mod
	if hit_stun_duration > 0.0:
		rotation_weight *= Coeff.hit_stun_rotation_speed

	ring_indicator.rotation = rotate_toward(current_rotation, wanted_rotation_angle, rotation_weight)

	# Adjust summon indicator too
	var offset = 700
	var v = get_ring_indicator_vector()
	summon_indicator.position = Vector2(offset * v.x, offset * v.y)
	# or, angle between self and ring indicator * 725?
	
	# adjust stat labels too (still in progress)
	#var x_offset = 500
	#var y_offset = 500
	#stat_labels.position = Vector2(x_offset * v.x, y_offset * v.y)
	
	if unit.active_move and unit.summon_period_over():
		summon_indicator.visible = true
		ring_indicator.visible = false
	else:
		summon_indicator.visible = false
		ring_indicator.visible = true
		
func get_ring_indicator_vector() -> Vector2:
	var x_component = cos(ring_indicator.rotation)
	var y_component = sin(ring_indicator.rotation)
	return Vector2(x_component, y_component)

func pass_duration(delta : float) -> void:
	boost_shield = max(0, boost_shield - delta)
	boost_duration = max(0, boost_duration - delta)
	boost_cooldown = max(0, boost_cooldown - delta)
	hit_stun_duration = max(0, hit_stun_duration - delta)
	hit_stun_shield = max(0, hit_stun_shield - delta)

func _physics_process(delta: float) -> void:
	var direction: Vector2 = get_direction_input_helper()
	var ring_direction: Vector2 = get_ring_indicator_vector()
	var is_attacking: bool = get_attack_input_helper()
	var target_pos: Vector2 = get_target_position()
	var is_boosting: bool = get_boost_input(direction)
	
	var acceleration_value = acceleration
	var speed_value = speed
	if is_boosting:
		acceleration_value = boost_acceleration
		speed_value *= Coeff.boost_speed_mod
	#elif unit.attacking_duration_left > 0.0 and not unit.summon_waiting_for_2nd_click():
	elif unit.attacking_duration_left > 0.0:
		speed_value *= unit.active_move.user_speed_mod
	elif is_backpedaling(direction, ring_direction):
		speed_value /= 2
	
	if unit.prep_time <= 0.0 and unit.move_boost_duration_left > 0.0:
		# if the move boosts, then add its speed and prioritize its own direction
		speed_value += (unit.active_move.move_speed_add * Coeff.speed)
		direction = ring_direction
		
	adjust_indicators(target_pos, delta)
	go_move(direction, speed_value, acceleration_value)
	go_attack(is_attacking, global_position, ring_direction)
	go_anim(delta, direction, is_boosting)
	update_labels(speed_value)
	
	pass_duration(delta)
