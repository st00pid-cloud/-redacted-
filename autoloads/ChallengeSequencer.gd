extends Node

## ChallengeSequencer — Autoload or level child
## After the port diagnostic, runs all 4 challenges + horror questions in order.
## Tracks score and emits final result.

signal sequence_completed(success: bool, score: int, total: int)

var _challenges: Array = []  # Array of {node, task_name, task_desc}
var _current_index: int = 0
var _score: int = 0
var _total: int = 0
var _running: bool = false

func start_sequence() -> void:
	_challenges.clear()
	_current_index = 0
	_score = 0
	_running = true

	# Find challenge nodes by group
	var echo = _find_group("challenge_echo")
	var ghost = _find_group("challenge_ghost")
	var thermal = _find_group("challenge_thermal")
	var memory = _find_group("challenge_memory")

	if echo:
		_challenges.append({
			"node": echo,
			"task_name": "Echo Correlation",
			"task_desc": "Align the audio feeds using the slider. Identify the anomaly.",
		})
	if ghost:
		_challenges.append({
			"node": ghost,
			"task_name": "Cursor Calibration",
			"task_desc": "Drag the diagnostic tool to the drop zone. Avoid the ghost cursor.",
		})
	if thermal:
		_challenges.append({
			"node": thermal,
			"task_name": "Thermal Scan",
			"task_desc": "Click all heat leaks to patch them. Watch for anomalies.",
		})
	if memory:
		_challenges.append({
			"node": memory,
			"task_name": "Memory Validation",
			"task_desc": "Memorize the string. Type it back exactly.",
		})

	_total = _challenges.size()

	if _total == 0:
		push_warning("ChallengeSequencer: No challenge nodes found!")
		emit_signal("sequence_completed", false, 0, 0)
		return

	_run_next()

func _run_next() -> void:
	if _current_index >= _challenges.size():
		_running = false
		var success = _score >= max(1, _total - 1)  # need N-1 to pass
		emit_signal("sequence_completed", success, _score, _total)
		return

	var entry = _challenges[_current_index]
	var node = entry["node"]

	# Update task HUD
	var task = TaskData.new()
	task.task_id = "challenge_%d" % _current_index
	task.task_name = entry["task_name"]
	task.description = entry["task_desc"]
	TaskManager.set_task(task)

	# Connect and launch
	if not node.challenge_completed.is_connected(_on_challenge_done):
		node.challenge_completed.connect(_on_challenge_done, CONNECT_ONE_SHOT)
	node.open_challenge()

func _on_challenge_done(success: bool) -> void:
	if success:
		_score += 1
	_current_index += 1

	# Brief pause between challenges
	await get_tree().create_timer(1.0).timeout
	_run_next()

func _find_group(group_name: String) -> Node:
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		return nodes[0]
	return null
