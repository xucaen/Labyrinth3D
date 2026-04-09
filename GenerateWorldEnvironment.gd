@tool
extends Node

@export var generate_krell_environment: bool = false : set = _generate


func _generate(value: bool) -> void:
	if not value:
		return
	
	# Reset toggle so you can click again
	generate_krell_environment = false

	print("GENERATING...")

	# ✅ THIS is the correct way in editor
	var scene = get_tree().edited_scene_root
	
	if scene == null:
		push_error("No scene root found!")
		return

	var env_node: WorldEnvironment = null
	
	# Find existing WorldEnvironment
	for child in scene.get_children():
		if child is WorldEnvironment:
			env_node = child
			break
	
	# Create if missing
	if env_node == null:
		env_node = WorldEnvironment.new()
		env_node.name = "ScifiWorldEnvironment"
		scene.add_child(env_node)
		env_node.owner = scene
	
	var env := Environment.new()
	env_node.environment = env

	# Background
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.05)

	# Ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.15, 0.2)
	env.ambient_light_energy = 0.3

	# Fog
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.05
	env.volumetric_fog_albedo = Color(0.2, 0.6, 0.8)
	env.volumetric_fog_emission = Color(0.1, 0.3, 0.5)
	env.volumetric_fog_emission_energy = 0.5

	# Glow
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.2
	env.glow_bloom = 0.7
	env.glow_hdr_threshold = 0.6

	print("Scifi WorldEnvironment generated.")
