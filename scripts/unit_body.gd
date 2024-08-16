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

# Moveset
#@export var move1: move

""" Setup """
func _ready() -> void:
	unit.refresh(HP_max_coeff, PW_max_coeff)
	hp_bar.max_value = unit.HP_max
	hp_bar.value = unit.HP_max
	speed = speed_coeff * Coeff.speed
	acceleration = acceleration_coeff * Coeff.acceleration

""" Reacting """
func being_attacked(damage: int) -> void:
	# When you are attacked, you do a few things:
	unit.take_hit(damage)
	if unit.is_defeated():
		start_being_defeated()

func start_being_defeated() -> void:
	# does some stuff when the unit is defeated
	# probably has a dying animation and timer, then also leaves a body behind
	pass

func update_hp_bar(new_value: int, delta: float) -> void:
	# Graphical only; we don't check for death or anything like that here.
	if hp_bar.value > new_value:
		hp_bar.value -= Coeff.hp_bar_update_speed * delta
	elif hp_bar.value < new_value:
		hp_bar.value += Coeff.hp_bar_update_speed * delta

""" Running """
func go_anim(delta: float) -> void:
	update_hp_bar(unit.HP_cur, delta)
	
#func go_move(delta: float, direction_input: Vector2, speed_input: int, acceleration: float) -> void:
	#if direction_input.length() > 0:
		#velocity = velocity.lerp(direction_input * speed_input, acceleration)
	#else:
		#velocity = velocity.lerp(Vector2.ZERO, acceleration)
	#move_and_slide()


func _physics_process(delta: float) -> void:	
	#*how does it decide what to do?
	#-if already doing something; keep doing it (attack, dodge, travel)
	#-check location of units from encounter
	#-choose thing to do based on location of units (attack, dodge, travel)
	#-execute plan (use move, boost, or move somewhere/towards something)
	
	#var acceleration_value = acceleration
	#var speed_value = speed
	
	#
	go_anim(delta)
	
	#pass_duration(delta)
	#move_and_slide()
