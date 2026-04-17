#level_transition.gd (attached to Player)
extends Area3D

@export var my_section_id: int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body):
	if body.name == "Player":
		# 1. Logic to increment the internal ID
		print("On Body Enter fired!!")
		print("Leaving MazeSection_", my_section_id)
		GameManager.current_level_id = my_section_id

		GameManager.get_next_level_path()
		
		# 2. Teleport the player within the same scene
		# 'owner' is the root of the Helix_Level_0.tscn
		GameManager.spawn_player(get_tree().current_scene)
