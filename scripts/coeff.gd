extends Node

"""
Holds the coefficients for things like:
	speed
	damage
	knockback
	hp
and etc

The values are set here, and all stats are proportional to the coefficient value described.
"""

"""Combat Balance"""
var combo_timeout_duration: float = 1.0  # time it takes for a combo to elapse if you do not attack.
var combo_output_relief_speed: float = 60  # how quickly combo_output is reduced (amount in 1 second).
var combo_output_to_enter_combo: float = 0.0  # the unit's combo output must be leq than this to begin a new combo.
# ^unsure whether this value should be 0 or 50 or customizable or what

var loadout_cooldown: float = 0.1  # time it takes to switch to the next loadout
var move_cooldown: float = 0.2  # time between using moves
var move_rotation_mod: float = 1.0 # affects speed of rotation when using a move.

#var proj_spawn_offset : int = 750
var proj_spawn_offset : int = 50  # to prevent facehugging, it seems.
var rotation_speed: int = 20  # speed at which indicators rotate
var speed: int = 8000  # speed at which units move across the map
var acceleration: float = 0.08  # acceleration at which units increase speed

var hp: int = 1  # base hp value multiplier
var damage: int = 1  # base damage value multiplier
var knockback: float = 200  # base knockback value

var move_stun_duration: float = 0.2  # base duration of movement lockout on being hit
var hit_stun_duration: float = 1.0  # base duration (s) of attacking lockout on being hit
var hit_stun_shield_duration: float = 1.0  # duration (s) of stun immunity after being stunned
var hit_stun_rotation_speed: float = 0.0  # at 0, cannot rotate when hit.

"""Movement Constants"""
var boost_speed_set: float = 9000.0  # boosting sets your speed to this value
var boost_full_duration: float = 0.25  # how long the boost lasts
var boost_shield_full_duration: float = boost_full_duration
var boost_full_cooldown: float = 2.0  # how long until you may boost again
var full_speed_angle_gate: float = PI / (8.0 / 3)  # how large the angle between the indicator and the movement input may be while the unit still moves at full speed

"""AI Parameters"""
var boost_min_distance_to_trigger: float = 3500.0  # the minimum distance a unit must want to travel to consider boosting
var feel_threatened_at_distance: float = 5000.0  # how close a hostile may be to a unit before it feels threatened
var time_before_boost_permitted: int = 1000  # how long (ms) a unit must be in a given intention before it may boost.
var retreat_randomness_range: float = PI/2.0  # how far a unit may veer off from its retreat course.
var time_between_intention_update: int = 2000  # in ms. temp for now.
var attack_permission_timer: int = 2000  # lockout time on giving permission for another unit to attack a unit (in milliseconds)
var standoff: float = 1000.0  # base distance ai units want between themselves and their targets
var move_range: float = 1000.0  # base value for min range and max range of ai moves

"""Purely Visual"""
var damage_text_slowdown: float = 0.01  # affects the short continued moving effect of damage text on hit
var hp_bar_update_speed: int = 500  # affects the speed at which the hp bar updates
var attack_colour_dict = {	# colours projectiles and damage numbers according to user.
	0: Color.DARK_BLUE, 	# used by player.
	1: Color.CORNFLOWER_BLUE,	# used by ally.
	2: Color.RED		# used by enemy.
}

"""Move Animation Helper"""
enum Move_Anim_Type {MELEE, RANGED, SPECIAL}
enum Move_Spawn_Type {FIRED, ON_RING, SUMMON}
