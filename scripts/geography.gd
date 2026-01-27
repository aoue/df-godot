extends Node2D
class_name Geography

"""
Holds basic information about the geography scene.
Will be read by the encounter on load to manage stuff.
"""

@export var sprite_mat: Sprite2D

func get_sprite_mat_x() -> int:
	return sprite_mat.texture.get_width() * scale.x

func get_sprite_mat_y() -> int:
	return sprite_mat.texture.get_height() * scale.y
