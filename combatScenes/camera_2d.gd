extends Camera2D


"""
Encounter scene camera.
Takes in unit to follow.
Takes in map boundaries.

Follows player but avoids map boundaries.


"""
var followThisGuy : UnitBody = null
var player_followWeight : float = 0.75
var pointer_followWeight : float = 0.25

func setup(toFollow: UnitBody, x_limit: int, y_limit: int) -> void:
	followThisGuy = toFollow
	limit_smoothed = true
	@warning_ignore("integer_division")
	limit_left = -x_limit / 2
	@warning_ignore("integer_division")
	limit_right = x_limit / 2
	@warning_ignore("integer_division")
	limit_bottom = y_limit / 2
	@warning_ignore("integer_division")
	limit_top = -y_limit / 2

func _physics_process(_delta) -> void:
	# follow after followThisGuy
	if followThisGuy:
		# position is a mix between guy and mouse
		#var mouse_pos = get_global_mouse_position()
		self.position = ((followThisGuy.position * player_followWeight) + (get_global_mouse_position() * pointer_followWeight)) / 2.0		
