extends Node2D

var cursor_sprite = load("res://assets/ui/encounter_cursor.png")

#@export_group("World")
#@export var proj_mother : Node2D

@export_group("Units")
@export var Anse : PackedScene
@export var Adelie : PackedScene

var anse_in_world : UnitBody
var adelie_in_world : UnitBody



# Called when the node enters the scene tree for the first time.
func _ready():
	#Input.set_custom_mouse_cursor(cursor_sprite)
	#var a = Coeff.speed
	#print("coeff speed = " + str(a))
	create_world()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func create_world() -> void:
	# hardcoded
	anse_in_world = Anse.instantiate()
	add_child(anse_in_world)
	
	adelie_in_world = Adelie.instantiate()
	adelie_in_world.position = Vector2(1302, 33)
	add_child(adelie_in_world)
	

	
