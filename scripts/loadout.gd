extends Node2D
class_name Loadout

@export var loadoutID : int

@export_group("Move Slots")
@export var slot0 : PackedScene
@export var slot1 : PackedScene
@export var slot2 : PackedScene

var slot_links : Array
var used_slot_links : Array
var slot_pointer : int
var already_refreshed : bool = false
var filled_slots : int

func refresh() -> void:
	# called when the loadout is activated.
	if already_refreshed:
		return
	already_refreshed = true
	slot_pointer = 0
	used_slot_links = []
	slot_links = [slot0, slot1, slot2]
	filled_slots = 0
	for slot in slot_links:
		if slot != null:
			filled_slots += 1

func do_not_refresh() -> void:
	already_refreshed = false

func combo_end() -> void:
	slot_pointer = filled_slots

func is_loadout_finished() -> bool:
	return slot_pointer == filled_slots

func get_next_move() -> PackedScene:
	# returns the move corresponding to the current slot id
	# updates state as well
	var to_return : PackedScene = slot_links[slot_pointer]
	slot_pointer += 1
	return to_return

func peek_next_move() -> PackedScene:
	return slot_links[slot_pointer]
	
