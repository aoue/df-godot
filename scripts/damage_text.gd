extends Label

var lifetime : float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta
	if lifetime < 0.0:
		queue_free()
