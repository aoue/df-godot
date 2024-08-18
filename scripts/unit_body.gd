extends CharacterBody2D
class_name UnitBody

# References
@export var unit: Node
@export var character_anim: AnimatedSprite2D
@export var hp_bar: TextureProgressBar

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
	
func get_mouse() -> Vector2:
	# Returns the vector between the player location and the mouse location
	return get_global_mouse_position()

""" Reacting """
func being_attacked(proj_damage: int, proj_knockback: Vector2) -> void:
	knockback = proj_knockback
	unit.take_damage(proj_damage)
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
	if direction.x > 0:
		character_anim.play("right")
	elif direction.x < 0:
		character_anim.play("left")
	elif direction.y != 0:
		character_anim.play("vertical")
	else:
		character_anim.play("still")

func set_anim_plus(mouse_pos: Vector2, isAttacking: bool, isBoosting: bool) -> void:
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

func go_attack(attack_input: bool, mouse_input: Vector2) -> void:
	pass

func pass_duration(delta : float) -> void:
	boost_duration -= delta
	boost_cooldown -= delta
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
		speed_value = speed * boost_speed_mod
	
	go_move(direction, speed_value, acceleration_value)
	go_attack(is_attacking, mouse_pos)
	go_anim(delta, direction, mouse_pos, is_attacking, is_boosting)
	
	pass_duration(delta)
