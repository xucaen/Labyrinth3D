#level_transition.gd
extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body):
	if body.name == "Player":
		# 1. Ask GameManager for the next path
		var next_path = GameManager.get_next_level_path()
		print("DEBUG:: Maze Name:",next_path)
		# 2. Tell MainWorldNode to swap
		var main_node = get_node("/root/MainWorldNode")
		if main_node:
			main_node.transition_to_level(next_path)
