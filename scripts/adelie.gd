extends UnitBody

"""
Its own special functions will have to cover its AI.

1. navigation
var speed: float
var acceleration: float
var knockback: Vector2

"""
@export_group("AI")
@export var nav: NavigationAgent2D

var movement_target_position: Vector2 = Vector2(1000.0, 2500.0)

func _ready():
	super()
	actor_setup.call_deferred()
	
func actor_setup():
	await get_tree().physics_frame
	set_movement_target(movement_target_position)
	
func set_movement_target(movement_target: Vector2):
	nav.target_position = movement_target

func _physics_process(delta):
	if nav.is_navigation_finished():
		set_movement_target(Vector2.ZERO)
		return
	
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = nav.get_next_path_position()
	
	velocity = current_agent_position.direction_to(next_path_position) * speed
	move_and_slide()
