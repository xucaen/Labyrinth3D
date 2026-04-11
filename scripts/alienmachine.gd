extends MeshInstance3D

func _ready():
	# This ensures each capsule blinks independently 
	# rather than all of them pulsing in unison.
	var mat = get_active_material(0)
	if mat:
		set_surface_override_material(0, mat.duplicate())

func _process(_delta):
	# Get the material we duplicated in _ready
	var mat = get_surface_override_material(0) as StandardMaterial3D
	
	if mat:
		# Time.get_ticks_msec() returns a large integer, 
		# so we multiply by a small decimal to control speed.
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) / 2.0
		
		# Apply the pulse to the Emission Energy
		mat.emission_energy_multiplier = pulse * 5.0
