extends Node3D

@export var rotation_speed: float = 0.5 

func _process(delta):
	# Access the parent node and ensure it is a Node3D so we can rotate it
	var parent = get_parent() as Node3D
	var offset = 1
	if parent:
		# Apply rotation to the parent's axes [cite: 10]
		# Multiplying by delta keeps it smooth regardless of FPS [cite: 11]
		parent.rotate_x(rotation_speed * offset * delta)
		parent.rotate_y(rotation_speed * offset * delta)
		parent.rotate_z(rotation_speed * offset * delta)
