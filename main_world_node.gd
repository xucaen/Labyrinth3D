extends Node3D
@onready var level_container = $LevelContainer
@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This is the "Auto-Start" line you are missing!
	# It tells the game to load the first level as soon as you press F5.
	transition_to_level("res://Level_2112.tscn")


func transition_to_level(level_path: String):
	# 1. Clear the old level
	for child in level_container.get_children():
		child.queue_free()
	
	# 2. Wait for the old level to be completely gone
	await get_tree().process_frame
	
	# 3. Load and instance the new level
	var next_level_resource = load(level_path)
	var next_level_instance = next_level_resource.instantiate()
	level_container.add_child(next_level_instance)
	
	# 4. CRITICAL: Wait for the new level to "settle"
	# This ensures the SpawnPoint marker actually exists in the 3D world
	await get_tree().process_frame
	
	# 5. Look for the SpawnPoint marker
	# We use find_child with 'true' to search all sub-folders of the level
	var spawn_node = next_level_instance.find_child("SpawnPoint", true, false)
	
	if spawn_node:
		# Use global_position to match the marker exactly
		player.global_position = spawn_node.global_position
		# Match the rotation too (so player faces the right way)
		player.global_rotation = spawn_node.global_rotation
		# Stop all movement so they don't slide through the floor
		player.velocity = Vector3.ZERO
		print("Spawned player at Marker: SpawnPoint")
	else:
		# Safety fallback if you forgot the marker
		player.global_position = Vector3(0, 5, 0)
		player.velocity = Vector3.ZERO
		print("Warning: No SpawnPoint found. Dropping player from height.")
