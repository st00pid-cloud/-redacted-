extends StaticBody3D

## NetworkRack.gd — The main puzzle interactable
## Flow: Player interacts → dialogue explains the problem → diagnostic panel opens

var _interaction_stage: int = 0  # 0=first look, 1=diagnostic, 2=completed
var _diag_ref: Node = null  # fetched lazily — NOT typed as CanvasLayer to avoid Godot assignment issues

const INTRO_LINES: Array[String] = [
	"[SYSTEM]: Rack 7 — anomalous activity detected on network port.",
	"[SYSTEM]: Run diagnostic scan to isolate corrupted port.",
	"[SYSTEM]: WARNING: Incorrect isolation may accelerate integration.",
]

const POST_SUCCESS_LINES: Array[String] = [
	"[SYSTEM]: Port 7 isolated. Partial containment achieved.",
	"[SYSTEM]: ...signal residue detected in adjacent subsystems.",
	"[SYSTEM]: Recommend immediate facility evacuation.",
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
	match _interaction_stage:
		0:
			_interaction_stage = 1
			var task = TaskData.new()
			task.task_id = "diagnose_rack"
			task.task_name = "Diagnose Rack 7"
			task.description = "Run the diagnostic interface. Identify the corrupted port."
			TaskManager.set_task(task)
			
			var lines: Array[String] = []
			for l in INTRO_LINES:
				lines.append(l)
			DialogueManager.show_dialogue(lines)
			await DialogueManager.dialogue_finished
			_open_diagnostic()
		1:
			_open_diagnostic()
		2:
			var lines: Array[String] = ["[SYSTEM]: Rack 7 — diagnostic complete. No further action available."]
			DialogueManager.show_dialogue(lines)

func _open_diagnostic() -> void:
	var panel = _get_diagnostic_panel()
	if panel:
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
	
	TaskManager.complete_task("diagnose_rack")
	
	if success:
		var lines: Array[String] = []
		for l in POST_SUCCESS_LINES:
			lines.append(l)
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished
		TaskManager.begin_corruption()
		await get_tree().create_timer(8.0).timeout
		GameManager.trigger_ending("engineer_resisted")
	else:
		var lines: Array[String] = []
		for l in POST_FAIL_LINES:
			lines.append(l)
		DialogueManager.show_dialogue(lines)
		await DialogueManager.dialogue_finished
		GameManager.trigger_game_over("integration_accelerated")

func _find_node_by_script(script_hint: String) -> Node:
	for child in get_tree().root.get_children():
		if child.name.contains(script_hint) or (child.get_script() and child.get_script().resource_path.contains(script_hint)):
			return child
		for sub in child.get_children():
			if sub.name.contains(script_hint) or (sub.get_script() and sub.get_script().resource_path.contains(script_hint)):
				return sub
	return null
