extends Node3D
@onready var level_container = $LevelContainer
@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This is the "Auto-Start" line you are missing!
	# It tells the game to load the first level as soon as you press F5.
	transition_to_level("MazeLevel1")


# Add 'level_name' inside the parentheses to accept the argument
func transition_to_level(level_name: String):
	# 1. Access the level node that already exists under level_container
	var next_level_node = get_node_or_null(level_name)
	print("DEBUG(transition_to_level)::::",next_level_node)
	if next_level_node:
		# 2. Find the SpawnPoint specifically inside THIS level node
		var spawn_node = next_level_node.find_child("SpawnPoint", true, false)
		
		if spawn_node:
			# 3. Teleport the player
			player.global_position = spawn_node.global_position
			player.global_rotation = spawn_node.global_rotation
			
			# 4. Reset movement
			if player is CharacterBody3D:
				player.velocity = Vector3.ZERO
				
			print("Teleported player to: ", level_name)
		else:
			push_error("Error: SpawnPoint marker missing in " + level_name)
	else:
		push_error("Error: Could not find node " + level_name + " in level_container")
