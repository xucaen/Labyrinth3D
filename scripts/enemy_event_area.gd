#res://scripts/enemy_event_area.gd
extends Area3D

func _ready() -> void:
	# Connect the signals to detect the player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	# Check if the thing entering the area is the Player
	if body.name == "Player":
		# Get the parent (EnemyDrone) and set its target/state
		get_parent().target = body
		get_parent().current_state = get_parent().State.ATTACK
	
	if body.name == "EnemyDrone":
		get_parent().target = body
		get_parent().current_state = get_parent().State.EVADE

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		# Tell the drone to return to formation
		get_parent().target = null
		get_parent().current_state = get_parent().State.RETURNING
	
	if body.name == "EnemyDrone":
		get_parent().target = body
		get_parent().current_state = get_parent().State.SEEKING
