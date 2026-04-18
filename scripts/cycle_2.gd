extends VehicleBody3D

# --- EXPORTS ---
@export var bike_mass: float = 180.0
@export var engine_power: float = 1500.0
@export var brake_force: float = 60.0
@export var steer_speed: float = 1.5
@export var steer_limit: float = 0.4
@export var balance_strength: float = 25.0

# --- INTERNAL VARS ---
var is_occupied: bool = false
var player_ref: CharacterBody3D = null
var can_enter: bool = false

# --- VISUAL / CAMERA ---
@onready var bike_camera: Camera3D = $Camera3D
@onready var front_assembly = $MeshBody/FrontSuspension


func _ready():
	mass = bike_mass
	
	# Stronger upright behavior via center of mass shift
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.7, 0)


func _physics_process(delta: float) -> void:
	_stabilize(delta)

	if not is_occupied:
		_check_for_entry()
		engine_force = 0
		brake = 10.0 # handbrake when empty
		return

	_handle_movement(delta)
	_check_for_exit()


# --- STABILITY (UPDATED VERSION) ---
func _stabilize(delta: float) -> void:
	# Find tilt direction relative to world up
	var tilt = global_transform.basis.y.cross(Vector3.UP)

	# Smooth out angular chaos (prevents flipping / jitter)
	angular_velocity = angular_velocity.lerp(Vector3.ZERO, delta * 10.0)

	# Apply corrective torque (main upright force)
	apply_torque(tilt * balance_strength * mass * delta)


# --- MOVEMENT (UPDATED VERSION) ---
func _handle_movement(delta: float) -> void:
	var steer_input = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var throttle = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	var braking = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)

	# --- SPEED SENSITIVITY STEERING ---
	var speed_factor = clamp(1.0 - (linear_velocity.length() / 40.0), 0.4, 1.0)
	var target_steering = steer_input * steer_limit * speed_factor

	steering = lerp(steering, target_steering, steer_speed * delta)

	# --- VISUAL FRONT END TURN ---
	if front_assembly:
		front_assembly.rotation.y = steering

	# --- ENGINE ---
	engine_force = throttle * engine_power

	# --- BRAKING ---
	if braking > 0.1:
		brake = braking * brake_force
	else:
		brake = 0.0


# --- ENTER / EXIT SYSTEM (UNCHANGED) ---
func _check_for_entry() -> void:
	if can_enter and Input.is_action_just_pressed("ui_accept"):
		enter_bike()


func _check_for_exit() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		exit_bike()


func enter_bike() -> void:
	is_occupied = true
	if player_ref:
		player_ref.visible = false
		player_ref.process_mode = Node.PROCESS_MODE_DISABLED
	bike_camera.make_current()


func exit_bike() -> void:
	is_occupied = false
	if player_ref:
		player_ref.visible = true
		player_ref.process_mode = Node.PROCESS_MODE_INHERIT
		player_ref.global_position = global_position + (global_transform.basis.x * -3.0)

		var p_cam = player_ref.find_child("Camera3D")
		if p_cam:
			p_cam.make_current()

	$Area3D.monitoring = false
	$Area3D.monitoring = true


# --- AREA DETECTION ---
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_ref = body as CharacterBody3D
		can_enter = true
		print("Press Space to Ride")


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player_ref:
		can_enter = false
