extends CanvasLayer

## PauseMenu.gd — FIXED
## Resolved the logic loop preventing resume.

var _is_paused: bool = false

func _ready() -> void:
	# Keep the process_mode fix to ensure the script runs while paused [cite: 13]
	process_mode = Node.PROCESS_MODE_ALWAYS 
	hide()

func _input(event: InputEvent) -> void:
# Use the built-in action for Escape (ui_cancel) for better compatibility
	if event.is_action_pressed("ui_cancel"):
		
		# If we are already paused, we ALWAYS want to allow the resume toggle
		if _is_paused:
			_resume()
			get_viewport().set_input_as_handled()
			return

		# If NOT paused, check if something else is blocking us (dialogue, etc.) [cite: 15, 16]
		if _is_pause_blocked():
			return

		_pause()
		get_viewport().set_input_as_handled()

func _is_pause_blocked() -> bool:
	# Block if dialogue or challenges are active 
	if DialogueManager and DialogueManager.is_active:
		return true
	if ChallengeTracker and ChallengeTracker.is_player_frozen():
		return true
	
	# Only block if the tree was paused by something ELSE (like a cutscene) 
	# but we aren't the ones currently holding the pause state.
	if get_tree().paused and not _is_paused:
		return true
		
	return false

func _pause() -> void:
	_is_paused = true
	get_tree().paused = true
	if SignalIntegrityTimer:
		SignalIntegrityTimer.pause_timer() 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _resume() -> void:
	_is_paused = false
	get_tree().paused = false
	hide()
	if SignalIntegrityTimer:
		SignalIntegrityTimer.resume_timer() 
	
	# Safety check before capturing mouse [cite: 9]
	if not ChallengeTracker.is_player_frozen() and not DialogueManager.is_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed() -> void:
	_resume()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://World/main_menu/MainMenu.tscn")
