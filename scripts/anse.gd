extends UnitBody

# References
@export var boost_anim : AnimatedSprite2D

""" Setup """

""" Input """
func get_direction_input() -> Vector2:
	if boost_duration > 0.0:
		return boost_vector
	
	# Cannot move if stunned
	if hit_stun_duration > 0.0:
		return Vector2.ZERO
		
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
	if boost_duration > 0.0:  # already boosting
		return true
		
	if Input.is_action_pressed('boost') and boost_cooldown <= 0.0 and direction.length() > 0:  # start boosting
		# Save current direction for our boost
		boost_vector = direction
		boost_duration = Coeff.boost_full_duration
		boost_cooldown = Coeff.boost_full_cooldown + Coeff.boost_full_duration  # wow that's pretty smart (it was my idea)
		return true
	return false

func get_target_position() -> Vector2:
	# Returns the vector that the unitBody is looking at
	return get_mouse()
	
func get_attack_input() -> bool:
	if Input.is_action_pressed('attack_lmb'):
		return true
	return false

""" Reacting """


""" Running """
func get_mouse() -> Vector2:
	return get_global_mouse_position()

func set_anim_plus(isBoosting: bool) -> void:
	# Control BoostAnim
	if isBoosting:
		boost_anim.play("boost")
		boost_anim.show()
	else:
		boost_anim.hide()

#func go_attack(unit_pos: Vector2, mouse_input: Vector2) -> void:
	#if attack_input:
		#unit.use_move1(unit_pos, mouse_input)

