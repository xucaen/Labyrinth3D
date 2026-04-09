@tool
extends EditorScript

func _run() -> void:
	var scene_root = Node3D.new()
	scene_root.name = "RacetrackScene"
	
	create_track_segment(scene_root, "MainTrack", Vector3.ZERO, 0)
	create_track_segment(scene_root, "AltTrack", Vector3.ZERO, 90)
	
	var packed_scene := PackedScene.new()
	packed_scene.pack(scene_root)
	ResourceSaver.save(packed_scene, "res://race_track.tscn")
	get_editor_interface().get_resource_filesystem().scan()
	print("Tracks generated and glued!")

func create_track_segment(root: Node3D, track_name: String, pos: Vector3, rot_y_deg: float) -> void:
	# --- Path ---
	var track_path := Path3D.new()
	track_path.name = track_name
	
	var curve := Curve3D.new()
	curve.add_point(Vector3(0, 0, 0), Vector3(0, 0, 500), Vector3(0, 0, -500))
	curve.add_point(Vector3(200, 100, -200), Vector3(-100, 0, 0), Vector3(100, 0, 0))
	curve.add_point(Vector3(400, 0, 0), Vector3(0, 0, -100), Vector3(0, 0, 100))
	curve.add_point(Vector3(200, -50, 200), Vector3(100, 0, 0), Vector3(-100, 0, 0))
	curve.closed = true
	
	track_path.curve = curve
	track_path.position = pos
	track_path.rotation_degrees.y = rot_y_deg
	
	root.add_child(track_path)
	track_path.owner = root
	
	# --- Mesh (sibling, not child) ---
	var road_mesh := CSGPolygon3D.new()
	road_mesh.name = track_name + "_Mesh"
	
	road_mesh.polygon = PackedVector2Array([
		Vector2(-5, -1),
		Vector2(5, -1),
		Vector2(5, 1),
		Vector2(-5, 1)
	])

	root.add_child(road_mesh)
	road_mesh.owner = root
	
	# --- Path setup (NO get_path call) ---
	road_mesh.mode = CSGPolygon3D.MODE_PATH
	
	# Relative path from mesh → sibling path
	road_mesh.path_node = NodePath("../" + track_name)
	
	road_mesh.path_interval = 0.5
	road_mesh.path_joined = true
	road_mesh.path_continuous_u = true
	road_mesh.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH

	road_mesh.use_collision = true
