extends CanvasLayer

var _is_paused: bool = false

func _ready() -> void:
	# Ensure the pause menu itself can run even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS 
	hide()

func _input(event: InputEvent) -> void:
	# Use _input instead of _unhandled_input to override other UI/Blocking
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		
		# Prevent pausing if the player is currently in a challenge/dialogue 
		# unless you specifically want them to be able to pause there.
		if ChallengeTracker.is_player_frozen():
			# Optional: Allow pausing during challenges, but you must 
			# be careful with mouse mode conflicts.
			pass 

		if _is_paused:
			_resume()
		else:
			_pause()
		
		# Stop the input from bubbling down to other nodes
		get_viewport().set_input_as_handled()

func _pause() -> void:
	_is_paused = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _resume() -> void:
	_is_paused = false
	hide()
	# Check if we should actually capture the mouse 
	# (don't capture if the player is still in a terminal)
	if not ChallengeTracker.is_player_frozen():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	get_tree().paused = false
