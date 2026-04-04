extends Camera3D

@export var sensitivity := 0.002
@onready var player = get_owner() # Ensures it finds the CharacterBody3D root

func _ready():
	# Crucial: Ensure the mouse is captured or _input won't fire correctly
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# 1. Rotate the PLAYER (Horizontal - Y Axis)
		player.rotate_y(-event.relative.x * sensitivity)
		
		# 2. Rotate the CAMERA (Vertical - X Axis)
		# We modify rotation.x directly to bypass parent inheritance issues
		var new_rotation_x = rotation.x - event.relative.y * sensitivity
		rotation.x = clamp(new_rotation_x, deg_to_rad(-80), deg_to_rad(80))
		
		# 3. Orthogonality Check: Ensure Z rotation stays at 0 (prevents tilting)
		rotation.z = 0
