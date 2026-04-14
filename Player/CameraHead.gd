extends Camera3D

@export var sensitivity := 0.002

@onready var player: CharacterBody3D = get_parent().get_parent()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * sensitivity)
		
		var new_rotation_x = rotation.x - event.relative.y * sensitivity
		rotation.x = clamp(new_rotation_x, deg_to_rad(-80), deg_to_rad(80))
		rotation.z = 0
