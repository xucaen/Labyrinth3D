extends CharacterBody3D

@export var speed: float = 10.0
@export var look_sensitivity: float = 0.05
@export var jump_velocity: float = 4.5
@export var jetpack_thrust: float = 15.0
@export var max_fall_speed: float = 12.0
@export var max_flight_speed: float = 6.0
@export var gravity: float = 9.8

var is_occupied: bool = false
var player_ref: CharacterBody3D = null
var can_enter: bool = false

@onready var propellerPack_camera: Camera3D = $wearablePack/Camera3D

func _physics_process(delta: float) -> void:
	# 1. HANDLE INPUT/LOGIC BASED ON STATE
	if not is_occupied:
		_check_for_entry()
		# Zero out horizontal velocity when empty so it doesn't slide forever
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	else:
		_handle_movement(delta)
		_handle_look_left_right(delta)
		_handle_look_up_down(delta)
		_check_for_exit()

	# 2. APPLY GRAVITY (ALWAYS)
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 3. TERMINAL VELOCITY CLAMP
	velocity.y = clamp(velocity.y, -max_fall_speed, max_flight_speed)

	# 4. FINAL EXECUTION
	move_and_slide()

func _handle_movement(delta: float) -> void:
	var input_vector := Vector3.ZERO
	input_vector.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	input_vector.z = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

	var trigger_val = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var is_trigger_pressed = trigger_val > 0.2 

	# JUMP & JETPACK
	var motor: Node3D = $wearablePack/PropellorMotor	
	if is_on_floor():
		motor.rotation.y = 0
		if is_trigger_pressed:
			velocity.y = jump_velocity
	else:
		if is_trigger_pressed:
			velocity.y += jetpack_thrust * delta
			motor.rotation.y += jetpack_thrust * delta
		else:
			motor.rotation.y -= jetpack_thrust * delta

	# HORIZONTAL MOVEMENT
	var move_dir = (global_transform.basis * Vector3(input_vector.x, 0, input_vector.z)).normalized()
	if input_vector.length() > 0.1:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

# --- HELPER FUNCTIONS ---

func _handle_look_left_right(delta: float) -> void:
	var look_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(look_x) > 0.1:
		rotation.y -= look_x * look_sensitivity

func _handle_look_up_down(delta: float) -> void:
	var look_y := -Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var cam = propellerPack_camera # Use the onready ref
	if cam and abs(look_y) > 0.1:
		cam.rotation.x = clamp(cam.rotation.x - (look_y * look_sensitivity), -1.4, 1.4)

func _check_for_entry() -> void:
	if can_enter and Input.is_action_just_pressed("ui_accept"):
		enter_propellerPack()

func _check_for_exit() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		exit_propellerPack()

func enter_propellerPack() -> void:
	is_occupied = true
	player_ref.visible = false
	player_ref.process_mode = Node.PROCESS_MODE_DISABLED
	propellerPack_camera.make_current()

func exit_propellerPack() -> void:
	is_occupied = false
	player_ref.visible = true
	player_ref.process_mode = Node.PROCESS_MODE_INHERIT
	
	$Area3D.monitoring = false
	$Area3D.monitoring = true
	
	player_ref.global_position = global_position + (global_transform.basis.x * -3.0)
	var p_cam = player_ref.find_child("Camera3D")
	if p_cam: p_cam.make_current()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_ref = body as CharacterBody3D
		can_enter = true
		print("Press Space Bar to Enter")

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player_ref:
		can_enter = false
