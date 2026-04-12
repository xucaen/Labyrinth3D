extends OmniLight3D

@export var base_energy: float = 3.0
@export var flicker_speed: float = 2.0  # Lower is slower
@export var flicker_depth: float = 0.5  # How much it dims

func _process(delta):
	var time = Time.get_ticks_msec() / 1000.0
	# sin() creates a smooth wave between -1 and 1
	var wave = sin(time * flicker_speed) 
	
	light_energy = base_energy + (wave * flicker_depth)
