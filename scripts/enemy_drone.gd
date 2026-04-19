#res://scripts/enemy_drone.gd
extends CharacterBody3D

@export_group("AI Stats")
@export var speed: float = 80.0
@export var acceleration: float = 10.0
@export var rotation_speed: float = 3.0
@export var attack_range: float = 100.0
@export var stop_distance: float = 1.0

@export_group("Nodes")
@onready var muzzle: Marker3D = $BulletSpawn

# --- WEAPONS ---
const BULLET_SCENE = preload("res://assets/Bullet_2.tscn")
const POOL_SIZE = 1 
var bullet_pool: Array[Node3D] = []
var pool_index: int = 0
var fire_cooldown: float = 0.8 
var time_since_last_shot: float = 0.0
var is_overheated: bool = false

# --- AI LOGIC ---
enum State { FORMATION, ATTACK, RETURNING, EVADE, SEEKING }
var current_state: State = State.FORMATION
var formation_offset: Vector3 = Vector3.ZERO

var target: Node3D = null      # Usually the Player
var home_node: Marker3D = null # The "Slot" in the Area3D zone
var radar_tick: float = 0.0    # For optimization
var radar_delay: float = 0.5   # Scan every 0.5 seconds

func _ready() -> void:
	# Initialize Bullet Pool
	for i in range(POOL_SIZE):
		var b = BULLET_SCENE.instantiate()
		b.visible = false
		b.set_process(false)
		get_tree().root.add_child.call_deferred(b)
		bullet_pool.append(b)

func _physics_process(delta: float) -> void:
	time_since_last_shot += delta
	
	match current_state:
		State.FORMATION:
			_process_formation(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RETURNING:
			_process_returning(delta)
		State.EVADE:
			_process_evading(delta)
		State.SEEKING:
			_seeking_player(delta)

	move_and_slide()

# --- STATE BEHAVIORS ---

func _process_formation(delta: float):
	if not home_node: return

	# 1. Calculate the exact slot position
	var target_pos = home_node.global_transform * formation_offset

	# 2. Directly interpolate velocity toward the slot instead of using _fly_towards
	# This prevents them from just flying "forward" past the point
	var direction = global_position.direction_to(target_pos)
	var distance = global_position.distance_to(target_pos)

	# Match the speed of the formation, plus extra if we are far away
	var target_velocity = direction * speed
	if distance < 1.0:
		target_velocity = Vector3.ZERO # Stop jittering when arrived

	velocity = velocity.move_toward(target_velocity, acceleration * delta)

	# 3. Rotate to match the leader's orientation
	var target_basis = home_node.global_transform.basis
	global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta)

	#TODO: they should follow a patrol path
	


func _process_attack(delta: float):
	if not is_instance_valid(target):
		current_state = State.RETURNING
		return

	var dist = global_position.distance_to(target.global_position)
	
	# Look at Player
	_smooth_look_at(target.global_position, delta)
	
	# Maintain distance
	if dist > stop_distance:
		velocity += -transform.basis.z * acceleration * delta
	
	# Fire if in range and lined up
	if dist < attack_range:
		var forward = -global_transform.basis.z
		var to_target = (target.global_position - global_position).normalized()
		if forward.dot(to_target) > 0.9: # Only fire if roughly facing player
			_attempt_fire()

func _process_returning(delta: float):
	if not home_node: return
	var dist = global_position.distance_to(home_node.global_position)
	_fly_towards(home_node.global_position, delta)
	
	if dist < 2.0:
		current_state = State.FORMATION


func _process_evading(delta: float):
	# 'target' here is likely the other drone detected by the Area3D
	if not is_instance_valid(target):
		current_state = State.RETURNING
		return

	var dir_away = target.global_position.direction_to(global_position)
	# Move toward a point away from the neighbor to maintain personal space
	var escape_point = global_position + dir_away * 5.0
	_fly_towards(escape_point, delta)

	# If we have enough distance from the neighbor, head back to formation
	if global_position.distance_to(target.global_position) > 15.0:
		current_state = State.SEEKING
		

func _seeking_player(delta: float):
	radar_tick += delta

	# Only update target position every 'radar_delay' seconds for performance
	if radar_tick >= radar_delay:
		radar_tick = 0.0
		# Search for the Player node in the scene tree
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			target = player

	if is_instance_valid(target):
		_fly_towards(target.global_position, delta)
		# If we get close enough for the Area3D to take over, or close enough to shoot
		if global_position.distance_to(target.global_position) < attack_range:
			current_state = State.ATTACK
	else:
		# If player is truly lost, go home
		current_state = State.RETURNING



# --- HELPER FUNCTIONS ---

func _fly_towards(target_pos: Vector3, delta: float):
	_smooth_look_at(target_pos, delta)
	var dist = global_position.distance_to(target_pos)
	var desired_velocity = -transform.basis.z * speed
	
	# Slow down as we reach the "slot"
	if dist < 5.0:
		desired_velocity *= (dist / 5.0)
		
	velocity = velocity.lerp(desired_velocity, delta * 2.0)

func _fly_away_from(target_pos: Vector3, delta: float):
	_smooth_look_at(target_pos, delta)
	var dist = global_position.distance_to(target_pos)
	var desired_velocity = -transform.basis.z / speed
	
	# Slow down as we reach the "slot"
	if dist < 50.0:
		desired_velocity *= (dist / 50.0)
		
	velocity = velocity.lerp(desired_velocity, delta * 2.0)


func _smooth_look_at(target_pos: Vector3, delta: float):
	if global_position.is_equal_approx(target_pos):
		return
	var look_transform = global_transform.looking_at(target_pos, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(look_transform.basis, rotation_speed * delta)

# --- WEAPONS LOGIC ---

func _attempt_fire():
	if time_since_last_shot >= fire_cooldown and not is_overheated:
		fire_weapons()
		time_since_last_shot = 0.0

func fire_weapons() -> void:
	var shot = attempt_shot(muzzle)
	if not shot:
		is_overheated = true
		await get_tree().create_timer(1.5).timeout
		is_overheated = false

func attempt_shot(muz: Marker3D) -> bool:
	for i in range(POOL_SIZE):
		var b = bullet_pool[pool_index]
		pool_index = (pool_index + 1) % POOL_SIZE
		if not b.is_processing():
			b.global_transform = muz.global_transform
			b.visible = true
			b.set_process(true)
			if b.has_method("reset_bullet"): b.reset_bullet()
			return true
	return false
