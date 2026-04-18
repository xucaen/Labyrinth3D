#spaceFighter.gd
extends CharacterBody3D

@export_group("Flight Stats")
@export var max_thrust: float = 80.0
@export var acceleration: float = 5.0
@export var friction_drag: float = 2.0
@export var gravity: float = 9.8

@export_group("Rotation")
@export var turn_speed: float = 2.5
@export var pitch_speed: float = 2.0

# --- INTERACTION VARIABLES ---
var current_thrust_power: float = 0.0
var is_occupied: bool = false
var player_ref: CharacterBody3D = null
var can_enter: bool = false

# --- NODES ---

@onready var ship_camera: Camera3D = $Fusalage/FighterCam


func _physics_process(delta: float) -> void:
	if not is_occupied:
		if not is_on_floor():
			velocity.y -= gravity * delta
			move_and_slide()
		_check_for_entry()
		return

	_handle_flight_logic(delta)
	_check_for_exit()
	move_and_slide()

func _handle_flight_logic(delta: float) -> void:
	# --- INPUT ---
	var throttle_input = -Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) # Forward/Back

	var pitch_input = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)   # Up/Down
	var yaw_input   = -Input.get_joy_axis(0, JOY_AXIS_LEFT_X)    # Left/Right
	var left_roll = Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	var right_roll = Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
	var roll_input = float(left_roll) - float(right_roll)
	print("roll_input is ",roll_input)

	# --- DEADZONE ---
	var deadzone = 0.15
	if abs(pitch_input) < deadzone: pitch_input = 0.0
	if abs(yaw_input) < deadzone: yaw_input = 0.0
	if abs(throttle_input) < deadzone: throttle_input = 0.0

	# --- SETTINGS ---
	var turn_speed = 2.5        # rotation speed
	var roll_speed = 2.0
	var acceleration = 100.0
	var max_speed = 3000.0
	var drag = 5.0
	var max_roll = deg_to_rad(30.0)
	var max_pitch = deg_to_rad(180.0)
	roll_input = clamp(roll_input, -max_roll, max_roll)
	pitch_input = clamp(pitch_input, -max_pitch, max_pitch)

	# --- ROTATION ---
	rotate_object_local(Vector3.RIGHT, pitch_input * turn_speed * delta) # pitch
	rotate_y(yaw_input * turn_speed * delta)                             # yaw
	rotate_object_local(Vector3.BACK, roll_input * roll_speed * delta)   # roll

	# --- FORWARD MOVEMENT ---
	var forward_dir = -transform.basis.z
	
	velocity += forward_dir * throttle_input * acceleration * delta

	# --- DRAG (prevents infinite drifting) ---
	velocity = velocity.lerp(Vector3.ZERO, drag * delta)

	# --- CLAMP SPEED ---
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# --- MOVE ---
	move_and_slide()


func _check_for_entry() -> void:
	if can_enter and Input.is_action_just_pressed("ui_accept"):
		enter_ship()

func _check_for_exit() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		exit_ship()

func enter_ship() -> void:
	is_occupied = true
	player_ref.visible = false
	player_ref.process_mode = Node.PROCESS_MODE_DISABLED
	ship_camera.make_current()

func exit_ship() -> void:
	is_occupied = false
	player_ref.visible = true
	player_ref.process_mode = Node.PROCESS_MODE_INHERIT
	
	# THE FIX: Tell the ship to look for the player again
	$Area3D.monitoring = false
	$Area3D.monitoring = true
	
	player_ref.global_position = global_position + (global_transform.basis.x * -3.0)
	
	var p_cam = player_ref.find_child("Camera3D")
	if p_cam:
		p_cam.make_current()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_ref = body as CharacterBody3D
		can_enter = true
		print("Press Space Bar to Enter") # Added print back

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player_ref:
		can_enter = false
