extends Node
class_name Unit

# Holds all the stat information for a unit. 
# Things like HP, PW, Loadouts, allegiance,
# All attack/damage stat-related information needs to be retrieved and modified here.
# But not movement-related things.

enum flag {PLAYER, ALLY, ENEMY}

# Basic statistics
var HP_max : int
var HP_cur : int
var PW_max : int
var PW_cur : int
@export var allegiance : flag
var combat_id : int  # set automatically when spawned in by encounter.

# Attack boost variables
var move_boost_duration_left : float = 0.0

# Attack variables
var attacking_duration_left : float = 0.0
var projectile_counter : int = 0
var can_attack : bool = true
var can_attack_cooldown : float = 0.0
var set_attack_anim : bool = false
var scored_hit: bool = false
var summon_all_green: bool = false
var recoil : Vector2

# Loadouts and moves
# (will have a link to a move, which has both:
# - a link to its projectile type 
# - a function that specifies the usage and spawning of projectiles)
@export var move1 : PackedScene
var active_move : Object

func refresh(HP_max_coeff: float, PW_max_coeff: float):
	# sets the unit's stats to their initial state
	HP_max = HP_max_coeff * Coeff.hp
	HP_cur = HP_max
	PW_max = PW_max_coeff * Coeff.hp
	PW_cur = PW_max
	
	# temporary
	combat_id = 0

# Being Attacked
func take_damage(damage : int) -> void:
	HP_cur = clamp(HP_cur - damage, 0, HP_max)

func is_defeated() -> bool:
	if HP_cur == 0:
		return true
	return false

func summon_period_over() -> bool:
	return (active_move.spawn_type == 2 and attacking_duration_left <= active_move.move_duration)

func summon_waiting_for_2nd_click() -> bool:
	return active_move.spawn_type == 2 and not summon_all_green

# Attacking
func use_active_move(unit_pos : Vector2, ring_indicator_vector : Vector2, ring_indicator_obj : Node2D):
	# If we are not attacking but are eligible too, then we switch the active move and start it.
	# If we are already in the middle of using a move, then we check against fire times and call fire() if appropriate
	if attacking_duration_left > 0.0:
		# summon conditions: if you are a summon move then:
		#	-you may not fire if still in the summon period
		#	-you may not fire if awaiting second click
		if active_move.spawn_type == 2 and not summon_period_over():
			return
		if summon_waiting_for_2nd_click():
			return
		# check against active move's fire times
		if projectile_counter < len(active_move.fire_table) and attacking_duration_left <= active_move.move_duration * active_move.fire_table[projectile_counter]:
			projectile_counter += 1
			fire(unit_pos, ring_indicator_vector, ring_indicator_obj)
		return
	if can_attack == false:
		return
	
	# enter 'new active move' state
	active_move = move1.instantiate()  # will map depending on which move was selected
	# set timers
	attacking_duration_left = active_move.move_duration + active_move.summon_duration
	move_boost_duration_left = active_move.move_speed_add_duration
	projectile_counter = 0
	can_attack_cooldown = attacking_duration_left + active_move.summon_duration + Coeff.move_cooldown
	# set flags
	set_attack_anim = true
	can_attack = false
	scored_hit = false
	summon_all_green = false

func fire(unit_pos : Vector2, ring_indicator_vector : Vector2, ring_indicator_obj : Node2D):
	# find its spawn location (between player and mouse), offset
	# Note: 650 is the ring indicator offset.
	var offset: int = 650 * active_move.proj_spawn_offset
	var spawn_direction : Vector2 = ((unit_pos + offset * ring_indicator_vector) - unit_pos).normalized()  
	var proj_spawn_loc : Vector2 = unit_pos + (spawn_direction * offset)
	
	# calculate recoil too
	if active_move.recoil_moment == 1:
		recoil = spawn_direction * active_move.recoil_knockback * Coeff.knockback
	
	# instantiate projectile into the scene
	var proj : Object = active_move.spawn_projectiles(proj_spawn_loc, spawn_direction, allegiance, self)
	if active_move.spawn_type == 1:  # 'on ring' 
		ring_indicator_obj.add_child(proj)
		proj.position = Vector2(offset, 0)
	else:  # 'fired' or 'summon'
		add_child(proj)

func report_hit(hit_body_position : Vector2) -> void:
	# Called by projectile when it scores a hit to let the unit know what's happened.
	#print("Scored hit!")
	scored_hit = true
	
	# report knockback too, if 'on_hit' type
	if active_move and active_move.recoil_moment == 2:
		var recoil_angle : float = get_parent().global_position.angle_to_point(hit_body_position)
		var recoil_scalar : float = active_move.recoil_knockback * Coeff.knockback
		recoil = Vector2(cos(recoil_angle), sin(recoil_angle)).normalized() * recoil_scalar

func _process(delta):
	# manage attack cooldown
	if attacking_duration_left > 0.0:
		if summon_waiting_for_2nd_click():
			attacking_duration_left = max(active_move.move_duration, attacking_duration_left - delta)
		else:
			attacking_duration_left = max(0, attacking_duration_left - delta)
	else:
		active_move = null
		can_attack_cooldown = max(0, can_attack_cooldown - delta)
		if can_attack_cooldown == 0.0:
			can_attack = true
	
	# manage move speed effect
	if move_boost_duration_left > 0.0:
		move_boost_duration_left = max(0, move_boost_duration_left - delta)

