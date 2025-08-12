extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func place_projectile(proj : Object) -> void:
	# called when a projectile needs to be created in the world
	# (except for ring types)
	add_child(proj)
