extends Label

var lifetime : float

# Called every frame. 'delta' is the elapsed time since the previous frame.

func display(display_str: String, display_colour: Color, display_bias: Vector2 = Vector2.ZERO, display_noise: int = 500, display_lifetime: float = 0.5) -> void:
	# places itself generically
	text = display_str
	self_modulate = display_colour
	lifetime = display_lifetime
	
	var placement_noise: Vector2 = Vector2(randi_range(-display_noise/2, display_noise/2), randi_range(-display_noise/2, display_noise/2))
	position = (display_noise * display_bias) + placement_noise

func _process(delta):
	lifetime -= delta
	if lifetime < 0.0:
		queue_free()
