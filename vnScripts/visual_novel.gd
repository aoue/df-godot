extends Node2D

"""
This is the coordinator for the visual novel scenes in the game.
While we're under-construction, it will hold a bunch of stuff that will later be refactored out.

Right now, we're working on:
	- background image
	- live snow falling effect
"""

@export_group("Visual Assets")
@export var back_sprite: Sprite2D
@export var snowStuff: GPUParticles2D
@export var fore_sprite: Sprite2D
@export var cutIn_sprite: Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
