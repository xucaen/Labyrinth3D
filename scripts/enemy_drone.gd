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
var angle: float = 0.0
# --- AI LOGIC ---
enum State { ATTACK, FOLLOW_PATH }
var current_state: State = State.FOLLOW_PATH


var target: Node3D = null      # Usually the Player
var radar_tick: float = 0.0    # For optimization
var radar_delay: float = 0.5   # Scan every 0.5 seconds

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
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
		State.ATTACK:
			_process_attack(delta)
		State.FOLLOW_PATH:
			_follow_path(delta)

	move_and_slide()

# --- STATE BEHAVIORS ---

func _on_body_entered(body):
	if body.name == "Player":
		target = body
		current_state = State.ATTACK

func _on_body_exited(body):
	if body == target:
		target = null
		current_state = State.FOLLOW_PATH
		
func _process_attack(delta: float):
	if not is_instance_valid(target):
		current_state = State.FOLLOW_PATH
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


	

func _follow_path(delta: float):
	angle += delta
	var center = get_parent().global_position + Vector3(randf_range(-20,20), randf_range(-20,20), randf_range(-20,20))
	var target_pos = center + Vector3(cos(angle), 0, sin(angle)).rotated(Vector3.UP, randf()*TAU) * 20.0
	_fly_towards(target_pos, delta)



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
