extends Node2D
class_name Unit

# Holds all the stat information for a unit. 
# Things like HP, PW, Loadouts, allegiance,
# All attack/damage stat-related information needs to be retrieved and modified here.
# But not movement-related things.

enum flag {PLAYER, ALLY, ENEMY}

# Basic statistics
@export var unitName : String
var HP_max : int
var HP_cur : int
var PW_max : int
var PW_cur : int
var stun_cur : int
@export var allegiance : flag
var combat_id : int  # assigned each battle. Value doesn't matter, as long as it is unique. Used for hit reporting.

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
@export var all_loadouts : Array[Loadout]
var loadout : Loadout
var loadout_pointer : int
var loadout_gate_time : float
var active_move : Move
var early_exit_taken : bool = false

func refresh(HP_max_coeff: float, PW_max_coeff: float):
	# sets the unit's stats to their initial state
	HP_max = HP_max_coeff * Coeff.hp
	HP_cur = HP_max
	PW_max = PW_max_coeff * Coeff.hp
	PW_cur = PW_max
	
	loadout_pointer = 0
	loadout_gate_time = 0.0
	update_loadout_status()
	
# Being Attacked
func take_damage(damage : int, breakPer: int) -> void:
	HP_cur = clamp(HP_cur - damage, 0, HP_max)
	stun_cur = clamp(stun_cur + breakPer, 0, 100)

func is_defeated() -> bool:
	if HP_cur == 0:
		return true
	return false

func summon_period_over() -> bool:
	return (active_move.spawn_type == 2 and attacking_duration_left <= active_move.move_duration)

func summon_waiting_for_2nd_click() -> bool:
	return active_move and active_move.spawn_type == 2 and not summon_all_green

# Attacking
func early_exit() -> void:
	if early_exit_taken:  # idempotent
		return
	early_exit_taken = true
	attacking_duration_left = Coeff.move_cooldown
	can_attack_cooldown = Coeff.move_cooldown
	move_boost_duration_left = Coeff.move_cooldown

func update_loadout_status() -> void:
	if not loadout:
		loadout = all_loadouts[0]
	elif loadout.is_loadout_finished():
		#print("Current loadout finished... switching loadout")
		loadout.finished()
		# switch loadout
		loadout_pointer += 1
		if loadout_pointer == len(all_loadouts):
			loadout_pointer = 0
		loadout = all_loadouts[loadout_pointer]
		loadout_gate_time = Coeff.loadout_cooldown
	loadout.refresh()

func use_active_move(unit_pos : Vector2, ring_indicator_vector : Vector2, ring_indicator_obj : Node2D):
	# This function is called like all the time when you are in an attack; as soon as you click to attack.
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
			
		#  try :combo incentive?
		# if the move has hit, then you can immediately finish it after the last projectile has been fired
		elif projectile_counter == len(active_move.fire_table) and scored_hit and not early_exit_taken:
			early_exit()
		return
	if can_attack == false:
		return
	
	# check loadout state: either give next move or switch to next loadout
	if loadout_gate_time > 0.0:
		return
	var next_move = loadout.get_next_move()
	update_loadout_status()
	
	# enter 'new active move' state
	active_move = next_move.instantiate()
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
	early_exit_taken = false

func fire(unit_pos : Vector2, ring_indicator_vector : Vector2, ring_indicator_obj : Node2D):
	# find its spawn location (between player and mouse), offset
	
	var offset: int = Coeff.proj_spawn_offset * active_move.proj_spawn_offset
	var spawn_direction : Vector2 = Vector2.ZERO
	if active_move.spawn_type != 1:
		spawn_direction = ((unit_pos + offset * ring_indicator_vector) - unit_pos).normalized()
	var proj_spawn_loc : Vector2 = unit_pos + (spawn_direction * offset)
	
	#var temp = unit_pos - proj_spawn_loc
	#print("proj spawn loc relative = " + str(temp))
	
	# calculate recoil too
	if active_move.recoil_moment == 1:
		recoil = spawn_direction * active_move.recoil_knockback * Coeff.knockback
	
	# instantiate projectile 'proj'
	var proj : Object = active_move.spawn_projectiles(proj_spawn_loc, spawn_direction, allegiance, self)	
	if active_move.spawn_type == 1:  # 'on ring'
		proj.position = Vector2(offset, 0)
		ring_indicator_obj.add_child(proj)
	else:  # 'fired' or 'summon'
		# this projectile type should not be tied to the unit.
		# instead it will be tied to the projectile mother, guardian of all projectiles.
		ProjectileMother.place_projectile(proj)

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
		if active_move:
			active_move.queue_free()
		active_move = null
		can_attack_cooldown = max(0, can_attack_cooldown - delta)
		if can_attack_cooldown == 0.0:
			can_attack = true
	
	# manage move speed effect
	if move_boost_duration_left > 0.0:
		move_boost_duration_left = max(0, move_boost_duration_left - delta)
		
	# manage loadout switch
	if loadout_gate_time > 0.0:
		loadout_gate_time = max(0, loadout_gate_time - delta)

