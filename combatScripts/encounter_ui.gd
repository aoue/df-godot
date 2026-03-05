extends Control
class_name EncounterUI

@export var quitButton : Button


func _ready():
	quitButton.pressed.connect(_quit_button_pressed)

func _quit_button_pressed() -> void:
	get_tree().quit()
