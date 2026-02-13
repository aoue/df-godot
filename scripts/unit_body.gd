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

@export_group("Display")
@export var stat_labels : Node2D
@export var output_label : Label
@export var utility_label : Label
@export var speed_label : Label
@export var floating_text : PackedScene

@export_group("Stat Coeffs")
# Basic movement variables
@export var HP_max_coeff: float
@export var speed_coeff: float
@export var rotation_coeff: float
@export var acceleration_coeff: float
var speed: float
var acceleration: float
var knockback: Vector2

# Die beautifully
var defeated: bool = false
var defeated_disappear_timer: float = 5.0

# Boost variables
var boost_shield: float = 0.0
var boost_acceleration: float = 2.0 * Coeff.acceleration
var boost_vector: Vector2 = Vector2.ZERO
var boost_duration: float = 0.0
var boost_cooldown: float = 0.0

# Being hit variables
var move_stun_duration: float = 0.0  # remaining stun duration on unit, impedes movement.
var hit_stun_duration: float = 0.0  # remaining stun duration on unit, impedes attacking.

# Moveset
#@export var move1: move

""" Setup """
func _ready() -> void:
	unit.refresh(HP_max_coeff)
	hp_bar.max_value = unit.HP_max
	hp_bar.value = unit.HP_max
	speed = speed_coeff * Coeff.speed
	acceleration = acceleration_coeff * Coeff.acceleration
		
	# Colour ring
	var unit_colour: Color = Coeff.attack_colour_dict[unit.allegiance]
	ring.self_modulate = unit_colour
	ring_indicator.self_modulate = unit_colour
	
	# Label colours
	output_label.self_modulate = unit_colour
	
	# setup unit's physical collision
	if unit.allegiance == 2:  # if enemy
		set_collision_layer_value(2, true)
		set_collision_mask_value(2, true)
	elif unit.allegiance == 1:  # if ally
		set_collision_layer_value(3, true)
		set_collision_mask_value(3, true)

""" Input """
func get_direction_input_helper() -> Vector2:
	if move_stun_duration > 0.0:
		return Vector2.ZERO
	#if boost_duration > 0.0:
		#return boost_vector
	
	return get_direction_input()
	
func get_direction_input() -> Vector2:
	return Vector2.ZERO
	
func get_boost_input(_direction: Vector2) -> bool:
	return false

func get_attack_input_helper() -> bool:	
	if hit_stun_duration > 0.0:
		return false
	if unit.output_exceeding_limit():
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

func end_combo_ai() -> void:
	# pure virtual
	pass

func being_hit_ai() -> void:
	# pure virtual
	pass
	
func being_hit(proj_damage: int, proj_knockback: Vector2, stun: float) -> void:
	# Do damage and cause knockback
	unit.take_damage(proj_damage)
	knockback += proj_knockback
	
	# Give the unit's ai the chance to react to this.
	being_hit_ai()
	
	# Cancel any ongoing action
	# immediately cancel the unit's attack as well, if that is ongoing.
	unit.emergency_exit()
	
	# Be stunned, if appropriate
	if stun > 0:
		move_stun_duration = Coeff.move_stun_duration  # movement stun
		hit_stun_duration = stun  # attack stun
		# hit stun shield only activates when the unit's stun is about to expire.
	
	# Die, if appropriate
	if unit.is_defeated():
		go_be_defeated()

func go_be_defeated() -> void:
	# few things to do:
	# you can never act again, so set that flag
	defeated = true
	character_anim.play("5b_defeated")
	# hide hpbar and ring stuff
	ring.hide()
	hp_bar.hide()
	GameMother.free_unit(unit.allegiance, self)
	
	# turn off collision for movement and projectiles
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func get_delay_between_actions() -> float:
	return 0.0

""" UI """
func update_timing_bar(delta: float) -> void:
	# first: discover value we should be comparing:
	
	var new_value : float = 0
	var new_max_value : float = 1
	
	# case 0: we are stunned
	if hit_stun_duration > 0.0:
		new_max_value = Coeff.hit_stun_duration
		new_value = hit_stun_duration
	## case 1: we are attacking; update attack thing
	elif unit.attacking_duration_left > 0.0:
		new_max_value = unit.active_move.get_total_duration()
		new_value = unit.attacking_duration_left
	# case 2: in cooldown
	elif unit.can_attack_cooldown > 0.0:
		new_max_value = Coeff.move_cooldown
		new_value = unit.can_attack_cooldown
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

func update_labels(_speed_value : float) -> void:
	output_label.text = str(snapped(unit.combo_output, 1)) + "%"
	#stun_label.text = str(unit.stun_cur) + "%"
	#utility_label.text = "UTL--" + str(timing_bar.value)
	#speed_label.text = "SPD--" + str(speed_value)

func show_loadout_swap(display_message: String) -> void:
	# display a visual element thing when swapping loadouts for readability
	var floating_loadout_swap_text = floating_text.instantiate()
	var display_str: String = display_message
	var display_colour: Color = Coeff.attack_colour_dict[unit.allegiance]
	var display_noise: int = 650
	
	var display_bias_radians: float = ring_indicator.rotation
	var display_bias: Vector2 = Vector2(cos(display_bias_radians), sin(display_bias_radians)).normalized()
	floating_loadout_swap_text.display(display_str, display_colour, display_bias, display_noise)
	add_child(floating_loadout_swap_text)

""" Running """
func flip_unit() -> void:
	# check x direction for flipping
	# Set the rest animation corresponding to the vector between yourself and the target location.
	# if x component is greater, then look to the side
	# if y component is greater, then look up/down
	var look_dir: Vector2 = (get_target_position() - global_position).normalized()
	var x_power: float = look_dir.x
	#var y_power: float = look_dir.y
	if x_power > 0.0:
		character_anim.flip_h = false
	else:
		character_anim.flip_h = true

func set_anim(direction: Vector2) -> void:
	# Control CharacterAnim
	
	## NOTE: currently testing with single 3/4 angle, so disabling front and back rest/move anims.
	
	# Stunned?
	if move_stun_duration > 0.0:
		character_anim.play("5_being_hit")
		return
	# if dead and death delay passed: play("9b_defeated")
	
	# Attacking?
	if unit.set_attack_anim and unit.active_move:
		# Play the corresponding animation
		flip_unit()
		unit.set_attack_anim = false
		if unit.active_move.animation_type == 0:
			character_anim.play("2_melee")
		elif unit.active_move.animation_type == 1:
			character_anim.play("3_ranged")
		else:
			character_anim.play("4_special")
		return
	elif unit.attacking_duration_left > 0.0:
		if unit.scored_hit and unit.active_move.animation_type == 0:
			character_anim.play("2b_melee_finisher")
		# Don't play any other animation while ongoing
		return
	if unit.in_combo:
		return
	
	flip_unit()
	
	# set anims according to direction vector.
	if direction == Vector2.ZERO:
		character_anim.play("0_rest")
		#if abs(x_power) >= abs(y_power):
			#character_anim.play("0_side_rest")
		#else:
			#if y_power >= 0:
				#character_anim.play("2_front_rest")
			#else:
				#character_anim.play("4_back_rest")
	else:
		character_anim.play("1_move")
		#if abs(x_power) > abs(y_power):
			#character_anim.play("1_side_mov")
		#elif y_power > 0:
			#character_anim.play("3_front_mov")
		#elif y_power < 0:
			#character_anim.play("5_back_mov")

func set_anim_plus(_isBoosting: bool) -> void:
	# To set animations supporting the unit, but not the character animations themselves.
	pass

func go_anim(delta: float, direction_input: Vector2, boost_input: bool) -> void:
	set_anim(direction_input)
	set_anim_plus(boost_input)
	update_hp_bar(unit.HP_cur, delta)
	update_timing_bar(delta)

func go_boost(direction_value: Vector2) -> void:
	# Save current direction for our boost
	boost_shield = Coeff.boost_shield_full_duration
	boost_vector = direction_value
	boost_duration = Coeff.boost_full_duration
	boost_cooldown = Coeff.boost_full_cooldown + Coeff.boost_full_duration  # wow that's pretty smart (it was my idea)

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
		# force loadout switch
		unit.update_loadout_status()
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
	var rotation_weight: float = delta * rotation_coeff * Coeff.rotation_speed
	if unit.attacking_duration_left > 0.0:
		rotation_weight *= (unit.active_move.user_rotation_mod * Coeff.move_rotation_mod)
	if move_stun_duration > 0.0:
		rotation_weight *= Coeff.hit_stun_rotation_speed

	ring_indicator.rotation = rotate_toward(current_rotation, wanted_rotation_angle, rotation_weight)
	output_label.rotation = rotate_toward(-current_rotation, -wanted_rotation_angle, rotation_weight)
			
func get_ring_indicator_vector() -> Vector2:
	var x_component = cos(ring_indicator.rotation)
	var y_component = sin(ring_indicator.rotation)
	return Vector2(x_component, y_component)

func pass_duration(delta : float) -> void:
	boost_shield = max(0, boost_shield - delta)
	boost_duration = max(0, boost_duration - delta)
	boost_cooldown = max(0, boost_cooldown - delta)
	move_stun_duration = max(0, move_stun_duration - delta)
	hit_stun_duration = max(0, hit_stun_duration - delta)

func _physics_process(delta: float) -> void:
	if defeated:
		defeated_disappear_timer -= delta
		go_move(Vector2.ZERO, 0, acceleration)  # show the knockback still, though.
		# start fading out as well
		# function, do nothing for 1 second, then fade out at a constant rate over 5 seconds
		var color_alpha: Color = Color(Color.WHITE, 0.2 * defeated_disappear_timer)
		modulate = color_alpha
		if defeated_disappear_timer < 0.05:
			queue_free()
		return
		
	var direction: Vector2 = get_direction_input_helper()
	var ring_direction: Vector2 = get_ring_indicator_vector()
	var is_attacking: bool = get_attack_input_helper()
	var target_pos: Vector2 = get_target_position()
	var is_boosting: bool = get_boost_input(direction)
	
	var acceleration_value = acceleration
	var speed_value = speed
	
	if unit.in_combo:
		speed_value *= unit.combo_speed_mod * 2
		
	if is_boosting:
		acceleration_value = boost_acceleration
		speed_value += Coeff.boost_speed_set
	elif unit.move_boost_duration_left > 0.0 and (not unit.scored_hit or unit.active_move and unit.active_move.proj_passthrough):
		# if the move boosts, then add its speed and prioritize its own direction
		speed_value += (unit.active_move.move_speed_add * Coeff.speed)
		direction = ring_direction
	elif is_backpedaling(direction, ring_direction):
		speed_value *= Coeff.backpedaling_speed_mod
	
	adjust_indicators(target_pos, delta)
	go_move(direction, speed_value, acceleration_value)
	go_attack(is_attacking, global_position, ring_direction)
	go_anim(delta, direction, is_boosting)
	update_labels(speed_value)
	
	pass_duration(delta)
