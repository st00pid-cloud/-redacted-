extends CanvasLayer

## PauseMenu.gd
##
## CRITICAL SCENE SETUP — this script alone is not enough:
##   1. In PauseMenu.tscn, select the root CanvasLayer node.
##   2. In the Inspector → Node → Process Mode → set to "Always".
##      (Do NOT rely on _ready() to set this — it fires after the first pause.)
##   3. PauseMenu must be added to your Level scene as a DIRECT child of the
##      Level root, NOT as a child of the Player node.
##      (freeze_player() calls set_process_input(false) on Player's subtree.)

var _is_paused: bool = false

func _ready() -> void:
	# DO NOT set process_mode here — it must be set in the .tscn Inspector.
	# Setting it in _ready() is unreliable: if the tree is already paused when
	# this node enters, _ready() itself won't fire until unpaused, defeating
	# the purpose.
	hide()

func _input(event: InputEvent) -> void:
	# This guard is belt-and-suspenders: process_mode = Always in the .tscn
	# is what actually keeps _input() alive during pause. This check is for
	# runtime safety only.
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode != KEY_ESCAPE:
		return

	if _is_paused:
		_resume()
	else:
		_pause()

	get_viewport().set_input_as_handled()

func _pause() -> void:
	_is_paused = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _resume() -> void:
	_is_paused = false
	get_tree().paused = false
	hide()
	# Only recapture mouse if no challenge/dialogue is stealing it
	if not ChallengeTracker.is_player_frozen() and not DialogueManager.is_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed() -> void:
	_resume()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
