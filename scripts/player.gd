extends CharacterBody3D

@export var speed: float = 10.0
@export var look_sensitivity: float = 0.05
@export var jump_velocity: float = 4.5

var camera: Camera3D
var rotation_x: float = 0.0
var rotation_y: float = 0.0

func _ready() -> void:
	# Hide mouse
	
	
	# Grab the camera
	camera = $Camera3D
	if not camera:
		push_error("Camera3D not found as child of Player!")

func _physics_process(delta: float) -> void:
	for i in range(10):
		var val = Input.get_joy_axis(0, i)
		#if abs(val) > 0.2:
			#print("Moving Axis: ", i, " Value: ", val)
	_handle_movement(delta)
	_handle_look_left_right(delta)
	_handle_look_up_down(delta)


func _handle_movement(delta: float) -> void:
	var input_vector := Vector3.ZERO

	# Left stick directly (Xbox Controller 0)
	input_vector.x = Input.get_joy_axis(0, 0)
	input_vector.z = Input.get_joy_axis(0, 1)

	#jump
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and is_on_floor():
			velocity.y = jump_velocity
		
	# Horizontal movement
	if input_vector.length() > 0.1:
		input_vector = input_vector.normalized() * speed  # <-- remove * delta
		var transform_dir := global_transform.basis
		var movement := transform_dir.x * input_vector.x + transform_dir.z * input_vector.z
		velocity.x = movement.x
		velocity.z = movement.z
	else:
		velocity.x = 0
		velocity.z = 0

	# Gravity (always applied)

	if not is_on_floor():
		velocity.y -= 9.8 * delta


	# Move the character
	move_and_slide()

func _handle_look_left_right(delta: float) -> void:
	# Right stick Horizontal (Axis 2)
	var look_x := Input.get_joy_axis(0, 2)
	
	if abs(look_x) < 0.1: 
		look_x = 0
	
	# Rotates the whole player node around the vertical Y axis
	rotation.y -= look_x * look_sensitivity

func _handle_look_up_down(delta: float) -> void:
	var look_y := -Input.get_joy_axis(0, 3) # Stick Forward is -1.0
	
	# Find the camera directly every frame to ensure we aren't hitting a null/wrong node
	var cam = get_viewport().get_camera_3d()
	
	if cam and abs(look_y) > 0.1:
		# PORTAL 2 STYLE: Stick Forward (-1.0) -> Look Down (+X)
		# We subtract the negative value to get a positive tilt
		var target_rotation = cam.rotation.x - (look_y * look_sensitivity)
		
		# Clamp so you don't flip
		cam.rotation.x = clamp(target_rotation, -1.4, 1.4)
