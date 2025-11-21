extends Area2D
@export var bodyChief: UnitBody

func get_unit_id() -> int:
	# calls up the chief and returns the unit id.
	# We use this so that we don't hit the same unit multiple times.
	return bodyChief.unit.combat_id

func report_hit(proj_damage: int, proj_knockback: Vector2, stun: float) -> void:
	# simply report the hit up to the boss
	bodyChief.being_hit(proj_damage, proj_knockback, stun)
