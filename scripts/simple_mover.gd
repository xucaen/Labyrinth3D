extends Node3D

@export var distance: float = 500.0 # How far it moves up and down
@export var speed: float = 0.5    # How fast it cycles
@export var offset: float = 0.0   # Use this to make different parts move out of sync

var initial_y: float

func _ready():
	# Remember where we started so we move relative to this spot
	if get_parent() is Node3D:
		initial_y = get_parent().global_position.y

func _process(_delta):
	var parent = get_parent() as Node3D
	if parent:
		# The Math: sin() creates a value between -1 and 1.
		# Multiplying by 'distance' makes it move between -distance and +distance.
		var time = Time.get_ticks_msec() * 0.001
		var new_y = initial_y + (sin(time * speed + offset) * distance)
		
		parent.global_position.y = new_y
