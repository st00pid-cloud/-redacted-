extends StaticBody3D

## ChallengeTerminal.gd — All improvements integrated:
## - Named stage constants instead of magic ints
## - Retry system: failed terminals allow one re-entry with corruption penalty
## - Soft ordering: thermal requires echo done, memory requires ghost done
## - TaskManager.begin_corruption() called when challenge opens

@onready var status_light: OmniLight3D = $OmniLight3D
@onready var hum_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export_enum("echo", "ghost", "thermal", "memory") var challenge_type: String = "echo"

var _challenge_node: Node = null

# Named stage constants — replaces magic 0/1/2 ints
const STAGE_IDLE     = 0
const STAGE_RUNNING  = 1
const STAGE_FAILED   = 2
const STAGE_COMPLETE = 3

var _interaction_stage: int = STAGE_IDLE
var has_been_read: bool = false

# Soft unlock requirements — key must be done before value is accessible
const UNLOCK_AFTER: Dictionary = {
	"thermal": ["echo"],
	"memory":  ["ghost"],
}

const TERMINAL_LINES = {
	"echo": {
		"intro": [
			"[TERMINAL]: Audio Monitor — Bay 2.",
			"[SYSTEM]: Strange noise detected on internal mics. Cleanup required.",
			"[SYSTEM]: Match the frequencies to find the source.",
		],
		"task_name": "Frequency Match",
		"task_desc": "Use the slider to sync Feeds A and B. Find out what’s making that noise.",
	},
	"ghost": {
		"intro": [
			"[TERMINAL]: Interface Console — Bay 5.",
			"[SYSTEM]: Input lag detected. Mouse tracking is drifting.",
			"[SYSTEM]: Reset the sensor by dragging the tool to the target.",
		],
		"task_name": "Sensor Reset",
		"task_desc": "Drag the tool into the target zone. Don't let the drift pull you off course.",
	},
	"thermal": {
		"intro": [
			"[TERMINAL]: Temp Control — Bay 9.",
			"[SYSTEM]: Warning: Cooling failure. Multiple heat spikes detected.",
			"[SYSTEM]: Seal the leaks before the rack overheats.",
		],
		"task_name": "Leak Repair",
		"task_desc": "Click the hot spots to seal them. Keep an eye out for anything unusual",
	},
	"memory": {
		"intro": [
			"[TERMINAL]: Data Security — Bay 12.",
			"[SYSTEM]: Security code verification required.",
			"[SYSTEM]: Watch the sequence. Repeat it back to unlock the tray.",
		],
		"task_name": "Security Override",
		"task_desc": "A code will flash on screen. Type it back exactly as you saw it.",
	},
}

# NEW (scene-based)
const CHALLENGE_SCENES = {
	"echo":    "res://challenges_tscn_version/EchoCorrelation.tscn",
	"ghost":   "res://challenges_tscn_version/GhostCursor.tscn",
	"thermal": "res://challenges_tscn_version/ThermalScan.tscn",
	"memory":  "res://challenges_tscn_version/MemoryString.tscn",
}

func _ready() -> void:
	_load_challenge_scene()

func _load_challenge_scene() -> void:
	var scene_path = CHALLENGE_SCENES.get(challenge_type, "")
	if scene_path == "":
		push_warning("ChallengeTerminal: Unknown challenge_type: " + challenge_type)
		return
	var scene = load(scene_path)
	if not scene:
		push_warning("ChallengeTerminal: Failed to load scene: " + scene_path)
		return
	_challenge_node = scene.instantiate()
	get_tree().root.call_deferred("add_child", _challenge_node)


func interact() -> void:
	# Complete — short system message
	if _interaction_stage == STAGE_COMPLETE:
		var lines: Array[String] = ["[SYSTEM]: This terminal's diagnostic is complete."]
		DialogueManager.show_dialogue(lines)
		return

	# Already running — hard block
	if _interaction_stage == STAGE_RUNNING:
		return

	# Already tracked as done
	if ChallengeTracker.is_challenge_done(challenge_type):
		_interaction_stage = STAGE_COMPLETE
		has_been_read = true
		var lines: Array[String] = ["[SYSTEM]: This terminal's diagnostic is complete."]
		DialogueManager.show_dialogue(lines)
		return

	# ── Retry path — previously failed terminal ───────────────────────────
	if _interaction_stage == STAGE_FAILED:
		var lines: Array[String] = [
			"[SYSTEM]: Previous diagnostic incomplete.",
			"[SYSTEM]: Re-entry permitted. Corruption penalty applied.",
		]
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished
		# Corruption penalty for retry
		TaskManager._corruption_level = min(TaskManager._corruption_level + 0.2, 1.0)
		TaskManager.corruption_tick.emit()
		_interaction_stage = STAGE_IDLE
		# Fall through to normal open below

	# ── Soft ordering check ───────────────────────────────────────────────
	var prereqs: Array = UNLOCK_AFTER.get(challenge_type, [])
	for req in prereqs:
		if not ChallengeTracker.is_challenge_done(req):
			var lines: Array[String] = [
				"[SYSTEM]: Subsystem locked.",
				"[SYSTEM]: Complete an earlier diagnostic terminal first.",
			]
			DialogueManager.show_dialogue(lines)
			return

	# ── Normal open ───────────────────────────────────────────────────────
	_interaction_stage = STAGE_RUNNING
	ChallengeTracker.freeze_player()

	# Begin corruption immediately when challenge opens
	TaskManager.begin_corruption()

	var data = TERMINAL_LINES.get(challenge_type, {})

	var task = TaskData.new()
	task.task_id = challenge_type
	task.task_name = data.get("task_name", "Diagnostic")
	task.description = data.get("task_desc", "Complete the diagnostic.")
	TaskManager.set_task(task)

	var intro = data.get("intro", [])
	if intro.size() > 0:
		var lines: Array[String] = []
		for l in intro:
			lines.append(l)
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished

	if _challenge_node and _challenge_node.has_method("open_challenge"):
		if not _challenge_node.challenge_completed.is_connected(_on_challenge_done):
			_challenge_node.challenge_completed.connect(_on_challenge_done, CONNECT_ONE_SHOT)
		_challenge_node.open_challenge()
	else:
		push_warning("ChallengeTerminal: Challenge node not ready for type: " + challenge_type)
		ChallengeTracker.unfreeze_player()
		_interaction_stage = STAGE_IDLE

func _on_challenge_done(success: bool) -> void:
	# Set stage based on outcome
	_interaction_stage = STAGE_COMPLETE if success else STAGE_FAILED
	has_been_read = true

	ChallengeTracker.register_result(challenge_type, success)
	ChallengeTracker.unfreeze_player()

	if success:
		var lines: Array[String] = [
			"Diagnostic passed. Terminal secured.",
			"%d / %d subsystems checked." % [ChallengeTracker.get_completed_count(), ChallengeTracker.required_ids.size()],
		]
		DialogueManager.show_dialogue(lines)
	else:
		var lines: Array[String] = [
			"Diagnostic anomaly detected. Result logged.",
			"[SYSTEM]: Re-entry available. Corruption penalty will apply.",
			"%d / %d subsystems checked." % [ChallengeTracker.get_completed_count(), ChallengeTracker.required_ids.size()],
		]
		DialogueManager.show_dialogue(lines)

	await DialogueManager.dialogue_finished

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

func _process(delta: float) -> void:
	if _interaction_stage == STAGE_IDLE:
		status_light.light_energy = 1.0 + (sin(Time.get_ticks_msec() * 0.005) * 0.5)
		if randf() < 0.02:
			status_light.visible = !status_light.visible
	elif _interaction_stage == STAGE_FAILED:
		# Dim red pulse for failed terminals
		status_light.visible = true
		status_light.light_color = Color(0.8, 0.1, 0.1)
		status_light.light_energy = 0.4 + (sin(Time.get_ticks_msec() * 0.003) * 0.2)
	elif _interaction_stage == STAGE_COMPLETE:
		status_light.visible = true
		status_light.light_color = Color.GREEN
		status_light.light_energy = 0.5
		hum_audio.unit_size = lerp(hum_audio.unit_size, 0.0, 0.1)
