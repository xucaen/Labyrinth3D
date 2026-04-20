#res://scripts/npc_area_0.gd
extends Area3D

@export var drone_scene: PackedScene = preload("res://NPCs/enemy_droneX.tscn")
@export var fleet_size: int = 100
@export var spacing: float = 5.0 
@export var spawn_delay: float = 0.5 # Time in seconds between each drone (adjust as needed)

@onready var home_marker: Marker3D = $Marker3D

var fleet: Array = []
var spawn_index: int = 0
var is_spawning: bool = false
var spawn_timer: Timer
var body_name: String = "SpaceFighter"


func _ready() -> void:

	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)
	
	# Set up the timer for staggered spawning
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_delay
	spawn_timer.timeout.connect(_spawn_next_drone)
	add_child(spawn_timer)

func _on_player_entered(body):
	if body.name == body_name:
		print("Player has entered the drone zone!!!")
		is_spawning = true
		spawn_timer.start()
		_spawn_next_drone()

		

func _spawn_next_drone():
	if spawn_index >= fleet_size:
		spawn_timer.stop()
		is_spawning = false
		return


	var drone = drone_scene.instantiate()
	get_parent().add_child(drone)
	
	# Initialize drone data
	drone.global_position = home_marker.global_position
	drone.current_state = drone.State.PATROL
	
	
	fleet.append(drone)
	spawn_index += 1

func _on_player_exited(body):
	if body.name == body_name:
		# 1. Stop the staggered spawn timer if it's still running
		spawn_timer.stop()
		is_spawning = false
		spawn_index = 0


		# 2. Tell all drones to delete themselves
		for drone in fleet:
			if is_instance_valid(drone):
				drone.queue_free() # Removes the drone from the game entirely

		# 3. Clear the list so we don't have "ghost" references
		fleet.clear()
