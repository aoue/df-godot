extends Node2D

var cursor_sprite = load("res://assets/ui/encounter_cursor.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_custom_mouse_cursor(cursor_sprite)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
