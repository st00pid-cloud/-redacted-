extends CanvasLayer

var _is_paused: bool = false

func _ready() -> void:
	# CRITICAL: this node must keep processing even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_paused:
			_resume()
		else:
			_pause()

func _pause() -> void:
	_is_paused = true
	get_tree().paused = true
	# Set mouse mode AFTER pausing the tree
	await get_tree().process_frame
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _resume() -> void:
	_is_paused = false
	hide()
	# Release mouse capture BEFORE unpausing
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().process_frame
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_resume()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().quit()
