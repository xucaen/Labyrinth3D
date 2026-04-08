extends Node
var target_spawn_name: String = "SpawnPoint"
var current_level_id: int = 1 # Start ID
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func get_next_level_path() -> String:
	if current_level_id >= 11:
		print("Game Over! Returning to start.")
		current_level_id = 1 # Reset to start
	else:
		# Increment the ID
		current_level_id += 1
	
	# Rebuild the string: "res://Level_2113.tscn"
	return "MazeLevel" + str(current_level_id)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func spawn_player(current_scene: Node):
	if target_spawn_name == "":
		return # No spawn target set, stay at default position

	# Find the Marker3D in the current level
	var spawn_node = current_scene.find_child(target_spawn_name, true, false)
	# Find the Player node in the scene
	var player_node = current_scene.find_child("Player", true, false)

	if spawn_node and player_node:
		# Move player to the marker's global position and rotation
		player_node.global_transform = spawn_node.global_transform
		print("Player spawned at: ", target_spawn_name)
		# Clear the target so it doesn't loop next time unless set again
		target_spawn_name = ""
	else:
		if !spawn_node:
			print("Warning: Could not find Marker3D named: ", target_spawn_name)
		if !player_node:
			print("Warning: Could not find node named 'Player' in this scene.")
