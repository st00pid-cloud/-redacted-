extends CharacterBody3D

@onready var ray = $HeadPivot/Camera3D/RayCast3D

const SPEED = 8.5
const JUMP_VELOCITY = 7.5
const STEP_HEIGHT = 8 # Max height the player can step up (tweak to match your stairs)
const STEP_CHECK_DIST = 15 # How far ahead to check for steps


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		_try_step_up(delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "backward", "forward")
	
	# Use global_transform.basis so it follows the node's actual rotation
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	
	# Zero out Y so movement stays on the horizontal plane
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var direction = (right * input_dir.x + forward * input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if event.is_action_pressed("interact"):
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider.is_in_group("interactable"):
				collider.interact() 
				
func _try_step_up(delta: float) -> bool:
	var move_dir = Vector3(velocity.x, 0, velocity.z).normalized()
	if move_dir.length() < 0.1:
		return false

	var space_state = get_world_3d().direct_space_state

	# Cast forward at step height to make sure there's open space
	var step_top = global_position + Vector3.UP * STEP_HEIGHT
	var forward_check = PhysicsRayQueryParameters3D.create(
		step_top,
		step_top + move_dir * STEP_CHECK_DIST,
		0xFFFFFFFF,
		[get_rid()]
	)
	var forward_result = space_state.intersect_ray(forward_check)

	# If something is blocking at step height, it's a wall, not a step
	if forward_result:
		return false

	# Cast downward from the forward position to find the step surface
	var cast_from = step_top + move_dir * STEP_CHECK_DIST
	var cast_to = cast_from + Vector3.DOWN * (STEP_HEIGHT + 0.1)
	var down_check = PhysicsRayQueryParameters3D.create(
		cast_from,
		cast_to,
		0xFFFFFFFF,
		[get_rid()]
	)
	var down_result = space_state.intersect_ray(down_check)

	if down_result:
		var step_y = down_result.position.y
		var height_diff = step_y - global_position.y

		# Only step up if the surface is above us but within step height
		if height_diff > 0.05 and height_diff <= STEP_HEIGHT:
			global_position.y = step_y
			return true

	return false
