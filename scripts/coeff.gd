extends Node

"""
Holds the coefficients for things like:
	speed
	damage
	knockback
	hp
	pw
	pw cost
and etc

The actual value is set here, and all stats are proportional to the coefficient value set out here.
"""

"""Already in use"""
var speed: int = 5000
var acceleration: float = 0.08
var hp: int = 1000
var damage: int = 1000
var knockback: float = 200
var damage_text_slowdown: float = 0.01
var hp_bar_update_speed: int = 500

"""Not yet in use"""
var delay : int = 1
# var spawn_distance (to make sure to clear the unit's own hitbox...?? 
# or maybe this will because irrelevant once the layers are set up) 
