extends CharacterBody3D

@onready var ray: RayCast3D = $HeadPivot/Camera3D/RayCast3D
@onready var footstep_player: AudioStreamPlayer = $footsteps

const SPEED = 10
const JUMP_VELOCITY = 7.5
const STEP_HEIGHT = 4.5
const STEP_CHECK_DIST = 8

# Footstep timing — one step every this many seconds while moving
const FOOTSTEP_INTERVAL = 0.42
var _footstep_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		_try_step_up(delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "backward", "forward")

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction = (right * input_dir.x + forward * input_dir.y).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		# Tick footstep timer only when moving on floor
		if is_on_floor():
			_footstep_timer -= delta
			if _footstep_timer <= 0.0:
				_footstep_timer = FOOTSTEP_INTERVAL
				_play_footstep()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		_footstep_timer = 0.0 # reset so first step after pause is immediate

	move_and_slide()

func _play_footstep() -> void:
	if footstep_player and not footstep_player.playing:
		# Randomize pitch slightly so steps don't sound robotic
		footstep_player.pitch_scale = randf_range(0.9, 1.1)
		footstep_player.play()

func _input(event):
	if event.is_action_pressed("interact"):
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider.is_in_group("interactable"):
				collider.interact()

func _try_step_up(delta: float) -> bool:
	var move_dir = Vector3(velocity.x, 0, velocity.z).normalized()
	if move_dir.length() < 0.1 or not is_on_floor():
		return false

	var space_state = get_world_3d().direct_space_state
	var forward_offset = move_dir * STEP_CHECK_DIST
	var step_top = global_position + Vector3.UP * STEP_HEIGHT
	var forward_check = PhysicsRayQueryParameters3D.create(
		step_top,
		step_top + forward_offset,
		1,
		[get_rid()]
	)
	var forward_result = space_state.intersect_ray(forward_check)
	if forward_result:
		return false

	var cast_from = global_position + forward_offset + Vector3.UP * STEP_HEIGHT
	var cast_to = global_position + forward_offset + Vector3.DOWN * 0.1
	var down_check = PhysicsRayQueryParameters3D.create(
		cast_from,
		cast_to,
		1,
		[get_rid()]
	)
	var down_result = space_state.intersect_ray(down_check)

	if down_result:
		var step_y = down_result.position.y
		var height_diff = step_y - global_position.y
		if height_diff > 0.05 and height_diff <= STEP_HEIGHT:
			velocity.y = 0
			global_position.y = step_y
			return true

	return false
