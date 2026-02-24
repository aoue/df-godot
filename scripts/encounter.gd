extends Node2D

var cursor_sprite = load("res://assets/ui/encounter_cursor.png")

#@export_group("World")
#@export var proj_mother : Node2D


@export var mainCamera : Camera2D
@export var musicPlayer: AudioStreamPlayer
@export var uiManager: EncounterUI

""" Specific encounter setup """
@export var levelSong : AudioStream
@export var geoMapPacked : PackedScene

@export_group("Units")
@export var Anse : PackedScene
@export var Adelie : PackedScene
@export var Friendly : PackedScene


var geoMap : Geography

""" Testing """
var anse_in_world : UnitBody
var friendly_in_world : UnitBody

var enemy_group : Array[UnitBody] = []
var enemy_count: int = 4
var call_friendly: bool = true
var auto_mode: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#Input.set_custom_mouse_cursor(cursor_sprite)
	create_world.call_deferred()

func create_world() -> void:
	# hardcoded
	# will do things like: load encounter 
	# (includes geography, units/enemies starting positions, gamerules, etc)
	#GameMother.setup_UI()
	
	# Setup world
	geoMap = geoMapPacked.instantiate()
	add_child(geoMap)
	GameMother.setup_map_info(geoMap.get_sprite_mat_x(), geoMap.get_sprite_mat_y())
	
	musicPlayer.play()
	
	# Setup Units	
	if call_friendly:
		friendly_in_world = Friendly.instantiate()
		friendly_in_world.position = Vector2(-5000, 0)
		add_child(friendly_in_world)
		GameMother.add_unit(friendly_in_world)
		if auto_mode:
			mainCamera.setup(friendly_in_world, geoMap.get_sprite_mat_x(), geoMap.get_sprite_mat_y())
	
	if not auto_mode:
		anse_in_world = Anse.instantiate()
		add_child(anse_in_world)
		GameMother.add_unit(anse_in_world)
		# pass character and map info to camera.
		mainCamera.setup(anse_in_world, geoMap.get_sprite_mat_x(), geoMap.get_sprite_mat_y())
	
	var spawn_offset: int = -1000
	var flip_offset: int = 1000
	for i in range(0, enemy_count):
		var adelie_in_world: UnitBody = Adelie.instantiate()
		adelie_in_world.position = Vector2(5000 + flip_offset, spawn_offset)
		add_child(adelie_in_world)
		GameMother.add_unit(adelie_in_world)
		spawn_offset += 500
		flip_offset = flip_offset * -1
	
	
	# Once all units are created. Necessary for proper hit register.
	GameMother.assign_combat_ids()
	
	

	
