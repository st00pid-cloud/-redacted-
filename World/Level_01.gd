extends Node3D

@onready var horror_overlay: ColorRect = $HorrorOverlay
@onready var resist_overlay: Control = $ResistOverlay

var _player: CharacterBody3D = null
var _resist_active: bool = false
var _resist_progress: float = 0.0
var _resist_presses_needed: int = 5
var _resist_presses: int = 0
var _ending_in_progress: bool = false

const OPENING_LINES = [
	"Central Command Console. 0300 hours.",
	"Routine maintenance call. Someone flagged an anomaly on Rack 7.",
	"You've done this a hundred times. Pull the module, reseat it, go home.",
	"The server room is quieter than usual.",
]

func _ready():
	# Hide overlays
	if horror_overlay:
		horror_overlay.visible = false
		horror_overlay.modulate.a = 0.0
	if resist_overlay:
		resist_overlay.visible = false

	# Find the player and freeze them for the opening
	await get_tree().process_frame
	_player = _find_player()
	if _player:
		_player.set_physics_process(false)
		_player.set_process_input(false)

	# Set opening task
	var task = TaskData.new()
	task.task_id = "task_01"
	task.task_name = "Maintenance Call"
	task.description = "Investigate anomalous buffer overflow — Server Rack 7."
	TaskManager.set_task(task)

	# Play opening dialogue after a short delay
	await get_tree().create_timer(1.2).timeout
	var lines: Array[String] = []
	for line in OPENING_LINES:
		lines.append(line)
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished

	# Unfreeze player after dialogue
	if _player:
		_player.set_physics_process(true)
		_player.set_process_input(true)

	# Listen for the post-diagnostic corruption ending
	TaskManager.task_completed.connect(_on_task_completed)

func _on_task_completed(task_id: String) -> void:
	# After the diagnostic is done, NetworkRack handles the immediate aftermath.
	# We handle the resist mechanic here if corruption triggers.
	pass

## Called by NetworkRack (or externally) to start the RESIST sequence
func start_resist_sequence() -> void:
	if _ending_in_progress:
		return
	_ending_in_progress = true

	# Freeze player
	if _player:
		_player.set_physics_process(false)
		_player.set_process_input(false)

	# Flash horror overlay (red screen)
	if horror_overlay:
		horror_overlay.visible = true
		var tween = create_tween()
		tween.tween_property(horror_overlay, "modulate:a", 0.6, 0.3)
		await tween.finished

	# Show resist prompt
	_resist_active = true
	_resist_presses = 0
	if resist_overlay:
		resist_overlay.visible = true

	# Give player a window to resist
	await get_tree().create_timer(6.0).timeout

	# If they haven't resisted enough, integration wins
	if _resist_active:
		_resist_active = false
		if resist_overlay:
			resist_overlay.visible = false
		GameManager.trigger_game_over("integration_complete")

func _input(event: InputEvent) -> void:
	if not _resist_active:
		return
	if event.is_action_pressed("interact"):
		_resist_presses += 1
		# Shake the overlay for feedback
		if horror_overlay:
			var tween = create_tween()
			tween.tween_property(horror_overlay, "modulate:a",
				max(0.0, horror_overlay.modulate.a - 0.12), 0.1)
		if _resist_presses >= _resist_presses_needed:
			_resist_active = false
			_on_resist_success()

func _on_resist_success() -> void:
	if resist_overlay:
		resist_overlay.visible = false

	# Fade out horror overlay
	if horror_overlay:
		var tween = create_tween()
		tween.tween_property(horror_overlay, "modulate:a", 0.0, 0.8)
		await tween.finished
		horror_overlay.visible = false

	# Unfreeze player briefly
	if _player:
		_player.set_physics_process(true)
		_player.set_process_input(true)

	# Show final dialogue then end
	var lines: Array[String] = [
		"[SYSTEM]: Integration rejected. Host signal unstable.",
		"[SYSTEM]: Entity retreating to secondary buffer.",
		"[SYSTEM]: ...silence.",
	]
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished

	await get_tree().create_timer(1.0).timeout
	GameManager.trigger_ending("engineer_resisted")

func _find_player() -> CharacterBody3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	# Fallback
	for child in get_children():
		if child is CharacterBody3D:
			return child
	return null
