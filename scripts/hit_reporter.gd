extends Area2D
@export var bodyChief: UnitBody

func _ready():
	# set collision layers
	
	# for enemy
	if bodyChief.unit.allegiance == 2:
		set_collision_layer_value(9, true)
		set_collision_layer_value(10, true)
	# for player/ally
	else:
		set_collision_layer_value(17, true)
		set_collision_layer_value(18, true)

func get_unit_id() -> int:
	# calls up the chief and returns the unit id.
	# We use this so that we don't hit the same unit multiple times.
	return bodyChief.unit.combat_id

func report_hit(proj_damage: int, proj_knockback: Vector2, stun: float) -> void:
	# simply report the hit up to the boss
	bodyChief.being_hit(proj_damage, proj_knockback, stun)
