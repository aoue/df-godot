extends UnitBody

# References
@export var weapon_pivot : Node
@export var weapon_anim : AnimatedSprite2D
@export var boost_anim : AnimatedSprite2D

""" Setup """

""" Input """
func get_direction_input() -> Vector2:
	if boost_duration > 0.0:
		return boost_vector
		
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

func get_target_direction() -> Vector2:
	# Returns the vector that the unitBody wants to move towards
	return get_mouse()
	
func get_attack_input() -> bool:
	if Input.is_action_pressed('attack0') or Input.is_action_pressed('attack1') or Input.is_action_pressed('attack2'):
		return true
	return false

""" Reacting """


""" Running """
func set_anim_plus(mouse_pos: Vector2, isAttacking: bool, isBoosting: bool) -> void:
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

func go_attack(attack_input: bool, mouse_input: Vector2) -> void:
	if attack_input:
		unit.use_move1(position, mouse_input)

