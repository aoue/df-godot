extends Move

"""
Works the same as move under the hood.

Here, we save some variables that help the AI choose when and in what position to use the move.
For example, the AiMove 'ai_rifle' specifies the range at which the ai may use it at.

And of course, the variables here are all relative to constants set in Coeff.
"""

@export_group("AI")
@export var miss_delay: float  # forced wait (unmoving) on miss
@export var min_range: float
@export var standoff_distance: float
@export var max_range: float

func get_standoff_distance() -> float:
	return standoff_distance * Coeff.standoff

func get_min_range() -> float:
	return min_range * Coeff.move_range
	
func get_max_range() -> float:
	return max_range * Coeff.move_range

func get_miss_delay() -> float:
	return miss_delay
