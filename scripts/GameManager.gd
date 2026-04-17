# GameManager.gd
extends Node
var target_spawn_name: String = "SpawnPoint"
var current_level_id: int = 0 


func _ready() -> void:
	# Wait one frame to ensure all nodes from the .tscn are initialized
	await get_tree().process_frame
	spawn_at_markers()

#Spawn player and vehicles
func spawn_at_markers():
	var root = get_tree().current_scene
	
	# Mapping the Node Name to its corresponding Marker Name
	var spawn_map = {
		"Player": "PlayerSpawn",
		"Cycle": "CycleSpawn",
		"SpaceFighter": "SpaceFighterSpawn",
		"PropellerPack": "PropPackSpawn"
	}

	for entity_name in spawn_map:
		var entity = root.find_child(entity_name, true, false)
		var marker = root.find_child(spawn_map[entity_name], true, false)
		
		if entity and marker:
			# Move entity to the marker's roof position
			entity.global_position = marker.global_position
			
			# Reset velocity for the player to prevent physics glitches on spawn
			if entity_name == "Player" and entity is CharacterBody3D:
				entity.velocity = Vector3.ZERO 
			
			print("Successfully spawned ", entity_name, " at roof.")
		else:
			push_warning("Could not find ", entity_name, " or ", spawn_map[entity_name])





#when player enters the ExitArea of any maze, get it's level number and go to the next one
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
