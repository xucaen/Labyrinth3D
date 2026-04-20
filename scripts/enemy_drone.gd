#res://scripts/enemy_drone.gd
extends CharacterBody3D

@export_group("AI Stats")
@export var speed: float = 60.0
@export var rotation_speed: float = 4.0
@export var attack_range: float = 80.0
@export var stop_distance: float = 15.0

@onready var muzzle: Marker3D = $BulletSpawn

# --- AI LOGIC ---
enum State { ATTACK, PATROL }
var current_state: State = State.PATROL

var target: Node3D = null
var home_point: Vector3 = Vector3.ZERO
var patrol_angle: float = 0.0

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	
	home_point = global_position
	patrol_angle = randf() * TAU # Randomize start phase so they don't sync up

func _physics_process(delta: float) -> void:
	match current_state:
		State.ATTACK:
			_process_attack(delta)
		State.PATROL:
			_process_patrol(delta)

	move_and_slide()

# --- STATE BEHAVIORS ---

func _on_body_entered(body):
	if body.name == "Player":
		target = body
		current_state = State.ATTACK

func _on_body_exited(body):
	if body == target:
		target = null
		current_state = State.PATROL
		
func _process_attack(delta: float):
	if not is_instance_valid(target):
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(target.global_position)
	
	# FIX 2: Disengage logic if player escapes
	if dist > attack_range * 2.0:
		target = null
		current_state = State.PATROL
		return

	_smooth_look_at(target.global_position, delta)
	var dir_to_target = (target.global_position - global_position).normalized()
	
	# FIX 3: Steering/Inertia (Ship feel)
	var desired_velocity = Vector3.ZERO
	if dist > stop_distance:
		desired_velocity = dir_to_target * speed
	
	velocity = velocity.lerp(desired_velocity, 5.0 * delta)
	
	# Fire Logic check
	if dist < attack_range:
		var forward = -global_transform.basis.z
		if forward.dot(dir_to_target) > 0.85:
			# _attempt_fire()
			pass

func _process_patrol(delta: float):
	# FIX 1: Local Wander/Orbit
	patrol_angle += delta * 0.8 # Rotation speed around home
	
	var offset = Vector3(cos(patrol_angle), 0, sin(patrol_angle)) * 12.0
	var target_pos = home_point + offset

	_smooth_look_at(target_pos, delta)
	
	# Move toward the patrol point with a bit of "drift"
	var dir = (target_pos - global_position).normalized()
	var desired_velocity = dir * (speed * 0.4) 
	velocity = velocity.lerp(desired_velocity, 5.0 * delta)

# --- HELPER FUNCTIONS ---

func _smooth_look_at(target_pos: Vector3, delta: float):
	if global_position.distance_squared_to(target_pos) < 0.1:
		return
	var look_transform = global_transform.looking_at(target_pos, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(look_transform.basis, rotation_speed * delta)
