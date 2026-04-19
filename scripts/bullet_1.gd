extends Node3D

@export var speed: float = 150.0  
@export var max_distance: float = 1000.0

@onready var start_position: Vector3 = global_position


func reset_bullet():
	start_position = global_position


func _process(delta: float) -> void:
	# This moves the bullet forward relative to its own local orientation
	# It doesn't rotate the bullet; it just reads the existing direction
	var forward_vector = -global_transform.basis.z
	global_position += forward_vector * speed * delta

	# Despawn logic based on distance from start
	if global_position.distance_to(start_position) >= max_distance:
		despawn()
		

func _on_body_entered(body: Node):
	# Standard cleanup on hit
	if not body is CharacterBody3D: 
		despawn()

func despawn():
	visible = false
	set_process(false) # This "frees" it up for the ship's list check
	global_position = Vector3(0, -100, 0) # Move it out of view just in case
