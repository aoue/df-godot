extends Node

"""
Holds the coefficients for things like:
	speed
	damage
	knockback
	hp
and etc

The actual value is set here, and all stats are proportional to the coefficient value set out here.
"""

"""Combat Balance"""
var move_cooldown: float = 0.25
var rotation_speed: int = 10
var speed: int = 5000
var acceleration: float = 0.08
var hp: int = 1000
var damage: int = 1000
var knockback: float = 200
var hit_stun_duration: float = 1.0
var stun_shield_duration: float = 1.0

"""Purely Visual"""
var damage_text_slowdown: float = 0.01
var hp_bar_update_speed: int = 500
var attack_colour_dict = {	# colours projectiles and damage numbers according to user.
	0: Color.ROYAL_BLUE,	# used by player.
	1: Color.GREEN_YELLOW,	# used by ally.
	2: Color.RED		# used by enemy.
}

"""Move Animation Helper"""
enum Move_Anim_Type {MELEE, RANGED, SPECIAL}
enum Move_Spawn_Type {FIRED, ON_RING, SUMMON}



