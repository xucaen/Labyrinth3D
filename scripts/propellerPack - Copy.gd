extends CharacterBody3D

@export var speed: float = 10.0
@export var look_sensitivity: float = 0.05
@export var jump_velocity: float = 4.5
@export var jetpack_thrust: float = 15.0      # How much force the motor adds
@export var max_fall_speed: float = 12.0     # Terminal velocity going down
@export var max_flight_speed: float = 6.0    # Cap for going UP (slower than falling)
@export var jetpack_activation_delay: float = 0.2 # Small buffer after jump

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
	input_vector.x = Input.get_joy_axis(0, 0)
	input_vector.z = Input.get_joy_axis(0, 1)

	# --- INPUT CHANGE HERE ---
	# We check the Left Trigger axis (JOY_AXIS_LEFT_TRIGGER is index 4)
	# We use a threshold (0.2) to see if it's being pressed down
	var trigger_val = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var is_trigger_pressed = trigger_val > 0.2 

	# 1. JUMP & JETPACK LOGIC
	if is_on_floor():
		if is_trigger_pressed:
			velocity.y = jump_velocity
	else:
		if is_trigger_pressed:
			velocity.y += jetpack_thrust * delta
			
			if velocity.y > max_flight_speed:
				velocity.y = max_flight_speed
		
		# 2. GRAVITY & TERMINAL VELOCITY
		velocity.y -= 9.8 * delta
		
		if velocity.y < -max_fall_speed:
			velocity.y = -max_fall_speed

	# 3. HORIZONTAL MOVEMENT
	if input_vector.length() > 0.1:
		var move_dir = (global_transform.basis * Vector3(input_vector.x, 0, input_vector.z)).normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

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
