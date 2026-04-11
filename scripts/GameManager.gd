#GameManager.gd
extends Node

var target_spawn_name: String = "SpawnPoint"
var current_level_id: int = 0 

func _ready() -> void:
	# Wait for the scene to be ready so find_child works correctly
	await get_tree().process_frame
	spawn_player(get_tree().current_scene)

func get_next_level_path() -> String:
	var next_id = current_level_id + 1
	var next_section_name = "MazeSection_" + str(next_id)
	
	# Check if the NEXT section actually exists in the scene
	var root = get_tree().current_scene
	var next_node = root.find_child(next_section_name, true, false)
	
	if next_node:
		current_level_id = next_id
		print("Next maze found: ", next_section_name)
	else:
		current_level_id = 0
		print("No more mazes. Returning to MazeSection_0")
	
	return "MazeSection_" + str(current_level_id)

func spawn_player(current_scene: Node):
	var section_name = "MazeSection_" + str(current_level_id)
	var section_node = current_scene.find_child(section_name, true, false)
	var player_node = current_scene.find_child("Player", true, false)

	if not section_node:
		print("ERROR: Cannot find ", section_name, " in ", current_scene.name)
		return
		
	if not player_node:
		print("ERROR: Cannot find Player in ", current_scene.name)
		return

	var spawn_node = section_node.find_child(target_spawn_name, true, false)
	print(spawn_node.get_path())
	if spawn_node:
		player_node.velocity = Vector3.ZERO
		player_node.global_position = spawn_node.global_position + Vector3.UP * 0.5


		print("Success! Player moved to ", section_name)
	else:
		print("ERROR: Section found, but no ", target_spawn_name, " inside it.")