extends StaticBody3D

## ChallengeTerminal.gd
## Attach to a StaticBody3D in the "interactable" group.
## Set challenge_type in the inspector to assign which challenge this terminal runs.
##
## Usage in the scene:
##   1. Instance a NetworkRack or any mesh with a StaticBody3D child
##   2. Attach this script to the StaticBody3D
##   3. Set challenge_type to "echo", "ghost", "thermal", or "memory"
##   4. The terminal auto-creates the challenge CanvasLayer at runtime

@export_enum("echo", "ghost", "thermal", "memory") var challenge_type: String = "echo"

var _challenge_node: Node = null
var _interaction_stage: int = 0  # 0=available, 1=running, 2=completed
var has_been_read: bool = false  # for crosshair exhaustion check

# Dialogue lines per challenge type (intro flavor)
const TERMINAL_LINES = {
	"echo": {
		"intro": [
			"[TERMINAL]: Audio monitoring station — Sub-Level 3, Bay 2.",
			"[SYSTEM]: Anomalous audio feeds detected. Correlation required.",
			"[SYSTEM]: Align the feeds to identify the source.",
		],
		"task_name": "Echo Correlation",
		"task_desc": "Align audio feeds A and B using the slider. Identify the anomaly.",
	},
	"ghost": {
		"intro": [
			"[TERMINAL]: Peripheral interface console — Sub-Level 3, Bay 5.",
			"[SYSTEM]: Input calibration drift detected on this terminal.",
			"[SYSTEM]: Recalibrate by dragging the diagnostic tool to the drop zone.",
		],
		"task_name": "Cursor Calibration",
		"task_desc": "Drag the tool to the drop zone. Watch for peripheral interference.",
	},
	"thermal": {
		"intro": [
			"[TERMINAL]: Environmental monitoring station — Sub-Level 3, Bay 9.",
			"[SYSTEM]: Thermal grid shows multiple unpatched heat leaks.",
			"[SYSTEM]: Patch all leaks. Report any anomalous signatures.",
		],
		"task_name": "Thermal Scan",
		"task_desc": "Click heat leaks to patch them. Watch for anomalous signatures.",
	},
	"memory": {
		"intro": [
			"[TERMINAL]: Memory validation console — Sub-Level 3, Bay 12.",
			"[SYSTEM]: Buffer integrity check required.",
			"[SYSTEM]: Memorize the string. Reproduce it exactly.",
		],
		"task_name": "Memory Validation",
		"task_desc": "A string will flash briefly. Type it back from memory.",
	},
}

# Script paths for each challenge type
const CHALLENGE_SCRIPTS = {
	"echo": "res://challenges/EchoCorrelation.gd",
	"ghost": "res://challenges/GhostCursor.gd",
	"thermal": "res://challenges/ThermalScan.gd",
	"memory": "res://challenges/MemoryString.gd",
}

func _ready() -> void:
	# Create the challenge node at runtime
	_create_challenge_node()

func _create_challenge_node() -> void:
	var script_path = CHALLENGE_SCRIPTS.get(challenge_type, "")
	if script_path == "":
		push_warning("ChallengeTerminal: Unknown challenge_type: " + challenge_type)
		return

	var scr = load(script_path)
	if not scr:
		push_warning("ChallengeTerminal: Failed to load script: " + script_path)
		return

	_challenge_node = CanvasLayer.new()
	_challenge_node.set_script(scr)
	# Add to scene tree at root level so the CanvasLayer renders properly
	get_tree().root.call_deferred("add_child", _challenge_node)

func interact() -> void:
	# Already done
	if _interaction_stage == 2:
		var lines: Array[String] = ["[SYSTEM]: This terminal's diagnostic is complete."]
		DialogueManager.show_dialogue(lines)
		return

	# Already running (shouldn't happen if player is frozen, but safety check)
	if _interaction_stage == 1:
		return

	# Check if this challenge was already completed via tracker
	if ChallengeTracker.is_challenge_done(challenge_type):
		_interaction_stage = 2
		has_been_read = true
		var lines: Array[String] = ["[SYSTEM]: This terminal's diagnostic is complete."]
		DialogueManager.show_dialogue(lines)
		return

	# Start the challenge
	_interaction_stage = 1

	var data = TERMINAL_LINES.get(challenge_type, {})

	# Set task
	var task = TaskData.new()
	task.task_id = challenge_type
	task.task_name = data.get("task_name", "Diagnostic")
	task.description = data.get("task_desc", "Complete the diagnostic.")
	TaskManager.set_task(task)

	# Show intro dialogue
	var intro = data.get("intro", [])
	if intro.size() > 0:
		var lines: Array[String] = []
		for l in intro:
			lines.append(l)
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished

	# Freeze player and launch challenge
	ChallengeTracker.freeze_player()

	if _challenge_node and _challenge_node.has_method("open_challenge"):
		if not _challenge_node.challenge_completed.is_connected(_on_challenge_done):
			_challenge_node.challenge_completed.connect(_on_challenge_done, CONNECT_ONE_SHOT)
		_challenge_node.open_challenge()
	else:
		push_warning("ChallengeTerminal: Challenge node not ready for type: " + challenge_type)
		ChallengeTracker.unfreeze_player()
		_interaction_stage = 0

func _on_challenge_done(success: bool) -> void:
	_interaction_stage = 2
	has_been_read = true

	# Register result
	ChallengeTracker.register_result(challenge_type, success)

	# Unfreeze player
	ChallengeTracker.unfreeze_player()

	# Show result dialogue
	if success:
		var lines: Array[String] = [
			"[SYSTEM]: Diagnostic passed. Terminal secured.",
			"[SYSTEM]: %d / %d subsystems checked." % [ChallengeTracker.get_completed_count(), ChallengeTracker.required_ids.size()],
		]
		DialogueManager.show_dialogue(lines)
	else:
		var lines: Array[String] = [
			"[SYSTEM]: Diagnostic anomaly detected. Result logged.",
			"[SYSTEM]: %d / %d subsystems checked." % [ChallengeTracker.get_completed_count(), ChallengeTracker.required_ids.size()],
		]
		DialogueManager.show_dialogue(lines)

	await DialogueManager.dialogue_finished

	# Update task to guide player to next terminal or the main rack
	if ChallengeTracker.all_done():
		var task = TaskData.new()
		task.task_id = "return_rack"
		task.task_name = "Return to Rack 7"
		task.description = "All subsystem diagnostics complete. Return to the main console."
		TaskManager.set_task(task)
	else:
		var remaining = ChallengeTracker.required_ids.size() - ChallengeTracker.get_completed_count()
		var task = TaskData.new()
		task.task_id = "find_terminals"
		task.task_name = "Subsystem Diagnostics"
		task.description = "%d terminal(s) remaining. Locate and complete them." % remaining
		TaskManager.set_task(task)
