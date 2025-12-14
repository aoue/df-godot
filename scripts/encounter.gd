extends Node2D

var cursor_sprite = load("res://assets/ui/encounter_cursor.png")

#@export_group("World")
#@export var proj_mother : Node2D

@export_group("Units")
@export var Anse : PackedScene
@export var Adelie : PackedScene

""" Testing """
var anse_in_world : UnitBody
var adelie_in_world : UnitBody
var adelie_in_world2 : UnitBody
var adelie_in_world3 : UnitBody

# Called when the node enters the scene tree for the first time.
func _ready():
	#Input.set_custom_mouse_cursor(cursor_sprite)
	create_world.call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func create_world() -> void:
	# hardcoded
	# will do things like: load encounter 
	# (includes geography, units/enemies starting positions, gamerules, etc)
	GameMother.setup_UI()
	
	anse_in_world = Anse.instantiate()
	add_child(anse_in_world)
	GameMother.add_hero(anse_in_world)
	
	adelie_in_world = Adelie.instantiate()
	adelie_in_world.position = Vector2(3000, 0)
	add_child(adelie_in_world)
	GameMother.add_villain(adelie_in_world)
	
	#adelie_in_world2 = Adelie.instantiate()
	#adelie_in_world2.position = Vector2(2000, -1000)
	#add_child(adelie_in_world2)
	#GameMother.add_villain(adelie_in_world2)
	#
	#adelie_in_world3 = Adelie.instantiate()
	#adelie_in_world3.position = Vector2(1500, -1500)
	#add_child(adelie_in_world3)
	#GameMother.add_villain(adelie_in_world3)
	
	# Once all units are created. Necessary for proper hit register.
	GameMother.assign_combat_ids()
	
	

	
