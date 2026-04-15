extends StaticBody3D

## NetworkRack.gd — The main puzzle interactable
## Flow: interact → dialogue → diagnostic (port + 4 horror questions) → ending
## Updates TaskManager at each stage so the TaskHUD always shows the current objective.

var _interaction_stage: int = 0  # 0=first look, 1=diagnostic open, 2=completed
var _diag_ref: Node = null

const INTRO_LINES: Array[String] = [
	"[SYSTEM]: Rack 7 — anomalous activity detected on network port.",
	"[SYSTEM]: Run diagnostic scan to isolate corrupted port.",
	"[SYSTEM]: WARNING: Incorrect isolation may accelerate integration.",
]

const POST_SUCCESS_LINES: Array[String] = [
	"[SYSTEM]: Diagnostic complete. Containment at 42%.",
	"[SYSTEM]: Entity is resisting isolation.",
	"[SYSTEM]: Brace yourself, R. Vasquez.",
]

const POST_FAIL_LINES: Array[String] = [
	"[SYSTEM]: Diagnostic failure. Integration vector widened.",
	"[SYSTEM]: It knows you tried.",
]

func _get_diagnostic_panel() -> Node:
	if _diag_ref and is_instance_valid(_diag_ref):
		return _diag_ref
	var nodes = get_tree().get_nodes_in_group("diagnostic_panel")
	if nodes.size() > 0:
		_diag_ref = nodes[0]
	return _diag_ref

func interact() -> void:
	if _interaction_stage == 2:
		var lines: Array[String] = ["[SYSTEM]: Rack 7 — diagnostic complete. No further action available."]
		DialogueManager.show_dialogue(lines)
		return
	if _interaction_stage == 1:
		_open_diagnostic()
		return

	# Stage 0: first interaction
	_interaction_stage = 1

	# Task: diagnose
	_set_task("diagnose_rack", "Diagnose Rack 7", "Interact with the console to run the diagnostic scan.")

	var lines: Array[String] = []
	for l in INTRO_LINES:
		lines.append(l)
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished

	# Update task before opening diagnostic
	_set_task("select_port", "Identify Corrupted Port", "Examine the port data. One port has anomalous cycling values — isolate it.")

	_open_diagnostic()

func _open_diagnostic() -> void:
	var panel = _get_diagnostic_panel()
	if not panel:
		push_warning("NetworkRack: No diagnostic_panel found in group!")
		return
	var loc_header = _find_node_by_script("LocationHeader")
	if loc_header and loc_header.has_method("hide_header"):
		loc_header.hide_header()
	panel.open_diagnostic()
	if not panel.diagnostic_completed.is_connected(_on_diagnostic_done):
		panel.diagnostic_completed.connect(_on_diagnostic_done, CONNECT_ONE_SHOT)

func _on_diagnostic_done(success: bool) -> void:
	_interaction_stage = 2
	var loc_header = _find_node_by_script("LocationHeader")
	if loc_header and loc_header.has_method("show_header"):
		loc_header.show_header()

	# Clear the diagnostic task
	TaskManager.complete_task("select_port")

	if success:
		# Set a new task for the resist phase
		_set_task("survive", "Survive", "Something is wrong. Brace yourself.")

		var lines: Array[String] = []
		for l in POST_SUCCESS_LINES:
			lines.append(l)
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished

		TaskManager.begin_corruption()
		await get_tree().create_timer(3.0).timeout

		# Update task right before resist
		_set_task("resist", "RESIST", "The entity is attempting integration. Fight back.")

		var level = get_tree().current_scene
		if level and level.has_method("start_resist_sequence"):
			level.start_resist_sequence()
		else:
			GameManager.trigger_ending("engineer_resisted")
	else:
		_set_task("failed", "---", "Diagnostic failed.")

		var lines: Array[String] = []
		for l in POST_FAIL_LINES:
			lines.append(l)
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished
		GameManager.trigger_game_over("integration_accelerated")

func _set_task(id: String, title: String, desc: String) -> void:
	var task = TaskData.new()
	task.task_id = id
	task.task_name = title
	task.description = desc
	TaskManager.set_task(task)

func _find_node_by_script(script_hint: String) -> Node:
	for child in get_tree().root.get_children():
		if child.name.contains(script_hint) or (child.get_script() and child.get_script().resource_path.contains(script_hint)):
			return child
		for sub in child.get_children():
			if sub.name.contains(script_hint) or (sub.get_script() and sub.get_script().resource_path.contains(script_hint)):
				return sub
	return null
