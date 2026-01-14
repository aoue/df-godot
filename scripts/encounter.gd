extends Node2D

var cursor_sprite = load("res://assets/ui/encounter_cursor.png")

#@export_group("World")
#@export var proj_mother : Node2D

@export_group("Units")
@export var Anse : PackedScene
@export var Adelie : PackedScene
@export var Friendly : PackedScene

@export_group("Testing")
@export var fixedCamera : Camera2D

""" Testing """
var anse_in_world : UnitBody
var friendly_in_world : UnitBody

var enemy_group : Array[UnitBody] = []
var enemy_count: int = 1
var call_friendly: bool = true
var camera_mode: bool = false

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
	
	if call_friendly:
		friendly_in_world = Friendly.instantiate()
		friendly_in_world.position = Vector2(-1250, 0)
		add_child(friendly_in_world)
		GameMother.add_hero(friendly_in_world)
	
	if camera_mode:
		fixedCamera.enabled = true
	else:
		fixedCamera.enabled = false
		anse_in_world = Anse.instantiate()
		add_child(anse_in_world)
		GameMother.add_hero(anse_in_world)
	
	var spawn_offset: int = 0
	var flip_offset: int = 1
	for i in range(0, enemy_count):
		var adelie_in_world: UnitBody = Adelie.instantiate()
		adelie_in_world.position = Vector2(5000 * flip_offset, spawn_offset)
		add_child(adelie_in_world)
		GameMother.add_villain(adelie_in_world)
		spawn_offset += 500
		flip_offset = flip_offset * -1
	
	# Once all units are created. Necessary for proper hit register.
	GameMother.assign_combat_ids()
	
	

	
