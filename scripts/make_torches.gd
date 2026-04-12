@tool
extends EditorScript

func _run():
	generate_torches()

func generate_torches():
	# Your specific updated shape list
	var shape_configs = {
		"Cylinder": {"mesh": CylinderMesh.new(), "color": Color(0.0, 1.0, 1.0, 1.0)},   # Cyan
		"Torus":    {"mesh": TorusMesh.new(),    "color": Color(0.0, 1.0, 0.0, 1.0)},   # Green
		"Tube":     {"mesh": TubeTrailMesh.new(),"color": Color(1.0, 0.0, 0.0, 1.0)},   # Red
		"Box":      {"mesh": BoxMesh.new(),      "color": Color(1.0, 1.0, 0.0, 1.0)},   # Yellow
		"Capsule":  {"mesh": CapsuleMesh.new(),  "color": Color(1.0, 0.0, 1.0, 1.0)}    # Pink
	}
	
	# The pale yellow cast color from your original files
	var base_yellow = Color(0.9905583, 1, 0.75342906, 1) 
	
	# Correct path for flicker.gd
	var flicker_path = "res://Scripts/flicker.gd"
	var flicker_script = load(flicker_path) if FileAccess.file_exists(flicker_path) else null

	for shape_name in shape_configs:
		var root = Node3D.new()
		root.name = "ScifiTorch" + shape_name
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		root.add_child(mesh_instance)
		mesh_instance.owner = root 
		
		# Material Setup using the Color(r, g, b, a) format
		var material = StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = shape_configs[shape_name]["color"]
		material.emission_energy_multiplier = 2.17 # Match your Prism torch
		
		var mesh = shape_configs[shape_name]["mesh"]
		mesh.material = material
		mesh_instance.mesh = mesh
		
		# Light Setup
		var light = OmniLight3D.new()
		light.name = "OmniLight3D"
		light.light_color = base_yellow
		
		# Attach flicker script
		if flicker_script:
			light.set_script(flicker_script)
			
		mesh_instance.add_child(light)
		light.owner = root
		
		# Save to File
		var scene = PackedScene.new()
		scene.pack(root)
		var path = "res://scifi_torch_" + shape_name.to_lower() + ".tscn"
		
		var error = ResourceSaver.save(scene, path)
		if error == OK:
			print("Successfully generated: ", path)
		else:
			print("Error saving ", path, ": ", error)
